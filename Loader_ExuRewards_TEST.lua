-- Prime Void Hub | Exu timed-rewards Obsidian UI TEST.
-- Entry point remains the same; production Loader.lua and Exu gateway remain unchanged.
if tonumber(game.PlaceId)~=103076400317371 then
    warn("[PVEXU TEST] Este loader de teste funciona apenas no Roube um Exu.")
    return
end
local url="https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/refs/heads/test/exu-gift-hop/Loader_ExuRewards_UI_TEST.lua"
local source=game:HttpGet(url)
local chunk,err=loadstring(source)
if not chunk then
    error("[PVEXU TEST] Não foi possível compilar o loader de teste: "..tostring(err),0)
end
chunk()
