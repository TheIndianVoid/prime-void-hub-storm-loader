# Prime Void Hub — Storm Loader

Loader público da Storm Suite v9.0.2 para Roblox RSBK. O projeto Olho do Prime Void é independente.

## Execução

```lua
loadstring(game:HttpGet('https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Loader.lua'))()
```

O arquivo `Loader.lua` consulta o gateway dedicado da Vercel, que entrega a source Luau. A source original é mantida no repositório GitHub privado `prime-void-hub-storm-suite`; contudo, **qualquer pessoa que acessar o endpoint público poderá obter uma cópia do código servido**. Repositório privado não equivale a proteção contra extração do código carregado pelo cliente.

Gateway: https://prime-void-hub-storm-gateway.vercel.app/prime-void-hub.lua

Estado: implantação reportada como READY na Vercel; a resposta HTTP externa e a execução no Roblox ainda não foram testadas.
