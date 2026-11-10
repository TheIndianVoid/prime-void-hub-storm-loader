-- Prime Void Hub | Steal a Brainrot | v0.1 TEST
-- Gameplay callbacks ported from source; third-party network removed; Obsidian UI.

local n = nil
local o = nil
local r = ""
local oInvoke = nil
local oUnreliable = nil
local sabSilentAimRewriteRemoteArgs = nil
local sabSilentAimUnpack = table.unpack or unpack
local sabRawPcall = pcall
local sabPack = table.pack or function(...)
    return {
        n = select("#", ...),
        ...
    }
end
local SAB_ERROR_DEMOTE_ENABLED = false
local SAB_ERROR_DEMOTE_COOLDOWN = 6
local sabDemotedErrorState = {}
local SAB_DEMOTED_ERROR_IGNORE_PATTERNS = {
    "pluginmanager",
    "tables cannot be cyclic",
}

local function sabWarnPcallFailure(err)
    --warn("[SAB] pcall failed:", tostring(err))
    if debug and type(debug.traceback) == "function" then
        --warn(debug.traceback(nil, 3))
    end
end

--[[ 
local function pcall(fn, ...)
    local results = sabPack(sabRawPcall(fn, ...))
    if not results[1] then
        sabWarnPcallFailure(results[2])
    end
    return sabSilentAimUnpack(results, 1, results.n)
end
]]

local function sabWarnDemotedError(err, trace)
    local message = tostring(err or "unknown error")
    local lowered = string.lower(message)
    for _, pattern in ipairs(SAB_DEMOTED_ERROR_IGNORE_PATTERNS) do
        if string.find(lowered, pattern, 1, true) then
            return
        end
    end

    local now = os.clock()
    local state = sabDemotedErrorState[message]
    if not state then
        state = {
            count = 0,
            lastWarnAt = 0,
        }
        sabDemotedErrorState[message] = state
    end
    state.count = state.count + 1

    local sinceLastWarn = now - (state.lastWarnAt or 0)
    if state.lastWarnAt ~= 0 and sinceLastWarn < SAB_ERROR_DEMOTE_COOLDOWN then
        return
    end

    local repeats = math.max(0, state.count - 1)
    if repeats > 0 then
        --warn(string.format("[SAB] demoted error (%d repeats):", repeats), message)
    else
        --warn("[SAB] demoted error:", message)
    end
    if type(trace) == "string" and trace ~= "" then
        --warn(trace)
    end

    state.lastWarnAt = now
    state.count = 0
end

--[[ this is bs
pcall(function()
    if type(hookfunction) ~= "function" or type(newcclosure) ~= "function" then
        return
    end

    local sabOldError
    sabOldError = hookfunction(error, newcclosure(function(message, level)
        if not SAB_ERROR_DEMOTE_ENABLED then
            return sabOldError(message, level)
        end
        local fromCaller = type(checkcaller) == "function" and checkcaller()
        if fromCaller then
            local trace = ""
            if debug and type(debug.traceback) == "function" then
                trace = tostring(debug.traceback(nil, 2))
            end
            sabWarnDemotedError(message, trace)
            return nil
        end

        return sabOldError(message, level)
    end))
end)
]]

local function f()
    for _, s in pairs(game:GetChildren()) do
        if not (s.Name == "ReplicatedStorage" or s.Name == "Workspace" or s.Name == "Players") then
            for _, d in pairs(s:GetDescendants()) do
                if d:IsA("RemoteEvent") or d:IsA("UnreliableRemoteEvent") then
                    for _, c in pairs(getconnections(d.OnClientEvent)) do
                        if c.Function and debug.info(c.Function, "s"):find("ReplicatedFirst") then
                            return d
                        end
                    end
                end
            end
        end
    end
end

n = f()
if n then r = n:GetFullName() end

local oldInfo
oldInfo = hookfunction(debug.info, newcclosure(function(func, ...)
    local s, l, name = oldInfo(func, ...)
    if name == "FireServer" and s == "[C]" then
        return "=[C]", -1, "FireServer"
    end
    return s, l, name
end))

o = hookfunction(Instance.new("RemoteEvent").FireServer, newcclosure(function(self, ...)
    if not checkcaller() and type(sabSilentAimRewriteRemoteArgs) == "function" then
        local rewritten = sabSilentAimRewriteRemoteArgs(self, { ... }, "FireServer")
        if type(rewritten) == "table" then
            return o(self, sabSilentAimUnpack(rewritten))
        end
    end
    return o(self, ...)
end))

pcall(function()
    oInvoke = hookfunction(Instance.new("RemoteFunction").InvokeServer, newcclosure(function(self, ...)
        if not checkcaller() and type(sabSilentAimRewriteRemoteArgs) == "function" then
            local rewritten = sabSilentAimRewriteRemoteArgs(self, { ... }, "InvokeServer")
            if type(rewritten) == "table" then
                return oInvoke(self, sabSilentAimUnpack(rewritten))
            end
        end
        return oInvoke(self, ...)
    end))
end)

pcall(function()
    local unreliableRemote = Instance.new("UnreliableRemoteEvent")
    oUnreliable = hookfunction(unreliableRemote.FireServer, newcclosure(function(self, ...)
        if not checkcaller() and type(sabSilentAimRewriteRemoteArgs) == "function" then
            local rewritten = sabSilentAimRewriteRemoteArgs(self, { ... }, "FireServer")
            if type(rewritten) == "table" then
                return oUnreliable(self, sabSilentAimUnpack(rewritten))
            end
        end
        return oUnreliable(self, ...)
    end))
    unreliableRemote:Destroy()
end)

local p; p = hookfunction(game.GetFullName, newcclosure(function(s)
    if not checkcaller() and s == n then
        return r
    end
    return p(s)
end))

-- ==================================================
-- PANEL SDK — Real-time presence tracking (WebSocket)
-- ==================================================
-- Outside panel SDK disabled: PVH owns analytics only.
local lp = game:GetService("Players").LocalPlayer

local function getHiddenUiParent()
    local ok, ui = pcall(function()
        if typeof(gethui) == "function" then return gethui() end
        if typeof(get_hidden_gui) == "function" then return get_hidden_gui() end
        if typeof(gethiddenui) == "function" then return gethiddenui() end
    end)
    if ok and typeof(ui) == "Instance" then
        return ui
    end
    return game:GetService("CoreGui")
end

local hiddenUiParent = getHiddenUiParent()

-- ==================================================
-- UI LIBRARY (Fatality)
-- ==================================================
local __pvbrCreateUI=loadstring(game:HttpGet("https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/refs/heads/feature/steal-brainrot-port-20261110/PVH_BrainrotUI.lua"))()
local Library,Window=__pvbrCreateUI()

-- ==================================================
-- PAGE 1: RAGE
-- ==================================================
local RageMenu = Window:AddMenu({ Name = "RAGE", Columns = 2 })

local PlayerSection = RageMenu:AddSection({ Name = "PLAYER", Column = 1 })
local FishingSection = RageMenu:AddSection({ Name = "FISHING", Column = 1 })
local SilentAimSection = RageMenu:AddSection({ Name = "SILENT AIM", Column = 1 })
local CombatSection = RageMenu:AddSection({ Name = "COMBAT", Column = 2 })

-- ==================================================
-- PLAYER MODULE
-- ==================================================
local CollectionService = game:GetService("CollectionService")
local UIS = game:GetService("UserInputService")

local PlayerConfig = {
    AutoFish = false,
    SpeedBoost = false,
    SpeedValue = 30,
    DefaultWalkSpeed = 16,
}

local AutoFishConnection
local SpeedBoostConnection
local isFishingActionDelay = false

local function findRod()
    local c = lp.Character
    if not c then return nil end
    local bp = lp:FindFirstChildOfClass("Backpack")
    local function checkRod(item)
        return item:IsA("Tool") and item.Name:match("Rod")
    end
    for _, ch in ipairs(c:GetChildren()) do
        if checkRod(ch) then return ch end
    end
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if checkRod(ch) then return ch end
        end
    end
    return nil
end

local function getMyBobber()
    local char = lp.Character
    if not char then return nil end
    for _, obj in ipairs(CollectionService:GetTagged("FishingBobber")) do
        local rope = obj:FindFirstChildOfClass("RopeConstraint")
        if rope then
            if (rope.Attachment0 and rope.Attachment0:IsDescendantOf(char)) or
               (rope.Attachment1 and rope.Attachment1:IsDescendantOf(char)) then
                return obj
            end
        end
        local owner = obj:GetAttribute("Owner")
        if owner == lp.UserId or owner == lp.Name then
            return obj
        end
    end
    return nil
end

local function startAutoFish()
    if AutoFishConnection then return end
    AutoFishConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not PlayerConfig.AutoFish then return end
        if isFishingActionDelay then return end

        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hum then return end

        local rod = findRod()
        if not rod then return end

        if rod.Parent ~= char then
            hum:EquipTool(rod)
            return
        end

        local bobber = getMyBobber()
        if not bobber then
            -- Need to cast
            isFishingActionDelay = true
            rod:Activate()
            task.delay(1.5, function() isFishingActionDelay = false end)
        else
            -- We have a bobber, wait for bite
            if bobber:GetAttribute("bite") == true then
                isFishingActionDelay = true
                rod:Activate()
                -- Delay to let it reel in and catch
                task.delay(2.0, function() isFishingActionDelay = false end)
            end
        end
    end)
end

local function stopAutoFish()
    if AutoFishConnection then
        AutoFishConnection:Disconnect()
        AutoFishConnection = nil
    end
end

local function applyPlayerSpeedBoost(speedValue)
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum then
        return false
    end
    if UIS.TouchEnabled and not UIS.KeyboardEnabled then
        hum.WalkSpeed = math.max(PlayerConfig.DefaultWalkSpeed, speedValue)
        return true
    end
    if not hrp then
        return false
    end
    if hum.MoveDirection.Magnitude <= 0.1 then
        return false
    end
    local moveDir = hum.MoveDirection.Unit
    hrp.AssemblyLinearVelocity = Vector3.new(
        moveDir.X * speedValue,
        hrp.AssemblyLinearVelocity.Y,
        moveDir.Z * speedValue
    )
    return true
end

local function startPlayerSpeedBoost()
    if SpeedBoostConnection then return end
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.WalkSpeed > 0 then
        PlayerConfig.DefaultWalkSpeed = hum.WalkSpeed
    end
    SpeedBoostConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not PlayerConfig.SpeedBoost then return end
        applyPlayerSpeedBoost(PlayerConfig.SpeedValue)
    end)
end

local function stopPlayerSpeedBoost()
    if SpeedBoostConnection then
        SpeedBoostConnection:Disconnect()
        SpeedBoostConnection = nil
    end
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = PlayerConfig.DefaultWalkSpeed
    end
end

PlayerSection:AddSliderToggle({
    Name = "Speed",
    SaveKey = "sab_player_speed_control",
    DefaultToggle = false,
    Min = 30,
    Max = 60,
    Default = 30,
    Suffix = "",
    OnToggleChange = function(state)
        PlayerConfig.SpeedBoost = state and true or false
        if state then startPlayerSpeedBoost() else stopPlayerSpeedBoost() end
    end,
    OnSliderChange = function(value)
        PlayerConfig.SpeedValue = math.clamp(math.floor(tonumber(value) or 30), 30, 60)
    end,
})

FishingSection:AddToggle({
    Name = "AFK Auto-Fishing",
    SaveKey = "sab_auto_fish",
    Default = false,
    Callback = function(state)
        PlayerConfig.AutoFish = state and true or false
        if state then startAutoFish() else stopAutoFish() end
    end,
})

lp.CharacterAdded:Connect(function()
    task.wait(0.5)
    if PlayerConfig.SpeedBoost then startPlayerSpeedBoost() end
    if PlayerConfig.AutoFish then startAutoFish() end
end)

-- ==================================================
-- COMBAT MODULE
-- ==================================================
local CombatConfig = {
    HitCircle = false,
}

local Cebo = { Conn=nil, Circle=nil }

local SlapList = {
    {1,"Bat"},{2,"Slap"},{3,"Iron Slap"},{4,"Gold Slap"},
    {5,"Diamond Slap"},{6,"Emerald Slap"},{7,"Ruby Slap"},
    {8,"Dark Matter Slap"},{9,"Flame Slap"},{10,"Nuclear Slap"},
    {11,"Galaxy Slap"},{12,"Glitched Slap"}
}

local function findBat()
    local c = lp.Character
    if not c then return nil end
    local bp = lp:FindFirstChildOfClass("Backpack")
    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
    end
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
        end
    end
    for _, i in ipairs(SlapList) do
        local t = c:FindFirstChild(i[2]) or (bp and bp:FindFirstChild(i[2]))
        if t then return t end
    end
    return nil
end

local function startHitCircle()
    if Cebo.Conn then return end
    local char = lp.Character or lp.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    -- Outline Circle using CylinderHandleAdornment safely parented to CoreGui
    Cebo.Circle = Instance.new("CylinderHandleAdornment")
    Cebo.Circle.Name = "HitCircleAura"
    Cebo.Circle.Radius = 7.25
    Cebo.Circle.InnerRadius = 7.15
    Cebo.Circle.Height = 0.05
    Cebo.Circle.Color3 = Color3.fromRGB(160, 60, 255)
    Cebo.Circle.Transparency = 0.1
    Cebo.Circle.ZIndex = 0
    Cebo.Circle.AlwaysOnTop = false
    Cebo.Circle.Adornee = hrp
    Cebo.Circle.CFrame = CFrame.new(0, -hrp.Size.Y/2 - 0.9, 0) * CFrame.Angles(math.rad(90), 0, 0)
    
    local coreGui = game:GetService("CoreGui")
    if coreGui then
        Cebo.Circle.Parent = coreGui
    else
        Cebo.Circle.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end

    Cebo.Conn = game:GetService("RunService").RenderStepped:Connect(function()
        if not CombatConfig.HitCircle then return end
        local currentTarget, dmin = nil, 7.25
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Parent == workspace then
                local eHRP = p.Character.HumanoidRootPart
                local d = (eHRP.Position - hrp.Position).Magnitude
                if d <= dmin then currentTarget, dmin = eHRP, d end
            end
        end
        if currentTarget and char:FindFirstChild("Humanoid") then
            local bat = findBat()
            if bat then
                if bat.Parent ~= char then bat.Parent = char end
                local now = tick()
                
                -- TIMING JITTER: Instead of purely static 0.12, add math.random noise from 0.00 to 0.05
                local dynamicDelay = 0.12 + (math.random() * 0.05)
                
                if now - (CombatConfig.lastBatSwing or 0) >= dynamicDelay then
                    CombatConfig.lastBatSwing = now
                    local s, e = pcall(function() bat:Activate() end)
                    if not s then --[[warn("[SAB] Bat auto-equip error:", e)]] end
                end
            end
        end
    end)
end

local function stopHitCircle()
    if Cebo.Conn   then Cebo.Conn:Disconnect()   Cebo.Conn   = nil end
    if Cebo.Circle then Cebo.Circle:Destroy()    Cebo.Circle = nil end
end

CombatSection:AddToggle({
    Name = "Hit Circle (Aura)",
    SaveKey = "sab_hit_circle",
    Default = false,
    Callback = function(state)
        CombatConfig.HitCircle = state
        if state then startHitCircle() else stopHitCircle() end
    end,
})

lp.CharacterAdded:Connect(function()
    task.wait(0.5)
    if CombatConfig.HitCircle then
        startHitCircle()
    end
end)

-- ==================================================
-- PAGE 2: STEALER
-- ==================================================
local StealerMenu = Window:AddMenu({ Name = "STEALER", Columns = 2 })

local StealerSection = StealerMenu:AddSection({ Name = "STEALER", Column = 1 })
local CombatStealerSection = StealerMenu:AddSection({ Name = "COMBAT STEALER", Column = 2 })
local DuelHelperSection = StealerMenu:AddSection({ Name = "DUEL HELPER", Column = 2 })

-- ==================================================
-- AUTOGRAB MODULE
-- ==================================================
local RunService = game:GetService("RunService")
local PlotController
local AnimalsData
local AnimalsShared
local MutationsData
local getMoneyPerSec

local StealerConfig = {
    AutoGrabEnabled = false,
    AutoGrabRadius = 25,
    AutoGrabPriority = "Highest M/S",
    AntiRagdoll = false,
}

local AutoGrabConnection = nil
local AutoGrabScanThread = nil
local CachedGrabbables = {}
local CHUNK_SIZE = 200
local AGX = {
    nearestSlotMaxDist = 14,
    compatScanInterval = 2,
}

function AGX.cleanupDebugVisuals()
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("BillboardGui") and inst.Name == "AutoGrabDebugBB" then
            pcall(function()
                inst:Destroy()
            end)
        end
    end
end

function AGX.ensureHiddenTextLabel(parent, name)
    if typeof(parent) ~= "Instance" then
        return
    end
    local existing = parent:FindFirstChild(name)
    if existing and existing:IsA("TextLabel") then
        return
    end
    if existing then
        pcall(function()
            existing:Destroy()
        end)
    end

    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = UDim2.fromOffset(0, 0)
    label.BackgroundTransparency = 1
    label.TextTransparency = 1
    label.TextStrokeTransparency = 1
    label.Text = ""
    label.Visible = false
    label.Parent = parent
end

function AGX.ensurePlotModelCompat(plotModel)
    if typeof(plotModel) ~= "Instance" or not plotModel:IsA("Model") then
        return
    end

    local unlock = plotModel:FindFirstChild("Unlock")
    if not unlock then
        local boolVal = Instance.new("BoolValue")
        boolVal.Name = "Unlock"
        boolVal.Value = false
        boolVal.Parent = plotModel
    end

    local purchases = plotModel:FindFirstChild("Purchases")
    if not purchases then
        return
    end

    for _, inst in ipairs(purchases:GetDescendants()) do
        if inst:IsA("BillboardGui") then
            AGX.ensureHiddenTextLabel(inst, "Locked")
            AGX.ensureHiddenTextLabel(inst, "RemainingTime")
        end
    end
end

function AGX.runPlotClientCompatPass()
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then
        return
    end
    for _, plotModel in ipairs(plotsFolder:GetChildren()) do
        AGX.ensurePlotModelCompat(plotModel)
    end
end

do
    local nextCompatScanAt = 0
    RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now >= nextCompatScanAt then
            nextCompatScanAt = now + AGX.compatScanInterval
            pcall(AGX.runPlotClientCompatPass)
        end
    end)
    pcall(AGX.runPlotClientCompatPass)
end

function AGX.isPurchasePrompt(promptInstance, promptPart, promptModel, plotModel)
    if typeof(plotModel) ~= "Instance" then
        return false
    end
    local purchases = plotModel:FindFirstChild("Purchases")
    if not purchases then
        return false
    end
    if typeof(promptModel) == "Instance" and promptModel:IsDescendantOf(purchases) then
        return true
    end
    if typeof(promptPart) == "Instance" and promptPart:IsDescendantOf(purchases) then
        return true
    end
    if typeof(promptInstance) == "Instance" and promptInstance:IsDescendantOf(purchases) then
        return true
    end
    return false
end

function AGX.resolvePromptPlotModel(basePart, plotsFolder)
    if typeof(basePart) ~= "Instance" or not plotsFolder then
        return nil
    end
    local ancestor = basePart
    while ancestor and ancestor ~= workspace do
        if ancestor.Parent == plotsFolder then
            return ancestor
        end
        ancestor = ancestor.Parent
    end
    return nil
end

function AGX.buildPlotValueCache()
    local cacheByPlotModel = {}
    if not PlotController or type(PlotController.GetPlots) ~= "function" then
        return cacheByPlotModel
    end

    local okPlots, plots = pcall(PlotController.GetPlots, PlotController)
    if not okPlots or type(plots) ~= "table" then
        return cacheByPlotModel
    end

    for _, plot in pairs(plots) do
        if type(plot) == "table" then
            local plotModel = rawget(plot, "PlotModel")
            local channel = rawget(plot, "Channel")
            local podiums = typeof(plotModel) == "Instance" and plotModel:FindFirstChild("AnimalPodiums") or nil
            if podiums and channel and type(channel.Get) == "function" then
                local okList, animalList = pcall(channel.Get, channel, "AnimalList")
                if okList and type(animalList) == "table" then
                    local plotData = {
                        slotValues = {},
                        nodes = {},
                        podiums = podiums,
                    }
                    for slot, entry in pairs(animalList) do
                        local slotKey = tostring(slot)
                        local value = 0
                        if type(entry) == "table" and type(getMoneyPerSec) == "function" then
                            value = math.max(0, tonumber(getMoneyPerSec(entry)) or 0)
                        end
                        plotData.slotValues[slotKey] = value

                        local podium = podiums:FindFirstChild(slotKey)
                        local base = podium and podium:FindFirstChild("Base")
                        local spawnPart = base and base:FindFirstChild("Spawn")
                        if spawnPart and spawnPart:IsA("BasePart") then
                            plotData.nodes[#plotData.nodes + 1] = {
                                slot = slotKey,
                                value = value,
                                spawnPart = spawnPart,
                            }
                        end
                    end
                    cacheByPlotModel[plotModel] = plotData
                end
            end
        end
    end

    return cacheByPlotModel
end

function AGX.hasForbiddenPromptAncestor(instance)
    local ancestor = instance
    while ancestor and ancestor ~= workspace do
        local name = string.lower(tostring(ancestor.Name or ""))
        if name == "purchases" or name == "plotblock" then
            return true
        end
        ancestor = ancestor.Parent
    end
    return false
end

function AGX.resolvePromptPriorityValue(prompt, promptPart, promptModel, plotModel, plotValueCache)
    if AGX.isPurchasePrompt(prompt, promptPart, promptModel, plotModel) then
        return 0, "purchase", nil
    end
    if AGX.hasForbiddenPromptAncestor(prompt) or AGX.hasForbiddenPromptAncestor(promptPart) or AGX.hasForbiddenPromptAncestor(promptModel) then
        return 0, "purchase", nil
    end

    local priorityValue = 0
    local source = "fallback"
    local slotName = nil

    local plotData = plotModel and plotValueCache and plotValueCache[plotModel]
    if plotData then
        if promptModel and plotData.podiums then
            local ancestor = promptModel
            while ancestor and ancestor ~= plotModel do
                if ancestor.Parent == plotData.podiums then
                    local resolvedSlot = tostring(ancestor.Name)
                    local slotValue = plotData.slotValues[resolvedSlot]
                    if type(slotValue) == "number" and slotValue > 0 then
                        priorityValue = slotValue
                        source = "channel-slot"
                        slotName = resolvedSlot
                    end
                    break
                end
                ancestor = ancestor.Parent
            end
        end

        if priorityValue <= 0 and promptPart then
            local nearestDist = math.huge
            local nearestNode = nil
            for _, node in ipairs(plotData.nodes) do
                local spawnPart = node.spawnPart
                if spawnPart and spawnPart.Parent then
                    local dist = (spawnPart.Position - promptPart.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearestNode = node
                    end
                end
            end
            if nearestNode and nearestDist <= AGX.nearestSlotMaxDist then
                local nearestValue = math.max(0, tonumber(nearestNode.value) or 0)
                if nearestValue > 0 then
                    priorityValue = nearestValue
                    source = "channel-nearest"
                    slotName = nearestNode.slot
                end
            end
        end
    end

    if priorityValue <= 0 and promptModel then
        local nameCheck = promptModel.Name
        if nameCheck:sub(1, 9) == "Purchased" then
            nameCheck = nameCheck:sub(10)
        end
        if type(AnimalsData) == "table" and type(getMoneyPerSec) == "function" then
            local animalInfo = AnimalsData[nameCheck]
            if animalInfo then
                priorityValue = math.max(0, tonumber(getMoneyPerSec(animalInfo)) or 0)
                if priorityValue > 0 then
                    source = "animals-data"
                end
            end
        end
    end

    if priorityValue <= 0 then
        for _, inst in ipairs({ prompt, promptPart, promptModel }) do
            if typeof(inst) == "Instance" then
                for _, key in ipairs({ "MoneyPerSec", "Generation", "Value", "Price" }) do
                    local attrValue = inst:GetAttribute(key)
                    if type(attrValue) == "number" and attrValue > priorityValue then
                        priorityValue = attrValue
                        source = "attributes"
                    end
                    local childValue = inst:FindFirstChild(key)
                    if childValue and childValue:IsA("NumberValue") and childValue.Value > priorityValue then
                        priorityValue = childValue.Value
                        source = "numbervalue"
                    end
                end
            end
        end
    end

    return math.max(0, tonumber(priorityValue) or 0), source, slotName
end

local function ScanGrabbables()
    local allDesc = workspace:GetDescendants()
    local results = {}
    local plotsFolder = workspace:FindFirstChild("Plots")
    local plotValueCache = AGX.buildPlotValueCache()
    for i = 1, #allDesc do
        local desc = allDesc[i]
        if desc:IsA("ProximityPrompt") then
            local act = desc.ActionText and desc.ActionText:lower() or ""
            local state = desc:GetAttribute("State")
            local isStealPrompt = act:find("steal", 1, true) ~= nil or state == "Steal"

            if isStealPrompt then
                local part = desc.Parent
                if part then
                    if part:IsA("BasePart") then
                        local plotModel = AGX.resolvePromptPlotModel(part, plotsFolder)
                        local model = desc:FindFirstAncestorWhichIsA("Model")
                        local priorityValue, valueSource, slotName = AGX.resolvePromptPriorityValue(desc, part, model, plotModel, plotValueCache)
                        local shouldInclude = priorityValue > 0
                            and (valueSource == "channel-slot" or valueSource == "channel-nearest" or valueSource == "animals-data")
                        if shouldInclude then
                            results[#results + 1] = {
                                prompt = desc,
                                part = part,
                                plotModel = plotModel,
                                priorityValue = priorityValue,
                                valueSource = valueSource,
                                slotName = slotName,
                            }
                        end
                    elseif part:IsA("Attachment") and part.Parent and part.Parent:IsA("BasePart") then
                        local basePart = part.Parent
                        local plotModel = AGX.resolvePromptPlotModel(basePart, plotsFolder)
                        local model = desc:FindFirstAncestorWhichIsA("Model")
                        local priorityValue, valueSource, slotName = AGX.resolvePromptPriorityValue(desc, basePart, model, plotModel, plotValueCache)
                        local shouldInclude = priorityValue > 0
                            and (valueSource == "channel-slot" or valueSource == "channel-nearest" or valueSource == "animals-data")
                        if shouldInclude then
                            results[#results + 1] = {
                                prompt = desc,
                                part = basePart,
                                plotModel = plotModel,
                                priorityValue = priorityValue,
                                valueSource = valueSource,
                                slotName = slotName,
                            }
                        end
                    end
                end
            end
        end
        if i % CHUNK_SIZE == 0 then task.wait() end
    end
    CachedGrabbables = results
end

AGX.cleanupDebugVisuals()

local function StartAutoGrabScan()
    if AutoGrabScanThread then return end
    AutoGrabScanThread = task.spawn(function()
        while StealerConfig.AutoGrabEnabled do 
            local s, e = pcall(ScanGrabbables) 
            if not s then --[[warn("[SAB] ScanGrabbables error:", e)]] end
            task.wait(0.8) 
        end
        AutoGrabScanThread = nil
    end)
end

local function StartAutoGrab()
    if AutoGrabConnection then AutoGrabConnection:Disconnect() end
    AGX.cleanupDebugVisuals()
    StartAutoGrabScan()
    local grabCooldown = 0
    local function resolveTargetPlotModel(rootPosition)
        local plotsFolder = workspace:FindFirstChild("Plots")
        if not plotsFolder then
            return nil
        end
        local insidePlot = nil
        local insideDistance = math.huge
        local nearestPlot = nil
        local nearestDistance = math.huge
        for _, plotModel in ipairs(plotsFolder:GetChildren()) do
            if plotModel:IsA("Model") then
                local anchorPart = plotModel:FindFirstChild("Spawn") or plotModel:FindFirstChildWhichIsA("BasePart", true)
                local anchorPos = anchorPart and anchorPart.Position or nil
                local okBounds, boundsCf, boundsSize = pcall(plotModel.GetBoundingBox, plotModel)
                if okBounds and boundsCf and boundsSize then
                    anchorPos = boundsCf.Position
                    local localPos = boundsCf:PointToObjectSpace(rootPosition)
                    local isInside = math.abs(localPos.X) <= (boundsSize.X * 0.5)
                        and math.abs(localPos.Y) <= (boundsSize.Y * 0.5)
                        and math.abs(localPos.Z) <= (boundsSize.Z * 0.5)
                    local dist = (anchorPos - rootPosition).Magnitude
                    if isInside and dist < insideDistance then
                        insidePlot = plotModel
                        insideDistance = dist
                    end
                    if dist < nearestDistance then
                        nearestPlot = plotModel
                        nearestDistance = dist
                    end
                elseif anchorPos then
                    local dist = (anchorPos - rootPosition).Magnitude
                    if dist < nearestDistance then
                        nearestPlot = plotModel
                        nearestDistance = dist
                    end
                end
            end
        end
        return insidePlot or nearestPlot
    end
    AutoGrabConnection = RunService.Heartbeat:Connect(function()
        if not StealerConfig.AutoGrabEnabled then return end
        local char = lp.Character; local rootPart = char and char:FindFirstChild("HumanoidRootPart"); local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not rootPart or not humanoid then return end
        if tick() - grabCooldown < 0.3 then return end
        if char:FindFirstChildOfClass("Tool") then return end
        local radius = StealerConfig.AutoGrabRadius
        local myPos = rootPart.Position
        local targetPlotModel = resolveTargetPlotModel(myPos)
        local bestDist = radius + 1
        local bestValue = -1
        local bestItem = nil
        for _, item in ipairs(CachedGrabbables) do
            if item.part and item.part.Parent and (not targetPlotModel or item.plotModel == targetPlotModel) then
                local ok, dist = pcall(function() return (item.part.Position - myPos).Magnitude end)
                if ok and dist and dist <= radius then
                    if item.prompt and item.prompt.Parent and item.prompt.Enabled then
                        local itemValue = math.max(0, tonumber(item.priorityValue) or 0)
                        if StealerConfig.AutoGrabPriority == "Highest M/S" then
                            if itemValue > bestValue or (itemValue == bestValue and dist < bestDist) then
                                bestValue = itemValue
                                bestDist = dist
                                bestItem = item
                            end
                        else
                            if dist < bestDist or (math.abs(dist - bestDist) <= 0.05 and itemValue > bestValue) then
                                bestValue = itemValue
                                bestDist = dist
                                bestItem = item
                            end
                        end
                    end
                end
            end
        end
        if bestItem then
            grabCooldown = tick()
            pcall(function()
                if fireproximityprompt then
                    fireproximityprompt(bestItem.prompt)
                else
                    bestItem.prompt:InputHoldBegin()
                    task.delay(bestItem.prompt.HoldDuration + 0.05, function()
                        if bestItem.prompt and bestItem.prompt.Parent then bestItem.prompt:InputHoldEnd() end
                    end)
                end
            end)
        end
    end)
end

local function StopAutoGrab()
    if AutoGrabConnection then AutoGrabConnection:Disconnect(); AutoGrabConnection = nil end
    CachedGrabbables = {}
    AGX.cleanupDebugVisuals()
end
-- ==================================================
-- STEAL PATHS (DUEL HELPER)
-- ==================================================
local stealPathActive = false
local stealLastFlatVel = Vector3.zero
local STEAL_PATH_VELOCITY_SPEED  = 59.2
local STEAL_PATH_SECOND_SPEED    = 29.6
local STEAL_PATH_BASE_STOP       = 1.35
local STEAL_PATH_MIN_STOP        = 0.65
local STEAL_PATH_NEXT_POINT_BIAS = 0.45
local STEAL_PATH_SMOOTH_FACTOR   = 0.12

local stealPath_Right = {
    {pos = Vector3.new(-470.6, -5.9,  34.4)},
    {pos = Vector3.new(-484.2, -3.9,  21.4)},
    {pos = Vector3.new(-475.6, -5.8,  29.3)},
    {pos = Vector3.new(-473.4, -5.9, 111.0)}
}
local stealPath_Left = {
    {pos = Vector3.new(-474.7, -5.9,  91.0)},
    {pos = Vector3.new(-483.4, -3.9,  97.3)},
    {pos = Vector3.new(-474.7, -5.9,  91.0)},
    {pos = Vector3.new(-476.1, -5.5,  25.4)}
}
local function stealMoveToPoint(hrp, current, nextPoint, speed)
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not stealPathActive then conn:Disconnect() hrp.AssemblyLinearVelocity = Vector3.zero return end
        local pos = hrp.Position
        local target = Vector3.new(current.X, pos.Y, current.Z)
        local dir = target - pos
        local dist = dir.Magnitude
        local stopDist = math.clamp(STEAL_PATH_BASE_STOP - dist * 0.04, STEAL_PATH_MIN_STOP, STEAL_PATH_BASE_STOP)
        if dist <= stopDist then conn:Disconnect() hrp.AssemblyLinearVelocity = Vector3.zero return end
        local moveDir = dir.Unit
        if nextPoint then
            local nextDir = (Vector3.new(nextPoint.X, pos.Y, nextPoint.Z) - pos).Unit
            moveDir = (moveDir + nextDir * STEAL_PATH_NEXT_POINT_BIAS).Unit
        end
        if stealLastFlatVel.Magnitude > 0.1 then
            moveDir = (moveDir * (1 - STEAL_PATH_SMOOTH_FACTOR) + stealLastFlatVel.Unit * STEAL_PATH_SMOOTH_FACTOR).Unit
        end
        local vel = Vector3.new(moveDir.X * speed, hrp.AssemblyLinearVelocity.Y, moveDir.Z * speed)
        hrp.AssemblyLinearVelocity = vel
        stealLastFlatVel = Vector3.new(vel.X, 0, vel.Z)
    end)
    while stealPathActive and
        (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(current.X, 0, current.Z)).Magnitude > STEAL_PATH_BASE_STOP do
        RunService.Heartbeat:Wait()
    end
