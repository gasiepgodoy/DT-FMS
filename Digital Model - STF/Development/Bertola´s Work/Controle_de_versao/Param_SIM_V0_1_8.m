%% Param_SIM_V0_1_8.m - parametros do Chart_SIM (FullFMS_SIM V0_1_8)
% Carregado pelo PreLoadFcn do modelo, depois do BUS_CONFIG_SIM.mat.
% Base: Param_SIM_V0_1_7.m (todas as estacoes) + MASTER [20]: esteira completa (FB11 + FB2), Vision [26] e supervisorio.
% Os parametros t_24_*, t_25_*, t_27_*, t_28_*, T_CONV*_T* e t_conv/t_leave das paradas simplificadas nao sao mais usados (ficam para comparacao).
% Tempos em segundos. "ladder" = valor exato do programa do CLP;
% "Historian" = media medida em "Historian Program Cycles" (19 arquivos);
% "estimado" = nao deu para medir.

% Passo de amostragem do Chart_SIM (multiplo do FixedStep 0.01 do modelo)
Ts_SIM = 0.05;

%% ===================== Handling 1 [50] + parada 29 =====================
% --- Temporizadores do ladder (exatos) ---
T_HD1_T1  = 2;      % Hd1 FB4 T1 S_PEXT: pulso do CRoute_Out (Historian confirma ~1.9 s)
T_CONV_T6 = 3;      % Master FB11 T6 SE: carro parado na 29 ate CartDel

% --- Tempos fisicos do Handling 1 (Historian, media) ---
t_v_down = 0.93;    % F_52_Claw_Down sobe   -> O_50_Claw_Low  (n=38, 0.82..0.98)
t_v_up   = 1.37;    % F_52_Claw_Down desce  -> O_50_Claw_High (n=38, 1.25..1.44)
t_h_del  = 2.82;    % F_52_Claw_2_Del       -> O_50_Claw_Del  (n=19, 2.67..3.73)
t_h_cart = 2.38;    % F_52_Claw_2_Cart      -> O_50_Claw_Cart (n=19, 2.19..3.16)
t_grip   = 0.10;    % F_52_Close_Claw -> O_50_Part_in_Claw (medido 0.01/0.08 s; usa 2*Ts_SIM)
t_v = (t_v_down + t_v_up)/2;   % medias, so para referencia
t_h = (t_h_del + t_h_cart)/2;

% --- Esteira, parada 29 (estimados; Historian nao isola o transporte) ---
t_conv  = 5;        % carro chamado -> carro na parada 29 (estimado)
t_leave = 2;        % CRoute_Out -> carro sai da parada 29 (estimado)

%% ============================ Sorting [60] =============================
% --- Setup escrito pelo supervisorio (C_65_xxx_Output) ---
% 1 = RBS (FB4), 2 = RSB (FB5), 3 = BRS (FB6), 4 = BSR (FB7), 5 = SRB (FB8), 6 = SBR (FB9)
SORT_MODE = 1;

% Cores: 1 = vermelha (ID_1=1, ID_2=1), 2 = preta (1,0), 3 = metalica/prata (0,1); 0 = sem peca (0,0)
% Destino por modo, lido do N3 de cada FB: [cor na alavanca 1, cor na alavanca 2, cor que passa direto]
SORT_MAP = [1 2 3    % FB4 RBS
            1 3 2    % FB5 RSB
            2 1 3    % FB6 BRS (N3 da alavanca 2 le o FB5_PartDel M1.4 -- erro do ladder, mantido)
            2 3 1    % FB7 BSR
            3 1 2    % FB8 SRB
            3 2 1];  % FB9 SBR (N4 le "T11" no ladder -- tratado como T6)

% --- Cenario ---
N_PARTS = 3;                 % numero de pecas a simular
PART_COLORS = [1 2 3];       % cor de cada peca, na ordem de chegada (tamanho N_PARTS)

% --- Temporizadores do ladder (exatos) ---
T_SORT_ID = 2;      % FB4..FB9 T1..T6 SE (pulso prolongado) S5T#2S: janela de identificacao
                    % (Historian: F_62_Conveyor -> F_62_P1/P2 = 1.92 s, n=14)
