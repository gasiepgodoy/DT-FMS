# Sombra Digital - Full FMS (Stateflow)
Sombra digital do FMS controlado por CLP S7 (CPU 313C-2 DP), em Simulink/Stateflow.
O modelo apenas **observa** a planta: os barramentos `Sensors_*`, `Actuators_*`,
`Control_*` e `AS_i_*` entram no chart com escopo **Input** (somente leitura).
Desde a v0.5.0 existem blocos OPC UA Write para as variaveis simuladas (SS_/SA_/SC_/SR_/SID_),
ainda sem ligacao com o chart.
Pasta: `Digital Model - STF/`
---

---

# HISTORICO DE VERSOES

## v0.4.6 --> v0.4.7  (Sorting [60])
A Sorting nao tinha logica: os 6 blocos eram copias de outra estacao.
- Declaradas 30 variaveis `StatusXXX_1..5` (RBS, RSB, BRS, BSR, SRB, SBR) que nao existiam
- `Control_60.Identify_Pin` (campo inexistente E bus de entrada) --> leitura de `Actuators_60.F_62_Identify`
- `Sensors_60.SL1_Fwd`, `SL2_Fwd`, `SL1_Bck`, `SL2_Bck` --> `Sensors_60.O_60_*`
- `Sensors_60.Part_Pass` --> `Sensors_60.O_60_Part_Pass` (6 transicoes)
- Mapeamento de cor corrigido nas 6 combinacoes, conforme FB4-FB9:
  Vermelha = `ID_1 && ID_2` | Preta = `ID_1 && ~ID_2` | Prata = `~ID_1 && ID_2`
- Removido o ramo morto `~ID_1 && ~ID_2` (combinacao impossivel) de 5 blocos
- `BRS/ESTATE5` escrevia em `StatusBSR_5` (variavel do BSR) - corrigido
- `BSR/ESTATE3` tinha `entry:[StatusXXX_3 == true]` no campo errado - removido
- Adicionadas 6 transicoes de retorno (estagio 5 --> inicio); sem elas a maquina
  travava apos processar UMA peca (ver FB4, Rede 5)
- `SBR` deixou de ser copia duplicada de `SRB`
---
## v0.4.7 --> v0.4.8  (conflitos de variavel + Processing [100])
### 1. 69 conflitos de variavel compartilhada
Instancias duplicadas escreviam nas MESMAS variaveis (`Status5_1` era escrita por
8 estados diferentes), com risco de sobrescrita silenciosa. Cada instancia recebeu
variaveis proprias: `St_DSg0/1_*`, `St_DCt0/1_*`, `St_DCd0/1_*`, `St_C2P0..4_*`,
`St_P2P0..2_*`, `St_Stor_*`, `St_Retr_*`, `St_Visn_*`, `St_Rbt1/2_*`, `St_IdDl_*`, `St_RqDl_*`.
200 variaveis novas (Local/boolean), 69 orfas removidas.
> A Distribution [80] foi incluida. Ela ja funcionava, mas as instancias se
> contaminavam; agora nao. Se as duas nunca ficavam ativas juntas, nada muda.
### 2. Processing [100] implementada
Os 3 blocos sob o balao "Processing [100]" eram copias da Distribution [80]
(usavam `Actuators_80`/`Sensors_80`, nunca `*_100`). Reescritos a partir do ladder:
| Bloco | Antes | Ladder | Estados |
|---|---|---|---|
| `Processing_TestOnly` | `Distribution_Single1` | FB4 - Test Part Only | 7 |
| `Processing_TestDrill` | `Distribution_Continuous1` | FB5 - Test + Drill | 11 |
| `Processing_RotationOnly` | `Distribution_Counted1` | FB6 - Rotation Only | 5 |
Selecao de modo por `Control_100.C_105_Test` / `C_105_TestDrill` / `C_105_Rotation`.
### 3. Transicoes mal-parenteadas
As 6 transicoes de retorno da Sorting criadas na v0.4.7 estavam penduradas no Chart
em vez de dentro dos blocos. Corrigido.
---
## v0.4.8 --> v0.4.9  (layout + ligacao da Processing ao fluxo)
- Sobreposicao dos 3 blocos da Processing (caixas de 910 de altura com origens a
  556 de distancia) e dos 6 da Sorting (alturas aumentadas na v0.4.8 sem respacar)
- Blocos da Processing devolvidos as caixas originais dos baloes, com os estados
  em linha unica e a ordem logica preservada
- Removidas 4 arestas soltas herdadas das copias da Distribution (uma delas era a
  transicao "esticada" atravessando o canvas)
- Processing ligada ao fluxo da linha:
  `PartToProcessing --> [3 modos]` por `C_95_PD_Proc` + bit de modo;
  cada modo `--> PartToProcessing1` por `C_105_Part_ready`
- Removidos os loop-backs internos da Processing: com o topo em `EXCLUSIVE_OR`,
  um retorno interno prenderia a maquina no bloco sem passar a peca adiante
- Multiplas transicoes default por bloco (ambiguidade) reduzidas a uma
- Removidas 8 transicoes duplicadas em `Processing_RotationOnly` (cada ligacao
  estava triplicada, sobra de tentativas falhas)
