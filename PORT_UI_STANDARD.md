# Prime Void Hub — Padrão obrigatório de interface dos ports

Este documento é a referência de design/funcionalidade do **main loader / Ride Storm / Storm Suite**. Qualquer novo port ou revisão de port deve seguir o padrão completo, não somente títulos de abas.

## Início / Home
- Bloco **Conta**: avatar Roblox real (AvatarBust 180–185 px), DisplayName, @username, UserId e PlaceId.
- Bloco **Dicas úteis**: atalhos, dicas específicas do jogo, funções integradas; tradução PT-BR/EN-US por seleção, sem mostrar ambos simultaneamente.
- Bloco **Ports disponíveis**: lista atualizada de todos os ports de produção e status corretos.
- Bloco **Suporte**: Discord e canais oficiais; evitar abas "Sobre" extras.
- Estado da sessão pode aparecer no bloco de dicas ou na aba da função pertinente, sem janelas flutuantes redundantes.

## Configurações / Settings
- **Sessão** no topo esquerdo, integrada ao `PVH_Persistence` do loader: AutoSave (ativado por padrão), AutoExecute (opt-in), Rejoin, regras de teleporte. Não duplicar estes controles localmente.
- **Controles**: minimizar/descarregar, keybinds configuráveis, painel de atalhos opcional; Shift direito e Delete como defaults.
- **Aparência**: idioma PT/EN, animações e sons independentes.
- **Perfis de configuração**: campo de **nome** editável; botões com ícones para **Criar, Carregar, Sobrescrever e Excluir**. Perfis ficam em `primevoid_hub/<Port>/Configs/Profiles`.
- **Workspace**: exibir claramente caminhos `Configs`, `Logs` e `Profiles`.
- **UNLOAD / DESCARREGAR HUB**: ação destacada em vermelho (`Risky=true`) com ícone; nenhum botão visual sem callback funcional.
- Ícones Lucide apropriados nos grupos e ações. Evitar legendas repetitivas sob cada opção, diagnósticos manuais e uma aba "Sobre" separada.

## Padrões técnicos
- Obsidian: nunca usar `ToggleKeybind=Enum.KeyCode.Unknown` (cliques do mouse usam `KeyCode.Unknown`). Após `CreateWindow`, desativar o toggle interno se o botão/keypicker já controla minimizar.
- Keypickers `Mode="Press"` em botões disparam a função do botão; **não** criar outro `InputBegan` para a mesma ação.
- UI e callbacks devem persistir no AutoSave do loader. Perfil manual não substitui o AutoSave universal.
- Checker deve rodar automaticamente e gravar TXT em `primevoid_hub/<Port>/Logs`; nunca exigir clique em "Diagnóstico" para gerar logs.
- Logger universal deve conhecer PlaceId/UniverseId e nome do port; não inventar executor ou sucesso de funções.
- Port só pode anunciar ação **confirmada** depois de retorno/estado observável do jogo. Checks estruturais não provam gameplay.
- Teleportes: usar destinos físicos reais + raycast de piso + verificação de posição final; não marcar sucesso apenas porque `PivotTo` foi chamado.
- Em atualizações, nunca remover funções existentes sem solicitação. Features novas desligadas por padrão quando o efeito não é totalmente conhecido.
- Sem descrições fúteis embaixo dos botões ou toggles.

Data de registro: 2026-11-10.

## Nomenclatura oficial dos jogos (regra permanente)
- A lista **Ports disponíveis / Supported Games**, Home, título e metadados de sessão devem usar o **nome real da experiência Roblox** correspondente ao PlaceId (confirmar a página oficial e o criador quando houver ambiguidade).
- **Nunca acrescentar `+1` automaticamente**. Manter `+1` apenas se ele realmente fizer parte do nome do jogo. Igualmente, não apagar `+1` quando constar do nome oficial.
- Não transportar prefixos decorativos de arquivos, nomes de sources, pastas, rótulos de lote ou nomes inventados para a lista pública.
- Tags temporárias de atualizações (`[W2]`, `[UPDATE]`, emojis de evento) podem ser omitidas na lista para manter um nome estável, sem alterar a identidade principal.
- Para jogo renomeado, atualizar o catálogo do loader; preservar PlaceId, ID interno do módulo e configurações antigas. O `PVH_LegacyPortBridge` usa o catálogo oficial do loader para corrigir o nome exibido nas sources protegidas.
- Revisar nomes nos novos lotes de 10 **antes** de publicar; não inserir jogos indisponíveis conhecidos sem justificativa explícita.

## Publicações em lotes (regra permanente)
- A partir do **Lote 3**, cada lote tem **15 novos ports**. Lotes 1 e 2 preservam os respectivos 10 ports.
- Publicar somente o lote expressamente autorizado. A autorização para um lote não vale para o próximo.
- Antes de publicar: excluir PlaceIds duplicados, conferir o nome verdadeiro, revisar sinais de riscos da auditoria, validar presença/hash do módulo Obscura VM e integrar loader, Obsidian/bridge, `PVH_Persistence`, logger universal e `PVH_Checker`.
- Corrigir nomes somente quando comprovados; `+1` só quando realmente integra o nome oficial do jogo, nunca por suposição ou por nome de source.
- Registrar o commit e os caminhos `Configs`, `Logs`, `Profiles`; conferir a publicação na main e manter um relatório para cada lote.
- Publicação de módulo protegido e checagem estrutural **não** comprovam gameplay. Testes em partida continuam obrigatórios.
- Sources com hooks de depuração ou outros alertas de segurança exigem revisão individual antes de inclusão.
