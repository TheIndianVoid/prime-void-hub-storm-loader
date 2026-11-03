-- Prime Void Hub | Test-only gift/rewards runner.
-- Uses the CURRENT production source, but never edits the main loader.
local place = tonumber(game.PlaceId) or 0
if place ~= 103076400317371 then
    warn("[PVH Gifts TEST] Apenas Roube um Exu / Steal An Exu.")
    return
end
loadstring(game:HttpGet("https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Loader.lua"))()
local ok, errorMessage = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/refs/heads/test/exu-gift-hop/Exu_GiftHop_Test.lua"))()
end)
if not ok then
    warn("[PVH Gifts TEST] Complemento não iniciado: " .. tostring(errorMessage))
end