end
local function stealRunPath(path)
    local hrp = (lp.Character or lp.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
    for i, p in ipairs(path) do
        if not stealPathActive then return end
        local speed = i > 2 and STEAL_PATH_SECOND_SPEED or STEAL_PATH_VELOCITY_SPEED
        local nextP = path[i + 1] and path[i + 1].pos
        stealMoveToPoint(hrp, p.pos, nextP, speed)
        if i == 2 then task.wait(0.2) else task.wait(0.01) end
    end
end
local function startStealPath(path)
    stealPathActive = true
    task.spawn(function()
        while stealPathActive do stealRunPath(path) task.wait(0.1) end
    end)
end
local function stopStealPath()
    stealPathActive = false
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
end

local AntiRagdoll = {
    enabled = false,
    conns = {},
    cached = {},
    isBoosting = false,
    boostWalkSpeed = 400,
    defaultWalkSpeed = 16,
}

function AntiRagdoll:cacheCharacterData()
    local char = lp.Character
    if not char then
        return false
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then
        return false
    end
    self.cached = {
        character = char,
        humanoid = hum,
        root = root,
    }
    if type(hum.WalkSpeed) == "number" and hum.WalkSpeed > 0 then
        self.defaultWalkSpeed = hum.WalkSpeed
    end
    return true
end

function AntiRagdoll:disconnectAll()
    for _, conn in ipairs(self.conns) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    table.clear(self.conns)
end

function AntiRagdoll:isRagdolled()
    local hum = self.cached.humanoid
    if not hum then
        return false
    end
    local state = hum:GetState()
    if state == Enum.HumanoidStateType.Physics
        or state == Enum.HumanoidStateType.Ragdoll
        or state == Enum.HumanoidStateType.FallingDown then
        return true
    end
    local endTime = lp:GetAttribute("RagdollEndTime")
    if type(endTime) == "number" and (endTime - workspace:GetServerTimeNow()) > 0 then
        return true
    end
    return false
end

function AntiRagdoll:forceExitRagdoll()
    local cached = self.cached
    local char = cached.character
    local hum = cached.humanoid
    local root = cached.root
    if not char or not hum or not root then
        return
    end

    pcall(function()
        lp:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow())
    end)

    for _, inst in ipairs(char:GetDescendants()) do
        if inst:IsA("BallSocketConstraint")
            or (inst:IsA("Attachment") and string.find(inst.Name, "RagdollAttachment", 1, true)) then
            pcall(function()
                inst:Destroy()
            end)
        end
    end

    if not self.isBoosting then
        self.isBoosting = true
        if type(hum.WalkSpeed) == "number" and hum.WalkSpeed > 0 then
            self.defaultWalkSpeed = hum.WalkSpeed
        end
        hum.WalkSpeed = self.boostWalkSpeed
    end

    if hum.Health > 0 then
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end
    root.Anchored = false
end

function AntiRagdoll:onHeartbeat()
    if not self.enabled then
        return
    end
    local ragdolled = self:isRagdolled()
    if ragdolled then
        self:forceExitRagdoll()
    elseif self.isBoosting then
        self.isBoosting = false
        local hum = self.cached.humanoid
        if hum then
            hum.WalkSpeed = self.defaultWalkSpeed
        end
    end
end

function AntiRagdoll:start()
    if self.enabled then
        return
    end
    self.enabled = true
    self.isBoosting = false

    if not self:cacheCharacterData() then
        task.spawn(function()
            pcall(function()
                local _ = lp.Character or lp.CharacterAdded:Wait()
                task.wait(0.1)
                if self.enabled then
                    self:cacheCharacterData()
                end
            end)
        end)
    end

    table.insert(self.conns, RunService.Heartbeat:Connect(function()
        AntiRagdoll:onHeartbeat()
    end))

    table.insert(self.conns, RunService.RenderStepped:Connect(function()
        if not AntiRagdoll.enabled then
            return
        end
        local cam = workspace.CurrentCamera
        local hum = AntiRagdoll.cached.humanoid
        if cam and hum and hum.Parent then
            cam.CameraSubject = hum
        end
    end))

    table.insert(self.conns, lp.CharacterAdded:Connect(function()
        AntiRagdoll.isBoosting = false
        task.wait(0.5)
        if AntiRagdoll.enabled then
            AntiRagdoll:cacheCharacterData()
        end
    end))
end

function AntiRagdoll:stop()
    if self.isBoosting then
        local hum = self.cached.humanoid
        if hum then
            hum.WalkSpeed = self.defaultWalkSpeed
        end
    end
    self.isBoosting = false
    self.enabled = false
    self:disconnectAll()
    table.clear(self.cached)
end

StealerSection:AddToggle({
    Name = "Auto Grab",
    SaveKey = "sab_new_autograb",
    Default = false,
    Callback = function(state)
        StealerConfig.AutoGrabEnabled = state
        if state then StartAutoGrab() else StopAutoGrab() end
    end,
})

StealerSection:AddSlider({
    Name = "Auto Grab Radius",
    SaveKey = "sab_new_autograb_radius",
    Min = 5,
    Max = 60,
    Default = 25,
    Callback = function(value)
        StealerConfig.AutoGrabRadius = value
    end,
})

StealerSection:AddDropdown({
    Name = "Auto Grab Priority",
    SaveKey = "sab_new_autograb_priority",
    Options = { "Highest M/S", "Closest" },
    Default = "Highest M/S",
    Callback = function(value)
        StealerConfig.AutoGrabPriority = tostring(value or "Highest M/S")
    end,
})

StealerSection:AddToggle({
    Name = "Anti Ragdoll",
    SaveKey = "sab_stealer_anti_ragdoll",
    Default = false,
    Callback = function(state)
        StealerConfig.AntiRagdoll = state
        if state then
            AntiRagdoll:start()
        else
            AntiRagdoll:stop()
        end
    end,
})

DuelHelperSection:AddToggle({
    Name = "Auto Right Steal",
    SaveKey = "sab_duel_auto_right",
    Default = false,
    Callback = function(state)
        StealerConfig.AutoRight = state
        if state then
            StealerConfig.AutoLeft = false
            stopStealPath() 
            startStealPath(stealPath_Right)
        else 
            stopStealPath() 
        end
    end,
})

DuelHelperSection:AddToggle({
    Name = "Auto Left Steal",
    SaveKey = "sab_duel_auto_left",
    Default = false,
    Callback = function(state)
        StealerConfig.AutoLeft = state
        if state then
            StealerConfig.AutoRight = false
            stopStealPath() 
            startStealPath(stealPath_Left)
        else 
            stopStealPath() 
        end
    end,
})

-- Handle respawns
lp.CharacterAdded:Connect(function()
    task.wait(0.5)
    if StealerConfig.AutoGrabEnabled then StartAutoGrab() end
    if StealerConfig.AntiRagdoll then AntiRagdoll:start() end
end)

-- ==================================================
-- PAGE 3: VISUALS
-- ==================================================
local VisualsMenu = Window:AddMenu({ Name = "VISUALS", Columns = 2 })

local PlayerEspSection = VisualsMenu:AddSection({ Name = "PLAYER ESP", Column = 1 })
local BaseVisualsSection = VisualsMenu:AddSection({ Name = "BASE VISUALS", Column = 1 })
local BaseSpawnerSection = VisualsMenu:AddSection({ Name = "BASE BRAINROT SPAWNER", Column = 1 })
local BrainrotEspSection = VisualsMenu:AddSection({ Name = "BRAINROT ESP", Column = 2 })
local TrapsEspSection = VisualsMenu:AddSection({ Name = "TRAPS ESP", Column = 2 })
local RoadSpawnerSection = VisualsMenu:AddSection({ Name = "ROAD BRAINROT SPAWNER", Column = 2 })
local BaseEspSection = VisualsMenu:AddSection({ Name = "BASE ESP", Column = 2 })
local WorldVisualsSection = VisualsMenu:AddSection({ Name = "WORLD VISUALS", Column = 2 })

-- ==================================================
-- PAGE 4: SERVER
-- ==================================================
local ServerMenu = Window:AddMenu({ Name = "SERVER", Columns = 2 })

local AutoJoinerSection = ServerMenu:AddSection({ Name = "FINDER", Column = 1 })
local ServerExploitsSection = ServerMenu:AddSection({ Name = "SERVER EXPLOITS", Column = 2 })

local function addToggleColorPicker(section, toggle, cpOpts)
    if type(toggle) == "table" and type(toggle.AddColorPicker) == "function" then
        return toggle:AddColorPicker(cpOpts)
    end

    if type(section) ~= "table" or type(section.AddColorPicker) ~= "function" then
        return nil
    end

    local picker = section:AddColorPicker(cpOpts)
    if type(picker) ~= "table" then
        return picker
    end

    local toggleRow = rawget(toggle, "_root")
    local pickerRow = rawget(picker, "_root")
    if typeof(toggleRow) == "Instance" and typeof(pickerRow) == "Instance" then
        local colorBox = pickerRow:FindFirstChildWhichIsA("TextButton")
        local colorLabel = pickerRow:FindFirstChild("Label")
        local checkBox = toggleRow:FindFirstChild("Check")
        local toggleLabel = toggleRow:FindFirstChild("Label")

        if colorLabel and colorLabel:IsA("TextLabel") then
            colorLabel.Visible = false
        end

        if toggleLabel and toggleLabel:IsA("TextLabel") then
            toggleLabel.Size = UDim2.new(1, -44, 1, 0)
        end

        pickerRow.Size = UDim2.new(1, 0, 0, 0)
        pickerRow.Visible = false

        if colorBox and colorBox:IsA("TextButton") then
            colorBox.Parent = toggleRow
            colorBox.Name = "ColorBox"
            colorBox.ZIndex = 9
            if checkBox and checkBox:IsA("GuiObject") then
                colorBox.Position = UDim2.new(1, -22, 0.5, 0)
            else
                colorBox.Position = UDim2.new(1, 0, 0.5, 0)
            end
        end
    end

    return picker
end

-- ==================================================
-- PLAYER ESP MODULE (from GitHub)
-- ==================================================
local ESP
pcall(function()
    ESP=loadstring(game:HttpGet("https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/refs/heads/feature/steal-brainrot-port-20261110/PVH_BrainrotESP.lua"))()
    if ESP and type(ESP.Init)=="function" then ESP:Init() end
end)

local function safeESP(fn, s)
    if ESP then pcall(fn, ESP, s) end
end


-- ==================================================
-- BRAINROT ESP (local, no GitHub module load)
-- ==================================================
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local controllersFolder = ReplicatedStorage:WaitForChild("Controllers")
local datasFolder = ReplicatedStorage:WaitForChild("Datas")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")

local function safeRequire(moduleScript)
    local ok, result = pcall(require, moduleScript)
    if ok then
        return result
    end
    --warn("[SAB BrainrotESP] Failed to require", moduleScript and moduleScript:GetFullName() or "?", result)
    return nil
end

PlotController = safeRequire(controllersFolder:WaitForChild("PlotController"))
AnimalsData = safeRequire(datasFolder:WaitForChild("Animals"))
AnimalsShared = safeRequire(sharedFolder:WaitForChild("Animals"))
MutationsData = safeRequire(datasFolder:WaitForChild("Mutations"))

local NumberUtils
do
    local utilsFolder = ReplicatedStorage:FindFirstChild("Utils")
    if utilsFolder then
        local numUtilsMod = utilsFolder:FindFirstChild("NumberUtils")
        if numUtilsMod then
            NumberUtils = safeRequire(numUtilsMod)
        end
    end
end

local function trimAbbreviatedNumberText(text)
    if type(text) ~= "string" then
        return tostring(text or "")
    end

    local whole, decimal, suffix = string.match(text, "^(-?%d+)%.(%d+)([A-Za-z]+)$")
    if whole and decimal and suffix then
        decimal = string.gsub(decimal, "0+$", "")
        if decimal == "" then
            return whole .. suffix
        end
        return whole .. "." .. decimal .. suffix
    end

    return text
end

local BrainrotESP = {
    enabled = false,
    showName = false,
    showMoney = false,
    showHighlight = true,
    showTracers = false,
    currentBaseOnly = false,
    highlightColor = Color3.fromRGB(50, 180, 255),
    tracerColor = Color3.fromRGB(255, 255, 255),
    filterMode = "All", -- "All" | "Most Expensive Only"
    tracked = {},
    connection = nil,
    nextUpdateAt = 0,
    updateInterval = 0.2,
}

local function getBrainrotTracerStartAttachment()
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return nil
    end

    local attachment = hrp:FindFirstChild("SabBrainrotTracerAttachment")
    if attachment and attachment:IsA("Attachment") then
        return attachment
    end

    attachment = Instance.new("Attachment")
    attachment.Name = "SabBrainrotTracerAttachment"
    attachment.Parent = hrp
    return attachment
end

local function formatShort(value)
    local n = tonumber(value) or 0
    local absN = math.abs(n)
    local function formatScaled(divisor, suffix)
        local scaled = n / divisor
        local formatted = string.format("%.1f", scaled)
        formatted = string.gsub(formatted, "%.?0+$", "")
        return formatted .. suffix
    end

    if absN >= 1e12 then
        return formatScaled(1e12, "T")
    elseif absN >= 1e9 then
        return formatScaled(1e9, "B")
    elseif absN >= 1e6 then
        return formatScaled(1e6, "M")
    elseif absN >= 1e3 then
        return formatScaled(1e3, "K")
    end
    return tostring(math.floor(n + 0.5))
end

local function getDisplayName(index)
    if type(index) ~= "string" then
        return "Brainrot"
    end
    local entry = AnimalsData and AnimalsData[index]
    if type(entry) == "table" and type(entry.DisplayName) == "string" and entry.DisplayName ~= "" then
        return entry.DisplayName
    end
    return index
end

getMoneyPerSec = function(entry)
    if type(entry) ~= "table" then
        return 0
    end

    local idx = entry.Index
    if type(idx) ~= "string" then
        return 0
    end

    if type(entry.Generation) == "number" then
        return entry.Generation
    end
    if type(entry.MoneyPerSec) == "number" then
        return entry.MoneyPerSec
    end

    if AnimalsShared and type(AnimalsShared.GetGeneration) == "function" then
        local ok, value = pcall(AnimalsShared.GetGeneration, AnimalsShared, idx, entry.Mutation, entry.Traits, nil)
        if ok and type(value) == "number" then
            return value
        end
        local okAlt, altValue = pcall(AnimalsShared.GetGeneration, idx, entry.Mutation, entry.Traits, nil)
        if okAlt and type(altValue) == "number" then
            return altValue
        end
    end

    local data = AnimalsData and AnimalsData[idx]
    if type(data) == "table" and type(data.Generation) == "number" then
        return data.Generation
    end

    return 0
end

local function getOwner(plot)
    local ok, owner = pcall(function()
        return plot:GetOwner()
    end)
    if ok then
        return owner
    end
    return nil
end

local function isLocalOwner(owner)
    if owner == nil then
        return false
    end
    if owner == lp then
        return true
    end
    if typeof(owner) == "Instance" and owner:IsA("Player") then
        return owner == lp
    end
    if type(owner) == "table" then
        if owner.UserId and lp.UserId and owner.UserId == lp.UserId then
            return true
        end
        if owner.Name and type(owner.Name) == "string" and owner.Name:lower() == lp.Name:lower() then
            return true
        end
    end
    if type(owner) == "string" then
        return owner:lower() == lp.Name:lower()
    end
    if type(owner) == "number" and lp.UserId then
        return owner == lp.UserId
    end
    return false
end

local function resolveHighlightAdornee(plot, slot, spawnPart)
    if type(plot) == "table" and type(plot.AnimalsModels) == "table" then
        local model = plot.AnimalsModels[slot] or plot.AnimalsModels[tonumber(slot)]
        if typeof(model) == "Instance" and model.Parent then
            return model
        end
    end
    return spawnPart
end

local function createVisual()
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BrainrotESPBillboard"
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 3000
    billboard.Size = UDim2.fromOffset(220, 54)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
    billboard.Parent = hiddenUiParent

    local root = Instance.new("Frame")
    root.Name = "Root"
    root.BackgroundTransparency = 1
    root.Size = UDim2.fromScale(1, 1)
    root.Parent = billboard

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
    nameLabel.Position = UDim2.fromScale(0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = false
    nameLabel.TextSize = 15
    nameLabel.TextWrapped = true
    nameLabel.TextYAlignment = Enum.TextYAlignment.Bottom
    nameLabel.TextColor3 = Color3.fromRGB(255, 235, 150)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(10, 10, 10)
    nameLabel.Parent = root

    local moneyLabel = Instance.new("TextLabel")
    moneyLabel.Name = "Money"
    moneyLabel.BackgroundTransparency = 1
    moneyLabel.Size = UDim2.new(1, 0, 0.45, 0)
    moneyLabel.Position = UDim2.fromScale(0, 0.55)
    moneyLabel.Font = Enum.Font.GothamSemibold
    moneyLabel.TextScaled = false
    moneyLabel.TextSize = 14
    moneyLabel.TextWrapped = true
    moneyLabel.TextYAlignment = Enum.TextYAlignment.Top
    moneyLabel.TextColor3 = Color3.fromRGB(135, 255, 145)
    moneyLabel.TextStrokeTransparency = 0
    moneyLabel.TextStrokeColor3 = Color3.fromRGB(10, 10, 10)
    moneyLabel.Parent = root

    local highlight = Instance.new("Highlight")
    highlight.Name = "BrainrotESPHighlight"
    highlight.FillColor = BrainrotESP.highlightColor
    highlight.FillTransparency = 0.72
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.22
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    highlight.Parent = hiddenUiParent

    local tracerAttachment = Instance.new("Attachment")
    tracerAttachment.Name = "BrainrotESPTracerAttachment"

    local tracer = Instance.new("Beam")
    tracer.Name = "BrainrotESPTracer"
    tracer.FaceCamera = true
    tracer.Segments = 1
    tracer.LightEmission = 1
    tracer.Width0 = 0.08
    tracer.Width1 = 0.08
    tracer.Transparency = NumberSequence.new(0.1)
    tracer.Color = ColorSequence.new(BrainrotESP.tracerColor)
    tracer.Enabled = false
    tracer.Parent = workspace

    return {
        billboard = billboard,
        nameLabel = nameLabel,
        moneyLabel = moneyLabel,
        highlight = highlight,
        tracer = tracer,
        tracerAttachment = tracerAttachment,
    }
end

local function destroyVisual(visual)
    if not visual then
        return
    end
    pcall(function() visual.billboard:Destroy() end)
    pcall(function() visual.highlight:Destroy() end)
    pcall(function() visual.tracer:Destroy() end)
    pcall(function() visual.tracerAttachment:Destroy() end)
end

local function clearAllVisuals()
    for key, visual in pairs(BrainrotESP.tracked) do
        destroyVisual(visual)
        BrainrotESP.tracked[key] = nil
    end
end

local function refreshBrainrotEsp()
    if not BrainrotESP.enabled then
        return
    end
    if not PlotController or type(PlotController.GetPlots) ~= "function" then
        return
    end

    local plots = PlotController:GetPlots()
    if type(plots) ~= "table" then
        return
    end

    local seen = {}
    local candidates = {}
    local bestKey = nil
    local bestValue = -math.huge
    local currentBaseBestKey = nil
    local currentBaseBestValue = -math.huge
    local targetPlotUID = nil
    local nearestPlotUID = nil
    local nearestPlotDistance = math.huge
    local insidePlotUID = nil
    local insidePlotDistance = math.huge
    local useCurrentBaseFilter = BrainrotESP.currentBaseOnly == true
    local localRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    local localRootPosition = localRoot and localRoot.Position or nil

    if localRootPosition then
        for plotUID, plot in pairs(plots) do
            if type(plot) == "table" then
                local plotModel = rawget(plot, "PlotModel")
                if typeof(plotModel) == "Instance" then
                    local anchorPart = plotModel:FindFirstChild("Spawn") or plotModel:FindFirstChildWhichIsA("BasePart", true)
                    local anchorPos = anchorPart and anchorPart.Position or nil
                    local okBounds, boundsCf, boundsSize = pcall(plotModel.GetBoundingBox, plotModel)
                    if okBounds and boundsCf and boundsSize then
                        anchorPos = boundsCf.Position
                        local localPos = boundsCf:PointToObjectSpace(localRootPosition)
                        local isInside = math.abs(localPos.X) <= (boundsSize.X * 0.5)
                            and math.abs(localPos.Y) <= (boundsSize.Y * 0.5)
                            and math.abs(localPos.Z) <= (boundsSize.Z * 0.5)
                        local dist = (anchorPos - localRootPosition).Magnitude
                        if isInside and dist < insidePlotDistance then
                            insidePlotUID = tostring(plotUID)
                            insidePlotDistance = dist
                        end
                        if dist < nearestPlotDistance then
                            nearestPlotUID = tostring(plotUID)
                            nearestPlotDistance = dist
                        end
                    elseif anchorPos then
                        local dist = (anchorPos - localRootPosition).Magnitude
                        if dist < nearestPlotDistance then
                            nearestPlotUID = tostring(plotUID)
                            nearestPlotDistance = dist
                        end
                    end
                end
            end
        end
        targetPlotUID = insidePlotUID or nearestPlotUID
    end

    for plotUID, plot in pairs(plots) do
        if type(plot) == "table" then
            local isTargetPlot = targetPlotUID ~= nil and tostring(plotUID) == targetPlotUID
            if (not isLocalOwner(getOwner(plot))) or (useCurrentBaseFilter and isTargetPlot) then
                local channel = rawget(plot, "Channel")
                local plotModel = rawget(plot, "PlotModel")
                local podiums = typeof(plotModel) == "Instance" and plotModel:FindFirstChild("AnimalPodiums") or nil
                if channel and type(channel.Get) == "function" and podiums then
                    local okList, animalList = pcall(channel.Get, channel, "AnimalList")
                    if okList and type(animalList) == "table" then
                        for slot, entry in pairs(animalList) do
                            if type(entry) == "table" and type(entry.Index) == "string" then
                                local podium = podiums:FindFirstChild(tostring(slot))
                                local base = podium and podium:FindFirstChild("Base")
                                local spawnPart = base and base:FindFirstChild("Spawn")
                                if spawnPart and spawnPart:IsA("BasePart") then
                                    local key = tostring(plotUID) .. ":" .. tostring(slot)
                                    local moneyPerSec = getMoneyPerSec(entry)
                                    candidates[key] = {
                                        plot = plot,
                                        slot = slot,
                                        spawnPart = spawnPart,
                                        name = getDisplayName(entry.Index),
                                        moneyPerSec = moneyPerSec,
                                    }
                                    seen[key] = true
                                    if moneyPerSec > bestValue then
                                        bestValue = moneyPerSec
                                        bestKey = key
                                    end
                                    if isTargetPlot and moneyPerSec > currentBaseBestValue then
                                        currentBaseBestValue = moneyPerSec
                                        currentBaseBestKey = key
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if useCurrentBaseFilter and currentBaseBestKey == nil then
        currentBaseBestKey = bestKey
    end

    for key, info in pairs(candidates) do
        local visual = BrainrotESP.tracked[key]
        if not visual then
            visual = createVisual()
            BrainrotESP.tracked[key] = visual
        end

        local showByFilter = true
        if BrainrotESP.currentBaseOnly then
            showByFilter = key == currentBaseBestKey
        elseif BrainrotESP.filterMode == "Most Expensive Only" then
            showByFilter = key == bestKey
        end
        local showBillboard = showByFilter and (BrainrotESP.showName or BrainrotESP.showMoney)

        visual.billboard.Adornee = info.spawnPart
        visual.billboard.Enabled = showBillboard
        visual.nameLabel.Visible = BrainrotESP.showName
        visual.moneyLabel.Visible = BrainrotESP.showMoney
        visual.nameLabel.Text = info.name
        visual.moneyLabel.Text = "$" .. formatShort(info.moneyPerSec) .. "/s"

        local highlightAdornee = resolveHighlightAdornee(info.plot, info.slot, info.spawnPart)
        visual.highlight.Adornee = highlightAdornee
        visual.highlight.FillColor = BrainrotESP.highlightColor
        visual.highlight.Enabled = showByFilter and BrainrotESP.showHighlight

        if visual.tracerAttachment.Parent ~= info.spawnPart then
            visual.tracerAttachment.Parent = info.spawnPart
        end

        visual.tracer.Attachment0 = getBrainrotTracerStartAttachment()
        visual.tracer.Attachment1 = visual.tracerAttachment
        visual.tracer.Color = ColorSequence.new(BrainrotESP.tracerColor)
        visual.tracer.Enabled = showByFilter and BrainrotESP.showTracers and visual.tracer.Attachment0 ~= nil
    end

    for key, visual in pairs(BrainrotESP.tracked) do
        if not seen[key] then
            destroyVisual(visual)
            BrainrotESP.tracked[key] = nil
        end
    end
end

function BrainrotESP:Start()
    if self.enabled then
        return
    end
    self.enabled = true
    refreshBrainrotEsp()

    self.connection = RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now >= self.nextUpdateAt then
            self.nextUpdateAt = now + self.updateInterval
            refreshBrainrotEsp()
        end
    end)
