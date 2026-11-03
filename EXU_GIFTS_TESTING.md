# Prime Void Hub — Exu Rewards & Halloween Event Lab (branch de teste)

Este é um diagnóstico **experimental**, não a release principal. O loader de teste executa o `Loader.lua` do branch `main` sem modificá-lo, depois carrega `Exu_GiftHop_Test.lua`. O gateway de telemetria não é alterado.

## Iniciar

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/refs/heads/test/exu-gift-hop/Loader_ExuRewards_TEST.lua"))()
```

PlaceId exclusivo: `103076400317371`. Janela nativa de teste arrastável e minimizável, com três abas: Recompensas, Halloween e Logs. O botão X faz cleanup dos listeners e dos dados temporários em `Workspace`.

## Logs e diagnóstico (não mais genéricos)

1. Aba **Logs** mostra cada evento com timestamp UTC, categoria, resultado e parâmetros relevantes. O botão **COPIAR LOGS** facilita envio para revisão.
2. Se o executor oferece `writefile` e `makefolder`, os arquivos são gravados em `workspace/primevoid_hub/Exu_Security_Lab/Logs/GiftHalloween_<timestamp>.log` (a função de arquivos recebe o caminho relativo, sem prefixo `workspace/`).
3. Em tempo de execução, `Workspace.PVEXU_EventLab_Logs` também contém entradas `StringValue`, e `Workspace.PVEXU_Test_Log` contém a última linha. Eles são locais e são removidos ao encerrar o laboratório.
4. **INSPECIONAR PRESENTES** registra rótulos de UI e atributos relacionados a recompensas para investigar por que o resgate não confirmou.

Se `writefile` não existir, a aba Logs e a pasta em `Workspace` continuam funcionando. A indicação no painel será "apenas memória".

## Recompensas — correção de diagnóstico

O arquivo do jogo revela uma `RemoteFunction` chamada `ReplicatedStorage.Remotes.Rewards`, e `Config.Gifts` descreve prêmios em **1, 3, 5, 8, 12, 16, 22 e 30 minutos**. O script que realmente aciona os presentes (`ClientMain`) **não está decompilado**: não é possível afirmar a assinatura do remote sem observar uma ação legítima.

1. Clique **CAPTURAR RESGATE**, resgate no menu original, e confira a linha `REWARD_CAPTURE` na aba Logs.
2. Para um segundo resgate, clique **CAPTURAR RESGATE** novamente e realize outro resgate manual no jogo.
3. Clique **CONFIRMAR**: agora **todos os índices capturados** são marcados como concluídos, em vez de marcar apenas o último.
4. Clique **INICIAR AUTO RESGATE** e acompanhe `REWARD_START`, `REWARD_DUE` e `REWARD_ATTEMPT`. O timer parte do momento da execução do teste, não necessariamente da entrada na sessão.
5. **TESTAR PRÓXIMO AGORA** realiza uma única chamada diagnosticada para o próximo prêmio não confirmado. O laboratório registra integralmente o retorno, mas **não marca `nil`/desconhecido como sucesso**.
6. O Server Hop fica bloqueado enquanto a conclusão não estiver comprovada. Há um limite experimental de dois hops e verificação de prêmio após a mudança de servidor. A hipótese de reset de prêmios por servidor ainda não está provada.

Desative a opção antiga **Auto trocar servidor sem Exu** durante os testes para não interromper os 30 minutos.

## Halloween — descoberta fundamentada na source do jogo

`ReplicatedStorage.Shared.Halloween` define **três missões diárias sorteadas de nove**. O progresso exato vem de `LocalPlayer:GetAttribute("HwDaily")` como JSON com índices `i` e contador `n`; `LocalScript_HalloweenShop.lua` utiliza exatamente essas duas propriedades. A rotação dos eventos está definida em `Halloween.every=1800` (30 min) e `offset=900`.

| Chave | Missão | Meta | Doces |
|:--|:--|--:|--:|
| pick | Pegue 20 abóboras | 20 | 15 |
| skel | Derrube 10 monstros | 10 | 15 |
| seal | Sele 2 tumbas | 2 | 20 |
| giant | Golpeie a Abóbora Gigante | 40 | 15 |
| boss | Golpeie o Sete Catacumbas | 40 | 25 |
| soul | Leve almas ao caldeirão | 6 | 20 |
| dance | Sobreviva na Dança das Covas | 6 | 20 |
| ghost | Bata nos Fantasmas Ladrões | 15 | 15 |
| lost | Ache uma Abóbora Perdida | 1 | 15 |

O `RemoteEvent` `ReplicatedStorage.Remotes.Hw` comunica criação, posição e remoção de alvos: `pick+`, `pick-`, `tomb+`, `tombSeal`, `skel+`, `gh+`, `giantFall` etc. O código de cliente decompilado revela `Hw:FireServer("leave")`, mas não fornece uma operação cliente confiável para "completar missão". O progresso é controlado pelo servidor.

**Automação implementada para teste:** coletar abóboras durante o evento `hunt` para missão `pick`; aproximar-se de tumbas durante `graves` para missão `seal`. Usa `Humanoid:MoveTo` e `PathfindingService`, não teleporta diretamente nem falsifica contadores; registra se houve aproximação ou evento de conclusão no servidor. Ativar somente na aba **Halloween** com o Auto Farm e outro Server Hop desligados.

**Ainda não automatizado:** combate contra monstros, gigante, boss, fantasmas, transporte de almas, dança e abóbora perdida. Dependem de validação da mecânica concreta antes da automação e são acompanhados pela interface e logs. Não se deve anunciar essas sete missões como concluídas.

## Critérios para eventual integração no main

- O log do resgate precisa mostrar a assinatura válida e evidência de sucesso (não apenas um `InvokeServer` sem retorno).
- Confirmar que realmente existe reset de prêmios ao trocar de servidor, para evitar hops inúteis.
- Para Halloween, confirmar pelo menos uma coleta de abóbora e um selamento com crescimento do `HwDaily`.
- Confirmar que não existe conflito com Auto Farm, auto hop antigo e outros ports.
- Realizar testes dentro do Roblox. Revisão estática não comprova execução real.


## Diagnóstico do teste de 3 de novembro de 2026

Resultado comprovado pela saída real do usuário:

- `10:36:07Z`: teste iniciou a contagem local.
- `10:37:10Z`: a chamada manual `Rewards:InvokeServer("gift", 1)` retornou `true`.
- `10:39:07Z`: a chamada automática `Rewards:InvokeServer("gift", 2)` retornou `true`, quando o timer **local do teste** alcançou 180 segundos.
- O usuário percebeu aproximadamente 10 segundos de atraso em relação ao painel nativo do jogo. Como o timer de teste começa ao iniciar o script, **não necessariamente na entrada no servidor**, isso é plausível. Não é prova de atraso de rede nem de controle client-side.

### Melhorias na branch experimental

- O timer de resgate agora verifica a condição a cada `0.35` segundo, em vez de aguardar até 2 segundos.
- **ANTECIPAR TESTE 12s: ON/OFF**: por padrão, ativa um conjunto limitado de sondagens de `Rewards("gift", index)` nos 12 segundos anteriores ao tempo local estimado. O retorno `false` provoca espera entre as novas tentativas, não um bloqueio desnecessário de 30 segundos.
- Registros adicionais: `REWARD_PROBE`, `REWARD_SEND`, `REWARD_GATE`, `REWARD_ATTEMPT`, `REWARD_ACCEPTED`, `REWARD_UI_TIMER`. Anotam *offset* de tempo, duração da chamada, argumentos e resposta do servidor.
- **Um retorno `true` antes do timer local NÃO prova bypass:** pode ser que o tempo de sessão tenha começado antes da execução do teste. Para dizer se o servidor valida a espera é preciso comparar as sondagens antes da disponibilidade com a contagem de tempo **do próprio jogo** e verificar os retornos em sessões diferentes.
- Se uma tentativa for rejeitada depois do tempo nominal, o laboratório tenta novamente com intervalos maiores, até orçamento máximo de 9 tentativas; então pausa, registra a causa e impede hop não confirmado.
- **Servidor vs cliente**: a configuração `Config.Gifts` é acessível no cliente; a resposta booleana de `Rewards` vem de uma RemoteFunction. O handler servidor da RemoteFunction não está disponível no arquivo decompilado. Por isso, a validação do prazo **ainda não é confirmada**.

### Como confirmar o comportamento do cooldown

1. Resgate manualmente o presente #1 e confirme o protocolo `"gift",1` na aba Recompensas.
2. Ative o Auto Resgate com **ANTECIPAR TESTE 12s: ON**. Se quiser descartar qualquer sondagem antecipada, deixe OFF.
3. Envie os registros `REWARD_PROBE`, `REWARD_SEND`, `REWARD_GATE`, `REWARD_ATTEMPT` e `REWARD_ACCEPTED` do presente #2 ou #3. Se a aba do jogo tiver contador visível, informe quanto tempo ela mostrava ao início da tentativa.
4. Se o servidor responder `false` antes da elegibilidade e `true` quando ela chegar, há forte indício de verificação no servidor. Se responder `true` muito antes da elegibilidade *real* verificada, o teste precisa confirmar se o relógio cliente é apenas estimativo ou se há falha na validação.
