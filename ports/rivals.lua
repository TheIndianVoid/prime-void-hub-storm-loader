-- Prime Void Hub | RIVALS | v0.1.1
-- Client-side RIVALS port. No remote spoofing, anticheat hooks, or borrowed Da Hood routines.
if tonumber(game.GameId) ~= 6035872082 and tonumber(game.PlaceId) ~= 17625359962 then
    error("[PVH RIVALS] Wrong experience", 0)
end

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local env = type(getgenv) == "function" and getgenv() or _G
-- Persistent stage trace for crashes that terminate the Roblox process before F9
-- can be inspected. This contains only boot phases and error names, no credentials.
local tracePath = "PVH_Rivals_BootTrace.txt"
local traceLines = {}
local function trace(stage, extra)
    local line = string.format("[%s] %s%s", tostring(os.time()), stage,
        extra and (" | " .. tostring(extra):sub(1,180)) or "")
    traceLines[#traceLines + 1] = line
    warn("[PVH RIVALS BOOT] " .. line)
    if type(writefile) == "function" then
        pcall(writefile, tracePath, table.concat(traceLines, "\n") .. "\n")
    end
end
trace("port_entry", "v0.1.1")
if type(env.PVH_RivalsUnload) == "function" then
    trace("previous_port_cleanup")
    pcall(env.PVH_RivalsUnload)
end

local alive = true
local connections = {}
local visuals = {}
local controller
local library
local fovGui, fovRing
local oldFov
local lightingBackup = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows,
}
local options = {
    aim = false, aimMode = "Hold", aimPart = "Head", aimFov = 180,
    aimSmooth = 0.18, visible = true, teamCheck = true,
    esp = false, espNames = true, espHealth = true, espDistance = true,
    fovCircle = true, cameraFov = false, cameraValue = 90,
    fullBright = false, animations = true,
    language = "pt-BR",
}