T_SORT_T7 = 4;      % OB1 N10 T7 SE S5T#4S na borda NEG do Part_Pass -> C_65_Part_Sorted
                    % (Historian: Part_Sorted ligado 3.98 s, n=19). FB1 nao usa temporizador.

% --- Tempos fisicos da Sorting (Historian, media; tempo de esteira ligada) ---
t_s_spart_off = 0.135; % F_62_Conveyor -> O_60_SPart cai (mediana, n=19)
t_s_photo     = 0.14;  % F_62_Conveyor -> O_60_SPhoto (n=12; vermelha e metalica)
t_s_ind       = 0.26;  % F_62_Conveyor -> O_60_SInd   (n=5; so metalica)
t_s_ind_off   = 0.12;  % F_62_Identify -> O_60_SInd cai   (n=5)
t_s_photo_off = 0.19;  % F_62_Identify -> O_60_SPhoto cai (n=12)
t_s_pass1     = 1.98;  % F_62_Identify -> O_60_Part_Pass, saida pela alavanca 1 (n=7, 1.87..2.11)
t_s_pass2     = 2.57;  % F_62_Identify -> O_60_Part_Pass, saida pela alavanca 2 (n=7, 2.48..2.64)
t_s_pass3     = 2.87;  % F_62_Identify -> O_60_Part_Pass, passa direto (n=5, 2.83..2.92)
t_s_pp        = 0.15;  % duracao do pulso O_60_Part_Pass (n=19, 0.11..0.17)
t_sl1_fwd     = 0.42;  % F_62_P1 sobe  -> O_60_SL1_Fwd (n=7, 0.37..0.50)
t_sl1_bck     = 0.25;  % F_62_P1 desce -> O_60_SL1_Bck (n=7, 0.23..0.29)
t_sl2_fwd     = 0.14;  % F_62_P2 sobe  -> O_60_SL2_Fwd (n=7, 0.11..0.22)
t_sl2_bck     = 0.32;  % F_62_P2 desce -> O_60_SL2_Bck (n=7, 0.29..0.37)
% Referencias (nao usados como parametro, saem da simulacao):
%   O_50_Claw_Del -> O_60_SPart 1.00 s (n=19); O_60_SPart -> F_62_Conveyor 1.44 s (n=19);
%   esteira ligada 4.62 s por peca (n=19); Part_Pass -> esteira desliga 0.04 s.

%% ============================ Testing [70] =============================
% --- Setup escrito pelo supervisorio ---
TEST_MODE = 1;               % 1 = Identified Delivery (FB4), 2 = Requested Delivery (FB5)
% Pedido de cada carro no modo Requested: [C_75_RQ_Delivery1 C_75_RQ_Delivery2], uma linha por carro
% (mesma tabela de bits: [1 1] vermelha, [1 0] preta, [0 1] metalica)
RQ_DELIVERY = [1 1; 1 0; 0 1];
% PART_COLORS = ordem das pecas no magazine da Distribution (a de baixo sai primeiro).

% --- Temporizadores do ladder (exatos) ---
T_TEST_T1 = 4;      % FB1 N3 T1 SE S5T#4S: pulso do pistao para tirar peca residual
T_TEST_T2 = 2;      % FB4 N4 / FB5 N4 T2 S_ODT S5T#2S: identificacao no alto (Historian: Elev_High -> Eject 1.99 s, n=19)
T_TEST_T8 = 0.5;    % FB5 N4 T8 S_PEXT S5T#500MS: janela de leitura da cor no Requested
T_TEST_T3 = 2;      % FB4 N5 T3 SP S5T#2S: pulso do pistao de ejecao para o carro (cai antes com A_74_Optic)
T_TEST_T5 = 2;      % FB5 N6 T5 SP S5T#2S: idem no Requested (peca certa)
T_TEST_T6 = 2;      % FB5 N8 T6 SP S5T#2S: ejecao da peca errada embaixo (Historian: 1.9 s, n=3)
T_TEST_T7 = 2;      % OB1 N6 T7 S_PEXT S5T#2S: A_74_CRoute_Out (Historian: 1.91 s, n=19)
T_CONV24_T1 = 3;    % Master FB11 N6 T1 SE S5T#3S: C_24_CartDel (Historian: 2.96 s)

