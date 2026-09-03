# Sombra Digital - Full FMS (Stateflow)

Sombra digital do FMS controlado por CLP S7 (CPU 313C-2 DP), em Simulink/Stateflow.
O modelo apenas **observa** a planta: os barramentos `Sensors_*`, `Actuators_*`,
`Control_*` e `AS_i_*` entram no chart com escopo **Input** (somente leitura).
Nao existe nenhum bloco OPC UA Write.

Pasta: `Digital Model - STF/`

---

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

## Mapa dos Conveyors [20] (apenas mapeado, nao modificado)

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

## v0.4.13 --> v0.4.14  (Conveyor [20])

### O que o `Master/FB11` revelou

`Master/FB11 - Conveyor Control` tem 48 redes, mas e **o mesmo padrao de 7 redes repetido**
para 6 destinos (redes 1-7 Testing, 8-14 Processing, 15-21 Vision, 22-28 Robot,
29-35 Storage, 36-42 Sorting; 43-48 sao os comandos aos pinos de cada estacao).

| Rede | Funcao |
|---|---|
| N1 | Solicitacao de carrinho -- `C_2N_Request` ou pedido da estacao, e **nenhum outro destino solicitando** |
| N2 | Escolhe o carro mais proximo e abre o caminho (cascata de prioridade entre as estacoes) |
| N3 | Aciona a esteira -- exige `O_20_Controler_On`, senao gera `FB11_Conv_Error` |
| N4 | Desliga os pinos quando o carro fica proximo (`Cart_Next`) |
| N5 | Contador identifica o numero do carro --> `*_CartID` |
| N6 | Carro chegou (`Cart_Stat`) + timer de 3 s |
| N7 | Sinaliza chegada --> `C_2N_CartDel` |

Os barramentos confirmam a estrutura: `Control_20` e `Sensors_20` sao organizados por
indice **24 a 29** -- exatamente seis destinos.

### Mapeamento dos 6 blocos

| Bloco | Indice | Destino |
|---|---|---|
| `CartToTesting` | 24 | Testing |
| `CartToProcessing` | 25 | Processing |
| `CartToProcessing1` | 26 | Vision |
| `CartToProcessing2` | 27 | Robot |
| `CartToProcessing3` | 28 | Storage |
| `CartToProcessing4` | 29 | Sorting |

Cada bloco passou de 12 estados (copia generica, com `T1`/`T2`/`T3`) para **7 estados**
espelhando as 7 redes: `Config > EscolheCarro > EsteiraLigada > CarroProximo >
IdentificaCarro > CarroChegou > SinalizaChegada`.

### Erro encontrado: `CartToProcessing1` com indice trocado

O bloco vai para o **Vision**, mas usava `C_25_Request` e `C_25_CartDel` -- sinais do
**Processing**. Reagiria ao pedido do destino errado. Corrigido para `C_26_*`.
So apareceu porque agora existe um mapeamento sistematico para conferir contra.

### Guardas externas

As **7 transicoes externas que estavam sem guarda** foram preenchidas no padrao do CLP:
entrada exige `C_2N_Request`, saida exige `C_2N_CartDel`. Somando as do Robot (v0.4.13),
**nao resta nenhuma transicao externa sem guarda no chart**.

### Layout

Ao crescer as caixas, `CartToProcessing3` e `CartToProcessing4` colidiram com outros
blocos. Movidos para faixa livre (`y=10553` e `y=11453`).

### Ressalvas

- **A rede N2 foi simplificada.** A cascata de prioridade do ladder escolhe entre cinco
  origens possiveis de carro (Processing, Vision, Robot, Storage, Sorting), cada uma abrindo
  um caminho diferente. No modelo virou um unico estado `EscolheCarro`. Defensavel para uma
  sombra que observa o estado da linha, mas **nao e reproducao fiel** -- se for preciso saber
  *de onde* o carro veio, esse estado precisa ser desmembrado.
- **Lidas 9 das 72 paginas do FB11.** Verificado o padrao do destino Testing; assumido que os
  outros cinco seguem a mesma estrutura (o indice das redes sustenta, mas e inferencia).
  As redes 43-48 (comandos aos pinos) nao foram modeladas.

**Verificacao da v0.4.14:** 0 sobreposicoes (blocos e juncoes), 0 transicoes mal-parenteadas,
0 transicoes externas sem guarda, **Chart compila sem erros**.

---

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
## Estado atual por estacao

| Estacao | Situacao | Blocos |
|---|---|---|
| Sorting [60] | implementada, verificada contra o ladder | BRS, BSR, RBS, RSB, SRB, SBR |
| Processing [100] | implementada, verificada contra o ladder | TestOnly, TestDrill, RotationOnly |
| Handling 1 [50] | implementada, verificada contra o ladder | Handling1_Cart2Del |
| Distribution [80] | implementada, verificada contra o ladder (FB4) | Single, Continuous, Counted |
| Testing [70] | implementada, verificada contra `FB4`/`FB5` | Identified_Delivery, Requested_Delivery |
| Conveyor [20] | implementada, verificada contra `Master/FB11` | CartToTesting, CartToProcessing..4 |
| Handling 2 [90] | implementada, verificada contra `FB4`/`FB5` | PartToProcessing, ProcessingToPart |
| Storage [40] | implementada, verificada contra o ladder (estacao simulada) | Store, Retrieve |
| Robot [30] | implementada, verificada contra `Master/FB3` | Robot1, Robot2 |
| Vision | **pendente** - stub de 2 estados, **sem PDF de ladder** | - |

Nenhum bloco le `Sensors_30/40`, `Actuators_30/40` ou `AS_i_30/40`: os barramentos
dessas estacoes estao declarados e nunca usados.

PDFs de ladder disponiveis para 8 pastas (Distribution, Hd1, Hd2, Master, Processing,
Sorting, Storage, Testing). O Robot [30] esta dentro da Master (`FB3`, remota) e o
Conveyor [20] em `Master/FB11` (48 redes, 6 destinos). **Nao ha PDF do Vision.**

Pendencias: **Vision** (stub de 2 estados, `FinishesProcess` inalcancavel, **sem PDF de ladder**);
**Testing [70]** e **Handling 2 [90]** tem logica substancial mas nunca verificada contra os PDFs;
a **Sorting nao tem transicao de saida** (cicla internamente).

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
