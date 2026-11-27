function build_chart_sim_V0_1_2(ch, doLog)
% Popula um Stateflow.Chart vazio com o Chart_SIM da FullFMS_SIM V0_1_2:
% Conveyor29 + HD1_Ctrl + HD1_Plant (V0_1_0) + SORT_Plant + SORT_Ctrl (Sorting [60]).
if nargin < 2, doLog = false; end
ch.ActionLanguage = 'MATLAB';
ch.Decomposition  = 'PARALLEL_AND';
ch.ChartUpdate    = 'DISCRETE';
ch.SampleTime     = 'Ts_SIM';

outs = {'SimActuators_20','SimControl_20','SimSensors_20','SimActuators_50', ...
        'SimASi_50','SimControl_50','SimSensors_50', ...
        'SimActuators_60','SimControl_60','SimSensors_60'};
for i = 1:numel(outs)
    d = Stateflow.Data(ch); d.Name = outs{i}; d.Scope = 'Output';
    d.DataType = ['Bus: B_' outs{i}]; d.Port = i;
end
pars = {'Ts_SIM','T_HD1_T1','T_CONV_T6','t_v_down','t_v_up','t_h_del','t_h_cart','t_grip', ...
        't_conv','t_leave','N_PARTS', ...
        'SORT_MODE','T_SORT_ID','T_SORT_T7','t_s_spart_off','t_s_photo','t_s_ind', ...
        't_s_ind_off','t_s_photo_off','t_s_pass1','t_s_pass2','t_s_pass3','t_s_pp', ...
        't_sl1_fwd','t_sl1_bck','t_sl2_fwd','t_sl2_bck'};
for i = 1:numel(pars)
    d = Stateflow.Data(ch); d.Name = pars{i}; d.Scope = 'Parameter'; d.DataType = 'double';
end
for p = {'PART_COLORS','SORT_MAP'}
    d = Stateflow.Data(ch); d.Name = p{1}; d.Scope = 'Parameter'; d.DataType = 'double';
    d.Props.Array.Size = '-1';
end
locB = {'PartOnCart','CartAt29','CRouteIn54','Claw2CartCmd', ...
        'FB1Init','FB1Conv','FB1IDPin','FBSel','ConvOn60','TrigConv','Lever1','Lever2','PassStr','PinSort','PartDel'};
for i = 1:numel(locB)
    d = Stateflow.Data(ch); d.Name = locB{i}; d.Scope = 'Local'; d.DataType = 'boolean';
    d.Props.InitialValue = 'false';
    if doLog, d.LoggingInfo.DataLogging = true; end
end
locD = {'nCart','nDone','nSortIn','sortColor','sortExit','cID','xSort'};
for i = 1:numel(locD)
    d = Stateflow.Data(ch); d.Name = locD{i}; d.Scope = 'Local'; d.DataType = 'double';
    d.Props.InitialValue = '0';
    if doLog, d.LoggingInfo.DataLogging = true; end
end

S20='SimSensors_20.'; A20='SimActuators_20.'; C20='SimControl_20.';
A50='SimActuators_50.'; R50='SimASi_50.'; C50='SimControl_50.'; S50='SimSensors_50.';
A60='SimActuators_60.'; C60='SimControl_60.'; S60='SimSensors_60.';
nl = newline;

