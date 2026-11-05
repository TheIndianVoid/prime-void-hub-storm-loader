# Prime Void Hub — Universal Obscura TEST

**Status:** compilação automatizada aprovada, publicado na branch `test/all-obfuscated-sources`. **NÃO É PRODUÇÃO para os ports ofuscados.** As fontes originais dos jogos e os gateways Vercel não foram modificados.

## Atualização de 04/11/2026 — tradução e funcionalidades universais

O mesmo `Loader_Obfuscated_TEST.lua` foi atualizado, sem criar outro launcher.

- O loader de testes agora inclui os módulos oficiais **Auto Save** e **Autoexec** (preferências individuais por port), além da correção de posicionamento na coluna esquerda de Settings.
- Os textos de interface passam pela camada compartilhada `main/PVH_Locale.lua`, que consulta a preferência **PT-BR/EN-US do próprio jogo**. Não há dois idiomas apresentados ao mesmo tempo; rótulos legados como "Miscellaneous", "Minimize", "Race Mode" e "Fullbright" recebem equivalentes localizados.
- Os cinco ports protegidos e o módulo de presentes do Exu foram recompilados pela pipeline do GitHub Actions a partir dos gateways e transformações atuais do loader. O Destruction Simulator permanece na build Obscura já existente, sem dupla ofuscação.
- O próprio arquivo despachante `Loader_Obfuscated_TEST.lua` continua legível: são **as fontes de gameplay que ele carrega** que estão ofuscadas. Esse é o formato do teste original.
- O launcher principal continua carregando fontes não ofuscadas dos gateways; apenas o módulo de tradução compartilhada foi integrado ao seu fluxo normal.
- Antes de promover qualquer alteração adicional em mecânicas do jogo, validar no Roblox PT-BR/EN-US, especialmente mudanças de idioma durante a sessão e teleporte para outro place.

## Checker de funções (somente teste)

O próprio loader ofuscado inicia **PVH_Checker_TEST.lua** e coloca **Config → Diagnóstico / Diagnostics** na interface, quando o port permite adicionar grupos Obsidian.

- **Verificar todas as funções**: audita cada toggle, slider, dropdown, campo, atalho e botão descoberto na source e na UI. A auditoria inicial é automática, sem clicar em nada que afete o jogo.
- **Copiar relatório**: copia JSON com a situação de cada função para análise, sem incluir tokens/cookies ou nome da conta. No F9, busque por \`[PVH CHECKER]\`.
- **Modo de emergência**: \`getgenv().PVH_RunChecker()\` roda pelo console caso a interface de Diagnóstico não esteja disponível.
- **STRUCTURE_OK**: controle registrado e com callback/setter acessível, ou botão localizado. Isso **não comprova o efeito dentro do jogo**.
- **MISSING/ERROR**: controle esperado ausente ou inconsistente.
- **WARNING**: função desabilitada, lista vazia ou API ausente.
- **UNVERIFIED**: proteção/idioma/condição dinâmica impediu a inspeção.
- Ações de farm, combate, teleport, servidor e remotes **não são executadas automaticamente**. O relatório não pode atestar efeitos no servidor sem testes específicos reais.

A CI valida a compilação do checker e gera um catálogo por port a partir da source corrigida **antes** da ofuscação. O Destruction Simulator usa uma lista de referência v0.2.4 e tenta descobrir os botões reais da interface porque a build VM já chega protegida.

## Loader universal de testes

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/refs/heads/test/all-obfuscated-sources/Loader_Obfuscated_TEST.lua"))()
```

Mesmo carregamento automático dos jogos, com fontes de teste ofuscadas:

- Ride Storm — `obfuscated/storm.lua`
- Huntress — `obfuscated/huntress.lua`
- Roube um Exu (Exu Security Lab) — `obfuscated/exu.lua`
- Destruction Simulator — `obfuscated/destruction.lua` (cópia exata da build Obscura já publicada)
- Don't Splash — `obfuscated/splash.lua`
- Módulo de Presentes AFK do Exu — `obfuscated/exu-gifts.lua`

**Importante:** o `Loader_Obfuscated_TEST.lua` não é ofuscado: somente as fontes executadas por ele são. Isso permite inspecionar o despachante e diagnosticar um problema sem tocar no `main`.

## Como foi criado

As cinco sources são baixadas dos gateways existentes **somente durante o build**. A versão normal de `main/Loader.lua` é executada até imediatamente antes de carregar o port, para aplicar os ajustes normais *antes* de ofuscar. Depois a Obscura 1.1.0 (perfil `native`) protege cada source. A build Destruction existente já é Obscura e não é reofuscada.

Ações de validação:
1. Conferir assinaturas das cinco sources.
2. Reproduzir as transformações normais do loader em Luau isolado, sem iniciar o jogo.
3. Exigir explicitamente os toggles **Presentes AFK** no Exu já transformado.
4. Compilar cada versão transformada e cada versão ofuscada com o compilador Luau v0.745.
5. Compilar também `Loader_Obfuscated_TEST.lua`.
6. Publicar apenas `obfuscated/` nesta branch por GitHub Actions, sem alterar o loader principal.

Artefatos e hashes SHA-256 em [obfuscated/manifest.json](obfuscated/manifest.json). Workflow em [build-obfuscated-test.yml](.github/workflows/build-obfuscated-test.yml).

## Limitações

A compilação automática **não substitui o teste real dentro do Roblox**. O perfil Obscura `native` pode ter diferenças de desempenho ou compatibilidade com executores. O loader de testes **não volta automaticamente para sources originais** caso um arquivo ofuscado falhe; ele mostra erro e interrompe o port, para que o teste não dê falso positivo.

Nenhuma janela de Halloween é carregada por este loader. Os recursos presentes no main, incluindo **Presentes AFK** e o logger, continuam na cópia de teste já processada antes da ofuscação.
