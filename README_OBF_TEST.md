# Prime Void Hub — Universal Obscura TEST

**Status:** build testado estaticamente e publicado na branch `test/all-obfuscated-sources`. **NÃO É PRODUÇÃO.** O `main/Loader.lua`, as cinco sources originais e os gateways Vercel permanecem intocados.

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