W = 520; % largura dos estados de topo
%% (a) Conveyor29 -------------------------------------------------------
P = mkPar(ch,'Conveyor29',[0 0 W 760],1);
st = {
 'Idle',      ['entry: ' S20 'SS_29_Cart_Stat=false; ' S20 'SS_29_Optic=false; ' S20 'SS_29_Cart_Next=false;']
 'Arriving',  ['entry: ' S20 'SS_29_Cart_Next=true; ' A20 'SA_20_Conveyor=true; ' S20 'SS_20_Controler_On=true;']
 'AtStop',    ['entry: ' S20 'SS_29_Cart_Next=false; ' S20 'SS_29_Count=true; ' S20 'SS_29_Cart_Stat=true; ' S20 'SS_29_Optic=true;' nl 'PartOnCart=true; CartAt29=true; ' A20 'SA_20_Conveyor=false;']
 'Delivered', ['entry: ' S20 'SS_29_Count=false; ' C20 'SC_29_CartDel=true; CRouteIn54=true; ' R50 'SR_54_CRoute_In=true;' nl 'during: ' S20 'SS_29_Optic = PartOnCart;']
 'Leaving',   ['entry: ' C20 'SC_29_CartDel=false; CRouteIn54=false; ' R50 'SR_54_CRoute_In=false; CartAt29=false;']
};
H = colStates(P, st, doLog);
mkDef(P,H{1});
mkTr(P,H{1},H{2},'[nCart < N_PARTS]');
mkTr(P,H{2},H{3},'after(t_conv,sec)');
mkTr(P,H{3},H{4},'after(T_CONV_T6,sec)');
mkTr(P,H{4},H{5},['[' R50 'SR_54_CRoute_Out]']);
mkTr(P,H{5},H{1},'after(t_leave,sec)');

%% (b) HD1_Ctrl (ladder Hd1 FB4 Cart_2_Del, N1..N9) ----------------------
P = mkPar(ch,'HD1_Ctrl',[W+40 0 W+300 1500],2);
st = {
 'Init',         ['entry: ' C50 'SC_52_Profibus=true; ' C50 'SC_55_PD_Sort=false; ' R50 'SR_54_CRoute_Out=false;' nl ...
                  A50 'SA_50_Claw_Down=false; ' A50 'SA_50_Close_Claw=false; ' A50 'SA_50_Claw_2_Del=false; ' A50 'SA_50_Claw_2_Cart=false;']
 'Ready',        ['entry: ' C50 'SC_55_Initialization=true;']
 'N1_StartMove', ['entry: ' C50 'SC_55_PD_Sort=false;']
 'N2_LowerClaw', ['entry: ' A50 'SA_50_Claw_Down=true;']
 'N3_CloseClaw', ['entry: ' A50 'SA_50_Close_Claw=true;']
 'N3_Raise',     ['entry: ' A50 'SA_50_Claw_Down=false;']
 'N4_Claw2Del',  ['entry: ' A50 'SA_50_Claw_2_Cart=false; ' A50 'SA_50_Claw_2_Del=true;']
 'N5_LowerClaw2',['entry: ' A50 'SA_50_Claw_Down=true;']
 'N6_Release',   ['entry: ' A50 'SA_50_Close_Claw=false;']
 'N6_Raise',     ['entry: ' A50 'SA_50_Claw_Down=false;']
 'N7_PDSort',    ['entry: ' C50 'SC_55_PD_Sort=true;']
 'N8_Claw2Cart', ['entry: ' A50 'SA_50_Claw_2_Del=false; ' A50 'SA_50_Claw_2_Cart=true; Claw2CartCmd=true;']
 'N9_CRouteOut', ['entry: ' A50 'SA_50_Claw_2_Cart=false; Claw2CartCmd=false; ' R50 'SR_54_CRoute_Out=true;' nl 'exit: ' R50 'SR_54_CRoute_Out=false; nCart = nCart + 1;']
};
H = colStates(P, st, doLog);
mkDef(P,H{1});
c = {
 ['[' S50 'SS_50_Claw_Cart && ' S50 'SS_50_Claw_High && ~' S50 'SS_50_Part_in_Claw]']
 ['[CRouteIn54 && CartAt29 && ' S20 'SS_29_Optic && ~' S60 'SS_60_SPart]']
 ['[~' C50 'SC_55_PD_Sort && ' S50 'SS_50_Claw_Cart && ' S50 'SS_50_Claw_High && ~' S50 'SS_50_Part_in_Claw]']
 ['[' S50 'SS_50_Claw_Cart && ' S50 'SS_50_Claw_Low]']
 ['[' S50 'SS_50_Part_in_Claw]']
 ['[' S50 'SS_50_Claw_High && ' S50 'SS_50_Part_in_Claw && ~' S50 'SS_50_Claw_Del]']
 ['[' S50 'SS_50_Claw_Del && ' S50 'SS_50_Claw_High && ' S50 'SS_50_Part_in_Claw]']
 ['[' S50 'SS_50_Claw_Del && ' S50 'SS_50_Claw_Low]']
 ['[~' S50 'SS_50_Part_in_Claw]']
 ['[' S50 'SS_50_Claw_Del && ' S50 'SS_50_Claw_High && ~' S50 'SS_50_Part_in_Claw]']
 ''
 ['[' S50 'SS_50_Claw_Cart]']
};
for i = 1:numel(c), mkTr(P,H{i},H{i+1},c{i}); end
mkTr(P,H{13},H{2},'after(T_HD1_T1,sec)');