local function track(connection)
    connections[#connections + 1] = connection
    return connection
end
local function notify(text)
    if library and not library.Unloaded then
        pcall(function()
            library:Notify({Title = "Prime Void Hub | RIVALS", Description = text, Time = 4})
        end)
    end
end
local function getCamera()
    return workspace.CurrentCamera
end
local lastControllerProbe = 0
local function safeController()
    if controller then return controller end
    if os.clock() - lastControllerProbe < 4 then return nil end
    lastControllerProbe = os.clock()
    local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
    local controllers = playerScripts and playerScripts:FindFirstChild("Controllers")
    local module = controllers and controllers:FindFirstChild("FighterController")
    if module and module:IsA("ModuleScript") then
        trace("fighter_controller_require")
        local ok, result = pcall(require, module)
        if ok and type(result) == "table" then
            controller = result
            trace("fighter_controller_ready")
        else
            trace("fighter_controller_unavailable", ok and "not a table" or result)
        end
    end
    return controller
end
-- RIVALS uses replicated Fighter.Entity.Model, not necessarily Player.Character.
local function getFighter(player)
    local c = safeController()
    if not c then return nil end
    local ok, fighter = pcall(function() return c:GetFighter(player) end)
    if ok and type(fighter) == "table" then return fighter end
    return nil
end
local function getModel(player)
    local fighter = getFighter(player)
    local model = fighter and fighter.Entity and fighter.Entity.Model
    if typeof(model) == "Instance" and model.Parent then return model, fighter end
    return player.Character, fighter
end
local function getPart(model, name)
    if typeof(model) ~= "Instance" then return nil end
    return model:FindFirstChild(name, true)
        or model:FindFirstChild("Head", true)
        or model:FindFirstChild("HumanoidRootPart", true)
        or model.PrimaryPart
end
local function isFriendly(player)
    if player == LocalPlayer then return true end
    if not options.teamCheck then return false end
    return LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team
end
local function healthText(model, fighter)
    local humanoid = typeof(model) == "Instance" and model:FindFirstChildOfClass("Humanoid")
    if humanoid then return tostring(math.floor(humanoid.Health + 0.5)) end
    if fighter and fighter.Entity then
        local entity = fighter.Entity
        local ok, value = pcall(function() return entity:Get("Health") end)
        if ok and type(value) == "number" then
            return tostring(math.floor(value + 0.5))
        end
    end
    return nil
end
local function visiblePoint(point, targetModel)
    local camera = getCamera()
    if not camera then return false end
    local origin = camera.CFrame.Position
    local ray = RaycastParams.new()
    ray.FilterType = Enum.RaycastFilterType.Exclude
    ray.IgnoreWater = true
    local excluded = {LocalPlayer.Character, camera}
    local myFighter = getFighter(LocalPlayer)
    if myFighter and myFighter.Entity and myFighter.Entity.Model then
        excluded[#excluded + 1] = myFighter.Entity.Model
    end
    local valid = {}
    for _, node in ipairs(excluded) do
        if typeof(node) == "Instance" then valid[#valid + 1] = node end
    end
    ray.FilterDescendantsInstances = valid
    local result = workspace:Raycast(origin, point - origin, ray)
    return result == nil or (targetModel and result.Instance:IsDescendantOf(targetModel))
end
local function targetPosition(model)
    local preferred = options.aimPart
    local part = getPart(model, preferred)
    if part and part:IsA("BasePart") then return part.Position end
    return nil
end
local function findTarget()
    local camera = getCamera()
    if not camera then return nil end
    local viewport = camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
    local bestDistance, bestPoint = options.aimFov, nil
    for _, player in ipairs(Players:GetPlayers()) do
        if not isFriendly(player) then
            local model = getModel(player)
            local point = targetPosition(model)
            if point then
                local screen, onScreen = camera:WorldToViewportPoint(point)
                if onScreen and screen.Z > 0 then
                    local d = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                    if d < bestDistance and
                        (not options.visible or visiblePoint(point, model)) then
                        bestDistance = d
                        bestPoint = point
                    end
                end
            end
        end
    end
    return bestPoint
end

local function clearVisual(player)
    local entry = visuals[player]
    if not entry then return end
    visuals[player] = nil
    pcall(function() entry.highlight:Destroy() end)
    pcall(function() entry.billboard:Destroy() end)
end
local function createVisual(player)
    local entry = visuals[player]
    if entry then return entry end
    local highlight = Instance.new("Highlight")
    highlight.Name = "PVH_Rivals_Outline"
    highlight.FillTransparency = 0.82
    highlight.OutlineTransparency = 0
    highlight.FillColor = Color3.fromRGB(140, 100, 255)
    highlight.OutlineColor = Color3.fromRGB(217, 192, 255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PVH_Rivals_NameESP"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(260, 44)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.9, 0)
    billboard.MaxDistance = 2000
    billboard.ResetOnSpawn = false
    billboard.Parent = LocalPlayer:WaitForChild("PlayerGui")
    local nameText = Instance.new("TextLabel")
    nameText.BackgroundTransparency = 1
    nameText.Size = UDim2.fromScale(1, 1)
    nameText.Font = Enum.Font.GothamBold
    nameText.TextSize = 13
    nameText.TextColor3 = Color3.fromRGB(246, 240, 255)
    nameText.TextStrokeColor3 = Color3.fromRGB(20, 16, 29)
    nameText.TextStrokeTransparency = 0.25
    nameText.TextXAlignment = Enum.TextXAlignment.Center
    nameText.TextYAlignment = Enum.TextYAlignment.Center
    nameText.Parent = billboard
    entry = {highlight = highlight, billboard = billboard, text = nameText}
    visuals[player] = entry
    return entry
end
local function updateVisuals()
    if not options.esp then
        for player in pairs(visuals) do clearVisual(player) end
        return
    end
    local current = {}
    local camera = getCamera()
    for _, player in ipairs(Players:GetPlayers()) do
        if not isFriendly(player) then
            local model, fighter = getModel(player)
            local head = getPart(model, "Head")
            if model and model.Parent and head and head:IsA("BasePart") then
                current[player] = true
                local entry = createVisual(player)
                if entry.highlight.Adornee ~= model then
                    entry.highlight.Parent = model
                    entry.highlight.Adornee = model
                end
                entry.billboard.Adornee = head
                local chunks = {}
                if options.espNames then chunks[#chunks + 1] = player.DisplayName end
                local hp = options.espHealth and healthText(model, fighter) or nil
                if hp then chunks[#chunks + 1] = hp .. " HP" end
                if options.espDistance and camera then
                    local dist = (camera.CFrame.Position - head.Position).Magnitude
                    chunks[#chunks + 1] = string.format("%dm", math.floor(dist * 0.28 + 0.5))
                end
                entry.text.Text = table.concat(chunks, "  •  ")
                entry.billboard.Enabled = #chunks > 0
            end
        end
    end
    for player in pairs(visuals) do
        if not current[player] then clearVisual(player) end
    end
end
local function restoreLighting()
    for property, value in pairs(lightingBackup) do
        pcall(function() Lighting[property] = value end)
    end
end
local function applyLighting()
    if not options.fullBright then
        restoreLighting()
        return
    end
    Lighting.Brightness = 3
    Lighting.ClockTime = 14
    Lighting.Ambient = Color3.fromRGB(225, 225, 225)
    Lighting.OutdoorAmbient = Color3.fromRGB(225, 225, 225)
    Lighting.GlobalShadows = false
end
local function updateCameraFov()
    local cam = getCamera()
    if not cam then return end
    if options.cameraFov then
        cam.FieldOfView = options.cameraValue
    elseif oldFov then
        cam.FieldOfView = oldFov
    end
end
local function unload()
    if not alive then return end
    alive = false
    pcall(function() RunService:UnbindFromRenderStep("PVH_Rivals_Aim") end)
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    for player in pairs(visuals) do clearVisual(player) end
    if fovGui then pcall(function() fovGui:Destroy() end) end
    restoreLighting()
    local cam = getCamera()
    if cam and oldFov then pcall(function() cam.FieldOfView = oldFov end) end
    if library and not library.Unloaded then pcall(function() library:Unload() end) end
    if env.PVH_RivalsUnload == unload then env.PVH_RivalsUnload = nil end
end
env.PVH_RivalsUnload = unload

local function buildCircle()
    fovGui = Instance.new("ScreenGui")
    fovGui.Name = "PVH_Rivals_FOV"
    fovGui.IgnoreGuiInset = true
    fovGui.ResetOnSpawn = false
    fovGui.DisplayOrder = 10001
    fovGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    fovRing = Instance.new("Frame")
    fovRing.Name = "FOV"
    fovRing.BackgroundTransparency = 1
    fovRing.BorderSizePixel = 0
    fovRing.AnchorPoint = Vector2.new(0.5, 0.5)
    fovRing.Parent = fovGui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = fovRing
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.4
    stroke.Color = Color3.fromRGB(178, 153, 249)
    stroke.Transparency = 0.2
    stroke.Parent = fovRing
end

local function initialLanguage()
    local prefs = env.PVH_Persistence
    if type(prefs) == "table" and type(prefs.GetLanguage) == "function" then
        local ok, value = pcall(function() return prefs:GetLanguage() end)
        if ok and (value == "pt-BR" or value == "en-US") then return value end
    end
    return "pt-BR"
end
options.language = initialLanguage()
local EN = options.language == "en-US"
local function label(pt, en) return EN and en or pt end
-- Translate existing UI text in place; no unload, flicker, or mixed languages.
local translations = {
    {"Início", "Home"}, {"Combate", "Combat"}, {"Visuais", "Visuals"},
    {"Miscelânea", "Miscellaneous"}, {"Configurações", "Settings"},
    {"Conta e sessão", "Account & session"}, {"Jogos suportados", "Supported games"},
    {"Estado da sessão", "Session status"}, {"Port ativo: RIVALS", "Active port: RIVALS"},
    {"Mira: botão direito", "Aim: right mouse button"},
    {"Assistência de mira", "Aim assist"}, {"Suavização", "Smoothness"},
    {"Parte do corpo", "Hit part"}, {"Filtros", "Checks"},
    {"Verificação de parede", "Visibility check"}, {"Ignorar aliados", "Ignore teammates"},
    {"Exibir FOV", "Show FOV"}, {"ESP Jogadores", "Player ESP"},
    {"Nomes", "Names"}, {"Vida", "Health"}, {"Distância", "Distance"},
    {"Câmera", "Camera"}, {"FOV personalizado", "Custom FOV"},
    {"Ambiente", "Environment"}, {"Idioma", "Language"},
    {"Animações da UI", "UI animations"},
    {"Sessão e controles", "Session & controls"}, {"Reentrar", "Rejoin"},
    {"Descarregar", "Unload"},
}
local function applyLanguage(nextEnglish)
    if library and library.ScreenGui then
        for _, item in ipairs(library.ScreenGui:GetDescendants()) do
            if item:IsA("TextLabel") or item:IsA("TextButton") then
                local value = item.Text
                for _, pair in ipairs(translations) do
                    local from, to = nextEnglish and pair[1] or pair[2],
                        nextEnglish and pair[2] or pair[1]
                    if value == from then item.Text = to; break end
                end
            end
        end
    end
    EN = nextEnglish
end
local function saveLanguage(value)
    options.language = value
    applyLanguage(value == "en-US")
    if type(writefile) == "function" and type(makefolder) == "function" then
        pcall(function()
            if type(isfolder) ~= "function" or not isfolder("primevoid_hub") then
                makefolder("primevoid_hub")
            end
            if type(isfolder) ~= "function" or not isfolder("primevoid_hub/RIVALS") then
                makefolder("primevoid_hub/RIVALS")
            end
            if type(isfolder) ~= "function" or not isfolder("primevoid_hub/RIVALS/Configs") then
                makefolder("primevoid_hub/RIVALS/Configs")
            end
            writefile("primevoid_hub/RIVALS/Configs/ui_settings.json", HttpService:JSONEncode({
                language = value,
            }))
        end)
    end
    notify(label("Idioma atualizado.", "Language updated."))
end

local libraryUrl = "https://raw.githubusercontent.com/deividcomsono/Obsidian/82d402b5de7d8903915f1afe99b5b7e340e7cd28/Library.lua"
trace("ui_library_request")
local loaded, object = pcall(function() return loadstring(game:HttpGet(libraryUrl))() end)
if not loaded or type(object) ~= "table" then
    trace("ui_library_failed", object)
    unload()
    error("[PVH RIVALS] Obsidian unavailable: " .. tostring(object), 0)
end
trace("ui_library_ready")
library = object
env.Library = library
library.ShowCustomCursor = false
trace("ui_window_start")
local window = library:CreateWindow({
    Title = "Prime Void Hub | RIVALS",
    Footer = "RIVALS | v0.1.1",
    Center = true, AutoShow = true, Resizable = true,
    Size = UDim2.fromOffset(680, 475),
    ToggleKeybind = Enum.KeyCode.RightControl,
    ShowCustomCursor = false,
    NotifySide = "Right",
    MinSidebarWidth = 155,
    Animations = {
        ToggleWindow = true, TabSwitch = true, Groupbox = true,
        Dropdown = true, KeyPicker = true,
    },
})
trace("ui_window_ready")
local home = window:AddTab(label("Início", "Home"), "house")
local combat = window:AddTab(label("Combate", "Combat"), "crosshair")
local visualsTab = window:AddTab(label("Visuais", "Visuals"), "eye")
local misc = window:AddTab(label("Miscelânea", "Miscellaneous"), "wrench")
local settings = window:AddTab(label("Configurações", "Settings"), "settings")

local userGroup = home:AddGroupbox({Name = label("Conta e sessão", "Account & session"), Side = "Left"})
userGroup:AddLabel(LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")", true)
userGroup:AddLabel("UserId: " .. tostring(LocalPlayer.UserId))
userGroup:AddLabel("PlaceId: " .. tostring(game.PlaceId))
userGroup:AddLabel("RIVALS  |  v0.1.1")
local games = home:AddGroupbox({Name = label("Jogos suportados", "Supported games"), Side = "Right"})
games:AddLabel("Storm Suite  •  Huntress", true)
games:AddLabel("Exu Security Lab  •  Destruction Simulator", true)
games:AddLabel("Don't Splash  •  Clover Legends", true)
games:AddLabel("Steal a Brainrot  •  RIVALS", true)
local session = home:AddGroupbox({Name = label("Estado da sessão", "Session status"), Side = "Left"})
session:AddLabel(label("Port ativo: RIVALS", "Active port: RIVALS"))
session:AddLabel(label("Menu: RightCtrl", "Menu: RightCtrl"))
session:AddLabel(label("Mira: botão direito", "Aim: right mouse button"))
session:AddLabel("Aim: C   |   ESP: H   |   Unload: Del")

local aimGroup = combat:AddGroupbox({Name = label("Assistência de mira", "Aim assist"), Side = "Left"})
aimGroup:AddToggle("PVHR_Aim", {Text = label("Aim Assist", "Aim Assist"), Default = false,
    Callback = function(value)
        options.aim = value
        if value then trace("aim_assist_enabled") end
    end})
aimGroup:AddSlider("PVHR_AimFOV", {Text = "FOV", Default = 180, Min = 35, Max = 600, Rounding = 0,
    Callback = function(value) options.aimFov = value end})
aimGroup:AddSlider("PVHR_AimSmooth", {Text = label("Suavização", "Smoothness"), Default = 18, Min = 1, Max = 100, Rounding = 0,
    Callback = function(value) options.aimSmooth = value / 100 end})
aimGroup:AddDropdown("PVHR_AimPart", {Text = label("Parte do corpo", "Hit part"), Values = {"Head", "UpperTorso", "HumanoidRootPart"}, Default = 1,
    Callback = function(value) options.aimPart = value end})
local aimChecks = combat:AddGroupbox({Name = label("Filtros", "Checks"), Side = "Right"})
aimChecks:AddToggle("PVHR_Visible", {Text = label("Verificação de parede", "Visibility check"), Default = true,
    Callback = function(value) options.visible = value end})
aimChecks:AddToggle("PVHR_TeamCheck", {Text = label("Ignorar aliados", "Ignore teammates"), Default = true,
    Callback = function(value) options.teamCheck = value end})
aimChecks:AddToggle("PVHR_FovCircle", {Text = label("Exibir FOV", "Show FOV"), Default = true,
    Callback = function(value) options.fovCircle = value end})

local espGroup = visualsTab:AddGroupbox({Name = "ESP", Side = "Left"})
espGroup:AddToggle("PVHR_ESP", {Text = label("ESP Jogadores", "Player ESP"), Default = false,
    Callback = function(value)
        options.esp = value
        if value then trace("esp_enabled") end
    end})
espGroup:AddToggle("PVHR_ESPNames", {Text = label("Nomes", "Names"), Default = true,
    Callback = function(value) options.espNames = value end})
espGroup:AddToggle("PVHR_ESPHealth", {Text = label("Vida", "Health"), Default = true,
    Callback = function(value) options.espHealth = value end})
espGroup:AddToggle("PVHR_ESPDistance", {Text = label("Distância", "Distance"), Default = true,
    Callback = function(value) options.espDistance = value end})

local cameraGroup = misc:AddGroupbox({Name = label("Câmera", "Camera"), Side = "Left"})
cameraGroup:AddToggle("PVHR_CameraFOV", {Text = label("FOV personalizado", "Custom FOV"), Default = false,
    Callback = function(value) options.cameraFov = value; updateCameraFov() end})
cameraGroup:AddSlider("PVHR_CameraValue", {Text = "Camera FOV", Default = 90, Min = 50, Max = 120, Rounding = 0,
    Callback = function(value) options.cameraValue = value; updateCameraFov() end})
local worldGroup = misc:AddGroupbox({Name = label("Ambiente", "Environment"), Side = "Right"})
worldGroup:AddToggle("PVHR_Fullbright", {Text = "FullBright", Default = false,
    Callback = function(value) options.fullBright = value; applyLighting() end})

local mainPrefs = settings:AddGroupbox({Name = label("Interface", "Interface"), Side = "Left"})
mainPrefs:AddDropdown("PVHR_Language", {
    Text = label("Idioma", "Language"),
    Values = {"Português (BR)", "English (US)"},
    Default = EN and 2 or 1,
    Callback = function(value)
        local lang = value == "English (US)" and "en-US" or "pt-BR"
        if lang ~= options.language then saveLanguage(lang) end
    end,
})
mainPrefs:AddToggle("PVHR_Animations", {Text = label("Animações da UI", "UI animations"), Default = true,
    Callback = function(value)
        options.animations = value
        if library and type(library.Animations) == "table" then
            library.Animations.ToggleWindow = value
            library.Animations.TabSwitch = value
            library.Animations.Groupbox = value
            library.Animations.Dropdown = value
        end
    end})
local tools = settings:AddGroupbox({Name = label("Sessão e controles", "Session & controls"), Side = "Right"})
tools:AddButton({Text = label("Reentrar", "Rejoin"), Func = function()
    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end})
tools:AddButton({Text = label("Descarregar", "Unload"), Func = unload})
library:OnUnload(function()
    if alive then unload() end
end)

trace("ui_controls_ready")
buildCircle()
trace("fov_overlay_ready")
oldFov = getCamera() and getCamera().FieldOfView or 70
local aimingToggle = false
track(UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.C then aimingToggle = not aimingToggle end
    if input.KeyCode == Enum.KeyCode.H and library and library.Toggles
        and library.Toggles.PVHR_ESP then
        library.Toggles.PVHR_ESP:SetValue(not options.esp)
    end
    if input.KeyCode == Enum.KeyCode.Delete then unload() end
end))
trace("render_bind_start")
RunService:BindToRenderStep("PVH_Rivals_Aim", Enum.RenderPriority.Camera.Value + 30, function()
    if not alive then return end
    local camera = getCamera()
    if not camera then return end
    if options.aim and (UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or aimingToggle) then
        local point = findTarget()
        if point then
            local position = camera.CFrame.Position
            local wanted = CFrame.lookAt(position, point)
            camera.CFrame = camera.CFrame:Lerp(wanted, options.aimSmooth)
        end
    end
    if fovRing then
        fovRing.Visible = options.aim and options.fovCircle
        fovRing.Size = UDim2.fromOffset(options.aimFov * 2, options.aimFov * 2)
        fovRing.Position = UDim2.fromOffset(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    end
end)
task.spawn(function()
    local elapsed = 0
    while alive do
        task.wait(0.3)
        if not alive then break end
        updateVisuals()
        elapsed = elapsed + 0.3
        if elapsed >= 1.5 then
            elapsed = 0
            if options.fullBright then applyLighting() end
            if options.cameraFov then updateCameraFov() end
        end
    end
end)
trace("port_ready")
notify(label("RIVALS carregado.", "RIVALS loaded."))