% --- Tempos fisicos da Testing (Historian, media) ---
t_t_up         = 3.28;  % F_72_Elev_Up -> O_70_Elev_High (n=22, 3.06..3.57)
t_t_up_lowoff  = 0.85;  % F_72_Elev_Up -> O_70_Elev_Low cai (n=22)
t_t_up_ind     = 0.90;  % F_72_Elev_Up -> pulso O_70_SInductive na subida (n=14), dura 0.15 s
t_t_up_sst     = 1.33;  % F_72_Elev_Up -> pulso O_70_SStation na subida (n=22), dura 0.22 s
t_t_metal_off  = 1.08;  % peca metalica: O_70_SInductive fica ligado ate 1.08 s depois do F_72_Elev_Up (n=8)
t_t_height_pre = 0.31;  % O_70_SPart_Height liga 0.31 s antes do O_70_Elev_High (vermelha/metalica, n=15)
t_t_down       = 2.82;  % F_72_Elev_Down -> O_70_Elev_Low (mediana, n=19; com peca errada 2.93 s, n=3)
t_t_down_highoff = 0.07;% F_72_Elev_Down -> O_70_Elev_High cai (n=18)
t_t_down_sst   = 1.73;  % F_72_Elev_Down -> pulso O_70_SStation na descida (n=22), dura 0.27 s
t_t_down_ind   = 2.39;  % F_72_Elev_Down -> pulso O_70_SInductive na descida (n=22), dura 0.18 s
t_t_ej_spart   = 0.17;  % F_72_Eject_Part -> O_70_SPart cai (n=19; embaixo 0.135 s, n=3)
t_t_pist_fwd   = 0.14;  % F_72_Eject_Part -> O_70_Pist_Back cai (n=19)
t_t_pist_back  = 0.29;  % F_72_Eject_Part desce -> O_70_Pist_Back (n=19)
t_t_ej_cart    = 1.21;  % F_72_Eject_Part -> O_24_Optic (peca chega ao carro, n=19)

% --- Parada 24 (Master FB11, destino Testing; Historian, media) ---
t_24_arrive    = 10.51; % C_24_Request -> O_24_Cart_Stat (n=19)
t_24_count     = 1.04;  % O_24_Count -> O_24_Cart_Stat (n=16)
t_24_req       = 2.0;   % duracao do C_24_Request (Historian 01: 1.96 s)
t_24_croute_in0 = 0.13; % O_24_Cart_Stat -> A_74_CRoute_In (n=19)
t_24_croute_in = 1.80;  % duracao do A_74_CRoute_In (n=38)
t_24_pist_bck  = 0.43;  % A_74_CRoute_Out -> O_24_Pist_Bck (n=19)
t_24_optic_off = 1.38;  % A_74_CRoute_Out -> O_24_Optic cai (n=19)
t_24_leave     = 2.69;  % A_74_CRoute_Out -> O_24_Cart_Stat cai (n=19)