end

function BrainrotESP:Stop()
    if not self.enabled then
        return
    end
    self.enabled = false

    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end

    clearAllVisuals()
end

function BrainrotESP:SetName(value)
    self.showName = value and true or false
    refreshBrainrotEsp()
end

function BrainrotESP:SetMoney(value)
    self.showMoney = value and true or false
    refreshBrainrotEsp()
end

function BrainrotESP:SetHighlight(value)
    self.showHighlight = value and true or false
    refreshBrainrotEsp()
end

function BrainrotESP:SetHighlightColor(color)
    if typeof(color) == "Color3" then
        self.highlightColor = color
    end
    for _, visual in pairs(self.tracked) do
        visual.highlight.FillColor = self.highlightColor
    end
end

function BrainrotESP:SetTracers(value)
    self.showTracers = value and true or false
    refreshBrainrotEsp()
end

function BrainrotESP:SetFilterMode(mode)
    if mode == "Most Expensive Only" then
        self.filterMode = "Most Expensive Only"
    else
        self.filterMode = "All"
    end
    refreshBrainrotEsp()
end

function BrainrotESP:SetCurrentBaseOnly(value)
    self.currentBaseOnly = value and true or false
    refreshBrainrotEsp()
end

-- ==================================================
-- BASE VISUALS
-- ==================================================
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local BaseSkinIndexModule = datasFolder:WaitForChild("Index")
local baseSkinIndexFolder = BaseSkinIndexModule:FindFirstChild("Index")
local SynchronizerPackage = safeRequire(packagesFolder:WaitForChild("Synchronizer"))
local conchTypesFolder = sharedFolder:FindFirstChild("ConchTypes")
local BaseSkinConchType = nil
if conchTypesFolder then
    local baseSkinModule = conchTypesFolder:FindFirstChild("BaseSkin")
    if baseSkinModule then
        BaseSkinConchType = safeRequire(baseSkinModule)
    end
end

local function getCurrentBaseSkinData()
    local data = safeRequire(BaseSkinIndexModule)
    if type(data) == "table" then
        return data
    end
    return {}
end

local function getUnlockedBaseSkinNames()
    local names = {}
    if not SynchronizerPackage or type(SynchronizerPackage.Get) ~= "function" then
        return names
    end

    local okSync, syncData = pcall(SynchronizerPackage.Get, SynchronizerPackage, lp)
    if not okSync or type(syncData) ~= "table" or type(syncData.Get) ~= "function" then
        return names
    end

    local okUnlocked, unlocked = pcall(syncData.Get, syncData, "UnlockedBaseSkins")
    if okUnlocked and type(unlocked) == "table" then
        for skinName, unlockedState in pairs(unlocked) do
            if unlockedState and type(skinName) == "string" and skinName ~= "" then
                names[skinName] = true
            end
        end
    end

    return names
end

local baseSkinClientState = {
    selectedSkin = "Normal",
    originalColors = {},
}

local function colorKeyFromColor3(color)
    return string.format("%d,%d,%d",
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5)
    )
end

local function colorKeyFromVector3(vec)
    return string.format("%d,%d,%d",
        math.floor(vec.X + 0.5),
        math.floor(vec.Y + 0.5),
        math.floor(vec.Z + 0.5)
    )
end

local function extractConchTypeValues(typeObj)
    local values = {}
    local seen = {}

    local function addValue(v)
        if type(v) == "string" and v ~= "" then
            values[v] = true
        end
    end

    local function harvestArray(arr)
        if type(arr) ~= "table" then
            return
        end
        for _, value in ipairs(arr) do
            if type(value) == "string" then
                addValue(value)
            elseif type(value) == "table" then
                addValue(value.Name or value.name or value.Value or value.value)
            end
        end
    end

    local function walk(obj, depth)
        if depth > 3 or type(obj) ~= "table" or seen[obj] then
            return
        end
        seen[obj] = true

        harvestArray(obj)
        harvestArray(rawget(obj, "values"))
        harvestArray(rawget(obj, "enum"))
        harvestArray(rawget(obj, "options"))
        harvestArray(rawget(obj, "choices"))

        for _, key in ipairs({ "get_values", "GetValues", "values", "enum_values", "list" }) do
            local fn = rawget(obj, key)
            if type(fn) == "function" then
                local ok, result = pcall(fn, obj)
                if ok then
                    harvestArray(result)
                end
            end
        end

        for _, value in pairs(obj) do
            if type(value) == "table" then
                walk(value, depth + 1)
            end
        end
    end

    walk(typeObj, 1)
    return values
end

local resolveBaseSkinData

local function buildBaseSkinOptions()
    local currentBaseSkinData = getCurrentBaseSkinData()
    local unlockedSkinNames = getUnlockedBaseSkinNames()
    local optionSet = { Normal = true }
    local orderMap = { Normal = 0 }

    for skinName, data in pairs(currentBaseSkinData) do
        if type(skinName) == "string" and type(data) == "table" then
            if data.BaseColors ~= nil or data.DisplayText or data.DisplayWithRichText or data.MainColor or data.Order then
                optionSet[skinName] = true
                orderMap[skinName] = tonumber(data.Order) or 999
            end
        end
    end

    if baseSkinIndexFolder then
        for _, moduleScript in ipairs(baseSkinIndexFolder:GetDescendants()) do
            if moduleScript:IsA("ModuleScript") then
                local skinName = moduleScript.Name
                optionSet[skinName] = true
                if orderMap[skinName] == nil then
                    local data = resolveBaseSkinData(skinName, currentBaseSkinData)
                    orderMap[skinName] = (type(data) == "table" and tonumber(data.Order)) or 999
                end
            end
        end
    end

    for _, moduleScript in ipairs(BaseSkinIndexModule:GetChildren()) do
        if moduleScript:IsA("ModuleScript") then
            local skinName = moduleScript.Name
            optionSet[skinName] = true
            if orderMap[skinName] == nil then
                local data = resolveBaseSkinData(skinName, currentBaseSkinData)
                orderMap[skinName] = (type(data) == "table" and tonumber(data.Order)) or 999
            end
        end
    end

    local conchValues = extractConchTypeValues(BaseSkinConchType)
    for skinName in pairs(conchValues) do
        local data = currentBaseSkinData[skinName]
        if skinName == "Normal" or type(data) == "table" then
            optionSet[skinName] = true
            if orderMap[skinName] == nil then
                orderMap[skinName] = tonumber(data.Order) or 999
            end
        end
    end

    for skinName in pairs(unlockedSkinNames) do
        optionSet[skinName] = true
        if orderMap[skinName] == nil then
            local data = currentBaseSkinData[skinName]
            orderMap[skinName] = (type(data) == "table" and tonumber(data.Order)) or 999
        end
    end

    local options = {}
    for skinName in pairs(optionSet) do
        table.insert(options, skinName)
    end

    table.sort(options, function(a, b)
        if a == "Normal" then
            return true
        end
        if b == "Normal" then
            return false
        end
        local orderA = orderMap[a] or 999
        local orderB = orderMap[b] or 999
        if orderA == orderB then
            return tostring(a) < tostring(b)
        end
        return orderA < orderB
    end)

    return options
end

local function findBaseSkinModule(skinName)
    if type(skinName) ~= "string" or skinName == "" then
        return nil
    end

    if baseSkinIndexFolder then
        local direct = baseSkinIndexFolder:FindFirstChild(skinName)
        if direct and direct:IsA("ModuleScript") then
            return direct
        end

        for _, child in ipairs(baseSkinIndexFolder:GetDescendants()) do
            if child:IsA("ModuleScript") and child.Name == skinName then
                return child
            end
        end
    end

    local directFromIndex = BaseSkinIndexModule:FindFirstChild(skinName)
    if directFromIndex and directFromIndex:IsA("ModuleScript") then
        return directFromIndex
    end

    return nil
end

resolveBaseSkinData = function(skinName, currentBaseSkinData)
    if type(skinName) ~= "string" or skinName == "" then
        return nil
    end

    local source = type(currentBaseSkinData) == "table" and currentBaseSkinData or getCurrentBaseSkinData()
    local skinData = source[skinName]
    if type(skinData) == "table" then
        return skinData
    end

    local moduleScript = findBaseSkinModule(skinName)
    if moduleScript then
        local required = safeRequire(moduleScript)
        if type(required) == "table" then
            return required
        end
    end

    return nil
end

local function getLocalPlotModel()
    -- Method 1: Ask the PlotController for the literal user's plot
    if PlotController and type(PlotController.GetMyPlot) == "function" then
        local okMyPlot, myPlot = pcall(PlotController.GetMyPlot, PlotController)
        if okMyPlot and type(myPlot) == "table" then
            local myPlotModel = rawget(myPlot, "PlotModel")
            if typeof(myPlotModel) == "Instance" then
                return myPlotModel
            end
        end
    end

    -- Method 2: Manually find it in the Workspace by parsing the Owner attribute
    local plotsFolder = workspace:FindFirstChild("Plots")
    if plotsFolder then
        for _, plot in ipairs(plotsFolder:GetChildren()) do
            local ownerAttr = plot:GetAttribute("Owner")
            if ownerAttr and (ownerAttr == lp.UserId or ownerAttr == lp.Name) then
                return plot
            end
            local ownerVal = plot:FindFirstChild("Owner")
            if ownerVal and (ownerVal.Value == lp or ownerVal.Value == lp.Name or ownerVal.Value == lp.UserId) then
                return plot
            end
        end
    end

    -- Method 3: Parse PlotController.GetPlots and execute ownership string testing
    if PlotController and type(PlotController.GetPlots) == "function" then
        local ok, plots = pcall(PlotController.GetPlots, PlotController)
        if ok and type(plots) == "table" then
            for _, plot in pairs(plots) do
                if type(plot) == "table" and isLocalOwner(getOwner(plot)) then
                    local plotModel = rawget(plot, "PlotModel")
                    if typeof(plotModel) == "Instance" then
                        return plotModel
                    end
                end
            end
        end
    end

    return nil
end

local function captureOriginalPlotColors(plotModel)
    if typeof(plotModel) ~= "Instance" then
        return
    end

    for _, inst in ipairs(plotModel:GetDescendants()) do
        if inst:IsA("BasePart") and baseSkinClientState.originalColors[inst] == nil then
            baseSkinClientState.originalColors[inst] = inst.Color
        end
    end
end

local function restorePlotColors(plotModel)
    for part, originalColor in pairs(baseSkinClientState.originalColors) do
        if typeof(part) == "Instance" and part.Parent and part:IsDescendantOf(plotModel) then
            part.Color = originalColor
        end
    end
end

local function buildPaletteLookup(baseColors)
    local palette = {}
    local groundColor = nil

    if type(baseColors) ~= "table" then
        return palette, groundColor
    end

    for key, value in pairs(baseColors) do
        if key == "Ground" and typeof(value) == "Color3" then
            groundColor = value
        elseif typeof(key) == "Vector3" and typeof(value) == "Color3" then
            palette[colorKeyFromVector3(key)] = value
        end
    end

    return palette, groundColor
end

local function applyBaseSkinClientside(skinName)
    local currentBaseSkinData = getCurrentBaseSkinData()
    local plotModel = getLocalPlotModel()
    if not plotModel then
        --warn("[BaseSkinChanger] Could not find local plot model")
        return
    end

    captureOriginalPlotColors(plotModel)
    restorePlotColors(plotModel)
    baseSkinClientState.selectedSkin = skinName

    if skinName == "Normal" then
        return
    end

    local skinData = resolveBaseSkinData(skinName, currentBaseSkinData)
    if type(skinData) ~= "table" then
        --warn("[BaseSkinChanger] Missing skin data for", tostring(skinName))
        return
    end

    local palette, groundColor = buildPaletteLookup(skinData.BaseColors)
    local mainColor = typeof(skinData.MainColor) == "Color3" and skinData.MainColor or nil
    for part, originalColor in pairs(baseSkinClientState.originalColors) do
        if typeof(part) == "Instance" and part.Parent and part:IsDescendantOf(plotModel) then
            local mapped = palette[colorKeyFromColor3(originalColor)]
            if (not mapped) and groundColor and string.find(string.lower(part.Name), "ground", 1, true) then
                mapped = groundColor
            end
            if mapped then
                part.Color = mapped
            elseif mainColor then
                part.Color = mainColor
            end
        end
    end
end


local baseVisualFxState = {
    tracerEnabled = false,
    highlightEnabled = false,
    tracerColor = Color3.fromRGB(255, 255, 255),
    highlightColor = Color3.fromRGB(255, 210, 120),
    beam = nil,
    endAttachment = nil,
    highlight = nil,
    connection = nil,
}

local function getBaseTracerStartAttachment()
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return nil
    end

    local attachment = hrp:FindFirstChild("SabBaseTracerAttachment")
    if attachment and attachment:IsA("Attachment") then
        return attachment
    end

    attachment = Instance.new("Attachment")
    attachment.Name = "SabBaseTracerAttachment"
    attachment.Parent = hrp
    return attachment
end

local function findBaseTargetPart(plotModel)
    if typeof(plotModel) ~= "Instance" then
        return nil
    end

    for _, name in ipairs({ "Ground", "Base", "Floor", "Plot", "Center", "Spawn" }) do
        local inst = plotModel:FindFirstChild(name, true)
        if inst and inst:IsA("BasePart") then
            return inst
        end
    end

    if plotModel:IsA("Model") and plotModel.PrimaryPart then
        return plotModel.PrimaryPart
    end

    for _, inst in ipairs(plotModel:GetDescendants()) do
        if inst:IsA("BasePart") then
            return inst
        end
    end

    return nil
end

local function ensureBaseVisualFxObjects()
    if not baseVisualFxState.beam then
        local beam = Instance.new("Beam")
        beam.Name = "SabBaseTracer"
        beam.FaceCamera = true
        beam.Segments = 1
        beam.LightEmission = 1
        beam.Width0 = 0.11
        beam.Width1 = 0.11
        beam.Transparency = NumberSequence.new(0.08)
        beam.Color = ColorSequence.new(baseVisualFxState.tracerColor)
        beam.Enabled = false
        beam.Parent = workspace
        baseVisualFxState.beam = beam
    end

    if not baseVisualFxState.endAttachment then
        local attachment = Instance.new("Attachment")
        attachment.Name = "SabBaseTracerEnd"
        baseVisualFxState.endAttachment = attachment
    end

    if not baseVisualFxState.highlight then
        local highlight = Instance.new("Highlight")
        highlight.Name = "SabBaseHighlight"
        highlight.FillTransparency = 0.7
        highlight.OutlineTransparency = 0.15
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Enabled = false
        highlight.Parent = workspace
        baseVisualFxState.highlight = highlight
    end
end

local function refreshBaseVisualFx()
    ensureBaseVisualFxObjects()

    local plotModel = getLocalPlotModel()
    if not plotModel then
        baseVisualFxState.beam.Enabled = false
        baseVisualFxState.highlight.Enabled = false
        return
    end

    local targetPart = findBaseTargetPart(plotModel)
    local startAttachment = getBaseTracerStartAttachment()

    if targetPart and baseVisualFxState.endAttachment.Parent ~= targetPart then
        baseVisualFxState.endAttachment.Parent = targetPart
    end

    baseVisualFxState.beam.Attachment0 = startAttachment
    baseVisualFxState.beam.Attachment1 = targetPart and baseVisualFxState.endAttachment or nil
    baseVisualFxState.beam.Color = ColorSequence.new(baseVisualFxState.tracerColor)
    baseVisualFxState.beam.Enabled = baseVisualFxState.tracerEnabled and startAttachment ~= nil and targetPart ~= nil

    baseVisualFxState.highlight.Adornee = plotModel
    baseVisualFxState.highlight.FillColor = baseVisualFxState.highlightColor
    baseVisualFxState.highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    baseVisualFxState.highlight.Enabled = baseVisualFxState.highlightEnabled
end

local function updateBaseVisualFxConnection()
    local shouldRun = baseVisualFxState.tracerEnabled or baseVisualFxState.highlightEnabled
    if shouldRun then
        if not baseVisualFxState.connection then
            baseVisualFxState.connection = RunService.Heartbeat:Connect(refreshBaseVisualFx)
        end
        refreshBaseVisualFx()
    else
        if baseVisualFxState.connection then
            baseVisualFxState.connection:Disconnect()
            baseVisualFxState.connection = nil
        end
        if baseVisualFxState.beam then
            baseVisualFxState.beam.Enabled = false
        end
        if baseVisualFxState.highlight then
            baseVisualFxState.highlight.Enabled = false
        end
    end
end

local function setBaseTracerEnabled(value)
    baseVisualFxState.tracerEnabled = value and true or false
    updateBaseVisualFxConnection()
end

local function setBaseTracerColor(color)
    if typeof(color) == "Color3" then
        baseVisualFxState.tracerColor = color
        refreshBaseVisualFx()
    end
end

local function setBaseHighlightEnabled(value)
    baseVisualFxState.highlightEnabled = value and true or false
    updateBaseVisualFxConnection()
end

local function setBaseHighlightColor(color)
    if typeof(color) == "Color3" then
        baseVisualFxState.highlightColor = color
        refreshBaseVisualFx()
    end
end

local baseSkinOptions = buildBaseSkinOptions()
local defaultBaseSkin = "Normal"

BaseVisualsSection:AddDropdown({
    Name = "Base Skin Changer",
    SaveKey = "sab_base_skin",
    Options = baseSkinOptions,
    Default = defaultBaseSkin,
    Callback = function(value)
        applyBaseSkinClientside(value)
    end
})

local baseTracerColorDefault = Color3.fromRGB(255, 255, 255)
local baseTracerToggle = BaseVisualsSection:AddToggle({
    Name = "Base Tracer",
    SaveKey = "sab_base_tracer",
    Default = false,
    Callback = function(state)
        setBaseTracerEnabled(state)
    end,
})
addToggleColorPicker(BaseVisualsSection, baseTracerToggle, {
    Name = "Base Tracer Color",
    SaveKey = "sab_base_tracer_col",
    Default = baseTracerColorDefault,
    Callback = function(color)
        setBaseTracerColor(color)
    end,
})
setBaseTracerColor(baseTracerColorDefault)

local baseHighlightColorDefault = Color3.fromRGB(255, 210, 120)
local baseHighlightToggle = BaseVisualsSection:AddToggle({
    Name = "Base Highlight",
    SaveKey = "sab_base_hl",
    Default = false,
    Callback = function(state)
        setBaseHighlightEnabled(state)
    end,
})
addToggleColorPicker(BaseVisualsSection, baseHighlightToggle, {
    Name = "Base Highlight Color",
    SaveKey = "sab_base_hl_col",
    Default = baseHighlightColorDefault,
    Callback = function(color)
        setBaseHighlightColor(color)
    end,
})
setBaseHighlightColor(baseHighlightColorDefault)

do -- BASE SPAWNERS scope
local function __sab_base_spawners_scope()
local animalModelsFolder
do
    local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
    if not modelsFolder then
        local ok, result = pcall(function()
            return ReplicatedStorage:WaitForChild("Models", 3)
        end)
        if ok then
            modelsFolder = result
        end
    end
    if modelsFolder then
        animalModelsFolder = modelsFolder:FindFirstChild("Animals")
    end
end

local mutationConchType
local traitConchType
local traitsConchType
if conchTypesFolder then
    local mutationModule = conchTypesFolder:FindFirstChild("Mutation")
    if mutationModule then
        mutationConchType = safeRequire(mutationModule)
    end

    local traitModule = conchTypesFolder:FindFirstChild("Trait")
    if traitModule then
        traitConchType = safeRequire(traitModule)
    end

    local traitsModule = conchTypesFolder:FindFirstChild("Traits")
    if traitsModule then
        traitsConchType = safeRequire(traitsModule)
    end
end

local FastOverheadController = safeRequire(controllersFolder:WaitForChild("FastOverheadController"))
local RaritiesData = safeRequire(datasFolder:WaitForChild("Rarities"))
local TraitsData = safeRequire(datasFolder:WaitForChild("Traits"))
local GradientsPackage
do
    local packagesFolderForPreview = ReplicatedStorage:FindFirstChild("Packages")
    if packagesFolderForPreview then
        local gradientsModule = packagesFolderForPreview:FindFirstChild("Gradients")
        if gradientsModule then
            GradientsPackage = safeRequire(gradientsModule)
        end
    end
end

local brainrotAnimationsFolder
do
    local animationsRoot = ReplicatedStorage:FindFirstChild("Animations")
    if not animationsRoot then
        local ok, result = pcall(function()
            return ReplicatedStorage:WaitForChild("Animations", 3)
        end)
        if ok then
            animationsRoot = result
        end
    end
    if animationsRoot then
        brainrotAnimationsFolder = animationsRoot:FindFirstChild("Animals")
    end
end

local function getBrainrotAnimationSet(brainrotName)
    if type(brainrotName) ~= "string" or brainrotName == "" then
        return nil
    end
    if typeof(brainrotAnimationsFolder) ~= "Instance" then
        return nil
    end
    local animSet = brainrotAnimationsFolder:FindFirstChild(brainrotName)
    if animSet and animSet:IsA("Folder") then
        return animSet
    end
    return nil
end

local function ensureModelAnimator(model)
    if not (model and model:IsA("Model")) then
        return nil
    end

    local animationController = model:FindFirstChild("AnimationController")
    if animationController and not (animationController:IsA("Humanoid") or animationController:IsA("AnimationController")) then
        pcall(function()
            animationController:Destroy()
        end)
        animationController = nil
    end

    if not animationController then
        local humanoid = Instance.new("Humanoid")
        humanoid.Name = "AnimationController"
        humanoid.EvaluateStateMachine = false
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        humanoid.PlatformStand = true
        humanoid.Parent = model
        animationController = humanoid
    end

    local animator = animationController:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = animationController
    end

    return animator
end

local function startBrainrotAnimation(model, brainrotName, preferIdle)
    local animSet = getBrainrotAnimationSet(brainrotName)
    if not animSet then
        return nil
    end

    local animator = ensureModelAnimator(model)
    if not animator then
        return nil
    end

    local chosenAnimation = nil
    if preferIdle then
        chosenAnimation = animSet:FindFirstChild("Idle")
    end
    if not chosenAnimation then
        chosenAnimation = animSet:FindFirstChild("Walk")
    end
    if not (chosenAnimation and chosenAnimation:IsA("Animation")) then
        return nil
    end

    local okTrack, track = pcall(function()
        return animator:LoadAnimation(chosenAnimation)
    end)
    if not okTrack or not track then
        return nil
    end

    track.Looped = true
    track:Play()
    local speedAttr = chosenAnimation:GetAttribute("Speed")
    if type(speedAttr) == "number" then
        pcall(function()
            track:AdjustSpeed(speedAttr)
        end)
    end

    return function()
        pcall(function()
            track:Stop(0)
        end)
        pcall(function()
            track:Destroy()
        end)
    end
end

local previewSpawnerState = {
    selectedBrainrot = nil,
    selectedMutation = "None",
    selectedTrait1 = "None",
    selectedTrait2 = "None",
    selectedTrait3 = "None",
    amount = 3,
    previews = {},
    simulations = {},
    simulationConn = nil,
}

local function getPreviewContainer()
    local folder = workspace:FindFirstChild("SabPreviewAnimals")
    if folder and folder:IsA("Folder") then
        return folder
    end

    folder = Instance.new("Folder")
    folder.Name = "SabPreviewAnimals"
    folder.Parent = workspace
    return folder
end

local function destroyPreviewInstances()
    for _, inst in ipairs(previewSpawnerState.previews) do
        if typeof(inst) == "Instance" then
            pcall(function() inst:Destroy() end)
        elseif type(inst) == "function" then
            pcall(inst)
        elseif type(inst) == "table" and type(inst.Destroy) == "function" then
            pcall(function() inst:Destroy() end)
        end
    end
    previewSpawnerState.previews = {}
    previewSpawnerState.simulations = {}
    if previewSpawnerState.simulationConn then
        previewSpawnerState.simulationConn:Disconnect()
        previewSpawnerState.simulationConn = nil
    end
end

local function collectBrainrotOptions()
    local optionSet = {}

    if animalModelsFolder then
        for _, child in ipairs(animalModelsFolder:GetChildren()) do
            if child:IsA("Model") and child.Name ~= "" then
                optionSet[child.Name] = true
            end
        end
    end

    if type(AnimalsData) == "table" then
        for brainrotName, data in pairs(AnimalsData) do
            if type(brainrotName) == "string" and type(data) == "table" then
                optionSet[brainrotName] = true
            end
        end
    end

    local options = {}
    for brainrotName in pairs(optionSet) do
        table.insert(options, brainrotName)
    end

    table.sort(options, function(a, b)
        local ad = string.lower(tostring(getDisplayName(a)))
        local bd = string.lower(tostring(getDisplayName(b)))
        if ad == bd then
            return tostring(a) < tostring(b)
        end
        return ad < bd
    end)

    if #options == 0 then
        options = { "Unknown" }
    end
    return options
end

local function normalizeLookupKey(value)
    if type(value) ~= "string" then
        return nil
    end

    local normalized = string.lower(value)
    normalized = string.gsub(normalized, "[%s%-%_]+", "")
    return normalized
end

local function resolveMutationKey(value)
    if type(value) ~= "string" or value == "" or value == "None" then
        return nil
    end

    if type(MutationsData) == "table" and type(MutationsData[value]) == "table" then
        return value
    end

    local needle = normalizeLookupKey(value)
    if not needle or type(MutationsData) ~= "table" then
        return nil
    end

    for mutationKey, mutationData in pairs(MutationsData) do
        if type(mutationKey) == "string" then
            if normalizeLookupKey(mutationKey) == needle then
                return mutationKey
            end
            if type(mutationData) == "table" then
                local displayText = mutationData.DisplayText
                if type(displayText) == "string" and normalizeLookupKey(displayText) == needle then
                    return mutationKey
                end
            end
        end
    end

    return nil
end

local function resolveTraitKey(value)
    if type(value) ~= "string" or value == "" or value == "None" then
        return nil
    end

    if type(TraitsData) == "table" and type(TraitsData[value]) == "table" then
        return value
    end

    local needle = normalizeLookupKey(value)
    if not needle or type(TraitsData) ~= "table" then
        return nil
    end

    for traitKey, traitData in pairs(TraitsData) do
        if type(traitKey) == "string" then
            if normalizeLookupKey(traitKey) == needle then
                return traitKey
            end
            if type(traitData) == "table" then
                local displayText = traitData.Display
                if type(displayText) == "string" and normalizeLookupKey(displayText) == needle then
                    return traitKey
                end
            end
        end
    end

    return nil
end

local function collectMutationOptions()
    local optionSet = { None = true }

    if type(MutationsData) == "table" then
        for mutationName, data in pairs(MutationsData) do
            if type(mutationName) == "string" and type(data) == "table" then
                optionSet[mutationName] = true
            end
        end
    end

    local conchValues = extractConchTypeValues(mutationConchType)
    for mutationName in pairs(conchValues) do
        local resolved = resolveMutationKey(mutationName)
        if resolved then
            optionSet[resolved] = true
        end
    end

    local options = {}
    for mutationName in pairs(optionSet) do
        table.insert(options, mutationName)
    end

    table.sort(options, function(a, b)
        if a == "None" then
            return true
        end
        if b == "None" then
            return false
        end
        local ad = type(MutationsData) == "table" and type(MutationsData[a]) == "table" and tostring(MutationsData[a].DisplayText or a) or tostring(a)
        local bd = type(MutationsData) == "table" and type(MutationsData[b]) == "table" and tostring(MutationsData[b].DisplayText or b) or tostring(b)
        return ad < bd
    end)

    return options
end

