# Prime Void Hub — Universal Loader

Loader universal do **Prime Void Hub** para experiências Roblox compatíveis. Os ports são carregados de `main/obfuscated`, e a interface usa módulos compartilhados de configurações, idioma, diagnósticos e Auto Execute.

## Execução

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Loader.lua"))()
```

## Ports incluídos

- Ride Storm — Storm Suite
- HUNTRESS
- Steal An Exu — Exu Security Lab (**Auto Farm em manutenção**)
- Destruction Simulator
- Don't Splash
- Clover Legends: Devil Fusion — v0.1.3

**Clover Legends:** PlaceId `109813591245812`; UniverseId `10769707586`. Usa `obfuscated/clover.lua`, derivado da versão compilada na branch `test/all-obfuscated-sources`.

O painel segue o padrão comum de **Home, Farm, Miscelânea e Configurações**. O módulo `PVH_Persistence.lua` disponibiliza Auto Save (ligado por padrão), Auto Execute em teleporte (opt-in) e Rejoin quando suportados pelo executor. A aba Configurações também conta com idioma PT/EN, perfis e checker; Home exibe conta e lista de ports. O carregamento do código não comprova que cada automação funciona em tempo real.

> A distribuição protegida/obfuscada não impede extração de código que é executado no cliente. O projeto Olho do Prime Void é independente.