%% (c) HD1_Plant (resposta fisica) -------------------------------------
P = mkPar(ch,'HD1_Plant',[2*W+380 0 2*W+60 900],3);
P.Decomposition = 'PARALLEL_AND';
w2 = W - 20;
V = mkSub(P,'Vertical',[P.Position(1)+10 40 w2 420],1);
H = colStates(V, {
 'High',      ['entry: ' S50 'SS_50_Claw_High=true; ' S50 'SS_50_Claw_Low=false;']
 'GoingDown', ['entry: ' S50 'SS_50_Claw_High=false;']
 'Low',       ['entry: ' S50 'SS_50_Claw_Low=true;']
 'GoingUp',   ['entry: ' S50 'SS_50_Claw_Low=false;']}, doLog);
mkDef(V,H{1});
mkTr(V,H{1},H{2},['[' A50 'SA_50_Claw_Down]']);
mkTr(V,H{2},H{3},'after(t_v_down,sec)');
mkTr(V,H{2},H{4},['[~' A50 'SA_50_Claw_Down]']);
mkTr(V,H{3},H{4},['[~' A50 'SA_50_Claw_Down]']);
mkTr(V,H{4},H{1},'after(t_v_up,sec)');
mkTr(V,H{4},H{2},['[' A50 'SA_50_Claw_Down]']);
Z = mkSub(P,'Horizontal',[P.Position(1)+w2+30 40 w2 420],2);
H = colStates(Z, {
 'AtCart', ['entry: ' S50 'SS_50_Claw_Cart=true; ' S50 'SS_50_Claw_Del=false;']
 'ToDel',  ['entry: ' S50 'SS_50_Claw_Cart=false;']
 'AtDel',  ['entry: ' S50 'SS_50_Claw_Del=true;']
 'ToCart', ['entry: ' S50 'SS_50_Claw_Del=false;']}, doLog);
mkDef(Z,H{1});
mkTr(Z,H{1},H{2},['[' A50 'SA_50_Claw_2_Del]']);
mkTr(Z,H{2},H{3},'after(t_h_del,sec)');
mkTr(Z,H{3},H{4},['[' A50 'SA_50_Claw_2_Cart]']);
mkTr(Z,H{4},H{1},'after(t_h_cart,sec)');
G = mkSub(P,'Gripper',[P.Position(1)+10 480 w2 400],3);
H = colStates(G, {
 'Empty',     ['entry: ' S50 'SS_50_Part_in_Claw=false;']
 'Gripping',  ''
 'Holding',   ['entry: ' S50 'SS_50_Part_in_Claw=true; PartOnCart=false;']
 'Releasing', ''}, doLog);
mkDef(G,H{1});
mkTr(G,H{1},H{2},['[' A50 'SA_50_Close_Claw && ' S50 'SS_50_Claw_Low && ' S50 'SS_50_Claw_Cart && PartOnCart]']);
mkTr(G,H{2},H{3},'after(t_grip,sec)');
mkTr(G,H{3},H{4},['[~' A50 'SA_50_Close_Claw && ' S50 'SS_50_Claw_Low]']);
% soltou na posicao de entrega = peca na entrada da esteira da Sorting (sensor real SPart)
mkTr(G,H{4},H{1},['after(t_grip,sec){' S60 'SS_60_SPart = ' S60 'SS_60_SPart || ' S50 'SS_50_Claw_Del;}']);

