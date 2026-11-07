-- Prime Void Hub | Exu no-Exu server hop TEST overlay v1
-- Runs after the protected Exu port. Does not alter its farm or source.
return function()
    local env=(type(getgenv)=="function" and getgenv()) or _G
    if type(env.PVH_ExuHopStop)=="function" then pcall(env.PVH_ExuHopStop) end
    local Players=game:GetService("Players")
    local TeleportService=game:GetService("TeleportService")
    local HttpService=game:GetService("HttpService")
    local UIS=game:GetService("UserInputService")
    local player=Players.LocalPlayer
    local library=env.Library
    local ctrl=type(library)=="table" and type(library.Toggles)=="table"
        and library.Toggles.PVEXU_ServerHopNoExu or nil
    local farm=type(library)=="table" and type(library.Toggles)=="table"
        and library.Toggles.PVEXU_AutoFarm or nil
    if type(ctrl)~="table" or type(ctrl.SetValue)~="function" then
        warn("[PVH EXU HOP TEST] Existing Exu Auto Hop control was not registered")
        return
    end
    local running=true
    local connections={}
    local busy=false
    local lastAttempt=-math.huge
    local noExuSince=nil
    local lastCount=nil
    local lastUnknown=0
    local attempts=0
    local lastFailed=false
    local initialEnabled=ctrl.Value==true
    local prefPath="primevoid_hub/_Universal/exu_hop_test_"..tostring(player.UserId)..".json"
    local prefs={}
    local okPref,result=pcall(function()
        if type(isfile)=="function" and type(readfile)=="function" and isfile(prefPath) then
            return HttpService:JSONDecode(readfile(prefPath))
        end
    end)
    if okPref and type(result)=="table" then prefs=result end
    local seconds=math.clamp(tonumber(prefs.seconds) or 8,3,20)
    seconds=math.floor(seconds+0.5)
    local enabled=type(prefs.enabled)=="boolean" and prefs.enabled or initialEnabled
    local gui=library.ScreenGui
    local delayFrame,delayLabel,fill,handle,manualButton
    local dragging=false
    local oldButton=nil
    local oldCallback=type(ctrl.Callback)=="function" and ctrl.Callback or nil
    local oldChanged=type(ctrl.Changed)=="function" and ctrl.Changed or nil

    -- The protected legacy port has a second, hard-coded eight-second loop.
    -- Turn that older loop off and let this user-configurable loop own the toggle.
    if oldCallback then pcall(oldCallback,false) end
    if oldChanged and oldChanged~=oldCallback then pcall(oldChanged,false) end
    pcall(function()ctrl:SetValue(false)end)
    local function getLanguage()
        local p=env.PVH_Persistence
        if type(p)=="table" and type(p.GetLanguage)=="function" then
            local ok,l=pcall(function()return p:GetLanguage()end)
            if ok then return l end
        end
        return "pt-BR"
    end
    local function save()
        if type(writefile)~="function" then return end
        pcall(function()
            if type(makefolder)=="function" then
                if type(isfolder)=="function" then
                    if not isfolder("primevoid_hub") then makefolder("primevoid_hub") end
                    if not isfolder("primevoid_hub/_Universal") then makefolder("primevoid_hub/_Universal") end
                end
            end
            writefile(prefPath,HttpService:JSONEncode({schema=1,enabled=enabled,seconds=seconds}))
        end)
    end
    local function words()
        if getLanguage()=="en-US" then
            return "Auto server hop if no Exu", "No Exus for: "..seconds.." s", "Server Hop"
        end
        return "Auto trocar servidor sem Exu", "Sem Exus por: "..seconds.." s", "Trocar de servidor"
    end
    local function redraw()
        local toggleText,delayText,manualText=words()
        if type(ctrl.SetText)=="function" then pcall(function()ctrl:SetText(toggleText)end) end
        if delayFrame then delayFrame.Visible=enabled end
        if delayLabel then delayLabel.Text=delayText end
        if fill then fill.Size=UDim2.new((seconds-3)/17,0,1,0) end
        if handle then handle.Position=UDim2.new((seconds-3)/17,-6,0.5,-6) end
        if manualButton then
            for _,node in ipairs(manualButton:GetDescendants()) do
                if node:IsA("TextLabel") then
                    node.Text=manualText
                    break
                end
            end
            if manualButton:IsA("TextButton") and manualButton.Text~="" then
                manualButton.Text=manualText
            end
        end
    end
    ctrl.Callback=function(on)
        enabled=on==true
        noExuSince=nil
        save()
        redraw()
        warn("[PVH EXU HOP TEST] "..(enabled and "ON" or "OFF").." wait="..seconds.."s")
    end
    -- Some Obsidian versions route changes through Changed instead of Callback.
    if oldChanged then ctrl.Changed=ctrl.Callback end
    pcall(function()ctrl:SetValue(enabled)end)
    local function updateSeconds(value)
        seconds=math.clamp(math.floor(tonumber(value) or seconds),3,20)
        noExuSince=nil
        save()
        redraw()
    end

    local function queryServers(url)
        local ok,body=pcall(function()return game:HttpGet(url)end)
        if ok and type(body)=="string" then return body end
        local requestFn=env.request or env.http_request or (env.syn and env.syn.request)
        if type(requestFn)=="function" then
            local ok2,response=pcall(requestFn,{Url=url,Method="GET"})
            if ok2 and type(response)=="table" and (response.Success~=false)
                and type(response.Body)=="string" then
                return response.Body
            end
        end
        return nil
    end

    local function hop(reason)
        if not running or busy or os.clock()-lastAttempt<2 then return end
        busy=true
        lastAttempt=os.clock()
        attempts=attempts+1
        env.PVH_EXU_HopStatus.attempts=attempts
        task.spawn(function()
            local current=tostring(game.JobId)
            local dest,cursor=nil,nil
            for page=1,4 do
                local url="https://games.roblox.com/v1/games/"..tostring(game.PlaceId)
                    .."/servers/Public?sortOrder=Asc&limit=100"
                if cursor then url=url.."&cursor="..HttpService:UrlEncode(cursor) end
                local body=queryServers(url)
                local ok,data=pcall(function()return HttpService:JSONDecode(body or "")end)
                if not ok or type(data)~="table" then
                    warn("[PVH EXU HOP TEST] Could not list Roblox public servers")
                    lastFailed=true;busy=false;noExuSince=nil
                    return
                end
                local choices={}
                for _,entry in ipairs(data.data or {}) do
                    if type(entry.id)=="string" and entry.id~=current
                        and tonumber(entry.playing) and tonumber(entry.maxPlayers)
                        and tonumber(entry.playing)<tonumber(entry.maxPlayers) then
                        choices[#choices+1]=entry.id
                    end
                end
                if #choices>0 then dest=choices[math.random(1,#choices)];break end
                cursor=type(data.nextPageCursor)=="string" and data.nextPageCursor~=""
                    and data.nextPageCursor or nil
                if not cursor then break end
            end
            if not dest then
                warn("[PVH EXU HOP TEST] No other available public server")
                lastFailed=true;busy=false;noExuSince=nil
                return
            end
            warn("[PVH EXU HOP TEST] "..reason.." | "..current.." -> "..dest)
            -- Do NOT queue a loader here. PVH_Persistence_TEST only queues
            -- when Roblox emits an actual OnTeleport event and Autoexec is ON.
            local ok,err=pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId,dest,player)
            end)
            if not ok then
                warn("[PVH EXU HOP TEST] Teleport failed: "..tostring(err))
                lastFailed=true;busy=false;noExuSince=nil
            else
                task.delay(12,function()
                    if running then busy=false;noExuSince=nil end
                end)
            end
        end)
    end

    local function exuCount()
        if typeof(gui)~="Instance" or not gui.Parent then return nil end
        -- The existing Exu session widget exposes the port's own scan result
        -- as "Exus: N"; this avoids guessing which map decorations are NPCs.
        for _,node in ipairs(gui:GetDescendants()) do
            if node:IsA("TextLabel") and type(node.Text)=="string" then
                local n=node.Text:match("^%s*Exus:%s*(%d+)%s*$")
                if n then return tonumber(n) end
            end
        end
        return nil
    end

    local function carrying()
        for _,name in ipairs({"CarregandoExu","IsCarryingExu","CarryingExu","Carregando","IsCarrying"}) do
            if player:GetAttribute(name)==true then return true end
        end
        return false
    end

    -- Native slider inserted after existing Auto Hop and before manual hop.
    local function makeSlider(parent)
        local panel=Instance.new("Frame")
        panel.Name="PVH_EXU_HopWait_TEST"
        panel.BackgroundTransparency=1
        panel.BorderSizePixel=0
        panel.Size=UDim2.new(1,-4,0,48)
        panel.LayoutOrder=-298
        panel.Parent=parent
        local text=Instance.new("TextLabel")
        text.BackgroundTransparency=1
        text.TextColor3=Color3.fromRGB(205,207,213)
        text.Font=Enum.Font.Code
        text.TextSize=13
        text.TextXAlignment=Enum.TextXAlignment.Left
        text.Size=UDim2.new(1,-10,0,20)
        text.Parent=panel
        local track=Instance.new("TextButton")
        track.Name="PVH_Drag"
        track.Text=""
        track.BorderSizePixel=0
        track.BackgroundColor3=Color3.fromRGB(53,54,61)
        track.Size=UDim2.new(1,-12,0,6)
        track.Position=UDim2.new(0,6,0,31)
        track.AutoButtonColor=false
        track.Parent=panel
        local radius=Instance.new("UICorner")
        radius.CornerRadius=UDim.new(1,0)
        radius.Parent=track
        local filled=Instance.new("Frame")
        filled.BackgroundColor3=Color3.fromRGB(139,93,255)
        filled.BorderSizePixel=0
        filled.Size=UDim2.fromScale(0,1)
        filled.Parent=track
        local fr=Instance.new("UICorner")
        fr.CornerRadius=UDim.new(1,0)
        fr.Parent=filled
        local thumb=Instance.new("Frame")
        thumb.BackgroundColor3=Color3.fromRGB(160,119,255)
        thumb.Size=UDim2.fromOffset(12,12)
        thumb.BorderSizePixel=0
        thumb.AnchorPoint=Vector2.new(0,0)
        thumb.Parent=track
        local tr=Instance.new("UICorner")
        tr.CornerRadius=UDim.new(1,0)
        tr.Parent=thumb
        local function dragAt(x)
            local width=track.AbsoluteSize.X
            if width<=0 then return end
            local portion=math.clamp((x-track.AbsolutePosition.X)/width,0,1)
            updateSeconds(math.floor(3+17*portion+0.5))
        end
        connections[#connections+1]=track.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1
                or input.UserInputType==Enum.UserInputType.Touch then
                dragging=true
                dragAt(input.Position.X)
            end
        end)
        connections[#connections+1]=UIS.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement
                or input.UserInputType==Enum.UserInputType.Touch) then
                dragAt(input.Position.X)
            end
        end)
        connections[#connections+1]=UIS.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1
                or input.UserInputType==Enum.UserInputType.Touch then
                dragging=false
            end
        end)
        delayFrame,delayLabel,fill,handle=panel,text,filled,thumb
    end

    local function locateManualButton()
        if typeof(gui)~="Instance" then return nil end
        for _,node in ipairs(gui:GetDescendants()) do
            if node:IsA("TextButton") and node:FindFirstChildOfClass("UIStroke") then
                for _,child in ipairs(node:GetDescendants()) do
                    if child:IsA("TextLabel") then
                        local label=child.Text
                        if label=="Server Hop" or label=="Trocar de servidor" then
                            return node
                        end
                    end
                end
            end
        end
        return nil
    end

    local function build()
        local holder=ctrl.Holder
        local parent=typeof(holder)=="Instance" and holder.Parent or nil
        if parent and parent:IsA("GuiObject") then
            local layout=parent:FindFirstChildOfClass("UIListLayout")
            if layout then layout.SortOrder=Enum.SortOrder.LayoutOrder end
            if typeof(farm.Holder)=="Instance" and farm.Holder.Parent==parent then
                farm.Holder.LayoutOrder=-300
            end
            if holder:IsA("GuiObject") then holder.LayoutOrder=-299 end
            makeSlider(parent)
            oldButton=locateManualButton()
            if oldButton and oldButton.Parent then
                local btn=oldButton:Clone()
                btn.Name="PVH_ManualHop_TEST"
                btn.LayoutOrder=-297
                btn.Visible=true
                btn.Parent=parent
                oldButton.Visible=false
                manualButton=btn
                connections[#connections+1]=btn.MouseButton1Click:Connect(function()
                    hop("manual")
                end)
            else
                local btn=Instance.new("TextButton")
                btn.Name="PVH_ManualHop_TEST"
                btn.Size=UDim2.new(1,-5,0,29)
                btn.LayoutOrder=-297
                btn.TextColor3=Color3.fromRGB(205,207,213)
                btn.BackgroundColor3=Color3.fromRGB(31,31,34)
                btn.BorderSizePixel=0
                btn.Font=Enum.Font.Code
                btn.TextSize=14
                btn.Parent=parent
                manualButton=btn
                connections[#connections+1]=btn.MouseButton1Click:Connect(function()hop("manual")end)
            end
            return true
        end
        -- Safe UI fallback: keep all controls within the current Farm tab.
        local tab
        for name,t in pairs(library.Tabs or {}) do
            if tostring(name):lower():find("farm",1,true) then tab=t;break end
        end
        if tab then
            local group=tab:AddGroupbox({Side="Left",Name="Server Hop",IconName="refresh-cw"})
            group:AddSlider("PVH_EXU_HOP_WAIT_TEST",{
                Text="Sem Exus por / No Exus for",Min=3,Max=20,Rounding=0,
                Default=seconds,Callback=function(v)updateSeconds(v)end,
            })
            group:AddButton({Text="Trocar de servidor / Server Hop",Func=function()hop("manual")end})
            warn("[PVH EXU HOP TEST] Inline holder unavailable; added groupbox to Farm")
            return true
        end
        return false
    end

    local okUI,errUI=pcall(build)
    if not okUI then warn("[PVH EXU HOP TEST] UI layout: "..tostring(errUI)) end
    redraw()
    save()
    env.PVH_EXU_HopStatus={enabled=enabled,seconds=seconds,attempts=0,lastExus=nil}
    local function stop()
        running=false
        dragging=false
        for _,c in ipairs(connections) do pcall(function()c:Disconnect()end) end
        if env.PVH_ExuHopStop==stop then env.PVH_ExuHopStop=nil end
        if oldButton and oldButton.Parent then pcall(function()oldButton.Visible=true end) end
        if type(ctrl)=="table" then
            if oldCallback then ctrl.Callback=oldCallback end
            if oldChanged then ctrl.Changed=oldChanged end
        end
    end
    env.PVH_ExuHopStop=stop
    if type(library.OnUnload)=="function" then
        pcall(function()library:OnUnload(stop)end)
    end
    connections[#connections+1]=TeleportService.TeleportInitFailed:Connect(function(who)
        if who==player then busy=false;noExuSince=nil end
    end)
    task.spawn(function()
        local lastLanguage=nil
        while running and env.PV_Hub_ActivePort=="Exu Security Lab" do
            local lang=getLanguage()
            if lang~=lastLanguage then redraw();lastLanguage=lang end
            local isOn=ctrl.Value==true
            if enabled~=isOn then
                enabled=isOn;noExuSince=nil;save();redraw()
            end
            local count=exuCount()
            lastCount=count
            env.PVH_EXU_HopStatus.enabled=enabled
            env.PVH_EXU_HopStatus.seconds=seconds
            env.PVH_EXU_HopStatus.lastExus=count
            if enabled and farm and farm.Value==true and not busy and not carrying() then
                if count==0 then
                    noExuSince=noExuSince or os.clock()
                    if os.clock()-noExuSince>=seconds then
                        noExuSince=nil
                        hop("no_exu_"..seconds.."s")
                    end
                else
                    noExuSince=nil
                    if count==nil and os.clock()-lastUnknown>12 then
                        lastUnknown=os.clock()
                        warn("[PVH EXU HOP TEST] Exu scan label unavailable; hop withheld")
                    end
                end
            else
                noExuSince=nil
            end
            env.PVH_EXU_HopStatus.waitingFor=noExuSince
            task.wait(0.35)
        end
        stop()
    end)
end