local function collectTraitOptions()
    local optionSet = { None = true }

    if type(TraitsData) == "table" then
        for traitName, data in pairs(TraitsData) do
            if type(traitName) == "string" and type(data) == "table" then
                optionSet[traitName] = true
            end
        end
    end

    local traitValues = extractConchTypeValues(traitConchType)
    for traitName in pairs(traitValues) do
        local resolved = resolveTraitKey(traitName)
        if resolved then
            optionSet[resolved] = true
        end
    end

    local traitsValues = extractConchTypeValues(traitsConchType)
    for traitName in pairs(traitsValues) do
        local resolved = resolveTraitKey(traitName)
        if resolved then
            optionSet[resolved] = true
        end
    end

    local options = {}
    for traitName in pairs(optionSet) do
        table.insert(options, traitName)
    end

    table.sort(options, function(a, b)
        if a == "None" then
            return true
        end
        if b == "None" then
            return false
        end
        local ad = type(TraitsData) == "table" and type(TraitsData[a]) == "table" and tostring(TraitsData[a].Display or a) or tostring(a)
        local bd = type(TraitsData) == "table" and type(TraitsData[b]) == "table" and tostring(TraitsData[b].Display or b) or tostring(b)
        return ad < bd
    end)

    return options
end

local function formatPreviewMoney(value)
    return formatShort(tonumber(value) or 0)
end

local function callAnimalsSharedMethod(methodName, ...)
    if not AnimalsShared then
        return nil
    end

    local fn = AnimalsShared[methodName]
    if type(fn) ~= "function" then
        return nil
    end

    local ok, result = pcall(fn, AnimalsShared, ...)
    if ok then
        return result
    end

    return nil
end

local function getSelectedTraitKeys()
    local resolved = {}
    local seen = {}
    for _, rawValue in ipairs({
        previewSpawnerState.selectedTrait1,
        previewSpawnerState.selectedTrait2,
        previewSpawnerState.selectedTrait3,
    }) do
        local key = resolveTraitKey(rawValue)
        if key and not seen[key] then
            seen[key] = true
            table.insert(resolved, key)
        end
    end
    return resolved
end

local function getMutationDisplayName(mutationKey)
    local mutationInfo = type(MutationsData) == "table" and MutationsData[mutationKey] or nil
    if type(mutationInfo) == "table" and type(mutationInfo.DisplayText) == "string" and mutationInfo.DisplayText ~= "" then
        return mutationInfo.DisplayText
    end

    return mutationKey
end

local function getPreviewPrice(brainrotName)
    local price = callAnimalsSharedMethod("GetPrice", brainrotName, lp)
    if type(price) == "number" then
        return price
    end

    local entry = type(AnimalsData) == "table" and AnimalsData[brainrotName] or nil
    if type(entry) == "table" then
        if type(entry.Price) == "number" then
            return entry.Price
        end
        if type(entry.Cost) == "number" then
            return entry.Cost
        end
    end

    return 0
end

local function getPreviewGeneration(brainrotName, mutationName, traits)
    local resolvedMutation = resolveMutationKey(mutationName)
    -- Pass nil for player, same as game's PlotClient: GetGeneration(Index, Mutation, Traits, nil)
    -- Let the server's Animals module handle ALL the math (base gen, mutation modifier, traits, etc.)
    local generation = callAnimalsSharedMethod("GetGeneration", brainrotName, resolvedMutation, traits, nil)
    if type(generation) == "number" then
        return generation
    end

    local entry = type(AnimalsData) == "table" and AnimalsData[brainrotName] or nil
    if type(entry) == "table" and type(entry.Generation) == "number" then
        return entry.Generation
    end

    return 0
end

local function getPreviewClaimGeneration(brainrotName, mutationName, traits)
    local resolvedMutation = resolveMutationKey(mutationName)
    local generation = callAnimalsSharedMethod("GetGeneration", brainrotName, resolvedMutation, traits, lp)
    if type(generation) == "number" then
        return generation
    end
    return getPreviewGeneration(brainrotName, mutationName, traits)
end

-- Format generation value exactly like the game does (NumberUtils:ToString)
local function formatGenerationDisplay(value)
    if NumberUtils and type(NumberUtils.ToString) == "function" then
        local ok, formatted = pcall(NumberUtils.ToString, NumberUtils, value)
        if ok and type(formatted) == "string" then
            return trimAbbreviatedNumberText(formatted)
        end
    end
    return trimAbbreviatedNumberText(formatShort(tonumber(value) or 0))
end