%% (d) SORT_Plant (Sorting [60], resposta fisica) ------------------------
x0 = 2*W+380 + 2*W+60 + 60 + 2700 + 60;   % SORT_Plant fica a direita do SORT_Ctrl
P = mkPar(ch,'SORT_Plant',[x0 0 1640 1100],5);
P.Decomposition = 'PARALLEL_AND';
P.LabelString = sprintf(['SORT_Plant\nentry: %sSS_60_SPart=false; %sSS_60_SInd=false; %sSS_60_SPhoto=false; %sSS_60_Part_Pass=false;\n' ...
    '%sSS_60_SL1_Bck=true; %sSS_60_SL1_Fwd=false; %sSS_60_SL2_Bck=true; %sSS_60_SL2_Fwd=false;\n' ...
    '%sSS_61_Key_Pos=true; %sSS_61_Start=false; %sSS_61_Stop=false; %sSS_61_Reset=false;\n' ...
    '%sSS_61_Panel_I4=false; %sSS_61_Panel_I5=false; %sSS_61_Panel_I6=false; %sSS_61_Panel_I7=false;'], ...
    S60,S60,S60,S60,S60,S60,S60,S60,S60,S60,S60,S60,S60,S60,S60,S60);
cv = [A60 'SA_60_Conveyor'];
K = mkSub(P,'Part',[x0+10 110 760 980],1);
H = colStates(K, {
 'Empty',     ['entry: ' S60 'SS_60_Part_Pass=false;']
 'AtEntry',   ['entry: sortColor = PART_COLORS(min(nSortIn+1, numel(PART_COLORS))); nSortIn = nSortIn + 1;']
 'ToStopper', ['entry: xSort = 0;' nl 'during: if ConvOn60, xSort = xSort + Ts_SIM; end' nl ...
               S60 'SS_60_SPart = xSort < t_s_spart_off;' nl ...
               'if xSort >= t_s_photo, ' S60 'SS_60_SPhoto = (sortColor ~= 2); end' nl ...
               'if xSort >= t_s_ind, ' S60 'SS_60_SInd = (sortColor == 3); end']
 'AtStopper', ''
 'Released',  ['entry: xSort = 0;' nl 'if ' S60 'SS_60_SL1_Fwd, sortExit = 1; elseif ' S60 'SS_60_SL2_Fwd, sortExit = 2; else, sortExit = 3; end' nl ...
               'during: if ConvOn60, xSort = xSort + Ts_SIM; end' nl ...
               'if xSort >= t_s_ind_off, ' S60 'SS_60_SInd = false; end' nl ...
               'if xSort >= t_s_photo_off, ' S60 'SS_60_SPhoto = false; end']
 'PartPass',  ['entry: ' S60 'SS_60_Part_Pass = true; ' S60 'SS_60_SInd = false; ' S60 'SS_60_SPhoto = false; nDone = nDone + 1;']
 }, doLog, true);
