# Prime Void Hub — Universal Loader

Loader universal do **Prime Void Hub** para experiências Roblox compatíveis. Os ports são carregados de `main/obfuscated` ou, em módulos diretos auditados, de `ports/`. Interface, AutoSave, AutoExecute, logger e checker são compartilhados.

## Execução

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Loader.lua"))()
```

## Cobertura e publicações

- **353 registros de jogos publicados** na `main` até o **Lote 24** (17/11/2026).
- Lotes 1 e 2 — 10 ports por lote.
- Lotes 3 e 4 — 15 ports por lote.
- Lotes 5 e 6 — respectivamente 6 e 5 ports (publicações parciais históricas).
- Lotes 7 a 14 — 15 ports por lote; validação e proteção quando aplicável.
- Slap Battles (VINQ SB) — 1 port experimental, bridge Fluent/Obsidian.
- Lotes 15 a 24 — 15 ports por lote, binários protegidos Obscura VM e verificação estrutural.
- **Lote 24 publicado:** 15 módulos experimentais protegidos e verificados estruturalmente (353 registros). **Próximo lote pendente: 25**, com triagem privada; efeitos de gameplay ainda não testados.
- Para a lista completa de jogos e PlaceIds, consulte `Loader.lua`; a Home exibe o catálogo dinamicamente.
- Histórico de publicações: `batch-releases/`. Padrão técnico e nomenclatura: `PORT_UI_STANDARD.md`.

## Interface e execução

O modelo de referência tem Home, abas próprias de funcionalidades e Configurações com perfis, idioma PT/EN, AutoSave (ativado por padrão), AutoExecute (opt-in) e Rejoin quando o executor permitir. O checker automático produz TXT na pasta `primevoid_hub/<port>/Logs`; o logger universal grava tentativas de execução.

O port **Steal An Exu** mantém Auto Farm em manutenção. Outros recursos não foram removidos nesta integração.

> **Experimental:** binários compilados e protegidos, checks estruturais, ou recebimento HTTP do logger não atestam que as funções realmente funcionam em partidas do Roblox. A distribuição Obscura não impede extração de código no cliente. O projeto O Olho do Prime Void é independente.

As builds privadas dos Lotes 15–18 reutilizam os archives auditados e o pipeline persistente. O carregamento de novos módulos exige um binário VM completo, seu hash e integração com `PVH_Checker`/`PVH_Persistence`. Os ports acrescentados nesses lotes são experimentais; nenhum resultado de gameplay foi confirmado em jogo.
