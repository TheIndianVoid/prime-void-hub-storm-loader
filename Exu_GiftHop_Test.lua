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
        autoHop = resumed == nil or resumed.autoHop == true, -- default ON in isolated 2-hop test
        args = { "gift", 1 }, -- confirmed live: Rewards:InvokeServer("gift", index)
        slot = 2,
        slotWasString = false,
        calibrationIndex = nil,
        calibrationVerdict = "success", -- contract verified in live claims, not manual calibration
        manualConfirmed = true, -- zero interaction required to start claiming
        claimed = {},
        claimedViaRemote = {},
        attempted = {},
        rewardNextTryAt = {},
        rewardEarlyEnabled = true, -- test-only: small number of early server probes
        rewardEarlySeconds = 12,
        rewardBusy = false,
        hops = resumed and math.floor(tonumber(resumed.hops) or 0) or 0,
        sessionStart = os.clock(),
        maxHops = 2, -- test-only brake against infinite server hopping
        status = "Auto Resgate inicializando — sem captura manual.",
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
    local workspaceFolder=Instance.new("Folder")
    workspaceFolder.Name="PVEXU_EventLab_Logs"
    workspaceFolder.Parent=game:GetService("Workspace")
    state.workspaceFolder=workspaceFolder
    state.workspaceLogCount=0

    local function summarize(value, depth, visited)
        depth = depth or 0
        local kind = typeof(value)
        if kind == "string" then
            return string.format("%q", string.sub(value,1,220))
        elseif kind == "number" or kind == "boolean" or kind == "nil" then
            return tostring(value)
        elseif kind == "Vector3" then
            return string.format("Vector3(%.1f,%.1f,%.1f)",value.X,value.Y,value.Z)
        elseif kind == "table" then
            if depth>=3 then return "{...}" end
            visited=visited or {}
            if visited[value] then return "<circular table>" end
            visited[value]=true
            local entries={}
            for k,v in pairs(value) do
                if #entries>=12 then break end
                entries[#entries+1]=tostring(k).."="..summarize(v,depth+1,visited)
            end
            visited[value]=nil
            return "{"..table.concat(entries,",").."}"
        end
        return "<"..kind..">"
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
        if state.workspaceFolder and state.workspaceFolder.Parent then
            state.workspaceLogCount=state.workspaceLogCount+1
            local entry=Instance.new("StringValue")
            entry.Name=string.format("%05d_%s",state.workspaceLogCount,
                tostring(category):gsub("[^%w]","_"):sub(1,25))
            entry.Value=line
            entry.Parent=state.workspaceFolder
            if #state.workspaceFolder:GetChildren()>140 then
                state.workspaceFolder:GetChildren()[1]:Destroy()
            end
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

    -- UI gift timer/status from the game's native HUD.Presentes (8 indexed cards).
    -- A decompiled client cannot verify the server implementation; use the real
    -- UI for scheduling and the RemoteFunction result as the claim authority.
    local nativeGiftGrid=nil
    local lastNativeSnapshot=""
    local function countdownToSeconds(value)
        if type(value)~="string" then return nil end
        local textValue=string.lower(value)
        local hours=tonumber(textValue:match("(%d+)%s*h")) or 0
        local minutes=tonumber(textValue:match("(%d+)%s*m")) or 0
        local seconds=tonumber(textValue:match("(%d+)%s*s")) or 0
        if hours+minutes+seconds>0 then return hours*3600+minutes*60+seconds end
        if textValue:match("^%s*0%s*s%s*$") then return 0 end
        local mm,ss=textValue:match("(%d+):(%d%d)")
        if mm then return tonumber(mm)*60+tonumber(ss) end
        return nil
    end
    local function findGiftGrid()
        if nativeGiftGrid and nativeGiftGrid.Parent then return nativeGiftGrid end
        local pg=player:FindFirstChildOfClass("PlayerGui")
        local hud=pg and pg:FindFirstChild("HUD")
        local gifts=hud and hud:FindFirstChild("Presentes",true)
        if not gifts then return nil end
        for _,node in ipairs(gifts:GetDescendants()) do
            if node:IsA("Frame") and node:FindFirstChildOfClass("UIGridLayout") then
                local count=0
                for _,child in ipairs(node:GetChildren()) do
                    if child:IsA("Frame") then count=count+1 end
                end
                if count==#giftMinutes then
                    nativeGiftGrid=node
                    return node
                end
            end
        end
        return nil
    end
    local function giftCards()
        local grid=findGiftGrid()
        if not grid then return nil end
        local cards={}
        for _,child in ipairs(grid:GetChildren()) do
            if child:IsA("Frame") then cards[#cards+1]=child end
        end
        table.sort(cards,function(a,b)
            if a.LayoutOrder~=b.LayoutOrder then return a.LayoutOrder<b.LayoutOrder end
            return a.AbsolutePosition.Y==b.AbsolutePosition.Y
                and a.AbsolutePosition.X<b.AbsolutePosition.X
                or a.AbsolutePosition.Y<b.AbsolutePosition.Y
        end)
        return cards
    end
    local function readNativeGift(index)
        local cards=giftCards()
        local card=cards and cards[index]
        if not card then return {status="missing",text="card not found"} end
        local face=card:FindFirstChild("Face",true)
        if not face then return {status="unknown",text="Face button not found"} end
        local display=nil
        for _,child in ipairs(face:GetDescendants()) do
            if child:IsA("TextLabel") then display=child;break end
        end
        local value=display and tostring(display.Text or "")
            or (face:IsA("TextButton") and tostring(face.Text or "") or "")
        local normalized=string.lower(value)
        normalized=normalized:gsub("^%s+",""):gsub("%s+$","")
        if normalized=="✓" or normalized=="✔"
            or normalized:find("claimed",1,true) or normalized:find("resgatado",1,true)
            or normalized:find("collected",1,true) or normalized:find("coletado",1,true) then
            return {status="claimed",text=value}
        end
        local remaining=countdownToSeconds(value)
        if remaining~=nil then
            return {status="waiting",remaining=remaining,text=value}
        end
        if normalized:find("claim",1,true)
            or normalized:find("resgatar",1,true)
            or normalized:find("coletar",1,true)
            or normalized:find("ready",1,true) or normalized:find("pronto",1,true) then
            return {status="ready",remaining=0,text=value}
        end
        return {status="unknown",text=value}
    end
    local function logNativeCards(force)
        local snapshot={}
        for index=1,#giftMinutes do
            local card=readNativeGift(index)
            snapshot[#snapshot+1]="#"..index..":"..card.status
                .."="..tostring(card.text)
        end
        local joined=table.concat(snapshot," | ")
        if force or joined~=lastNativeSnapshot then
            -- Frequent countdown changes are not useful in file logs.
            local stamp=os.clock()
            if force or (state.lastNativeLog or 0)+12<=stamp then
                lastNativeSnapshot=joined
                state.lastNativeLog=stamp
                log("REWARD_NATIVE_UI",joined)
            end
        end
    end
    state.readNativeGift=readNativeGift
    state.logNativeCards=logNativeCards
    local function logVisibleGiftTimer()
        logNativeCards(true)
    end

    local function claim(index)
        if state.rewardBusy then
            log("REWARD_BUSY","Another claim request is still in flight")
            return "busy","request in flight"
        end
        state.rewardBusy=true
        local args = table.clone(state.args)
        args[state.slot] = state.slotWasString and tostring(index) or index
        local started = os.clock()
        local elapsed = started-state.sessionStart
        local due = (giftMinutes[index] or 0)*60
        local before = due-elapsed
        local serverClock=game:GetService('Workspace'):GetServerTimeNow()
        log("REWARD_SEND","index="..index.." elapsed="..string.format("%.2f",elapsed)
            .." seconds_until_nominal="..string.format("%.2f",before)
            .." server_clock="..string.format("%.3f",serverClock)
            .." args="..summarizeArgs(args))
        local ok, answer = pcall(function()
            return rewards:InvokeServer(table.unpack(args, 1, #args))
        end)
        local latency=os.clock()-started
        state.rewardBusy=false
        if not ok then
            log("REWARD_ERROR","index="..index.." error="..tostring(answer)
                .." request_sec="..string.format("%.3f",latency))
            return "error", tostring(answer)
        end
        local result=verdict(answer)
        log("REWARD_ATTEMPT","claim #"..index.." args="..summarizeArgs(args)
            .." result="..summarize(answer).." verdict="..result
            .." request_sec="..string.format("%.3f",latency)
            .." nominal_offset_sec="..string.format("%.2f",elapsed-due))
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
        if state.workspaceFolder then pcall(function() state.workspaceFolder:Destroy() end) end
        if env.PVEXU_GiftTest == state then env.PVEXU_GiftTest = nil end
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "PVExu_GiftHop_TEST"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999
    gui.IgnoreGuiInset = true
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
    root.Size = UDim2.fromOffset(430, 450)
    local camera=game:GetService("Workspace").CurrentCamera
    local vp=camera and camera.ViewportSize or Vector2.new(900,600)
    local baseScale=math.min(1,(vp.X-20)/430,(vp.Y-35)/450)
    local scale=Instance.new("UIScale")
    scale.Scale=math.max(0.45,baseScale)
    scale.Parent=root
    root.Position = UDim2.new(1, -(430*scale.Scale+12), 0, 30)
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
        root.Size=UDim2.fromOffset(430,minimized and 38 or 450)
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

    local scanUi=Instance.new("TextButton")
    scanUi.Name="ScanGiftsUI"
    scanUi.Text="INSPECIONAR PRESENTES"
    scanUi.TextColor3=Color3.fromRGB(241,225,255)
    scanUi.Font=Enum.Font.GothamBold
    scanUi.TextSize=11
    scanUi.BackgroundColor3=Color3.fromRGB(75,65,96)
    scanUi.Position=UDim2.new(0,205,1,-44)
    scanUi.Size=UDim2.fromOffset(212,32)
    scanUi.Parent=logsPage
    Instance.new("UICorner",scanUi).CornerRadius=UDim.new(0,6)
    state.callbacks[#state.callbacks+1]=scanUi.Activated:Connect(function()
        log("PROBE_START","Inspect PlayerGui and attributes for reward state.")
        local count=0
        local pg=player:FindFirstChildOfClass("PlayerGui")
        if pg then
            for _,element in ipairs(pg:GetDescendants()) do
                if element:IsA("TextLabel") or element:IsA("TextButton") then
                    local textValue=tostring(element.Text or "")
                    local lower=string.lower(textValue)
                    if lower:find("resgat",1,true) or lower:find("present",1,true)
                        or lower:find("claim",1,true) or lower:find("minutos",1,true) then
                        count=count+1
                        if count<=25 then
                            local visible=element.Visible
                            log("PROBE_UI","["..element.ClassName.."] path="
                                ..element:GetFullName().." visible="..tostring(visible)
                                .." text="..string.sub(textValue,1,105))
                        end
                    end
                end
            end
        end
        log("PROBE_UI","matching text controls="..count)
        for name,value in pairs(player:GetAttributes()) do
            local key=string.lower(tostring(name))
            if key:find("gift",1,true) or key:find("reward",1,true)
                or key:find("present",1,true) or key:find("time",1,true)
                or key:find("cash",1,true) or key:find("speed",1,true)
                or key:find("money",1,true) then
                log("PROBE_ATTR",tostring(name).."="..summarize(value))
            end
        end
        log("PROBE_END","Saved in "..(state.fileLogging and state.logFile or "console only"))
    end)

    state.callbacks[#state.callbacks+1]=copy.Activated:Connect(function()
        if type(setclipboard)=="function" then
            local ok=pcall(setclipboard,table.concat(state.logLines,"\n"))
            log("LOG_EXPORT",ok and "copied" or "clipboard denied")
        else
            log("LOG_EXPORT","no setclipboard; read "..state.logFile)
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

    button("CONFERIR CONTRATO",12,143,176,function()
        log("REWARD_CONTRACT","RemoteFunction="..(rewards and rewards:GetFullName() or "MISSING")
            .." method=InvokeServer args=gift,index integer"
            .." verified_live_indices=1,2"
            .." saved_claims="..tostring(#(state.claimed or {})))
        setStatus("Resgate automático já configurado. Protocolo: Rewards('gift', índice).")
    end)
    button("LER CARTÕES NATIVOS",198,143,178,function()
        if type(state.logNativeCards)=="function" then state.logNativeCards(true) end
        setStatus("Estado dos 8 presentes registrado na aba Logs.")
    end)

    local function startAuto(reason)
        if not rewards or not rewards:IsA("RemoteFunction") then
            setStatus("Rewards RemoteFunction ausente; Auto não pode iniciar.")
            log("REWARD_AUTO_ERROR","Missing RemoteFunction ReplicatedStorage.Remotes.Rewards")
            return false
        end
        local toggles = type(env.Toggles)=="table" and env.Toggles or nil
        local noExuHop = toggles and toggles.PVEXU_ServerHopNoExu
        if noExuHop and noExuHop.Value == true then
            setStatus("Desative o antigo Server Hop sem Exus, ele interrompe o ciclo de presentes.")
            log("REWARD_AUTO_CONFLICT","PVEXU_ServerHopNoExu is ON")
            return false
        end
        if state.running then return true end
        state.running=true
        state.manualConfirmed=true
        state.args={"gift",1}
        state.slot=2
        state.slotWasString=false
        log("REWARD_AUTO_START","reason="..tostring(reason)
            .." protocol=Rewards:InvokeServer('gift',index) no_calibration=true"
            .." ui_sync=on server_verified=true")
        setStatus("Auto Resgate ATIVO. Sem captura manual; aguardando os presentes liberarem.")
        return true
    end
    local autoButton
    autoButton=button("AUTO RESGATE: LIGADO",12,185,176,function()
        if state.running then
            state.running=false
            log("REWARD_AUTO","paused by user")
            setStatus("Auto Resgate pausado.")
        else
            startAuto("manual resume")
        end
        autoButton.Text=state.running and "AUTO RESGATE: LIGADO" or "AUTO RESGATE: PAUSADO"
    end)

    button("PARAR", 198, 185, 178, function()
        state.running = false
        state.armed = false
        autoButton.Text = "AUTO RESGATE: PAUSADO"
        setStatus("Pausado. Nada será resgatado ou teleportado.")
    end)


    button("TESTAR PRÓXIMO AGORA", 12, 272, 364, function()
        if not rewards or not rewards:IsA("RemoteFunction")
            or not state.args or not state.slot then
            setStatus("Protocolo Rewards indisponível. Consulte a aba Logs.")
            return
        end
        local nextIndex
        for i=1,#giftMinutes do
            if not state.claimed[i] then nextIndex=i; break end
        end
        if not nextIndex then
            setStatus("Todos os oito marcados. Nada a testar.")
            return
        end
        log("REWARD_MANUAL_PROBE","One-shot probe for #" .. nextIndex)
        task.spawn(function()
            local outcome,detail=claim(nextIndex)
            setStatus("Teste prêmio #" .. nextIndex .. ": " .. outcome
                .. ". Resposta=" .. string.sub(detail,1,120))
            if outcome=="success" then
                state.claimed[nextIndex]=true
            else
                log("REWARD_PROBE_WARNING","Not marked claimed. Verify server/UI state.")
            end
        end)
    end)


    local earlyButton
    earlyButton = button("FALLBACK SEM HUD 12s: ON", 12, 312, 364, function()
        state.rewardEarlyEnabled = not state.rewardEarlyEnabled
        earlyButton.Text = state.rewardEarlyEnabled
            and "FALLBACK SEM HUD 12s: ON" or "FALLBACK SEM HUD 12s: OFF"
        log("REWARD_EARLY_MODE","enabled="..tostring(state.rewardEarlyEnabled)
            .." (only 12-second diagnostics; no timer spoof)")
        setStatus(state.rewardEarlyEnabled
            and "Teste antecipado: poucas tentativas antes do prazo para medir resposta do servidor."
            or "Modo conservador: espera o prazo nominal de cada prêmio.")
    end)

    local hopButton
    hopButton = button(state.autoHop and "HOP APÓS 30 MIN: ON" or "HOP APÓS 30 MIN: OFF",
        12, 227, 364, function()
            state.autoHop = not state.autoHop
            hopButton.Text = state.autoHop and "HOP APÓS 30 MIN: ON" or "HOP APÓS 30 MIN: OFF"
            setStatus(state.autoHop and "Hop habilitado após TODOS os resgates confirmados."
                or "Hop desabilitado; apenas auto resgate.")
        end)


    -- HALLOWEEN: the real game's daily missions live in player attribute
    -- HwDaily, with [{i=<pool index>, n=<progress>}, ...]. Actual targets arrive
    -- via the native server -> client Hw events. No made-up claim remote.
    local Workspace=game:GetService("Workspace")
    local PathfindingService=game:GetService("PathfindingService")
    local remotes=ReplicatedStorage:FindFirstChild("Remotes")
    local hw=remotes and remotes:FindFirstChild("Hw")
    local halloweenModule=ReplicatedStorage:FindFirstChild("Shared")
    halloweenModule=halloweenModule and halloweenModule:FindFirstChild("Halloween")
    local halloweenData
    if halloweenModule and halloweenModule:IsA("ModuleScript") then
        local ok,result=pcall(require,halloweenModule)
        if ok and type(result)=="table" then halloweenData=result end
    end
    state.halloweenAuto=false
    state.dailyMissions={}
    state.hwTargets={pick={},tomb={},skel={},ghost={},giant={}}
    state.targetCooldown={}
    state.hwLastKind=tostring(Workspace:GetAttribute("HwKind") or "")
    log("HALLOWEEN_BOOT","module="..tostring(halloweenData~=nil)
        .." Hw="..tostring(hw and hw.ClassName)
        .." HwKind="..state.hwLastKind
        .." InHw="..tostring(player:GetAttribute("InHw")))
    local questTitle=Instance.new("TextLabel")
    questTitle.Name="QuestStatus"
    questTitle.Font=Enum.Font.GothamBold
    questTitle.TextSize=13
    questTitle.TextXAlignment=Enum.TextXAlignment.Left
    questTitle.TextColor3=Color3.fromRGB(255,187,105)
    questTitle.BackgroundTransparency=1
    questTitle.Size=UDim2.new(1,-20,0,28)
    questTitle.Position=UDim2.fromOffset(12,6)
    questTitle.Parent=halloweenPage
    local progressLabels={}
    for i=1,3 do
        local box=Instance.new("Frame")
        box.Name="Quest"..i
        box.BackgroundColor3=Color3.fromRGB(39,29,47)
        box.BorderSizePixel=0
        box.Size=UDim2.new(1,-22,0,45)
        box.Position=UDim2.fromOffset(11,35+(i-1)*51)
        box.Parent=halloweenPage
        Instance.new("UICorner",box).CornerRadius=UDim.new(0,7)
        local t=Instance.new("TextLabel")
        t.Font=Enum.Font.GothamMedium
        t.TextSize=12
        t.TextWrapped=true
        t.TextXAlignment=Enum.TextXAlignment.Left
        t.TextColor3=Color3.fromRGB(237,224,247)
        t.Text="Missão "..i.." — aguardando HwDaily"
        t.BackgroundTransparency=1
        t.Size=UDim2.new(1,-14,1,0)
        t.Position=UDim2.fromOffset(7,0)
        t.Parent=box
        progressLabels[i]=t
    end
    local hwDetail=Instance.new("TextLabel")
    hwDetail.Text="Eventos de Halloween: coleta e tumbas por aproximação."
    hwDetail.Font=Enum.Font.Gotham
    hwDetail.TextSize=11
    hwDetail.TextWrapped=true
    hwDetail.TextXAlignment=Enum.TextXAlignment.Left
    hwDetail.TextYAlignment=Enum.TextYAlignment.Top
    hwDetail.TextColor3=Color3.fromRGB(205,199,219)
    hwDetail.BackgroundTransparency=1
    hwDetail.Position=UDim2.fromOffset(14,194)
    hwDetail.Size=UDim2.new(1,-28,0,58)
    hwDetail.Parent=halloweenPage

    local function readDaily()
        local raw=tostring(player:GetAttribute("HwDaily") or "[]")
        local ok,result=pcall(function() return HttpService:JSONDecode(raw) end)
        if not ok or type(result)~="table" then
            log("HW_DAILY_ERROR","Invalid HwDaily attribute: "..string.sub(raw,1,350))
            result={}
        end
        local previous=state.dailyMissions
        state.dailyMissions=result
        local labelParts={}
        for i=1,3 do
            local item=result[i]
            local pool=halloweenData and halloweenData.daily and halloweenData.daily.pool
            local config=item and pool and pool[tonumber(item.i) or 0]
            if type(config)=="table" then
                local count=tonumber(item.n) or 0
                local goal=tonumber(config.goal) or 0
                local completed=goal>0 and count>=goal
                progressLabels[i].Text=(completed and "✓ " or "◌ ") .. tostring(config.text)
                    .. "\n"..tostring(count).."/"..tostring(goal)..
                    "  •  +"..tostring(config.doces or 0).." doces"
                progressLabels[i].TextColor3=completed
                    and Color3.fromRGB(153,249,181) or Color3.fromRGB(238,226,246)
                labelParts[#labelParts+1]=tostring(config.k)..":"..count.."/"..goal
            else
                progressLabels[i].Text="Missão "..i..": não carregada"
            end
        end
        questTitle.Text="MISSÕES DIÁRIAS (3)  •  EVENTO: "
            ..tostring(Workspace:GetAttribute("HwKind") or "aguardando")
        log("HW_DAILY",table.concat(labelParts," | ")
            .." | Doces="..tostring(player:GetAttribute("Doces")))
    end
    readDaily()
    state.callbacks[#state.callbacks+1]=player:GetAttributeChangedSignal("HwDaily"):Connect(readDaily)
    state.callbacks[#state.callbacks+1]=player:GetAttributeChangedSignal("Doces"):Connect(function()
        log("HW_CANDY","Doces="..tostring(player:GetAttribute("Doces")))
    end)
    state.callbacks[#state.callbacks+1]=Workspace:GetAttributeChangedSignal("HwKind"):Connect(function()
        local newKind=tostring(Workspace:GetAttribute("HwKind") or "")
        log("HW_EVENT","kind="..newKind.." previous="..state.hwLastKind)
        state.hwLastKind=newKind
        state.hwTargets={pick={},tomb={},skel={},ghost={},giant={}}
        state.targetCooldown={}
        questTitle.Text="MISSÕES DIÁRIAS (3)  •  EVENTO: "..newKind
    end)

    local function targetPos(data)
        if type(data)~="table" then return nil end
        local v=data.pos
        return typeof(v)=="Vector3" and v or nil
    end
    if hw and hw:IsA("RemoteEvent") then
        state.callbacks[#state.callbacks+1]=hw.OnClientEvent:Connect(function(event,data)
            if not state.alive or type(event)~="string" then return end
            local id=type(data)=="table" and data.id or nil
            local pos=targetPos(data)
            local key=id~=nil and tostring(id) or nil
            if event=="pick+" and key and pos then
                state.hwTargets.pick[key]=pos
                log("HW_TARGET","pumpkin+ id="..key.." pos="..summarize(pos))
            elseif event=="pick-" and key then
                state.hwTargets.pick[key]=nil
                log("HW_TARGET","pumpkin- id="..key)
            elseif event=="tomb+" and key and pos then
                state.hwTargets.tomb[key]=pos
                log("HW_TARGET","tomb+ id="..key.." pos="..summarize(pos))
            elseif event=="tombSeal" and key then
                state.hwTargets.tomb[key]=nil
                log("HW_TARGET","tombSeal id="..key)
            elseif event=="skel+" and key and pos then
                state.hwTargets.skel[key]=pos
                log("HW_TARGET","skeleton+ id="..key.." pos="..summarize(pos))
            elseif event=="skelDie" and key then
                state.hwTargets.skel[key]=nil
                log("HW_TARGET","skeleton- id="..key)
            elseif event=="gh+" and key and pos then
                state.hwTargets.ghost[key]=pos
                log("HW_TARGET","ghost+ id="..key.." pos="..summarize(pos))
            elseif event=="gh-" and key then
                state.hwTargets.ghost[key]=nil
                log("HW_TARGET","ghost- id="..key)
            elseif event=="giantFall" and pos then
                state.hwTargets.giant["active"]=pos
                log("HW_TARGET","giant pos="..summarize(pos))
            elseif event=="giantBreak" then
                state.hwTargets.giant={}
                log("HW_TARGET","giant defeated")
            elseif event=="dailyDone" then
                log("HW_DAILY_DONE","server event="..summarize(data))
                task.defer(readDaily)
            elseif event=="open" or event=="over" or event=="entered"
                or event=="left" or event=="reward" or event=="goal"
                or event=="mapClear" or event=="portalShut" then
                log("HW_EVENT",event.." payload="..summarize(data))
            end
        end)
    else
        log("HW_ERROR","No ReplicatedStorage.Remotes.Hw RemoteEvent; monitor unavailable.")
    end

    local function activeQuest(key)
        local pool=halloweenData and halloweenData.daily and halloweenData.daily.pool
        if not pool then return false end
        for _,slot in ipairs(state.dailyMissions) do
            local cfg=pool[tonumber(slot.i) or 0]
            if cfg and cfg.k==key and (tonumber(slot.n) or 0)<(tonumber(cfg.goal) or 0) then
                return true
            end
        end
        return false
    end

    local function nearestTarget(kind)
        local map=state.hwTargets[kind]
        if not map then return nil,nil end
        local char=player.Character
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil,nil end
        local bestId,bestPos,bestDist
        local now=os.clock()
        for id,pos in pairs(map) do
            if typeof(pos)=="Vector3" and (state.targetCooldown[kind..id] or 0)<=now then
                local distance=(hrp.Position-pos).Magnitude
                if bestDist==nil or distance<bestDist then
                    bestId,bestPos,bestDist=id,pos,distance
                end
            end
        end
        return bestId,bestPos
    end

    -- MoveTo + Pathfinding: the server must still register the physical action.
    -- Do not teleport directly or invent reward/quest remote parameters.
    local function walkNear(position,radius,reason)
        local character=player.Character
        local humanoid=character and character:FindFirstChildWhichIsA("Humanoid")
        local rootPart=character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart or humanoid.Health<=0 then
            log("HW_MOVE_ERROR","No alive humanoid/root for "..reason)
            return false
        end
        local distance=(position-rootPart.Position).Magnitude
        log("HW_MOVE","target="..reason.." dist="..math.floor(distance)
            .." radius="..radius)
        if distance<=radius then return true end
        local waypoints=nil
        local ok,path=pcall(function()
            local p=PathfindingService:CreatePath({
                AgentRadius=2, AgentHeight=5, AgentCanJump=true,
                WaypointSpacing=4,
            })
            p:ComputeAsync(rootPart.Position,position)
            return p
        end)
        if ok and path.Status==Enum.PathStatus.Success then
            waypoints=path:GetWaypoints()
        end
        if not waypoints or #waypoints==0 then
            waypoints={{Position=position}}
            log("HW_MOVE","Pathfinding unavailable; direct Humanoid:MoveTo fallback")
        end
        local start=os.clock()
        for _,wp in ipairs(waypoints) do
            if not state.alive or not state.halloweenAuto then return false end
            if humanoid.Health<=0 then return false end
            if wp.Action==Enum.PathWaypointAction.Jump then humanoid.Jump=true end
            humanoid:MoveTo(wp.Position)
            while state.alive and state.halloweenAuto and os.clock()-start<38 do
                if not rootPart.Parent then return false end
                if (rootPart.Position-position).Magnitude<=radius then return true end
                if (rootPart.Position-wp.Position).Magnitude<3.5 then break end
                task.wait(0.22)
            end
            if os.clock()-start>=38 then
                log("HW_MOVE_ERROR","timeout after 38s: "..reason)
                return false
            end
        end
        return (rootPart.Position-position).Magnitude<=radius
    end
    local function missionTick()
        if not state.halloweenAuto or state.halloweenMoving then return end
        local kind=tostring(Workspace:GetAttribute("HwKind") or "")
        local objective,category,radius,linger
        if kind=="hunt" and activeQuest("pick") then
            objective,category,radius,linger="pick","pick",7,4
        elseif kind=="graves" and activeQuest("seal") then
            objective,category,radius,linger="seal","tomb",9,20
        else
            return
        end
        local id,pos=nearestTarget(category)
        if not id then return end
        state.halloweenMoving=true
        task.spawn(function()
            local ok,err=pcall(function()
                log("HW_AUTO_START",objective.." id="..id)
                local arrived=walkNear(pos,radius,objective..":"..id)
                if not arrived then
                    log("HW_AUTO_WARN","failed to approach "..objective.." id="..id)
                else
                    log("HW_AUTO_ARRIVED",objective.." id="..id.." waiting for server progress")
                    local started=os.clock()
                    while state.alive and state.halloweenAuto
                        and os.clock()-started<linger do
                        if not state.hwTargets[category][id] then
                            log("HW_AUTO_SUCCESS",objective.." target removed by server id="..id)
                            break
                        end
                        task.wait(0.5)
                    end
                end
                state.targetCooldown[category..id]=os.clock()+15
            end)
            if not ok then log("HW_AUTO_ERROR",tostring(err)) end
            state.halloweenMoving=false
        end)
    end

    local autoQuestsButton
    autoQuestsButton=Instance.new("TextButton")
    autoQuestsButton.Text="INICIAR CAÇA / TUMBAS"
    autoQuestsButton.TextColor3=Color3.new(1,1,1)
    autoQuestsButton.Font=Enum.Font.GothamBold
    autoQuestsButton.TextSize=12
    autoQuestsButton.BackgroundColor3=Color3.fromRGB(147,76,28)
    autoQuestsButton.Position=UDim2.fromOffset(12,254)
    autoQuestsButton.Size=UDim2.fromOffset(239,36)
    autoQuestsButton.Parent=halloweenPage
    Instance.new("UICorner",autoQuestsButton).CornerRadius=UDim.new(0,7)
    state.callbacks[#state.callbacks+1]=autoQuestsButton.Activated:Connect(function()
        local toggles=type(env.Toggles)=="table" and env.Toggles or nil
        local farm=toggles and toggles.PVEXU_AutoFarm
        local otherHop=toggles and toggles.PVEXU_ServerHopNoExu
        if not state.halloweenAuto and ((farm and farm.Value==true)
            or (otherHop and otherHop.Value==true)) then
            log("HW_AUTO_BLOCK","Conflicting Exu AutoFarm or no-Exu Hop is on.")
            hwDetail.Text="Desative Auto Farm e Auto Hop por falta de Exus antes de iniciar."
            return
        end
        state.halloweenAuto=not state.halloweenAuto
        autoQuestsButton.Text=state.halloweenAuto and "PARAR AUTO EVENTO" or "INICIAR CAÇA / TUMBAS"
        log("HW_AUTO",state.halloweenAuto and "enabled: pumpkins/graves only"
            or "disabled by user")
        hwDetail.Text=state.halloweenAuto
            and "AUTO: aguardando evento + missão ativa. Usa MoveTo; não garante o progresso."
            or "Outras 7 missões: monitoramento e logs; automação ainda não validada."
    end)
    local refreshQuest=Instance.new("TextButton")
    refreshQuest.Text="ATUALIZAR"
    refreshQuest.TextColor3=Color3.new(1,1,1)
    refreshQuest.Font=Enum.Font.GothamBold
    refreshQuest.TextSize=12
    refreshQuest.BackgroundColor3=Color3.fromRGB(83,59,116)
    refreshQuest.Position=UDim2.fromOffset(260,254)
    refreshQuest.Size=UDim2.fromOffset(156,36)
    refreshQuest.Parent=halloweenPage
    Instance.new("UICorner",refreshQuest).CornerRadius=UDim.new(0,7)
    state.callbacks[#state.callbacks+1]=refreshQuest.Activated:Connect(readDaily)
    task.spawn(function()
        while state.alive do
            if state.halloweenAuto then
                local ok,err=pcall(missionTick)
                if not ok then log("HW_TICK_ERROR",tostring(err)) end
                if (state.nextHwHeartbeat or 0)<=os.clock() then
                    state.nextHwHeartbeat=os.clock()+25
                    local function countTargets(t)
                        local n=0
                        for _ in pairs(t or {}) do n=n+1 end
                        return n
                    end
                    log("HW_IDLE","kind="..tostring(Workspace:GetAttribute("HwKind"))
                        .." daily="..tostring(#state.dailyMissions)
                        .." tracked_pumpkins="..countTargets(state.hwTargets.pick)
                        .." tracked_tombs="..countTargets(state.hwTargets.tomb)
                        .." moving="..tostring(state.halloweenMoving==true))
                end
            end
            task.wait(1.7)
        end
    end)

    state.callbacks[#state.callbacks + 1] =
        TeleportService.TeleportInitFailed:Connect(function(who, result)
            if who == player and state.busy then
                state.busy = false
                setStatus("Não foi possível iniciar teleporte: " .. tostring(result))
            end
        end)

    -- A reward is attempted only when the actual server responds; our local clock
    -- is just a conservative estimate. In test mode a few early probes reveal
    -- whether the reward gate is server-enforced without spoofing client time.
    task.spawn(function()
        while state.alive do
            if state.running and not state.busy then
                local elapsed = os.clock()-state.sessionStart
                local nextIndex
                for i=1,#giftMinutes do
                    if not state.claimed[i] then
                        local card=state.readNativeGift and state.readNativeGift(i)
                        if card and card.status=="claimed" then
                            state.claimed[i]=true
                            log("REWARD_ALREADY_CLAIMED","index="..i.." ui="..tostring(card.text))
                            if state.hops>0 and i==1 then
                                state.running=false
                                state.autoHop=false
                                state.unverified=true
                                setStatus("Servidor novo não reiniciou os presentes. Parado.")
                                log("REWARD_NO_RESET","gift #1 was already claimed after hop")
                                break
                            end
                        else
                            nextIndex=i
                            break
                        end
                    end
                end
                if state.running and not nextIndex then
                    state.running=false
                    if state.autoHop and state.claimedViaRemote[8]
                        and not state.unverified then
                        hop()
                    else
                        setStatus("Todas as 8 recompensas confirmadas. Hop: "
                            ..(state.autoHop and "bloqueado/sem evidência" or "desligado")..".")
                    end
                elseif state.running and nextIndex then
                    local due=giftMinutes[nextIndex]*60
                    local native=state.readNativeGift and state.readNativeGift(nextIndex) or {status="missing"}
                    local nativeKnown=native.status=="waiting" or native.status=="ready"
                    local secondsRemaining=(native.status=="waiting" and native.remaining)
                        or (native.status=="ready" and 0) or (due-elapsed)
                    local early=nativeKnown and 1.2
                        or (state.rewardEarlyEnabled and state.rewardEarlySeconds or 0)
                    if (state.nextGiftHeartbeat or 0)<=os.clock() then
                        state.nextGiftHeartbeat=os.clock()+12
                        log("REWARD_WAIT","index="..nextIndex
                            .." remaining="..string.format("%.1f",secondsRemaining)
                            .." source="..(nativeKnown and "native_hud" or "local_fallback")
                            .." ui_text="..tostring(native.text)
                            .." early_mode="..tostring(state.rewardEarlyEnabled)
                            .." attempts="..tostring(state.attempted[nextIndex] or 0))
                    end
                    if state.statusLabel and os.clock()>=(state.nextStatusRefresh or 0) then
                        state.nextStatusRefresh=os.clock()+1
                        state.statusLabel.Text="🎁 AUTO RESGATE ATIVO\n"
                            .."Próximo: #"..nextIndex.." ("..giftMinutes[nextIndex].."min)"
                            .." | faltam "..math.max(0,math.ceil(secondsRemaining)).."s"
                            .."\nFonte: "..(nativeKnown and "tempo real do jogo"
                                or "tempo aproximado")
                    end
                    if secondsRemaining<=early and elapsed>=(state.rewardNextTryAt[nextIndex] or 0)
                        and not state.rewardBusy then
                        local tries=state.attempted[nextIndex] or 0
                        if tries>=9 or elapsed>due+80 then
                            state.running=false
                            state.unverified=true
                            log("REWARD_STOP","index="..nextIndex.." retry budget exhausted"
                                .." offset="..string.format("%.1f",elapsed-due))
                            setStatus("Prêmio #"..nextIndex
                                .." rejeitado repetidamente. Interrompido para diagnóstico.")
                        else
                            state.attempted[nextIndex]=tries+1
                            local earlyAttempt=secondsRemaining>0
                            log("REWARD_PROBE","index="..nextIndex
                                .." attempt="..state.attempted[nextIndex]
                                .." early="..tostring(earlyAttempt)
                                .." early_by="..string.format("%.1f",math.max(0,secondsRemaining)))
                            if state.attempted[nextIndex] == 1 then
                                logVisibleGiftTimer()
                            end
                            local outcome,detail=claim(nextIndex)
                            local afterElapsed=os.clock()-state.sessionStart
                            if outcome=="success" then
                                state.claimed[nextIndex]=true
                                state.claimedViaRemote[nextIndex]=true
                                state.rewardNextTryAt[nextIndex]=nil
                                log("REWARD_ACCEPTED","index="..nextIndex
                                    .." server_return=true"
                                    .." local_offset="..string.format("%.1f",afterElapsed-due)
                                    .." ui_status_before="..native.status
                                    .." ui_text="..tostring(native.text)
                                    .." note=offset_versus_test_start_not_proof_of_bypass")
                                setStatus("Servidor confirmou prêmio #"..nextIndex
                                    .." ("..giftMinutes[nextIndex].."min). "
                                    .."Offset local: "..string.format("%+.1fs",afterElapsed-due))
                            elseif outcome=="failed" then
                                local currentRemaining=due-afterElapsed
                                if currentRemaining>0 then
                                    log("REWARD_GATE","index="..nextIndex
                                        .." server_return=false before test deadline"
                                        .." seconds_to_nominal="..string.format("%.1f",currentRemaining)
                                        .." note=cannot_separate_server_gate_from_session_offset")
                                else
                                    log("REWARD_GATE","index="..nextIndex
                                        .." server_return=false after test deadline"
                                        .." note=possible_server_time_offset_or_claim_state")
                                end
                                -- At most a few probes; no high-frequency remote spam.
                                local delay
                                if native.status=="ready" then
                                    delay=0.9
                                elseif native.status=="waiting" then
                                    delay=math.max(0.8,math.min(2,secondsRemaining/2))
                                else
                                    delay=currentRemaining>0 and math.min(4,math.max(1.2,currentRemaining/4))
                                        or math.min(12,1.8+tries)
                                end
                                state.rewardNextTryAt[nextIndex]=afterElapsed+delay
                                if state.hops>0 and nextIndex==1 and afterElapsed>due+18 then
                                    state.running=false
                                    state.unverified=true
                                    setStatus("Após hop, prêmio #1 não foi aceito. "
                                        .."Pode haver controle por conta; ciclo interrompido.")
                                end
                            elseif outcome=="busy" then
                                state.rewardNextTryAt[nextIndex]=afterElapsed+1.5
                            else
                                state.unverified=true
                                state.running=false
                                log("REWARD_STOP","index="..nextIndex.." outcome="..outcome
                                    .." details="..string.sub(detail,1,180))
                                setStatus("Prêmio #"..nextIndex
                                    .." retornou "..outcome..". Auto pausado. Veja a aba Logs.")
                            end
                        end
                    end
                end
            end
            task.wait(0.25)
        end
    end)

    -- Initial resume is never enough to trust a reset across servers:
    -- the first gift must be positively accepted by the server.
    if resumed then
        state.autoHop=resumed.autoHop==true
        log("REWARD_RESUME","new server hop="..state.hops
            .." saved_verdict="..tostring(resumed.verdict)
            .." calibration_not_required=true")
    end
    -- Immediate autostart: no manual capture / confirm / click.
    task.defer(function()
        task.wait(1.5)
        if state.alive then
            startAuto(resumed and "teleport resume" or "initial launch")
            autoButton.Text=state.running and "AUTO RESGATE: LIGADO" or "AUTO RESGATE: PAUSADO"
        end
    end)
end
