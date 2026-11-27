run('Tags_SIM_V0_1_20261120.m');
model_name = "FullFMS_SIM_V0_1_8_R2025b";
key = 'C:\ssh_keys\MatOFI_lab_id_rsa';
localDir = pwd;
downloadCSV = true;

user = 'root';
ip = ["200.145.26.202", "200.145.26.213", "200.145.26.213", "200.145.26.203","200.145.26.204","200.145.26.205", "200.145.26.206", "200.145.26.207", "200.145.26.208"];

station = ["Master", "Robot", "Storage", "Handling1", "Sorting", "Testing","Distribution", "Handling2", "Processing"];

path3 = 'SimulatedVariables_';
path4= '.csv';
CSVLocal = path3 + station + path4;

name2 = ["MASTER", "NODE", "HD1", "SORT", "TEST", "DIST", "HD2", "PROC"];
blkW  = model_name + "/OPC UA Write-" + name2;
BUS_W = model_name + "/BUS_SIM_" + name2;

%==========================================================================
if downloadCSV
    for i = 1:numel(ip)
        try
            s = sftp(ip(i), user, 'PrivateKeyFile', key);
            cd(s, "/root/ProjetoGemeo/AAS/" + station(i));
            mget(s, 'SimulatedVariables.csv', localDir);
            close(s);

            fileOriginal = fullfile(localDir, 'SimulatedVariables.csv');
            fileDestino  = fullfile(localDir, CSVLocal(i));
            if exist(fileOriginal, 'file')
                movefile(fileOriginal, fileDestino, 'f');
            end
            fprintf('Download concluído [%s]!\n', station(i));
        catch ME
            fprintf('Erro na estação [%s] (IP: %s): %s\n', station(i), ip(i), ME.message);
        end
    end
end

numericTags = "CartID|RT_Counter|RQ_Turns|Mag_Parts|RQ_MParts|RQ_Parts|TagID|UserData";

for i = 1:numel(AllVariablesSim)
    secNames = AllVariablesSimNames{i};
    stationElems = Simulink.BusElement.empty;

    for k = 1:numel(AllVariablesSim{i})
        tags = string(AllVariablesSim{i}{k});
        elems = Simulink.BusElement.empty;
        for l = 1:numel(tags)
            e = Simulink.BusElement;
            e.Name = char(tags(l));
            if ~isempty(regexp(tags(l), numericTags, 'once'))
                e.DataType = 'double';
            else
                e.DataType = 'boolean';
            end
            elems(end+1) = e;
        end
        b = Simulink.Bus;
        b.Elements = elems;
        assignin('base', "B_" + secNames(k), b);

        se = Simulink.BusElement;
        se.Name = char(secNames(k));
        se.DataType = char("Bus: B_" + secNames(k));
        stationElems(end+1) = se;
    end

    bs = Simulink.Bus;
    bs.Elements = stationElems;
    assignin('base', "B_SIM_" + name2(i), bs);
end

busList = evalin('base', 'who(''-regexp'', ''^B_Sim|^B_SIM_'')');
evalin('base', "save('BUS_CONFIG_SIM.mat', '" + strjoin(string(busList), "','") + "')");
fprintf('Bus objects salvos em BUS_CONFIG_SIM.mat (%d buses)\n', numel(busList));

%==========================================================================
T1 = readtable("SimulatedVariables_Master.csv");
T2 = readtable("SimulatedVariables_Storage.csv");
T3 = readtable("SimulatedVariables_Robot.csv");
T4 = readtable("SimulatedVariables_Handling1.csv");
T5 = readtable("SimulatedVariables_Sorting.csv");
T6 = readtable("SimulatedVariables_Testing.csv");
T7 = readtable("SimulatedVariables_Distribution.csv");
T8 = readtable("SimulatedVariables_Handling2.csv");
T9 = readtable("SimulatedVariables_Processing.csv");

T = [T1;T2;T3;T4;T5;T6;T7;T8;T9];
Var1_limpo = string(erase(T.Var1,';ns'));

%==========================================================================
load_system(model_name);

for i = 1:numel(AllVariablesSim)

    NodeRows = strings(0);
    SelRows  = strings(0);
    Missing  = strings(0);
    ns = 6;
    cnt = 1;
    secNames = AllVariablesSimNames{i};

    for k = 1:numel(AllVariablesSim{i})

        tags_secao = string(AllVariablesSim{i}{k});
        if isempty(tags_secao), continue; end

        for l = 1:numel(tags_secao)
            idx = find(Var1_limpo == tags_secao(l), 1);
            if isempty(idx)
                Missing(end+1) = tags_secao(l);
                continue;
            end
            NodeRows(cnt) = sprintf("'%d','Value','%d','%d','1'", ...
                                    cnt, ns, T.Var3(idx));
            SelRows(cnt)  = secNames(k) + "." + tags_secao(l);
            cnt = cnt + 1;
        end
    end

    NodeListStr = "{ " + strjoin(NodeRows,"; ") + " }";
    disp("=============="+name2(i)+"=================");
    disp(NodeListStr);
    disp(SelRows);
    if ~isempty(Missing)
        fprintf('ATENÇÃO: %d tags simuladas não encontradas nos CSVs (ficaram fora do Write):\n', numel(Missing));
        disp(Missing);
    end
    disp("==========================================");

    if isempty(NodeRows), continue; end

    if getSimulinkBlockHandle(blkW(i)) ~= -1
        set_param(blkW(i), 'NodeList', NodeListStr);
    else
        fprintf('Bloco não existe ainda: %s\n', blkW(i));
    end
    if getSimulinkBlockHandle(BUS_W(i)) ~= -1
        set_param(BUS_W(i), 'OutputSignals', strjoin(SelRows, ','));
    else
        fprintf('Bloco não existe ainda: %s\n', BUS_W(i));
    end

    if getSimulinkBlockHandle(blkW(i)) ~= -1 && getSimulinkBlockHandle(BUS_W(i)) ~= -1
        phW = get_param(blkW(i), 'PortHandles');
        phS = get_param(BUS_W(i), 'PortHandles');
        for k = 1:numel(phW.Inport)
            ln = get_param(phW.Inport(k), 'Line');
            if ln ~= -1, delete_line(ln); end
        end
        for k = 1:numel(phS.Outport)
            ln = get_param(phS.Outport(k), 'Line');
            if ln ~= -1, delete_line(ln); end
        end
        for k = 1:min(numel(phS.Outport), numel(phW.Inport))
            add_line(model_name, phS.Outport(k), phW.Inport(k), 'autorouting', 'smart');
        end
    end
end
%==========================================================================
