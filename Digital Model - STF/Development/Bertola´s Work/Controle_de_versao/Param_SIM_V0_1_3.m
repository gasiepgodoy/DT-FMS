%% Param_SIM_V0_1_3.m - parametros do Chart_SIM (FullFMS_SIM V0_1_3)
% Carregado pelo PreLoadFcn do modelo, depois do BUS_CONFIG_SIM.mat.
% Base: Param_SIM_V0_1_2.m (Handling 1 + parada 29 + Sorting [60]) + Testing [70] + parada 24.
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
% A Testing usa PART_COLORS como a sequencia de pecas que a Distribution entrega (ver DIST_Feed).
% PROVISORIO (sai quando a Distribution [80] entrar no SIM): C_85_Initialization da Distribution
DIST_INIT_PROV = 1;

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

% --- DIST_Feed_PROVISORIO (Distribution [80] ainda nao existe no SIM) ---
t_dist_feed    = 10.15; % A_74_CRoute_In80 / C_75_RQ_Wrong -> O_70_SPart (Historian ~10.1-10.2 s, mediana)
t_dist_sst     = 0.19;  % O_70_SStation liga 0.19 s antes do O_70_SPart (n=22), dura 1.09 s
t_dist_sst_dur = 1.09;
t_dist_arm     = 1.87;  % O_70_SPart -> O_80_Arm_Mag volta (n=22); antes disso o elevador nao sobe