mkDef(K,H{1});
mkTr(K,H{1},H{2},['[' S60 'SS_60_SPart]']);
mkTr(K,H{2},H{3},['[' cv ']']);
mkTr(K,H{3},H{4},'[xSort >= t_s_ind]');
mkTr(K,H{4},H{5},['[' A60 'SA_60_Identify && ' cv ']']);
mkTr(K,H{5},H{6},'[(sortExit == 1 && xSort >= t_s_pass1) || (sortExit == 2 && xSort >= t_s_pass2) || (sortExit == 3 && xSort >= t_s_pass3)]');
mkTr(K,H{6},H{1},'after(t_s_pp,sec)');
for L = 1:2
    nm = sprintf('SL%d',L); pa = sprintf('%sSA_60_P%d',A60,L);
    Q = mkSub(P,['Lever' num2str(L)],[x0+790 110+(L-1)*490 830 470],1+L);
    H = colStates(Q, {
     [nm '_Bck'],   ['entry: ' S60 'SS_60_' nm '_Bck=true; ' S60 'SS_60_' nm '_Fwd=false;']
     [nm '_ToFwd'], ['entry: ' S60 'SS_60_' nm '_Bck=false;']
     [nm '_Fwd'],   ['entry: ' S60 'SS_60_' nm '_Fwd=true;']
     [nm '_ToBck'], ['entry: ' S60 'SS_60_' nm '_Fwd=false;']}, doLog, true);
    mkDef(Q,H{1});
    mkTr(Q,H{1},H{2},['[' pa ']']);
    mkTr(Q,H{2},H{3},sprintf('after(t_sl%d_fwd,sec)',L));
    mkTr(Q,H{2},H{4},['[~' pa ']']);
    mkTr(Q,H{3},H{4},['[~' pa ']']);
    mkTr(Q,H{4},H{1},sprintf('after(t_sl%d_bck,sec)',L));
    mkTr(Q,H{4},H{2},['[' pa ']']);
end

%% (e) SORT_Ctrl (ladder Sorting OB1 + FB1 + FB4..FB9 + FB3) -------------
x1 = 2*W+380 + 2*W+60 + 60;
P = mkPar(ch,'SORT_Ctrl',[x1 0 2700 1500],4);
P.Decomposition = 'PARALLEL_AND';
modes = {'RBS','RSB','BRS','BSR','SRB','SBR'};
s = sprintf('SORT_Ctrl\nentry: %sSC_62_Profibus=false; %sSC_65_Initialization=false; %sSC_65_ID_1=false; %sSC_65_ID_2=false; %sSC_65_Part_Sorted=false;\n', C60,C60,C60,C60,C60);
for i = 1:6, s = [s sprintf('%sSC_65_%s_Output = (SORT_MODE == %d); ', C60, modes{i}, i)]; end %#ok<AGROW>
acts = {'SA_60_Conveyor','SA_60_P1','SA_60_P2','SA_60_Identify','SA_61_Led_Start','SA_61_Led_Reset', ...
        'SA_61_Led_Extra1','SA_61_Led_Extra2','SA_61_Panel_O4','SA_61_Panel_O5','SA_61_Panel_O6','SA_61_Panel_O7'};
s = [s nl];
for i = 1:numel(acts), s = [s A60 acts{i} '=false; ']; end %#ok<AGROW>
s = [s nl 'FBSel = '];
for i = 1:6
    s = [s sprintf('(SORT_MODE == %d && %sSC_65_%s_Output)', i, C60, modes{i})]; %#ok<AGROW>
    if i < 6, s = [s ' || ']; else, s = [s ';']; end %#ok<AGROW>
end
P.LabelString = s;
% FB1 (Initialization, N1..N8)
F = mkSub(P,'FB1_Init',[x1+10 180 640 700],1);
H = colStates(F, {
 'FB1_N2_Check',    ['entry: ' C60 'SC_62_Profibus=true; FB1Init=false; ' C60 'SC_65_Initialization=false;']
 'FB1_N3_ClearPart',['entry: FB1Conv=true; FB1IDPin=true;']
 'FB1_N1_InitOk',   ['entry: FB1Init=true; ' C60 'SC_65_Initialization=true;']
 }, doLog, true);