> As 4 transicoes internas de `Processing_RotationOnly` foram desenhadas
> manualmente no editor (a API do Stateflow recusava parentea-las no bloco).
---
## v0.4.9 --> v0.4.10  (Handling 1 [50])
### 1. Handling 1 implementada
Novo bloco `Handling1_Cart2Del`, a partir de `Hd1/FB4` (Cart_2_Del - "entrega
partes do Conveyor para a Sorting"), 9 redes --> 9 estados:
| Estado | Rede | Observa |
|---|---|---|
| `Config_H1` | - | `C_55_Initialization` |
| `Aguarda_H1` | N1 | Start / `C_55_Start` / roteamento + carro na estacao + optico + SEM peca na Sorting |
| `DesceVazia_H1` | N2 | garra no carro, alta, vazia, descendo |
| `PegaPeca_H1` | N3 | garra baixa fechando |
| `MoveEntrega_H1` | N4 | garra alta com peca, indo para entrega |
| `DesceEntrega_H1` | N5 | na entrega, descendo |
| `EntregaPeca_H1` | N6 | baixa, garra abrindo |
| `SinalizaEntrega_H1` | N7 | alta, vazia, `C_55_PD_Sort` |
| `VoltaGarra_H1` | N8/N9 | voltando ao carro + `A_54_CRoute_Out` |
### 2. `PartToProcessing2` removido
Era placeholder: os 13 estados internos liam **so sinais `_90`** (Handling 2), mas a
aresta de saida dele para a Sorting era gatilhada por **`Control_50.C_55_PD_Sort`**
(sinal da Handling 1, produzido pela Rede 7 do `Hd1/FB4`). O lugar dele no fluxo
sempre foi da Handling 1.
Substituido no lugar, preservando o fluxo original:
```
CartToProcessing4 --> J1897 --> Handling1_Cart2Del
Handling1_Cart2Del --> J1898 [C_55_PD_Sort] --> leque --> 6 blocos da Sorting
Handling1_Cart2Del --> J1881 --> CartToTesting        (fecha o ciclo da linha)
```
O leque de `J1898` ja distribuia para as 6 combinacoes (`J1891->RBS`, `J1910->RSB`,
`J1888->BSR`, `J1917->SRB`, `J1880->BRS`, `J1921->SBR`), entao as 6 arestas diretas
`Handling1 --> Sorting` criadas antes eram redundantes e foram removidas.
Isso elimina o nao-determinismo: ha um unico caminho ate a Sorting.
Bloco apagado com 0 ligacoes externas restantes; 13 estados internos e 13
variaveis `St_P2P2_*` removidos junto.
---
## v0.4.10 --> v0.4.11  (validacao por compilacao + Distribution + after)
### 1. Primeira compilacao real do Chart
Ate aqui nenhuma versao tinha sido compilada. Montei um modelo de teste isolado
(so o Chart, alimentado por 32 Inports com os bus objects), o que contorna o OPC UA
e permite validar a logica do Stateflow sozinha. Resultado: **o Chart compila sem erros.**
Erros encontrados e corrigidos no caminho:
- **8 estados com rotulo invalido.** A primeira linha do label de um estado E o nome dele.
  Tinham texto extra: `BRS Output`, `BSR Output`, `RBS Output`, `RSB Output`, `SRB Output`,
  `SBR Output`, `Store Par`, `Retrieve Part`. Sobra dos nomes antigos dos blocos.
- **4 transicoes liam variavel de outro bloco** (copy-paste anterior, exposto pela separacao
  de variaveis da v0.4.8). Cada guarda passou a apontar para a variavel que o proprio estado
  de origem atribui:
| Bloco | Lia | Passou a ler |
|---|---|---|
| `Distribution_Continuous` | `St_DCt0_2a_2` (do Single) | `St_DCt0_2b_2` |
| `Requested_Delivery` | `St_RqDl_3a_1` (do Identified) | `Status3b_1` |
| `Requested_Delivery` | `St_RqDl_3a_13` | `Status3b_13` |
| `Requested_Delivery` | `St_RqDl_3a_8` | `Status3b_8` |
- 40 flags de status estavam com tipo `Inherit` sem inferencia possivel --> `boolean`
- 7 variaveis orfas removidas
### 2. Distribution [80] verificada contra o ladder
`Distribution_Single` conferido estado a estado contra `Distribution/FB4` (Single Delivery,
"Delivers a Single Part to Testing"). A sequencia do ladder --
`Single_On -> A2D_1 -> Pist_Fwd -> Transport -> A2M_1 -> Suct_On -> Part_Stuck -> A2D_2
-> Suct_Off -> Part_Del -> A2M_2 -> reset` -- corresponde a sequencia implementada.
O modelo e mais granular (estados `ArmCloseDelivery*` observando `O_70_SStation`), mas
nao contradiz o ladder. **Nenhuma logica precisou ser refeita.**
Estrutura das 3 modalidades conferida: 17/18/18 estados, 1 default cada, 0 transicoes
mal-parenteadas.
### 3. `after()` na Processing
Principio: numa sombra digital **nao se reimplementa o timer do CLP** -- observa-se o
sinal que o timer aciona, porque ele quase sempre esta exposto no OPC UA.
A Sorting ja estava certa: `[(ID_1 || ID_2 || after(2, sec)) && Status_2]` -- o `after`
em **OR** e so timeout de seguranca (a Rede 2 do FB4 usa T1 para setar `Q65.1`/`Q65.2`,
que sao `C_65_ID_1`/`ID_2`, observaveis).
O problema e o `after` em **AND**, onde a transicao so ocorre pelo relogio da simulacao --
que nao e o tempo da planta. Corrigidos os 2 casos da Processing, onde o timer T4 aciona
`M3.0 FB4_TestPin` = `Q124.5` = `Actuators_100.F_102_Test_Pin` (observavel):
```
antes: [(St_TOnly_4 == true) && after(2, sec)]
agora: [St_TOnly_4 == true && (F_102_Test_Pin == true || after(2, sec))]
```
**Nao corrigidos** (falta verificar o ladder ou nao ha PDF):
`Identified_Delivery`/`Requested_Delivery` (Elevator_Down, 2s), `Distribution/PartDel_CheckLoop`
(4s), e os conveyors `CartToTesting`/`CartToProcessing` (2s e 3s, **sem PDF do Conveyor [20]**).
### 4. Nota sobre o OPC UA
Os blocos OPC UA Read entregam `double` quando **nao conseguem conectar**. Durante esta
sessao isso apareceu porque os `close_system` do diagnostico derrubavam as sessoes.
Uma tentativa anterior de "corrigir" isso convertendo 382 atribuicoes e 392 portas foi
**descartada**: mascarava a desconexao e removia justamente o alarme que avisa que a
sombra esta cega. O erro de tipo e comportamento desejavel, nao defeito.
> Ao diagnosticar, nao feche o modelo -- fechar derruba as sessoes OPC UA.
---
## v0.4.11 --> v0.4.12  (Storage [40])
### A Storage nao tem mecanica
`Storage/FB4` tem **uma unica rede**, comentada como "Simulated Timer for Store Procedure".
`FB5` idem, para "Retrieve". Nao ha braco, elevador, garra ou sensor de posicao: o CLP
so conta o tempo e declara pronto. Confirmado pelos barramentos -- `Sensors_40` e
`Actuators_40` so tem painel (Start/Stop/Key/Reset/LEDs), nenhum sensor de processo.
Tempos vindos do ladder: **3 s para armazenar** (`T1`, `S5T#3S`) e **5 s para recuperar**
(`T2`, `S5T#5S`).
`Store` e `Retrieve` deixaram de ser stubs de 2 estados lendo `_90` (Handling 2) e passaram
a 5 estados cada, lendo `Control_40`/`Sensors_40`/`AS_i_40`:
| Estado | Origem | Observa |
|---|---|---|
| `Config` | - | `C_45_Initialization && C_45_StorePart` (ou `RetrievePart`) |
| `Aguarda` | OB1 N4/N5 | `C_45_Start` ou roteamento + `A_44_Cart_Stat` |
| `Armazenando`/`Recuperando` | FB4/FB5 N1 | temporizador simulado |
| `ProcessoOK` | OB1 N6 | fim do procedimento |
| `LiberaCarro` | OB1 N7 | pulso de 2 s em `A_44_CRoute_Out` |
> Aqui o `after()` **e** a modelagem correta, ao contrario dos outros casos: o proprio CLP
> e um temporizador e nao existe sinal intermediario para observar. `after(3, sec)` e
> `after(5, sec)` espelham os valores do ladder.
### Incidente
A rotina de limpeza de variaveis orfas apagou 74, mas 70 ainda estavam em uso -- o Chart
ficou com simbolos nao resolvidos. Detectado na compilacao e revertido. O filtro de
deteccao de uso nao batia com o de remocao; desconfiar dessa rotina.
---
## v0.4.12 --> v0.4.13  (Robot [30] + mapa das transicoes externas)
### 1. Mapa completo das transicoes externas
Levantadas as 40 transicoes bloco->bloco no nivel do Chart (resolvendo as cadeias de
juncao): **29 com guarda, 11 sem**. Fluxo da linha:
```
Start > CartToTesting > Distribution (Single/Continuous/Counted)
      > Testing (Identified/Requested_Delivery) > CartToProcessing
      > PartToProcessing > Processing (3 modos) > PartToProcessing1
      > CartToProcessing1 > Vision > CartToProcessing2 > Robot1/Robot2
      > CartToProcessing3 > Store/Retrieve > CartToProcessing4
      > Handling1_Cart2Del > Sorting (6 combinacoes)
                           > CartToTesting   (fecha o ciclo)
```
As 11 sem guarda envolvem exatamente os blocos ainda nao implementados (`Robot1/2`,
`Vision`), os recem-reescritos (`Store`, `Retrieve`) e as duas saidas de fim de ciclo.
As mais graves eram `CartToProcessing2` e `CartToProcessing3`, cada um com **duas saidas
sem guarda** -- nao-determinismo: a Storage podia entrar em "armazenar" com pedido de
"recuperar".
### 2. Robot [30] implementado
Fonte: `Master/FB3 - Robot Remote` (15 redes). O Robot e **remota da Master**, nao tem
CLP proprio. Os bus objects `B_*_30` existem no `BUS_CONFIG.mat` e nunca eram usados.
`Robot1` e `Robot2` passaram de stubs de 2 estados lendo `_90` para 7 estados cada:
| Estado | Rede | Observa |
|---|---|---|
| `Config` | N15 | `C_30_Robot1`/`C_30_Robot2` (modos mutuamente exclusivos) |
| `AguardaCarro` | N10/N11 | `A_34_Cart_Stat && ~A_34_No_Cart && A_34_Optic` |
| `PegaPeca` | N8 | `F_33_Spring_Cyl && O_32_Sp_Cyl_Fwd && O_31_Part_in_Claw` |
| `ColocaTampa` | N9 | `F_33_Cover_Cyl && O_32_Co_Cyl_Fwd && ~O_32_CoMag_Empty` |
| `Recua` | N8/N9 | cilindros recuados + `Sp_PickUp` e `Co_PickUp` |
| `PecaEntregue` | N13 | `C_35_Part_Del` |
| `LiberaCarro` | N14 | `A_34_CRoute_Out` (T8 = 2 s) |
Temporizadores do ladder preservados como timeout em OR: `T7` (5 s, roteamento do carro)
e `T8` (2 s, sinal de peca entregue).
### 3. Transicoes externas do Robot
As 4 que estavam sem guarda receberam condicao:
| Transicao | Guarda |
|---|---|
| `CartToProcessing2 -> Robot1` | `A_34_Cart_Stat && C_30_Robot1` |
| `CartToProcessing2 -> Robot2` | `A_34_Cart_Stat && C_30_Robot2` |
| `Robot1 -> CartToProcessing3` | `C_35_Part_Del && A_34_CRoute_Out` |
| `Robot2 -> CartToProcessing3` | `C_35_Part_Del && A_34_CRoute_Out` |
Segue o padrao do CLP inteiro: **bit de modo seleciona o ramo, sinal de conclusao libera
a saida**. Resolve o nao-determinismo do `CartToProcessing2`.
`Robot2` foi reposicionado (sobrepunha `Robot1` apos ganhar 7 estados).
### 4. Consolidacao da v0.4.13
**Erro corrigido: sobreposicao juncao-estado.** A juncao `J3808` (ponto de saida do
`Robot2` no nivel do Chart) ficou em cima da borda superior da caixa apos o `Robot2`
ser movido +223 para nao colidir com o `Robot1`. O bloco e os filhos foram movidos,
a juncao nao. Movida para `y=9480`.
> A rotina de verificacao de sobreposicao so comparava blocos com blocos. Passou a
> verificar tambem **juncao vs estado**.
**Aviso investigado: estado inalcancavel = `Vision / FinishesProcess`.** O bloco `Vision`
tem 2 estados e 2 transicoes (`<DEFAULT> -> InitialCondition` e `InitialCondition -> saida`).
Nao existe transicao para `FinishesProcess`: o estado tem codigo mas nada leva ate ele.
E um stub inacabado herdado de copia, lendo sinais `_90`. **Nao corrigido** -- o Vision e
a unica estacao sem PDF de ladder, e inventar a condicao seria pior que deixar o aviso visivel.
> Uma primeira analise acusou 52 estados inalcancaveis: falso positivo por seguir apenas
> transicoes estado->estado, ignorando as juncoes internas dos blocos. Refeita com juncoes,
> sobra 1 -- batendo com o aviso do Simulink.
**Timers do Robot reconferidos contra `Master/FB3` (N12-N14):**
| Rede | Timer | Cadeia real |
|---|---|---|
| N12 | `T7` = 5 s (`S_PEXT`) | `A_34_CRoute_In` + bit de modo --> `FB3_CartDel` |
| N13 | - | borda **negativa** de `FB3_CartDel` --> seta `C_35_Part_Del` |
| N14 | `T8` = 2 s (`S_ODT`) | `C_35_Part_Del` --> seta `A_34_CRoute_Out`, reseta `Part_Del` |
Associacao no modelo confirmada correta: `(C_35_Part_Del || after(5, sec))` e
`(A_34_CRoute_Out || after(2, sec))`.
> Ressalva: no ladder o `T7` conta a partir da **chegada do carro** (`A_34_CRoute_In`),
> nao do fim do recuo do robo. No modelo os 5 s contam a partir do estado `Recua`. Como o
> sinal observavel e o gatilho primario e o `after` e so fallback, o efeito pratico e
> pequeno -- mas o instante zero do cronometro difere.
**Correcao aplicada pelo usuario:** o `after` em AND na transicao `PecaEntregue -> LiberaCarro`
passou a `(A_34_CRoute_Out || after(2, sec))` nos dois blocos.
**Sobre o `FB3`:** as Redes 1-9 sao apenas passagem de I/O da remota (entradas byte 2 e 3,
LEDs, cilindros); 10-15 sao AS-i e temporizacao de roteamento. **O CLP nao sequencia o
movimento do robo** -- quem faz isso e o proprio robo. Os estados `PegaPeca`, `ColocaTampa`
e `Recua` sao validos como observacao dos sensores de cilindro, mas nao ha sequencia no
CLP para conferir contra eles.
**Verificacao final da v0.4.13:** 0 sobreposicoes (blocos e juncoes), 0 transicoes
mal-parenteadas, 1 estado inalcancavel conhecido (`Vision/FinishesProcess`), **Chart
compila sem erros**.
### Ainda sem guarda (7)
`CartToProcessing3 -> Store`, `-> Retrieve`, `Store -> CartToProcessing4`,
`Retrieve -> CartToProcessing4`, `CartToProcessing4 -> Handling1_Cart2Del`,
`Vision -> CartToProcessing2`, `Handling1_Cart2Del -> CartToTesting`.
Para a Storage o ladder ja da a resposta (`C_45_StorePart`/`C_45_RetrievePart` e
`A_44_CRoute_Out`); para os conveyors, o `Master/FB11`; para o `Vision`, **nao ha PDF**.
### Outros achados nao corrigidos
- `Requested_Delivery -> Distribution_*` tem a guarda `[C_75_RQ_Wrong] & [C_75_RQ_Wrong]`
  duplicada (redundante, nao contraditoria) -- sugere uma aresta a mais na cadeia de juncoes.
- A **Sorting nao tem transicao de saida**: entra pelas juncoes e cicla internamente
  (loop-back `ESTATE5 -> STATE1` da v0.4.7). Com o topo em `EXCLUSIVE_OR`, a maquina
  entra na Sorting e nunca devolve o controle a linha. Mesmo padrao que foi removido da
  Processing na v0.4.9. **Pendente de decisao sobre o destino apos a classificacao.**
## v0.4.13 --> v0.4.14  (Conveyor [20] -- os 6 blocos)
### 1. Estrutura do `Master/FB11 - Conveyor Control`
48 redes, mas e **o mesmo padrao de 7 redes repetido para 6 destinos**
(Testing 1-7, Processing 8-14, Vision 15-21, Robot 22-28, Storage 29-35, Sorting 36-42;
as redes 43-48 sao os comandos aos pinos de cada estacao).
| Rede | Funcao |
|---|---|
| N1 | Solicitacao de carrinho -- `C_2N_Request` ou pedido da estacao, e **nenhum outro destino solicitando** |
| N2 | Escolhe o carro mais proximo e abre o caminho (cascata de prioridade entre as estacoes) |
| N3 | Aciona a esteira -- exige `O_20_Controler_On`, senao gera `FB11_Conv_Error` |
| N4 | Desliga os pinos quando o carro fica proximo (`Cart_Next`) |
| N5 | Contador identifica o numero do carro --> `A_*_CartID` |
| N6 | Carro chegou (`Cart_Stat`) + timer de 3 s |
| N7 | Sinaliza chegada --> `C_2N_CartDel` |
Os barramentos confirmam a estrutura: `Control_20` e `Sensors_20` sao organizados por
indice **24 a 29** -- exatamente seis destinos.
### 2. Mapeamento dos blocos
| Bloco | Indice | Destino |
|---|---|---|
| `CartToTesting` | 24 | Testing |
| `CartToProcessing` | 25 | Processing |
| `CartToProcessing1` | 26 | Vision |
| `CartToProcessing2` | 27 | Robot |
| `CartToProcessing3` | 28 | Storage |
| `CartToProcessing4` | 29 | Sorting |
Cada bloco passou de 12 estados (copia generica, com `T1`/`T2`/`T3`) para **7 estados
espelhando as 7 redes**: `Config` > `EscolheCarro` > `EsteiraLigada` > `CarroProximo`
> `IdentificaCarro` > `CarroChegou` > `SinalizaChegada`.
### 3. Erro encontrado: indice trocado no `CartToProcessing1`
O bloco vai para o **Vision**, mas usava `C_25_Request` e `C_25_CartDel` -- sinais do
**Processing**. Reagiria ao pedido do destino errado. Corrigido para `C_26_*`.
> So apareceu porque passou a existir um mapeamento sistematico indice<->destino para
> conferir contra.
### 4. Guardas externas completas
As **7 transicoes externas que estavam sem guarda** foram preenchidas no padrao do CLP:
entrada exige `C_2N_Request`, saida exige `C_2N_CartDel`. Somando as do Robot (v0.4.13),
**nao resta nenhuma transicao externa sem guarda no chart**.
### 5. Layout
`CartToProcessing3` e `CartToProcessing4` passaram a colidir com outros blocos ao ganhar
caixas maiores. Movidos para faixa livre (`y=10553` e `y=11453`).
**Verificacao da v0.4.14:** 0 sobreposicoes de bloco, 0 de juncao, 0 transicoes
mal-parenteadas, **Chart compila sem erros**.
### Ressalvas
- **A rede N2 foi simplificada.** A cascata de prioridade do ladder escolhe entre cinco
  origens possiveis de carro (Processing, Vision, Robot, Storage, Sorting), cada uma
  abrindo um caminho diferente. No modelo isso virou um unico estado `EscolheCarro`.
  Defensavel para uma sombra que observa o estado da linha, mas **nao e reproducao fiel**:
  se for preciso saber *de onde* o carro veio, esse estado precisa ser desmembrado.
- **Lidas 9 das 72 paginas.** Verificado o padrao do destino Testing; assumido que os
  outros cinco seguem a mesma estrutura (o indice das redes sustenta isso, mas e
  inferencia, nao leitura completa). As redes 43-48 nao foram modeladas.
---
## v0.4.14 --> v0.4.15  (Testing [70] e Handling 2 [90] -- fim das verificacoes)
### 1. Testing [70] -- logica correta, sintaxe nao
Os 16 estados de `Identified_Delivery` e os 22 de `Requested_Delivery` conferidos contra
`Testing/FB4` e `FB5`. **A sequencia bate**: peca chega no elevador --> identificacao
metalica pelo indutivo --> sobe elevador --> identificacao no alto (sensor de altura +
temporizador) --> ejecao --> retorna elevador --> sinaliza entrega. O `Requested_Delivery`
acrescenta `CheckPart`/`Part_Equal`/`Part_Different` e uma segunda descida, que sao a
Rede 5 ("Part equals to Request?") e a Rede 8 ("Ejection Process for Bad Part") do FB5.
**74 erros de sintaxe corrigidos em 38 estados:** atribuicoes sem ponto-e-virgula
(`Status3a_10 = true`) e `if` com ponto-e-virgula na condicao
(`if ~AS_i_70.A_74_CRoute_Out;`). Tambem em `PartToProcessing`.
### 2. Handling 2 [90] -- erro de logica real
O `Hd2/OB1` chama **duas rotinas opostas**: `FB4 - Cart 2 Delivery` (carro --> entrega) e
`FB5 - Del 2 Cart` (entrega --> carro). No modelo, `PartToProcessing` e `PartToProcessing1`
eram **copias identicas**, ambas no sentido do FB4.
Confirmado no ladder: no `FB4` a Rede 2 garante a garra em `Claw_Cart` e a Rede 4 move para
`Claw2Del`; no `FB5` a Rede 2 garante `Claw_Del` e a Rede 4 move para `Claw2Cart` -- espelhado.
Corrigido o segundo bloco trocando `O_90_Claw_Cart` <-> `O_90_Claw_Del` e
`F_92_Claw_2_Cart` <-> `F_92_Claw_2_Del`, e renomeado para **`ProcessingToPart`**.
> O nome antigo dizia o oposto do comportamento -- provavelmente foi isso que manteve o
> erro invisivel. `PartToProcessing` leva do carro ao Processing; `ProcessingToPart` traz de volta.
### 3. Os 8 `after()` do Testing
Todos estavam em **AND**, e com respaldos diferentes no ladder:
| Transicao | Timer no ladder | Correcao |
|---|---|---|
| `Elevator_High -> Pushes_Part` | `T2`, 2 s | OR com `F_72_Eject_Part` |
| `Elevator_High -> CheckPart` | `T2`, 2 s | OR com `F_72_Eject_Part` |
| `J552 -> Piston_Back` | `T3`, 2 s | OR com `O_70_Pist_Bck` |
| `J722 -> Piston_Back` | `T3`, 2 s | OR com `O_70_Pist_Bck` |
| `Elevator_Down -> End_Process` (x2) | **nenhum** | `after` removido --> `[O_70_Elev_Low && C_75_Part_Del]` |
| `J723 -> Pushes_Part` | **nenhum** | `after` removido --> `[Part_Equal == true]` |
| `J723 -> J727` | **nenhum** | `after` removido --> `[Part_Different == true]` |
O pior era `Elevator_Down -> End_Process`: guarda `after(2,sec)` **sozinha**, sem condicao
de estado, disparando so pelo relogio da simulacao. A Rede 6 do FB4 nao tem temporizador --
o que encerra e o elevador chegar embaixo e sinalizar entrega.
Os dois do `J723` tambem corrigiam um problema colateral: como os dois ramos tinham o mesmo
`after(2,sec)`, o desempate entre peca certa e peca errada saia por **ordem de execucao**
em vez da comparacao.
### 4. Transicoes externas: 41, nenhuma sem guarda
Uma verificacao anterior acusou `J1892 -> ProcessingToPart` sem guarda. **Falso positivo:**
a listagem mostrava arestas diretas sem resolver as cadeias de juncao, e o trecho final de
uma cadeia nao carrega rotulo (a guarda esta no inicio). Resolvendo as cadeias:
**41 transicoes bloco->bloco, 0 sem guarda.**
**Verificacao da v0.4.15:** 0 sobreposicoes de bloco, 0 de juncao, 0 `after` em AND puro no
Testing, 1 estado inalcancavel conhecido (`Vision/FinishesProcess`), **Chart compila sem erros**.
---
## v0.4.15 --> v0.4.16  (Vision + auditoria final)
### 1. Vision -- estacao simbolica
Nao existe FB de Vision nos PDFs nem barramento proprio. Ela so aparece como **destino 26**
da esteira (`Master/FB11`, redes 15-21). O bloco era stub de 2 estados lendo `_90`, com
`FinishesProcess` **inalcancavel**. Reconstruido como passagem simbolica de 3 estados:
| Estado | Observa |
|---|---|
| `Config_Visn` | `Control_20.C_26_CartDel` (carro chegou na Vision) |
| `Inspecao_Visn` | passagem de **5 s** (tempo medido na planta fisica) |
| `FinishesProcess_Visn` | `Control_20.C_27_Request` (esteira pede o proximo destino) |
Guarda de saida: `[St_Visn_3 == true && Control_20.C_27_Request == true]`.
> **Os 5 s nao vem do CLP.** Sao valor medido na planta. Quem realmente libera a peca e a
> condicao `C_27_Request` na transicao externa; o tempo apenas preenche o intervalo.
### 2. Auditoria final
| Verificacao | Resultado |
|---|---|
| Estados inalcancaveis | **0** |
| Transicoes bloco->bloco sem guarda | **0** (de 40) |
| Transicoes mal-parenteadas | **0** |
| Sobreposicoes bloco-bloco | **0** |
| Sobreposicoes juncao-estado | **0** (1 corrigida: `J1897` sobre o `Vision`) |
| Campos de bus inexistentes | **0** |
| Identificadores nao declarados | **0** |
| Compilacao do Chart | **sem erros** |
Blocos de topo: 30. Estados: 287.
### 3. Blocos sem saida externa (6)
`BRS`, `BSR`, `RBS`, `RSB`, `SRB`, `SBR` -- a **Sorting e terminal**: entra pelas juncoes e
cicla internamente, sem devolver o controle a linha. **Pendente de decisao.**
### 4. `after()` restantes -- todos legitimos
> **CORRIGIDO na v0.4.18 (item 8):** a afirmacao de "ramo alternativo de juncao" vale
> apenas para o `Distribution_Single`. No `Continuous` e no `Counted` o `after(4,sec)` e
> uma terceira transicao saindo de `PartDel_CheckLoop`, e e **codigo morto**.
| Onde | Tempo | Por que |
|---|---|---|
| `Distribution_Single` | 4 s | **Ramo alternativo de juncao**, nao AND: o caminho normal tem prioridade, o `after` e saida por timeout |
| `Distribution_Continuous/Counted` | 4 s | **CORRIGIDO o registro na v0.4.18: e codigo morto**, nao ramo de juncao -- ver v0.4.18 item 8 |
| `Store` | 3 s | Estacao **simulada** no CLP (`S5T#3S`) |
| `Retrieve` | 5 s | Estacao **simulada** no CLP (`S5T#5S`) |
| `Vision` | 5 s | Estacao **simbolica**, sem ladder |
Nenhum `after` bloqueia caminho que tenha sinal observavel disponivel.
---
### 5. Ramos irmaos ambiguos em juncoes (correcao tardia)
A auditoria de "transicoes sem guarda" tinha um **defeito de metodo**: ela resolvia as
cadeias de juncao **concatenando** as guardas do caminho, entao ramos irmaos herdavam a
guarda comum do inicio e apareciam como "com guarda". Nunca verificou se **ramos que saem
da mesma juncao se distinguem entre si**.
Quatro defeitos reais encontrados por isso:
| No | Problema | Efeito | Correcao |
|---|---|---|---|
| `J1888` | Ramos para `Store` e `Retrieve` **ambos sem guarda** | Todo carro ia para `Retrieve`; `Store` inalcancavel na pratica | Guardas `C_45_StorePart` e `C_45_RetrievePart` (`Storage/OB1` N4 e N5) |
| `J1882` | Ramo sem guarda com **ordem 1**, guardado com ordem 2 | `RSB` nunca alcancado -- o fluxo escapava antes de testar o bit | Ordens invertidas |
| `J1890` | Idem | `SRB` nunca alcancado | Ordens invertidas |
| `Handling1_Cart2Del` | Idem | Saida para a Sorting nunca testada antes do desvio | Ordens invertidas |
> **Padrao correto de cascata if-else em juncao:** o ramo **com guarda** deve ter ordem de
> execucao **menor** que o ramo sem guarda (que funciona como `else`). Se o `else` vier
> primeiro, ele sempre passa e o ramo guardado vira codigo morto.
Apos a correcao: **6/6 combinacoes da Sorting alcancaveis**, 0 nos com ordem errada,
Chart compila sem erros.
### 6. Auditoria final da v0.4.16
| Verificacao | Resultado |
|---|---|
| Campos de bus inexistentes | 0 |
| Escritas em bus de entrada | 0 |
| Identificadores nao declarados | 0 |
| Estados inalcancaveis | 0 |
| Blocos com default != 1 | 0 |
| Transicoes mal-parenteadas | 0 |
| Sobreposicoes bloco e juncao | 0 |
| Rotulos de estado != nome | 0 |
| Variaveis so-leitura | 0 |
| Caminhos bloco->bloco sem guarda | 0 |
| Ramos de juncao com ordem errada | 0 |
| Sintaxe | 0 (3 corrigidos: `if ...;` no `ArmArrives_Finish` das 3 modalidades da Distribution) |
| Compilacao do Chart | **sem erros** |
Inventario: 30 blocos de topo, 287 estados, 374 transicoes, 70 juncoes, 695 dados.
### 7. CORRECAO: backtracking em juncoes
Durante a v0.4.16 afirmei que varios nos estavam quebrados por terem ramos sem guarda
avaliados antes dos guardados. **Isso estava errado.**
O Stateflow avalia uma transicao estado->estado atraves de juncoes como um **caminho
completo, com backtracking**: se o segmento final falhar, ele desfaz o caminho e tenta o
proximo ramo. Portanto um segmento intermediario **sem guarda e normal** -- a guarda fica
no fim do caminho.
Consequencias:
- `J259` (leque da Sorting em 2 grupos) e `J289` (Robot1/Robot2): **corretos**, nao
  precisavam de correcao. As 6 combinacoes e os 2 robos sao alcancaveis de fato.
- As mudancas de ordem de execucao em `J1882`, `J1890` e `Handling1_Cart2Del` eram
  **desnecessarias**. Nao quebraram nada (por o ramo guardado primeiro evita retrocesso
  a toa e e mais legivel), mas foram apresentadas como conserto de bug e nao eram.
- A correcao do **`J1888` (Store/Retrieve) era real e necessaria**: ali os dois caminhos
  terminavam em estado **sem nenhuma guarda em todo o percurso**, entao nao havia o que
  falhar e nao havia backtracking -- a ordem decidia sozinha e o `Store` era inalcancavel.
> **Criterio correto de verificacao:** nao basta olhar se ramos irmaos tem guarda. O que
> importa e se existe **caminho bloco->bloco sem nenhuma guarda em todo o percurso** --
> esse sim engole o fluxo. Hoje: 0.
---
## v0.4.16 --> v0.4.17  (desmembramento da rede N2 dos conveyors)
### 1. A regra descoberta no ladder
O estado generico `EscolheCarro` de cada conveyor escondia a cascata de prioridade da
**rede N2 do `Master/FB11`**. Lidas as **6 cascatas** (uma por destino), a regra e:
> **Prioridade = carro mais proximo a MONTANTE do laco.**
Laco fisico: `Testing(24) -> Processing(25) -> Vision(26) -> Robot(27) -> Storage(28) -> Sorting(29) ->` volta.
Para cada destino a busca vai para tras, e o ultimo da lista e o caso default (nenhum carro
nas outras estacoes).
| Destino | Prioridade | Paginas do PDF |
|---|---|---|
| Testing | Sorting > Storage > Robot > Vision > Processing | 2-5 |
| Processing | Testing > Sorting > Storage > Robot > Vision | 11-14 |
| Vision | Processing > Testing > Sorting > Storage > Robot | 20-22 |
| Robot | Vision > Processing > Testing > Sorting > Storage | 29-30 |
| Storage | Robot > Vision > Processing > Testing > Sorting | 38-39 |
| Sorting | Storage > Robot > Vision > Processing > Testing | 47-48 |
**Os 6 destinos foram confirmados diretamente no PDF** -- nenhuma extrapolacao.
### 2. Implementacao
Cada `EscolheCarro_CvN` virou **5 estados**, um por origem:
```
Config > DeSorting / DeStorage / DeRobot / DeVision / DeProcessing > EsteiraLigada
```
As guardas reproduzem os contatos NF do ladder: a de maior prioridade so testa presenca,
as seguintes acumulam as negacoes das anteriores.
```
prioridade 1: [C_24_Request && O_29_Cart_Stat]
prioridade 5: [C_24_Request && O_25_Cart_Stat && O_29_Cart_Stat == false
               && O_28_... == false && O_27_... == false && O_26_... == false]
```
Ordem de execucao = prioridade (redundante com as negacoes, mas fiel ao ladder).
Cada conveyor foi de 7 para **11 estados**; os 6 blocos foram reposicionados em faixa livre.
**Verificacao:** 0 sobreposicoes (bloco e juncao), 0 estados inalcancaveis, Chart compila
sem erros. Chart: 30 blocos, 317 estados.
> Item 1 do MAPA DAS SIMPLIFICACOES resolvido.
---
---
## v0.4.17 --> v0.4.18  (parte A: limpeza do `Variable_Declaration`)
Removido o bloco `Variable_Declaration` (9 filhos, `VarDeclaration_20` a `_100`), que era
**documentacao** -- cada filho listava os sinais da estacao em comentarios sem efeito.
Chart: 30 --> 29 blocos, 311 --> 301 estados.
Auditoria da v0.4.18: 0 campos de bus inexistentes, 0 escritas em Input, 0 nao declarados,
0 sintaxe, 0 inalcancaveis, 0 default!=1, 0 mal-parenteadas, 0 sobreposicoes, 0 caminhos
sem guarda, **Chart compila sem erros**. Os 29 blocos restantes tem a mesma contagem de
filhos da v0.4.17 (desmembramento da rede N2 preservado).
> O conteudo do `Variable_Declaration` continua disponivel na v0.4.17, caso a referencia
> rapida de nomes de sinal por estacao seja util.
---
## v0.4.17 --> v0.4.18  (parte B: Distribution FB5 e FB6 -- fim da unica logica por suposicao)
> A v0.4.18 reune duas frentes: a **parte A** (remocao do `Variable_Declaration`, documentada
> acima) e a **parte B**, abaixo. Ambas estao no mesmo arquivo `FullFMS_2026_02_25_V0_4_18.slx`.
Ate aqui `Distribution_Continuous` e `Distribution_Counted` nunca tinham sido conferidos
contra o ladder: assumiu-se que seguiam o `FB4` (Single), verificado na v0.4.11. Lidos
agora os dois PDFs inteiros (`Distribution/FB5`, 7 paginas; `Distribution/FB6`, 8 paginas),
rasterizados a 200 dpi com a polaridade NA/NF conferida contato a contato.
### 1. O que os dois FBs sao, de fato
Ambos sao o `FB4` com um envelope em volta. A sequencia do braco e **identica** nos tres:
```
A2D_1 (braco vazio ate a entrega) -> Pist_Fwd (pistao alimenta 1 peca do magazine)
-> PartMove -> A2M_1 (braco ate o magazine) -> Suct_On -> Part_Stuck (peca na ventosa)
-> A2D_2 (braco ate a entrega, com a peca) -> Suct_Off -> peca entregue
```
O que muda e o criterio de repeticao:
| FB | Envelope | Fim do ciclo |
|---|---|---|
| FB4 Single | nenhum | uma peca e para |
| FB5 Continuous | repete enquanto `Magazine_Empty` (I124.6) for **falso** | `Magazine_Empty` --> `T3` (1 s) --> `A2M_2` --> reseta `Automatic_On` |
| FB6 Counted | contador `C2` (`S_CD`) pre-carregado com `C_83_RQ_Parts + 1`, decrementado a cada peca entregue | o `Q` do contador cai --> `FB6_Counted_On` (M4.7) desliga |
**A malha de repeticao volta ao pistao, nao ao inicio.** No FB5 a Rede 2 reseta `PartMove`
e `PartStuck` mas **nao** reseta `PartExists`; com o braco ainda na entrega, o proximo rung
que fecha e `Arm_Del && ~PartMove && Pist_Back --> S Pist_Fwd`. O modelo ja voltava para
`ArmArrives_FeedsPart` -- **correto, confirmado**.
### 2. Erro de logica real: a malha do Counted estava invertida
`Distribution_Counted/PartDel_CheckLoop`:
```
antes: LoopDistCont = C_85_Part_Del && C_87_RQ_MParts == 0
agora: LoopDistCont = C_85_Part_Del && C_87_RQ_MParts ~= 0
```
`C_87_RQ_MParts` (QB87) e o **CV do contador** -- "Number of Parts Still Needed for Counted
Mode". Com `== 0` o bloco entregava **uma** peca e encerrava enquanto ainda faltavam pecas,
e passava a **repetir para sempre** justamente quando a contagem zerava. Invertido.
> Nao aparecia na compilacao. Mesmo perfil dos dois piores erros da v0.4.16 (`J1888` e a
> Handling 2 invertida): guarda sintaticamente valida, semantica trocada.
### 3. Bit de modo errado no Counted
`Distribution_Counted/InitialCondition` observava `Control_80.C_85_Continuous` -- copia do
bloco vizinho. `Control_80.C_85_Counted` existe no bus e nunca era usado. Corrigido.
> Sem efeito sobre o fluxo: a selecao de modo real esta na juncao `J1963`, no nivel do
> Chart, que **ja** usava `C_85_Counted`. Era erro de fidelidade, nao de comportamento.
### 4. Condicao de partida: `C_75_RQ_Wrong` nao pertence ao FB5 nem ao FB6
A Rede 1 do `FB4` tem o ramo OR `C_75_RQ_Wrong` (I75.5), documentado no proprio PDF:
"If on Requested Mode [70] starts again until correct part is delivered". **O FB5 (Rede 1)
e o FB6 (Rede 2) nao tem esse ramo** -- confirmado no PDF: as tres origens sao `Start`,
`C_85_Start` e (`A_74_CRoute_In80 && Key_Pos`). Removido das guardas de partida do
`Distribution_Continuous` e do `Distribution_Counted`; mantido no `Distribution_Single`.
### 5. Sinal do magazine no Continuous
`PartDel_CheckLoop` do Continuous usava `Control_80.C_86_Mag_Parts ~= 0` (contagem do OB1).
O FB5 le o sensor `Magazine_Empty` (I124.6) direto, e `Sensors_80.O_80_Mag_Empty` existe no
bus e nunca era usado:
```
antes: LoopDistCont = C_85_Part_Del && C_86_Mag_Parts ~= 0
agora: LoopDistCont = C_85_Part_Del && ~Sensors_80.O_80_Mag_Empty
```
### 6. Condicao do contador no Counted
O `FB6` Rede 2 so carrega o contador se `OB1_Exis_Parts >= C_83_RQ_Parts` (bloco `CMP >=I`)
-- ha pecas suficientes no magazine para o pedido. Acrescentado ao `InitialCondition`:
`C_86_Mag_Parts >= C_83_RQ_Parts`.
### 7. Variaveis
- `Distribution_Continuous/InitialCondition`: o ramo `if` atribuia `St_DCt0_2a_1` e o `else`
  atribuia `St_DCt0_2b_1` -- variaveis diferentes no mesmo if/else. Unificado em `_2b_1`;
  `St_DCt0_2a_1` removida (orfa).
- `Distribution_Counted/ArmArrives_FeedsPart` usava `St_DCd0_2b_4` (prefixo do Continuous)
  no lugar de `St_DCd0_2c_4`. Renomeada, no rotulo do estado e na guarda de saida.
### 8. CORRECAO ao registro da v0.4.16: os `after(4,sec)` da Distribution
A tabela "`after()` restantes -- todos legitimos" afirmava que os 4 s das tres modalidades
eram "ramo alternativo de juncao". **Isso vale apenas para o `Distribution_Single`**, onde o
`after` e o ramo de ordem 2 da juncao `J578`.
No `Continuous` e no `Counted` o `after(4,sec)` e uma **terceira transicao saindo do estado
`PartDel_CheckLoop`**, com ordem de execucao 3, enquanto as ordens 1 e 2 ja cobrem
`LoopDistCont == true` e `== false`. Sendo `LoopDistCont` booleana, uma das duas sempre
fecha: **a transicao de ordem 3 e codigo morto, e o estado `T1` desses dois blocos so e
alcancavel por ela.**
Nao removido: apagar a transicao deixaria `T1` inalcancavel, e a limpeza e mudanca de
estrutura, nao de fidelidade ao ladder. **Pendente de decisao.**
### 9. O que do FB6 continua nao modelado (e por que)
As Redes 4 e 5 do `FB6` produzem o decremento (`FB6_Dec_Count`) a partir de
`(FB6_Part_Del && C_75_Identified80) || (C_75_RQ_Part_Del && C_75_Requested80)`, com `T3` de
1 s, e resetam `FB6_Part_Del`. O modelo **nao** reimplementa isso: observa `C_87_RQ_MParts`,
que ja e o resultado do contador e esta exposto no OPC UA. E o principio da sombra aplicado
corretamente -- nao se reimplementa o contador do CLP, observa-se o valor que ele publica.
**Verificacao da v0.4.18:** 0 estados inalcancaveis nos 3 blocos da Distribution, 1 default
por bloco, **Chart compila sem erros** (harness isolado de 32 Inports).
Modelo: `FullFMS_2026_02_25_V0_4_18.slx`


---

## v0.4.18 --> v0.4.19  (ProcessingToPart -- correcao feita fora desta linha de trabalho)

Arquivo: `FullFMS_2026_02_25_V0_4_19_R2025b.slx`, gerado pelo script `corrige_ProcessingToPart.m`
a partir do `V0_4_18_R2025b`. Motivo: o `ProcessingToPart` era copia do `PartToProcessing`
e esperava o carro **cheio**; no ciclo real o carro esta vazio quando a peca sai do Processing.

1. `InitialCondition`: passou a exigir `~A_94_Cart_Full && C_95_Initialization && C_92_Profibus && O_91_Key_Pos`.
2. `InitialCondition -> ClawBeginsDescent`: `A_94_CRoute_In` trocado por `F_92_Claw_Down`.
3. `ClawDescent -> DeliversPart`: `O_100_PInit_Pos` trocado por `A_94_Cart_Full`.
4. `FinishesProcess`: `C_95_PD_Proc` trocado por `C_95_PD_Cart`.

**Resultado no teste com a planta:** a simulacao parou no `InitialCondition` do `ProcessingToPart`.
O cruzamento com o ladder (v0.4.20) mostrou que a condicao nao correspondia ao `Hd2/OB1` +
`FB5`: faltava `C_95_Del2Cart`, sobrava `O_91_Key_Pos`, e a sequencia de movimento nao era a do FB5.

---

## v0.4.19 --> v0.4.20  (FMS V2 + Handling 2 reescrito pelo FB4/FB5)

### 1. Levantamento do FMS novo (`Full_FMS_V2` / `Full_FMS_PDFs_V2`)

Comparados os 8 diretorios de PDFs V1 x V2 (texto extraido). Mudancas reais de conteudo:

| Bloco | Mudanca | Efeito no modelo |
|---|---|---|
| `Master/OB1` | rede 11 "Conveyor Control - Regular" chama `FB11` com `~C_21_MES_On` (Q21.0); rede 12 "Conveyor Control - MES" chama `FB12` com `C_21_MES_On` | nenhum enquanto o MES estiver desligado; `C_21_MES_On` **nao existe** em `B_Control_20`, nos CSV nem no `Tags_OPCUA.mat` |
| `Master/FB12` | bloco novo "Conveyor MES / MES Routing" v0.1, **vazio** | nada a modelar ainda (MES adiado a pedido) |
| `Master/FB2` | `T10` S5T#5S -> S5T#1S; Q26.2/`C_26_` -> Q25.2/`C_25_` ("Fix Optic issue") | passagem OPC UA, sem efeito na logica do Chart |

Todos os FBs de estacao (FB4/FB5/FB6 etc.) estao **iguais** a V1.

### 2. Handling 2 reescrito contra o ladder

`PartToProcessing` (FB4 `Cart_2_Del`, prefixo P2P0) e `ProcessingToPart` (FB5 `Del_2_Cart`,
prefixo P2P1) refeitos com 10 estados cada, um por passo do FB:
`Config -> Garra no carro/na entrega -> DescePega -> FechaGarra -> SobeComPeca ->
MoveParaEntrega/MoveParaCarro -> DesceEntrega -> AbreGarra -> SobeVazia -> PecaEntregue`.

- Config P2P0: `C_95_Initialization && C_92_Profibus && C_95_Cart2Del` (OB1 N5).
- Config P2P1: `C_95_Initialization && C_92_Profibus && C_95_Del2Cart` (OB1 N6, leitura parcial -- corrigida na v0.4.22).
- Fim P2P0: `C_95_PD_Proc` (OB1 N7, Q95.1 <- M1.7). Fim P2P1: `C_95_PD_Cart` (OB1 N8, Q95.2 <- M2.7).
- Saida externa `ProcessingToPart -> J1969`: `[St_P2P1_5_10 == true && C_95_PD_Cart == true]`;
  saida para `CartToProcessing1`: `[C_26_Request == true && St_P2P1_5_10 == true]` (antes
  referenciava `St_P2P1_5_13`, que deixou de existir -- erro de compilacao corrigido).
- `J1969` afastada da caixa do `ProcessingToPart`.

### 3. Incidente de versao

A v0.4.20 foi gravada primeiro com `save_system` numa sessao R2026a com nome `_R2025b` --
o arquivo continuava R2026a. Refeito com `Simulink.exportToVersion(m, arq, 'R2025B_SLX')`;
o original virou `_R2026a`. **Regra:** `save_system` grava sempre no formato da sessao.

---

## v0.4.20 --> v0.4.21  (dados nao inicializados + partida da Processing)

1. **Erro de execucao** `St_P2P1_5_10 was read before being written to`: as guardas externas
   leem variaveis locais de blocos ainda nao ativados. `InitialValue = 'false'` aplicado em
   **259** dados locais `St_*`/`Status*`.
2. **Processing parada em `Config_TOnly`**: exigia `C_105_Initialization`, mas o
   `Processing/OB1` rede 5 usa `M0.0 Init_Ok` (interno, fora do OPC UA). As tres configs
   passaram a usar a exclusao de modos do OB1:
   - `Config_TOnly`: `C_105_Test && ~C_105_TestDrill && ~C_105_Rotation`
   - `Config_TDrill`: `C_105_TestDrill && ~C_105_Test && ~C_105_Rotation`
   - `Config_ROnly`: `C_105_Rotation && ~C_105_Test && ~C_105_TestDrill`
3. Harness isolado: compila e simula sem erro. 29 blocos de topo, 295 estados, 406 transicoes,
   70 juncoes, 712 dados.

**Teste com a planta:** passou pelo `PartToProcessing` e pela `Processing_TestOnly`; parou
no `Config_P2P1` do `ProcessingToPart`.

---

## v0.4.21 --> v0.4.22  (`Config_P2P1` pela rede 6 do `Hd2/OB1`)

A rede 6 do `Hd2/OB1` ("Del 2 Cart") foi **rasterizada e lida visualmente** (nova ferramenta
`Matlba/renderPdfPage.m`, ver Notas). Topologia confirmada:

```
EN(FB5) = ( M0.0 FB1_Init_Parcial && I92.0 C_92_Profibus &&
            ( (M0.6 OB1_OK_Move && I95.2 C_95_Del2Cart)
            || (I105.1 C_105_Part_ready && /I94.2 A_94_Optic)
            || M2.0 FB5_P2D_Proc ) )
       || /I125.1 Stop
```

O `C_95_Del2Cart` e o caminho **manual**; no ciclo automatico quem habilita o FB5 e
`C_105_Part_ready && ~A_94_Optic` (peca pronta no Processing e sem peca no carro). Por isso
o estado ficava parado: o modelo so aceitava o caminho manual.

Nova condicao do `Config_P2P1`:

```matlab
if Control_90.C_95_Initialization && Control_90.C_92_Profibus && ...
   ( Control_90.C_95_Del2Cart || (Control_100.C_105_Part_ready && ~AS_i_90.A_94_Optic) )
```

Correspondencias e omissoes (todas por falta do sinal no OPC UA):

- `M0.0 FB1_Init_Parcial` (interno) -> `C_95_Initialization` (mesmo criterio do P2P0, que passou na planta).
- `I105.1` do Hd2 -> `Control_100.C_105_Part_ready` (o mesmo sinal publicado pelo CLP da Processing).
- `M0.6 OB1_OK_Move` (interno, rede 4) omitido -- so atua em serie com `C_95_Del2Cart`.
- `M2.0` (auto-retencao) e o proprio estado do modelo.
- `/I125.1 Stop` (painel local, fora do OPC UA) omitido.
- `FB5` rede 1: o movimento so comeca com `I95.0 C_95_Start` (S M2.0). **Nao** foi colocado na
  guarda, como no P2P0: os estados seguintes so avancam com atuadores/sensores reais da garra.

**Verificacao:** harness isolado compila e simula sem erro; `V0_4_22_R2025b.slx` exportado com
`exportToVersion` (`Simulink.MDLInfo` = R2025b) e a guarda nova conferida no XML do chart.

Modelo: `FullFMS_2026_02_25_V0_4_22_R2025b.slx` (teste) / `_R2026a.slx` (fonte).

**Teste com a planta:** continuou parado no `Config_P2P1`. Valores no momento: `C_105_Part_ready = 0`,
`C_95_Del2Cart = 0`, `C_95_PD_Cart = 1`, `A_94_No_Cart = 1` -- o CLP ja tinha entregue a peca no
carro e o carro ja tinha saido; a sombra perdeu a transferencia inteira.

---

## v0.4.22 --> v0.4.23  (`Config_P2P1` com captura na entrada + auto-retencao)

### Diagnostico
- A unica entrada do `ProcessingToPart` e a saida da Processing com guarda `C_105_Part_ready == true`
  (TestOnly, TestDrill e RotationOnly). Logo, **no passo da entrada o `Part_ready` era 1**.
- `Processing/OB1` rede 4 (rasterizada): `Q105.1 C_105_Part_ready` e bobina simples de
  `FB1_RT_RP1 || RP2 || RP3 || FB4_PartPickUp || FB5_PartPickUp || FB6_PartPickUp`. Cai assim que a
  garra da HD2 retira a peca -- ou seja, **o Part_ready dura pouco**.
- No CLP isso nao importa: depois que o FB5 parte, ele se mantem habilitado pelo ramo `M2.0`
  (auto-retencao da rede 6). No modelo, o `entry` zerava `St_P2P1_5_1` e o `during` so testava a
  condicao no passo seguinte; se o `Part_ready` ja tinha caido, o estado nunca saia.

### Correcao
- `entry`: `St_P2P1_5_1` recebe a condicao de habilitacao **no mesmo passo** da transicao de entrada
  (em que a guarda acabou de ler `Part_ready == true`).
- `during`: so seta para `true`, nunca volta a `false` -- e o equivalente observavel do `M2.0`.
- Os estados seguintes continuam esperando os sensores/atuadores reais da garra, entao a captura
  nao faz a sombra andar sozinha.

**Verificacao:** harness isolado compila e simula sem erro; `V0_4_23_R2025b.slx` exportado com
`exportToVersion` (`Simulink.MDLInfo` = R2025b).

**Ressalva para o teste:** a sombra precisa acompanhar o ciclo desde o inicio. Se a simulacao
comecar com a peca ja entregue (`C_95_PD_Cart = 1`, sem carro), nada mais vai acontecer no
`Config_P2P1`, como no CLP (o FB5 tambem fica desabilitado).

Modelo: `FullFMS_2026_02_25_V0_4_23_R2025b.slx` (teste) / `_R2026a.slx` (fonte).

**Teste com a planta:** passou do `Config_P2P1` e parou no `GarraNaEntrega_P2P1`, com a garra
ja parada no carro (`O_90_Claw_Cart = 1`, `Claw_High = 1`, atuadores em 0, sem peca na garra).

---

## v0.4.23 --> v0.4.24  (Handling 2: latch em todos os passos + saida pelo `C_95_PD_Cart`)

### Diagnostico (hipotese do usuario: "sinais rapidos demais" -- confirmada em parte)
- Configuracao do modelo: passo fixo de 0,01 s e 8 blocos OPC UA Read **sincronos** por passo.
  O tempo real de cada passo e bem maior que 0,01 s, entao sinais de duracao curta podem cair
  entre duas leituras.
- Todos os passos tinham `else St = false`: o estado precisava ver a condicao **no `during` e de
  novo no passo seguinte** (quando a transicao e testada). Condicao momentanea = estado preso.
- O caso concreto: a transicao `GarraNaEntrega -> DescePega` exigia, alem do flag,
  `O_90_Claw_High == true` **instantaneo**. Se a sombra chega com a garra ja descendo, `Claw_High`
  so volta a 1 no instante em que a garra sobe com a peca -- e o FB5 rede 4 manda a garra para o
  carro na hora (`Part_In_Claw && Claw_Up`). Janela curtissima; perdida, a garra sai da entrega,
  o `else` zera o flag e o estado trava -- exatamente a foto do teste.
- Nem todo sinal era curto: `Claw_Del`, `Claw_Cart`, `Part_in_Claw`, `C_95_PD_*` sao mantidos por
  segundos. Os curtos sao `Claw_Low` (so enquanto fecha/abre a garra) e os atuadores de translacao
  (`F_92_Claw_2_Cart`/`_2_Del` caem ao chegar -- por isso `Claw_2_Cart && Claw_Cart` quase nunca
  coexistem).

### Correcao (aplicada nos 20 passos de `PartToProcessing` e `ProcessingToPart`)
1. **Captura no `entry` + latch no `during`** (sem `else`). Equivale as bobinas `S` dos FB4/FB5:
   cada passo do CLP e um bit setado que so e resetado no fim do ciclo.
2. **`Claw_High` removido** das transicoes `GarraNoCarro/GarraNaEntrega -> DescePega`.
3. **Condicoes com alternativa mantida** nos passos de sinal curto (consequencia fisica do passo,
   nao suposicao de tempo):
   - `DescePega`: `(pos && Claw_Down && Claw_Low) || (pos && Part_in_Claw)` -- se ja pegou a peca, desceu.
   - `MoveParaCarro` / `MoveParaEntrega`: `pos_destino && Part_in_Claw` (o atuador de translacao cai ao chegar).
   - `DesceEntrega`: `(pos && Claw_Down && Claw_Low) || (pos && ~Part_in_Claw)` -- se ja soltou, desceu.
4. **Saida do `ProcessingToPart` pelo proprio CLP**, como ja era a do `PartToProcessing` (que sai
   por `C_95_PD_Proc` em qualquer passo -- por isso nunca travou). Novo dado local `P2P1_Armed`:
   zerado no `entry` do bloco, vira `true` quando `C_95_PD_Cart` e visto em 0 (o `Part_ready`
   reseta `M2.7` na rede 1 do FB5). Saidas:
   `[(St_P2P1_5_10 || P2P1_Armed) && C_95_PD_Cart]` e
   `[C_26_Request && (St_P2P1_5_10 || P2P1_Armed)]`. O armamento evita sair com um `PD_Cart = 1`
   antigo do ciclo anterior.

**Verificacao:** harness isolado compila e simula sem erro; `V0_4_24_R2025b.slx` exportado com
`exportToVersion` (R2025b); no XML: 19 latches, 5 referencias a `P2P1_Armed`, nenhuma guarda com
`Claw_High == true`.

**Limite:** se a simulacao comecar com o ciclo ja concluido (`PD_Cart = 1` o tempo todo), o
`P2P1_Armed` nunca arma e a sombra espera o proximo ciclo -- comportamento correto de sombra.

Modelo: `FullFMS_2026_02_25_V0_4_24_R2025b.slx` (teste) / `_R2026a.slx` (fonte).

**Teste com a planta:** Handling 2 passou; `CartToProcessing1` passou tao rapido que nem deu para
ver; parou no `Inspecao_Visn` (todos os `C_2x_*` em 0 no momento).

---

## v0.4.24 --> v0.4.25  (Vision: `C_26_CartDel` e pulso de 3 s + pedido do Robot)

### Diagnostico (lido no ladder, rasterizado)
- `Master/FB11` rede 20 ("Cart Arrived"): `M3.0 FB11_Visi && I14.4 Visi_Cart_Stat` -> **`T3` SE
  S5T#3S** e reseta `M3.6`, `M3.0`, `M7.1`. Rede 21: `T3` -> `C_26_CartDel`. Logo **`C_26_CartDel` e
  um pulso de 3 s**.
- O `Inspecao_Visn` (passagem simbolica de 5 s) exigia `C_26_CartDel = 1` **no instante dos 5 s**
  (`[St_Visn_2 && after(5,sec)]` com `else St = false`). Com pulso de 3 s isso e **impossivel** --
  a Vision travaria em todo ciclo.
- `Master/FB11` rede 22: `C_27_Request` (Q27.1, pedido OPC) **seta** `M4.0 FB11_Robot` (bobina S). O
  CLP guarda o pedido; o modelo exigia `C_27_Request` instantaneo na saida da Vision, de novo na
  juncao `J1014` e de novo no `Config_Cv27` -- tres leituras do mesmo pulso em passos diferentes.

### Correcao
- **Vision:** captura no `entry` + latch nos 3 passos. `Config`/`Inspecao` aceitam
  `C_26_CartDel || O_26_Cart_Stat` (carro presente na Vision, sinal mantido). Novo dado local
  `Vis_Req27`: zerado no `entry` da Vision com o valor atual de `C_27_Request` e setado no `during`
  sempre que o pedido aparece -- equivalente observavel do `M4.0`, inclusive se o pedido chegar
  durante a inspecao. `FinishesProcess_Visn` = `C_27_Request || Vis_Req27`.
- **Saida:** `Vision -> J1010` e `J1014 -> CartToProcessing2` agora `[St_Visn_3 == true]` (o pedido
  ja foi registrado). `J1010`/`J1014` so recebem da Vision; `CartToProcessing2` so e alcancado por eles.
- **`CartToProcessing2`:** `Config_Cv27` = `C_27_Request || Vis_Req27` (latch); nos ramos
  `De*` e nas transicoes `Config -> De*`, `C_27_Request` instantaneo trocado pelo flag latchado
  `St_Cv27_1`. Todos os passos do bloco com captura + latch. A saida do bloco ja era pelo proprio
  CLP (`C_27_CartDel`).

**Verificacao:** harness isolado compila e simula sem erro; `V0_4_25_R2025b.slx` exportado com
`exportToVersion` (R2025b), 8 referencias a `Vis_Req27` no XML.

**Atencao:** os outros blocos de esteira (`CartToTesting`, `CartToProcessing1/3/4`) tem o mesmo
padrao (`C_2x_Request` instantaneo nas transicoes, `C_2x_CartDel` pulso de 3 s, `Cart_Next`/`Count`
momentaneos). Nao foram alterados nesta versao.

Modelo: `FullFMS_2026_02_25_V0_4_25_R2025b.slx` (teste) / `_R2026a.slx` (fonte).

---
## v0.4.25 --> v0.4.26  (Vision guiada pelo roteamento `C_26_CRoute_In` / `C_26_CRoute_Out`)

### Diagnostico
A v0.4.25 ainda travava em `Inspecao_Visn`. O orientador indicou o sinal de "route out". Conferido no
ladder (`Master/FB2`, pag. 15, rasterizado):
- **Rede 31** "26 CRoute In": `Q26.2 C_26_CRoute_In` (OPC Route Arrive) -> `Q23.6 A_23_CRoute_In`
  (Route Arrive (Vision)).
- **Rede 32**: `I23.6 A_23_CRoute_Out` (Route Depart (Vision)) **OU** `A_23_CRoute_In` mantido por
  1 s (`T9 FB2_VisionRoute`, S_ODT S5T#1S) -> `I26.7 C_26_CRoute_Out` (OPC Route Depart).
- O mesmo par existe para todos os modulos da esteira (24..29) e nas estacoes os AS-i se chamam
  "Cart Arrived - Routing" / "Process Finished - Routing". Ou seja, **o fim da inspecao e o
  `C_26_CRoute_Out`**; os 5 s simbolicos eram suposicao.
- `Q26.2 C_26_CRoute_In` nao e escrito por nenhum bloco do Master: vem do cliente OPC externo
  (igual ao `Q26.1 C_26_Request`, `FB11` rede 15).
- Enderecos conferidos em `Variables_Master.csv`: CartDel `i=1462`, CRoute_Out `i=1472`, Request
  `i=1482`, CRoute_In `i=1492` (itens 18..21 do `OPC UA Read-MASTER`).

### Correcao
- **Vision (pai):** novos locais `Vis_RIn`, `Vis_ROut`, `Vis_Cart`. `entry` captura `C_26_CRoute_In`,
  `C_26_CRoute_Out`, `C_27_Request` e marca `Vis_Cart = true` (a entrada e por `C_26_CartDel`, que
  pela `FB11` N20/N21 so existe com `I14.4 Visi_Cart_Stat`); `during` faz latch dos tres sinais.
- **`Config_Visn`:** `C_26_CartDel || O_26_Cart_Stat || Vis_RIn || Vis_ROut` (captura + latch).
- **`Inspecao_Visn`:** `C_26_CRoute_Out || Vis_ROut` (captura + latch). Removido o `after(5,sec)`.
- **`Inspecao -> FinishesProcess`:** `[St_Visn_2 == true || Vis_Req27 == true]` -- o `C_27_Request`
  (`FB11` N22 seta `M4.0`) e saida autoritativa do CLP: ele leva o carro ao Robot mesmo sem
  roteamento da Vision.
- **`CartToProcessing2`:** `Config_Cv27 -> DeVision_Cv27` = `St_Cv27_1 && (O_26_Cart_Stat ||
  Vis_Cart)`, prioridade 1 (`FB11` N2); `DeVision_Cv27` idem. `exit` do bloco zera `Vis_Cart`.
  Motivo: o `I14.4` pode cair assim que o carro e liberado.

**Verificacao:** harness isolado (`harness_v4_26.m`) compila e simula sem erro; `V0_4_26_R2025b.slx`
exportado com `exportToVersion` (`MDLInfo` = R2025b), `Vis_ROut` presente no XML. Script de
criacao: `cria_v4_26.m`.

**No teste:** observar se `C_26_CRoute_In` / `C_26_CRoute_Out` vao a 1 com o carro na Vision. Se o
cliente OPC nao pedir o roteamento, a Vision sai so pelo `C_27_Request`.

Modelo: `FullFMS_2026_02_25_V0_4_26_R2025b.slx` (teste) / `_R2026a.slx` (fonte).

---
## v0.4.26 --> v0.4.27  (Vision: zera `St_Visn_3` no `entry`)

### Diagnostico
`St_Visn_3` so era escrito no `FinishesProcess_Visn` (captura + latch) e nunca voltava a `false`. A
saida `Vision -> J2015 [St_Visn_3 == true]` e avaliada antes dos subestados, entao a partir do
**2o carrinho** a Vision lia o `true` do ciclo anterior e saia no 1o passo, sem esperar a inspecao
nem o `C_27_Request`.

### Correcao
- **Vision (pai):** primeira linha do `entry` = `St_Visn_3 = false;`.

**Verificacao:** harness isolado compila e simula sem erro; `V0_4_27_R2025b.slx` exportado com
`exportToVersion`. (Os scripts de criacao/harness desta versao foram apagados a pedido.)

**Teste na planta (20/10):** Vision OK. Parou no `CartToProcessing2` porque `C_30_Robot1` e
`C_30_Robot2` estavam em 0 -- o modo do robo nao tinha sido selecionado no sistema (Config 1 =
Routine 1, ver `Config Setups.xlsx`). Corrigido na planta, o carro passou pelo Robot e parou no
`RBS` da Sorting (v0.4.28).

**No teste:** confirmar que o 2o carrinho espera na Vision; `C_30_Robot1` ou `C_30_Robot2` precisa
estar ligado quando o carro chega no Robot (senao `J2035` fica sem saida e o chart para em
`CartToProcessing2`). Obs.: `CarroProximo_Cv27` espera `O_27_Cart_Next`, que no Historian so liga na
saida do Robot -- nao trava (a saida do bloco e por `C_27_CartDel`), mas conferir a rede N4 da `FB11`.

Modelo: `FullFMS_2026_02_25_V0_4_27_R2025b.slx` (teste) / `_R2026a.slx` (fonte).

---
## v0.4.27 --> v0.4.28  (Sorting: partida dos 6 blocos + saida para o `Start`)

### Diagnostico (teste na planta, 20/10)
O chart parou no `STATE2` do `RBS`. Valores lidos na simulacao: `C_65_RBS_Output = 1`,
`C_65_Initialization = 0`, `C_55_PD_Sort = 1`, `O_50_Claw_Del = 0`, `StatusRBS_1 = 0`.
- `StatusRBS_1` exigia `C_65_Initialization && C_65_RBS_Output` -- o `Initialization` esta em 0 com a
  estacao rodando, entao o primeiro passo nunca ligava.
- A transicao `STATE2 -> ESTATE7` exigia `C_55_PD_Sort && O_50_Claw_Del && StatusRBS_1`. No Historian
  o `Claw_Del` fica so ~300 ms junto com o `PD_Sort` (a garra do Handling 1 volta logo para o carrinho)
  e o `PD_Sort` continua ligado -- o mesmo padrao de pulso curto do Handling 2.

### Correcao (Claude, 20/10)
Nos **6 blocos** da Sorting (`RBS`, `RSB`, `BRS`, `BSR`, `SRB`, `SBR`):
- Primeiro estado: `C_65_Initialization &&` removido -- fica so o bit de saida (`C_65_xxx_Output`).
- Primeira transicao: `O_50_Claw_Del == true &&` removido -- fica `C_55_PD_Sort && Status..._1`.
Harness isolado compila e simula sem erro. Exportado com `exportToVersion`.

### Saida para o `Start` (usuario, 22/10, so no `_R2025b.slx`)
- Adicionada uma transicao **sem condicao** de cada bloco da Sorting para o `Start` (borda do bloco
  pai -> `Start`, ordem de execucao 1).
- Removido o laco interno de volta ao primeiro estado (`ESTATE8 -> STATE2` no `RBS`,
  `ESTATE5 -> STATE1` nos outros 5).
- Isso fecha a pendencia "a Sorting nao tem transicao de saida".

> **Atencao:** uma transicao de saida **sem condicao** que parte da borda do bloco pai e testada a
> cada passo antes dos subestados -- o chart sai para o `Start` no passo seguinte a entrada, sem
> rodar a classificacao. Para sair so no fim do ciclo, a transicao deve partir do ultimo estado
> (`ESTATE8` / `ESTATE5`) ou ter a condicao do fim, ex.: `[StatusRBS_5 == true]`.
>
> **O `_R2026a.slx` da v0.4.28 nao tem essa mudanca** (so a correcao de partida). Se o R2026a for
> usado como fonte da proxima versao, refazer as 6 saidas nele antes.

Modelo: `FullFMS_2026_02_25_V0_4_28_R2025b.slx` (teste, com a saida para o `Start`) /
`_R2026a.slx` (fonte, sem a saida).

---
## v0.4.28 --> v0.4.29  (Sorting: saida para o `Start` so no fim do ciclo)

### Diagnostico
As 6 saidas `bloco -> Start` da v0.4.28 nao tinham condicao e partiam da borda do bloco pai. Uma
transicao assim e testada a cada passo antes dos subestados: o chart sairia para o `Start` no passo
seguinte a entrada, sem rodar a classificacao.

### Correcao
Nos 6 blocos da Sorting (`RBS`, `RSB`, `BRS`, `BSR`, `SRB`, `SBR`):
- Saida `bloco -> Start` = `[StatusXXX_5 == true]` (fim de ciclo: pino de identificacao recuado,
  escrito no ultimo estado -- `ESTATE8` no `RBS`, `ESTATE5` nos outros).
- `entry` do bloco pai = `StatusXXX_5 = false;` -- sem isso, no 2o ciclo a saida veria o `true` do
  ciclo anterior e o bloco sairia logo na entrada (mesmo caso do `St_Visn_3` na v0.4.27).

**Verificacao:** harness isolado compila e simula sem erro. Base: `V0_4_28_R2025b.slx` (com as saidas
do usuario); salvo como `_R2026a` e exportado com `exportToVersion` para `_R2025b`. As duas versoes da
v0.4.29 tem as saidas para o `Start`.

Modelo: `FullFMS_2026_02_25_V0_4_29_R2025b.slx` (teste) / `_R2026a.slx` (fonte).

---
## v0.4.29 --> v0.4.30  (Handling 2: zera `St_P2P1_5_10` no `entry` do `ProcessingToPart`)

### Diagnostico (auditoria de flags, 27/10)
Varredura de todas as transicoes do Chart que leem uma variavel local: a flag precisa ser
zerada/recalculada no `entry` do estado de origem (ou de um bloco pai), que roda de novo a cada
carrinho. So uma falhou:
- `St_P2P1_5_10` e escrita apenas no `PecaEntregue_P2P1` (captura + latch) e nunca voltava a `false`.
  Ela e lida na saida `ProcessingToPart -> J1861 [(St_P2P1_5_10 || P2P1_Armed) && C_95_PD_Cart]` e em
  `J1861 -> CartToProcessing1`. O `P2P1_Armed` (zerado no `entry`) existe para so liberar a saida
  depois que o `C_95_PD_Cart` cai e volta a 1 no ciclo atual. Com o `St_P2P1_5_10` ainda `true` do
  carrinho anterior, se o `C_95_PD_Cart` estiver em 1 no instante da entrada (o FB5 N1 so o reseta
  com o `Part_ready`), o bloco sai na entrada, sem rodar a sequencia do Handling 2.
- `Vis_Cart` tambem aparece na varredura, mas e intencional: liga no `entry` da Vision e e zerado no
  `exit` do `CartToProcessing2`.

### Correcao
- **`ProcessingToPart` (pai):** `entry` = `P2P1_Armed = false;` + `St_P2P1_5_10 = false;`.
- Efeito no 1o carrinho: nenhum (a flag ja comecava em `false` pelo valor inicial). Do 2o em diante o
  bloco volta a se comportar como no 1o.

**Verificacao:** harness isolado compila e simula sem erro. Base: `V0_4_29_R2026a`; exportado com
`exportToVersion` para `_R2025b`.

Modelo: `FullFMS_2026_02_25_V0_4_30_R2025b.slx` (teste) / `_R2026a.slx` (fonte).

---
## v0.4.30 --> v0.4.31  (Sorting: pino de identificacao com latch)

### Diagnostico (teste na planta, 27/10)
O chart parou no `ESTATE6` do `RBS`. A transicao `ESTATE6 -> ESTATE8` exigia
`O_60_Part_Pass && StatusRBS_4`, com `StatusRBS_4` = `F_62_Identify` no `during` (com `else false`).
No Historian o CLP desliga o pino **no mesmo instante** em que a peca passa:
| Historian | `F_62_Identify` cai | `O_60_Part_Pass` | Sobreposicao |
|---|---|---|---|
| 01 | 54,593 s | 54,546 - 54,701 s | ~47 ms |
| 06 | 04,469 s | 04,419 - 04,575 s | ~50 ms |
| 10 | 23,688 s | 23,688 - 23,805 s | **0 ms** |
Com o `else false`, o `StatusRBS_4` cai junto com o pino e a transicao quase nunca ve os dois juntos.

### Correcao
Nos 6 blocos da Sorting (estado do pino: `ESTATE6` no `RBS`, `ESTATE4` nos outros):
- Estado do pino: captura no `entry` (`StatusXXX_4 = F_62_Identify;`) + latch no `during` (sem `else`).
- Transicao seguinte: `[(O_60_Part_Pass == true || F_62_Identify == false) && StatusXXX_4 == true]` --
  depois de ver o pino acionado, a queda do pino (sinal de nivel) tambem fecha o passo; o `Part_Pass`
  e um pulso de ~150 ms.

**Verificacao:** harness isolado compila e simula sem erro. Base: `V0_4_30_R2026a`; exportado com
`exportToVersion` para `_R2025b`.

Modelo: `FullFMS_2026_02_25_V0_4_31_R2025b.slx` (teste) / `_R2026a.slx` (fonte).

---

## v0.4.31 --> v0.5.0  (escrita OPC UA das variaveis simuladas)

Inicio do modelo de simulacao: o chart vai escrever nos nos simulados dos servidores
(coluna "Simulated TAG" da planilha `Tags FMS V7.0.7.xlsx`). **O chart nao foi alterado**
(arquivos do Stateflow identicos aos da v0.4.31).

### Blocos novos (um conjunto por servidor: MASTER, NODE, HD1, SORT, TEST, DIST, HD2, PROC)
`BUS_SIM_IN_<srv>` (Bus Creator, `Bus: B_SIM_<srv>`) --> `BUS_SIM_<srv>` (Bus Selector) --> `OPC UA Write-<srv>`
- O Write aponta para o mesmo servidor do `OPC UA Read-<srv>` (no script: `SelectedServer` antes de `ServerList`).
- O Write tem **uma entrada por no**; a saida k do Bus Selector vai na entrada k do Write.
- As entradas dos Bus Creators estao vazias: as saidas do chart ainda nao existem.
  Decisao: essas saidas (`SimSensors_50`, ... tipo `Bus: B_SimSensors_50`) e as linhas ate o
  Bus Creator sao fixas, entao serao criadas direto no modelo, nao por script.
- `PreLoadFcn`: `load("BUS_CONFIG.mat"); load("BUS_CONFIG_SIM.mat")`.

### Arquivos novos
| Arquivo | Funcao |
|---|---|
| `Tags_SIM_V0_1_20261120.m` | Tags simuladas por servidor e grupo (`SimActuators_NN`, `SimASi_NN`, `SimControl_NN`, `SimSensors_NN`, `SimRFID_RFID`), mesma estrutura do `Tags_V0_4_20260221.m`. `AllVariablesSimNames` guarda o nome de cada grupo (usado nos buses e no Bus Selector). Nomes corrigidos em relacao a planilha: `SC_2x_CRoute_Out` e `SC_85_Part_Mag`. |
| `Connect_OPCUA_Write.m` | Equivalente do `Connect_OPCUA.m` para a escrita: baixa os `Variables.csv`, cria os bus objects, acha o `i=` de cada tag simulada pelo nome e grava o `NodeList` do Write, o `OutputSignals` do Bus Selector e as linhas Selector->Write, sempre na ordem do Tags_SIM. |
| `BUS_CONFIG_SIM.mat` | 41 bus objects: `B_Sim<grupo>_NN` (tags do grupo) e `B_SIM_<srv>` (grupos do servidor). Tags de CartID, contadores e RFID = `double`, resto `boolean`. |

### Index do AAS
Os index nao ficam fixos no modelo. **Depois de cada atualizacao do AAS, rodar o
`Connect_OPCUA_Write.m`** (como o `Connect_OPCUA.m`). Tag que nao estiver no CSV sai do
NodeList, do Bus Selector e das linhas ao mesmo tempo, e o script avisa.

### Pendente
- Os `Write` estao sem nos: os `Variables_*.csv` locais (06/10) nao tem tags simuladas e as
  TV boxes nao respondem fora da rede do laboratorio. Rodar o script no laboratorio.
- Ate as saidas do chart existirem, a compilacao reclama das entradas vazias dos Bus Creators.

Modelo: `FullFMS_2026_02_25_V0_5_0_R2025b.slx` (teste) / `_R2026a.slx` (fonte).

---

## v0.5.0 --> v0.6.0  (Chart_SIM: piloto Handling 1 + parada 29)

Primeiro modelo de simulacao. Chart novo `Chart_SIM` no topo (x ~ -960, a esquerda dos
`BUS_SIM_IN_*`), `SampleTime = Ts_SIM` (0.05 s), sem entradas, linguagem MATLAB.
**O chart da sombra (`Chart`) nao foi alterado**: o XML dele na v0.6.0 e identico ao da
v0.5.0, exceto o id interno do chart (3980 -> 4085, renumeracao feita pelo save).

### Saidas e ligacoes
| Porta | Saida | Tipo | Destino |
|---|---|---|---|
| 1-3 | `SimActuators_20`, `SimControl_20`, `SimSensors_20` | `Bus: B_<nome>` | `BUS_SIM_IN_MASTER` 1-3 |
| 4-7 | `SimActuators_50`, `SimASi_50`, `SimControl_50`, `SimSensors_50` | `Bus: B_<nome>` | `BUS_SIM_IN_HD1` 1-4 |

Os outros `BUS_SIM_IN_*` continuam sem entrada. Campos de bus nao usados ficam em 0.
- Parametros: `T_HD1_T1`, `T_CONV_T6`, `t_v_down`, `t_v_up`, `t_h_del`, `t_h_cart`, `t_grip`,
  `t_conv`, `t_leave`, `t_sort_clear`, `N_PARTS` (definidos em `Param_SIM_V0_6.m`).
- Locais: `SPart60` (peca na Sorting), `PartOnCart`, `CartAt29`, `CRouteIn54`, `Claw2CartCmd` (boolean), `nDone` (double).
- `PreLoadFcn`: `load("BUS_CONFIG.mat"); load("BUS_CONFIG_SIM.mat"); run("Param_SIM_V0_6.m")`.

### Estrutura Controle / Planta (3 estados paralelos, nesta ordem de execucao)
1. `Conveyor29` (Master FB11, parada 29, simplificado):
   `Idle -> Arriving [nDone < N_PARTS] -> AtStop after(t_conv) -> Delivered after(T_CONV_T6) -> Leaving [SR_54_CRoute_Out] -> Idle after(t_leave)`.
   `AtStop` liga `SS_29_Count/Cart_Stat/Optic` e poe a peca no carro; `Delivered` liga `SC_29_CartDel` e `SR_54_CRoute_In`; `during: SS_29_Optic = PartOnCart`.
2. `HD1_Ctrl` (controle = ladder `Hd1/FB4 Cart_2_Del`): sequencia abaixo. So escreve atuadores e controles.
3. `HD1_Plant` (planta = resposta fisica): 4 sub-estados paralelos que leem os atuadores e escrevem os sensores.
   - `Vertical`: High / GoingDown (t_v_down) / Low / GoingUp (t_v_up); inverte no meio se o comando mudar.
   - `Horizontal`: AtCart / ToDel (t_h_del) / AtDel / ToCart (t_h_cart).
   - `Gripper`: Empty / Gripping (t_grip) / Holding / Releasing (t_grip). Pega so se garra embaixo, no carro e `PartOnCart`; ao soltar, `SPart60 = SS_50_Claw_Del`.
   - `SortingFeed`: NoPart / HasPart; a Sorting leva a peca depois de `t_sort_clear` (`SPart60 = false`).

### Sequencia do HD1_Ctrl x ladder (`Hd1/FB4`, redes N1..N9)
| Estado | Condicao de entrada | Acao (entry) |
|---|---|---|
| `Init` (FB1) | default | `SC_52_Profibus`; zera atuadores |
| `Ready` | `Claw_Cart && Claw_High && ~Part_in_Claw` | `SC_55_Initialization` |
| `N1_StartMove` | `CRouteIn54 && CartAt29 && SS_29_Optic && ~SPart60` | `SC_55_PD_Sort = 0` |
| `N2_LowerClaw` | `~PD_Sort && Claw_Cart && Claw_High && ~Part_in_Claw` | `Claw_Down = 1` |
| `N3_CloseClaw` | `Claw_Cart && Claw_Low` | `Close_Claw = 1` |
| `N3_Raise` | `Part_in_Claw` | `Claw_Down = 0` |
| `N4_Claw2Del` | `Claw_High && Part_in_Claw && ~Claw_Del` | `Claw_2_Cart = 0; Claw_2_Del = 1` |
| `N5_LowerClaw2` | `Claw_Del && Claw_High && Part_in_Claw` | `Claw_Down = 1` |
| `N6_Release` | `Claw_Del && Claw_Low` | `Close_Claw = 0` |
| `N6_Raise` | `~Part_in_Claw` | `Claw_Down = 0` |
| `N7_PDSort` | `Claw_Del && Claw_High && ~Part_in_Claw` | `SC_55_PD_Sort = 1` |
| `N8_Claw2Cart` | incondicional | `Claw_2_Del = 0; Claw_2_Cart = 1` |
| `N9_CRouteOut` | `Claw_Cart` (borda NEG do Claw2Cart -> T1 S_PEXT) | `SR_54_CRoute_Out = 1`; exit: zera e `nDone++` |
| volta a `Ready` | `after(T_HD1_T1)` | |

### Tempos usados (`Param_SIM_V0_6.m`)
| Parametro | Valor | Origem |
|---|---|---|
| `T_HD1_T1` | 2 s | ladder exato (Hd1 FB4 T1 S_PEXT); Historian mostra pulso de ~1.9 s no `A_54_CRoute_Out` |
| `T_CONV_T6` | 3 s | ladder exato (Master FB11 T6 SE) |
| `t_v_down` | 0.93 s | Historian: `F_52_Claw_Down` sobe -> `O_50_Claw_Low` (n=38, 0.82..0.98) |
| `t_v_up` | 1.37 s | Historian: `F_52_Claw_Down` desce -> `O_50_Claw_High` (n=38, 1.25..1.44) |
| `t_h_del` | 2.82 s | Historian: `F_52_Claw_2_Del` -> `O_50_Claw_Del` (n=19) |
| `t_h_cart` | 2.38 s | Historian: `F_52_Claw_2_Cart` -> `O_50_Claw_Cart` (n=19) |
| `t_grip` | 0.10 s | Historian deu 0.01 s (fechar) e 0.08 s (abrir); usado 2*Ts_SIM |
| `t_conv` | 5 s | estimado (o Historian nao isola o transporte do carro) |
| `t_leave` | 2 s | estimado |
| `t_sort_clear` | 3 s | provisorio |
| `N_PARTS` | 3 | cenario |

Subida e descida da garra sao bem diferentes (0.93 x 1.37 s), assim como ida e volta (2.82 x 2.38 s),
por isso o `t_v`/`t_h` unico foi trocado por dois tempos cada (`t_v`/`t_h` ficam no .m so como media).
Observacao: no Historian `O_29_Count -> C_29_CartDel` leva ~1.2 s (n=17), e nao 3 s; o T6 pode nao
estar nesse caminho. Mantido o T6 do ladder ate conferir.

### Verificacao (modelo temporario em `%TEMP%`, sem OPC, 90 s, FixedStep 0.01)
`nDone` chega a 3 (t = 20.70, 41.45, 62.20 s) -> **ciclo de 20.75 s por peca** (60 s nao bastam para 3 pecas).
Linha do tempo da 1a peca (s):
`Arriving 0.05 | AtStop 5.05 | Delivered/CRoute_In/N1 8.05 | N2 8.10 | Claw_Low 9.05 | N3 9.10 |
Part_in_Claw 9.20 | N3_Raise 9.25 | Claw_High 10.65 | N4 10.70 | Claw_Del 13.55 | N5 13.60 | Claw_Low 14.55 |
N6 14.60 | Part_in_Claw=0, SPart60 14.70 | N6_Raise 14.75 | Claw_High 16.15 | N7 16.20 | N8 16.25 |
Claw_Cart 18.65 | N9/CRoute_Out 18.70 | Leaving 18.75 | nDone=1, Ready 20.70 | Idle 20.75 | 2o carro 20.80`.
Garra do CartDel ao CRoute_Out: 10.65 s no modelo x ~10.2 s no Historian 01.
`Ctrl+D` na v0.6.0: para no primeiro `BUS_SIM_IN_*` sem entrada (`BUS_SIM_IN_TEST` / `_SORT`),
como esperado; nenhum erro citou o Chart_SIM, o `BUS_SIM_IN_MASTER` ou o `BUS_SIM_IN_HD1`. A compilacao
completa so sera possivel quando as outras estacoes estiverem ligadas. O mesmo chart compila e roda sozinho.

### Armadilhas encontradas
- Bus de saida lido antes de ser escrito (erro em tempo de execucao): o `Init` agora escreve os 4 atuadores, `PD_Sort` e `CRoute_Out`.
- Transicao de retorno com `SourceOClock = 3` tem o arco empurrado para fora do pai e vira supertransicao
  (o `HD1_Plant` inteiro reentrava). Corrigido com `MidPoint` e rotulo dentro do pai e pai mais largo; o
  script de construcao confere o pai de cada transicao.

### Pendente
- Outras estacoes (MASTER restante, NODE, SORT, TEST, DIST, HD2, PROC).
- `SS_60_SPart` ainda e local (`SPart60`), nao vai para o bus da Sorting.
- `Connect_OPCUA_Write.m` ainda aponta para a v0.5.0 (e `Connect_OPCUA.m` para a v0.4.18).
- Conferir `t_conv`, `t_leave` e o T6 com dados da esteira.

Modelo: `FullFMS_2026_02_25_V0_6_0_R2025b.slx` (teste) / `_R2026a.slx` (fonte).

## FullFMS_SIM v0.1.0  (modelo de simulacao separado)

A partir de agora a simulacao fica num `.slx` proprio, `FullFMS_SIM_V0_1_0_R2026a.slx` (fonte) /
`_R2025b.slx` (teste), so com o `Chart_SIM` e a cadeia de escrita:
`Chart_SIM -> BUS_SIM_IN_<srv> -> BUS_SIM_<srv> -> OPC UA Write-<srv>` (8 servidores).
A sombra (chart `Chart`, `OPC UA Read-*`, `BUS_<srv>`, `MATLAB Function*`, Bus Creators de
leitura) continua nos `FullFMS_2026_02_25_*`; a v0.6.0 nao foi alterada.

- Feito a partir da v0.6.0 (save com novo nome + `delete_block` do resto): 1 chart + 24 blocos
  (8 `BUS_SIM_IN_*`, 8 `BUS_SIM_*`, 8 `OPC UA Write-*`) com os mesmos nomes, posicoes e parametros.
- Linhas: `Chart_SIM -> BUS_SIM_IN_MASTER` (3), `Chart_SIM -> BUS_SIM_IN_HD1` (4) e
  `BUS_SIM_IN_<srv> -> BUS_SIM_<srv>` (8). As linhas `BUS_SIM_<srv> -> OPC UA Write-<srv>` nao
  existem no .slx (nem existiam na v0.6.0): sao criadas pelo `Connect_OPCUA_Write.m`.
- `PreLoadFcn`: `load("BUS_CONFIG_SIM.mat"); run("Param_SIM_V0_6.m")` (o `BUS_CONFIG.mat` era so
  da leitura). Nenhum bloco usa mais `B_Actuators/B_Control/B_Sensors/B_AS_i`.
- `Ctrl+D`: para em `BUS_SIM_IN_SORT` (sem entrada, falta `B_SimActuators_60`), como na v0.6.0;
  nenhum erro cita o `Chart_SIM`, o `BUS_SIM_IN_MASTER` ou o `BUS_SIM_IN_HD1`.
- `Connect_OPCUA_Write.m` aponta para `FullFMS_SIM_V0_1_0_R2025b`.
- Cuidado: sem servidor OPC UA, um `get_param(...,'PortHandles')` num `OPC UA Write-*` leva ~50 s
  (inicializacao da mascara); para scripts longos use `matlab -batch`.

## FullFMS_SIM v0.1.0 --> v0.1.2  (Sorting [60])

Sorting no `Chart_SIM`, no mesmo nivel da sombra: controle = ladder rede a rede (`OB1`, `FB1`,
`FB3`, `FB4`..`FB9`, lidos renderizados, polaridade NA/NF conferida) + planta com tempos do Historian.
Feito a partir da v0.1.0 (save com novo nome; a v0.1.0 nao mudou). O chart e reconstruido pelo `build_chart_sim_V0_1_2.m` (nesta pasta).

### Saidas e ligacoes
| Porta | Saida | Destino |
|---|---|---|
| 1-3 | `SimActuators_20`, `SimControl_20`, `SimSensors_20` | `BUS_SIM_IN_MASTER` 1-3 |
| 4-7 | `SimActuators_50`, `SimASi_50`, `SimControl_50`, `SimSensors_50` | `BUS_SIM_IN_HD1` 1-4 |
| 8-10 | `SimActuators_60`, `SimControl_60`, `SimSensors_60` (`Bus: B_Sim..._60`) | `BUS_SIM_IN_SORT` 1-3 (ordem do `B_SIM_SORT`) |

- `PreLoadFcn`: `load("BUS_CONFIG_SIM.mat"); run("Param_SIM_V0_1_2.m")`.
- Ordem dos estados de topo: `Conveyor29`, `HD1_Ctrl`, `HD1_Plant`, `SORT_Ctrl`, `SORT_Plant`.
- O local `SPart60` saiu: o `HD1_Plant.Gripper` liga o sensor real `SimSensors_60.SS_60_SPart` ao
  soltar a peca na posicao de entrega, e o N1 do `HD1_Ctrl` le `~SS_60_SPart` (como o ladder).
  O estado `SortingFeed` (peca sumia apos `t_sort_clear`) foi removido.
- Contadores: `nCart` (carros atendidos pelo Hd1, ++ na saida do N9; o `Conveyor29` chama carro
  enquanto `nCart < N_PARTS`) e `nDone` (pecas classificadas, ++ quando a peca chega ao `Part_Pass`).
  `nSortIn` conta as pecas que entraram na esteira e escolhe a cor `PART_COLORS(nSortIn)`.

### Controle (`SORT_Ctrl`, 4 paralelos) x ladder
| Estado / transicao | Ladder | O que faz |
|---|---|---|
| entry do `SORT_Ctrl` | supervisorio | `SC_65_<modo>_Output = (SORT_MODE == k)`; zera todos os `SC_*` e `SA_*` |
| `FB1_N2_Check` | FB1 N2 | `C_62_Profibus`; vai para `FB1_N1_InitOk` se `~FB1Conv & ~SPart & ~SInd & ~SPhoto & ~Part_Pass` |
| `FB1_N3_ClearPart` | FB1 N3 | peca na estacao: `FB1_Conveyor` e `FB1_IDPin` (S); reset com `FB1_Conveyor & Part_Pass` |
| `FB1_N1_InitOk` | FB1 N1/N2 | `FB1_Init` (M0.0) = `C_65_Initialization`; volta ao N2 com `Reset` (N4..N8 zeram MB0..MB4) |
| `OB1_N4_9_Select` | OB1 N4..N9 | FB do modo so roda com `FB1_Init & C_65_xxx_Output`; dispara com `C_55_PD_Sort & O_50_Claw_Del` |
| `N1_StartConv` | FBx N1 | S `TrigConv`; R `ID_1`, `ID_2`; dispara `Tx` SE 2 s |
| `N2_Identify` | FBx N2 | durante `Tx`: `SInd` -> 01; `~SInd & SPhoto` -> 11; `~SInd & ~SPhoto` -> 10 |
| `N3_SelectLever` | FBx N3 | depois de `Tx`: `Lever1`/`Lever2`/passa direto pelos bits e pelo modo; S `Pin` com `SL1_Fwd` / `SL2_Fwd` / (`SL1_Bck & SL2_Bck`) |
| `N4_PartDel` | FBx N4 | `TrigConv & ~Tx & Part_Pass` -> S `PartDel`; derruba as alavancas |
| `N5_ResetNext` | FBx N5 | `PartDel` -> R `TrigConv`, `Pin`, `PartDel`; volta ao `OB1_N4_9_Select` |
| `N10_PartPass` -> `N11_PartSorted` | OB1 N10/N11 | borda NEG do `Part_Pass` -> T7 SE 4 s -> `C_65_Part_Sorted` |
| `FB3_Map` | FB3 N1..N12 | com `Key_Pos`: `Conveyor = TrigConv or FB1_Conveyor`, `P1 = Lever1`, `P2 = Lever2`, `Identify = Pin or FB1_IDPin`, `Led_Start = FB1_Init`, `Led_Extra1 = Part_Sorted` |

Os 6 FBs tem as mesmas 5 redes; muda so o destino de cada cor (N3). O chart tem um bloco
parametrizado (`FB4_9_Sort`) e a tabela `SORT_MAP` do `Param_SIM_V0_1_2.m`.
Bits: vermelha = `ID_1 & ID_2`, preta = `ID_1 & ~ID_2`, metalica = `~ID_1 & ID_2`.

| `SORT_MODE` | FB | Alavanca 1 (`P1`) | Alavanca 2 (`P2`) | Passa direto | Timer |
|---|---|---|---|---|---|
| 1 | FB4 RBS | vermelha | preta | metalica | T1 |
| 2 | FB5 RSB | vermelha | metalica | preta | T2 |
| 3 | FB6 BRS | preta | vermelha | metalica | T3 |
| 4 | FB7 BSR | preta | metalica | vermelha | T4 |
| 5 | FB8 SRB | metalica | vermelha | preta | T5 |
| 6 | FB9 SBR | metalica | preta | vermelha | T6 |

Erros do ladder encontrados (mantidos ou contornados):
- **FB6 N3**: a bobina `FB6_Lever2` le `~"FB5_PartDel"` (M1.4) em vez do `FB6_PartDel` (M2.1). No
  modo 3 a alavanca 2 nao cai no N4, so no N5 (mesmo ciclo do CLP). Replicado.
- **FB9 N4**: o contato e `~T11` (nunca disparado) em vez de `~T6`. Tratado como `T6` (como os outros 5 FBs);
  no CLP real o `PartDel` do FB9 pode ligar durante a janela de identificacao se o `Part_Pass` piscar.
- O T1..T6 e uma bobina `SE`: no S7 em ingles `SE` = pulso prolongado (S_PEXT), entao a janela de 2 s
  conta da borda de subida de `PD_Sort & Claw_Del`, mesmo com o `Claw_Del` caindo logo depois.

### Planta (`SORT_Plant`, 3 paralelos)
- `Part`: `Empty -> AtEntry [SS_60_SPart] -> ToStopper [Conveyor] -> AtStopper -> Released [Identify & Conveyor] -> PartPass -> Empty`.
  A peca anda so com a esteira ligada (`xSort` soma `Ts_SIM` enquanto `ConvOn60`). No `ToStopper`:
  `SPart` cai, `SPhoto` liga (vermelha/metalica), `SInd` liga (so metalica); a peca para no pino.
  No `Released` a saida e decidida pela alavanca avancada (1, 2 ou 3 = direto) e os sensores caem;
  o `Part_Pass` vem depois do tempo de cada saida.
- `Lever1` / `Lever2`: `Bck -> ToFwd -> Fwd -> ToBck` (inverte no meio se o comando mudar).
- Painel: `SS_61_Key_Pos = true` (automatico), `Start/Stop/Reset/Panel_I4..I7 = false`.

### Tempos (`Param_SIM_V0_1_2.m`)
| Parametro | Valor | Origem |
|---|---|---|
| `T_SORT_ID` | 2 s | ladder exato (T1..T6 SE S5T#2S); Historian: `Conveyor -> P1/P2` 1.92 s (n=14) |
| `T_SORT_T7` | 4 s | ladder exato (OB1 T7 SE S5T#4S); Historian: `Part_Sorted` 3.98 s (n=19) |
| `t_s_spart_off` | 0.135 s | Historian: `F_62_Conveyor -> O_60_SPart` cai (mediana, n=19) |
| `t_s_photo` / `t_s_ind` | 0.14 / 0.26 s | Historian: `F_62_Conveyor -> O_60_SPhoto` (n=12) / `-> O_60_SInd` (n=5) |
| `t_s_ind_off` / `t_s_photo_off` | 0.12 / 0.19 s | Historian: `F_62_Identify -> SInd` / `SPhoto` caem |
| `t_s_pass1` / `2` / `3` | 1.98 / 2.57 / 2.87 s | Historian: `F_62_Identify -> O_60_Part_Pass` por saida (n=7/7/5) |
| `t_s_pp` | 0.15 s | Historian: pulso do `Part_Pass` (n=19) |
| `t_sl1_fwd` / `t_sl1_bck` | 0.42 / 0.25 s | Historian: `F_62_P1 -> O_60_SL1_Fwd` / `-> SL1_Bck` (n=7) |
| `t_sl2_fwd` / `t_sl2_bck` | 0.14 / 0.32 s | Historian: `F_62_P2 -> O_60_SL2_Fwd` / `-> SL2_Bck` (n=7) |
| `SORT_MODE`, `PART_COLORS` | 1, [1 2 3] | cenario (setup do supervisorio e cores das pecas) |

Nenhum tempo da Sorting ficou estimado (FB1 nao tem temporizador). Config 01 do Historian = RBS
(vermelha -> P1, preta -> P2, metalica direto). `t_sort_clear` saiu (a peca agora sai pela planta).

### Verificacao (modelo temporario em `%TEMP%`, so o Chart_SIM, 90 s, FixedStep 0.01)
| Modo | Peca 1 vermelha | Peca 2 preta | Peca 3 metalica | `nDone` |
|---|---|---|---|---|
| 1 RBS | alavanca 1 | alavanca 2 | direto | 3 (t = 20.75, 41.80, 62.70) |
| 6 SBR | direto | alavanca 2 | alavanca 1 | 3 (t = 21.20, 41.80, 62.25) |

Bits no fim da janela: vermelha 11, preta 10, metalica 01 (batem com a tabela).
Linha do tempo da 1a peca (RBS, vermelha), em s:
`SPart 14.70 | PD_Sort + N1 (esteira, ID zerado) 16.20 | N2 16.25, SPart cai e SPhoto liga 16.35, ID 11 em 16.40 |
N3 / P1 18.20 | SL1_Fwd 18.65 | pino (Identify) 18.70 | SPhoto cai 18.90 | Part_Pass 20.75 | N4 20.80 (P1 cai) |
N5 20.85 (esteira e pino desligam) | Part_Sorted 20.95 -> 24.95 | SL1_Bck 21.05`.
Esteira ligada 4.65 s por peca (Historian 4.62 s); `SPart -> Part_Pass` 6.05 s; ciclo ~21 s por peca
(limitado pelo Hd1 e pelo carro, nao pela Sorting).
`Ctrl+D` na v0.1.2: para no `BUS_SIM_IN_TEST` (sem entrada, falta `B_SimActuators_70`) -- nao mais no SORT.

### Armadilha encontrada
Ler um campo de um bus de **saida** dentro de acao de estado (`during: if SimActuators_60.SA_60_Conveyor ...`)
faz o Stateflow reclamar que o bus "nao tem atribuicao completa". Em transicao pode. Solucao: copia local
(`ConvOn60`) escrita no `FB3_Map`.

### Pendente
- Testar com a planta (Connect_OPCUA_Write) em cada modo.
- `FB1` N3 (limpeza de peca na partida) so roda se houver peca no inicio; nao foi exercitado na verificacao.
- Proximas estacoes: TEST, DIST, HD2, PROC, NODE, MASTER restante.

Modelo: `FullFMS_SIM_V0_1_2_R2025b.slx` (teste) / `_R2026a.slx` (fonte). `Connect_OPCUA_Write.m` aponta para a R2025b.

## FullFMS_SIM v0.1.2 --> v0.1.3  (Testing [70])

Testing no `Chart_SIM`, no mesmo formato da Sorting: controle = ladder rede a rede (`OB1`, `FB1`, `FB3`,
`FB4` Identified, `FB5` Requested, lidos renderizados, polaridade NA/NF conferida) + planta com tempos do
Historian + parada 24 do carro. Feito a partir da v0.1.2 (save com novo nome; a v0.1.2 nao mudou).
O construtor desta versao ficou fora da pasta (em `%TEMP%`); o `build_chart_sim_V0_1_2.m` foi mantido.

### Saidas e ligacoes
| Porta | Saida | Destino |
|---|---|---|
| 1-10 | (iguais a v0.1.2) | `BUS_SIM_IN_MASTER`, `_HD1`, `_SORT` |
| 11-14 | `SimActuators_70`, `SimASi_70`, `SimControl_70`, `SimSensors_70` | `BUS_SIM_IN_TEST` 1-4 (ordem do `B_SIM_TEST`) |

- `PreLoadFcn`: `load("BUS_CONFIG_SIM.mat"); run("Param_SIM_V0_1_3.m")`.
- Estados de topo novos: `TEST_Ctrl` (6), `TEST_Plant` (7), `Conveyor24` (8), `DIST_Feed_PROVISORIO` (9).
- `Conveyor29`, Hd1 e Sorting nao mudaram. O carro que sai da parada 24 com a peca da Testing **ainda nao
  segue** pelas paradas 25-28 ate o Hd1: a Testing e contada a parte (`nTest` = carros que sairam com peca;
  `nTestIn` = pecas entregues ao elevador; `nReject` = pecas rejeitadas embaixo).

### Controle (`TEST_Ctrl`, 5 paralelos) x ladder
| Estado / transicao | Ladder | O que faz |
|---|---|---|
| entry do `TEST_Ctrl` | supervisorio + FB2 N16/N17 | `C_75_Identified = (TEST_MODE == 1)`, `C_75_Requested = (TEST_MODE == 2)`, `*80` iguais; zera `SC_*`, `SA_*`, `SR_*` |
| `FB1_N2_N3_Check` | FB1 N2/N3 | `C_72_Profibus`; elevador desce se nao estiver embaixo |
| `FB1_N3_PistonPulse` | FB1 N3 | peca no elevador embaixo: pistao por `T1` SE 4 s |
| `FB1_N1_N4_InitOk` | FB1 N1/N4 | `~SPart & Elev_Low & Pist_Back` (Init_Parcial) `& C_72_Profibus & C_85_Initialization` -> `FB1_Init` = `C_75_Initialization`; `Reset` volta (N5..N7) |
| `OB1_N4_Off` / `OB1_N5_Off` | OB1 N4/N5 | FB4 so com `FB1_Init & C_75_Identified`; FB5 so com `FB1_Init & C_75_Requested` |
| `N1_StartID` / `N1_StartReq` | FB4/FB5 N1 | borda POS do `SPart`: S `Iden_Del`/`Req_Del`; R `ID_Delivery1/2`, `Part_Del`, `RQ_Part_Del` (FB5 tambem `RQ_Wrong`, `Part_Different`) |
| `N2_N3_Raise` | N2 + N3 | `SPart & Elev_Low & SInductive` -> S `ID_Delivery2` (metalica); `Elev_Up = SPart & Pist_Back & O_80_Arm_Mag` |
| `N4_Identify` (FB4) | FB4 N4 | no alto: `~ID2` -> S `ID1`; `~ID2 & SPart_Height` -> S `ID2`; `T2` S_ODT 2 s -> R `Iden_Proc`, S `Eject_Proc` |
| `N4_ColorWindow` / `N4_ColorHold` (FB5) | FB5 N4 | mesma regra, mas so dentro de `T8` S_PEXT 0.5 s; `T2` S_ODT 2 s fecha |
| `N5_Compare` (FB5) | FB5 N5 | bits `ID` = bits `RQ` -> `Part_Ok` + `Eject_Ok`; qualquer bit diferente -> `Part_Different` + `Eject_Bad` |
| `N5_Eject*` (FB4) / `N6_Eject*` (FB5) | FB4 N5 / FB5 N6 | carro preso (`~A_74_Pist_Bck & A_74_Cart_Stat`) e vazio (`~A_74_Optic`): pistao + ar por `T3`/`T5` SP 2 s, cai com `A_74_Optic`; `Cart_Full = Cart_Stat & Optic` |
| `N6_ReturnElev` -> `N6_PartDel` (FB4) | FB4 N6 | `Pist_Back & ~SPart & Optic` -> desce; `Elev_Low` -> S `C_75_Part_Del` |
| `N7_ReturnElev` -> `N7_RQPartDel` -> `N10_ResetReq` (FB5) | FB5 N7/N10 | idem -> S `C_75_RQ_Part_Del`; R `Req_Del` |
| `N8_DownBad` -> `N8_EjectBad` -> `N8_WaitBack` (FB5) | FB5 N8 | peca errada: desce com a peca; embaixo pistao `T6` SP 2 s (rejeicao) |
| `N9_RQWrong` (FB5) | FB5 N9 | `Part_Different & ~Eject_Bad` -> S `C_75_RQ_Wrong` |
| `OB1_N6_T7_CRouteOut` | OB1 N6 | `Part_Del` ou `RQ_Part_Del` -> `T7` S_PEXT 2 s -> `A_74_CRoute_Out` |
| `FB3_Map` | FB3 + OB1 N7..N9 | `Elev_Up = FB4 | FB5`; `Elev_Down = FB1 | FB4 | FB5 Down1 | FB5 Down2`; `Eject = FB1 | FB4 | FB5 FWD1 | FWD2`; `Air_On = FB4 | FB5`; `A_74_No_Cart = ~Cart_Stat`; `A_74_Cart_Full = FB4_Cart_Full & Identified | FB5_Cart_Full & Requested | Cart_Stat & Optic`; `CRoute_In80 = CRoute_In`; Leds |

Bits (mesma tabela da Sorting): vermelha 11, preta 10, metalica 01 (metalica pelo indutivo embaixo,
vermelha pelo `SPart_Height` no alto).

Observacoes do ladder (mantidas):
- FB5 N4 usa o `T2` "FB4_Iden_T" -- o mesmo temporizador do FB4 (os dois nunca rodam juntos).
- FB4 nunca zera `Iden_Del` (so o FB1); FB5 N10 so zera `Req_Del` com `~Part_Different`, e o `Part_Different`
  so cai no N1 da peca seguinte -- depois de uma peca errada o `Req_Del` fica ligado ate a proxima peca.
- FB4/FB5 N3 e N6..N8 leem `O_80_Arm_Mag` (sensor da Distribution). No SIM vem do `DIST_Feed_PROVISORIO`.
- `SR_74_Request` nao aparece no ladder da Testing: fica em 0.
- Master FB11 N6/N7 (destino Testing): `T1` SE 3 s na chegada (`Cart_Stat`) e `C_24_CartDel = T1`, ou seja,
  o `CartDel` e um pulso de 3 s que **comeca** na chegada (Historian: 2.96 s). O `Conveyor29` da v0.6.0 usa o
  T6 como atraso antes do `CartDel` -- conferir na rede N41/N42 do FB11 quando a esteira for detalhada.

### Planta (`TEST_Plant`, 4 paralelos) e parada 24
- `Elevator`: `Elev_Low -> Elev_GoingUp -> Elev_High -> Elev_GoingDown`, com os sensores intermediarios da
  subida/descida (pulsos do `SInductive` e do `SStation` medidos), `Elev_Low` cai 0.85 s depois de subir,
  `SPart_Height` liga 0.31 s antes do `Elev_High` (vermelha/metalica). Metalica: `SInductive` ligado embaixo.
- `Piston`: `Pist_Back -> Pist_Fwd -> Pist_Return`; a peca sai do elevador 0.17 s depois do comando; no alto
  vai para o carro (`SlideToCart`, `O_24_Optic` 1.21 s depois do comando), embaixo e rejeitada (`nReject`).
- `Sensors_Out` copia os locais para o `SimSensors_70`. Painel: `Key_Pos = 1`, demais 0.
- `Conveyor24`: `C24_Request` (`C_24_Request` 2 s) -> `C24_Moving` -> `C24_Count` -> `C24_N6_AtStop` (`Cart_Stat`,
  pino segura o carro, `C_24_CartDel`, `SR_73_TestCartID`, pedido `RQ_DELIVERY` do carro) -> `C24_CRouteIn`
  (`A_74_CRoute_In` 1.8 s) -> `C24_Docked` -> `C24_N7_CartDelOff` (fim do pulso de 3 s) -> `[CRoute_Out]` ->
  `C24_Release` -> `C24_PinBack` -> `C24_Leaving` -> `C24_Gone` (`nTest++` se o carro saiu com peca).
- **`DIST_Feed_PROVISORIO`** (sai quando a Distribution [80] entrar): espera `CRoute_In80` (ou `RQ_Wrong`),
  tira o braco do magazine (`O_80_Arm_Mag = 0`), 10.15 s depois poe a proxima peca de `PART_COLORS` no elevador
  (`SPart`, com o pulso do `SStation`) e devolve o braco 1.87 s depois. `C_85_Initialization` = `DIST_INIT_PROV`
  (parametro provisorio).

### Tempos (`Param_SIM_V0_1_3.m`)
| Parametro | Valor | Origem |
|---|---|---|
| `T_TEST_T1` | 4 s | ladder exato (FB1 N3 T1 SE S5T#4S) |
| `T_TEST_T2` | 2 s | ladder exato (FB4/FB5 N4 T2 S_ODT); Historian `Elev_High -> Eject` 1.99 s (n=19) |
| `T_TEST_T8` | 0.5 s | ladder exato (FB5 N4 T8 S_PEXT S5T#500MS) |
| `T_TEST_T3` / `T5` / `T6` | 2 s | ladder exato (SP S5T#2S); Historian: ejecao no alto 1.28 s (cai com o `Optic`), embaixo 1.9 s |
| `T_TEST_T7` | 2 s | ladder exato (OB1 N6 S_PEXT); Historian `A_74_CRoute_Out` 1.91 s (n=19) |
| `T_CONV24_T1` | 3 s | ladder exato (Master FB11 N6 T1 SE S5T#3S); Historian `C_24_CartDel` 2.96 s |
| `t_t_up` / `t_t_up_lowoff` | 3.28 / 0.85 s | Historian `F_72_Elev_Up -> Elev_High` / `-> Elev_Low` cai (n=22) |
| `t_t_up_ind` / `t_t_up_sst` | 0.90 / 1.33 s | Historian: pulsos `SInductive` (n=14) e `SStation` (n=22) na subida |
| `t_t_metal_off` / `t_t_height_pre` | 1.08 / 0.31 s | Historian (n=8 / n=15) |
| `t_t_down` / `t_t_down_highoff` | 2.82 / 0.07 s | Historian `F_72_Elev_Down -> Elev_Low` (mediana, n=19) / `-> Elev_High` cai |
| `t_t_down_sst` / `t_t_down_ind` | 1.73 / 2.39 s | Historian: pulsos na descida (n=22) |
| `t_t_ej_spart` / `t_t_pist_fwd` / `t_t_pist_back` | 0.17 / 0.14 / 0.29 s | Historian (n=19) |
| `t_t_ej_cart` | 1.21 s | Historian `F_72_Eject_Part -> O_24_Optic` (n=19) |
| `t_24_arrive` / `t_24_count` | 10.51 / 1.04 s | Historian `C_24_Request -> O_24_Cart_Stat` (n=19) / `O_24_Count -> Cart_Stat` (n=16) |
| `t_24_croute_in0` / `t_24_croute_in` | 0.13 / 1.80 s | Historian (n=19 / n=38) |
| `t_24_pist_bck` / `t_24_optic_off` / `t_24_leave` | 0.43 / 1.38 / 2.69 s | Historian, a partir do `A_74_CRoute_Out` (n=19) |
| `t_24_req` | 2.0 s | Historian 01 (n=1) |
| `t_dist_feed` / `t_dist_sst` / `t_dist_sst_dur` / `t_dist_arm` | 10.15 / 0.19 / 1.09 / 1.87 s | Historian (provisorio ate a Distribution entrar) |
| `TEST_MODE`, `RQ_DELIVERY`, `DIST_INIT_PROV` | 1, [1 1; 1 0; 0 1], 1 | cenario / provisorio |

### Verificacao (modelo temporario em `%TEMP%`, so o Chart_SIM, FixedStep 0.01)
| Cenario | Resultado |
|---|---|
| A: Identified, pecas [vermelha preta metalica], 3 carros, 110 s | bits 11, 10, 01; as 3 pecas no carro; `nTest` = 3 (t = 35.80, 71.65, 107.50) |
| B: Requested, carro pede vermelha [1 1], pecas [preta vermelha], 60 s | preta: bits 10 != 11 -> desce, rejeitada embaixo (`nReject` = 1), `RQ_Wrong` em 33.75; nova peca 10.25 s depois; vermelha: 11 = 11 -> carro, `RQ_Part_Del` em 56.05; `nTest` = 1 |

Linha do tempo da 1a peca (Identified, vermelha), em s (Historian entre parenteses):
`carro pedido 0.05 | Cart_Stat + CartDel 10.60 (10.51) | CRoute_In 10.75 | SPart 21.05 | Elev_Up 23.00 (+1.83) |
Elev_Low cai 23.85 | SPart_Height 26.00 | Elev_High 26.35 (+3.28) | ID 11 em 26.40 | Eject + Air 28.45 (+1.99) |
SPart cai 28.65 | O_24_Optic 29.70 (+1.21) | Eject cai 29.75 (1.28) | Pist_Back 30.05 | Elev_Down 30.10 | Elev_Low 33.00 (+2.82) |
Part_Del + CRoute_Out 33.05 | CRoute_Out cai 35.05 | carro sai 35.80`.
Ciclo da Testing: ~35.8 s por carro (Historian 01: `C_24_Request` -> carro sai ~35.5 s).
Requested, peca errada: `Elev_High -> Elev_Down` 2.10 s (Historian 2.00), descida 2.90 s (2.93), pistao 2.0 s (1.9),
`RQ_Wrong -> nova SPart` 10.25 s (10.14).
`Ctrl+D` na v0.1.3: para no `BUS_SIM_IN_PROC` (sem entrada, falta `B_SimActuators_100`) -- nao mais no TEST.

### Pendente
- `DIST_Feed_PROVISORIO`, `O_80_Arm_Mag` e `DIST_INIT_PROV` saem quando a Distribution [80] entrar.
- Ligar o carro da parada 24 ao trilho (paradas 25-28) ate o Hd1 (hoje o `Conveyor29` cria a peca sozinho).
- Conferir o `T6` do `Conveyor29` contra o padrao N6/N7 do FB11 (pulso de `CartDel` a partir da chegada).
- Testar com a planta (Connect_OPCUA_Write) nos dois modos.

Modelo: `FullFMS_SIM_V0_1_3_R2025b.slx` (teste) / `_R2026a.slx` (fonte). `Connect_OPCUA_Write.m` aponta para a R2025b.

## FullFMS_SIM v0.1.3 --> v0.1.4  (Distribution [80])

Distribution no `Chart_SIM`, no mesmo formato da Testing e da Sorting: controle = ladder rede a rede (`OB1`,
`FB1`, `FB3`, `FB4` Single, `FB5` Continuous, `FB6` Counted, lidos renderizados, polaridade NA/NF conferida) +
planta (braco, pistao do magazine, ventosa) com tempos do Historian. **Sai o `DIST_Feed_PROVISORIO` da v0.1.3**:
a peca que chega ao elevador da Testing agora vem do braco da Distribution, o `O_80_Arm_Mag` vem da planta e o
`C_85_Initialization` vem do FB1 da Distribution (o `DIST_INIT_PROV` saiu). A ligacao Distribution -> Testing segue o
ladder: a Testing pede peca pelo `A_74_CRoute_In80` (ou `C_75_RQ_Wrong`) e a Distribution so entrega com o elevador
embaixo e vazio (`O_70_Elev_Low & ~O_70_SPart`). Feito a partir da v0.1.3 (save com novo nome; a v0.1.3 nao mudou).
O construtor desta versao ficou em `%TEMP%`, fora da pasta.

### Saidas e ligacoes
| Porta | Saida | Destino |
|---|---|---|
| 1-14 | (iguais a v0.1.3) | `BUS_SIM_IN_MASTER`, `_HD1`, `_SORT`, `_TEST` |
| 15-17 | `SimActuators_80`, `SimControl_80`, `SimSensors_80` | `BUS_SIM_IN_DIST` 1-3 (ordem do `B_SIM_DIST`) |

- `PreLoadFcn`: `load("BUS_CONFIG_SIM.mat"); run("Param_SIM_V0_1_4.m")`.
- Estados de topo novos: `DIST_Ctrl` (10), `DIST_Plant` (11). Saiu o `DIST_Feed_PROVISORIO`.

### Controle (`DIST_Ctrl`, 7 paralelos) x ladder
| Estado / transicao | Ladder | O que faz |
|---|---|---|
| entry do `DIST_Ctrl` | supervisorio | `C_85_Single/Continuous/Counted = (DIST_MODE == 1/2/3)`, `C_83_RQ_Parts = RQ_PARTS`; zera `SC_*` e `SA_*` |
| `FB1_N2_Check` | FB1 N2 | `C_82_Profibus`; magazine vazio -> `FB1_Mag_Empty`, cheio -> `FB1_Mag_Full` (contagem conhecida) |
| `FB1_N3_N4_EmptyMag` | FB1 N3/N4 | contagem desconhecida (nem cheio nem vazio): o CLP esvazia o magazine na Testing. **So o estado; o ciclo de esvaziar nao foi modelado** (o cenario comeca com o magazine cheio) |
| `FB1_N5_ArmToMag` -> `FB1_N1_N5_InitOk` | FB1 N5/N1 | braco para o magazine (`A2M_2`); `Arm_Mag` -> `Init_Ok` = `C_85_Initialization` |
| `OB1_N4_C1` | OB1 N4..N6 | contador C1 (S_CUD): CU = borda do `Mag_Full`, CD = borda do `Pist_Fwd`, S = `Mag_Full` por `T1` 5 s (PV 9), R = `Pist_Back & Mag_Empty` por `T2` 1 s; `PartinMag = C1 > 0`; `C_85_Part_Mag`, `C_86_Mag_Parts` |
| `OB1_N7_Off` / `OB1_N8_Off` / `OB1_N9_Off` | OB1 N7..N9 | FB4/FB5/FB6 so com `Init_Ok` e o bit do modo |
| `FB4_N1_SingleOn` | FB4 N1 | (`Start` ou `C_85_Start` ou `C_75_RQ_Wrong` ou `A_74_CRoute_In80 & Key_Pos`) `& O_70_Elev_Low & ~O_70_SPart & PartinMag` -> S `Single_On` |
| `D4_A2D_1` | FB4 N2 | braco vazio ate a entrega (so com o elevador da Testing embaixo e vazio) |
| `D4_PistFwd` -> `D4_Transport` | FB4 N2 | `Arm_Del & Pist_Back` -> pistao empurra 1 peca; `Pist_Fwd` -> S `Transport`, R pistao |
| `D4_A2M_1` -> `D4_SuctOn` -> `D4_PartStuck` | FB4 N2 | braco ao magazine; `Arm_Mag` -> ventosa; `Part_Stuck` -> S `PartStuck` |
| `D4_A2D_2` -> `D4_SuctOff` | FB4 N2 | braco com a peca ate a entrega (elevador embaixo e vazio); `Arm_Del` -> R ventosa, `Suction_Off` enquanto `Part_Stuck` |
| `D4_PartDel` -> `D4_A2M_2` -> `D4_Reset` | FB4 N2 | `~Part_Stuck` -> S `PartDel`; braco volta ao magazine; `Arm_Mag` -> R `Single_On`, `PartDel` |
| `FB5_N1_AutoOn` ... `D5_PartDel` | FB5 N1/N2 | mesma sequencia do braco; depois da entrega volta direto ao pistao (o braco fica na entrega) |
| `D5_N3_T3` -> `D5_N3_A2M_2` -> `D5_N4_Reset` | FB5 N3/N4 | `Arm_Del & Pist_Back & Magazine_Empty` -> `T3` S_ODT 1 s -> braco ao magazine -> R `Automatic_On` |
| `FB6_N1_N2_LoadC2` | FB6 N1/N2 | partida (sem o ramo `RQ_Wrong`) `& Arm_Mag & Elev_Low & ~SPart & PartinMag & Exis_Parts >= RQ_Parts` -> carrega o C2 (S_CD) com `RQ_Parts + 1`; `Counted_On = C2 > 0`; `C_87_RQ_MParts = CV` |
| `D6_*` (N3) | FB6 N3 | mesma sequencia do FB4 (`A2D_1` ... `A2M_2`) |
| `D6_N4_Wait` -> `D6_N4_DecCount` -> `D6_N5_NewCycle` | FB6 N4/N5 | `PartDel & C_75_Identified80` ou `C_75_RQ_Part_Del & C_75_Requested80` -> `Dec_Count` + `T3` SE 1 s -> R `PartDel`; `RQ_Wrong & Requested80` -> R `PartDel` sem decrementar; repete enquanto `Counted_On` |
| `OB1_N10_Wait` -> `OB1_N11_PartDel` | OB1 N10/N11 | `FB4_PartDel` ou borda NEG do `FB5_PartMove` ou `FB6_PartDel` -> `T4` SE 4 s -> `C_85_Part_Del` |
| `FB3_Map` | FB3 | `Pist_Adv`, `Suction_On`, `Suction_Off`, `Arm_2_Del` (`A2D_1`/`A2D_2` dos 3 FBs), `Arm_2_Mag` (FB1 + `A2M_1`/`A2M_2`), `Led_Start = Init_Ok`, `Led_Extra1 = C_85_Part_Del` |

Observacoes do ladder (mantidas):
- A Distribution le sensores da Testing (`O_70_Elev_Low`, `O_70_SPart`) e a Testing le o `O_80_Arm_Mag`: os dois CLPs
  trocam sinais pelo OPC UA. No SIM sao os mesmos locais (`ElevLow70`, `PartIn70`, `ArmMag80`).
- **FB6: o C2 e carregado com `C_83_RQ_Parts + 1`** e o `Counted_On` e o `Q` do contador (CV > 0). Lido literalmente,
  o Counted entrega `RQ_Parts + 1` pecas -- na verificacao, `RQ_PARTS = 2` entregou 3. Pode ser compensacao de algum
  efeito do CLP que o SIM nao tem (ex.: decremento extra na carga) -- conferir na planta.
- FB5 e FB6 usam o mesmo `T3` ("FB6_Timer"); nunca rodam juntos.
- FB5: no SIM o pistao so repete com `~Magazine_Empty` (a pagina do FB5 N2 com o ramo do pistao nao foi relida nesta
  versao; a v0.4.18 confirmou que a sequencia do braco e a mesma do FB4).

### Planta (`DIST_Plant`, 4 paralelos)
- `Arm`: `Arm_AtMag -> Arm_ToDel -> Arm_AtDel -> Arm_ToMag` (inverte no meio se o comando mudar). Ida mais lenta vazio
  (3.36 s) que carregado (3.27 s); `O_80_Arm_Mag` cai 1.85 s / 1.29 s depois do comando. O braco sobre a Testing liga o
  `O_70_SStation` (cai 1.07 s depois do `Arm_2_Mag`).
- `MagPiston`: `Pist_Adv` -> `Pist_Back` cai 0.33 s, `Pist_Fwd` 0.905 s (a peca de baixo sai do magazine), volta 0.11 s.
- `Suction`: ventosa no magazine com peca -> `Part_Stuck` 0.11 s; ventosa desliga na entrega -> 0.22 s depois a peca cai no
  elevador da Testing (`O_70_SPart`, cor = proxima de `PART_COLORS`, metalica liga o indutivo).
- `Sensors_Out80`: `Mag_Full = magCount >= 9`, `Mag_Empty = magCount == 0`; painel `Key_Pos = 1`.

### Tempos (`Param_SIM_V0_1_4.m`)
| Parametro | Valor | Origem |
|---|---|---|
| `T_DIST_T1` / `T_DIST_T2` | 5 / 1 s | ladder exato (OB1 N4 T1/T2 S_ODT) |
| `T_DIST_T3` | 1 s | ladder exato (FB5 N3 / FB6 N4) |
| `T_DIST_T4` | 4 s | ladder exato (OB1 N10 SE); Historian `C_85_Part_Del` 3.79 s (n=22) |
| `t_d_a2d_empty` / `t_d_a2d_load` | 3.36 / 3.27 s | Historian `F_82_Arm_2_Del -> O_80_Arm_Del` (n=22 / n=22) |
| `t_d_magoff_empty` / `t_d_magoff_load` | 1.85 / 1.29 s | Historian `-> O_80_Arm_Mag` cai |
| `t_d_a2m` / `t_d_deloff` / `t_d_sst_off` | 2.01 / 1.28 / 1.07 s | Historian a partir do `F_82_Arm_2_Mag` (n=44) |
| `t_d_pist_fwd` / `t_d_pist_bckoff` / `t_d_pist_back` | 0.905 / 0.33 / 0.11 s | Historian (n=9 / 22 / 22) |
| `t_d_suct` / `t_d_release` | 0.11 / 0.22 s | Historian (n=21 / 22) |
| `DIST_MODE`, `RQ_PARTS`, `MAG_PARTS0`, `MAG_CAP` | 1, 2, 9, 9 | cenario (magazine cheio no inicio) |

### Verificacao (modelo temporario em `%TEMP%`, so o Chart_SIM, FixedStep 0.01)
| Cenario | Resultado |
|---|---|
| A: Single + Identified, pecas [vermelha preta metalica], 3 carros | 3 entregas (`C_85_Part_Del` em 21.65, 58.20, 94.75), Testing 11/10/01, 3 carros saem (36.60, 73.15, 109.70); magazine 9 -> 6 |
| B: Single + Requested, carro pede vermelha, pecas [preta vermelha] | preta rejeitada; `C_75_RQ_Wrong` em 34.55 dispara o FB4 de novo (ramo `RQ_Wrong` do FB4 N1); vermelha no elevador 10.65 s depois (Historian 10.14), vai ao carro; 1 carro |
| C: Continuous + Identified, 3 carros | a proxima peca ja fica pronta no braco: carros saem em 37.65, 55.70, 73.75 (~18 s por carro contra ~36.5 s no Single); a 4a peca fica no elevador no fim |
| D: Counted (`RQ_PARTS = 2`) + Identified | C2 carregado com 3 em 10.90; 3 entregas e o `Counted_On` cai (ver observacao do FB6) |

Linha do tempo da 1a peca (cenario A), em s (Historian 01 entre parenteses):
`CRoute_In80 / Single_On / Arm_2_Del 10.95 (+0.04) | Arm_Del 14.40 (+3.36) | Pist_Adv 14.45 | Pist_Fwd -> Transport, Arm_2_Mag 15.50 |
Arm_Mag 17.60 (+2.01) | Suction_On 17.65 | Part_Stuck 17.80 (+0.11) | Arm_2_Del 17.90 | Arm_Del 21.25 (+3.27) | ventosa desliga 21.30 |
peca no elevador 21.55 (+0.22) | C_85_Part_Del 21.65 -> 25.65 | braco no magazine 23.75`.
`CRoute_In80 -> O_70_SPart`: 10.65 s no SIM x 10.15 s no Historian (diferenca dos passos de 0.05 s nas ~12 transicoes).
`Ctrl+D` na v0.1.4: continua parando no `BUS_SIM_IN_PROC` (falta `B_SimActuators_100`). A Distribution so pode ser conferida
pelo Ctrl+D quando a Processing entrar; o chart com a Distribution compila e roda no modelo de verificacao.

### Pendente
- `FB1_N3_N4_EmptyMag`: procedimento de esvaziar o magazine com contagem desconhecida (so o estado existe).
- Conferir na planta o `RQ_Parts + 1` do Counted e o ramo do pistao no FB5 N2.
- Ligar o carro da parada 24 ao trilho ate o Hd1; conferir o `T6` do `Conveyor29`.

Modelo: `FullFMS_SIM_V0_1_4_R2025b.slx` (teste) / `_R2026a.slx` (fonte). `Connect_OPCUA_Write.m` aponta para a R2025b.

## FullFMS_SIM v0.1.4 --> v0.1.5  (Processing [100])

Processing no `Chart_SIM`: controle = ladder rede a rede (`OB1`, `FB1`, `FB3`, `FB4` Test, `FB5` Test+Drill, `FB6`
Rotation, lidos renderizados) + planta (mesa giratoria de 6 posicoes, furadeira, pino de teste) com tempos do Historian.
O Hd2 [90] ainda nao existe no SIM: a garra que poe e tira a peca da mesa e o **`HD2_Feed_PROVISORIO`** (sai na v0.1.6).
Feito a partir da v0.1.4 (save com novo nome; a v0.1.4 nao mudou). Construtor em `%TEMP%`.

### Saidas e ligacoes
| Porta | Saida | Destino |
|---|---|---|
| 18-20 | `SimActuators_100`, `SimControl_100`, `SimSensors_100` | `BUS_SIM_IN_PROC` 1-3 |

`PreLoadFcn`: `load("BUS_CONFIG_SIM.mat"); run("Param_SIM_V0_1_5.m")`. Estados de topo novos: `PROC_Ctrl` (12),
`PROC_Plant` (13), `HD2_Feed_PROVISORIO` (14).

### Controle (`PROC_Ctrl`, 6 paralelos) x ladder
| Estado | Ladder | O que faz |
|---|---|---|
| `FB1_N2_DrillUp` -> `FB1_N3_Empty1` -> `FB1_N4_Rotate3` -> `FB1_N5_Empty2` -> `FB1_N12_InitOk` | FB1 N2..N5, N12 | broca em cima; mesa parada sem peca nas posicoes inicial/teste/broca; gira 3 passos (C1 = 3, so com a garra do Hd2 em cima ou fora da entrega); confere a outra metade; `Init_Ok` = `C_105_Initialization` |
| `FB1_N6_N11_Clear` | FB1 N6..N11 | peca na mesa na partida: **so o estado** (o cenario comeca com a mesa vazia) |
| `OB1_N4_N8_Map` | OB1 N4, N8 | `C_105_Part_ready` = pronto do FB4/FB5/FB6; contador C11 das bordas do `RT_Sensor` com `RT_On` -> `C_106_RT_Counter` |
| `FB4_N1_StartTest` | FB4 N1 | `PInit_Pos & O_90_Claw_High & RT_Sensor & ~RT_On` -> S `StartTest`, R `C_105_Test_OK/Fail` |
| `FB4_N2_SpinToTest` | FB4 N2 | C4 = 4: gira ate 4 bordas do `RT_Sensor` |
| `FB4_N3_T4_TestDelay` -> `FB4_N4_TestPin` | FB4 N3/N4 | `~RT_On & PTest_Pos & RT_Sensor` -> T4 SP 2 s -> pino de teste |
| `FB4_N5_N6_Result` | FB4 N5/N6 | T5 S_ODT 1 s: `PTest_Ok` -> `TestOK` / senao `TestFail`; `C_105_Test_OK` / `C_105_Test_Fail` |
| `FB4_N7_SpinToCollect` -> `FB4_N8_PartReady` -> `FB4_N9_PickedUp` | FB4 N7..N9 | C5 = 2 passos ate a posicao inicial; `Part_ready`; garra do Hd2 na entrega, embaixo, com peca -> reset |
| `FB5_*` | FB5 N1..N16 | igual ao FB4 ate o teste; Ok: C7 = 1 passo, pino de fixacao + broca desce (N8), `SDrill_Low` -> T8 SP 2 s com a broca ligada (N9/N10), broca sobe (N11), `SDrill_High` -> solta e `DrillOk` (N12), C8 = 1 passo (N13); Fail: C9 = 2 passos (N14); `Part_ready` (N15), reset (N16) |
| `FB6_*` | FB6 N1..N5 | C10 = 6 passos (volta inteira), `RotationOK`, `Part_ready`, reset |
| `FB3_Map` | FB3 | `RT_On`, `Drill_Down`, `Drill_Up` (FB1 + FB5), `Drill_Pin`, `Drill_On`, `Test_Pin`, `Led_Start`, `Led_Extra1 = Part_ready` |

Observacoes do ladder:
- Geometria da mesa pelos contadores: teste a 4 passos da entrada, broca a 5, volta a entrada em 6.
- Pino de teste: no ladder e T4 SP 2 s, mas no Historian o pino cai junto com a mesa voltando a girar ~1 s depois
  (fim do T5). O SIM segue o Historian (pino 1 s). Conferir na rede do FB3 do `Test_Pin`.
- `C_103_RQ_Turns` vai para o bus, mas o FB6 usa `C#6` fixo e nao le esse valor.

### Planta e tempos (`Param_SIM_V0_1_5.m`)
| Parametro | Valor | Origem |
|---|---|---|
| `T_PROC_T4` / `T_PROC_T5` / `T_PROC_T8` | 2 / 1 / 2 s | ladder exato; Historian `Test_Pin -> Test_Ok` 0.99 s (n=17), broca ligada 1.99 s (n=2) |
| `t_rt_step` | 1.13 s | Historian: intervalo entre bordas do `RT_Sensor` (n=76) |
| `t_rt_hi` | 0.13 s | Historian 01 (o tempo alto do sensor varia 0.06..1.2 s): estimado |
| `t_ptest_ok` | 0.06 s | Historian `Test_Pin -> PTest_Ok` (n=17) |
| `t_drill_down` / `t_drill_up` | 0.21 / 0.29 s | Historian (n=2) |
| `t_h2_*` (garra provisoria) | 0.13 .. 1.14 s | Historian 01 (n=1); `t_h2_return` = 20 s estimado |
| `PROC_MODE`, `PROC_TEST_OK`, `RQ_TURNS` | 1, [1 1 1], 1 | cenario |

Sensores `PInit_Pos`/`PTest_Pos`/`PDrill_Pos`: no SIM so a peca do cenario; no Historian eles piscam durante o giro
(provavelmente outras pecas ou os rebaixos da mesa) -- simplificacao.

### Verificacao (modelo temporario, so o Chart_SIM)
| Cenario | Resultado |
|---|---|
| A: Test, 3 pecas [ok fail ok] | giro ate o teste 4.65 s (Historian 4.50), pino 1.05 s, giro de volta 2.35 s (2.31); `Test_Ok`/`Test_Fail`/`Test_Ok` certos; 3 pecas retiradas |
| B: Test+Drill, [ok fail] | Ok: broca desce 0.25 s, ligada 2.0 s, sobe 0.30 s, gira ate o fim; Fail: 2 passos sem furar |
| C: Rotation, 2 pecas | volta inteira em 6.95 s (Historian 6.78 s, n=2) |
`Ctrl+D` na v0.1.5: para no `BUS_SIM_IN_NODE` (falta `B_SimActuators_30`) -- nao mais no PROC.

### Pendente
- `HD2_Feed_PROVISORIO` sai quando o Hd2 [90] entrar (v0.1.6). `FB1_N6_N11_Clear` (peca na mesa na partida).

Modelo: `FullFMS_SIM_V0_1_5_R2025b.slx` (teste) / `_R2026a.slx` (fonte). `Connect_OPCUA_Write.m` aponta para a R2025b.

## FullFMS_SIM v0.1.5 --> v0.1.6  (Handling 2 [90])

Hd2 no `Chart_SIM`: controle = ladder rede a rede (`OB1`, `FB1` Initialization, `FB3` OPC-UA Actuators, `FB4` Cart_2_Del,
`FB5` Del_2_Cart) + planta (garra: vertical, horizontal carro <-> entrega, pinca) + **parada 25** (destino Processing do
Master FB11). Sai o `HD2_Feed_PROVISORIO` da v0.1.5. Feito a partir da v0.1.5 (save com novo nome; a v0.1.5 nao mudou).
Construtor em `%TEMP%`.

Cadeia agora: Distribution -> Testing -> carro na parada 24 -> `C_24_CRoute_Out` -> carro anda ate a parada 25 ->
Hd2 FB4 tira a peca do carro e poe na mesa da Processing -> Processing (Test / Test+Drill / Rotation) ->
`C_105_Part_ready` -> Hd2 FB5 devolve a peca ao carro -> `C_95_PD_Cart` -> T1 2 s `A_94_CRoute_Out` -> carro sai.

### Saidas e ligacoes
| Porta | Saida | Destino |
|---|---|---|
| 21-24 | `SimActuators_90`, `SimASi_90`, `SimControl_90`, `SimSensors_90` | `BUS_SIM_IN_HD2` 1-4 |

`PreLoadFcn`: `load("BUS_CONFIG_SIM.mat"); run("Param_SIM_V0_1_6.m")`. Estados de topo novos: `HD2_Ctrl` (14),
`HD2_Plant` (15), `Conveyor25` (16). Na `Testing`, o `C24_Release` agora conta o carro com peca (`nCart25`) para a parada 25.

### Controle (`HD2_Ctrl`, 6 paralelos) x ladder
| Estado | Ladder | O que faz |
|---|---|---|
| `FB1_N2_N3_Check` -> `FB1_N1_N2_InitOk` | FB1 N1..N3 | `Profibus`; garra em cima, sem peca, no carro -> `C_95_Initialization`; se nao estiver no carro, vai para o carro |
| `FB1_N4_N5_Deliver` | FB1 N4/N5 | peca na garra na partida: **so o estado** (o cenario comeca sem peca) |
| `OB1_Map90` | OB1 N4, N7, N9 | `OKMove` = carro na parada, garra vazia e (Cart2Del com a mesa livre, ou Del2Cart com o carro vazio); `PD_Proc` / `PD_Cart`; `No_Cart`, `CRoute_In`, `Cart_Full` |
| `OB1_N8_Wait` -> `OB1_N8_Pulse` -> `OB1_N8_Hold` | OB1 N8 T1 | `PD_Cart` -> T1 S_PULSE 2 s -> `A_94_CRoute_Out` |
| `FB4_N1_Begin` .. `FB4_N6_PartDelivered` | FB4 N1..N6 | (`OKMove & Cart2Del` ou ja em curso) `& CRoute_In & Key_Pos`: garra ao carro, desce, fecha, sobe, vai a entrega, desce, abre, sobe -> `PartDel` |
| `FB5_N1_Begin` .. `FB5_N6_PartDelivered` | FB5 N1..N6 | (`OKMove & Del2Cart` ou `Part_ready` com o carro vazio) `& (Part_ready ou Start)`: o caminho inverso, da mesa ao carro |
| `FB3_Map` | FB3 | `Claw_2_Cart`, `Claw_2_Del`, `Claw_Down`, `Close_Claw` (FB1 + FB4 + FB5, com `Key_Pos`), `Led_Start`, `Led_Extra1 = PD_Cart` |

### Planta e tempos (`Param_SIM_V0_1_6.m`)
| Parametro | Valor | Origem |
|---|---|---|
| `T_HD2_T1` | 2 s | ladder exato (Historian `A_94_CRoute_Out` 1.95 s, n=19) |
| `t_c2_down` / `t_c2_up` | 0.75 / 0.97 s | Historian `Claw_Down` -> `Claw_Low` / -> `Claw_High` (n=76) |
| `t_c2_2del` / `t_c2_2cart` | 3.65 / 2.59 s | Historian `Claw_2_Del` -> `Claw_Del` / `Claw_2_Cart` -> `Claw_Cart` (n=19) |
| `t_c2_res_*` | 1.78 / 1.67 / 0.07 s | pulso do `Claw_Reserve` no meio do curso (n=37) |
| `t_c2_open` | 0.225 s | abre a garra -> `Part_in_Claw` cai (n=38) |
| `T_CONV25_T1` | 3 s | FB11 destino Processing, mesmo padrao do destino Testing (Historian `C_25_CartDel` 2.90 s) |
| `t_25_arrive` | 10.27 s | Historian `C_25_Request` -> `O_25_Cart_Stat` (n=19) |
| `t_25_croute_in` | 1.87 s | duracao do `A_94_CRoute_In` (n=19) |
| `t_25_pist_bck` / `t_25_optic_off` / `t_25_leave` | 0.40 / 1.50 / 2.68 s | `CRoute_Out` -> pistao recua / optico cai / `Cart_Stat` cai (n=19) |
| `HD2_CART2DEL`, `HD2_DEL2CART` | 1, 1 | setup do supervisorio |

### Verificacao (modelo temporario, so o Chart_SIM)
| Cenario | Resultado |
|---|---|
| A: Distribution -> Testing -> 24 -> 25 -> Hd2 -> Processing Test -> Hd2 -> carro, 2 pecas | carro pedido na 25 em 33.85 s e parado em 44.15 s (10.3 s, Hist 10.27); `CRoute_In` 1.9 s; Hd2 FB4: garra desce 0.80 s, ida a entrega 3.75 s (3.65), peca na mesa em 51.5 s; teste; FB5 devolve, `PD_Cart` 67.55 s, `CRoute_Out` 2.0 s, carro sai 2.7 s depois; 2 pecas, 2 carros |
| B: idem Test+Drill, 1 peca | mesma sequencia, furacao no meio; carro sai em 72.95 s |
`Ctrl+D` na v0.1.6: para no `BUS_SIM_IN_NODE` (falta `B_SimActuators_30`), como na v0.1.5. Modelo final: 25 blocos, 32 linhas.

### Pendente
- `Conveyor25` e simplificado (como a 29 e a 24): sai na v0.1.8 com o FB11 do Master completo.
- `FB1_N4_N5_Deliver` (peca na garra na partida) so como estado. `C_95_Start` vem do cenario (falso).

Modelo: `FullFMS_SIM_V0_1_6_R2025b.slx` (teste) / `_R2026a.slx` (fonte). `Connect_OPCUA_Write.m` aponta para a R2025b.

## FullFMS_SIM v0.1.6 --> v0.1.7  (NODE: Robot [30] + Storage [40])

Robot [30] e Storage [40] no `Chart_SIM` + paradas 27 (Robot) e 28 (Storage). O Robot e remota da Master: o
controle dele e o `Master/FB3 - Robot Remote` (N1..N15). A Storage tem CLP proprio (`Storage/OB1`, `FB1`..`FB5`).
Feito a partir da v0.1.6 (save com novo nome; a v0.1.6 nao mudou). Construtor em `%TEMP%`.

Cadeia agora: ... Processing -> Hd2 devolve a peca -> carro sai da parada 25 -> parada 27 (Robot: `CRoute_In` ->
`Part_Del` -> `CRoute_Out`) -> parada 28 (Storage: Store 3 s / Retrieve 5 s -> `CRoute_Out`) -> carro sai.

### Saidas e ligacoes
| Porta | Saida | Destino |
|---|---|---|
| 25-29 | `SimActuators_30`, `SimASi_30`, `SimControl_30`, `SimSensors_30`, `SimRFID_RFID` | `BUS_SIM_IN_NODE` 1-5 |
| 30-33 | `SimActuators_40`, `SimASi_40`, `SimControl_40`, `SimSensors_40` | `BUS_SIM_IN_NODE` 6-9 |

`PreLoadFcn`: `load("BUS_CONFIG_SIM.mat"); run("Param_SIM_V0_1_7.m")`. Estados de topo novos: `ROB_Ctrl` (17),
`ROB_Plant` (18), `Conveyor27` (19), `STOR_Ctrl` (20), `STOR_Panel` (21), `Conveyor28` (22).
No `Conveyor25`, o `C25_Gone` agora manda o carro para a parada 27 (`nCart27`).

**`Ctrl+D` na v0.1.7: OK (46 s)** -- primeira versao do SIM que compila inteira (todos os `BUS_SIM_IN_*` ligados).

### Robot (`ROB_Ctrl`) x ladder `Master/FB3`
| Estado | Rede | O que faz |
|---|---|---|
| entry | N15 | `C_30_Robot1`/`C_30_Robot2` pelo `ROBOT_MODE` (setup) |
| `FB3_Map30` | N4..N11 | `A_34_No_Cart = ~Cart_Stat`; `A_34_Cart_Full = Cart_Stat & Optic`; `Led_Extra1 = No_Cart`, `Led_Extra2 = Cart_Full` |
| `N12_T7_CartDel` | N12 | `A_34_CRoute_In & (Robot1 ou Robot2)` -> `FB3_CartDel` (T7) |
| `N13_PartDel` | N13 | borda NEG do `FB3_CartDel` -> S `C_35_Part_Del` |
| `N14_T8_Reset` | N14 | `Part_Del` -> `A_34_CRoute_Out`; T8 S_ODT 2 s -> R `Part_Del` |

Observacao: no ladder o T7 e S_PEXT 5 s, mas no Historian o `Part_Del` vem 0.22 s depois do fim do `CRoute_In`
(2.08 s depois do inicio, n=19), nunca 5 s. O SIM segue o Historian: `CartDel` acaba com o `CRoute_In` (5 s fica como
limite). Mesmo caso do pino da Processing.

**`ROB_Plant` em repouso**: os cilindros, a garra e o magazine do robo (`SS_31_*`, `SS_32_*`) sao comandados pelo
programa do proprio robo -- nao estao no CLP (o FB3 so repassa) nem no Historian. Ficam no valor de repouso
(cilindros recuados, mola na posicao de pega, magazine com tampa). `SimRFID_RFID` = 0 (sem dado de RFID no Historian).

### Storage (`STOR_Ctrl`) x ladder
| Estado | Ladder | O que faz |
|---|---|---|
| `FB1_N1_Profibus` -> `FB1_N1_InitOk` | FB1 N1 | `C_42_Profibus` -> `Init_Ok` -> `C_45_Initialization` |
| `FB4_Store` | OB1 N4 + FB4 N1 | `Init & StorePart`; `CRoute_In & Key_Pos` -> T1 S_PEXT 3 s (`StoreOK`), R `ProcessOK` |
| `FB5_Retrieve` | OB1 N5 + FB5 N1 | igual com T2 5 s (`RetrieveOK`) |
| `OB1_N6_NEG_ProcOK` | OB1 N6 | borda NEG do `StoreOK`/`RetrieveOK` -> S `ProcessOK` |
| `OB1_N7_T3_CRouteOut` | OB1 N7 | `Key_Pos & ProcessOK` -> T3 S_PULSE 2 s -> `A_44_CRoute_Out` |
| `Map40` | OB1 N8/N9 + FB3 | `No_Cart`, `Cart_Full`, `CRoute_In`; LEDs Start / Extra1 / Extra2 |
A Storage nao tem mecanica (FB4/FB5 sao "Simulated Timer"): `STOR_Panel` so tem o painel (FB2).
`C_45_Start` (caminho sem `Key_Pos`) fica falso.

### Tempos (`Param_SIM_V0_1_7.m`)
| Parametro | Valor | Origem |
|---|---|---|
| `T_ROB_T7` / `T_ROB_T8` | 5 / 2 s | ladder; Historian `CRoute_Out` 1.96 s |
| `T_STOR_T1` / `T_STOR_T2` / `T_STOR_T3` | 3 / 5 / 2 s | ladder; Historian `CRoute_In -> CRoute_Out` 3.08 s (Store) / 5.18 s (Retrieve), `CRoute_Out` 2.00 s |
| `t_27_travel` | 24.66 s | Historian `A_94_CRoute_Out -> A_34_Cart_Stat` 27.34 s menos a saida da 25; **inclui a parada da Vision** |
| `t_27_*` (optic/croute/pist/leave) | 0.23 / 0.18 / 1.86 / 0.54 / 1.67 / 2.83 s | Historian A_34 (n=19) |
| `t_28_travel` | 7.08 s | Historian `A_34_Cart_Stat` cai -> `A_44_Cart_Stat` (n=24) |
| `t_28_*` | 0.26 / 0.18 / 1.86 / 0.42 / 1.19 / 2.56 s | Historian A_44 (n=19) |
| `ROBOT_MODE`, `STOR_MODE` | 1, 1 | setup (`Config Setups.xlsx`: Config 1 = Routine 1 / Store) |

### Verificacao (modelo temporario, so o Chart_SIM)
| Cenario | Resultado |
|---|---|
| A: Robot1 + Store, 2 pecas | parada 27: `CRoute_In` 1.9 s, `Part_Del`/`CRoute_Out` 2.0 s, carro sai 2.9 s depois; parada 28: `CRoute_In -> CRoute_Out` 3.0 s (Hist 3.08), `CRoute_Out` 2.0 s; 2 carros ate o fim |
| B: Robot2 + Retrieve, 1 peca | `CRoute_In -> CRoute_Out` 5.0 s (Hist 5.18) |

### Pendente
- `Conveyor27`/`Conveyor28` simplificados; a viagem 25 -> 27 inclui a Vision. Saem na v0.1.8 (FB11 + Vision).
- Programa do robo (cilindros/garra) e RFID: sem dado.

Modelo: `FullFMS_SIM_V0_1_7_R2025b.slx` (teste) / `_R2026a.slx` (fonte). `Connect_OPCUA_Write.m` aponta para a R2025b.

## FullFMS_SIM v0.1.7 --> v0.1.8  (MASTER [20]: esteira completa + Vision [26] + supervisorio)

As paradas que eram simplificadas (`Conveyor29`, `Conveyor24`, `Conveyor25`, `Conveyor27` e `Conveyor28`, cada uma
com contador proprio e viagem fixa) foram substituidas por uma esteira so, controlada pelo `Master/FB11` rede a rede.
O carro agora da a volta no laco `29 -> 24 -> 25 -> 26 -> 27 -> 28 -> 29`. Feito a partir da v0.1.7 (save com novo nome;
a v0.1.7 nao mudou). Construtor em `%TEMP%`.

Cadeia completa: o supervisorio pede o carro para a 24 -> Distribution / Testing poe a peca -> 25 (Hd2 + Processing)
-> 26 (Vision) -> 27 (Robot) -> 28 (Storage) -> 29 (Hd1 + Sorting) -> o supervisorio pede a 24 de novo, ate `N_PARTS`.

Estados de topo novos (com a mesma ordem de execucao das paradas que sairam): `CONV_Plant` (1), `FB11_Ctrl` (8),
`MES_Super` (16), `VISION_Stn` (19). Saidas e ligacoes nao mudaram (33 portas). **`Ctrl+D` na v0.1.8: OK (56 s)**; 25 blocos, 41 linhas (R2026a e R2025b). `PreLoadFcn`:
`load("BUS_CONFIG_SIM.mat"); run("Param_SIM_V0_1_8.m")`.

### `FB11_Ctrl` x ladder `Master/FB11` (6 destinos x N1..N7) + N43..N48 + FB2
| Estado | Rede | O que faz |
|---|---|---|
| `N1_Request` | N1/8/15/22/29/36 | `C_2N_Request` (visto pelo CLP) e **nenhum outro destino pedindo** -> S `FB11_<dest>` |
| `N2_PathFrom<origem>` | N2/9/16/23/30/37 | cascata do carro mais proximo a montante: o 1o testa so `Cart_Stat`, os seguintes acumulam os NF; o ultimo e o caso default -> S `FB11_<dest>_<origem>` + S `Cart_Selected` |
| `N3_Conveyor` | N3/... | `Controler_On` -> S `FB11_<dest>_Conv`; senao `FB11_Conv_Error` |
| `N4_PinsOff` | N4/... | `Cart_Next` da parada imediatamente a montante -> R todos os caminhos do destino (pinos voltam) |
| `N5_Count` | N5/... | contador S_CU: pulsos do `Count` -> `A_x3_CartID`; R na borda POS do `Pist_Bck` |
| `N6_T_SE_CartDel` -> `N7_CartDelOff` | N6/N7 | `Cart_Stat` do destino -> T SE (S_PEXT) 3 s -> `C_2N_CartDel`; R esteira, pedido e `Cart_Selected` |
| `Pins_FB2_Map` | N43..N48 + FB2 | pino da parada s = OU de todos os caminhos origem -> destino que passam por s (da origem ate antes do destino); `SA_2x_Cart_*` = pino; `F_22_Conveyor` = OU das esteiras; `C_2N_CRoute_Out` = `A_x4_CRoute_Out` (FB2 N14...) |

Prioridades do N2 (mais proximo a montante, igual a sombra v0.4.17): Testing 29>28>27>26>25, Processing 24>29>28>27>26,
Vision 25>24>29>28>27, Robot 26>25>24>29>28, Storage 27>26>25>24>29, Sorting 28>27>26>25>24.

### Planta (`CONV_Plant`)
- `Cart`: `Cart_AtStop` -> `Cart_Move` quando a esteira esta ligada e o pino da parada recuou (`Pist_Bck`); chega na
  proxima parada depois de `T_HOP_ARR(origem)`; se o pino dela estiver recuado, passa direto. Um carro (`CART_ID` = 2).
- `Stop_Sensors`: para cada parada, `Cart_Stat`, `Optic` (= carro com peca), `Cart_Next` e `Count` em funcao do tempo
  no trecho; mais `CartHasPart`/`CartHasPart25`/`PartOnCart` para as estacoes.
- `Pin24..Pin29`: pistao de parada (recua 0.10 s depois do comando, volta 0.12 s depois).
- A peca no carro e uma variavel so (`cartPart`): Testing poe, Hd2 tira/devolve, Hd1 tira.

### Supervisorio (`MES_Super`) e Vision (`VISION_Stn`) -- sem ladder
O supervisorio (Node-RED) nao tem PDF; o comportamento veio do Historian:
- `MES_Req<N>`: quando a estacao anterior termina (`A_x4_CRoute_Out`; na 26, a Vision), pede o proximo destino:
  `C_2N_Request` por 2 s, 0.08 s depois. O CLP enxerga o pedido 0.24 s depois (latencia OPC UA + ciclo).
  O primeiro pedido (`C_24_Request`) sai em 4 s; a 24 so e pedida enquanto `nTest < N_PARTS`.
- `MES_Arr<N>`: chegada (`C_2N_CartDel`) -> 0.17 s -> `C_2N_CRoute_In` por 1.86 s (FB2: `A_x4_CRoute_In = C_2N_CRoute_In`).
- `VISION_Stn`: carro parado na 26 -> 5.04 s -> pronto (Historian `O_26_Cart_Stat -> C_27_Request`, n=19).

### Tempos (`Param_SIM_V0_1_8.m`, Historian, mediana, n=19 por trecho)
| Trecho | Chegada | `Cart_Stat` cai | `Cart_Next` | Optic cai |
|---|---|---|---|---|
| 24 -> 25 | 10.02 s | 2.35 | 8.03 | 1.05 |
| 25 -> 26 | 10.41 | 2.38 | 8.60 | 1.20 |
| 26 -> 27 | 10.63 | 2.34 | 8.10 | 1.11 |
| 27 -> 28 | 8.72 | 2.22 | 6.34 | 0.98 |
| 28 -> 29 | 11.58 | 2.22 | 10.33 | 0.86 |
| 29 -> 24 | 10.25 | 2.24 | 8.58 | (vazio) |
Contados a partir do `Release_FB` da origem. `T_FB11_T` = 3 s (Historian `CartDel` 2.89..2.95 s).

### Verificacao (modelo temporario, so o Chart_SIM): 2 pecas, Test, Robot1, Store
| Medida | SIM | Historian 01 |
|---|---|---|
| trechos 29->24 / 24->25 / 25->26 / 26->27 / 27->28 / 28->29 | 10.30 / 10.10 / 10.50 / 10.70 / 8.80 / 11.65 s | 10.19 / 10.00 / 10.38 / 10.63 (mediana) / 8.76 / 11.56 s |
| Vision (`Cart_Stat` 26 -> `C_27_Request`) | 5.15 s | 5.04 s |
| `CRoute_Out` -> proximo `Request` | 0.10 s | 0.04..0.11 s |
| volta completa (1o pedido -> `CRoute_Out` da 29) | 133.8 s (4.1 -> 137.9) | 136.0 s |
As 2 pecas passam por todas as estacoes (`nTest`, `nProc25Done`, `nRobDone`, `nStorDone`, `nDone` = 2) e o carro para na 29.

### Pendente / simplificacoes
- Um carro so (o Historian so tem o carro 2). A cascata do N2 ja escolhe entre varios carros, mas a planta move um.
- Pedido da propria estacao (`A_x4_Request`, caminho alternativo do N1) fica falso.
- Supervisorio e Vision: comportamento do Historian, nao ha ladder para conferir.
- Os parametros das paradas simplificadas (`t_24_*`, `t_25_*`, `t_27_*`, `t_28_*`, `t_conv`, `t_leave`) ficaram no Param
  so para comparacao.

Modelo: `FullFMS_SIM_V0_1_8_R2025b.slx` (teste) / `_R2026a.slx` (fonte). `Connect_OPCUA_Write.m` aponta para a R2025b.

---

# NOTAS, PENDENCIAS E CONTEXTO

## Estado atual por estacao
| Estacao | Situacao | Blocos |
|---|---|---|
| Sorting [60] | implementada, verificada contra o ladder | BRS, BSR, RBS, RSB, SRB, SBR |
| Processing [100] | implementada, verificada contra o ladder | TestOnly, TestDrill, RotationOnly |
| Handling 1 [50] | implementada, verificada contra o ladder | Handling1_Cart2Del |
| Distribution [80] | implementada, verificada contra `FB4`/`FB5`/`FB6` (v0.4.18) | Single, Continuous, Counted |
| Testing [70] | implementada, verificada contra `FB4`/`FB5` | Identified_Delivery, Requested_Delivery |
| Conveyor [20] | implementada, verificada contra `Master/FB11` | CartToTesting, CartToProcessing..4 |
| Handling 2 [90] | reescrita na v0.4.20 por `FB4`/`FB5`; partida do P2P1 pela `OB1` N6 (v0.4.22) | PartToProcessing, ProcessingToPart |
| Storage [40] | implementada, verificada contra o ladder (estacao simulada) | Store, Retrieve |
| Robot [30] | implementada, verificada contra `Master/FB3` | Robot1, Robot2 |
| Vision | sem FB proprio; guiada por `Master/FB11` N20-22 e `FB2` N31/N32 (`C_26_CRoute_In/Out`) desde a v0.4.26 | Vision |
Os barramentos `_30` e `_40` passaram a ser usados a partir das v0.4.12 (Storage) e
v0.4.13 (Robot): `Sensors_30` 16 usos, `AS_i_30` 16, `Control_30` 12, `Actuators_30` 4,
`Control_40` 12, `AS_i_40` 8, `Sensors_40` 2. Apenas `Actuators_40` segue sem uso --
coerente com a Storage ser estacao simulada (so painel e LEDs, sem atuador de processo).
PDFs de ladder disponiveis para 8 pastas (Distribution, Hd1, Hd2, Master, Processing,
Sorting, Storage, Testing). O Robot [30] esta dentro da Master (`FB3`, remota) e o
Conveyor [20] em `Master/FB11` (48 redes, 6 destinos). **Nao ha PDF do Vision.**
**Todas as estacoes foram verificadas contra o ladder**, exceto o Vision, que nao tem PDF
e foi modelado como passagem simbolica de 5 s (v0.4.16).
Saida da Sorting: desde a v0.4.29 cada bloco volta ao `Start` no fim do ciclo (`StatusXXX_5`).
---

## O QUE FALTA

| # | Item | Por que importa |
|---|---|---|
| 1 | **Simulacao com o OPC UA conectado** | Validacao que falta inteira. O modelo compila, mas nunca rodou com dados da planta. Os dois piores erros ja encontrados (`J1888` mandando todo carro para `Retrieve`; Handling 2 com sentido invertido) **nao apareciam na compilacao**. E dessa simulacao que saem os tempos para o modelo matematico. |
| 2 | **Saida da Sorting** | Feita na v0.4.29: os 6 blocos voltam ao `Start` no fim do ciclo, nas duas versoes (R2025b e R2026a). Falta testar na planta. |
| 3 | `Master/FB11` redes 43-48 | Comandos aos **pinos de desvio** de cada estacao. Sem eles o percurso do carro nao fecha (item 2 do mapa de simplificacoes). Unico trecho de ladder relevante ainda nao lido. |
| 0 | **Testar a v0.4.31 na planta** (v0.4.30 parou no `ESTATE6` do `RBS`, corrigido na v0.4.31) (Sorting + saida para o `Start` no fim do ciclo; flags zeradas a cada carrinho -- rodar pelo menos 2 ciclos seguidos). Ate a v0.4.27 o ciclo passou por Handling 2, Vision e Robot | v0.4.21-0.4.23 pararam no Handling 2 por sinais curtos; a v0.4.24 aplica latch + captura em todos os passos do Hd2. **As outras estacoes ainda usam `else St = false`** -- se travarem do mesmo jeito, aplicar o mesmo padrao (decisao pendente: fazer em todas de uma vez ou estacao por estacao). Daqui em diante, o primeiro bloco onde parar e o proximo ponto de cruzamento com o ladder. |
| 5 | **MES (Master `FB12`)** | Adiado a pedido. `FB12` esta vazio no FMS V2 e `C_21_MES_On` nao esta no OPC UA (`B_Control_20`, CSV, `Tags_OPCUA.mat`). Antes de modelar: incluir a tag no `Connect_OPCUA.m` e baixar de novo. |
| 4 | `after(4,sec)` morto na Distribution | No `Continuous` e no `Counted` e uma terceira transicao saindo de `PartDel_CheckLoop`, com as ordens 1 e 2 ja cobrindo `LoopDistCont` verdadeiro e falso -- nunca dispara. Mas o estado `T1` desses blocos **so e alcancavel por ela**. Apagar deixaria `T1` orfao. Pendente de decisao. |

> Com o OPC UA resolvido no R2025b, o item 1 subiu de prioridade: valida tudo de uma vez e
> destrava o proximo passo do projeto (modelo matematico da planta).

**Nao sao pendencias (decisao acordada):** os `OB1` de todas as estacoes (inicializacao) e
os `FB2`/`FB3` de cada estacao (passagem OPC-UA 1:1, ja coberta pelos blocos de bus).

---
## BUG DO R2026a -- OPC UA (IMPORTANTE)
### Sintoma
Os Bus Selectors nao recebem os sinais dos blocos OPC UA Read. No dialogo do bus,
"Elements in the bus" fica **vazio** e os `Value_XXXX` aparecem em **vermelho**.
Em paralelo surge o aviso:
```
Warning: Multiple nodes found with identifier NNNN. Using the first available node in the list.
  In opcuasrc.opcuamasks.helper.getNodes
  In opcUARead/getOutputDataTypeImpl
```
E, em alguns blocos, o erro:
```
MATLAB System block '.../opcInternalBlock' error occurred when invoking
'getOutputDataTypeImpl' method of 'opcUARead'.  Index exceeds array bounds.
```
### Situacao: RESOLVIDO
Confirmado pelo usuario: e bug da versao do MATLAB. O modelo exportado roda no **R2025b**.
### Causa
**Bug da Industrial Communication Toolbox 26.1 (R2026a, 20-Nov-2025).** No R2025b o mesmo
modelo funciona. Nao e problema do modelo, do script, da rede nem dos servidores.
### Solucao
Usar o **R2025b**. Modelo exportado com:
```matlab
Simulink.exportToVersion('FullFMS_2026_02_25_V0_4_18', ...
    'FullFMS_2026_02_25_V0_4_18_R2025b.slx', 'R2025B_SLX')
```
Arquivo gerado: **`FullFMS_2026_02_25_V0_4_18_R2025b.slx`**. Conteudo verificado apos a
exportacao -- 29 blocos, 301 estados, 412 transicoes, 70 juncoes, 718 dados, 8 blocos
OPC UA Read com servidor e `NodeList` intactos (66/66/44/39/53/39/46/40 nos).
**"No replaced blocks found"** -- nada foi substituido ou removido.
> O arquivo exportado tem ~202 KB contra ~2,1 MB do original. E normal: a exportacao
> descarta caches e metadados de renderizacao do R2026a. O conteudo funcional esta integro.
> Ao abrir no R2025b, o `PreLoadFcn` faz `load("BUS_CONFIG.mat")` sem caminho -- o MATLAB
> precisa estar com a pasta `Digital Model - STF` como diretorio atual ou no path.
### O que foi DESCARTADO no diagnostico (nao repetir)
| Hipotese | Como foi descartada |
|---|---|
| Script de conexao com bug | Gera `NodeList` e `OutputSignals` **identicos** aos da v0.4.5, que funcionava |
| Tags faltando ou sobrando | 386 tags conferidas contra os 32 bus objects e contra os 9 CSVs: 0 divergencias |
| Tag buscada no CSV da estacao errada | 0 erradas nos 8 grupos |
| CSVs desatualizados | Os 9 baixados na mesma execucao, em 10 s (16:29:15 a 16:29:25) |
| IDs duplicados dentro de um servidor | 0 duplicados dentro de cada CSV |
| Namespace errado | Todos `ns=6`, confirmado nos CSVs e pelo usuario |
| Hostname de discovery | `UseDiscoveryHostname=true` nao resolveu |
| Certificado nao confiavel | Servidores usam `None`; sem certificado a validar |
| Politica de seguranca | `MessageSecurityMode=None` + `ChannelSecurityPolicy=None` nao resolveu |
| Rede inacessivel | `ping` responde em `.202`, `.206`, `.213` |
| `ServerList` diferente entre versoes | Identico (1 item) em ambas |
| Modelo corrompido | A v0.4.18 chegou a resolver MASTER e NODE (66 cada) |
### Erros de interpretacao cometidos no caminho
- **`outports=1` NAO significa bloco desconectado.** O OPC UA Read tem sempre **uma** porta,
  que carrega um bus. Interpretei isso como falha de conexao varias vezes, o que contaminou
  diagnosticos.
- **Chamadas `opcua()` diretas deixam sessoes penduradas** e podem impedir os blocos de
  conectar. Ao testar hipoteses, provavelmente esgotei sessoes em `.203`-`.208` -- os mesmos
  seis que depois falhavam, enquanto `.202` e `.213` (nao testados diretamente) funcionavam.
- **Fechar o modelo derruba as sessoes OPC UA.** Nao fechar durante diagnostico.
- O aviso "message security mode... None" indica conexao **bem-sucedida**, nao problema.
### Fragilidades do script de conexao (nao sao a causa, mas valem correcao)
- `IdentRows = string(0)` inicializa com a string `"0"` em vez de vazio; use `strings(0)`.
- Se o `mget` falhar, o `Variables_X.csv` **anterior permanece** e passa despercebido.
- Se o `movefile` falhar, o `Variables.csv` generico fica na pasta e a **proxima** estacao
  do laco o renomeia com o nome dela -- atribuindo dados de um servidor a outro.
- `close(s)` esta dentro do `try`: se o `mget` lancar excecao, a sessao SFTP nunca fecha.
## COBERTURA DE LEITURA DOS PDFs
Inventario honesto do que foi lido em detalhe (rasterizado, polaridade NA/NF conferida,
cruzado com os barramentos) e do que nao foi.
### Lido e verificado
| Arquivo | Cobertura |
|---|---|
| `Sorting/FB4`, `FB5`, `FB6` | completo |
| `Processing/FB4`, `FB5`, `FB6` | completo |
| `Hd1/FB4` | completo (9 redes) |
| `Hd2/FB4`, `FB5` | completo |
| `Distribution/FB4`, `FB5`, `FB6` | completo (v0.4.18: FB5 7 pgs, FB6 8 pgs, polaridade NA/NF conferida) |
| `Testing/FB4`, `FB5` | completo |
| `Storage/FB4`, `FB5`, `OB1` | completo |
| `Master/FB3` (Robot) | completo (15 redes) |
| `Master/FB11` | redes N1-N2 dos **6** destinos + padrao N3-N7 do Testing |
### NAO lido -- risco real
| Arquivo | Por que importa |
|---|---|
| `Master/FB11` redes 43-48 | Comandos aos **pinos de desvio** de cada estacao -- sem eles o percurso nao fecha (item 2 do mapa de simplificacoes) |
| `Master/FB11` redes N3-N7 dos outros 5 destinos | Assumido que seguem o padrao do Testing (o indice das redes sustenta, mas e inferencia) |
### NAO lido -- risco baixo
`FB1` de todas as estacoes (inicializacao -- decisao acordada de nao modelar);
`FB2`/`FB3` de cada estacao (passagem OPC-UA 1:1, coberta pelos blocos de bus);
`Master/FB2`, `FB4`-`FB10` (mapeamento OPC-UA, mesma natureza de passagem).
### Prioridade sugerida para a proxima sessao
1. ~~`Distribution/FB5` e `FB6`~~ -- **RESOLVIDO na v0.4.18** (malha do Counted estava invertida)
2. `Master/FB11` redes 43-48 -- fecha o item 2 do mapa de simplificacoes
3. Decisao sobre a **saida da Sorting** (pendencia estrutural unica)
4. **Simulacao com o OPC UA conectado** -- validacao que falta inteira
5. Decisao sobre o `after(4,sec)` morto de `Distribution_Continuous`/`_Counted` (v0.4.18, item 8)
## MAPA DAS SIMPLIFICACOES
O que **nao** e reproducao fiel do CLP -- atencao ao migrar para o modelo matematico:
| # | Onde | Simplificacao | Impacto no modelo matematico |
|---|---|---|---|
| 1 | ~~Conveyor, rede N2~~ | **RESOLVIDO na v0.4.17** -- desmembrado em 5 estados por conveyor, 6 cascatas confirmadas no PDF | - |
| 2 | Conveyor, redes 43-48 | Comandos aos pinos de cada estacao nao modelados | Os pinos definem o desvio do carro; sem eles o percurso nao fecha |
| 3 | Vision | Estacao inteira simbolica (5 s fixos) | Sem ladder; tempo real precisa de medicao |
| 4 | Storage | Fiel ao CLP, mas o CLP **ja e simulacao** (3 s e 5 s) | A planta fisica pode ter tempo diferente |
| 5 | Robot, T7 | No ladder conta da **chegada do carro**; no modelo, do estado `Recua` | Instante zero do cronometro difere |
| 6 | Robot, movimento | O CLP nao sequencia o robo (`FB3` e so I/O da remota) | A sequencia real esta no programa do robo, indisponivel |
| 7 | OB1 de todas as estacoes | Inicializacao nao modelada (decisao acordada) | Modelo precisara de condicoes iniciais explicitas |
| 8 | FB2/FB3 de cada estacao | Passagem OPC-UA 1:1, coberta pelos blocos de bus | Sem impacto |
| 9 | Sorting | Sem transicao de saida; cicla internamente | Impede o fechamento do ciclo da linha |
| 10 | `Master/FB11` | Lidas 9 das 72 paginas; padrao do Testing extrapolado aos outros 5 destinos | Verificar antes de extrair tempos |
| 11 | Granularidade | Varias estacoes tem mais estados que redes no ladder | Nao contradiz o ladder, mas os estados extras nao tem tempo proprio no CLP |
### Nota sobre a transicao para o modelo matematico
A logica desta sombra pode ser reaproveitada: a estrutura de estados e transicoes e a mesma.
O que muda e a **direcao da causalidade** -- na sombra as variaveis vem da planta e os
estados as observam; no modelo matematico os estados **geram** as variaveis a partir de
tempos medidos.
Por isso os `after()` merecem atencao especial: na sombra sao fallback (o sinal real manda),
mas no modelo matematico **passam a ser a fonte da verdade**. Os 4 casos legitimos acima ja
tem tempo definido; os demais precisarao de tempo medido para cada transicao que hoje
depende de sinal observavel.
## HISTORICO DE ERROS DO METODO (para nao repetir)
Erros de verificacao cometidos ao longo do projeto, cada um descoberto depois de ter
afirmado que estava tudo certo:
| # | Erro de metodo | Como apareceu | Correcao do metodo |
|---|---|---|---|
| 1 | Verificacao de sobreposicao so comparava **bloco vs bloco** | `J3808` sobre a caixa do `Robot2` apos mover o bloco | Passou a verificar **juncao vs estado** |
| 2 | Ao mover blocos, mover os filhos **depois** de encolher a caixa | Estados saiam da hierarquia | Tecnica da **caixa-uniao**: alargar antes, mover, so entao encolher |
| 3 | Analise de alcancabilidade so seguia transicoes **estado->estado** | 52 falsos positivos de "estado inalcancavel" | Incluir **juncoes** no grafo |
| 4 | Listagem de guardas sem resolver **cadeias de juncao** | Falso positivo `J1892 -> ProcessingToPart` sem guarda | Resolver a cadeia ate o bloco destino |
| 5 | Resolucao de cadeias **concatenava** guardas do percurso | Ramos irmaos herdavam a guarda comum; `J1888` passou como correto | Verificar **caminho sem nenhuma guarda** |
| 6 | Diagnostico do `double` do OPC UA como "tipo do servidor" | 382 casts indevidos, mascarando desconexao | O `double` indica **falha de conexao**; nao fechar o modelo durante diagnostico |
| 7 | Limpeza de orfas com filtro diferente do de deteccao de uso | 70 variaveis em uso apagadas | Usar o **mesmo** regex nos dois lados |
| 8 | Assumir que ramo sem guarda antes do guardado quebra o fluxo | 3 correcoes desnecessarias de ordem | Stateflow faz **backtracking** |
| 9 | Marcar `after()` como legitimo sem distinguir ramo de juncao de transicao irma de estado | 2 `after(4,sec)` mortos passaram como "ramo alternativo" (v0.4.16 --> v0.4.18) | So um ramo de **juncao** e alternativa real; transicao irma de estado com ordem 3 apos duas guardas complementares e codigo morto |
| 10 | Assumir que um FB irmao segue o FB ja verificado | `Distribution/FB5` e `FB6` passaram 7 versoes sem leitura; o Counted estava com a malha invertida | Ler **todo** FB cuja logica foi implementada, mesmo que a estrutura pareca identica |
---
## Mapa dos Conveyors [20] -- LEVANTAMENTO INICIAL (superado)
> Registro historico da v0.4.11, quando os conveyors ainda eram copias genericas de 12
> estados. Foram implementados na v0.4.14 (7 estados, `Master/FB11`) e refinados na
> v0.4.17 (11 estados, rede N2 desmembrada). Ver essas secoes para o estado atual.
Seis instancias do mesmo transportador, todas lendo `Control_20`/`AS_i_20` mais os
barramentos das estacoes de origem e destino. Diferem pelo **destino**, nao pela logica.
| Bloco | Estados | Entra de | Sai para | Condicao de saida |
|---|---|---|---|---|
| `CartToTesting` | 10 | `Start` (`C_24_Request`) | Distribution Single/Continuous/Counted | `C_24_CartDel` |
| `CartToProcessing` | 12 | (junces) | `PartToProcessing` | `C_25_CartDel` |
| `CartToProcessing1` | 12 | (junces) | `Vision` | `C_25_CartDel` |
| `CartToProcessing2` | 12 | (junces) | `Robot1` / `Robot2` | - |
| `CartToProcessing3` | 12 | (junces) | `Store` / `Retrieve` | - |
| `CartToProcessing4` | 12 | (junces) | `Handling1_Cart2Del` | - |
Sequencia interna (identica nas 5 instancias `CartToProcessing*`):
```
InitialCondition > StartsProcess > PartLeavesSensor > CartStartsMoving
> CartGetsNearNextStation > DetectionofCartNumberinStation > CartPassesNextStation
> PartArrivesSensor > CartArrivesinNextStation      (+ T1, T2, T3 = temporizadores)
```
`CartToTesting` tem 10 estados: a mesma sequencia sem `PartLeavesSensor` e `PartArrivesSensor`
(sai da Distribution, onde ainda nao ha peca no carro para monitorar).
Cada instancia representa **um trecho do trilho**: Distribution->Testing, Testing->Handling2,
->Vision, ->Robot, ->Storage, ->Handling1. O `DetectionofCartNumberinStation` le o
`*_CartID` correspondente (`A_73_TestCartID`, `A_93_ProcCartID`, etc.), que e um dos poucos
campos numericos do modelo.
> Nao ha PDFs de ladder do Conveyor [20]. Estas 6 instancias **nunca foram verificadas**
> contra o CLP, e os `after(2,sec)`/`after(3,sec)` delas nao podem ser corrigidos sem o ladder.
## CONTEXTO PARA RETOMAR
**O que e este projeto:** sombra digital de um FMS didatico controlado por CLP S7
(CPU 313C-2 DP), em Simulink/Stateflow. O modelo **observa** a planta via OPC UA;
todos os barramentos entram no Chart com escopo `Input` (somente leitura).
**Como o Chart e organizado:** 29 blocos de topo (estados `OR`) no nivel do Chart,
ligados por uma rede de ~70 juncoes que forma o fluxo da linha. Cada bloco e uma
estacao ou um modo de operacao dela. O topo e `EXCLUSIVE_OR`: **um bloco ativo por vez**.
**Onde estao as coisas:**
- Modelo: `Digital Model - STF/FullFMS_2026_02_25_V0_4_31_R2025b.slx` (para rodar no R2025b,
  onde o OPC UA funciona) e `..._V0_4_31_R2026a.slx` (fonte). Gerar a versao R2025b SEMPRE com
  `Simulink.exportToVersion(m, arq, 'R2025B_SLX')`.
- PDFs do FMS atual: `Full_FMS_PDFs_V2/` (o `Full_FMS_PDFs/` e a V1)
- Bus objects: `Digital Model - STF/BUS_CONFIG.mat` (carregado pela `PreLoadFcn`)
- PDFs de ladder: `Full_FMS_PDFs/` (8 pastas) + texto extraido em `_txt/`
- Utilitarios de leitura de ladder: `Matlba/pdf2txt.m`, `pdfPage.m`, `dumpLadder.m`,
  `inflateBytes.m`, `getCMaps.m` -- leem os PDFs em MATLAB puro (nao ha Python nem
  pdftotext na maquina) e recuperam a **polaridade NA/NF** dos contatos
**Como validar o Chart sem OPC UA:** montar um modelo scratch com o Chart e 32 Inports
tipados com os bus objects (`OutDataTypeStr = 'Bus: B_xxx'`), conectados na ordem de
`D(i).Port`, e rodar `set_param(sc,'SimulationCommand','update')`. Isola a logica do
Stateflow da conexao OPC UA.
**Armadilhas da API do Stateflow** (ver secao de Notas): ordem `Destination` antes de
`Source` ao criar transicoes; criar estados e transicoes na mesma passagem; caixa-uniao
ao mover; `delete()` falha em silencio; `IsGrouped` impede criar objetos dentro do bloco.
**Pendencia estrutural unica:** a Sorting nao tem transicao de saida.
**Validacao que falta inteira:** o modelo nunca rodou com dados da planta. Os erros mais
graves desta sessao (`J1888` mandando todo carro para `Retrieve`; Handling 2 com o sentido
invertido) **nao apareciam na compilacao** -- so apareceriam em simulacao.
---
## Notas
- Auditoria da v0.4.10: 30 blocos de topo, 298 estados, 0 campos de bus inexistentes,
  0 identificadores nao declarados, 0 sobreposicoes.
- **O Chart foi compilado e valida sem erros** (harness isolado, v0.4.11). O modelo completo
  depende dos servidores OPC UA estarem conectados. Rode Ctrl+D com a conexao ativa.
- Os OB1 de cada estacao (inicializacao) nao foram modelados: assume-se que as
  condicoes iniciais estao corretas.
- FB2/FB3 de cada estacao sao passagem direta de tag OPC-UA (contato -> bobina, 1:1),
  ja coberta pelos blocos de bus no Simulink.
- Duplicatas de transicao **anteriores** a este trabalho, nao mexidas:
  `StartsProcess->T1` (6 copias), `InitialCondition->ArmToDelivery` (3),
  `Elevator_Down->End_Process` (2), `PartDel_CheckLoop->ArmToMagazine1` (2),
  `PartDel_CheckLoop->T1` (2).
- Inconsistencia de arquitetura: a Sorting e terminal com ciclo interno (entra pelas
  junces, nunca sai), enquanto Processing e Handling 1 sao de passagem. O topo do
  chart e `EXCLUSIVE_OR`, entao so um bloco fica ativo por vez - o que difere do CLP
  real, onde o OB1 chama todos os FBs a cada scan.
### Extracao dos PDFs de ladder
Nao havia Python nem pdftotext na maquina. Utilitarios em `Matlba/` fazem a leitura
em MATLAB puro: `pdf2txt.m`, `pdfPage.m`, `dumpLadder.m`, `inflateBytes.m`, `getCMaps.m`.
Decodificam fontes CID via CMap e recuperam a **polaridade dos contatos (NA/NF)** a
partir das barras de negacao vetoriais - validado contra o `Sorting/FB4` com 100% de
acerto. Texto extraido dos 47 PDFs em `Full_FMS_PDFs/_txt/`.
**Leitura visual (v0.4.22):** `renderPdfPage(pdf, pagina, 'saida.png')` redesenha a pagina
(linhas, retangulos e texto, com a matriz `cm` aplicada) e exporta imagem. Serve para
confirmar a **topologia de ramos paralelos**, que o texto sozinho nao mostra -- foi o que
resolveu a rede 6 do `Hd2/OB1`. O indice de pagina e o mesmo do `pdfPage` (streams com texto).
### Armadilhas da API do Stateflow
- Ao criar transicoes por script, definir `Source` antes de `Destination` faz o
  Stateflow reparentear a transicao para o Chart. Ordem correta: `Destination` primeiro.
  Nao use `SourceOClock`/`DestinationOClock`.
- Criar os estados e as transicoes na MESMA passagem funciona; reposicionar estados
  DEPOIS derruba as transicoes para o nivel do Chart.
- Ao mover/redimensionar um bloco, aumente a caixa ANTES de mover os filhos
  (tecnica da caixa-uniao), senao os estados saem da hierarquia.
- `delete()` falha silenciosamente as vezes, deixando estados orfaos com nomes
  duplicados (`Config_X` e `Config_X1` sobrepostos). Sempre verifique apos apagar.
---