%% ========================== Distribution [80] ==========================
% --- Setup escrito pelo supervisorio ---
DIST_MODE = 1;      % 1 = Single (FB4), 2 = Continuous (FB5), 3 = Counted (FB6)
RQ_PARTS  = 2;      % C_83_RQ_Parts (modo Counted)
MAG_PARTS0 = 9;     % pecas no magazine no inicio (9 = cheio: O_80_Mag_Full liga e o FB1 conhece a contagem)
MAG_CAP    = 9;     % capacidade do magazine (OB1 N4: C1 pre-carregado com C#9)

% --- Temporizadores do ladder (exatos) ---
T_DIST_T1 = 5;      % OB1 N4 T1 S_ODT S5T#5S: Mag_Full por 5 s carrega o contador C1 com 9
T_DIST_T2 = 1;      % OB1 N4 T2 S_ODT S5T#1S: Pist_Back e Magazine_Empty por 1 s zeram o C1
T_DIST_T3 = 1;      % FB5 N3 / FB6 N4 T3 S5T#1S ("FB6_Timer", o mesmo nos dois FBs)
T_DIST_T4 = 4;      % OB1 N10 T4 SE S5T#4S -> C_85_Part_Del (Historian: 3.79 s, n=22)

% --- Tempos fisicos da Distribution (Historian, media) ---
t_d_a2d_empty   = 3.36; % F_82_Arm_2_Del -> O_80_Arm_Del, braco vazio (n=22)
t_d_a2d_load    = 3.27; % idem, com peca na ventosa (n=22)
t_d_magoff_empty= 1.85; % F_82_Arm_2_Del -> O_80_Arm_Mag cai, vazio (n=22)
t_d_magoff_load = 1.29; % idem, com peca (n=22)
t_d_a2m         = 2.01; % F_82_Arm_2_Mag -> O_80_Arm_Mag (n=44)
t_d_deloff      = 1.28; % F_82_Arm_2_Mag -> O_80_Arm_Del cai (n=44)
t_d_sst_off     = 1.07; % F_82_Arm_2_Mag -> O_70_SStation cai (braco sai de cima da Testing, n=44)
t_d_pist_fwd    = 0.905;% F_82_Pist_Adv -> O_80_Pist_Fwd (n=9; comando dura 0.94 s, n=22)
t_d_pist_bckoff = 0.33; % F_82_Pist_Adv -> O_80_Pist_Back cai (n=22)
t_d_pist_back   = 0.11; % F_82_Pist_Adv cai -> O_80_Pist_Back (n=22)
t_d_suct        = 0.11; % F_82_Suction_On -> O_80_Part_Stuck (n=21)
t_d_release     = 0.22; % ventosa desliga no Arm_Del -> O_80_Part_Stuck cai e O_70_SPart liga (n=22)

%% =========================== Processing [100] ===========================
% --- Setup escrito pelo supervisorio ---
PROC_MODE = 1;          % 1 = Test (FB4), 2 = Test + Drill (FB5), 3 = Rotation only (FB6)
PROC_TEST_OK = [1 1 1]; % resultado do teste (O_100_PTest_Ok) de cada peca que chega a mesa: 1 = Ok, 0 = Fail
RQ_TURNS = 1;           % C_103_RQ_Turns (escrito no bus; o FB6 do ladder usa C#6 fixo e nao le este valor)

% --- Temporizadores do ladder (exatos) ---
T_PROC_T4 = 2;      % FB4/FB5 N3 T4 SP S5T#2S: pulso do pino de teste
T_PROC_T5 = 1;      % FB4/FB5 N5 T5 S_ODT S5T#1S: leitura do teste (Historian: Test_Pin -> C_105_Test_Ok 0.99 s, n=17)
T_PROC_T8 = 2;      % FB5 N9 T8 SP S5T#2S: broca ligada (Historian: Drill_On 1.99 s, n=2)
% Contadores da mesa (ladder exato): FB4 C4 = 4 passos ate o teste, C5 = 2 ate a coleta; FB5 C7 = 1 ate a broca,
% C8 = 1 ate o fim, C9 = 2 ate o fim se falhou; FB6 C10 = 6 (volta inteira); FB1 C1 = 3 (meia volta)

% --- Tempos fisicos da Processing (Historian, media) ---
t_rt_step    = 1.13;    % passo da mesa: borda do O_100_RT_Sensor a cada 1.13 s com RT_On (n=76; 1a borda 1.12 s, n=38)
t_rt_hi      = 0.13;    % O_100_RT_Sensor cai 0.13 s depois de sair da posicao (Historian 01; estimado, duracao varia 0.06..1.2 s)
t_ptest_ok   = 0.06;    % F_102_Test_Pin -> O_100_PTest_Ok (n=17)
t_drill_down = 0.21;    % F_102_Drill_Down -> O_100_SDrill_Low (n=2)
t_drill_up   = 0.29;    % F_102_Drill_Up -> O_100_SDrill_High (duracao do Drill_Up, n=2)

%% ============================ Handling 2 [90] ============================
% --- Setup escrito pelo supervisorio ---
HD2_CART2DEL = 1;   % C_95_Cart2Del: leva a peca do carro para a Processing
HD2_DEL2CART = 1;   % C_95_Del2Cart: devolve a peca da Processing para o carro

% --- Temporizadores do ladder (exatos) ---
T_HD2_T1    = 2;    % OB1 N8 T1 S_PULSE S5T#2S: A_94_CRoute_Out (Historian: 1.95 s, n=19)
T_CONV25_T1 = 3;    % Master FB11 destino Processing, mesmo padrao do destino Testing (Historian C_25_CartDel 2.90 s, n=19)

% --- Tempos fisicos da garra do Hd2 (Historian, media) ---
t_c2_down    = 0.75;  % F_92_Claw_Down -> O_90_Claw_Low (n=76)
t_c2_highoff = 0.135; % F_92_Claw_Down -> O_90_Claw_High cai (n=76)
t_c2_up      = 0.97;  % F_92_Claw_Down cai -> O_90_Claw_High (n=76)
t_c2_lowoff  = 0.17;  % F_92_Claw_Down cai -> O_90_Claw_Low cai (n=76)
t_c2_2del    = 3.65;  % F_92_Claw_2_Del -> O_90_Claw_Del (n=19)
t_c2_2cart   = 2.59;  % F_92_Claw_2_Cart -> O_90_Claw_Cart (n=19)
t_c2_cartoff = 0.40;  % F_92_Claw_2_Del -> O_90_Claw_Cart cai (n=19)
t_c2_deloff  = 0.30;  % F_92_Claw_2_Cart -> O_90_Claw_Del cai (n=19)
t_c2_res_del = 1.78;  % pulso do O_90_Claw_Reserve na ida (n=19)
t_c2_res_cart= 1.67;  % pulso do O_90_Claw_Reserve na volta (n=18)
t_c2_res_dur = 0.07;  % duracao do pulso (n=37)
t_c2_grip    = 0.05;  % F_92_Close_Claw -> O_90_Part_in_Claw (Historian: mesmo instante; usado 1 passo)
t_c2_open    = 0.225; % F_92_Close_Claw cai -> O_90_Part_in_Claw cai (n=38)

% --- Parada 25 (Master FB11 destino Processing; Historian, media) ---
t_25_arrive     = 10.27; % C_25_Request -> O_25_Cart_Stat (n=19)
t_25_req        = 2.0;   % duracao do C_25_Request (Historian 01)
t_25_croute_in0 = 0.17;  % O_25_Cart_Stat -> A_94_CRoute_In (n=19)
t_25_croute_in  = 1.87;  % duracao do A_94_CRoute_In (n=19)
t_25_pist_bck   = 0.40;  % A_94_CRoute_Out -> O_25_Pist_Bck (n=19)
t_25_optic_off  = 1.50;  % A_94_CRoute_Out -> O_25_Optic cai (n=19)
t_25_leave      = 2.68;  % A_94_CRoute_Out -> O_25_Cart_Stat cai (n=19)

%% ============================ NODE: Robot [30] + Storage [40] ============================
% --- Setup escrito pelo supervisorio (Config Setups.xlsx: Config 1 = Routine 1 / Store; 2 e 3 = Routine 2 / Retrieve) ---
ROBOT_MODE = 1;     % 1 = C_30_Robot1, 2 = C_30_Robot2
STOR_MODE  = 1;     % 1 = C_45_StorePart (FB4), 2 = C_45_RetrievePart (FB5)

% --- Temporizadores do ladder (exatos) ---
T_ROB_T7  = 5;      % Master FB3 N12 T7 S_PEXT 5 s (Historian: o CartDel acaba junto com o A_34_CRoute_In, 1.86 s)
T_ROB_T8  = 2;      % Master FB3 N14 T8 S_ODT 2 s: A_34_CRoute_Out (Historian 1.96 s, n=19)
T_STOR_T1 = 3;      % Storage FB4 T1 S_PEXT 3 s (Historian CRoute_In -> CRoute_Out 3.08 s na Config 1)
T_STOR_T2 = 5;      % Storage FB5 T2 S_PEXT 5 s (Historian 5.18 s na Config 2)
T_STOR_T3 = 2;      % Storage OB1 N7 T3 S_PULSE 2 s: A_44_CRoute_Out (Historian 2.00 s, n=19)
T_CONV27_T1 = 3;    % Master FB11 destino Robot (Historian C_27_CartDel 2.85 s)
T_CONV28_T1 = 3;    % Master FB11 destino Storage (mesmo padrao; O_28 nao esta no Historian)

% --- Parada 27 (Robot; Historian, media, n=19) ---
t_27_travel     = 24.66; % C25_Gone -> A_34_Cart_Stat (Historian A_94_CRoute_Out -> A_34_Cart_Stat 27.34 s - 2.68 s) -- INCLUI a parada da Vision [26] (sai na v0.1.8)
t_27_optic_stat = 0.23;  % A_34_Optic -> A_34_Cart_Stat
t_27_croute_in0 = 0.18;  % A_34_Cart_Stat -> A_34_CRoute_In
t_27_croute_in  = 1.86;  % duracao do A_34_CRoute_In
t_27_pist_bck   = 0.54;  % A_34_CRoute_Out -> A_34_Pist_Bck
t_27_optic_off  = 1.67;  % A_34_CRoute_Out -> A_34_Optic cai
t_27_leave      = 2.83;  % A_34_CRoute_Out -> A_34_Cart_Stat cai

% --- Parada 28 (Storage; Historian, media, n=19) ---
t_28_travel     = 7.08;  % A_34_Cart_Stat cai -> A_44_Cart_Stat (n=24)
t_28_optic_stat = 0.26;  % A_44_Optic -> A_44_Cart_Stat
t_28_croute_in0 = 0.18;  % A_44_Cart_Stat -> A_44_CRoute_In
t_28_croute_in  = 1.86;  % duracao do A_44_CRoute_In
t_28_pist_bck   = 0.42;  % A_44_CRoute_Out -> A_44_Pist_Bck
t_28_optic_off  = 1.19;  % A_44_CRoute_Out -> A_44_Optic cai
t_28_leave      = 2.56;  % A_44_CRoute_Out -> A_44_Cart_Stat cai

%% ============================ MASTER [20]: esteira (FB11 + FB2), Vision, supervisorio ============================
% Indice das paradas nos vetores: [24 25 26 27 28 29]. Um carro (Historian: sempre o carro 2).
CART_ID = 2;          % numero do carro = pulsos do sensor Count (Historian: CartID 1 -> 2 antes de cada chegada)
T_FB11_T = 3;         % FB11 N6 T SE (S_PEXT) 3 s -> C_2N_CartDel (Historian 2.89..2.95 s, n=19 por parada)

% --- trechos da esteira, por parada de ORIGEM (24->25, 25->26, 26->27, 27->28, 28->29, 29->24); Historian, mediana, n=19 ---
T_HOP_ARR     = [10.02 10.41 10.63  8.72 11.58 10.25]; % Release_FB da origem -> Cart_Stat do destino
T_HOP_STATOFF = [ 2.35  2.38  2.34  2.22  2.22  2.24]; % Release_FB -> Cart_Stat da origem cai
T_HOP_OPTOFF  = [ 1.05  1.20  1.11  0.98  0.86  1.00]; % Release_FB -> Optic da origem cai (29->24: carro vazio, estimado)
T_HOP_NEXT    = [ 8.03  8.60  8.10  6.34 10.33  8.58]; % Release_FB -> Cart_Next da origem
T_HOP_NEXTDUR = [ 0.98  0.99  1.58  1.01  0.23  0.98]; % duracao do Cart_Next
% --- por parada de DESTINO ---
T_OPT_ON = [0.25 0.23 0.20 0.24 0.29 0.33];  % Optic sobe antes do Cart_Stat (24: carro vazio, estimado)
T_CNT    = [1.04 1.12 1.12 1.17 1.21 1.22];  % primeiro pulso do Count antes do Cart_Stat
t_cnt_per   = 0.07;   % periodo dos pulsos do Count (Historian: CartID 1 -> 2 em 0.07 s)
t_cnt_pulse = 0.04;   % largura do pulso

% --- pinos (pistao de parada) ---
t_pin_bck = 0.10;     % Release_FB -> Pist_Bck (n=114)
t_pin_fwd = 0.12;     % Release_FB cai -> Pist_Bck cai (n=114)

% --- supervisorio (Node-RED; sem ladder: comportamento do Historian) ---
t_mes_start  = 4;     % primeiro C_24_Request (apos a inicializacao das estacoes)
t_mes_req    = 0.08;  % A_x4_CRoute_Out -> C_proximo_Request (0.04..0.11 s)
t_opc        = 0.24;  % C_2N_Request -> Release_FB (latencia OPC UA + ciclo do CLP; n=114)
t_mes_reqdur = 2.0;   % duracao do C_2N_Request
t_mes_cri0   = 0.17;  % C_2N_CartDel -> C_2N_CRoute_In
t_mes_cri    = 1.86;  % duracao do C_2N_CRoute_In
t_vis        = 5.04;  % Vision: O_26_Cart_Stat -> C_27_Request (n=19)
