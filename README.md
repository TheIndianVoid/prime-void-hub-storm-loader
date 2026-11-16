# Prime Void Hub — Universal Loader

Loader universal do **Prime Void Hub** para experiências Roblox compatíveis. Os ports são carregados de `main/obfuscated` ou, em módulos diretos auditados, de `ports/`. Interface, AutoSave, AutoExecute, logger e checker são compartilhados.

## Execução

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Loader.lua"))()
```

## Cobertura e publicações

- **56 registros de jogos** na branch `main` após o Lote 3.
- Lote 1 — 10 ports experimentais.
- Lote 2 — 10 ports experimentais.
- Lote 3 — 15 ports experimentais.
- Próximos lotes — **15 ports**, cada um mediante autorização independente.
- Para a lista completa de jogos e PlaceIds, consulte `Loader.lua`; a Home exibe o catálogo dinamicamente.
- Histórico de publicações: `batch-releases/`. Padrão técnico e nomenclatura: `PORT_UI_STANDARD.md`.

## Interface e execução

O modelo de referência tem Home, abas próprias de funcionalidades e Configurações com perfis, idioma PT/EN, AutoSave (ativado por padrão), AutoExecute (opt-in) e Rejoin quando o executor permitir. O checker automático produz TXT na pasta `primevoid_hub/<port>/Logs`; o logger universal grava tentativas de execução.

O port **Steal An Exu** mantém Auto Farm em manutenção. Outros recursos não foram removidos nesta integração.

> **Experimental:** binários compilados e protegidos, checks estruturais, ou recebimento HTTP do logger não atestam que as funções realmente funcionam em partidas do Roblox. A distribuição Obscura não impede extração de código no cliente. O projeto O Olho do Prime Void é independente.