mkDef(F,H{1});
mkTr(F,H{1},H{3},['[' C60 'SC_62_Profibus && ~FB1Conv && ~' S60 'SS_60_SPart && ~' S60 'SS_60_SInd && ~' S60 'SS_60_SPhoto && ~' S60 'SS_60_Part_Pass]']);
mkTr(F,H{1},H{2},['[' S60 'SS_60_SPart || ' S60 'SS_60_SInd || ' S60 'SS_60_SPhoto]']);
mkTr(F,H{2},H{1},['[FB1Conv && ' S60 'SS_60_Part_Pass]{FB1Conv=false; FB1IDPin=false;}']);
mkTr(F,H{3},H{1},['[' S60 'SS_61_Reset]{FB1Conv=false; FB1IDPin=false; TrigConv=false; Lever1=false; Lever2=false; PinSort=false; PartDel=false;}']);
% FB4..FB9 (bloco do modo ativo, N1..N5; selecao pelo OB1 N4..N9)
B = mkSub(P,'FB4_9_Sort',[x1+670 180 1000 1300],2);
H = colStates(B, {
 'OB1_N4_9_Select', ''
 'N1_StartConv',    ['entry: TrigConv=true; ' C60 'SC_65_ID_1=false; ' C60 'SC_65_ID_2=false;']
 'N2_Identify',     ['en, du: if ' S60 'SS_60_SInd, ' C60 'SC_65_ID_1=false; ' C60 'SC_65_ID_2=true;' nl ...
                     'elseif ' S60 'SS_60_SPhoto, ' C60 'SC_65_ID_1=true; ' C60 'SC_65_ID_2=true;' nl ...
                     'else, ' C60 'SC_65_ID_1=true; ' C60 'SC_65_ID_2=false; end']
 'N3_SelectLever',  ['entry: cID = 0;' nl 'if ' C60 'SC_65_ID_1 && ' C60 'SC_65_ID_2, cID = 1; elseif ' C60 'SC_65_ID_1, cID = 2; elseif ' C60 'SC_65_ID_2, cID = 3; end' nl ...
                     'Lever1 = (cID == SORT_MAP(SORT_MODE,1)); Lever2 = (cID == SORT_MAP(SORT_MODE,2)); PassStr = (cID == SORT_MAP(SORT_MODE,3));' nl ...
                     'during: if (Lever1 && ' S60 'SS_60_SL1_Fwd) || (Lever2 && ' S60 'SS_60_SL2_Fwd) || (PassStr && ' S60 'SS_60_SL1_Bck && ' S60 'SS_60_SL2_Bck), PinSort = true; end']
 'N4_PartDel',      ['entry: PartDel=true; Lever1=false;' nl 'if SORT_MODE ~= 3, Lever2=false; end']
 'N5_ResetNext',    'entry: TrigConv=false; PinSort=false; PartDel=false; Lever1=false; Lever2=false; PassStr=false;'
 }, doLog, true);
mkDef(B,H{1});
mkTr(B,H{1},H{2},['[FB1Init && FBSel && ' C50 'SC_55_PD_Sort && ' S50 'SS_50_Claw_Del]']);
mkTr(B,H{2},H{3},'');
mkTr(B,H{3},H{4},'after(T_SORT_ID - Ts_SIM,sec)');
mkTr(B,H{4},H{5},['[' S60 'SS_60_Part_Pass]']);
mkTr(B,H{5},H{6},'');
mkTr(B,H{6},H{1},'');
% OB1 N10/N11 (T7 SE 4 s na borda NEG do Part_Pass)
O = mkSub(P,'OB1_N10_11',[x1+1690 180 500 560],3);
H = colStates(O, {
 'N10_Wait',       ['entry: ' C60 'SC_65_Part_Sorted=false;']
 'N10_PartPass',   ''
 'N11_PartSorted', ['entry: ' C60 'SC_65_Part_Sorted=true;']
 }, doLog, true);