local function collectLocalSpawnSlots(maxCount)
    local result = {}
    local plotModel = getLocalPlotModel()
    if not plotModel then
        return result, nil
    end

    local podiums = plotModel:FindFirstChild("AnimalPodiums")
    if not podiums then
        return result, plotModel
    end

    local indexed = {}
    for _, podium in ipairs(podiums:GetChildren()) do
        local slot = tonumber(podium.Name)
        local base = podium:FindFirstChild("Base")
        local spawnPart = base and base:FindFirstChild("Spawn")
        local claim = podium:FindFirstChild("Claim")
        local claimMain = claim and claim:FindFirstChild("Main")
        if slot and spawnPart and spawnPart:IsA("BasePart") then
            table.insert(indexed, {
                slot = slot,
                podium = podium,
                spawnPart = spawnPart,
                claimPart = claimMain and claimMain:IsA("BasePart") and claimMain or nil,
            })
        end
    end

    table.sort(indexed, function(a, b)
        return a.slot < b.slot
    end)

    for i = 1, math.min(maxCount, #indexed) do
        table.insert(result, indexed[i])
    end

    return result, plotModel
end

local function ensureModelPrimaryPart(model)
    if not (model and model:IsA("Model")) then
        return nil
    end

    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end

    local preferred = model:FindFirstChild("HumanoidRootPart", true)
        or model:FindFirstChild("RootPart", true)
        or model:FindFirstChildWhichIsA("BasePart", true)
    if preferred and preferred:IsA("BasePart") then
        model.PrimaryPart = preferred
    end

    return model.PrimaryPart
end

local function prepareModelForPreview(model)
    if not model or not model:IsA("Model") then
        return
    end

    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("BasePart") then
            desc.Anchored = false
            desc.CanCollide = false
            desc.CanTouch = false
            desc.CanQuery = false
            desc.Massless = true
        elseif desc:IsA("Script") or desc:IsA("LocalScript") then
            pcall(function()
                desc.Disabled = true
            end)
        end
    end
    local primary = ensureModelPrimaryPart(model)
    if primary then
        primary.Anchored = true
        primary.RootPriority = 100
    end
end

local function applyPreviewMutation(model, brainrotName, mutationName)
    local resolvedMutation = resolveMutationKey(mutationName)
    if not resolvedMutation then
        return nil
    end
    if not AnimalsShared or type(AnimalsShared.ApplyMutation) ~= "function" then
        return nil
    end

    local ok, result = pcall(AnimalsShared.ApplyMutation, AnimalsShared, model, brainrotName, resolvedMutation)
    if ok then
        return result
    end

    return nil
end

local function applyPreviewTraits(model, brainrotName, traits)
    if type(traits) ~= "table" or #traits == 0 then
        return nil
    end
    if not AnimalsShared or type(AnimalsShared.ApplyTraits) ~= "function" then
        return nil
    end

    local ok, result = pcall(AnimalsShared.ApplyTraits, AnimalsShared, model, brainrotName, traits)
    if ok then
        return result
    end

    return nil
end

local function applyLabelGradient(label, gradientPreset)
    if not label or not label:IsA("TextLabel") then
        return nil
    end
    if not gradientPreset or not GradientsPackage or type(GradientsPackage.apply) ~= "function" then
        return nil
    end

    local ok, cleanup = pcall(GradientsPackage.apply, label, gradientPreset)
    if ok and type(cleanup) == "function" then
        return cleanup
    end

    return nil
end

local function getPreviewOverheadAdornee(model, brainrotName, spawnPart)
    local existing = model:FindFirstChild("OVERHEAD_ATTACHMENT", true) or model:FindFirstChild("Info", true)
    if existing and existing:IsA("Attachment") then
        return existing
    end

    local anchor = spawnPart
    if not (anchor and anchor:IsA("BasePart")) then
        anchor = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    end
    if not anchor then
        return nil
    end

    local entry = type(AnimalsData) == "table" and AnimalsData[brainrotName] or nil
    local yModifier = 1
    if type(entry) == "table" and type(entry.OverheadYOffsetModifier) == "number" then
        yModifier = entry.OverheadYOffsetModifier
    end

    local extents = model:GetExtentsSize()
    local attachment = Instance.new("Attachment")
    attachment.Name = "OVERHEAD_ATTACHMENT"
    attachment.CFrame = CFrame.new(0, extents.Y * 0.75 * yModifier, 0)
    attachment.Parent = anchor
    return attachment
end

local function createNativePreviewOverhead(model, brainrotName, mutationName, traits, spawnPart)
    if not FastOverheadController or type(FastOverheadController.createFastOverhead) ~= "function" then
        return
    end

    local templates = FastOverheadController.GuiTemplates
    local animalOverheadTemplate = type(templates) == "table" and templates.AnimalOverhead or nil
    if typeof(animalOverheadTemplate) ~= "Instance" then
        return
    end

    local adornee = getPreviewOverheadAdornee(model, brainrotName, spawnPart)
    if not adornee then
        return
    end
    table.insert(previewSpawnerState.previews, adornee)

    local ok, overheadGui, cleanup = pcall(function()
        return FastOverheadController.createFastOverhead({
            adornee = adornee,
            guiTemplate = animalOverheadTemplate,
        })
    end)
    if not ok then
        return
    end

    if type(cleanup) == "function" then
        table.insert(previewSpawnerState.previews, cleanup)
    elseif typeof(overheadGui) == "Instance" then
        table.insert(previewSpawnerState.previews, overheadGui)
    end

    if typeof(overheadGui) ~= "Instance" then
        return
    end

    local resolvedMutation = resolveMutationKey(mutationName)
    local animalInfo = type(AnimalsData) == "table" and AnimalsData[brainrotName] or nil
    local rarityName = (type(animalInfo) == "table" and animalInfo.Rarity) or "Unknown"
    local rarityInfo = type(RaritiesData) == "table" and RaritiesData[rarityName] or nil
    local mutationInfo = type(MutationsData) == "table" and MutationsData[resolvedMutation] or nil

    local nameLabel = overheadGui:FindFirstChild("DisplayName", true)
    if nameLabel and nameLabel:IsA("TextLabel") then
        nameLabel.Text = getDisplayName(brainrotName)
    end

    local priceLabel = overheadGui:FindFirstChild("Price", true)
    if priceLabel and priceLabel:IsA("TextLabel") then
        priceLabel.Text = string.format("$%s", formatPreviewMoney(getPreviewPrice(brainrotName)))
    end

    local generationLabel = overheadGui:FindFirstChild("Generation", true)
    if generationLabel and generationLabel:IsA("TextLabel") then
        local genValue = getPreviewGeneration(brainrotName, resolvedMutation, traits)
        generationLabel.Text = string.format("$%s/s", formatGenerationDisplay(genValue))
        generationLabel.Visible = true
    end

    local rarityLabel = overheadGui:FindFirstChild("Rarity", true)
    if rarityLabel and rarityLabel:IsA("TextLabel") then
        rarityLabel.Text = tostring(rarityName)
        if type(rarityInfo) == "table" and typeof(rarityInfo.Color) == "Color3" then
            rarityLabel.TextColor3 = rarityInfo.Color
        end

        local rarityStroke = rarityLabel:FindFirstChildOfClass("UIStroke")
        if rarityStroke and type(rarityInfo) == "table" and typeof(rarityInfo.StrokeColor) == "Color3" then
            rarityStroke.Color = rarityInfo.StrokeColor
        end

        if type(rarityInfo) == "table" and rarityInfo.GradientPreset then
            local cleanupGradient = applyLabelGradient(rarityLabel, rarityInfo.GradientPreset)
            if cleanupGradient then
                table.insert(previewSpawnerState.previews, cleanupGradient)
            end
        end
    end

    local mutationLabel = overheadGui:FindFirstChild("Mutation", true)
    if mutationLabel and mutationLabel:IsA("TextLabel") then
        local hasMutation = resolvedMutation ~= nil
        mutationLabel.Visible = hasMutation and true or false
        if hasMutation then
            if type(mutationInfo) == "table" then
                if mutationInfo.UseRichText and type(mutationInfo.DisplayWithRichText) == "string" then
                    mutationLabel.RichText = true
                    mutationLabel.Text = mutationInfo.DisplayWithRichText
                else
                    mutationLabel.RichText = false
                    mutationLabel.Text = tostring(mutationInfo.DisplayText or mutationName)
                end

                if mutationInfo.GradientPreset then
                    mutationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    local cleanupGradient = applyLabelGradient(mutationLabel, mutationInfo.GradientPreset)
                    if cleanupGradient then
                        table.insert(previewSpawnerState.previews, cleanupGradient)
                    end
                elseif typeof(mutationInfo.MainColor) == "Color3" then
                    mutationLabel.TextColor3 = mutationInfo.MainColor
                end
            else
                mutationLabel.RichText = false
                mutationLabel.Text = tostring(getMutationDisplayName(resolvedMutation))
            end
        end
    end

    local traitsFrame = overheadGui:FindFirstChild("Traits", true)
    if traitsFrame and traitsFrame:IsA("GuiObject") then
        local traitList = type(traits) == "table" and traits or {}
        local template = traitsFrame:FindFirstChild("Template")
        if template and #traitList > 0 then
            for _, child in ipairs(traitsFrame:GetChildren()) do
                if child ~= template and child:IsA("GuiObject") then
                    child:Destroy()
                end
            end

            for _, traitKey in ipairs(traitList) do
                local traitData = type(TraitsData) == "table" and TraitsData[traitKey] or nil
                local icon = template:Clone()
                icon.Name = tostring(traitKey)
                icon.Visible = true
                if icon:IsA("ImageLabel") and type(traitData) == "table" and type(traitData.Icon) == "string" then
                    icon.Image = traitData.Icon
                end
                icon.Parent = traitsFrame
            end
            traitsFrame.Visible = true
        else
            traitsFrame.Visible = false
        end
    end

    local stolenLabel = overheadGui:FindFirstChild("Stolen", true)
    if stolenLabel and stolenLabel:IsA("TextLabel") then
        stolenLabel.Visible = false
    end

    return overheadGui
end

local function resolveCashPadLabels(cashPadGui)
    if typeof(cashPadGui) ~= "Instance" then
        return nil, nil, nil
    end

    local collectLabel = cashPadGui:FindFirstChild("Collect", true)
    local collectAmountLabel = cashPadGui:FindFirstChild("CollectAmount", true)
        or cashPadGui:FindFirstChild("Amount", true)
        or cashPadGui:FindFirstChild("Value", true)
    local offlineLabel = cashPadGui:FindFirstChild("Offline", true)

    return collectLabel, collectAmountLabel, offlineLabel
end

previewSpawnerState._ensureSimulationLoop = function()
    if previewSpawnerState.simulationConn then
        return
    end

    previewSpawnerState.simulationConn = RunService.Heartbeat:Connect(function()
        local sims = previewSpawnerState.simulations
        if #sims == 0 then
            return
        end

        local now = workspace:GetServerTimeNow()
        for i = #sims, 1, -1 do
            local sim = sims[i]
            if sim.destroyed or not sim.model or not sim.model.Parent then
                if sim.destroy then
                    sim.destroy()
                else
                    table.remove(sims, i)
                end
            else
                local elapsed = math.max(0, math.floor(now - sim.lastCollectAt))
                local collectAmount = math.max(0, math.floor((elapsed * sim.generationPerSec) + 0.5))
                sim.collectAmount = collectAmount

                if sim.collectAmountLabel and sim.collectAmountLabel:IsA("TextLabel") then
                    sim.collectAmountLabel.Text = "$" .. formatGenerationDisplay(collectAmount)
                end

                if sim.cashPadGui and sim.cashPadGui:IsA("BillboardGui") then
                    sim.cashPadGui.Enabled = true
                end
            end
        end

        if #sims == 0 and previewSpawnerState.simulationConn then
            previewSpawnerState.simulationConn:Disconnect()
            previewSpawnerState.simulationConn = nil
        end
    end)
end

previewSpawnerState._attachSimulation = function(model, brainrotName, mutationName, traits, slotInfo)
    if not (model and model:IsA("Model")) then
        return nil
    end
    if type(slotInfo) ~= "table" then
        return nil
    end

    local claimPart = slotInfo.claimPart
    if not (claimPart and claimPart:IsA("BasePart")) then
        return nil
    end

    local generationPerSec = math.max(0, tonumber(getPreviewClaimGeneration(brainrotName, mutationName, traits)) or 0)
    local cashPadGui = nil
    local cashPadCleanup = nil

    if FastOverheadController and type(FastOverheadController.createFastOverhead) == "function" then
        local templates = FastOverheadController.GuiTemplates
        local cashPadTemplate = type(templates) == "table" and templates.CashPad or nil
        if typeof(cashPadTemplate) == "Instance" then
            local ok, gui, cleanup = pcall(function()
                return FastOverheadController.createFastOverhead({
                    adornee = claimPart,
                    guiTemplate = cashPadTemplate,
                })
            end)
            if ok and typeof(gui) == "Instance" then
                cashPadGui = gui
                cashPadCleanup = cleanup
            end
        end
    end

    local collectLabel, collectAmountLabel, offlineLabel = resolveCashPadLabels(cashPadGui)
    if collectLabel and collectLabel:IsA("TextLabel") then
        collectLabel.Text = "Collect"
    end
    if offlineLabel and offlineLabel:IsA("TextLabel") then
        offlineLabel.Visible = false
    end

    local sim = {
        model = model,
        claimPart = claimPart,
        cashPadGui = cashPadGui,
        collectAmountLabel = collectAmountLabel,
        generationPerSec = generationPerSec,
        lastCollectAt = workspace:GetServerTimeNow(),
        collectAmount = 0,
        destroyed = false,
    }

    local touchConn = claimPart.Touched:Connect(function(hit)
        if sim.destroyed then
            return
        end
        local char = lp.Character
        if not char or not hit then
            return
        end
        if hit:IsDescendantOf(char) then
            sim.lastCollectAt = workspace:GetServerTimeNow()
        end
    end)

    sim.destroy = function()
        if sim.destroyed then
            return
        end
        sim.destroyed = true

        if touchConn and typeof(touchConn) == "RBXScriptConnection" then
            touchConn:Disconnect()
        end
        touchConn = nil

        if type(cashPadCleanup) == "function" then
            pcall(cashPadCleanup)
        elseif cashPadGui and cashPadGui.Parent then
            pcall(function()
                cashPadGui:Destroy()
            end)
        end
        cashPadGui = nil
        cashPadCleanup = nil

        for i = #previewSpawnerState.simulations, 1, -1 do
            if previewSpawnerState.simulations[i] == sim then
                table.remove(previewSpawnerState.simulations, i)
                break
            end
        end
    end

    table.insert(previewSpawnerState.simulations, sim)
    previewSpawnerState._ensureSimulationLoop()
    return sim.destroy
end

local function createFallbackPreview(cframe, brainrotName, mutationName, traits, slotInfo)
    local model = Instance.new("Model")
    model.Name = "SabPreview_" .. tostring(brainrotName)
    model.Parent = getPreviewContainer()

    local body = Instance.new("Part")
    body.Name = "Body"
    body.Anchored = true
    body.CanCollide = false
    body.CanTouch = false
    body.CanQuery = false
    body.Material = Enum.Material.Neon
    body.Size = Vector3.new(2.2, 2.6, 2.2)
    body.Color = Color3.fromRGB(120, 220, 255)
    body.CFrame = cframe
    body.Parent = model
    model.PrimaryPart = body

    local spawnPart = type(slotInfo) == "table" and slotInfo.spawnPart or nil
    local overheadGui = createNativePreviewOverhead(model, brainrotName, mutationName, traits, spawnPart or body)
    local simulationCleanup = previewSpawnerState._attachSimulation(model, brainrotName, mutationName, traits, slotInfo, overheadGui)

    table.insert(previewSpawnerState.previews, model)
    if simulationCleanup then
        table.insert(previewSpawnerState.previews, simulationCleanup)
    end
end

local function createSingleBrainrotPreview(cframe, brainrotName, mutationName, traits, slotInfo)
    local template = animalModelsFolder and animalModelsFolder:FindFirstChild(brainrotName)
    if not (template and template:IsA("Model")) then
        --warn("[BaseSpawner] Missing model template for", tostring(brainrotName))
        return
    end

    local model = template:Clone()
    model.Name = "SabPreview_" .. tostring(brainrotName)
    prepareModelForPreview(model)
    model.Parent = getPreviewContainer()

    model:PivotTo(cframe)

    local mutationHandle = applyPreviewMutation(model, brainrotName, mutationName)
    local traitsHandle = applyPreviewTraits(model, brainrotName, traits)
    local animCleanup = startBrainrotAnimation(model, brainrotName, true)
    local spawnPart = type(slotInfo) == "table" and slotInfo.spawnPart or nil
    local overheadGui = createNativePreviewOverhead(model, brainrotName, mutationName, traits, spawnPart)
    local simulationCleanup = previewSpawnerState._attachSimulation(model, brainrotName, mutationName, traits, slotInfo, overheadGui)

    table.insert(previewSpawnerState.previews, model)
    if mutationHandle then
        table.insert(previewSpawnerState.previews, mutationHandle)
    end
    if traitsHandle then
        table.insert(previewSpawnerState.previews, traitsHandle)
    end
    if animCleanup then
        table.insert(previewSpawnerState.previews, animCleanup)
    end
    if simulationCleanup then
        table.insert(previewSpawnerState.previews, simulationCleanup)
    end
end

local function spawnBrainrotPreviews()
    destroyPreviewInstances()

    local brainrotName = previewSpawnerState.selectedBrainrot
    if type(brainrotName) ~= "string" or brainrotName == "" then
        return
    end

    local amount = math.clamp(math.floor(tonumber(previewSpawnerState.amount) or 1), 1, 12)
    local mutationName = previewSpawnerState.selectedMutation or "None"
    local selectedTraits = getSelectedTraitKeys()

    local spawnSlots, plotModel = collectLocalSpawnSlots(amount)
    if #spawnSlots > 0 then
        for i = 1, math.min(amount, #spawnSlots) do
            local slotInfo = spawnSlots[i]
            createSingleBrainrotPreview(slotInfo.spawnPart:GetPivot(), brainrotName, mutationName, selectedTraits, slotInfo)
        end
        return
    end

    if not plotModel then
        --warn("[BaseSpawner] Could not resolve local plot model/slots")
    else
        --warn("[BaseSpawner] No podium spawn slots found on local plot")
    end
end

local brainrotSpawnOptions = collectBrainrotOptions()
local mutationSpawnOptions = collectMutationOptions()
local traitSpawnOptions = collectTraitOptions()
previewSpawnerState.selectedBrainrot = brainrotSpawnOptions[1]

BaseSpawnerSection:AddDropdown({
    Name = "Brainrot",
    SaveKey = "sab_preview_brainrot",
    Options = brainrotSpawnOptions,
    Default = brainrotSpawnOptions[1],
    Callback = function(value)
        previewSpawnerState.selectedBrainrot = value
    end,
})

BaseSpawnerSection:AddDropdown({
    Name = "Mutation",
    SaveKey = "sab_preview_mutation",
    Options = mutationSpawnOptions,
    Default = "None",
    Callback = function(value)
        previewSpawnerState.selectedMutation = value
    end,
})

BaseSpawnerSection:AddDropdown({
    Name = "Trait 1",
    SaveKey = "sab_preview_trait_1",
    Options = traitSpawnOptions,
    Default = "None",
    Callback = function(value)
        previewSpawnerState.selectedTrait1 = value
    end,
})

BaseSpawnerSection:AddDropdown({
    Name = "Trait 2",
    SaveKey = "sab_preview_trait_2",
    Options = traitSpawnOptions,
    Default = "None",
    Callback = function(value)
        previewSpawnerState.selectedTrait2 = value
    end,
})

BaseSpawnerSection:AddDropdown({
    Name = "Trait 3",
    SaveKey = "sab_preview_trait_3",
    Options = traitSpawnOptions,
    Default = "None",
    Callback = function(value)
        previewSpawnerState.selectedTrait3 = value
    end,
})

BaseSpawnerSection:AddSlider({
    Name = "Preview Amount",
    SaveKey = "sab_preview_amount",
    Min = 1,
    Max = 12,
    Default = 3,
    Precision = 0,
    Callback = function(value)
        previewSpawnerState.amount = value
    end,
})

BaseSpawnerSection:AddButton({
    Name = "Spawn Preview",
    Callback = function()
        spawnBrainrotPreviews()
    end,
})

BaseSpawnerSection:AddButton({
    Name = "Clear Previews",
    Callback = function()
        destroyPreviewInstances()
    end,
})

-- ==================================================
-- ROAD BRAINROT SPAWNER
-- ==================================================
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local renderedMovingAnimals = workspace:FindFirstChild("RenderedMovingAnimals")
    or Instance.new("Folder", workspace)
if renderedMovingAnimals.Name ~= "RenderedMovingAnimals" then
    renderedMovingAnimals.Name = "RenderedMovingAnimals"
end
local classesFolder = ReplicatedStorage:WaitForChild("Classes")
local AnimalClientClass = safeRequire(classesFolder:WaitForChild("AnimalClient"))
local HttpService = game:GetService("HttpService")

local roadSpawnerState = {
    selectedBrainrot = nil,
    selectedMutation = "None",
    selectedTrait1 = "None",
    selectedTrait2 = "None",
    selectedTrait3 = "None",
    walkSpeed = 8,
    activeRoadBrainrots = {},  -- { {sourceModel, animalClient, tweens, cleanups} }
}

local function getRoadSelectedTraitKeys()
    local traits = {}
    local selections = {
        roadSpawnerState.selectedTrait1,
        roadSpawnerState.selectedTrait2,
        roadSpawnerState.selectedTrait3,
    }
    for _, sel in ipairs(selections) do
        if type(sel) == "string" and sel ~= "None" and sel ~= "" then
            local resolved = resolveTraitKey(sel)
            if resolved then
                table.insert(traits, resolved)
            end
        end
    end
    return traits
end

local function ensurePrimaryPart(model)
    if not (model and model:IsA("Model")) then
        return nil
    end
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end
    local firstPart = model:FindFirstChildWhichIsA("BasePart", true)
    if firstPart then
        model.PrimaryPart = firstPart
    end
    return firstPart
end

local function stripCollectionTags(root)
    local function stripOne(obj)
        local okTags, tags = pcall(function()
            return CollectionService:GetTags(obj)
        end)
        if okTags and type(tags) == "table" then
            for _, tag in ipairs(tags) do
                pcall(function()
                    CollectionService:RemoveTag(obj, tag)
                end)
            end
        end
    end

    stripOne(root)
    for _, desc in ipairs(root:GetDescendants()) do
        stripOne(desc)
    end
end

local function getRoadSourceTemplate()
    local taggedAnimals = CollectionService:GetTagged("Animal")
    local fallback = nil

    for _, inst in ipairs(taggedAnimals) do
        if inst:IsA("Model") and inst.Parent then
            local pp = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
            if pp then
                if not fallback then
                    fallback = inst
                end
                local hasPrompt = pp:FindFirstChild("PromptAttachment") ~= nil
                local hasCustomWeld = inst:FindFirstChild("CreateClientWeld") ~= nil
                if hasPrompt and not hasCustomWeld then
                    return inst
                end
            end
        end
    end

    return fallback
end

local function collectRoadWaypoints()
    local road = workspace:FindFirstChild("Road")
    if not road then
        return {}
    end

    -- Collect numbered waypoint parts (1, 2, 3, ...) from descendants.
    local waypoints = {}
    local groundNumbered = {}
    local numbered = {}
    for _, child in ipairs(road:GetDescendants()) do
        if child:IsA("BasePart") then
            local lower = string.lower(child.Name)
            local num = tonumber(child.Name)
            if num then
                numbered[num] = child
            end
            local groundNum = tonumber(
                lower:match("^(%d+)ground$")
                or lower:match("^ground(%d+)$")
                or lower:match("^waypoint(%d+)ground$")
                or lower:match("^waypointground(%d+)$")
            )
            if groundNum then
                groundNumbered[groundNum] = child
            end
        end
    end

    if next(groundNumbered) then
        local keys = {}
        for k in pairs(groundNumbered) do
            table.insert(keys, k)
        end
        table.sort(keys)
        for _, k in ipairs(keys) do
            table.insert(waypoints, groundNumbered[k].Position)
        end
        return waypoints
    end

    if next(numbered) then
        local keys = {}
        for k in pairs(numbered) do
            table.insert(keys, k)
        end
        table.sort(keys)
        for _, k in ipairs(keys) do
            table.insert(waypoints, numbered[k].Position)
        end
        return waypoints
    end

    -- Fallback path: Start -> known nodes -> End/Finish.
    local startPart = road:FindFirstChild("StartGround", true) or road:FindFirstChild("Start", true)
    local endPart = road:FindFirstChild("EndGround", true) or road:FindFirstChild("End", true) or road:FindFirstChild("Finish", true)

    if startPart and startPart:IsA("BasePart") then
        table.insert(waypoints, startPart.Position)
    end

    local groundNodeParts = {}
    local regularNodeParts = {}
    for _, child in ipairs(road:GetDescendants()) do
        if child:IsA("BasePart") and child ~= startPart and child ~= endPart then
            local lower = string.lower(child.Name)
            if string.find(lower, "waypoint", 1, true) or string.find(lower, "node", 1, true) then
                if string.find(lower, "ground", 1, true) then
                    table.insert(groundNodeParts, child)
                else
                    table.insert(regularNodeParts, child)
                end
            end
        end
    end

    local nodeParts = (#groundNodeParts > 0) and groundNodeParts or regularNodeParts
    if #nodeParts > 0 then
        if startPart and startPart:IsA("BasePart") then
            table.sort(nodeParts, function(a, b)
                return (a.Position - startPart.Position).Magnitude < (b.Position - startPart.Position).Magnitude
            end)
        else
            table.sort(nodeParts, function(a, b)
                return a.Position.X < b.Position.X
            end)
        end
        for _, node in ipairs(nodeParts) do
            table.insert(waypoints, node.Position)
        end
    end

    if endPart and endPart:IsA("BasePart") then
        table.insert(waypoints, endPart.Position)
    end

    -- Remove near-duplicates that cause zero-length segments.
    local deduped = {}
    local seen = {}
    for _, pos in ipairs(waypoints) do
        local key = string.format("%.2f,%.2f,%.2f", pos.X, pos.Y, pos.Z)
        if not seen[key] then
            seen[key] = true
            table.insert(deduped, pos)
        end
    end

    return deduped
end

local function removeRoadBrainrotEntry(entry)
    if type(entry) ~= "table" or entry._destroyed then
        return
    end
    entry._destroyed = true

    if entry.tweens then
        for _, tw in ipairs(entry.tweens) do
            pcall(function() tw:Cancel() end)
            if type(tw) == "table" and type(tw._sab_cleanup) == "function" then
                pcall(tw._sab_cleanup)
            end
        end
    end

    if entry.cleanups then
        for _, cleanup in ipairs(entry.cleanups) do
            if type(cleanup) == "function" then
                pcall(cleanup)
            elseif typeof(cleanup) == "Instance" then
                pcall(function() cleanup:Destroy() end)
            elseif type(cleanup) == "table" and type(cleanup.Destroy) == "function" then
                pcall(function() cleanup:Destroy() end)
            end
        end
    end

    if entry.animalClient and type(entry.animalClient.Destroy) == "function" then
        pcall(function()
            entry.animalClient:Destroy()
        end)
        entry.animalClient = nil
    end

    if entry.sourceModel and typeof(entry.sourceModel) == "Instance" then
        pcall(function()
            entry.sourceModel:Destroy()
        end)
        entry.sourceModel = nil
    end

    if entry.anchor and typeof(entry.anchor) == "Instance" and entry.anchor.Parent then
        pcall(function()
            entry.anchor:Destroy()
        end)
        entry.anchor = nil
    end

    for i = #roadSpawnerState.activeRoadBrainrots, 1, -1 do
        if roadSpawnerState.activeRoadBrainrots[i] == entry then
            table.remove(roadSpawnerState.activeRoadBrainrots, i)
            break
        end
    end
end

local function destroyRoadBrainrots()
    local snapshot = {}
    for i, entry in ipairs(roadSpawnerState.activeRoadBrainrots) do
        snapshot[i] = entry
    end
    for _, entry in ipairs(snapshot) do
        removeRoadBrainrotEntry(entry)
    end
    roadSpawnerState.activeRoadBrainrots = {}
end

local function tweenAlongWaypoints(targetInstance, waypoints, speed, onComplete)
    if #waypoints < 2 then
        if onComplete then
            task.defer(onComplete)
        end
        return {}
    end

    if not (targetInstance and targetInstance.Parent) then
        return {}
    end

    local isModel = targetInstance:IsA("Model")
    local mover = nil
    local moveConn = nil
    local function getCurrentPosition()
        if isModel then
            return targetInstance:GetPivot().Position
        end
        return targetInstance.Position
    end
    local function setInstantCFrame(cf)
        if isModel then
            targetInstance:PivotTo(cf)
        else
            targetInstance.CFrame = cf
        end
    end

    if isModel then
        mover = Instance.new("CFrameValue")
        mover.Value = CFrame.new(waypoints[1], waypoints[2])
        moveConn = mover:GetPropertyChangedSignal("Value"):Connect(function()
            if targetInstance and targetInstance.Parent then
                targetInstance:PivotTo(mover.Value)
            end
        end)
        targetInstance:PivotTo(mover.Value)
    end

    local tweens = {}
    local currentIndex = 1
    local finished = false

    local function moveToNext()
        if finished then
            return
        end

        currentIndex = currentIndex + 1
        if currentIndex > #waypoints then
            finished = true
            if onComplete then
                task.defer(onComplete)
            end
            return
        end

        local targetPos = waypoints[currentIndex]
        local currentPos = getCurrentPosition()
        local distance = (targetPos - currentPos).Magnitude
        local duration = distance / math.max(speed, 1)

        local direction = (targetPos - currentPos)
        if direction.Magnitude <= 0.05 then
            setInstantCFrame(CFrame.new(targetPos))
            moveToNext()
            return
        end

        local moveDir = direction.Unit
        local startCf = CFrame.new(currentPos, currentPos + moveDir)
        local endCf = CFrame.new(targetPos, targetPos + moveDir)
        setInstantCFrame(startCf)

        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
        local tween
        if isModel then
            tween = TweenService:Create(mover, tweenInfo, { Value = endCf })
        else
            tween = TweenService:Create(targetInstance, tweenInfo, { CFrame = endCf })
        end
        table.insert(tweens, tween)

        tween.Completed:Connect(function(status)
            if finished then
                return
            end
            if status == Enum.PlaybackState.Completed then
                moveToNext()
            end
        end)
        tween:Play()
    end

    setInstantCFrame(CFrame.new(waypoints[1], waypoints[2]))
    moveToNext()

    if moveConn then
        table.insert(tweens, {
            Cancel = function() end,
            _sab_cleanup = function()
                if moveConn then
                    moveConn:Disconnect()
                    moveConn = nil
                end
                if mover then
                    mover:Destroy()
                    mover = nil
                end
            end,
        })
    end

    return tweens
end

local function spawnRoadBrainrot()
    local brainrotName = roadSpawnerState.selectedBrainrot
    if type(brainrotName) ~= "string" or brainrotName == "" then
        --warn("[RoadSpawner] No brainrot selected")
        return
    end

    local mutationName = roadSpawnerState.selectedMutation or "None"
    local selectedTraits = getRoadSelectedTraitKeys()
    local resolvedMut = resolveMutationKey(mutationName)
    local speed = roadSpawnerState.walkSpeed or 8

    -- Get road waypoints
    local waypoints = collectRoadWaypoints()
    if #waypoints < 2 then
        --warn("[RoadSpawner] Could not find road waypoints in workspace.Road")
        return
    end

    local template = animalModelsFolder and animalModelsFolder:FindFirstChild(brainrotName)
    if not (template and template:IsA("Model")) then
        --warn("[RoadSpawner] No model found for", brainrotName)
        return
    end

    local sourceModel = nil
    local sourceTemplate = getRoadSourceTemplate()
    if sourceTemplate then
        local okClone, cloned = pcall(function()
            return sourceTemplate:Clone()
        end)
        if okClone and cloned and cloned:IsA("Model") then
            sourceModel = cloned
        end
    end

    if not sourceModel then
        --warn("[RoadSpawner] No live road source found. Wait for a natural road brainrot, then try again.")
        return
    end

    sourceModel.Name = "RoadSource_" .. tostring(brainrotName) .. "_" .. HttpService:GenerateGUID(false)
    stripCollectionTags(sourceModel)

    local primaryPart = ensurePrimaryPart(sourceModel)
    if not primaryPart then
        sourceModel:Destroy()
        --warn("[RoadSpawner] Could not resolve source model PrimaryPart")
        return
    end

    for _, desc in ipairs(sourceModel:GetDescendants()) do
        if desc:IsA("BasePart") then
            desc.Anchored = true
            desc.CanCollide = false
            desc.CanQuery = false
            desc.CanTouch = false
            desc.Massless = true
            desc.Transparency = 1
            desc.CastShadow = false
        end
    end

    local promptAttachment = primaryPart:FindFirstChild("PromptAttachment")
    if not promptAttachment then
        promptAttachment = Instance.new("Attachment")
        promptAttachment.Name = "PromptAttachment"
        promptAttachment.Parent = primaryPart
    end
    local traitsMap = nil
    if #selectedTraits > 0 then
        traitsMap = {}
        for _, traitKey in ipairs(selectedTraits) do
            traitsMap[traitKey] = true
        end
    end

    sourceModel:SetAttribute("Index", brainrotName)
    sourceModel:SetAttribute("Mutation", resolvedMut)
    sourceModel:SetAttribute("ForceIdle", false)
    if traitsMap then
        sourceModel:SetAttribute("Traits", HttpService:JSONEncode(traitsMap))
    else
        sourceModel:SetAttribute("Traits", nil)
    end

    sourceModel.Parent = workspace
    sourceModel:PivotTo(CFrame.new(waypoints[1], waypoints[2]))

    if not (AnimalClientClass and type(AnimalClientClass.new) == "function") then
        sourceModel:Destroy()
        --warn("[RoadSpawner] AnimalClient unavailable")
        return
    end

    local okAnimal, animalClient = pcall(AnimalClientClass.new, sourceModel)
    if not okAnimal or type(animalClient) ~= "table" then
        sourceModel:Destroy()
        --warn("[RoadSpawner] AnimalClient spawn failed")
        return
    end

    local entry = {
        anchor = sourceModel,
        sourceModel = sourceModel,
        animalClient = animalClient,
        tweens = {},
        cleanups = {},
    }

    table.insert(roadSpawnerState.activeRoadBrainrots, entry)

    entry.tweens = tweenAlongWaypoints(sourceModel, waypoints, speed, function()
        removeRoadBrainrotEntry(entry)
    end)
end

-- Road Spawner UI
local roadBrainrotOptions = collectBrainrotOptions()
local roadMutationOptions = collectMutationOptions()
local roadTraitOptions = collectTraitOptions()
roadSpawnerState.selectedBrainrot = roadBrainrotOptions[1]

RoadSpawnerSection:AddDropdown({
    Name = "Brainrot",
    SaveKey = "sab_road_brainrot",
    Options = roadBrainrotOptions,
    Default = roadBrainrotOptions[1],
    Callback = function(value)
        roadSpawnerState.selectedBrainrot = value
    end,
})

RoadSpawnerSection:AddDropdown({
    Name = "Mutation",
    SaveKey = "sab_road_mutation",
    Options = roadMutationOptions,
    Default = "None",
    Callback = function(value)
        roadSpawnerState.selectedMutation = value
    end,
})

RoadSpawnerSection:AddDropdown({
    Name = "Trait 1",
    SaveKey = "sab_road_trait_1",
    Options = roadTraitOptions,
    Default = "None",
    Callback = function(value)
        roadSpawnerState.selectedTrait1 = value
    end,
})

RoadSpawnerSection:AddDropdown({
    Name = "Trait 2",
    SaveKey = "sab_road_trait_2",
    Options = roadTraitOptions,
    Default = "None",
    Callback = function(value)
        roadSpawnerState.selectedTrait2 = value
    end,
})

RoadSpawnerSection:AddDropdown({
    Name = "Trait 3",
    SaveKey = "sab_road_trait_3",
    Options = roadTraitOptions,
    Default = "None",
    Callback = function(value)
        roadSpawnerState.selectedTrait3 = value
    end,
})

RoadSpawnerSection:AddSlider({
    Name = "Walk Speed",
    SaveKey = "sab_road_speed",
    Min = 2,
    Max = 30,
    Default = 8,
    Precision = 0,
    Callback = function(value)
        roadSpawnerState.walkSpeed = value
    end,
})

RoadSpawnerSection:AddButton({
    Name = "Spawn on Road",
    Callback = function()
        spawnRoadBrainrot()
    end,
})

RoadSpawnerSection:AddButton({
    Name = "Clear Road Brainrots",
    Callback = function()
        destroyRoadBrainrots()
    end,
})
end
do
    local ok, err = pcall(__sab_base_spawners_scope)
    if not ok then
        --warn("[SAB] BASE SPAWNERS init failed:", err)
    end
end
end -- end BASE SPAWNERS scope

-- ==================================================
-- PLAYER ESP TOGGLES
-- ==================================================
PlayerEspSection:AddToggle({ Name = "Box ESP", SaveKey = "sab_box_esp", Default = false,
    Callback = function(s) safeESP(ESP.SetBoxEsp, s) end
})
PlayerEspSection:AddToggle({ Name = "Name ESP", SaveKey = "sab_name_esp", Default = false,
    Callback = function(s) safeESP(ESP.SetNameEsp, s) end
})
PlayerEspSection:AddToggle({ Name = "Health ESP", SaveKey = "sab_health_esp", Default = false,
    Callback = function(s) safeESP(ESP.SetHealthEsp, s) end
})
PlayerEspSection:AddToggle({ Name = "Team ESP", SaveKey = "sab_team_esp", Default = false,
    Callback = function(s) safeESP(ESP.SetTeamEsp, s) end
})
PlayerEspSection:AddToggle({ Name = "Tracers", SaveKey = "sab_tracers", Default = false,
    Callback = function(s) safeESP(ESP.SetTracers, s) end
})
PlayerEspSection:AddToggle({ Name = "Skeleton ESP", SaveKey = "sab_skeleton_esp", Default = true,
    Callback = function(s) safeESP(ESP.SetSkeletonEsp, s) end
})
PlayerEspSection:AddToggle({ Name = "Held Item ESP", SaveKey = "sab_held_item_esp", Default = false,
    Callback = function(s) safeESP(ESP.SetHeldItemEsp, s) end
})

-- ==================================================
-- BRAINROT ESP TOGGLES
-- ==================================================
local function safeBR(fn, v)
    if BrainrotESP then pcall(fn, BrainrotESP, v) end
end

BrainrotEspSection:AddToggle({ Name = "Brainrot ESP", SaveKey = "sab_brainrot_esp", Default = false,
    Callback = function(s)
        if BrainrotESP then
            pcall(function()
                if s then BrainrotESP:Start() else BrainrotESP:Stop() end
            end)
        end
    end
})
local highlightColorDefault = Color3.fromRGB(50, 180, 255)
local hlToggle = BrainrotEspSection:AddToggle({ Name = "Highlight", SaveKey = "sab_br_highlight", Default = true,
    Callback = function(s) safeBR(BrainrotESP.SetHighlight, s) end
})
safeBR(BrainrotESP.SetHighlightColor, highlightColorDefault)

local highlightColorPickerConfig = {
    Name = "Highlight Color",
    SaveKey = "sab_br_hl_col",
    Default = highlightColorDefault,
    Callback = function(c) safeBR(BrainrotESP.SetHighlightColor, c) end
}

addToggleColorPicker(BrainrotEspSection, hlToggle, highlightColorPickerConfig)
BrainrotEspSection:AddToggle({ Name = "Name ESP", SaveKey = "sab_br_name", Default = false,
    Callback = function(s) safeBR(BrainrotESP.SetName, s) end
})
BrainrotEspSection:AddToggle({ Name = "Money Per/s", SaveKey = "sab_br_money", Default = false,
    Callback = function(s) safeBR(BrainrotESP.SetMoney, s) end
})
BrainrotEspSection:AddToggle({ Name = "Tracers", SaveKey = "sab_br_tracers", Default = false,
    Callback = function(s) safeBR(BrainrotESP.SetTracers, s) end
})
BrainrotEspSection:AddDropdown({
    Name = "Filter",
    SaveKey = "sab_br_filter",
    Options = { "Most Expensive Only", "All" },
    Default = "All",
    Callback = function(v) safeBR(BrainrotESP.SetFilterMode, v) end
})
BrainrotEspSection:AddToggle({
    Name = "Most Expensive In Current Base",
    SaveKey = "sab_br_current_base_only",
    Default = false,
    Callback = function(s) safeBR(BrainrotESP.SetCurrentBaseOnly, s) end
})

-- ==================================================
-- WORLD VISUALS
-- ==================================================
local Lighting = game:GetService("Lighting")
local UserSettings = settings()
local WorldSection = VisualsMenu:AddSection({ Name = "WORLD VISUALS", Column = 2 })
local BETTER_GRAPHICS_SKY_ID = "rbxassetid://6000000000"

local originalLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    ClockTime = Lighting.ClockTime,
}

local betterGraphicsState = {
    connection = nil,
    original = nil,
    customSky = nil,
    createdEffects = {},
}

local function getRenderingQuality()
    local ok, quality = pcall(function()
        return UserSettings.Rendering.QualityLevel
    end)
    if ok then
        return quality
    end
    return nil
end

local function setRenderingQuality(level)
    pcall(function()
        if UserSettings and UserSettings.Rendering and UserSettings.Rendering.QualityLevel ~= level then
            UserSettings.Rendering.QualityLevel = level
        end
    end)
end

local function captureLightingState()
    local function captureEffect(className, props)
        local instance = Lighting:FindFirstChildOfClass(className)
        if not instance then
            return nil
        end
        local data = { instance = instance, properties = {} }
        for _, prop in ipairs(props) do
            data.properties[prop] = instance[prop]
        end
        return data
    end

    local skies = {}
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("Sky") then
            table.insert(skies, child:Clone())
        end
    end

    return {
        renderingQuality = getRenderingQuality(),
        lightingProps = {
            Technology = Lighting.Technology,
            GlobalShadows = Lighting.GlobalShadows,
            ClockTime = Lighting.ClockTime,
            Brightness = Lighting.Brightness,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
            EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        },
        skies = skies,
        effects = {
            Atmosphere = captureEffect("Atmosphere", { "Density", "Haze", "Color", "Offset" }),
            BloomEffect = captureEffect("BloomEffect", { "Enabled", "Intensity", "Size", "Threshold" }),
            ColorCorrectionEffect = captureEffect("ColorCorrectionEffect", { "Enabled", "TintColor", "Saturation", "Contrast" }),
            DepthOfFieldEffect = captureEffect("DepthOfFieldEffect", { "Enabled", "FarIntensity", "InFocusRadius" }),
        },
    }
end

local function getOrCreateLightingEffect(className)
    local effect = Lighting:FindFirstChildOfClass(className)
    if not effect then
        effect = Instance.new(className)
        effect.Parent = Lighting
        betterGraphicsState.createdEffects[className] = true
    end
    return effect
end

local function applyBetterGraphicsSettings()
    setRenderingQuality(Enum.QualityLevel.Level21)

    Lighting.Technology = Enum.Technology.Future
    Lighting.GlobalShadows = true
    Lighting.ClockTime = 22
    Lighting.Brightness = 2.2
    Lighting.Ambient = Color3.fromRGB(60, 50, 80)
    Lighting.OutdoorAmbient = Color3.fromRGB(80, 70, 100)
    Lighting.EnvironmentDiffuseScale = 2.5
    Lighting.EnvironmentSpecularScale = 3.0

    if not betterGraphicsState.customSky or betterGraphicsState.customSky.Parent ~= Lighting then
        if betterGraphicsState.customSky then
            betterGraphicsState.customSky:Destroy()
        end
        for _, sky in ipairs(Lighting:GetChildren()) do
            if sky:IsA("Sky") then
                sky:Destroy()
            end
        end
        local clientSky = Instance.new("Sky")
        clientSky.Name = "ClientDeepSpaceSky"
        clientSky.SkyboxBk = BETTER_GRAPHICS_SKY_ID
        clientSky.SkyboxDn = BETTER_GRAPHICS_SKY_ID
        clientSky.SkyboxFt = BETTER_GRAPHICS_SKY_ID
        clientSky.SkyboxLf = BETTER_GRAPHICS_SKY_ID
        clientSky.SkyboxRt = BETTER_GRAPHICS_SKY_ID
        clientSky.SkyboxUp = BETTER_GRAPHICS_SKY_ID
        clientSky.Parent = Lighting
        betterGraphicsState.customSky = clientSky
    end

    local atmosphere = getOrCreateLightingEffect("Atmosphere")
    atmosphere.Density = 0.25
    atmosphere.Haze = 1.2
    atmosphere.Color = Color3.fromRGB(110, 120, 135)
    atmosphere.Offset = 0.05

    local bloom = getOrCreateLightingEffect("BloomEffect")
    bloom.Enabled = true
    bloom.Intensity = 0.2
    bloom.Size = 24
    bloom.Threshold = 1.9

    local colorCorrection = getOrCreateLightingEffect("ColorCorrectionEffect")
    colorCorrection.Enabled = true
    colorCorrection.TintColor = Color3.fromRGB(230, 240, 255)
    colorCorrection.Saturation = 0.2
    colorCorrection.Contrast = 0.25

    local depthOfField = getOrCreateLightingEffect("DepthOfFieldEffect")
    depthOfField.Enabled = true
    depthOfField.FarIntensity = 0.35
    depthOfField.InFocusRadius = 120
end

local function enableBetterGraphics()
    if betterGraphicsState.original then
        return
    end

    betterGraphicsState.original = captureLightingState()
    applyBetterGraphicsSettings()

    if betterGraphicsState.connection then
        betterGraphicsState.connection:Disconnect()
    end

    betterGraphicsState.connection = RunService.Heartbeat:Connect(applyBetterGraphicsSettings)
end

local function disableBetterGraphics()
    if betterGraphicsState.connection then
        betterGraphicsState.connection:Disconnect()
        betterGraphicsState.connection = nil
    end

    if betterGraphicsState.customSky then
        betterGraphicsState.customSky:Destroy()
        betterGraphicsState.customSky = nil
    end

    if betterGraphicsState.original then
        for prop, value in pairs(betterGraphicsState.original.lightingProps) do
            Lighting[prop] = value
        end

        if betterGraphicsState.original.renderingQuality then
            setRenderingQuality(betterGraphicsState.original.renderingQuality)
        end

        for _, sky in ipairs(Lighting:GetChildren()) do
            if sky:IsA("Sky") then
                sky:Destroy()
            end
        end
        for _, skyClone in ipairs(betterGraphicsState.original.skies or {}) do
            skyClone.Parent = Lighting
        end

        for _, data in pairs(betterGraphicsState.original.effects) do
            local instance = data and data.instance
            if instance and instance.Parent ~= Lighting then
                instance.Parent = Lighting
            end
            if instance and data.properties then
                for prop, value in pairs(data.properties) do
                    instance[prop] = value
                end
            end
        end
    end

    for effectClass, created in pairs(betterGraphicsState.createdEffects) do
        if created then
            local inst = Lighting:FindFirstChildOfClass(effectClass)
            if inst then
                inst:Destroy()
            end
        end
    end

    betterGraphicsState.createdEffects = {}
    betterGraphicsState.original = nil
end

WorldSection:AddToggle({ Name = "Better Graphics", SaveKey = "sab_better_graphics", Default = false,
    Callback = function(s)
        if s then
            enableBetterGraphics()
        else
            disableBetterGraphics()
        end
    end
})

WorldSection:AddToggle({ Name = "Fullbright", SaveKey = "sab_fullbright", Default = false,
    Callback = function(s)
        if s then
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.Brightness = 2
            Lighting.FogEnd = 1e9
            Lighting.FogStart = 1e9
            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") then
                    v.Enabled = false
                end
            end
        else
            Lighting.Ambient = originalLighting.Ambient
            Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
            Lighting.Brightness = originalLighting.Brightness
            Lighting.FogEnd = originalLighting.FogEnd
            Lighting.FogStart = originalLighting.FogStart
            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") then
                    v.Enabled = true
                end
            end
        end
    end
})

WorldSection:AddSlider({ Name = "Time of Day", SaveKey = "sab_time",
    Min = 0, Max = 24, Default = 14, Precision = 1,
    Callback = function(v)
        Lighting.ClockTime = v
    end
})

-- ==================================================
-- SILENT AIM (Aimbot) — ported from bootstrap.lua
-- ==================================================
UserInputService = game:GetService("UserInputService")
PlayerMouseModule = nil
NetModule = nil
pcall(function()
    PlayerMouseModule = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("PlayerMouse"))
end)
pcall(function()
    NetModule = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"))
end)
Aimbot = {
    enabled = false,
    allWeaponsEnabled = true,
    toolConns = {},
    containerConns = {},
    charAddedConn = nil,
    fovRadius = 200,
    fovCircle = nil,
    fovConn = nil,
    fovGui = nil,
    fovFrame = nil,
    fovTextDrawing = nil,
    fovTextLabel = nil,
    currentTargetName = "None",
    targetUpdateConn = nil,
    lastLabelUpdate = 0,
    mouseOverrideConn = nil,
    activationWindow = 0.85,
    shotState = {
        tool = nil,
        target = nil,
        expiresAt = 0,
    },
    learnedRemotes = {},
    useItemProxyCache = {},
    hookInstalled = false,
    hookFailed = false,
}

local function disconnectConn(conn)
    if conn and typeof(conn) == "RBXScriptConnection" then
        conn:Disconnect()
    end
end

function Aimbot:useFovMode()
    return not UserInputService.TouchEnabled
end

function Aimbot:destroyFovCircle()
    disconnectConn(self.fovConn)
    self.fovConn = nil
    disconnectConn(self.targetUpdateConn)
    self.targetUpdateConn = nil
    if self.fovTextDrawing then
        pcall(function()
            if self.fovTextDrawing.Remove then self.fovTextDrawing:Remove()
            else self.fovTextDrawing:Destroy() end
        end)
        self.fovTextDrawing = nil
    end
    if self.fovTextLabel then
        pcall(function() self.fovTextLabel:Destroy() end)
        self.fovTextLabel = nil
    end
    if self.fovFrame then
        pcall(function() self.fovFrame:Destroy() end)
        self.fovFrame = nil
    end
    if self.fovCircle then
        pcall(function()
            if self.fovCircle.Remove then self.fovCircle:Remove()
            else self.fovCircle:Destroy() end
        end)
        self.fovCircle = nil
    end
    if self.fovGui then
        pcall(function() self.fovGui:Destroy() end)
        self.fovGui = nil
    end
end

function Aimbot:createFovCircle()
    self:destroyFovCircle()
    if not self:useFovMode() then return end

    -- Try Drawing API first
    if typeof(Drawing) == "table" and typeof(Drawing.new) == "function" then
        local ok, circle = pcall(Drawing.new, "Circle")
        if ok and circle then
            circle.Filled = false
            circle.NumSides = 64
            circle.Thickness = 1.5
            circle.Transparency = 0.4
            circle.Color = Color3.fromRGB(120, 180, 255)
            circle.Radius = self.fovRadius or 200
            self.fovCircle = circle
            local textOk, textObj = pcall(Drawing.new, "Text")
            if textOk and textObj then
                textObj.Center = true
                textObj.Outline = true
                textObj.Size = 16
                textObj.Transparency = 0.9
                textObj.Color = circle.Color
                textObj.Text = "Target: " .. (self.currentTargetName or "None")
                self.fovTextDrawing = textObj
            end
            self.fovConn = RunService.RenderStepped:Connect(function()
                if not (self.enabled and self.fovCircle) then return end
                local cam = workspace.CurrentCamera
                if not cam then
                    self.fovCircle.Visible = false
                    if self.fovTextDrawing then self.fovTextDrawing.Visible = false end
                    return
                end
                local mousePos = UserInputService:GetMouseLocation()
                local radius = self.fovRadius or 200
                self.fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
                self.fovCircle.Radius = radius
                self.fovCircle.Visible = true
                if self.fovTextDrawing then
                    self.fovTextDrawing.Position = Vector2.new(mousePos.X, mousePos.Y + radius + 12)
                    self.fovTextDrawing.Text = "Target: " .. (self.currentTargetName or "None")
                    self.fovTextDrawing.Visible = true
                end
            end)
            return
        end
    end

    -- Fallback: ScreenGui circle
    local gui = Instance.new("ScreenGui")
    gui.Name = "AimbotFOV"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = hiddenUiParent
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset((self.fovRadius or 200) * 2, (self.fovRadius or 200) * 2)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Parent = gui
    self.fovFrame = frame
    local label = Instance.new("TextLabel")
    label.AnchorPoint = Vector2.new(0.5, 0)
    label.Position = UDim2.new(0.5, 0, 1, 6)
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(120, 180, 255)
    label.TextStrokeTransparency = 0.1
    label.Text = "Target: " .. (self.currentTargetName or "None")
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.Parent = frame
    self.fovTextLabel = label
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(120, 180, 255)
    stroke.Transparency = 0.4
    stroke.Parent = frame
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame
    self.fovGui = gui
    self.fovConn = RunService.RenderStepped:Connect(function()
        if not self.enabled then return end
        local mousePos = UserInputService:GetMouseLocation()
        local radius = self.fovRadius or 200
        frame.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
        frame.Size = UDim2.fromOffset(radius * 2, radius * 2)
        if self.fovTextLabel then
            self.fovTextLabel.Text = "Target: " .. (self.currentTargetName or "None")
        end
    end)
end

function Aimbot:updateTargetLabel(target)
    local name = "None"
    if target and target.Parent then
        name = target.Parent.Name or "None"
    end
    self.currentTargetName = name
    if self.fovTextDrawing then
        self.fovTextDrawing.Text = "Target: " .. name
        self.fovTextDrawing.Visible = self.enabled
    end
    if self.fovTextLabel then
        self.fovTextLabel.Text = "Target: " .. name
    end
end

function Aimbot:getHRP()
    local char = lp and lp.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

function Aimbot:getCharacterAimParts(char)
    if not char then
        return {}
    end

    local orderedNames = {
        "Head",
        "HumanoidRootPart",
        "UpperTorso",
        "Torso",
        "LowerTorso",
    }
    local seen = {}
    local parts = {}

    for _, partName in ipairs(orderedNames) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            seen[part] = true
            table.insert(parts, part)
        end
    end

    if #parts == 0 then
        for _, desc in ipairs(char:GetChildren()) do
            if desc:IsA("BasePart") and not seen[desc] then
                table.insert(parts, desc)
            end
        end
    end

    return parts
end

function Aimbot:getPrimaryAimPart(char)
    local parts = self:getCharacterAimParts(char)
    return parts[1]
end

function Aimbot:findTarget(maxDistance)
    if self:useFovMode() then
        return self:getFovTarget(maxDistance)
    end
    local myHRP = self:getHRP()
    if not myHRP then return nil end
    local best, bestDist
    for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
        if plr ~= lp then
            local char = plr.Character
            local aimPart = char and self:getPrimaryAimPart(char)
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if aimPart and hum and hum.Health > 0 then
                local dist = (aimPart.Position - myHRP.Position).Magnitude
                if (not maxDistance or dist <= maxDistance) and (not bestDist or dist < bestDist) then
                    best = aimPart
                    bestDist = dist
                end
            end
        end
    end
    return best
end

function Aimbot:getFovTarget(maxDistance)
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local myHRP = self:getHRP()
    if not myHRP then return nil end
    local mousePos = UserInputService:GetMouseLocation()
    local center = Vector2.new(mousePos.X, mousePos.Y)
    local best, bestScreenDist, bestWorldDist
    local radius = self.fovRadius or 200

    for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
        if plr ~= lp then
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if char and hum and hum.Health > 0 then
                for _, part in ipairs(self:getCharacterAimParts(char)) do
                    local worldPos, onScreen = cam:WorldToViewportPoint(part.Position)
                    local dist3d = (part.Position - myHRP.Position).Magnitude
                    if (not maxDistance or dist3d <= maxDistance) and onScreen and worldPos.Z > 0 then
                        local screenDist = (Vector2.new(worldPos.X, worldPos.Y) - center).Magnitude
                        if screenDist <= radius then
                            if not best
                                or screenDist < bestScreenDist
                                or (screenDist == bestScreenDist and dist3d < (bestWorldDist or math.huge)) then
                                best = part
                                bestScreenDist = screenDist
                                bestWorldDist = dist3d
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

function Aimbot:getNearestEnemy(maxDistance)
    local target = self:findTarget(maxDistance)
    self:updateTargetLabel(target)
    return target
end

function Aimbot:isProbablyMeleeTool(tool)
    if not (tool and tool:IsA("Tool")) then
        return false
    end
    local name = string.lower(tool.Name or "")
    local blocked = {
        "bat", "sword", "knife", "blade", "hammer", "pickaxe", "medusa", "boogie",
        "trap", "mine", "bomb", "shield", "fist", "glove", "lantern",
    }
    for _, token in ipairs(blocked) do
        if string.find(name, token, 1, true) then
            return true
        end
    end
    return false
end

function Aimbot:isSupportedTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    if not self.allWeaponsEnabled then
        return false
    end
    if self:isProbablyMeleeTool(tool) then
        return false
    end
    return true
end

function Aimbot:getEquippedTool()
    local char = lp and lp.Character
    if not char then
        return nil
    end
    return char:FindFirstChildOfClass("Tool")
end

function Aimbot:getToolKey(tool)
    if not (tool and tool:IsA("Tool")) then
        return nil
    end
    local name = tostring(tool.Name or "")
    if name == "" then
        return nil
    end
    return string.lower(name)
end

function Aimbot:applyPlayerMouseOverride(target)
    if type(PlayerMouseModule) ~= "table" then
        return
    end
    if not (target and target.Parent) then
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    local lookVector = camera.CFrame.LookVector
    if lookVector.Magnitude < 0.001 then
        lookVector = Vector3.new(0, 0, -1)
    end

    PlayerMouseModule.Hit = CFrame.lookAt(target.Position, target.Position + lookVector)
    PlayerMouseModule.Target = target
end

function Aimbot:describeRemote(selfRemote, method)
    local fullName = tostring(selfRemote)
    if typeof(selfRemote) == "Instance" then
        local ok, resolved = pcall(function()
            return selfRemote:GetFullName()
        end)
        if ok and type(resolved) == "string" and resolved ~= "" then
            fullName = resolved
        end
    end
    return string.format("%s [%s]", tostring(fullName), tostring(method))
end

function Aimbot:rememberRemote(tool, selfRemote, method)
    local toolKey = self:getToolKey(tool)
    if not toolKey then
        return
    end
    local bucket = self.learnedRemotes[toolKey]
    if type(bucket) ~= "table" then
        bucket = {
            instances = {},
            labels = {},
        }
        self.learnedRemotes[toolKey] = bucket
    end
    if bucket.instances[selfRemote] then
        return
    end
    bucket.instances[selfRemote] = true
    local label = self:describeRemote(selfRemote, method)
    table.insert(bucket.labels, label)
    --warn(string.format("[SAB] Silent Aim learned %s -> %s", tool.Name, label))
end

function Aimbot:isLearnedRemote(tool, selfRemote)
    local toolKey = self:getToolKey(tool)
    local bucket = toolKey and self.learnedRemotes[toolKey]
    return type(bucket) == "table" and bucket.instances[selfRemote] == true
end

function Aimbot:armShot(tool)
    if not self.enabled then
        return
    end
    if not self:isSupportedTool(tool) then
        return
    end
    local target = self:getNearestEnemy(nil)
    if not target then
        return
    end
    self.shotState.tool = tool
    self.shotState.target = target
    self.shotState.expiresAt = os.clock() + (self.activationWindow or 0.85)
end

function Aimbot:getActiveShotTarget()
    if not (self.enabled and self.allWeaponsEnabled) then
        return nil
    end
    if (self.shotState.expiresAt or 0) < os.clock() then
        return nil
    end
    local equippedTool = self:getEquippedTool()
    if not equippedTool or equippedTool ~= self.shotState.tool then
        return nil
    end
    local target = self:findTarget(nil)
    if not target then
        target = self.shotState.target
    end
    if target and target.Parent then
        local hum = target.Parent:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            self.shotState.target = target
            return target
        end
    end
    target = self:getNearestEnemy(nil)
    self.shotState.target = target
    return target
end

function Aimbot:getLiveSupportedTarget()
    if not (self.enabled and self.allWeaponsEnabled) then
        return nil
    end
    local equippedTool = self:getEquippedTool()
    if not self:isSupportedTool(equippedTool) then
        return nil
    end
    local target = self:findTarget(nil)
    if target and target.Parent then
        local hum = target.Parent:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            self.shotState.tool = equippedTool
            self.shotState.target = target
            return target
        end
    end
    return self.shotState.target
end

function Aimbot:rewriteArgForTarget(arg, target, tool)
    local argType = typeof(arg)
    if argType == "Vector3" then
        return target.Position, true
    end
    if argType == "CFrame" then
        return CFrame.new(target.Position), true
    end
    if argType == "Ray" then
        local origin = arg.Origin
        local direction = target.Position - origin
        if direction.Magnitude < 0.001 then
            direction = target.CFrame.LookVector
        end
        return Ray.new(origin, direction), true
    end
    if argType == "Instance" then
        local char = lp and lp.Character
        if (tool and arg:IsDescendantOf(tool)) or (char and arg:IsDescendantOf(char)) then
            return arg, false
        end
        if arg:IsA("Humanoid") then
            return target.Parent and target.Parent:FindFirstChildOfClass("Humanoid") or arg, true
        end
        if arg:IsA("Attachment") then
            local targetAttachment = target:FindFirstChild("RootAttachment") or target:FindFirstChildWhichIsA("Attachment")
            return targetAttachment or arg, true
        end
        return target, true
    end
    return arg, false
end

function Aimbot:rewriteRemoteArgs(args, target)
    local changed = false
    local rewritten = table.create(#args)
    local tool = self.shotState.tool
    for i = 1, #args do
        local newArg, didChange = self:rewriteArgForTarget(args[i], target, tool)
        rewritten[i] = newArg
        if didChange then
            changed = true
        end
    end
    return rewritten, changed
end

function Aimbot:shouldRewriteRemote(selfRemote, args)
    if not (selfRemote and typeof(selfRemote) == "Instance") then
        return false
    end

    local tool = self.shotState.tool
    if tool and self:isLearnedRemote(tool, selfRemote) then
        return true
    end

    local remoteName = string.lower(tostring(selfRemote.Name or ""))
    local remoteHintTokens = {
        "shoot", "fire", "hit", "damage", "cast", "projectile", "bullet",
        "gun", "web", "laser", "paint", "throw", "use",
    }
    for _, token in ipairs(remoteHintTokens) do
        if string.find(remoteName, token, 1, true) then
            return true
        end
    end

    local char = lp and lp.Character
    for _, arg in ipairs(args) do
        local argType = typeof(arg)
        if argType == "Vector3" or argType == "CFrame" or argType == "Ray" then
            return true
        end
        if argType == "Instance" then
            if arg:IsA("BasePart") or arg:IsA("Model") or arg:IsA("Humanoid") or arg:IsA("Attachment") then
                if not ((tool and arg:IsDescendantOf(tool)) or (char and arg:IsDescendantOf(char))) then
                    return true
                end
            end
        end
    end

    return false
end

function Aimbot:ensureHook()
    if self.hookInstalled or self.hookFailed then
        return
    end
    if type(hookfunction) ~= "function" then
        self.hookFailed = true
        --warn("[SAB] Silent Aim hook unavailable in this executor")
        return
    end
    sabSilentAimRewriteRemoteArgs = function(selfRemote, args, method)
        if not (Aimbot.enabled and Aimbot.allWeaponsEnabled) then
            return nil
        end
        if method ~= "FireServer" and method ~= "InvokeServer" then
            return nil
        end
        if not (typeof(selfRemote) == "Instance" and (selfRemote:IsA("RemoteEvent") or selfRemote:IsA("UnreliableRemoteEvent") or selfRemote:IsA("RemoteFunction"))) then
            return nil
        end
        local target = Aimbot:getActiveShotTarget()
        if not target then
            return nil
        end
        if Aimbot.shotState.tool and Aimbot:shouldRewriteRemote(selfRemote, args) then
            Aimbot:rememberRemote(Aimbot.shotState.tool, selfRemote, method)
        end
        if not Aimbot:shouldRewriteRemote(selfRemote, args) then
            return nil
        end
        local rewritten, changed = Aimbot:rewriteRemoteArgs(args, target)
        if not changed then
            return nil
        end
        return rewritten
    end
    self.hookInstalled = true
end

function Aimbot:getUseItemProxy(remote)
    if not remote then
        return remote
    end
    local cached = self.useItemProxyCache[remote]
    if cached then
        return cached
    end

    local aimbot = self
    local proxy = {
        _remote = remote,
        Name = remote.Name,
        ClassName = remote.ClassName,
        Parent = remote.Parent,
    }

    function proxy:GetFullName()
        return remote:GetFullName()
    end

    function proxy:FireServer(...)
        local args = { ... }
        local target = aimbot:getLiveSupportedTarget()
        if target then
            aimbot:applyPlayerMouseOverride(target)
            local rewritten, changed = aimbot:rewriteRemoteArgs(args, target)
            if changed then
                return remote:FireServer(unpack(rewritten))
            end
        end
        return remote:FireServer(...)
    end

    self.useItemProxyCache[remote] = proxy
    return proxy
end

function Aimbot:ensureNetUseItemProxy()
    if not (type(NetModule) == "table" and type(NetModule.RemoteEvent) == "function") then
        return
    end
    if NetModule.__sabSilentUseItemProxyInstalled then
        return
    end

    local originalRemoteEvent = NetModule.RemoteEvent
    NetModule.RemoteEvent = function(netSelf, endpoint, waitTimeout)
        local remote = originalRemoteEvent(netSelf, endpoint, waitTimeout)
        if endpoint == "UseItem" then
            return Aimbot:getUseItemProxy(remote)
        end
        return remote
    end
    NetModule.__sabSilentUseItemProxyInstalled = true
end

function Aimbot:startMouseOverride()
    if self.mouseOverrideConn or type(PlayerMouseModule) ~= "table" then
        return
    end
    self.mouseOverrideConn = RunService.RenderStepped:Connect(function()
        if not (self.enabled and self.allWeaponsEnabled) then
            return
        end
        local equippedTool = self:getEquippedTool()
        if not self:isSupportedTool(equippedTool) then
            return
        end
        local target = self:getLiveSupportedTarget()
        if target then
            self.shotState.target = target
            self:applyPlayerMouseOverride(target)
        end
    end)
end

function Aimbot:stopMouseOverride()
    disconnectConn(self.mouseOverrideConn)
    self.mouseOverrideConn = nil
end

function Aimbot:bindTool(tool)
    if not tool or not tool:IsA("Tool") or self.toolConns[tool] then
        return
    end
    self.toolConns[tool] = tool.Activated:Connect(function()
        self:armShot(tool)
    end)
    tool.Destroying:Connect(function()
        disconnectConn(self.toolConns[tool])
        self.toolConns[tool] = nil
    end)
end

function Aimbot:watchContainer(container)
    if not container then return end
    for _, child in ipairs(container:GetChildren()) do
        self:bindTool(child)
    end
    local conn = container.ChildAdded:Connect(function(obj)
        self:bindTool(obj)
    end)
    table.insert(self.containerConns, conn)
end

function Aimbot:start()
    if self.enabled then return end
    self:ensureHook()
    self:ensureNetUseItemProxy()
    self.enabled = true
    self:updateTargetLabel(nil)
    self:createFovCircle()
    self:startMouseOverride()
    self.shotState.tool = nil
    self.shotState.target = nil
    self.shotState.expiresAt = 0

    disconnectConn(self.targetUpdateConn)
    self.lastLabelUpdate = 0
    self.targetUpdateConn = RunService.RenderStepped:Connect(function()
        if not self.enabled then return end
        local now = workspace:GetServerTimeNow()
        if now - (self.lastLabelUpdate or 0) < 0.05 then return end
        self.lastLabelUpdate = now
        local target = self:findTarget(nil)
        self:updateTargetLabel(target)
    end)

    local char = lp and lp.Character
    self:watchContainer(char)
    self:watchContainer(lp and lp:FindFirstChildOfClass("Backpack"))

    disconnectConn(self.charAddedConn)
    if lp then
        self.charAddedConn = lp.CharacterAdded:Connect(function(newChar)
            for _, c in ipairs(self.containerConns) do
                disconnectConn(c)
            end
            table.clear(self.containerConns)
            self:watchContainer(newChar)
            self:watchContainer(lp:FindFirstChildOfClass("Backpack"))
        end)
    end
end

function Aimbot:stop()
    self.enabled = false
    self:updateTargetLabel(nil)
    self:destroyFovCircle()
    self:stopMouseOverride()
    disconnectConn(self.targetUpdateConn)
    self.targetUpdateConn = nil
    disconnectConn(self.charAddedConn)
    self.charAddedConn = nil
    self.shotState.tool = nil
    self.shotState.target = nil
    self.shotState.expiresAt = 0

    for _, conn in pairs(self.toolConns) do disconnectConn(conn) end
    self.toolConns = {}

    for _, conn in ipairs(self.containerConns) do disconnectConn(conn) end
    table.clear(self.containerConns)
end

-- ==================================================
-- MEDUSA COUNTER
-- ==================================================
local medusaCounterEnabled = false
local medusaCounterConn = nil
local medusaToolConns = {}
local lastCounterUse = 0

local function isMedusaToolName(name)
    if not name then return false end
    local lowered = name:lower()
    return lowered:find("medusa") ~= nil or lowered:find("boogie") ~= nil
end

local function getCounterTool()
    local char = lp and lp.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and isMedusaToolName(item.Name) then
                return item
            end
        end
    end
    local backpack = lp and lp:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and isMedusaToolName(item.Name) then
                return item
            end
        end
    end
    return nil
end

local function activateCounterTool()
    local tool = getCounterTool()
    if not tool then return false end
    local now = workspace:GetServerTimeNow()
    if now - lastCounterUse <= 1.5 then return false end
    local char = lp and lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    if tool.Parent ~= char then
        pcall(function() hum:EquipTool(tool) end)
    end
    pcall(function() tool:Activate() end)
    lastCounterUse = now
    task.delay(0.35, function()
        local h = lp and lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if h then pcall(function() h:UnequipTools() end) end
    end)
    return true
end

local function startMedusaCounter()
    if medusaCounterConn then return end
    medusaCounterEnabled = true
    medusaCounterConn = RunService.Heartbeat:Connect(function()
        if not medusaCounterEnabled then return end
        local myChar = lp and lp.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
            if plr ~= lp then
                local ch = plr.Character
                if ch then
                    local hrp = ch:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local hasMedusa = false
                        for _, item in ipairs(ch:GetChildren()) do
                            if item:IsA("Tool") and isMedusaToolName(item.Name) then
                                hasMedusa = true
                                break
                            end
                        end
                        if hasMedusa then
                            local dist = (hrp.Position - myHRP.Position).Magnitude
                            if dist <= 5 then
                                activateCounterTool()
                                return
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function stopMedusaCounter()
    medusaCounterEnabled = false
    if medusaCounterConn then
        medusaCounterConn:Disconnect()
        medusaCounterConn = nil
    end
end

-- ==================================================
-- RAGE PAGE UI
-- ==================================================
SilentAimSection:AddToggle({
    Name = "Silent Aim",
    SaveKey = "sab_silent_aim",
    Default = false,
    Callback = function(value)
        if value then
            Aimbot:start()
        else
            Aimbot:stop()
        end
    end,
})

SilentAimSection:AddToggle({
    Name = "All Supported Weapons",
    SaveKey = "sab_aim_supported",
    Default = true,
    Callback = function(value)
        Aimbot.allWeaponsEnabled = value == true
    end,
})

SilentAimSection:AddSlider({
    Name = "FOV Radius",
    SaveKey = "sab_aim_fov",
    Min = 50,
    Max = 600,
    Default = 200,
    Precision = 0,
    Callback = function(value)
        Aimbot.fovRadius = value
        if Aimbot.fovCircle then
            Aimbot.fovCircle.Radius = value
        end
    end,
})

CombatSection:AddToggle({
    Name = "Medusa Counter",
    SaveKey = "sab_medusa_counter",
    Default = false,
    Callback = function(value)
        if value then
            startMedusaCounter()
        else
            stopMedusaCounter()
        end
    end,
})

do -- STEALER: INVISIBLE scope
if not pcall(function()
-- ==================================================
-- STEALER: INVISIBLE — ported from bootstrap.lua
-- ==================================================
do
local Invisible = {
    enabled = false,
    heartbeat = nil,
    charConn = nil,
    healthConn = nil,
    anim = nil,
    track = nil,
    animId = "rbxassetid://112089880074848",
    posOffset = Vector3.new(0, -2.6, 0),
    rotOffset = Vector3.new(-160, 0, 0),
    playbackTime = 3.05,
}

function Invisible:loadTrack(hum)
    if not hum then return end
    if not self.anim then
        self.anim = Instance.new("Animation")
        self.anim.AnimationId = self.animId
    end
    local loader = hum:FindFirstChildOfClass("Animator") or hum
    if loader then
        self.track = loader:LoadAnimation(self.anim)
    end
end

function Invisible:cleanupTrack()
    if self.track then
        pcall(function() self.track:Stop() end)
        pcall(function() self.track:Destroy() end)
    end
    if self.anim then
        pcall(function() self.anim:Destroy() end)
    end
    self.track = nil
    self.anim = nil
end

function Invisible:attachHealthGuard(char)
    if self.healthConn and typeof(self.healthConn) == "RBXScriptConnection" then
        self.healthConn:Disconnect()
    end
    self.healthConn = nil
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    self.healthConn = hum.HealthChanged:Connect(function(health)
        if self.enabled and health < 100 then
            hum.Health = 100
        end
    end)
end

function Invisible:start()
    if self.heartbeat then return end
    self.enabled = true
    local char = lp and lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    self:loadTrack(hum)
    self:attachHealthGuard(char)

    if self.charConn and typeof(self.charConn) == "RBXScriptConnection" then
        self.charConn:Disconnect()
    end
    if lp then
        self.charConn = lp.CharacterAdded:Connect(function(newChar)
            self:attachHealthGuard(newChar)
            local newHum = newChar:WaitForChild("Humanoid", 5)
            self:loadTrack(newHum)
        end)
    end

    self.heartbeat = RunService.Heartbeat:Connect(function()
        if not self.enabled then return end
        local c = lp and lp.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not (c and h and hrp and h.Health > 0) then return end

        local originalCFrame = hrp.CFrame
        local originalVelocity = hrp.AssemblyLinearVelocity

        if self.track then
            self.track:Stop()
            if not self.track.Parent then
                self:loadTrack(h)
            end
            if self.track then
                self.track:Play(0.01, 1, 0)
                self.track.TimePosition = self.playbackTime
            end
        end

        local spoofed = originalCFrame
            * CFrame.new(self.posOffset)
            * CFrame.Angles(math.rad(self.rotOffset.X), math.rad(self.rotOffset.Y), math.rad(self.rotOffset.Z))

        hrp.CFrame = spoofed
        RunService.RenderStepped:Wait()
        hrp.CFrame = originalCFrame
        hrp.AssemblyLinearVelocity = originalVelocity
    end)
end

function Invisible:stop()
    self.enabled = false
    if self.heartbeat and typeof(self.heartbeat) == "RBXScriptConnection" then
        self.heartbeat:Disconnect()
    end
    if self.charConn and typeof(self.charConn) == "RBXScriptConnection" then
        self.charConn:Disconnect()
    end
    if self.healthConn and typeof(self.healthConn) == "RBXScriptConnection" then
        self.healthConn:Disconnect()
    end
    self.heartbeat = nil
    self.charConn = nil
    self.healthConn = nil
    self:cleanupTrack()
end

StealerSection:AddToggle({
    Name = "Invisible",
    SaveKey = "sab_invisible",
    Default = false,
    Callback = function(value)
        if value then Invisible:start() else Invisible:stop() end
    end,
})
end
end) then
    --warn("[SAB] STEALER Invisible init failed")
end
end


-- ==================================================
-- STEALER: AUTO KICK ON STEAL
-- ==================================================
do
if not pcall(function()
local autoKickState = {
    enabled = false,
    minRarity = "Common",
    uiConn = nil,
    uiChangedConns = {},
    remoteConn = nil,
}

local rarityOrder = {
    ["Common"] = 1, ["Uncommon"] = 2, ["Rare"] = 3, ["Epic"] = 4,
    ["Legendary"] = 5, ["Mythic"] = 6, ["Secret"] = 7, ["Divine"] = 8, ["Exclusive"] = 9,
}

local function getRarityRank(rarityName)
    if type(rarityName) ~= "string" then return 0 end
    if rarityOrder[rarityName] then return rarityOrder[rarityName] end
    for key, rank in pairs(rarityOrder) do
        if key:lower() == rarityName:lower() then return rank end
    end
    return 0
end

local function buildRarityOptions()
    local ordered = {}
    for key, rank in pairs(rarityOrder) do
        table.insert(ordered, { name = key, rank = rank })
    end
    table.sort(ordered, function(a, b) return a.rank < b.rank end)
    local opts = {}
    for _, entry in ipairs(ordered) do
        table.insert(opts, entry.name)
    end
    return opts
end

local function passesRarityFilter(brainrotIndex)
    if not brainrotIndex or type(brainrotIndex) ~= "string" then return true end
    local animalInfo = type(AnimalsData) == "table" and AnimalsData[brainrotIndex] or nil
    if type(animalInfo) ~= "table" then return true end
    local rarity = animalInfo.Rarity
    if type(rarity) ~= "string" then return true end

    local function resolveRank(rarityName)
        if type(rarityName) ~= "string" then
            return 0
        end

        local directRank = rarityOrder[rarityName]
        if directRank then
            return directRank
        end

        local lowered = string.lower(rarityName)
        for key, rank in pairs(rarityOrder) do
            if string.lower(key) == lowered then
                return rank
            end
        end

        return 0
    end

    return resolveRank(rarity) >= resolveRank(autoKickState.minRarity)
end

local function stripRichText(text)
    if type(text) ~= "string" then return "" end
    return text:gsub("%b<>", "")
end

local function extractStolenName(text)
    if type(text) ~= "string" then return nil end
    local plain = stripRichText(text)
    local match = plain:match("[Yy]ou%s+[Ss]tole%s+(.*)")
    if not match or match == "" then return nil end
    return match:gsub("^%s+", ""):gsub("%s+$", "")
end

local function resolveStolenBrainrotIndex(...)
    local args = { ... }
    for _, arg in ipairs(args) do
        if type(arg) == "table" then
            local index = arg.Index or arg.Name or arg.Brainrot or arg.DisplayName or arg[1]
            if type(index) == "string" and index ~= "" then return index end
        elseif type(arg) == "string" and arg ~= "" then
            return arg
        end
    end
    if lp then
        local attr = lp:GetAttribute("StealingIndex") or lp:GetAttribute("StealingName")
        if type(attr) == "string" and attr ~= "" then return attr end
    end
    return nil
end

local function getKickDisplayName(index)
    if type(index) ~= "string" then return "a Brainrot" end
    local data = type(AnimalsData) == "table" and AnimalsData[index] or nil
    if type(data) == "table" and type(data.DisplayName) == "string" and data.DisplayName ~= "" then
        return data.DisplayName
    end
    return index
end

local function kickSelf(brainrotIndex)
    local displayName = getKickDisplayName(brainrotIndex)
    if lp and typeof(lp.Kick) == "function" then
        lp:Kick("You Stole " .. displayName)
    end
end

local function watchStealUiLabel(inst)
    if not inst then return end
    if not (inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox")) then return end
    local function check()
        if not autoKickState.enabled then return end
        local txt = inst.Text
        if type(txt) ~= "string" or txt == "" then return end
        if txt:lower():find("you stole") then
            local stolenName = extractStolenName(txt) or "Brainrot"
            local foundIndex = nil
            if type(AnimalsData) == "table" then
                for key, data in pairs(AnimalsData) do
                    if type(data) == "table" and type(data.DisplayName) == "string" then
                        if data.DisplayName:lower() == stolenName:lower() or key:lower() == stolenName:lower() then
                            foundIndex = key
                            break
                        end
                    end
                end
            end
            if passesRarityFilter(foundIndex) then
                kickSelf(foundIndex or stolenName)
            end
        end
    end
    check()
    if autoKickState.uiChangedConns[inst] then
        autoKickState.uiChangedConns[inst]:Disconnect()
    end
    autoKickState.uiChangedConns[inst] = inst:GetPropertyChangedSignal("Text"):Connect(check)
    inst.Destroying:Connect(function()
        if autoKickState.uiChangedConns[inst] then
            autoKickState.uiChangedConns[inst]:Disconnect()
            autoKickState.uiChangedConns[inst] = nil
        end
    end)
end

local function startAutoKickOnSteal()
    if autoKickState.enabled then return end
    autoKickState.enabled = true
    task.spawn(function()
        local gui = lp and (lp:FindFirstChild("PlayerGui") or lp:WaitForChild("PlayerGui", 5))
        if not gui then return end
        for _, desc in ipairs(gui:GetDescendants()) do
            watchStealUiLabel(desc)
        end
        if autoKickState.uiConn and typeof(autoKickState.uiConn) == "RBXScriptConnection" then
            autoKickState.uiConn:Disconnect()
        end
        autoKickState.uiConn = gui.DescendantAdded:Connect(function(inst)
            watchStealUiLabel(inst)
        end)
    end)
    local stealRemote = findRemoteByName("RemoteEvent", function(inst)
        local n = inst.Name:lower()
        return n:find("steal") and (n:find("success") or n:find("stolen") or n:find("grab"))
    end)
    if stealRemote and stealRemote.OnClientEvent then
        if autoKickState.remoteConn and typeof(autoKickState.remoteConn) == "RBXScriptConnection" then
            autoKickState.remoteConn:Disconnect()
        end
        autoKickState.remoteConn = stealRemote.OnClientEvent:Connect(function(...)
            if not autoKickState.enabled then return end
            local brainrotIndex = resolveStolenBrainrotIndex(...)
            if passesRarityFilter(brainrotIndex) then
                kickSelf(brainrotIndex)
            end
        end)
    end
end

local function stopAutoKickOnSteal()
    autoKickState.enabled = false
    if autoKickState.uiConn and typeof(autoKickState.uiConn) == "RBXScriptConnection" then
        autoKickState.uiConn:Disconnect()
        autoKickState.uiConn = nil
    end
    if autoKickState.remoteConn and typeof(autoKickState.remoteConn) == "RBXScriptConnection" then
        autoKickState.remoteConn:Disconnect()
        autoKickState.remoteConn = nil
    end
    for inst, conn in pairs(autoKickState.uiChangedConns) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
        autoKickState.uiChangedConns[inst] = nil
    end
end

StealerSection:AddToggle({
    Name = "Auto Kick On Steal",
    SaveKey = "sab_auto_kick_steal",
    Default = false,
    Callback = function(value)
        if value then startAutoKickOnSteal() else stopAutoKickOnSteal() end
    end,
})

StealerSection:AddDropdown({
    Name = "Min Rarity to Kick",
    SaveKey = "sab_kick_min_rarity",
    Options = buildRarityOptions(),
    Default = "Common",
    Callback = function(value)
        autoKickState.minRarity = value
    end,
})
end)
then
    --warn("[SAB] STEALER AutoKick init failed")
end

-- ==================================================
-- STEALER: SENTRY DESTROYER - ported from bootstrap.lua
-- ==================================================
end

if not pcall(function()
    local function isPlayerMatch(val)
        if val == nil then return false end
        if val == lp then return true end
        local asStr = tostring(val)
        if asStr == (lp and lp.Name) or asStr == tostring(lp and lp.UserId) then return true end
        local num = tonumber(val)
        return num ~= nil and lp ~= nil and num == lp.UserId
    end

    local BrainrotPurchaseSection = StealerMenu:AddSection({ Name = "BRAINROT PURCHASE", Column = 1 })
    local BrainrotPurchase = {
        enabled = false,
        selectAll = true,
        minMoneyPerSec = 0,
        selectedBrainrots = {},
        selectedRarities = {},
        loopThread = nil,
        currentTargetUid = nil,
        attemptedUids = {},
        purchasedUids = {},
    }
    local brainrotPurchaseHelpers = {}
    local brainrotPurchaseDropdown = nil
    local HttpService = game:GetService("HttpService")
    local brainrotPurchaseMinOptions = {
        { label = "Any", value = 0 },
        { label = "10K", value = 10000 },
        { label = "100K", value = 100000 },
        { label = "500K", value = 500000 },
        { label = "1M", value = 1000000 },
        { label = "5M", value = 5000000 },
        { label = "10M", value = 10000000 },
    }

    local function cloneList(values)
        local copy = {}
        for i, value in ipairs(values) do
            copy[i] = value
        end
        return copy
    end

    function brainrotPurchaseHelpers.buildMinLabels()
        local labels = {}
        for _, option in ipairs(brainrotPurchaseMinOptions) do
            table.insert(labels, option.label)
        end
        return labels
    end

    function brainrotPurchaseHelpers.resolveMinValue(label)
        for _, option in ipairs(brainrotPurchaseMinOptions) do
            if option.label == label then
                return option.value
            end
        end
        return 0
    end

    function brainrotPurchaseHelpers.buildSelectedSet(values)
        local selected = {}
        if type(values) == "table" then
            for _, value in ipairs(values) do
                selected[tostring(value)] = true
            end
        end
        return selected
    end

    function brainrotPurchaseHelpers.buildDynamicRarityOptions()
        local entries = {}
        if type(RaritiesData) == "table" then
            for rarityName, rarityInfo in pairs(RaritiesData) do
                if type(rarityName) == "string" and rarityName ~= "" then
                    table.insert(entries, {
                        name = rarityName,
                        weight = tonumber(type(rarityInfo) == "table" and rarityInfo.Weight) or math.huge,
                    })
                end
            end
        end
        if #entries == 0 then
            local fallback = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Divine", "Exclusive" }
            for _, rarityName in ipairs(fallback) do
                table.insert(entries, { name = rarityName, weight = math.huge })
            end
        end
        table.sort(entries, function(a, b)
            if a.weight == b.weight then
                return string.lower(a.name) < string.lower(b.name)
            end
            return a.weight < b.weight
        end)
        local options = {}
        for _, entry in ipairs(entries) do
            table.insert(options, entry.name)
        end
        return options
    end

    function brainrotPurchaseHelpers.buildBrainrotOptions()
        local optionSet = {}
        if type(AnimalsData) == "table" then
            for brainrotName, info in pairs(AnimalsData) do
                if type(brainrotName) == "string" and brainrotName ~= "" and type(info) == "table" then
                    optionSet[brainrotName] = true
                end
            end
        end
        local options = {}
        for brainrotName in pairs(optionSet) do
            table.insert(options, brainrotName)
        end
        table.sort(options, function(a, b)
            local ad = string.lower(tostring(getDisplayName(a)))
            local bd = string.lower(tostring(getDisplayName(b)))
            if ad == bd then
                return tostring(a) < tostring(b)
            end
            return ad < bd
        end)
        return #options > 0 and options or { "Unknown" }
    end

    function brainrotPurchaseHelpers.decodeTraits(raw)
        if type(raw) == "table" then
            return raw
        end
        if type(raw) == "string" and raw ~= "" then
            local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
            if ok and type(decoded) == "table" then
                return decoded
            end
        end
        return nil
    end

    function brainrotPurchaseHelpers.getPromptPart(prompt)
        if not (prompt and prompt:IsA("ProximityPrompt")) then
            return nil
        end
        local parent = prompt.Parent
        if parent and parent:IsA("Attachment") then
            parent = parent.Parent
        end
        if parent and parent:IsA("BasePart") then
            return parent
        end
        return prompt:FindFirstAncestorWhichIsA("BasePart")
    end

    function brainrotPurchaseHelpers.isRoadPrompt(prompt)
        if not (prompt and prompt:IsA("ProximityPrompt") and prompt:IsDescendantOf(workspace)) then
            return false
        end
        local model = prompt:FindFirstAncestorWhichIsA("Model")
        if not (model and model.Parent) then
            return false
        end
        if model:FindFirstChild("CreateClientWeld") then
            return false
        end
        local brainrotIndex = model:GetAttribute("Index") or prompt:GetAttribute("Index")
        if type(brainrotIndex) ~= "string" or brainrotIndex == "" then
            return false
        end
        return true, model, brainrotIndex
    end

    local function buildPurchaseCandidate(prompt)
        local okPrompt, model, brainrotIndex = brainrotPurchaseHelpers.isRoadPrompt(prompt)
        if not okPrompt then return nil end
        local uid = tostring(prompt:GetAttribute("UID") or model:GetAttribute("UID") or model.Name)
        if BrainrotPurchase.purchasedUids[uid] then return nil end
        if BrainrotPurchase.attemptedUids[uid] and tick() - BrainrotPurchase.attemptedUids[uid] < 8 then return nil end
        if prompt:GetAttribute("Disabled") == true then return nil end

        local targetPlayer = prompt:GetAttribute("TargetPlayer")
        if targetPlayer ~= nil and targetPlayer ~= "" then
            if isPlayerMatch(targetPlayer) then BrainrotPurchase.purchasedUids[uid] = true end
            return nil
        end
        if not BrainrotPurchase.selectAll and not BrainrotPurchase.selectedBrainrots[brainrotIndex] then return nil end

        local promptPart = brainrotPurchaseHelpers.getPromptPart(prompt)
        if not promptPart then return nil end
        local mutation = model:GetAttribute("Mutation")
        if type(mutation) ~= "string" or mutation == "" then mutation = nil end
        local traits = brainrotPurchaseHelpers.decodeTraits(model:GetAttribute("Traits"))
        local moneyPerSec = math.max(0, tonumber(getMoneyPerSec({ Index = brainrotIndex, Mutation = mutation, Traits = traits })) or 0)
        if moneyPerSec < BrainrotPurchase.minMoneyPerSec then return nil end

        local animalInfo = type(AnimalsData) == "table" and AnimalsData[brainrotIndex] or nil
        local rarityName = type(animalInfo) == "table" and tostring(animalInfo.Rarity or "Unknown") or "Unknown"
        if not BrainrotPurchase.selectedRarities[rarityName] then return nil end

        local myChar = lp and lp.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local distance = myHrp and (promptPart.Position - myHrp.Position).Magnitude or math.huge
        return { uid = uid, prompt = prompt, model = model, part = promptPart, index = brainrotIndex, displayName = getDisplayName(brainrotIndex), rarity = rarityName, moneyPerSec = moneyPerSec, distance = distance }
    end

    local function findBestPurchaseCandidate()
        local bestCandidate = nil
        for _, prompt in ipairs(CollectionService:GetTagged("AnimalPurchasePrompt")) do
            local candidate = buildPurchaseCandidate(prompt)
            if candidate and (not bestCandidate or candidate.moneyPerSec > bestCandidate.moneyPerSec or (candidate.moneyPerSec == bestCandidate.moneyPerSec and candidate.distance < bestCandidate.distance)) then
                bestCandidate = candidate
            end
        end
        return bestCandidate
    end

    local function moveToPurchaseTarget(candidate)
        local deadline = tick() + 12
        while BrainrotPurchase.enabled and tick() < deadline do
            local char = lp and lp.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not (humanoid and hrp and candidate.prompt and candidate.prompt.Parent) then return false end
            if candidate.prompt:GetAttribute("Disabled") == true then return false end
            local targetPlayer = candidate.prompt:GetAttribute("TargetPlayer")
            if targetPlayer ~= nil and targetPlayer ~= "" then
                if isPlayerMatch(targetPlayer) then BrainrotPurchase.purchasedUids[candidate.uid] = true end
                return false
            end
            local promptPart = brainrotPurchaseHelpers.getPromptPart(candidate.prompt)
            if not promptPart then return false end
            local distance = (promptPart.Position - hrp.Position).Magnitude
            local activationDistance = math.max(6, tonumber(candidate.prompt.MaxActivationDistance) or 10)
            if distance <= activationDistance + 1.5 then return true end
            humanoid:MoveTo(promptPart.Position)
            task.wait(0.15)
        end
        return false
    end

    local function triggerPurchasePrompt(prompt)
        if not (prompt and prompt.Parent) then return false end
        return pcall(function()
            if fireproximityprompt then
                fireproximityprompt(prompt)
            else
                prompt:InputHoldBegin()
                task.wait((tonumber(prompt.HoldDuration) or 0) + 0.1)
                if prompt and prompt.Parent then prompt:InputHoldEnd() end
            end
        end)
    end

    function BrainrotPurchase:start()
        if self.loopThread then return end
        self.enabled = true
        self.loopThread = task.spawn(function()
            while self.enabled do
                for uid, lastAttempt in pairs(self.attemptedUids) do
                    if tick() - lastAttempt > 20 then self.attemptedUids[uid] = nil end
                end
                local candidate = findBestPurchaseCandidate()
                if candidate then
                    self.currentTargetUid = candidate.uid
                    self.attemptedUids[candidate.uid] = tick()
                    if moveToPurchaseTarget(candidate) then
                        if triggerPurchasePrompt(candidate.prompt) then self.purchasedUids[candidate.uid] = true end
                        task.wait(0.8)
                    else
                        task.wait(0.3)
                    end
                    self.currentTargetUid = nil
                else
                    task.wait(0.35)
                end
            end
            self.loopThread = nil
            self.currentTargetUid = nil
        end)
    end

    function BrainrotPurchase:stop()
        self.enabled = false
        self.currentTargetUid = nil
    end

    local brainrotPurchaseBrainrotOptions = brainrotPurchaseHelpers.buildBrainrotOptions()
    local brainrotPurchaseRarityOptions = brainrotPurchaseHelpers.buildDynamicRarityOptions()
    BrainrotPurchase.selectedBrainrots = brainrotPurchaseHelpers.buildSelectedSet(brainrotPurchaseBrainrotOptions)
    BrainrotPurchase.selectedRarities = brainrotPurchaseHelpers.buildSelectedSet(brainrotPurchaseRarityOptions)

    BrainrotPurchaseSection:AddToggle({ Name = "Enable Brainrot Purchase", SaveKey = "sab_brainrot_purchase_enabled", Default = false, Callback = function(value) if value then BrainrotPurchase:start() else BrainrotPurchase:stop() end end })
    BrainrotPurchaseSection:AddToggle({ Name = "All Brainrots", SaveKey = "sab_brainrot_purchase_all", Default = true, Callback = function(value) BrainrotPurchase.selectAll = value == true if brainrotPurchaseDropdown and brainrotPurchaseDropdown.SetDisabled then brainrotPurchaseDropdown:SetDisabled(value == true) end end })
    brainrotPurchaseDropdown = BrainrotPurchaseSection:AddMultiDropdown({
        Name = "Brainrot Filter",
        SaveKey = "sab_brainrot_purchase_filter",
        Options = brainrotPurchaseBrainrotOptions,
        Default = brainrotPurchaseBrainrotOptions,
        Callback = function(values, selectedSet)
            local selected = selectedSet
            if type(selected) ~= "table" then
                selected = brainrotPurchaseHelpers.buildSelectedSet(values)
            end
            BrainrotPurchase.selectedBrainrots = selected
        end
    })
    if brainrotPurchaseDropdown and brainrotPurchaseDropdown.SetDisabled then brainrotPurchaseDropdown:SetDisabled(true) end
    BrainrotPurchaseSection:AddDropdown({ Name = "Minimum /s", SaveKey = "sab_brainrot_purchase_min_per_sec", Options = brainrotPurchaseHelpers.buildMinLabels(), Default = "Any", Callback = function(value) BrainrotPurchase.minMoneyPerSec = brainrotPurchaseHelpers.resolveMinValue(value) end })
    BrainrotPurchaseSection:AddMultiDropdown({
        Name = "Rarity Filter",
        SaveKey = "sab_brainrot_purchase_rarity_filter",
        Options = brainrotPurchaseRarityOptions,
        Default = brainrotPurchaseRarityOptions,
        Callback = function(values, selectedSet)
            local selected = selectedSet
            if type(selected) ~= "table" then
                selected = brainrotPurchaseHelpers.buildSelectedSet(values)
            end
            BrainrotPurchase.selectedRarities = selected
        end
    })
end) then
    --warn("[SAB] Brainrot Purchase init failed")
end

if not pcall(function()
    local function isPlayerMatch(val)
        if val == nil then return false end
        if val == lp then return true end
        local asStr = tostring(val)
        if asStr == (lp and lp.Name) or asStr == tostring(lp and lp.UserId) then return true end
        local num = tonumber(val)
        return num ~= nil and lp ~= nil and num == lp.UserId
    end

    local SENTRY_TOOL_NAME = "Bat"
    local SentryDestroyer = { enabled = false, hitOnce = {}, attemptedIds = {}, tracked = {}, ownerCache = {}, touchCache = {}, queue = {}, queueSet = {}, conns = {}, sentryConns = {}, ancestryConns = {}, processing = false }

    local function isMySentry(inst)
        if not inst then return false end
        local ownerTag = inst:FindFirstChild("Owner") or inst:FindFirstChild("Creator") or inst:FindFirstChild("Player") or inst:FindFirstChild("Placer")
        if ownerTag and ownerTag:IsA("ValueBase") and isPlayerMatch(ownerTag.Value) then return true end
        local ownerKeys = { "Owner", "OwnerUserId", "OwnerId", "PlacerUserId", "Creator", "PlacedBy", "UserId" }
        for _, key in ipairs(ownerKeys) do if isPlayerMatch(inst:GetAttribute(key)) then return true end end
        if lp and lp.Name and inst:GetFullName():lower():find(lp.Name:lower(), 1, true) then return true end
        return false
    end

    local function isSentryRoot(inst) return inst and string.match(inst.Name or "", "^Sentry_%d+") ~= nil end
    local function hasTouchTransmitter(model) return model and (model:FindFirstChild("TouchInterest", true) or model:FindFirstChildWhichIsA("TouchTransmitter", true)) end

    local function shouldAttemptTurret(model)
        if not model then return false end
        local owned = SentryDestroyer.ownerCache[model]
        if owned == nil then owned = isMySentry(model); SentryDestroyer.ownerCache[model] = owned end
        if owned then SentryDestroyer.hitOnce[model] = true; return false end
        if SentryDestroyer.hitOnce[model] then return false end
        return true
    end

    local function markSentryAttempted(model) if model then SentryDestroyer.hitOnce[model] = true end end

    local function getSentryDestroyTool()
        local backpack = lp and lp:FindFirstChildOfClass("Backpack")
        local char = lp and lp.Character
        local tool = backpack and backpack:FindFirstChild(SENTRY_TOOL_NAME)
        if not tool and char then tool = char:FindFirstChild(SENTRY_TOOL_NAME) end
        if not tool then
            for _, item in ipairs((char and char:GetChildren()) or {}) do if item:IsA("Tool") and (item.Name or ""):lower():find("bat") then tool = item; break end end
            if not tool and backpack then
                for _, item in ipairs(backpack:GetChildren()) do if item:IsA("Tool") and (item.Name or ""):lower():find("bat") then tool = item; break end end
            end
        end
        return tool
    end

    local function getToolHandle(tool) return tool and (tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")) end

    local function getTurretTargetPart(model)
        if not model then return nil end
        if model:IsA("BasePart") then return model end
        local transmitter = model:FindFirstChildWhichIsA("TouchTransmitter", true)
        if transmitter and transmitter.Parent and transmitter.Parent:IsA("BasePart") then return transmitter.Parent end
        if model.PrimaryPart then return model.PrimaryPart end
        return model:FindFirstChildWhichIsA("BasePart", true)
    end

    local function swingAtSentry(handle, target)
        if not (handle and target and target:IsA("BasePart")) then return false end
        if not (handle:IsDescendantOf(workspace) and target:IsDescendantOf(workspace)) then return false end
        if typeof(firetouchinterest) ~= "function" then return false end
        pcall(firetouchinterest, handle, target, 0)
        pcall(firetouchinterest, handle, target, 1)
        return true
    end

    local function attackEnemySentries(enemies)
        if #enemies == 0 then return 0 end
        local tool = getSentryDestroyTool()
        if not tool then --[[warn("[SentryDestroyer] Bat not found")]] return 0 end
        local handle = getToolHandle(tool)
        if not handle then return 0 end
        local char = lp and lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local backpack = lp and lp:FindFirstChildOfClass("Backpack")
        if hum and backpack and tool.Parent == backpack then hum:EquipTool(tool) end
        task.wait(0.1)
        if typeof(tool.Activate) == "function" then tool:Activate() end
        local hits = 0
        for _, enemy in ipairs(enemies) do
            local target = getTurretTargetPart(enemy)
            markSentryAttempted(enemy)
            if target and swingAtSentry(handle, target) then hits = hits + 1 end
        end
        task.wait(0.9)
        if backpack and char and tool.Parent == char then tool.Parent = backpack end
        return hits
    end

    function SentryDestroyer:start()
        if self.enabled then return end
        self.enabled = true
        table.clear(self.queue); table.clear(self.queueSet)
        table.clear(self.tracked); table.clear(self.touchCache)
        table.clear(self.ownerCache); table.clear(self.attemptedIds)
        self.processing = false
        for key, conn in pairs(self.conns) do if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end self.conns[key] = nil end
        local function trackSentry(model)
            if not (self.enabled and model and isSentryRoot(model)) then return end
            if self.tracked[model] then return end
            self.tracked[model] = true
            if not shouldAttemptTurret(model) then return end
            self.touchCache[model] = hasTouchTransmitter(model) and true or false
            if self.touchCache[model] then self:enqueue(model) end
            self.sentryConns[model] = model.DescendantAdded:Connect(function(desc)
                if not self.enabled then return end
                if desc:IsA("TouchInterest") or desc:IsA("TouchTransmitter") then self.touchCache[model] = true; self:enqueue(model) end
            end)
            self.ancestryConns[model] = model.AncestryChanged:Connect(function(_, parent) if not parent then self:untrack(model) end end)
        end
        self.conns.workspaceAdded = workspace.ChildAdded:Connect(function(obj) trackSentry(obj) end)
        self.conns.workspaceRemoved = workspace.ChildRemoved:Connect(function(obj) if self.tracked[obj] then self:untrack(obj) end end)
        for _, obj in ipairs(workspace:GetChildren()) do trackSentry(obj) end
    end

    function SentryDestroyer:stop()
        self.enabled = false
        for key, conn in pairs(self.conns) do if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end self.conns[key] = nil end
        for model, conn in pairs(self.sentryConns) do if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end self.sentryConns[model] = nil end
        for model, conn in pairs(self.ancestryConns) do if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end self.ancestryConns[model] = nil end
        table.clear(self.queue); table.clear(self.queueSet)
        table.clear(self.tracked); table.clear(self.touchCache); table.clear(self.ownerCache)
        self.processing = false
    end

    function SentryDestroyer:untrack(model)
        if not model then return end
        self.tracked[model] = nil; self.queueSet[model] = nil
        self.touchCache[model] = nil; self.ownerCache[model] = nil
        if self.sentryConns[model] then if typeof(self.sentryConns[model]) == "RBXScriptConnection" then self.sentryConns[model]:Disconnect() end self.sentryConns[model] = nil end
        if self.ancestryConns[model] then if typeof(self.ancestryConns[model]) == "RBXScriptConnection" then self.ancestryConns[model]:Disconnect() end self.ancestryConns[model] = nil end
    end

    function SentryDestroyer:enqueue(model)
        if not (self.enabled and model) then return end
        if self.queueSet[model] then return end
        if not shouldAttemptTurret(model) then return end
        self.queueSet[model] = true
        table.insert(self.queue, model)
        self:processQueue()
    end

    function SentryDestroyer:processQueue()
        if self.processing then return end
        self.processing = true
        task.spawn(function()
            if not self.enabled then self.processing = false; return end
            local enemies, retry = {}, {}
            while #self.queue > 0 do
                local model = table.remove(self.queue, 1)
                self.queueSet[model] = nil
                if model and model.Parent and isSentryRoot(model) and shouldAttemptTurret(model) then
                    local hasTouch = self.touchCache[model]
                    if hasTouch == nil then hasTouch = hasTouchTransmitter(model) and true or false; self.touchCache[model] = hasTouch end
                    if hasTouch then table.insert(enemies, model) else table.insert(retry, model) end
                end
            end
            if #enemies > 0 then local hits = attackEnemySentries(enemies) if hits > 0 then --[[warn("[SentryDestroyer] Attacked", hits, "targets")]] end end
            self.processing = false
            if not self.enabled then return end
            if #retry > 0 then task.delay(0.25, function() if not self.enabled then return end for _, model in ipairs(retry) do self:enqueue(model) end end) end
            if #self.queue > 0 then self:processQueue() end
        end)
    end

    CombatStealerSection:AddToggle({ Name = "Sentry Destroyer", SaveKey = "sab_sentry_destroyer", Default = false, Callback = function(value) if value then SentryDestroyer:start() else SentryDestroyer:stop() end end })
end) then
    --warn("[SAB] STEALER Sentry init failed")
end
StealerSection:AddToggle({
    Name = "Fake Lag",
    SaveKey = "sab_fake_lag",
    Default = false,
    Callback = function(value)
        -- Placeholder: no logic yet
    end,
})

StealerSection:AddDropdown({
    Name = "Fake Lag Mode",
    SaveKey = "sab_fake_lag_mode",
    Options = { "Aggressive", "Normal", "Minimal", "Adaptive" },
    Default = "Normal",
    Callback = function(value)
        -- Placeholder: no logic yet
    end,
})

do -- WORLD VISUALS scope
if not pcall(function()
-- ==================================================
-- WORLD VISUALS UI
-- ==================================================
local lowPolyOriginals = {}
local lowPolyActive = false

local function saveLowPolyOriginals()
    if next(lowPolyOriginals) ~= nil then return end -- already saved
    local g = game
    local w = g.Workspace
    local l = g.Lighting
    local t = w.Terrain

    lowPolyOriginals._terrain = {
        WaterWaveSize = t.WaterWaveSize,
        WaterWaveSpeed = t.WaterWaveSpeed,
        WaterReflectance = t.WaterReflectance,
        WaterTransparency = t.WaterTransparency,
    }
    lowPolyOriginals._lighting = {
        GlobalShadows = l.GlobalShadows,
        FogEnd = l.FogEnd,
        Brightness = l.Brightness,
    }
    lowPolyOriginals._renderQuality = nil
    pcall(function()
        lowPolyOriginals._renderQuality = settings().Rendering.QualityLevel
    end)
    lowPolyOriginals._effects = {}
    for _, e in pairs(l:GetChildren()) do
        if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect")
            or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
            lowPolyOriginals._effects[e] = e.Enabled
        end
    end
    lowPolyOriginals._parts = {}
    for _, v in pairs(g:GetDescendants()) do
        pcall(function()
            if v:IsA("Part") or v:IsA("Union") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then
                lowPolyOriginals._parts[v] = { Material = v.Material, Reflectance = v.Reflectance }
            elseif v:IsA("Decal") or v:IsA("Texture") then
                lowPolyOriginals._parts[v] = { Transparency = v.Transparency }
            elseif v:IsA("ParticleEmitter") then
                lowPolyOriginals._parts[v] = { Lifetime = v.Lifetime }
            elseif v:IsA("Trail") then
                lowPolyOriginals._parts[v] = { Lifetime = v.Lifetime }
            elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
                lowPolyOriginals._parts[v] = { Enabled = v.Enabled }
            elseif v:IsA("MeshPart") then
                lowPolyOriginals._parts[v] = { Material = v.Material, Reflectance = v.Reflectance, TextureID = v.TextureID }
            end
        end)
    end
end

local function applyLowPoly()
    local g = game
    local w = g.Workspace
    local l = g.Lighting
    local t = w.Terrain

    t.WaterWaveSize = 0
    t.WaterWaveSpeed = 0
    t.WaterReflectance = 0
    t.WaterTransparency = 0
    l.GlobalShadows = false
    l.FogEnd = 9e9
    l.Brightness = 0
    pcall(function() settings().Rendering.QualityLevel = "Level01" end)

    for _, v in pairs(g:GetDescendants()) do
        pcall(function()
            if v:IsA("Part") or v:IsA("Union") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then
                v.Material = "Plastic"
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") then
                v.Lifetime = NumberRange.new(0)
            elseif v:IsA("Trail") then
                v.Lifetime = 0
            elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
                v.Enabled = false
            elseif v:IsA("MeshPart") then
                v.Material = "Plastic"
                v.Reflectance = 0
                v.TextureID = ""
            end
        end)
    end
    for _, e in pairs(l:GetChildren()) do
        if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect")
            or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
            e.Enabled = false
        end
    end
end

local function restoreLowPoly()
    if not next(lowPolyOriginals) then return end
    local g = game
    local w = g.Workspace
    local l = g.Lighting
    local t = w.Terrain

    local to = lowPolyOriginals._terrain
    if to then
        t.WaterWaveSize = to.WaterWaveSize
        t.WaterWaveSpeed = to.WaterWaveSpeed
        t.WaterReflectance = to.WaterReflectance
        t.WaterTransparency = to.WaterTransparency
    end
    local lo = lowPolyOriginals._lighting
    if lo then
        l.GlobalShadows = lo.GlobalShadows
        l.FogEnd = lo.FogEnd
        l.Brightness = lo.Brightness
    end
    if lowPolyOriginals._renderQuality then
        pcall(function() settings().Rendering.QualityLevel = lowPolyOriginals._renderQuality end)
    end
    for inst, props in pairs(lowPolyOriginals._parts or {}) do
        pcall(function()
            if inst and inst.Parent then
                for prop, val in pairs(props) do
                    inst[prop] = val
                end
            end
        end)
    end
    for e, wasEnabled in pairs(lowPolyOriginals._effects or {}) do
        pcall(function()
            if e and e.Parent then e.Enabled = wasEnabled end
        end)
    end
    lowPolyOriginals = {}
end

WorldVisualsSection:AddToggle({
    Name = "Low Poly",
    SaveKey = "sab_low_poly",
    Default = false,
    Callback = function(value)
        if value then
            saveLowPolyOriginals()
            applyLowPoly()
            lowPolyActive = true
        else
            restoreLowPoly()
            lowPolyActive = false
        end
    end,
})
end) then
    --warn("[SAB] WORLD VISUALS init failed")
end
end -- end WORLD VISUALS scope

do -- BASE ESP scope
if not pcall(function()
-- ==================================================
-- BASE ESP
-- ==================================================
local BaseESP = {
    timerEnabled = false,
    cameraNoCollision = false,
    transparency = 0,
    highlightEnabled = false,
    highlightMode = "All",
    highlightBestOwner = false,
    timerGuis = {},
    highlights = {},
    originalTransparency = {},
    originalLocalTransparency = {},
    refreshConn = nil,
}

local PlayersService = game:GetService("Players")

local function getWorkspacePlots()
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then return {} end
    return plotsFolder:GetChildren()
end

local function isMyPlot(plot)
    if not plot then return false end
    local attrOwner = plot:GetAttribute("Owner") or plot:GetAttribute("OwnerName")
    if isLocalOwner(attrOwner) then return true end
    if type(attrOwner) == "string" and attrOwner:lower() == lp.Name:lower() then return true end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        for _, child in ipairs(sign:GetChildren()) do
            if child:IsA("ObjectValue") and child.Value == lp then
                return true
            end
            if child:IsA("StringValue") and type(child.Value) == "string" and child.Value:lower() == lp.Name:lower() then
                return true
            end
            if child:IsA("BoolValue") and child.Name == "YourBase" and child.Value then
                return true
            end
        end
    end
    return false
end

local function getPodiumAnimalName(podium)
    local name = podium:GetAttribute("AnimalIndex") or podium:GetAttribute("Animal") or podium:GetAttribute("Index")
    if name then return name end
    for _, child in ipairs(podium:GetChildren()) do
        if child:IsA("StringValue") and (child.Name == "AnimalIndex" or child.Name == "Animal" or child.Name == "Index") then
            return child.Value
        end
    end
    for _, desc in ipairs(podium:GetDescendants()) do
        if desc:IsA("TextLabel") and desc.Name == "DisplayName" and desc.Text ~= "" then
            return desc.Text
        end
    end
    return nil
end

local function getAnimalPrice(animalName)
    if not animalName then return 0 end
    local price = 0
    pcall(function()
        price = callAnimalsSharedMethod("GetPrice", animalName, lp) or 0
    end)
    if price == 0 then
        pcall(function()
            if type(AnimalsData) == "table" and AnimalsData[animalName] then
                price = AnimalsData[animalName].Price or AnimalsData[animalName].Value or AnimalsData[animalName].Cost or 0
            end
        end)
    end
    return price
end

local function getPlotMaxPriceFromModel(plotModel)
    local podiums = plotModel and plotModel:FindFirstChild("AnimalPodiums")
    if not podiums then return 0 end
    local maxPrice = 0
    for _, podium in ipairs(podiums:GetChildren()) do
        local name = getPodiumAnimalName(podium)
        local price = getAnimalPrice(name)
        if price > maxPrice then maxPrice = price end
    end
    return maxPrice
end

local function getPlotRecords()
    local records = {}
    local gotControllerPlots = false

    if PlotController and type(PlotController.GetPlots) == "function" then
        local ok, plots = pcall(PlotController.GetPlots, PlotController)
        if ok and type(plots) == "table" then
            for uid, plot in pairs(plots) do
                if type(plot) == "table" then
                    local plotModel = rawget(plot, "PlotModel")
                    if typeof(plotModel) == "Instance" and plotModel:IsDescendantOf(workspace) then
                        local owner = getOwner(plot)
                        if not isLocalOwner(owner) then
                            gotControllerPlots = true
                            table.insert(records, {
                                uid = tostring(uid),
                                plotObj = plot,
                                plotModel = plotModel,
                                owner = owner,
                            })
                        end
                    end
                end
            end
        end
    end

    if gotControllerPlots then
        return records
    end

    for _, plotModel in ipairs(getWorkspacePlots()) do
        if not isMyPlot(plotModel) then
            table.insert(records, {
                uid = tostring(plotModel.Name),
                plotObj = nil,
                plotModel = plotModel,
                owner = nil,
            })
        end
    end

    return records
end

local function getPlotChannel(plotObj)
    if type(plotObj) ~= "table" then return nil end
    local channel = rawget(plotObj, "Channel")
    if type(channel) == "table" and type(channel.Get) == "function" then
        return channel
    end
    return nil
end

local function getChannelValue(channel, key)
    if not channel or type(channel.Get) ~= "function" then return nil end
    local ok, value = pcall(channel.Get, channel, key)
    if ok then return value end
    return nil
end

local function getEntryMostExpensiveValue(entry)
    if type(entry) ~= "table" then
        return 0
    end

    local generation = getMoneyPerSec(entry)
    if generation > 0 then
        return generation
    end

    local idx = entry.Index
    if type(idx) == "string" and idx ~= "" then
        local price = callAnimalsSharedMethod("GetPrice", idx, lp)
        if type(price) == "number" and price > 0 then
            return price
        end
    end

    for _, key in ipairs({ "Price", "Value", "Cost", "Worth", "Money", "MoneyPerSec", "Generation" }) do
        local value = entry[key]
        if type(value) == "number" and value > 0 then
            return value
        end
    end

    return 0
end

local function getPlotMostExpensiveValue(record)
    local bestValue = 0
    local channel = getPlotChannel(record.plotObj)
    local animalList = getChannelValue(channel, "AnimalList")
    if type(animalList) == "table" then
        for _, entry in pairs(animalList) do
            if type(entry) == "table" and type(entry.Index) == "string" then
                local value = getEntryMostExpensiveValue(entry)
                if value > bestValue then
                    bestValue = value
                end
            end
        end
    end

    if bestValue <= 0 then
        bestValue = getPlotMaxPriceFromModel(record.plotModel)
    end

    return bestValue
end

local function normalizeRemainingSeconds(rawValue)
    if type(rawValue) ~= "number" then
        return nil
    end
    local now = workspace:GetServerTimeNow()
    if rawValue > 100000000 then
        return rawValue - now
    end
    return rawValue
end

local function getPlotLockSeconds(record)
    local channel = getPlotChannel(record.plotObj)
    for _, key in ipairs({ "BlockEndTime", "BlockedDelayTime", "LockEndTime", "LockTime", "LockTimer", "UnlockTime" }) do
        local remaining = normalizeRemainingSeconds(getChannelValue(channel, key))
        if type(remaining) == "number" then
            return remaining
        end
    end

    local plotModel = record.plotModel
    if typeof(plotModel) == "Instance" then
        for _, key in ipairs({ "BlockEndTime", "BlockedDelayTime", "LockEndTime", "LockTime", "LockTimer", "UnlockTime", "RemainingTime" }) do
            local remaining = normalizeRemainingSeconds(plotModel:GetAttribute(key))
            if type(remaining) == "number" then
                return remaining
            end
        end
    end

    return nil
end

local function formatSeconds(seconds)
    local s = math.max(0, math.floor(seconds + 0.5))
    local h = math.floor(s / 3600)
    local m = math.floor((s % 3600) / 60)
    local sec = s % 60
    if h > 0 then
        return string.format("%d:%02d:%02d", h, m, sec)
    end
    return string.format("%02d:%02d", m, sec)
end

local function getPlotTimerText(record)
    local remaining = getPlotLockSeconds(record)
    if type(remaining) ~= "number" then
        return nil
    end
    if remaining <= 0 then
        return "Open"
    end
    return formatSeconds(remaining)
end

local function resolveTimerAdornee(plotModel)
    if typeof(plotModel) ~= "Instance" then return nil end

    local purchases = plotModel:FindFirstChild("Purchases")
    if purchases then
        for _, purchase in ipairs(purchases:GetChildren()) do
            local main = purchase:FindFirstChild("Main")
            if main and main:IsA("BasePart") and main:FindFirstChild("BillboardGui") then
                return main
            end
        end
        local purchasePart = purchases:FindFirstChildWhichIsA("BasePart", true)
        if purchasePart then
            return purchasePart
        end
    end

    local plotSign = plotModel:FindFirstChild("PlotSign")
    if plotSign then
        local signPart = plotSign:FindFirstChildWhichIsA("BasePart", true)
        if signPart then
            return signPart
        end
    end

    local spawn = plotModel:FindFirstChild("Spawn")
    if spawn and spawn:IsA("BasePart") then
        return spawn
    end

    return plotModel:FindFirstChildWhichIsA("BasePart", true)
end

local function createTimerGui(record)
    local adornee = resolveTimerAdornee(record.plotModel)
    if not adornee then return nil end

    local offsetY = 7
    if record and typeof(record.plotModel) == "Instance" then
        local purchases = record.plotModel:FindFirstChild("Purchases")
        if purchases and adornee:IsDescendantOf(purchases) then
            offsetY = 3.2
        end
    end

    local bg = Instance.new("BillboardGui")
    bg.Name = "BaseESP_Timer"
    bg.Adornee = adornee
    bg.Size = UDim2.new(0, 110, 0, 30)
    bg.StudsOffset = Vector3.new(0, offsetY, 0)
    bg.AlwaysOnTop = true
    bg.ResetOnSpawn = false
    bg.Parent = adornee

    local label = Instance.new("TextLabel")
    label.Name = "TimerLabel"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 100)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextScaled = false
    label.Text = ""
    label.Parent = bg

    return {
        gui = bg,
        label = label,
        record = record,
    }
end

local function updateTimerLabel(label, timerText)
    if not label then return end
    if timerText == "Open" then
        label.TextColor3 = Color3.fromRGB(135, 255, 145)
    else
        label.TextColor3 = Color3.fromRGB(255, 255, 100)
    end
    label.Text = timerText or ""
end

local function getOwnerPlayerFromRecord(record)
    local owner = record and record.owner
    if typeof(owner) == "Instance" and owner:IsA("Player") then
        return owner
    end

    local ownerName = nil
    local ownerUserId = nil
    if type(owner) == "table" then
        if type(owner.Name) == "string" then
            ownerName = owner.Name
        end
        if type(owner.UserId) == "number" then
            ownerUserId = owner.UserId
        end
    elseif type(owner) == "string" then
        ownerName = owner
    elseif type(owner) == "number" then
        ownerUserId = owner
    end

    local plotModel = record and record.plotModel
    if typeof(plotModel) == "Instance" then
        local attrName = plotModel:GetAttribute("OwnerName") or plotModel:GetAttribute("Owner")
        if type(attrName) == "string" and attrName ~= "" then
            ownerName = ownerName or attrName
        end
        local attrUserId = plotModel:GetAttribute("OwnerUserId")
        if type(attrUserId) == "number" then
            ownerUserId = ownerUserId or attrUserId
        end
    end

    local ownerNameLower = type(ownerName) == "string" and ownerName:lower() or nil
    for _, plr in ipairs(PlayersService:GetPlayers()) do
        if ownerUserId and plr.UserId == ownerUserId then
            return plr
        end
        if ownerNameLower and plr.Name:lower() == ownerNameLower then
            return plr
        end
    end

    return nil
end

local function cleanBaseEsp()
    for _, timerEntry in pairs(BaseESP.timerGuis) do
        local gui = timerEntry
        if type(timerEntry) == "table" then
            gui = timerEntry.gui
        end
        pcall(function()
            if gui then
                gui:Destroy()
            end
        end)
    end
    BaseESP.timerGuis = {}
    for _, hl in pairs(BaseESP.highlights) do
        pcall(function() hl:Destroy() end)
    end
    BaseESP.highlights = {}
    for part, original in pairs(BaseESP.originalTransparency) do
        pcall(function() part.Transparency = original end)
    end
    BaseESP.originalTransparency = {}
end

local function clearCameraNoCollisionVisuals()
    for part, original in pairs(BaseESP.originalLocalTransparency) do
        pcall(function()
            if part and part.Parent then
                part.LocalTransparencyModifier = original
            end
        end)
    end
    BaseESP.originalLocalTransparency = {}
end

local function updateCameraNoCollisionVisuals()
    if not BaseESP.cameraNoCollision then
        clearCameraNoCollisionVisuals()
        return
    end

    local camera = workspace.CurrentCamera
    local char = lp and lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not (camera and char and hrp and plotsFolder) then
        clearCameraNoCollisionVisuals()
        return
    end

    local visibleSet = {}
    local ok, obstructingParts = pcall(function()
        return camera:GetPartsObscuringTarget({ camera.CFrame.Position, hrp.Position }, { char })
    end)
    if ok and type(obstructingParts) == "table" then
        for _, part in ipairs(obstructingParts) do
            if part and part:IsA("BasePart") and part:IsDescendantOf(plotsFolder) then
                visibleSet[part] = true
                if BaseESP.originalLocalTransparency[part] == nil then
                    BaseESP.originalLocalTransparency[part] = part.LocalTransparencyModifier
                end
                part.LocalTransparencyModifier = math.max(part.LocalTransparencyModifier, 0.7)
            end
        end
    end

    for part, original in pairs(BaseESP.originalLocalTransparency) do
        if not (part and part.Parent and visibleSet[part]) then
            pcall(function()
                if part and part.Parent then
                    part.LocalTransparencyModifier = original
                end
            end)
            BaseESP.originalLocalTransparency[part] = nil
        end
    end
end

local function refreshBaseEsp()
    cleanBaseEsp()
    local records = getPlotRecords()

    local bestRecord, bestValue = nil, -1
    local trackMostExpensive = BaseESP.highlightBestOwner or (BaseESP.highlightEnabled and BaseESP.highlightMode == "Most Expensive")
    if trackMostExpensive then
        for _, record in ipairs(records) do
            local value = getPlotMostExpensiveValue(record)
            if value > bestValue then
                bestValue = value
                bestRecord = record
            end
        end
    end

    for _, record in ipairs(records) do
        local plotModel = record.plotModel
        if typeof(plotModel) == "Instance" then
            if BaseESP.timerEnabled then
                local timerEntry = createTimerGui(record)
                if timerEntry then
                    table.insert(BaseESP.timerGuis, timerEntry)
                    updateTimerLabel(timerEntry.label, getPlotTimerText(record))
                end
            end

            if BaseESP.transparency > 0 then
                for _, desc in ipairs(plotModel:GetDescendants()) do
                    if desc:IsA("BasePart") then
                        if not BaseESP.originalTransparency[desc] then
                            BaseESP.originalTransparency[desc] = desc.Transparency
                        end
                        desc.Transparency = math.max(desc.Transparency, BaseESP.transparency)
                    end
                end
            end

            if BaseESP.highlightEnabled then
                local shouldHighlight = false
                if BaseESP.highlightMode == "All" then
                    shouldHighlight = true
                elseif BaseESP.highlightMode == "Most Expensive" then
                    shouldHighlight = (record == bestRecord)
                end
                if shouldHighlight then
                    for _, child in ipairs(plotModel:GetChildren()) do
                        if child:IsA("Highlight") and child.Name == "BaseESP_Highlight" then
                            child:Destroy()
                        end
                    end
                    local hl = Instance.new("Highlight")
                    hl.Name = "BaseESP_Highlight"
                    hl.FillColor = Color3.fromRGB(255, 100, 100)
                    hl.FillTransparency = 0.7
                    hl.OutlineColor = Color3.fromRGB(255, 50, 50)
                    hl.OutlineTransparency = 0
                    hl.Adornee = plotModel
                    hl.Parent = plotModel
                    table.insert(BaseESP.highlights, hl)
                end
            end
        end
    end

    if BaseESP.cameraNoCollision then
        updateCameraNoCollisionVisuals()
    else
        clearCameraNoCollisionVisuals()
    end

    if BaseESP.highlightBestOwner and bestRecord then
        local ownerPlayer = getOwnerPlayerFromRecord(bestRecord)
        local character = ownerPlayer and ownerPlayer.Character
        if character and character.Parent then
            local ownerHighlight = Instance.new("Highlight")
            ownerHighlight.Name = "BaseESP_OwnerHighlight"
            ownerHighlight.FillColor = Color3.fromRGB(70, 200, 255)
            ownerHighlight.FillTransparency = 0.72
            ownerHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            ownerHighlight.OutlineTransparency = 0
            ownerHighlight.Adornee = character
            ownerHighlight.Parent = character
            table.insert(BaseESP.highlights, ownerHighlight)
        end
    end
end

local function startBaseEspLoop()
    if BaseESP.refreshConn then return end
    BaseESP.refreshConn = RunService.Heartbeat:Connect(function()
        if BaseESP.timerEnabled then
            for _, timerEntry in pairs(BaseESP.timerGuis) do
                pcall(function()
                    local gui = type(timerEntry) == "table" and timerEntry.gui or timerEntry
                    local label = type(timerEntry) == "table" and timerEntry.label or (gui and gui:FindFirstChild("TimerLabel"))
                    local record = type(timerEntry) == "table" and timerEntry.record or nil
                    if not gui or not gui.Parent then return end
                    if not record or typeof(record.plotModel) ~= "Instance" or not record.plotModel.Parent then return end
                    updateTimerLabel(label, getPlotTimerText(record))
                end)
            end
        end
        if BaseESP.cameraNoCollision then
            updateCameraNoCollisionVisuals()
        else
            clearCameraNoCollisionVisuals()
        end
    end)
end

local function stopBaseEspLoop()
    if BaseESP.refreshConn then
        BaseESP.refreshConn:Disconnect()
        BaseESP.refreshConn = nil
    end
    clearCameraNoCollisionVisuals()
end

-- ==================================================
-- BASE ESP UI
-- ==================================================
BaseEspSection:AddToggle({
    Name = "Timer ESP",
    SaveKey = "sab_base_timer_esp",
    Default = false,
    Callback = function(value)
        BaseESP.timerEnabled = value
        if value then
            startBaseEspLoop()
        elseif not BaseESP.cameraNoCollision then
            stopBaseEspLoop()
        end
        refreshBaseEsp()
    end,
})

BaseEspSection:AddToggle({
    Name = "Camera No Collision",
    SaveKey = "sab_base_no_collision",
    Default = false,
    Callback = function(value)
        BaseESP.cameraNoCollision = value
        if value or BaseESP.timerEnabled then
            startBaseEspLoop()
        else
            stopBaseEspLoop()
        end
        refreshBaseEsp()
    end,
})

BaseEspSection:AddSlider({
    Name = "Base Transparency",
    SaveKey = "sab_base_transparency",
    Min = 0,
    Max = 0.9,
    Default = 0,
    Precision = 1,
    Callback = function(value)
        BaseESP.transparency = value
        refreshBaseEsp()
    end,
})

BaseEspSection:AddToggle({
    Name = "Highlight Bases",
    SaveKey = "sab_base_highlight",
    Default = false,
    Callback = function(value)
        BaseESP.highlightEnabled = value
        refreshBaseEsp()
    end,
})

BaseEspSection:AddToggle({
    Name = "Highlight Most Expensive Base Owner",
    SaveKey = "sab_base_highlight_best_owner",
    Default = false,
    Callback = function(value)
        BaseESP.highlightBestOwner = value
        refreshBaseEsp()
    end,
})

BaseEspSection:AddDropdown({
    Name = "Highlight Filter",
    SaveKey = "sab_base_highlight_filter",
    Options = { "All", "Most Expensive" },
    Default = "All",
    Callback = function(value)
        BaseESP.highlightMode = value
        refreshBaseEsp()
    end,
})
end) then
    --warn("[SAB] BASE ESP init failed")
end
end -- end BASE ESP scope


do -- TRAPS ESP scope
if not pcall(function()
-- ==================================================
-- TRAPS ESP MODULE
-- ==================================================
local TRAP_NAMES = {
    ["BeeHive"] = { color = Color3.fromRGB(255, 200, 0), label = "Bee Hive" },
    ["Bee Hive"] = { color = Color3.fromRGB(255, 200, 0), label = "Bee Hive" },
    ["All Seeing Sentry"] = { color = Color3.fromRGB(0, 200, 255), label = "Sentry" },
    ["Candy Sentry"] = { color = Color3.fromRGB(255, 100, 200), label = "Candy Sentry" },
    ["Cake Trap"] = { color = Color3.fromRGB(255, 150, 180), label = "Cake Trap" },
    ["CakeTrap"] = { color = Color3.fromRGB(255, 150, 180), label = "Cake Trap" },
    ["Dart Trap"] = { color = Color3.fromRGB(200, 50, 50), label = "Dart Trap" },
    ["DartTrap"] = { color = Color3.fromRGB(200, 50, 50), label = "Dart Trap" },
    ["Lotus Trap"] = { color = Color3.fromRGB(100, 255, 100), label = "Lotus Trap" },
    ["LotusTrap"] = { color = Color3.fromRGB(100, 255, 100), label = "Lotus Trap" },
    ["Blackhole Bomb"] = { color = Color3.fromRGB(80, 0, 160), label = "Blackhole" },
    ["BlackholeBomb"] = { color = Color3.fromRGB(80, 0, 160), label = "Blackhole" },
    ["Flashbang"] = { color = Color3.fromRGB(255, 255, 200), label = "Flashbang" },
    ["Decoy Deploy"] = { color = Color3.fromRGB(180, 180, 180), label = "Decoy" },
    ["DecoyDeploy"] = { color = Color3.fromRGB(180, 180, 180), label = "Decoy" },
    ["Holo Decoy"] = { color = Color3.fromRGB(100, 200, 255), label = "Holo Decoy" },
    ["HoloDecoy"] = { color = Color3.fromRGB(100, 200, 255), label = "Holo Decoy" },
    ["Freeze Ray"] = { color = Color3.fromRGB(100, 200, 255), label = "Freeze Ray" },
    ["FreezeRay"] = { color = Color3.fromRGB(100, 200, 255), label = "Freeze Ray" },
    ["Candy Bomb"] = { color = Color3.fromRGB(255, 100, 150), label = "Candy Bomb" },
    ["CandyBomb"] = { color = Color3.fromRGB(255, 100, 150), label = "Candy Bomb" },
    ["Boogie Bomb"] = { color = Color3.fromRGB(255, 0, 255), label = "Boogie Bomb" },
    ["BoogieBomb"] = { color = Color3.fromRGB(255, 0, 255), label = "Boogie Bomb" },
}

-- Unique labels for dropdown
local TRAP_LABELS = {}
for _, data in pairs(TRAP_NAMES) do
    if not table.find(TRAP_LABELS, data.label) then
        table.insert(TRAP_LABELS, data.label)
    end
end
table.sort(TRAP_LABELS)

local TrapESP = {
    enabled = false,
    selectedTraps = {},
    connection = nil,
    addedConnection = nil,
    removingConnection = nil,
    visuals = {},
    tracked = {},
    elapsed = 0,
    updateInterval = 0.2,
    maxDistance = 300,
}
-- Default: all traps selected
for _, label in ipairs(TRAP_LABELS) do
    TrapESP.selectedTraps[label] = true
end

local function resolveTrapInfo(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    if TRAP_NAMES[name] then
        return TRAP_NAMES[name], name
    end
    for trapName, data in pairs(TRAP_NAMES) do
        if name:find(trapName, 1, true) then
            return data, trapName
        end
    end
    return nil
end

local function resolveTrapRoot(instance)
    local current = instance
    while current and current ~= workspace do
        if current:IsA("Model") or current:IsA("BasePart") then
            local trapData, trapName = resolveTrapInfo(current.Name)
            if trapData then
                return current, trapData, trapName
            end
        end
        current = current.Parent
    end
    return nil
end

local function getTrapPosition(instance)
    if instance:IsA("BasePart") then
        return instance.Position
    end
    if instance:IsA("Model") then
        local primary = instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart")
        if primary then
            return primary.Position
        end
        local ok, pivot = pcall(instance.GetPivot, instance)
        if ok and typeof(pivot) == "CFrame" then
            return pivot.Position
        end
    end
    return nil
end

local function getTrapAdornee(instance)
    if instance:IsA("Model") then
        return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart")
    end
    if instance:IsA("BasePart") then
        return instance
    end
    return nil
end

local function createTrapVisual()
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SabTrapESPBillboard"
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = TrapESP.maxDistance + 40
    billboard.Size = UDim2.fromOffset(150, 30)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0)
    billboard.Enabled = false
    billboard.Parent = hiddenUiParent

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "TrapLabel"
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.fromScale(1, 1)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextScaled = false
    textLabel.TextSize = 13
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(12, 12, 12)
    textLabel.TextWrapped = true
    textLabel.Parent = billboard

    local highlight = Instance.new("Highlight")
    highlight.Name = "SabTrapESPHighlight"
    highlight.FillTransparency = 0.8
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    highlight.Parent = hiddenUiParent

    return {
        billboard = billboard,
        text = textLabel,
        highlight = highlight,
    }
end

local function clearTrapVisuals()
    for inst, drawings in pairs(TrapESP.visuals) do
        for _, d in pairs(drawings) do
            pcall(function()
                d:Destroy()
            end)
        end
    end
    TrapESP.visuals = {}
end

local function removeTrapVisual(instance)
    local drawings = TrapESP.visuals[instance]
    if not drawings then
        return
    end
    for _, d in pairs(drawings) do
        pcall(function()
            d:Destroy()
        end)
    end
    TrapESP.visuals[instance] = nil
end

local function trackTrap(instance)
    local root, trapData = resolveTrapRoot(instance)
    if root and trapData then
        TrapESP.tracked[root] = trapData
    end
end

local function untrackTrap(instance)
    local root = instance
    if not TrapESP.tracked[root] then
        root = resolveTrapRoot(instance)
    end
    if root then
        TrapESP.tracked[root] = nil
        removeTrapVisual(root)
    end
end

local function rebuildTrackedTraps()
    table.clear(TrapESP.tracked)
    local folders = {
        workspace:FindFirstChild("PlacedItems"),
        workspace:FindFirstChild("Items"),
        workspace:FindFirstChild("Effects"),
        workspace,
    }
    local seen = {}
    for _, container in ipairs(folders) do
        if typeof(container) == "Instance" and not seen[container] then
            seen[container] = true
            for _, child in ipairs(container:GetDescendants()) do
                trackTrap(child)
            end
        end
    end
end

local function updateTrapEsp()
    local myChar = lp.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then
        for _, drawings in pairs(TrapESP.visuals) do
            if drawings.billboard then
                drawings.billboard.Enabled = false
            end
            if drawings.highlight then
                drawings.highlight.Enabled = false
            end
        end
        return
    end

    local found = {}
    for child, trapData in pairs(TrapESP.tracked) do
        if child.Parent == nil then
            untrackTrap(child)
        elseif TrapESP.selectedTraps[trapData.label] then
            local pos = getTrapPosition(child)
            if pos then
                local dist = (pos - myHRP.Position).Magnitude
                if dist <= TrapESP.maxDistance then
                    found[child] = { data = trapData, pos = pos, dist = dist }
                end
            end
        end
    end

    -- Remove visuals for traps that no longer exist
    for inst in pairs(TrapESP.visuals) do
        if not found[inst] then
            removeTrapVisual(inst)
        end
    end

    -- Update / create visuals
    for inst, info in pairs(found) do
        if not TrapESP.visuals[inst] then
            TrapESP.visuals[inst] = createTrapVisual()
        end
        local vis = TrapESP.visuals[inst]
        local adornee = getTrapAdornee(inst)
        if adornee then
            vis.billboard.Adornee = adornee
            vis.billboard.Enabled = true
            vis.billboard.MaxDistance = TrapESP.maxDistance + 40
            vis.text.Text = string.format("%s [%dm]", info.data.label, math.floor(info.dist))
            vis.text.TextColor3 = info.data.color
            vis.highlight.Adornee = inst
            vis.highlight.FillColor = info.data.color
            vis.highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            vis.highlight.Enabled = true
        else
            vis.billboard.Enabled = false
            vis.highlight.Enabled = false
        end
    end
end

function TrapESP:Start()
    if self.enabled then return end
    self.enabled = true
    self.elapsed = 0
    rebuildTrackedTraps()
    self.addedConnection = workspace.DescendantAdded:Connect(trackTrap)
    self.removingConnection = workspace.DescendantRemoving:Connect(untrackTrap)
    self.connection = game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
        if self.enabled then
            self.elapsed = self.elapsed + (deltaTime or 0)
            if self.elapsed < self.updateInterval then
                return
            end
            self.elapsed = 0
            pcall(updateTrapEsp)
        end
    end)
end

function TrapESP:Stop()
    if not self.enabled then return end
    self.enabled = false
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    if self.addedConnection then
        self.addedConnection:Disconnect()
        self.addedConnection = nil
    end
    if self.removingConnection then
        self.removingConnection:Disconnect()
        self.removingConnection = nil
    end
    for instance in pairs(self.tracked) do
        self.tracked[instance] = nil
    end
    clearTrapVisuals()
end

-- UI Controls
TrapsEspSection:AddToggle({
    Name = "Enable Traps ESP",
    SaveKey = "sab_traps_esp_enabled",
    Default = false,
    Callback = function(value)
        if value then TrapESP:Start() else TrapESP:Stop() end
    end,
})

TrapsEspSection:AddMultiDropdown({
    Name = "Trap Filter",
    SaveKey = "sab_traps_esp_filter",
    Options = TRAP_LABELS,
    Default = TRAP_LABELS,
    Callback = function(values, selectedSet)
        local selected = selectedSet
        if type(selected) ~= "table" then
            selected = {}
            if type(values) == "table" then
                for _, label in ipairs(values) do
                    selected[label] = true
                end
            end
        end
        for _, label in ipairs(TRAP_LABELS) do
            TrapESP.selectedTraps[label] = selected[label] and true or false
        end
    end,
})

TrapsEspSection:AddSlider({
    Name = "Trap Max Distance",
    SaveKey = "sab_traps_esp_distance",
    Min = 50,
    Max = 600,
    Default = 300,
    Precision = 0,
    Callback = function(value)
        TrapESP.maxDistance = tonumber(value) or 300
    end,
})
end) then
    --warn("[SAB] TRAPS ESP init failed")
end
end -- end TRAPS ESP scope


-- External Finder omitted (needs trusted PVH backend); server controls use UI adapter.



-- Deferred auto-load
task.defer(function()
    pcall(function()
        -- Temporarily disable callback suppression so UI features initialize correctly on load
        local oldBegin = Library._beginControlSync
        local oldEnd = Library._endControlSync
        
        Library._beginControlSync = function() end
        Library._endControlSync = function() end

        Library:LoadConfig()
        Library:SaveConfig()

        Library._beginControlSync = oldBegin
        Library._endControlSync = oldEnd
    end)
end)

