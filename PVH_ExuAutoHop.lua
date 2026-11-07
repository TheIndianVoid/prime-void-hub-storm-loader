-- Prime Void Hub | Steal An Exu | Auto Hop v2 (native Obsidian UI)
-- Original protected source is untouched. Disable legacy 8s loop and replace
-- it with a 3..20s configurable no-target timeout while Auto Farm searches.
return function()
    local env=(type(getgenv)=="function" and getgenv()) or _G
    if type(env.PVH_ExuHopStop)=="function" then pcall(env.PVH_ExuHopStop) end
    local Players=game:GetService("Players")
    local TeleportService=game:GetService("TeleportService")
    local HttpService=game:GetService("HttpService")
    local player=Players.LocalPlayer
    local lib=env.Library
    local ctrl=type(lib)=="table" and lib.Toggles and lib.Toggles.PVEXU_ServerHopNoExu
    local farm=type(lib)=="table" and lib.Toggles and lib.Toggles.PVEXU_AutoFarm
    if type(ctrl)~="table" or type(farm)~="table"
        or type(ctrl.SetValue)~="function" or type(ctrl.Parent)~="table" then
        warn("[PVH EXU HOP] Exu Obsidian controls unavailable")
        return
    end
    local group=ctrl.Parent
    if type(group.AddSlider)~="function" or type(group.AddButton)~="function" then
        warn("[PVH EXU HOP] Farm group does not support native controls")
        return
    end

    local running,busy=true,false
    local noExuSince,lastAttempt=nil,-math.huge
    local attempts,lastUnknown=0,0
    local oldCallback=type(ctrl.Callback)=="function" and ctrl.Callback or nil
    local oldChanged=type(ctrl.Changed)=="function" and ctrl.Changed or nil
    local initialEnabled=ctrl.Value==true
    local config="primevoid_hub/_Universal/exu_hop_test_"..tostring(player.UserId)..".json"
    local saved={}
    local ok,decoded=pcall(function()
        if type(isfile)=="function" and type(readfile)=="function" and isfile(config) then
            return HttpService:JSONDecode(readfile(config))
        end
    end)
    if ok and type(decoded)=="table" then saved=decoded end
    local waitSeconds=math.clamp(math.floor((tonumber(saved.seconds) or 8)+0.5),3,20)
    local enabled=type(saved.enabled)=="boolean" and saved.enabled or initialEnabled
    local slider,manual
    local oldButton
    local connections={}
    local ui=lib.ScreenGui
    local started=os.clock()
    local status={enabled=enabled,seconds=waitSeconds,attempts=0,lastExus=nil}
    env.PVH_EXU_HopStatus=status

    local function save()
        if type(writefile)~="function" then return end
        pcall(function()
            if type(makefolder)=="function" then
                pcall(makefolder,"primevoid_hub")
                pcall(makefolder,"primevoid_hub/_Universal")
            end
            writefile(config,HttpService:JSONEncode({
                schema=2,enabled=enabled,seconds=waitSeconds
            }))
        end)
    end
    local function lang()
        local p=env.PVH_Persistence
        if type(p)=="table" and type(p.GetLanguage)=="function" then
            local ok2,l=pcall(function()return p:GetLanguage()end)
            if ok2 then return l end
        end
        return "pt-BR"
    end
    local function labels()
        if lang()=="en-US" then
            return "Auto server hop if no Exu","No Exus for (seconds)","Server Hop"
        end
        return "Auto trocar servidor sem Exu","Sem Exus por (segundos)","Trocar de servidor"
    end
    local function show()
        local t,s,b=labels()
        pcall(function()ctrl:SetText(t)end)
        if slider then
            pcall(function()slider:SetText(s)end)
            pcall(function()slider:SetVisible(enabled)end)
        end
        if manual then pcall(function()manual:SetText(b)end) end
        status.enabled=enabled
        status.seconds=waitSeconds
    end
    local function setSeconds(v)
        local nextSeconds=math.clamp(math.floor((tonumber(v) or waitSeconds)+0.5),3,20)
        if nextSeconds==waitSeconds then return end
        waitSeconds=nextSeconds
        noExuSince=nil
        save()
        show()
    end
    local function setEnabled(v)
        local changed=enabled~=(v==true)
        enabled=v==true
        if changed then noExuSince=nil;save() end
        show()
    end

    -- Original callback modifies its own local 'serverHopWhenNoExu' and
    -- starts the fixed eight-second loop. Clear it before replacing callback.
    if oldCallback then pcall(oldCallback,false) end
    if oldChanged and oldChanged~=oldCallback then pcall(oldChanged,false) end
    pcall(function()ctrl:SetValue(false)end)
    ctrl.Callback=setEnabled
    if oldChanged then ctrl.Changed=setEnabled end

    -- Find and delete only the old Server Hop action in this SAME group.
    -- Avoids old code queueing /main/Loader.lua and leaves a single button.
    for _,b in ipairs(lib.Buttons or {}) do
        if type(b)=="table" and type(b.Holder)=="userdata" then
            -- Kept for legacy executors with userdata-style Instance typing.
        end
        if type(b)=="table" and (b.Text=="Server Hop" or b.Text=="Trocar de servidor")
            and typeof(b.Holder)=="Instance"
            and b.Holder.Parent==group.Container then
            oldButton=b
            break
        end
    end
    slider=group:AddSlider("PVH_EXU_HOP_WAIT_TEST",{
        Text=lang()=="en-US" and "No Exus for (seconds)" or "Sem Exus por (segundos)",
        Min=3,Max=20,Rounding=0,Default=waitSeconds,
        Callback=setSeconds,
    })
    if oldButton and type(oldButton.Destroy)=="function" then
        pcall(function()oldButton:Destroy()end)
    end

    local function getServerList(url)
        local ok2,body=pcall(function()return game:HttpGet(url)end)
        if ok2 and type(body)=="string" then return body end
        local requestFn=env.request or env.http_request or (env.syn and env.syn.request)
        if type(requestFn)=="function" then
            local ok3,resp=pcall(requestFn,{Url=url,Method="GET"})
            if ok3 and type(resp)=="table" and resp.Success~=false then
                return resp.Body
            end
        end
        return nil
    end
    local function hop(reason)
        if not running or busy or os.clock()-lastAttempt<2 then return end
        busy=true
        lastAttempt=os.clock()
        attempts=attempts+1
        status.attempts=attempts
        task.spawn(function()
            local current=tostring(game.JobId)
            local dest,cursor=nil,nil
            for page=1,4 do
                local url="https://games.roblox.com/v1/games/"..tostring(game.PlaceId)
                    .."/servers/Public?sortOrder=Asc&limit=100"
                if cursor then url=url.."&cursor="..HttpService:UrlEncode(cursor) end
                local body=getServerList(url)
                local success,data=pcall(function()return HttpService:JSONDecode(body or "")end)
                if not success or type(data)~="table" then
                    warn("[PVH EXU HOP] Public server listing unavailable")
                    busy=false;noExuSince=nil
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
                if #choices>0 then
                    dest=choices[math.random(1,#choices)]
                    break
                end
                cursor=type(data.nextPageCursor)=="string" and data.nextPageCursor~=""
                    and data.nextPageCursor or nil
                if not cursor then break end
            end
            if not dest then
                warn("[PVH EXU HOP] No alternative non-full public server")
                busy=false;noExuSince=nil
                return
            end
            warn("[PVH EXU HOP] "..reason.." | "..current.." -> "..dest)
            -- No early queue. The TEST persistence module queues only on the
            -- actual Roblox OnTeleport transition, and only if Autoexec is ON.
            local accepted,err=pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId,dest,player)
            end)
            if not accepted then
                warn("[PVH EXU HOP] Teleport error: "..tostring(err))
                busy=false;noExuSince=nil
            else
                task.delay(12,function()
                    if running then busy=false;noExuSince=nil end
                end)
            end
        end)
    end
    manual=group:AddButton({Text=lang()=="en-US" and "Server Hop" or "Trocar de servidor",
        Func=function()hop("manual")end})
    if typeof(farm.Holder)=="Instance"
        and farm.Holder.Parent==group.Container then
        farm.Holder.LayoutOrder=-300
    end
    if typeof(ctrl.Holder)=="Instance" then ctrl.Holder.LayoutOrder=-299 end
    if type(slider)=="table" and typeof(slider.Holder)=="Instance" then
        slider.Holder.LayoutOrder=-298
    end
    if type(manual)=="table" and typeof(manual.Holder)=="Instance" then
        manual.Holder.LayoutOrder=-297
    end
    pcall(function()ctrl:SetValue(enabled)end)
    show()
    save()

    -- The Home "Exus: N" value is the unfiltered MAP TOTAL (e.g. 61),
    -- NOT the number of farm-eligible targets. The farm can legitimately be
    -- in Procurando_Exu with many Exus on the map but none matching rarity.
    -- Prefer its explicit search status over the unfiltered total.
    local function countTargets()
        if typeof(ui)~="Instance" or not ui.Parent then
            return nil,"gui_unavailable",nil
        end
        local searching=false
        local mapTotal=nil
        local statusText=nil
        for _,node in ipairs(ui:GetDescendants()) do
            if node:IsA("TextLabel") and type(node.Text)=="string" then
                local original=node.Text
                local count=original:match("^%s*Exus:%s*(%d+)")
                if count then mapTotal=tonumber(count) end
                local normalized=original:lower():gsub("[_%-%s]+"," ")
                if normalized:find("procurando exu",1,true)
                    or normalized:find("searching for exu",1,true)
                    or normalized:find("searching exu",1,true) then
                    searching=true
                    statusText=original:sub(1,90)
                end
            end
        end
        if searching then return 0,"farm_searching:"..tostring(statusText),mapTotal end
        if mapTotal==0 then return 0,"map_empty",mapTotal end
        -- A positive map total does not prove an eligible target exists.
        -- Fail closed instead of cancelling a valid timeout based on raw total.
        return nil,mapTotal and "map_has_unfiltered_exus" or "status_unavailable",mapTotal
    end
    local function carrying()
        for _,name in ipairs({"CarregandoExu","IsCarryingExu","CarryingExu","Carregando","IsCarrying"}) do
            if player:GetAttribute(name)==true then return true end
        end
        return false
    end
    local function stop()
        running=false
        for _,conn in ipairs(connections) do pcall(function()conn:Disconnect()end) end
        if env.PVH_ExuHopStop==stop then env.PVH_ExuHopStop=nil end
        if oldCallback then ctrl.Callback=oldCallback end
        if oldChanged then ctrl.Changed=oldChanged end
    end
    env.PVH_ExuHopStop=stop
    if type(lib.OnUnload)=="function" then
        pcall(function()lib:OnUnload(stop)end)
    end
    connections[#connections+1]=TeleportService.TeleportInitFailed:Connect(function(who)
        if who==player then busy=false;noExuSince=nil end
    end)
    task.spawn(function()
        local lastLanguage=nil
        local lastDiagnostic=0
        local lastReason=""
        while running and env.PV_Hub_ActivePort=="Exu Security Lab" do
            local language=lang()
            if language~=lastLanguage then show();lastLanguage=language end
            if enabled~=(ctrl.Value==true) then setEnabled(ctrl.Value==true) end
            local count,reason,mapTotal=countTargets()
            local active=enabled and farm.Value==true and os.clock()-started>=4
                and not busy and not carrying()
            status.enabled=enabled
            status.seconds=waitSeconds
            status.lastExus=mapTotal
            status.searching=(count==0)
            status.signal=reason
            status.farmActive=farm.Value==true
            -- Small one-time grace period prevents premature hop at spawn.
            if active and count==0 then
                noExuSince=noExuSince or os.clock()
                if os.clock()-noExuSince>=waitSeconds then
                    warn("[PVH EXU HOP] Empty eligible-target timeout reached; attempting auto hop")
                    noExuSince=nil
                    hop("no_eligible_exu_"..waitSeconds.."s")
                end
            else
                noExuSince=nil
                if active and count==nil and os.clock()-lastUnknown>12 then
                    lastUnknown=os.clock()
                    warn("[PVH EXU HOP] Cannot prove no eligible Exu; status="..tostring(reason))
                end
            end
            local elapsed=noExuSince and math.max(0,os.clock()-noExuSince) or 0
            status.waitingSince=noExuSince
            status.waitElapsed=elapsed
            local stateReason=active and reason or (busy and "hop_in_progress"
                or not enabled and "disabled"
                or farm.Value~=true and "auto_farm_off"
                or carrying() and "carrying"
                or "spawn_grace")
            status.blockReason=stateReason
            if stateReason~=lastReason or os.clock()-lastDiagnostic>=5 then
                lastReason=stateReason
                lastDiagnostic=os.clock()
                warn(string.format(
                    "[PVH EXU HOP] WATCH | state=%s | enabled=%s | farm=%s | mapTotal=%s | wait=%.1f/%ds | attempts=%d",
                    tostring(stateReason),tostring(enabled),tostring(farm.Value),
                    tostring(mapTotal),elapsed,waitSeconds,attempts))
            end
            task.wait(0.35)
        end
        stop()
    end)
    warn("[PVH EXU HOP] Native Obsidian slider, manual button and 3..20s timer ready")
end
