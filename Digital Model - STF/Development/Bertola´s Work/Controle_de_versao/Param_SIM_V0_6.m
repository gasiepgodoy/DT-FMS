%% Param_SIM_V0_6.m - parametros do Chart_SIM (FullFMS V0_6_0)
% Carregado pelo PreLoadFcn do modelo, depois dos BUS_CONFIG*.mat.
% Tempos em segundos. "ladder" = valor exato do programa do CLP;
% "Historian" = media medida em "Historian Program Cycles" (19 arquivos).

% Passo de amostragem do Chart_SIM (multiplo do FixedStep 0.01 do modelo)
Ts_SIM = 0.05;

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
t_conv  = 5;        % carro chamado -> carro na parada 29 (provisorio)
t_leave = 2;        % CRoute_Out -> carro sai da parada 29 (provisorio)

% --- Sorting e cenario ---
t_sort_clear = 3;   % tempo ate a Sorting levar a peca (provisorio)
N_PARTS = 3;        % numero de pecas a simular
