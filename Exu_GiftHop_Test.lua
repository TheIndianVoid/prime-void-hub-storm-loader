-- Prime Void Hub | Exu Gifts / Server Hop EXPERIMENT
-- Standalone test companion. No changes to Loader.lua or the production gateway.
-- Never guesses the Rewards remote signature: first observe one legitimate claim.
do
    if tonumber(game.PlaceId) ~= 103076400317371 then return end

    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local player = Players.LocalPlayer
    if not player then return end

    local env = type(getgenv) == "function" and getgenv() or _G
    if env.PVEXU_GiftTest and type(env.PVEXU_GiftTest.Stop) == "function" then
        pcall(env.PVEXU_GiftTest.Stop)
    end

    local rewards = ReplicatedStorage:WaitForChild("Remotes", 20)
    rewards = rewards and rewards:FindFirstChild("Rewards")
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local configModule = shared and shared:FindFirstChild("Config")
    local giftMinutes = { 1, 3, 5, 8, 12, 16, 22, 30 }
    if configModule then
        local ok, config = pcall(require, configModule)
        if ok and type(config) == "table" and type(config.Gifts) == "table" then
            local discovered = {}
            for i, gift in ipairs(config.Gifts) do
                if type(gift) == "table" and tonumber(gift.minutes) then
                    discovered[i] = tonumber(gift.minutes)
                end
            end
            if #discovered == 8 then giftMinutes = discovered end
        end
    end

    local resumed
    if type(env.PVEXU_GiftTestResumeJSON) == "string" then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(env.PVEXU_GiftTestResumeJSON)
        end)
        if ok and type(data) == "table" then resumed = data end
    end
    env.PVEXU_GiftTestResumeJSON = nil

    local state = {
        alive = true,
        running = false,
        armed = false,
        busy = false,
        autoHop = resumed and resumed.autoHop == true or false,
        args = resumed and resumed.args or nil,
        slot = resumed and tonumber(resumed.slot) or nil,
        slotWasString = resumed and resumed.slotWasString == true or false,
        calibrationIndex = nil,
        calibrationVerdict = resumed and resumed.verdict or nil,
        manualConfirmed = resumed ~= nil,
        claimed = {},
        attempted = {},
        hops = resumed and math.floor(tonumber(resumed.hops) or 0) or 0,
        sessionStart = os.clock(),
        maxHops = 2, -- test-only brake against infinite server hopping
        status = "Teste carregado. Primeiro, capture um resgate.",
        callbacks = {},
    }
    env.PVEXU_GiftTest = state


    -- Diagnostics: a real file in the executor workspace, an in-game Workspace
    -- StringValue, and an inspectable ring buffer. These never use the telemetry gateway.
    state.logLines = {}
    state.logFile = "primevoid_hub/Exu_Security_Lab/Logs/GiftHalloween_"
        .. os.date("%Y%m%d_%H%M%S") .. ".log"
    state.fileLogging = false
    local folderParts = {
        "primevoid_hub",
        "primevoid_hub/Exu_Security_Lab",
        "primevoid_hub/Exu_Security_Lab/Logs",
    }
    if type(writefile) == "function" then
        for _, folder in ipairs(folderParts) do
            if type(makefolder) == "function" then
                pcall(function()
                    if type(isfolder) ~= "function" or not isfolder(folder) then
                        makefolder(folder)
                    end
                end)
            end
        end
        local ok = pcall(writefile, state.logFile,
            "PVH Exu Gift/Halloween TEST — " .. os.date("!%Y-%m-%d %H:%M:%S UTC") .. "\n")
        state.fileLogging = ok
    end
    local workspaceLog = Instance.new("StringValue")
    workspaceLog.Name = "PVEXU_Test_Log"
    workspaceLog.Value = "Initializing event diagnostics"
    workspaceLog.Parent = game:GetService("Workspace")
    state.workspaceLog = workspaceLog

    local function summarize(value)
        local kind = typeof(value)
        if kind == "string" then
            return string.format("%q", string.sub(value, 1, 220))
        elseif kind == "number" or kind == "boolean" or kind == "nil" then
            return tostring(value)
        elseif kind == "Vector3" then
            return string.format("Vector3(%.1f,%.1f,%.1f)",value.X,value.Y,value.Z)
        elseif kind == "table" then
            local result={}
            for k,v in pairs(value) do
                if #result >= 12 then break end
                result[#result+1] = tostring(k) .. "=" .. summarize(v)
            end
            return "{" .. table.concat(result,",") .. "}"
        end
        return "<" .. kind .. ">"
    end
    local function summarizeArgs(args)
        if type(args) ~= "table" then return summarize(args) end
        local chunks={}
        for i=1,math.min(#args,12) do chunks[#chunks+1]="arg"..i..":"..summarize(args[i]) end
        return table.concat(chunks, " | ")
    end
    local function log(category, detail)
        local line = os.date("!%Y-%m-%dT%H:%M:%SZ")
            .. " [" .. tostring(category) .. "] "
            .. string.sub(tostring(detail or ""),1,1200)
        state.logLines[#state.logLines+1] = line
        if #state.logLines > 500 then table.remove(state.logLines,1) end
        warn("[PVEXU LAB] " .. line)
        if state.workspaceLog and state.workspaceLog.Parent then
            state.workspaceLog.Value = line
        end
        if state.fileLogging then
            local ok = pcall(function()
                if type(appendfile) == "function" then
                    appendfile(state.logFile,line.."\n")
                else
                    writefile(state.logFile,table.concat(state.logLines,"\n").."\n")
                end
            end)
            if not ok then state.fileLogging=false end
        end
        if type(state.logSink) == "function" then pcall(state.logSink,line) end
    end
    state.log = log
    log("BOOT","PlaceId="..tostring(game.PlaceId).." JobId="..tostring(game.JobId)
        .." Rewards="..(rewards and rewards.ClassName or "MISSING")
        .." writefile="..tostring(state.fileLogging)
        .." log="..state.logFile)

    local function setStatus(s)
        state.status = tostring(s)
        log("STATUS", state.status)
        if state.statusLabel then
            state.statusLabel.Text = state.status
        end
    end

    local function verdict(value)
        if value == true then return "success" end
        if value == false then return "failed" end
        if type(value) == "number" then
            return value > 0 and "success" or "failed"
        end
        if type(value) == "table" then
            if value.success == true or value.ok == true or value.claimed == true then
                return "success"
            end
            if value.success == false or value.ok == false or value.error ~= nil then
                return "failed"
            end
        end
        if type(value) == "string" then
            local s = string.lower(value)
            if s:find("success", 1, true) or s:find("claimed", 1, true)
                or s:find("resgatado", 1, true) then
                return "success"
            end
            if s:find("error", 1, true) or s:find("failed", 1, true)
                or s:find("already", 1, true) or s:find("aguarde", 1, true) then
                return "failed"
            end
        end
        return "unknown"
    end

    local function inspectSignature(arguments)
        if type(arguments) ~= "table" then return nil end
        local found
        for i = 1, #arguments do
            local v = arguments[i]
            if (type(v) == "number" and v >= 1 and v <= #giftMinutes and v % 1 == 0)
                or (type(v) == "string" and tonumber(v)
                    and tonumber(v) >= 1 and tonumber(v) <= #giftMinutes
                    and tonumber(v) % 1 == 0) then
                if found then return nil end -- ambiguous: do not guess
                found = { slot = i, index = tonumber(v), asString = type(v) == "string" }
            elseif type(v) ~= "string" and type(v) ~= "number"
                and type(v) ~= "boolean" then
                return nil -- unsupported argument types
            end
        end
        return found
    end

    local function capture(arguments, response)
        if not state.alive or not state.armed then return end
        state.armed = false
        state.captureCount = (state.captureCount or 0) + 1
        log("REWARD_CAPTURE","capture="..state.captureCount.." args="..summarizeArgs(arguments)
            .." response="..summarize(response).." verdict="..verdict(response))
        local sig = inspectSignature(arguments)
        if not sig then
            setStatus("Chamada Rewards capturada, mas sem índice único 1–8. Não é seguro automatizar.")
            return
        end
        if state.slot and (state.slot ~= sig.slot or state.slotWasString ~= sig.asString) then
            log("REWARD_MISMATCH","previous_slot="..tostring(state.slot)
                .." new_slot="..sig.slot.." refusing incompatible protocol")
            state.manualConfirmed = false
            setStatus("Capturas incompatíveis: não automatizar. Veja a aba Logs.")
            return
        end
        state.args = arguments
        state.slot = sig.slot
        state.slotWasString = sig.asString
        state.calibrationIndex = sig.index
        state.calibrationVerdict = verdict(response)
        state.manualConfirmed = false
        setStatus("Capturado prêmio #" .. sig.index .. " (resultado: "
            .. state.calibrationVerdict .. "). Confira no jogo e clique CONFIRMAR.")
    end

    local function installCapture()
        if state.hookInstalled then
            state.armed = true
            setStatus("Captura armada: resgate UM prêmio manualmente no menu original.")
            return
        end
        if not rewards or not rewards:IsA("RemoteFunction")
            or type(hookmetamethod) ~= "function"
            or type(getnamecallmethod) ~= "function" then
            setStatus("Este executor não permite observar Rewards:InvokeServer. Nenhum remote será adivinhado.")
            return
        end
        local previous
        local function interceptor(self, ...)
            if self == rewards and state.alive and state.armed
                and getnamecallmethod() == "InvokeServer" then
                local args = table.pack(...)
                local returned = table.pack(previous(self, ...))
                local flat = {}
                for i = 1, args.n do flat[i] = args[i] end
                local firstResult = returned[1]
                task.defer(function() capture(flat, firstResult) end)
                return table.unpack(returned, 1, returned.n)
            end
            return previous(self, ...)
        end
        local wrapped = type(newcclosure) == "function"
            and newcclosure(interceptor) or interceptor
        local ok, old = pcall(function()
            return hookmetamethod(game, "__namecall", wrapped)
        end)
        if not ok or type(old) ~= "function" then
            setStatus("A captura não pôde ser instalada: " .. tostring(old))
            return
        end
        previous = old
        state.hookInstalled = true
        state.armed = true
        setStatus("Captura armada: resgate UM prêmio manualmente no menu original.")
    end

    local function claim(index)
        local args = table.clone(state.args)
        args[state.slot] = state.slotWasString and tostring(index) or index
        local ok, answer = pcall(function()
            return rewards:InvokeServer(table.unpack(args, 1, #args))
        end)
        if not ok then
            log("REWARD_ERROR","claim #" .. index .. " args=" .. summarizeArgs(args)
                .. " error=" .. tostring(answer))
            return "error", tostring(answer)
        end
        local result=verdict(answer)
        log("REWARD_ATTEMPT","claim #" .. index .. " args=" .. summarizeArgs(args)
            .. " result="..summarize(answer).." verdict="..result)
        return result, tostring(answer)
    end

    local function queueForTeleport()
        local queue = type(queue_on_teleport) == "function" and queue_on_teleport
            or (type(syn) == "table" and type(syn.queue_on_teleport) == "function"
                and syn.queue_on_teleport)
            or (type(fluxus) == "table" and type(fluxus.queue_on_teleport) == "function"
                and fluxus.queue_on_teleport)
        if type(queue) ~= "function" then return false, "executor sem queue_on_teleport" end
        local payload = HttpService:JSONEncode({
            args = state.args,
            slot = state.slot,
            slotWasString = state.slotWasString,
            verdict = state.calibrationVerdict,
            autoHop = true,
            hops = state.hops + 1,
        })
        local loaderUrl = "https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/refs/heads/test/exu-gift-hop/Loader_ExuRewards_TEST.lua"
        local code = "getgenv().PVEXU_GiftTestResumeJSON = "
            .. string.format("%q", payload)
            .. "\nloadstring(game:HttpGet("
            .. string.format("%q", loaderUrl) .. "))()"
        local ok, err = pcall(queue, code)
        return ok, ok and nil or tostring(err)
    end

    local function hop()
        if state.busy or not state.alive then return end
        if state.hops >= state.maxHops then
            setStatus("Limite de 2 hops de teste atingido. Sem loop infinito.")
            state.running = false
            return
        end
        state.busy = true
        setStatus("Buscando servidor público diferente...")
        local destination
        local cursor
        for _ = 1, 4 do
            local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId)
                .. "/servers/Public?sortOrder=Asc&limit=100"
            if cursor then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end
            local ok, data = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(url))
            end)
            if not ok or type(data) ~= "table" then break end
            local candidates = {}
            for _, server in ipairs(data.data or {}) do
                if type(server.id) == "string" and server.id ~= game.JobId
                    and tonumber(server.playing) and tonumber(server.maxPlayers)
                    and server.playing < server.maxPlayers then
                    candidates[#candidates + 1] = server.id
                end
            end
            if #candidates > 0 then
                destination = candidates[math.random(1, #candidates)]
                break
            end
            cursor = data.nextPageCursor
            if type(cursor) ~= "string" or cursor == "" then break end
        end
        if not destination then
            state.busy = false
            setStatus("Nenhum servidor alternativo disponível. Sem teleporte.")
            return
        end
        local okQueue, queueError = queueForTeleport()
        if not okQueue then
            state.busy = false
            setStatus("Hop cancelado: " .. tostring(queueError) .. ".")
            return
        end
        setStatus("Oito recompensas concluídas. Teleportando...")
        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, destination, player)
        end)
        if not ok then
            state.busy = false
            setStatus("Teleport falhou: " .. tostring(err))
        end
    end

    function state.Stop()
        state.alive = false
        state.running = false
        state.armed = false
        if state.gui then pcall(function() state.gui:Destroy() end) end
        for _, conn in ipairs(state.callbacks) do
            pcall(function() conn:Disconnect() end)
        end
        if state.workspaceLog then pcall(function() state.workspaceLog:Destroy() end) end
        if env.PVEXU_GiftTest == state then env.PVEXU_GiftTest = nil end
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "PVExu_GiftHop_TEST"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    state.gui = gui
    local parent = player:WaitForChild("PlayerGui")
    if type(gethui) == "function" then
        local ok, container = pcall(gethui)
        if ok and typeof(container) == "Instance" then parent = container end
    end
    gui.Parent = parent

    local root = Instance.new("Frame")
    root.Name = "TestWindow"
    root.Size = UDim2.fromOffset(430, 408)
    root.Position = UDim2.new(1, -448, 0, 85)
    root.Active = true
    root.ClipsDescendants = true
    root.BackgroundColor3 = Color3.fromRGB(24, 22, 35)
    root.BorderSizePixel = 0
    root.Parent = gui
    Instance.new("UICorner", root).CornerRadius = UDim.new(0, 9)
    local stroke = Instance.new("UIStroke", root)
    stroke.Color = Color3.fromRGB(111, 77, 187)
    stroke.Thickness = 1.3


    local UserInputService = game:GetService("UserInputService")
    local function pane(name)
        local p=Instance.new("Frame")
        p.Name=name
        p.BackgroundTransparency=1
        p.Position=UDim2.fromOffset(0, 80)
        p.Size=UDim2.new(1,0,1,-85)
        p.Visible=false
        p.Parent=root
        return p
    end
    local rewardPage=pane("RewardsPage")
    local halloweenPage=pane("HalloweenPage")
    local logsPage=pane("LogsPage")
    rewardPage.Visible=true
    local chrome=Instance.new("Frame")
    chrome.Name="DragHeader"
    chrome.Size=UDim2.new(1,0,0,38)
    chrome.BackgroundColor3=Color3.fromRGB(35,29,53)
    chrome.BorderSizePixel=0
    chrome.Active=true
    chrome.Parent=root
    Instance.new("UICorner",chrome).CornerRadius=UDim.new(0,9)
    local brand=Instance.new("TextLabel")
    brand.Text="PRIME VOID HUB  /  EXU EVENT LAB  •  TEST"
    brand.Font=Enum.Font.GothamBold
    brand.TextSize=12
    brand.TextXAlignment=Enum.TextXAlignment.Left
    brand.TextColor3=Color3.fromRGB(228,209,255)
    brand.BackgroundTransparency=1
    brand.Position=UDim2.fromOffset(12,0)
    brand.Size=UDim2.new(1,-102,1,0)
    brand.Parent=chrome

    local function chromeButton(value,x,func)
        local b=Instance.new("TextButton")
        b.Name=value=="−" and "Minimize" or "Close"
        b.Text=value
        b.Font=Enum.Font.GothamBold
        b.TextSize=18
        b.TextColor3=Color3.fromRGB(247,240,255)
        b.BackgroundColor3=Color3.fromRGB(58,46,81)
        b.Size=UDim2.fromOffset(32,26)
        b.Position=UDim2.new(1,-x,0,6)
        b.Parent=chrome
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
        state.callbacks[#state.callbacks+1]=b.Activated:Connect(func)
        return b
    end
    local minimized=false
    local tabs=Instance.new("Frame")
    tabs.Name="Tabs"
    tabs.BackgroundTransparency=1
    tabs.Position=UDim2.fromOffset(10,42)
    tabs.Size=UDim2.new(1,-20,0,32)
    tabs.Parent=root
    chromeButton("×",38,function() state.Stop() end)
    local minimizeButton
    minimizeButton=chromeButton("−",76,function()
        minimized=not minimized
        tabs.Visible=not minimized
        for _,p in ipairs({rewardPage,halloweenPage,logsPage}) do
            if minimized then p.Visible=false end
        end
        root.Size=UDim2.fromOffset(430,minimized and 38 or 408)
        minimizeButton.Text=minimized and "+" or "−"
        if not minimized then
            local active=state.activePage or "Rewards"
            rewardPage.Visible=active=="Rewards"
            halloweenPage.Visible=active=="Halloween"
            logsPage.Visible=active=="Logs"
        end
        log("UI",minimized and "minimized" or "restored")
    end)
    local function tab(label,x,page)
        local b=Instance.new("TextButton")
        b.Text=label
        b.Font=Enum.Font.GothamSemibold
        b.TextSize=12
        b.TextColor3=Color3.fromRGB(227,211,252)
        b.BackgroundColor3=Color3.fromRGB(57,44,78)
        b.Size=UDim2.new(1/3,-6,1,0)
        b.Position=UDim2.new(x/3,3,0,0)
        b.Parent=tabs
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
        state.callbacks[#state.callbacks+1]=b.Activated:Connect(function()
            state.activePage=page
            rewardPage.Visible=page=="Rewards"
            halloweenPage.Visible=page=="Halloween"
            logsPage.Visible=page=="Logs"
            log("UI","tab="..page)
        end)
    end
    tab("🎁 RECOMPENSAS",0,"Rewards")
    tab("🎃 HALLOWEEN",1,"Halloween")
    tab("📋 LOGS",2,"Logs")
    state.activePage="Rewards"

    -- Real draggable desktop/mobile header (no static modal).
    local dragging=false
    local dragStart
    local origin
    state.callbacks[#state.callbacks+1]=chrome.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1
            or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            dragStart=input.Position
            origin=root.Position
        end
    end)
    state.callbacks[#state.callbacks+1]=UserInputService.InputChanged:Connect(function(input)
        if dragging and dragStart and (input.UserInputType==Enum.UserInputType.MouseMovement
            or input.UserInputType==Enum.UserInputType.Touch) then
            local delta=input.Position-dragStart
            root.Position=UDim2.new(origin.X.Scale,origin.X.Offset+delta.X,
                origin.Y.Scale,origin.Y.Offset+delta.Y)
        end
    end)
    state.callbacks[#state.callbacks+1]=UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1
            or input.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end)
    -- File-backed, browseable structured log console.
    local logTitle=Instance.new("TextLabel")
    logTitle.BackgroundTransparency=1
    logTitle.Text="DIAGNÓSTICO  •  " .. (state.fileLogging and "arquivo ativo" or "apenas memória")
    logTitle.TextColor3=Color3.fromRGB(191,163,255)
    logTitle.TextSize=13
    logTitle.Font=Enum.Font.GothamBold
    logTitle.TextXAlignment=Enum.TextXAlignment.Left
    logTitle.Position=UDim2.fromOffset(14,3)
    logTitle.Size=UDim2.new(1,-28,0,24)
    logTitle.Parent=logsPage
    local logPathLabel=Instance.new("TextLabel")
    logPathLabel.Text=state.logFile
    logPathLabel.BackgroundTransparency=1
    logPathLabel.TextColor3=Color3.fromRGB(177,176,189)
    logPathLabel.Font=Enum.Font.Code
    logPathLabel.TextSize=10
    logPathLabel.TextWrapped=true
    logPathLabel.TextXAlignment=Enum.TextXAlignment.Left
    logPathLabel.Position=UDim2.fromOffset(14,27)
    logPathLabel.Size=UDim2.new(1,-24,0,35)
    logPathLabel.Parent=logsPage
    local console=Instance.new("ScrollingFrame")
    console.Name="EventLog"
    console.BackgroundColor3=Color3.fromRGB(16,15,26)
    console.BorderSizePixel=0
    console.ScrollBarThickness=5
    console.ScrollBarImageColor3=Color3.fromRGB(153,100,253)
    console.Position=UDim2.fromOffset(12,66)
    console.Size=UDim2.new(1,-24,1,-122)
    console.CanvasSize=UDim2.fromOffset(0,0)
    console.AutomaticCanvasSize=Enum.AutomaticSize.Y
    console.Parent=logsPage
    Instance.new("UICorner",console).CornerRadius=UDim.new(0,6)
    local content=Instance.new("UIListLayout")
    content.SortOrder=Enum.SortOrder.LayoutOrder
    content.Padding=UDim.new(0,3)
    content.Parent=console
    local logElements={}
    local function addConsoleLine(line)
        if not state.alive or not console.Parent then return end
        local t=Instance.new("TextLabel")
        t.BackgroundTransparency=1
        t.Size=UDim2.new(1,-15,0,28)
        t.AutomaticSize=Enum.AutomaticSize.Y
        t.TextWrapped=true
        t.TextXAlignment=Enum.TextXAlignment.Left
        t.TextYAlignment=Enum.TextYAlignment.Top
        t.Font=Enum.Font.Code
        t.TextSize=11
        t.TextColor3=string.find(line,"ERROR",1,true)
            and Color3.fromRGB(255,130,130) or Color3.fromRGB(210,218,236)
        t.Text=line
        t.LayoutOrder=#logElements+1
        t.Parent=console
        logElements[#logElements+1]=t
        if #logElements>130 then
            local old=table.remove(logElements,1)
            old:Destroy()
        end
        task.defer(function()
            if console.Parent then
                console.CanvasPosition=Vector2.new(0,math.max(0,content.AbsoluteContentSize.Y))
            end
        end)
    end
    for _,line in ipairs(state.logLines) do addConsoleLine(line) end
    state.logSink=addConsoleLine
    local copy=Instance.new("TextButton")
    copy.Text="COPIAR LOGS"
    copy.Font=Enum.Font.GothamBold
    copy.TextSize=12
    copy.TextColor3=Color3.new(1,1,1)
    copy.BackgroundColor3=Color3.fromRGB(82,52,129)
    copy.Position=UDim2.new(0,12,1,-44)
    copy.Size=UDim2.fromOffset(180,32)
    copy.Parent=logsPage
    Instance.new("UICorner",copy).CornerRadius=UDim.new(0,6)
    state.callbacks[#state.callbacks+1]=copy.Activated:Connect(function()
        if type(setclipboard)=="function" then
            local ok=pcall(setclipboard,table.concat(state.logLines,"\n"))
            log("LOG_EXPORT",ok and "copied" or "clipboard denied")
        else
            log("LOG_EXPORT","no setclipboard; read "...state.logFile)
        end
    end)

    local function label(text, y, height, size, color)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Text = text
        l.Font = Enum.Font.Gotham
        l.TextColor3 = color or Color3.fromRGB(229, 225, 243)
        l.TextSize = size or 13
        l.TextWrapped = true
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextYAlignment = Enum.TextYAlignment.Center
        l.Size = UDim2.new(1, -24, 0, height)
        l.Position = UDim2.fromOffset(12, y)
        l.Parent = rewardPage
        return l
    end

    label("PRIME VOID HUB · RECOMPENSAS (TESTE)", 9, 24, 14,
        Color3.fromRGB(189, 157, 255))
    label("1 · 3 · 5 · 8 · 12 · 16 · 22 · 30 min", 35, 22, 12)
    state.statusLabel = label(state.status, 64, 74, 12,
        Color3.fromRGB(233, 212, 150))

    local function button(text, x, y, w, onClick)
        local b = Instance.new("TextButton")
        b.BackgroundColor3 = Color3.fromRGB(52, 42, 78)
        b.BorderSizePixel = 0
        b.Text = text
        b.Font = Enum.Font.GothamSemibold
        b.TextSize = 12
        b.TextColor3 = Color3.fromRGB(244, 239, 255)
        b.Size = UDim2.fromOffset(w, 34)
        b.Position = UDim2.fromOffset(x, y)
        b.Parent = rewardPage
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        state.callbacks[#state.callbacks + 1] = b.MouseButton1Click:Connect(onClick)
        return b
    end

    button("1. CAPTURAR RESGATE", 12, 143, 176, installCapture)
    button("2. CONFIRMAR", 198, 143, 178, function()
        if state.calibrationIndex and state.args and state.slot then
            state.manualConfirmed = true
            state.claimed[state.calibrationIndex] = true
            setStatus("Protocolo confirmado. Recompensa #" ..
                state.calibrationIndex .. " foi resgatada manualmente.")
        else
            setStatus("Primeiro capture uma chamada Rewards do botão de resgate.")
        end
    end)

    button("INICIAR AUTO RESGATE", 12, 185, 176, function()
        if not rewards or not rewards:IsA("RemoteFunction") then
            setStatus("RemoteFunction Rewards não localizada.")
            return
        end
        if not state.args or not state.slot or not state.manualConfirmed then
            setStatus("Primeiro capture e confirme um resgate manual.")
            return
        end
        if state.running then return end
        local toggles = type(env.Toggles) == "table" and env.Toggles or nil
        local previousHop = toggles and toggles.PVEXU_ServerHopNoExu
        if previousHop and previousHop.Value == true then
            setStatus("Desative primeiro 'Auto trocar servidor sem Exu' na Farm; esse hop atrapalha os 30 min.")
            return
        end
        state.running = true
        state.attempted = {}
        setStatus("Auto resgate iniciado. Mantenha o hop por falta de Exus DESLIGADO.")
    end)

    button("PARAR", 198, 185, 178, function()
        state.running = false
        state.armed = false
        setStatus("Pausado. Nada será resgatado ou teleportado.")
    end)

    local hopButton
    hopButton = button(state.autoHop and "HOP APÓS 30 MIN: ON" or "HOP APÓS 30 MIN: OFF",
        12, 227, 364, function()
            state.autoHop = not state.autoHop
            hopButton.Text = state.autoHop and "HOP APÓS 30 MIN: ON" or "HOP APÓS 30 MIN: OFF"
            setStatus(state.autoHop and "Hop habilitado após TODOS os resgates confirmados."
                or "Hop desabilitado; apenas auto resgate.")
        end)

    state.callbacks[#state.callbacks + 1] =
        TeleportService.TeleportInitFailed:Connect(function(who, result)
            if who == player and state.busy then
                state.busy = false
                setStatus("Não foi possível iniciar teleporte: " .. tostring(result))
            end
        end)

    task.spawn(function()
        while state.alive do
            if state.running and not state.busy then
                local elapsed = (os.clock() - state.sessionStart) / 60
                local nextIndex
                for i = 1, #giftMinutes do
                    if not state.claimed[i] then nextIndex = i; break end
                end
                if not nextIndex then
                    state.running = false
                    if state.autoHop and state.calibrationVerdict == "success" and not state.unverified then
                        hop()
                    else
                        setStatus(state.autoHop
                            and "Todos processados. Hop bloqueado: servidor não confirmou o protocolo."
                            or "Todos os 8 resgates processados. Hop desabilitado.")
                    end
                elseif elapsed >= giftMinutes[nextIndex] then
                    local retries = state.attempted[nextIndex] or 0
                    if retries >= 4 then
                        state.running = false
                        setStatus("Prêmio #" .. nextIndex ..
                            " falhou 4 vezes. Pausado para evitar spam e hop indevido.")
                    else
                        state.attempted[nextIndex] = retries + 1
                        local outcome, detail = claim(nextIndex)
                        if state.hops > 0 and outcome ~= "success" and nextIndex == 1 then
                            state.running = false
                            setStatus("Novo servidor não confirmou prêmio #1 (" .. outcome .. "). Ciclo interrompido.")
                            outcome = "paused"
                        end
                        if outcome == "paused" then
                            -- Do not hop again when per-player rewards may be persistent.
                        elseif outcome == "success" then
                            state.claimed[nextIndex] = true
                            setStatus("Resgatado #" .. nextIndex .. " ("
                                .. giftMinutes[nextIndex] .. "min). "
                                .. (nextIndex < 8 and "Próximo em "
                                    .. giftMinutes[nextIndex+1] .. "min." or "Último!"))
                        elseif outcome == "unknown" then
                            -- Unknown is never proof of a claim; previous build advanced silently.
                            state.running = false
                            state.unverified = true
                            setStatus("Resgate #" .. nextIndex .. " sem confirmação do servidor. "
                                .. "Auto pausado; veja o retorno completo na aba Logs.")
                        else
                            setStatus("Prêmio #" .. nextIndex .. " não confirmado (" ..
                                outcome .. "); tentativa " .. state.attempted[nextIndex] ..
                                "/4. " .. string.sub(detail, 1, 60))
                            task.wait(30)
                        end
                    end
                end
            end
            task.wait(2)
        end
    end)

    -- Initial resume is never enough to trust a reset across servers:
    -- the first gift must be positively accepted by the server.
    if resumed then
        state.running = state.args ~= nil and state.slot ~= nil
        state.manualConfirmed = state.running
        state.calibrationVerdict = resumed.verdict
        state.autoHop = resumed.autoHop == true
        setStatus("Retomado no novo servidor (hop " .. state.hops ..
            "). Validar resgate de 1min antes de prosseguir.")
    end
end
