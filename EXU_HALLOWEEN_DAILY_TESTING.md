# Halloween Daily Agent — Exu TEST (2026-11-03)

**Somente testes**. O `Loader.lua` da branch `main`, os gateways e o envio de telemetria permanecem intocados.

## Como carregar

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/refs/heads/test/exu-gift-hop/Loader_ExuRewards_TEST.lua"))()
```

O laboratório continua arrastável/minimizável, com abas Recompensas, Halloween e Logs. O launcher habilita automaticamente **AUTO MISSÕES DIÁRIAS: ON**. O botão na aba Halloween pode desligar a automação; o script pausa movimento se o Auto Farm normal ou o Server Hop por falta de Exus estiver ligado.

## Descobertas reais na cópia .rbxlx

- `ReplicatedStorage.Shared.Halloween.daily.pool` contém nove objetivos; `LocalPlayer.HwDaily` indica as três tarefas selecionadas e o progresso `{i,n}`.
- Caso observado nos logs enviados: **lost:0/1**, **dance:0/6**, **soul:0/6**.
- `Halloween.lost`: tentativa de spawn periódico a cada 150 segundos, vida de 60 segundos. Sem garantia de horário real ou de elegibilidade.
- `Halloween.kinds.cauldron`: evento de portal, com coleta de almas nas tumbas e entrega ao caldeirão.
- `Halloween.kinds.dance`: evento de portal, sobreviver em covas acesas. O módulo configura 12 rodadas (missão diária exige sobrevivência em 6).
- `Halloween.PORTAL_POS` é a posição (0, 1, -248). O ingresso e o sucesso são validados pelo próprio jogo.
- Os eventos de Halloween rodam na configuração a cada 1800 segundos (30 minutos), com rotação e offset. `HwKind` informa o evento atual.
- Os scripts servidor que geram e validam os alvos **não estão presentes no cliente decompilado**; nomes reais dos objetos especiais do Caldeirão e Dança só podem ser observados durante o evento ativo.

## O que foi implementado

1. O planejador lê diariamente `HwDaily` e atua apenas para missões incompletas. Toda mudança gera `HW_QUEST_PROGRESS` e toda conclusão `HW_QUEST_COMPLETE`, baseada no atributo de servidor.
2. **Abóbora Perdida**: procura `Hw.pick+` com tipo `lost` e objetos com nome específico de abóbora perdida perto do jogador; tenta aproximação física sem falsificar o contador.
3. **Caldeirão / soul**: quando o evento adequado ativa, tenta se deslocar ao portal. Dentro do evento, procura objetos reais denominados Soul/Alma e Cauldron/Caldeirão, aproximando-se deles na ordem de coleta/entrega. O sucesso ainda precisa ser comprovado por aumento de `HwDaily`.
4. **Dança / dance**: entra no portal adequado e procura plataformas identificadas como seguras no runtime, tentando chegar até elas. Sem nomes ou sinais confiáveis durante a rodada, não adivinha a cova.
5. **Caça e Tumbas**: mantém a aproximação a abóboras comuns e selamento de tumbas caso sejam missões ativas.
6. Cache de estado dos eventos `Hw.state`, posições `pick+` / `tomb+`, scanner espacial perto do personagem, limite de tentativas e verificação de progresso.
7. O botão de sondagem manual de presentes agora tem intervalo mínimo de seis segundos para evitar disparos em sequência.

## Diagnóstico necessário

Na próxima execução, deixe a aba Halloween em AUTO ON e copie os logs em torno de um evento:

- `HW_AGENT_BOOT`, `HW_DAILY`, `HW_EVENT`, `HW_TARGET`
- `HW_RUNTIME_SCAN` / `HW_RUNTIME_TARGET` (objetos disponíveis)
- `HW_PORTAL`, `HW_AGENT_MOVE` e `HW_AGENT_ARRIVED`
- `HW_SOUL_PICKUP_ATTEMPT`, `HW_SOUL_DELIVERY_ATTEMPT` ou `HW_DANCE_SAFE_ATTEMPT`
- `HW_QUEST_PROGRESS` e `HW_QUEST_COMPLETE` caso o jogo registre progresso

**Não declare a automação de soul/dance validada sem ver o contador HwDaily avançar no evento real.** Não há prova de que apenas andar até os objetos sempre execute as interações necessárias. Se `HW_RUNTIME_SCAN` retornar zero, o próximo passo é identificar os nomes ou a geometria reais durante o evento e ajustar os seletores. A execução em Roblox ainda não foi testada por este agente.
