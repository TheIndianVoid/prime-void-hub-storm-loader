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

-- Test-only: enable the Halloween daily planner on launch.
-- The in-game tab can disable it; conflicting Exu Farm/Server Hop pauses movement.
if ok then
    local env=type(getgenv)=="function" and getgenv() or _G
    local lab=env.PVEXU_GiftTest
    if lab and lab.alive then
        lab.halloweenAuto=true
        if type(lab.log)=="function" then
            lab.log("HW_AGENT_BOOT","Auto daily quests ON | MoveTo + server HwDaily validation")
        end
        if lab.gui and lab.gui.Parent then
            for _,element in ipairs(lab.gui:GetDescendants()) do
                if element:IsA("TextButton") and element.Text=="AUTO MISSÕES DIÁRIAS: OFF" then
                    element.Text="AUTO MISSÕES DIÁRIAS: ON"
                end
            end
        end
    end
end
