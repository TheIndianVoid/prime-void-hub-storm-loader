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