mkDef(O,H{1});
mkTr(O,H{1},H{2},['[' S60 'SS_60_Part_Pass]']);
mkTr(O,H{2},H{3},['[~' S60 'SS_60_Part_Pass]']);
mkTr(O,H{3},H{1},'after(T_SORT_T7,sec)');
% FB3 (OPC-UA Actuators: Key_Pos em automatico)
M = mkSub(P,'FB3_Actuators',[x1+1690 770 1000 700],4);
kp = [S60 'SS_61_Key_Pos'];
H = colStates(M, {
 'FB3_Map', ['during: ConvOn60 = ' kp ' && (TrigConv || FB1Conv); ' A60 'SA_60_Conveyor = ConvOn60;' nl ...
             A60 'SA_60_P1 = ' kp ' && Lever1; ' A60 'SA_60_P2 = ' kp ' && Lever2;' nl ...
             A60 'SA_60_Identify = ' kp ' && (PinSort || FB1IDPin);' nl ...
             A60 'SA_61_Led_Start = ' kp ' && FB1Init; ' A60 'SA_61_Led_Reset = ' kp ' && ' S60 'SS_61_Reset;' nl ...
             A60 'SA_61_Led_Extra1 = ' C60 'SC_65_Part_Sorted; ' A60 'SA_61_Led_Extra2 = false;' nl ...
             A60 'SA_61_Panel_O4 = false; ' A60 'SA_61_Panel_O5 = false; ' A60 'SA_61_Panel_O6 = false; ' A60 'SA_61_Panel_O7 = false;']
 }, doLog, true);
mkDef(M,H{1});
end

%% ---------------------------------------------------------------------
function s = mkPar(ch,name,pos,ord)
s = Stateflow.State(ch); s.Name = name; s.Position = pos; s.ExecutionOrder = ord;
end
function s = mkSub(p,name,pos,ord)
s = Stateflow.State(p); s.Name = name; s.Position = pos; s.ExecutionOrder = ord;
end
function H = colStates(P, st, doLog, newStyle)
% newStyle=false: geometria da V0_1_0 (HD1/Conveyor); true: altura pelo numero de linhas
if nargin < 4, newStyle = false; end
x0 = P.Position(1) + 60; y = P.Position(2) + 50;
if newStyle
    y = y + 16*numel(strfind(P.LabelString, newline));
    w = min(P.Position(3) - 120, 900); gap = 45;
else
    w = min(P.Position(3) - 120, 400); h = 60; gap = 45;
    if size(st,1) <= 4, gap = 35; h = 55; end
    if size(st,1) == 2, h = 50; end
end
if newStyle && size(st,1) <= 4, gap = 35; end
H = cell(size(st,1),1);
for i = 1:size(st,1)
    if newStyle
        nL = 1 + numel(strfind(st{i,2}, newline)) + ~isempty(st{i,2});
        h = max(50, 16*nL + 14);
    end
    s = Stateflow.State(P);
    if isempty(st{i,2}), s.LabelString = st{i,1};
    else, s.LabelString = [st{i,1} newline st{i,2}]; end
    s.Position = [x0 y w h];
    if doLog, s.LoggingInfo.DataLogging = true; end
    y = y + h + gap; H{i} = s;
end
need = y + 20 - P.Position(2);
if newStyle && need > P.Position(4)
    error('build_chart_sim:size','%s precisa de altura %d (tem %d)', P.Name, need, P.Position(4));
end
end
function mkDef(P,s)
t = Stateflow.Transition(P); t.Destination = s; t.DestinationOClock = 0;
t.SourceEndpoint = [s.Position(1)+s.Position(3)/2, s.Position(2)-25];
t.MidPoint = [s.Position(1)+s.Position(3)/2, s.Position(2)-12];
end
function mkTr(P,a,b,lbl)
t = Stateflow.Transition(P); t.Source = a; t.Destination = b;
if b.Position(2) > a.Position(2)        % para baixo: sai por baixo
    t.SourceOClock = 6; t.DestinationOClock = 12;
else                                    % retorno: pelo lado direito
    t.SourceOClock = 3; t.DestinationOClock = 3;
    t.MidPoint = [a.Position(1)+a.Position(3)+25, (a.Position(2)+b.Position(2)+b.Position(4))/2];
end
t.LabelString = lbl;
if b.Position(2) <= a.Position(2)
    lp = t.LabelPosition; mp = t.MidPoint;
    x = min(mp(1)+5, P.Position(1)+P.Position(3)-lp(3)-5);
    t.LabelPosition = [x mp(2)-lp(4)/2 lp(3) lp(4)];
end
if t.getParent ~= P
    error('build_chart_sim:parent','Transicao %s -> %s saiu do pai %s', a.Name, b.Name, P.Name);
end
end
