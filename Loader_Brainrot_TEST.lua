-- Prime Void Hub | Steal a Brainrot | Independent TEST loader v0.1
-- Non-destructive: this test does not change production universal Loader.lua.
local place=tonumber(game.PlaceId) or 0
local universe=tonumber(game.GameId) or 0
if place~=109983668079237 and universe~=7709344486 then
    warn("[PVH BRAINROT] Jogo incorreto: "..tostring(place).." / "..tostring(universe))
    return
end
local e=(type(getgenv)=="function" and getgenv()) or _G
if type(e.PVBR_Unload)=="function" then pcall(e.PVBR_Unload) end
local base="https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/refs/heads/feature/steal-brainrot-port-20261110/"
local old=e.PVH_Persistence
if type(old)=="table" and type(old.Stop)=="function" then pcall(function()old:Stop()end) end
local persist
local okPersist,errorPersist=pcall(function()
    local construct=loadstring(game:HttpGet("https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/PVH_Persistence.lua"))()
    persist=construct({
        port="Steal a Brainrot",
        nativeConfig="primevoid_hub/Steal_Brainrot/Configs/ui_settings.json",
        originUniverse=universe,
        loaderUrl=base.."Loader_Brainrot_TEST.lua",
    })
    e.PVH_Persistence=persist
    persist:BeforePort()
end)
if not okPersist then warn("[PVH BRAINROT] Config unavailable: "..tostring(errorPersist)) end
local ok,err=pcall(function()
    local raw=game:HttpGet(base.."StealBrainrot_TEST.lua?cb="..tostring(os.time()))
    local fn,parseError=loadstring(raw)
    if not fn then error("Luau compilation failed: "..tostring(parseError)) end
    fn()
end)
if not ok then
    warn("[PVH BRAINROT] Runtime failure: "..tostring(err))
    return
end
if persist then pcall(function()persist:AfterPort()end)end
e.PV_Hub_ActivePort="Steal a Brainrot"
warn("[PVH BRAINROT] Port loaded in TEST mode")