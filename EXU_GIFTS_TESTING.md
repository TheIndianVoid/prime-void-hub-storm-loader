# Prime Void Hub — Auto Gifts + Server Hop (ambiente de teste)

**Projeto:** Steal An Exu / Roube um Exu, PlaceId \`103076400317371\`.

## O que está confirmado no arquivo .rbxlx
- \`ReplicatedStorage.Shared.Config.Gifts\`: recompensas com 1, 3, 5, 8, 12, 16, 22 e 30 minutos de sessão.
- Última recompensa: \`kind="cash"\`, \`seconds=1800\`, \`min=60000\`.
- \`ReplicatedStorage.Remotes.Rewards\` é uma RemoteFunction.
- O código do cliente que invoca a remote não pôde ser decompilado (ClientMain está irrecuperável).
- **Não foi provado** que mudar de servidor reinicia os resgates. Esta é a hipótese a testar.

## Isolamento
Esta branch adiciona somente \`Loader_ExuRewards_TEST.lua\` e \`Exu_GiftHop_Test.lua\`. Usa o loader **main original** e injeta painel experimental por fora. Não altera \`Loader.lua\`, o gateway, nem os logs existentes. O teste não afeta outros jogos.

## Execução
\`\`\`lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/refs/heads/test/exu-gift-hop/Loader_ExuRewards_TEST.lua"))()
\`\`\`

## Teste guiado
1. No jogo, desligue a opção anterior **Auto trocar servidor sem Exu** (ela pode atrapalhar a contagem de 30 minutos).
2. Execute o loader de testes assim que entrar no servidor.
3. Clique **CAPTURAR RESGATE** no painel de teste.
4. Quando a primeira recompensa (1 minuto) estiver disponível, clique **Resgatar** *na interface original do jogo*.
5. Veja se o painel identificou o índice e retorno da \`Rewards\`. Se o item apareceu e o benefício foi recebido, clique **CONFIRMAR**.
6. Clique **INICIAR AUTO RESGATE**. Acompanhe as recompensas de 3 a 30 minutos.
7. Opcionalmente ative **HOP APÓS 30 MIN: ON**. O teleport só ocorre se todas as oito recompensas forem marcadas e a API tiver confirmado sucesso de forma suficiente. O máximo experimental é **2 hops** para evitar loop infinito. Precisa de \`queue_on_teleport\` para continuar após troca.
8. Se a nova sessão não aceitar a primeira recompensa depois de 1 minuto, o teste interrompe o ciclo.

## Limitações deliberadas
- Precisa capturar uma chamada manual antes do piloto automático; **nenhuma assinatura da remote é adivinhada**.
- Quando a remote retorna \`nil\` ou um resultado não interpretável, o painel informa que a confirmação está incompleta e **não faz hop automaticamente**.
- O tempo é contado a partir da execução do teste. Se o servidor já tiver tempo de sessão acumulado, os resgates poderão ser tentados mais tarde do que o necessário.
- Hooks de \`__namecall\` dependem do executor; se indisponíveis, o addon falha com mensagem e deixa o Hub original intacto.
- Interações e Server Hop ainda **não foram testados dentro do Roblox**. Não publicar no loader principal até os retornos reais serem verificados.
