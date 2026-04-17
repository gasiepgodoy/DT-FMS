run('Tags.m');
load('Tags_OPCUA.mat');
modelo_name = "FullFMS_2025_12_15_V0_3_6";
chave = "C:/ssh_keys/MatOFI_lab_id_rsa";
%==========================================================================
usuario = 'root';
ip = ["200.145.26.202", "200.145.26.213", "200.145.26.213", "200.145.26.203", "200.145.26.204",...
"200.145.26.205", "200.145.26.206", "200.145.26.207", "200.145.26.208"];
%==========================================================================
bancadas = ["Master", "Storage", "Robot", "Handling1", "Sorting", "Testing", ...
    "Distribution", "Handling2", "Processing"];
%==========================================================================
path1 = '/root/ProjetoGemeo/AAS/';
path2 = '/Variables.csv';
arquivo_remoto = path1 + bancadas + path2;
%==========================================================================
path3 = 'Variables_';
path4 = ["Master", "Storage", "Robot", "Handling1", "Sorting", "Testing", ...
    "Distribution", "Handling2", "Processing"];
path5 = '.csv';
arquivo_local = path3 + path4 + path5;
%==========================================================================
name1 = modelo_name + "/OPC UA Read-";
name2 = ["MASTER", "NODE", "HD1", "SORT", "TEST", "DIST", "HD2", "PROC"];
blk = name1 + name2;
%==========================================================================
for i=1:numel(ip)
    cmd = sprintf('scp -i "%s" %s@%s:"%s" "%s"', chave, usuario, ip(i), arquivo_remoto(i), arquivo_local(i));
    [status, cmdout] = system(cmd);
    if status == 0
        disp('Download concluído via SCP externo!');
    else
        disp('Erro ao executar SCP:');
        disp(cmdout);
    end
 end
%==========================================================================
BUS_SLC = ["BUS_MASTER", "BUS_NODE", "BUS_HD1", "BUS_SORT", "BUS_TEST",...
    "BUS_DIST", "BUS_HD2", "BUS_PROC"];
BUS_IN = modelo_name +"/"+ BUS_SLC;
%==========================================================================
T1 = readtable("Variables_Master.csv");
T2 = readtable("Variables_Storage.csv");
T3 = readtable("Variables_Robot.csv");
T4 = readtable("Variables_Handling1.csv");
T5 = readtable("Variables_Sorting.csv");
T6 = readtable("Variables_Testing.csv");
T7 = readtable("Variables_Distribution.csv");
T8 = readtable("Variables_Handling2.csv");
T9 = readtable("Variables_Processing.csv");

T = [T1;T2;T3;T4;T5;T6;T7;T8;T9];
Var1_limpo = erase(T.Var1,';ns');
%==========================================================================
for i = 1:numel(AllVariables)

    NodeRows = strings(0);
    IdentRows = string(0);
    ns = 6;
    cnt = 1;

    for k = 1:numel(AllVariables{i})

        tags_secao = string(AllVariables{i}{k});
        if isempty(tags_secao), continue; end

        idx = ismember(Var1_limpo, tags_secao);
        Identifiers = T.Var3(idx);

        for l = 1:numel(Identifiers)
            NodeRows(cnt) = sprintf("'%d','Value','%d','%d','1'", ...
                                    cnt, ns, Identifiers(l));
            IdentRows(cnt) = sprintf("Value_%d", Identifiers(l));
            cnt = cnt + 1;
        end
    end

    NodeListStr = "{ " + strjoin(NodeRows,"; ") + " }";
    disp("=============="+name2(i)+"=================");
    disp(NodeListStr);
    disp(IdentRows);
    disp("==========================================");
    set_param(blk(i),'NodeList',NodeListStr);
    set_param(BUS_IN(i), 'OutputSignals', strjoin(IdentRows, ','));
end
%==========================================================================
