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

## Recompensas — AUTOMAÇÃO SEM CAPTURA MANUAL (atualização do teste)

O protocolo de resgate foi **confirmado pelos logs reais de 2026-11-03**:
`ReplicatedStorage.Remotes.Rewards:InvokeServer("gift", indice)`, com `indice` de 1 a 8.

**Não é mais necessário capturar, confirmar ou clicar em qualquer botão**. Basta executar o loader de teste; o resgate automático inicia após carregar a interface.

- O teste encontra `PlayerGui.HUD.Presentes` e a grade original de oito presentes. Lê cada texto de status/contagem (e.g. `31s`, `2m 31s`) para saber o momento de cada tentativa. Quando a UI reporta item já resgatado, não envia um resgate duplicado.
- O status é apresentado na aba Recompensas, com próximo prêmio e segundos restantes.
- Se não encontrar a grade, usa cronômetro aproximado e sondagens limitadas como fallback.
- A RemoteFunction continua sendo a autoridade: somente `true` confirma um novo resgate; `false` indica rejeição e agenda nova tentativa com intervalo.
- O Auto Hop experimental vem **ativado por padrão**, limitado a dois hops. Só parte depois da oitava recompensa ter sido aceita pela RemoteFunction, nunca por suposição de UI. Na chegada, se o primeiro prêmio já estiver resgatado, o teste conclui que o hop não reiniciou os presentes e **para o ciclo**.
- Os botões manuais antigos de Capturar/Confirmar foram removidos. Permanecem **CONFERIR CONTRATO**, **LER CARTÕES NATIVOS**, liga/desliga Auto Resgate, pausa, e **TESTAR PRÓXIMO AGORA** (diagnóstico opcional).
- O código de hook `__namecall` para a captura anterior foi removido.

### Logs principais

`REWARD_AUTO_START`, `REWARD_NATIVE_UI`, `REWARD_WAIT`, `REWARD_PROBE`,
`REWARD_SEND`, `REWARD_ATTEMPT`, `REWARD_ACCEPTED`, `REWARD_GATE`,
`REWARD_ALREADY_CLAIMED`, `REWARD_NO_RESET`, `REWARD_ALL_DONE`.

**Limitação:** a UI é útil para agendar ações, mas ela não é prova da validação interna do servidor. A implementação de `OnServerInvoke` permanece indisponível na cópia decompilada. Não há prova de que os limites de tempo podem ser ignorados.

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

1. Execute o loader de teste. O Auto Resgate é iniciado sozinho e sincronizado com os oito cartões da interface nativa.
2. Consulte `REWARD_NATIVE_UI`, `REWARD_PROBE`, `REWARD_SEND`, `REWARD_GATE`, `REWARD_ATTEMPT` e `REWARD_ACCEPTED` se algum item atrasar ou falhar.
3. Quando todos os oito forem confirmados, teste o comportamento do **Server Hop**. Caso o prêmio #1 esteja marcado como coletado no servidor novo, o sistema registra `REWARD_NO_RESET` e interrompe o farm em vez de repetir hops improdutivos.

## Obsidian — seção nova para testar (2026-11-03)

O `Loader_ExuRewards_TEST.lua` agora carrega a cópia experimental `Loader_ExuRewards_UI_TEST.lua`, derivada do `main/Loader.lua`. A **cópia de teste** introduz um groupbox do lado direito da aba **Farm**, imediatamente após **Seleção de alvos** e antes de **Estado da sessão**:

- **Recompensas por tempo** / **Timed rewards**
- **Auto resgatar presentes** / **Auto-claim gifts** (toggle, sem keybind)
- **Trocar servidor ao finalizar** / **Server hop after gifts** (toggle, sem keybind)

Ambos começam **OFF**. O addon `Exu_GiftHop_Test.lua` recebe as opções via `getgenv().PVEXU_TestRewardsPrefs` e só inicia quando o usuário ativa a respectiva opção na Obsidian. A janela experimental de diagnóstico começa **minimizada** para priorizar a interface principal, mas pode ser restaurada pelo botão `+`. Logs continuam sendo escritos.

Durante um hop autorizado pelo usuário, o estado ON dos dois toggles é transferido via `queue_on_teleport`. A checagem de resgate do presente #8 e limite experimental de dois hops continuam em vigor. Se a validação do reset no novo servidor falhar, o teste não insiste indefinidamente.

O código tenta localizar no texto-fonte da versão atual o construtor da seção Estado da sessão. Se o gateway modificar esse trecho, a injeção falha fechada, imprimindo `[PVEXU UI TEST] Session-state group constructor not found`; não deve criar uma seção em posição errada nem editar o loader principal.

**Nenhum commit alterou** `main/Loader.lua` ou o gateway Vercel. O build foi revisado estaticamente; a posição final e a troca de idioma ainda precisam ser verificadas dentro do Roblox.
