# Prime Void Hub — Universal Loader

Loader universal do **Prime Void Hub** para experiências Roblox compatíveis. Os ports são carregados de `main/obfuscated` ou, em módulos diretos auditados, de `ports/`. Interface, AutoSave, AutoExecute, logger e checker são compartilhados.

## Execução

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Loader.lua"))()
```

## Cobertura e publicações

- **263 registros de jogos** previstos nesta release: 233 já publicados + 15 do Lote 17 + 15 do Lote 18.
- Lote 1 — 10 ports experimentais.
- Lote 2 — 10 ports experimentais.
- Lote 3 — 15 ports experimentais.
- Lote 4 — 15 ports experimentais.
- Lote 5 — 6 ports experimentais (parcial).
- Lote 6 — 5 ports experimentais (parcial).
- Lote 7 — 15 ports experimentais compilados e protegidos.
- Lote 8 — 15 ports experimentais compilados e protegidos.
- Lote 9 — 15 ports experimentais compilados e protegidos.
- Lote 10 — 15 ports experimentais compilados e protegidos.
- Lote 11 — 15 ports experimentais compilados e protegidos.
- Lote 12 — 15 ports experimentais compilados e protegidos.
- Lote 13 — 15 ports experimentais compilados e protegidos.
- Lote 14 — 15 ports experimentais compilados e protegidos.
- Slap Battles (VINQ SB) — 1 port experimental, bridge Fluent/Obsidian.
- Lote 15 — 15 ports experimentais em Obscura VM.
- Lote 16 — 15 ports experimentais em Obscura VM.
- Lote 17 — 15 ports experimentais em Obscura VM.
- Lote 18 — 15 ports experimentais em Obscura VM.
- Lote 17 — 15 ports experimentais em Obscura VM.
- Lote 18 — 15 ports experimentais em Obscura VM.
- Próximos lotes — **até 15 ports** do inventário aprovado, cada um mediante autorização independente. O padrão-alvo segue sendo 15 quando existirem candidatos seguros e módulos protegidos preparados.
- Para a lista completa de jogos e PlaceIds, consulte `Loader.lua`; a Home exibe o catálogo dinamicamente.
- Histórico de publicações: `batch-releases/`. Padrão técnico e nomenclatura: `PORT_UI_STANDARD.md`.

## Interface e execução

O modelo de referência tem Home, abas próprias de funcionalidades e Configurações com perfis, idioma PT/EN, AutoSave (ativado por padrão), AutoExecute (opt-in) e Rejoin quando o executor permitir. O checker automático produz TXT na pasta `primevoid_hub/<port>/Logs`; o logger universal grava tentativas de execução.

O port **Steal An Exu** mantém Auto Farm em manutenção. Outros recursos não foram removidos nesta integração.

> **Experimental:** binários compilados e protegidos, checks estruturais, ou recebimento HTTP do logger não atestam que as funções realmente funcionam em partidas do Roblox. A distribuição Obscura não impede extração de código no cliente. O projeto O Olho do Prime Void é independente.

As builds privadas dos Lotes 15–18 reutilizam os archives auditados e o pipeline persistente. O carregamento de novos módulos exige um binário VM completo, seu hash e integração com `PVH_Checker`/`PVH_Persistence`. Os ports acrescentados nesses lotes são experimentais; nenhum resultado de gameplay foi confirmado em jogo.
