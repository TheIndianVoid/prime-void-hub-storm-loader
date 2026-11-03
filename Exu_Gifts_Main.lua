-- Prime Void Hub | Exu timed gifts | isolated production runtime
-- Loaded only for Exu Security Lab. No ScreenGui, no Halloween actions.
-- Protocol verified in live tests: ReplicatedStorage.Remotes.Rewards:InvokeServer("gift", index).
if tonumber(game.PlaceId) ~= 103076400317371 then return end

local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TeleportService=game:GetService("TeleportService")
local HttpService=game:GetService("HttpService")
local player=Players.LocalPlayer
if not player then return end
local env=(type(getgenv)=="function" and getgenv()) or _G
local prefs=env.PVEXU_GiftsPrefs
if type(prefs)~="table" then
    prefs={collect=false,hop=false}
    env.PVEXU_GiftsPrefs=prefs
end
local resume=env.PVEXU_GiftsResume
env.PVEXU_GiftsResume=nil
if type(resume)=="table" then
    prefs.collect=resume.collect==true
    prefs.hop=resume.hop==true
end
local previous=env.PVEXU_GiftsMain
if type(previous)=="table" and type(previous.Stop)=="function" then
    pcall(previous.Stop)
end

local schedule={1,3,5,8,12,16,22,30}
local cfg=ReplicatedStorage:FindFirstChild("Shared")
cfg=cfg and cfg:FindFirstChild("Config")
if cfg and cfg:IsA("ModuleScript") then
    local ok,data=pcall(require,cfg)
    if ok and type(data)=="table" and type(data.Gifts)=="table" then
        local minutes={}
        for i=1,8 do
            local entry=data.Gifts[i]
            if type(entry)=="table" then minutes[i]=tonumber(entry.minutes) end
        end
        if #minutes==8 then schedule=minutes end
    end
end

local state={
    alive=true,
    collect=false,
    hop=false,
    busy=false,
    claimed={},
    attempts={},
    firstAttempt={},
    nextTry={},
    sessionStart=os.clock(),
    resumed=type(resume)=="table",
    hops=type(resume)=="table" and tonumber(resume.hops) or 0,
    teleportAttempted=false,
}
env.PVEXU_GiftsMain=state
local function log(label,details)
    warn("[PVH GIFTS] "..label.." | "..tostring(details or ""))
end
local function notice(text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",{
            Title="Prime Void Hub • Presentes",Text=text,Duration=5
        })
    end)
end
function state.Stop()
    state.alive=false
    state.collect=false
    state.hop=false
    if env.PVEXU_GiftsMain==state then env.PVEXU_GiftsMain=nil end
end
function state.SetCollect(on)
    state.collect=on==true
    prefs.collect=state.collect
    log("COLLECT",state.collect and "ON" or "OFF")
    return state.collect
end
function state.SetHop(on)
    state.hop=on==true
    prefs.hop=state.hop
    log("HOP",state.hop and "ON" or "OFF")
    return state.hop
end

local remoteContainer=ReplicatedStorage:WaitForChild("Remotes",20)
local rewards=remoteContainer and remoteContainer:FindFirstChild("Rewards")
if not rewards or not rewards:IsA("RemoteFunction") then
    log("ERROR","Rewards RemoteFunction not found; other Hub features remain unaffected")
    notice("Não foi possível localizar as recompensas.")
    state.alive=false
    return
end

-- The source game's native HUD supplies the actual countdown and the
-- GiftsClaimed player attribute supplies persistent claimed slots.
local nativeGrid
local function readNative(index)
    local pg=player:FindFirstChildOfClass("PlayerGui")
    local hud=pg and pg:FindFirstChild("HUD")
    if not hud then return "missing",nil end
    if not nativeGrid or not nativeGrid.Parent then
        local gifts=hud:FindFirstChild("Presentes",true)
        if not gifts then return "missing",nil end
        for _,node in ipairs(gifts:GetDescendants()) do
            if node:IsA("Frame") and node:FindFirstChildOfClass("UIGridLayout") then
                local count=0
                for _,child in ipairs(node:GetChildren()) do
                    if child:IsA("Frame") then count=count+1 end
                end
                if count==8 then nativeGrid=node;break end
            end
        end
    end
    if not nativeGrid then return "missing",nil end
    local cards={}
    for _,child in ipairs(nativeGrid:GetChildren()) do
        if child:IsA("Frame") then cards[#cards+1]=child end
    end
    table.sort(cards,function(a,b)
        if a.LayoutOrder~=b.LayoutOrder then return a.LayoutOrder<b.LayoutOrder end
        if a.AbsolutePosition.Y~=b.AbsolutePosition.Y then
            return a.AbsolutePosition.Y<b.AbsolutePosition.Y
        end
        return a.AbsolutePosition.X<b.AbsolutePosition.X
    end)
    local card=cards[index]
    if not card then return "missing",nil end
    local face=card:FindFirstChild("Face",true)
    if not face then return "unknown",nil end
    local display
    for _,child in ipairs(face:GetDescendants()) do
        if child:IsA("TextLabel") then display=child;break end
    end
    local text=(display and tostring(display.Text or ""))
        or (face:IsA("TextButton") and tostring(face.Text or "") or "")
    local lower=text:lower():gsub("^%s+",""):gsub("%s+$","")
    if lower=="✓" or lower=="✔" or lower:find("claimed",1,true)
        or lower:find("resgatado",1,true) or lower:find("coletado",1,true) then
        return "claimed",0
    end
    local h=tonumber(lower:match("(%d+)%s*h")) or 0
    local m=tonumber(lower:match("(%d+)%s*m")) or 0
    local sec=tonumber(lower:match("(%d+)%s*s")) or 0
    if h+m+sec>0 or lower:match("^0%s*s$") then
        return "waiting",h*3600+m*60+sec
    end
    local mm,ss=lower:match("(%d+):(%d%d)")
    if mm then return "waiting",tonumber(mm)*60+tonumber(ss) end
    if lower:find("claim",1,true) or lower:find("resgatar",1,true)
        or lower:find("coletar",1,true) or lower:find("ready",1,true)
        or lower:find("pronto",1,true) then
        return "ready",0
    end
    return "unknown",nil
end

local lastRaw,attrClaims=nil,{}
local function claimedByAttribute(index)
    local raw=player:GetAttribute("GiftsClaimed")
    if raw~=lastRaw then
        lastRaw=raw
        attrClaims={}
        local data=raw
        if type(raw)=="string" then
            local ok,decoded=pcall(function()return HttpService:JSONDecode(raw)end)
            data=ok and decoded or nil
        end
        if type(data)=="table" then
            for key,value in pairs(data) do
                if type(key)=="number" and tonumber(value) then
                    attrClaims[tonumber(value)]=true
                elseif value==true and tonumber(key) then
                    attrClaims[tonumber(key)]=true
                end
            end
        end
    end
    return attrClaims[index]==true
end
local function isClaimed(index)
    if state.claimed[index] or claimedByAttribute(index) then return true end
    local status=readNative(index)
    return status=="claimed"
end
local function resetDidNotHappen()
    if not state.resumed then return false end
    -- Gifts already claimed on arrival mean the state persisted across the hop.
    -- Do not send the player through another 30-minute farming cycle.
    return claimedByAttribute(1) or readNative(1)=="claimed"
end
local function legacyHopEnabled()
    local check=env.PVEXU_GiftsLegacyHopEnabled
    if type(check)=="function" then
        local ok,res=pcall(check)
        return ok and res==true
    end
    return false
end
local function sendClaim(index)
    state.busy=true
    local ok,result=pcall(function()
        return rewards:InvokeServer("gift",index)
    end)
    state.busy=false
    if not ok then
        log("REMOTE_ERROR","#"..index.." "..tostring(result))
        return "error"
    end
    if result==true then
        log("CLAIM_OK","#"..index.." ("..schedule[index].." min)")
        state.claimed[index]=true
        state.attempts[index]=nil
        state.firstAttempt[index]=nil
        return "success"
    end
    log("CLAIM_REJECTED","#"..index.." result="..tostring(result))
    return result==false and "rejected" or "unknown"
end

local function queueHop(nextCount)
    local queue=type(queue_on_teleport)=="function" and queue_on_teleport
        or (type(syn)=="table" and type(syn.queue_on_teleport)=="function" and syn.queue_on_teleport)
        or (type(fluxus)=="table" and type(fluxus.queue_on_teleport)=="function" and fluxus.queue_on_teleport)
    if type(queue)~="function" then
        log("HOP_BLOCKED","Executor without queue_on_teleport")
        notice("Server Hop não disponível neste executor.")
        return false
    end
    local carry=HttpService:JSONEncode({
        collect=true,hop=true,hops=nextCount,previousServer=tostring(game.JobId)
    })
    local url="https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Loader.lua"
    -- A JSON string is decoded after teleport to restore only the 2 toggles.
    local launch="getgenv().PVEXU_GiftsResume = game:GetService('HttpService'):JSONDecode("
        ..string.format("%q",carry)..")"
        .."\nloadstring(game:HttpGet("..string.format("%q",url).."))()"
    local ok,err=pcall(queue,launch)
    if not ok then
        log("HOP_QUEUE_ERROR",err)
        return false
    end
    return true
end
local function hop()
    if state.teleportAttempted or not state.collect or not state.hop
        or os.clock()<(state.nextHopAt or 0) then return end
    state.nextHopAt=os.clock()+45
    state.teleportAttempted=true
    local destination,cursor=nil,nil
    for page=1,4 do
        local url="https://games.roblox.com/v1/games/"..game.PlaceId
            .."/servers/Public?sortOrder=Asc&limit=100"
        if cursor then url=url.."&cursor="..HttpService:UrlEncode(cursor) end
        local ok,data=pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if not ok or type(data)~="table" then break end
        for _,s in ipairs(data.data or {}) do
            if type(s.id)=="string" and s.id~=game.JobId
                and tonumber(s.playing) and tonumber(s.maxPlayers)
                and s.playing<s.maxPlayers then
                destination=s.id
                break
            end
        end
        if destination then break end
        cursor=data.nextPageCursor
        if type(cursor)~="string" or cursor=="" then break end
    end
    if not destination then
        log("HOP_BLOCKED","No alternative server found")
        state.teleportAttempted=false
        return
    end
    if not queueHop((state.hops or 0)+1) then
        state.teleportAttempted=false
        return
    end
    log("HOP_START","Completed all eight, joining new public server")
    local ok,err=pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId,destination,player)
    end)
    if not ok then
        state.teleportAttempted=false
        log("HOP_ERROR",err)
    end
end

state.SetCollect(prefs.collect)
state.SetHop(prefs.hop)
-- Teleport failures should not leave a permanently "busy" farm.
local failConnection
failConnection=TeleportService.TeleportInitFailed:Connect(function(who,reason)
    if state.alive and who==player and state.teleportAttempted then
        state.teleportAttempted=false
        log("HOP_FAILED",tostring(reason))
        notice("Não foi possível trocar de servidor; tentativa posterior.")
    end
end)
local originalStop=state.Stop
function state.Stop()
    if failConnection then failConnection:Disconnect() end
    originalStop()
end
log("READY","8 timed gifts; no GUI; auto="..tostring(state.collect)
    .." hop="..tostring(state.hop))

task.spawn(function()
    local nextHeartbeat=0
    while state.alive do
        if state.collect and not state.busy and not state.teleportAttempted then
            if state.resumed and resetDidNotHappen() then
                state.collect=false
                state.hop=false
                prefs.collect=false
                prefs.hop=false
                log("RESET_FAILED","Already-claimed first gift persisted to new server")
                notice("Os presentes não reiniciaram. Farm interrompido.")
            elseif legacyHopEnabled() then
                if os.clock()>=nextHeartbeat then
                    nextHeartbeat=os.clock()+30
                    log("PAUSED","Legacy no-Exu server hop is enabled. Disable it.")
                end
            else
                local index
                for i=1,8 do
                    if not isClaimed(i) then
                        index=i;break
                    end
                end
                if not index then
                    if state.hop then hop()
                    else
                        state.collect=false
                        prefs.collect=false
                        log("COMPLETE","All eight claimed; server hop disabled")
                        notice("Todos os presentes resgatados.")
                    end
                else
                    -- Don't leave a server if claimed gifts persist across hops.
                    if state.resumed and index==1 and os.clock()-state.sessionStart>90
                        and (state.attempts[1] or 0)>6 then
                        state.collect=false
                        state.hop=false
                        prefs.collect=false
                        prefs.hop=false
                        log("RESET_FAILED","Server hop did not reset gift #1")
                        notice("Os presentes não reiniciaram no novo servidor.")
                    else
                        local elapsed=os.clock()-state.sessionStart
                        local status,nativeSeconds=readNative(index)
                        local sourceKnown=status=="waiting" or status=="ready"
                        local due=(schedule[index] or 30)*60
                        local remaining=sourceKnown and (nativeSeconds or 0) or (due-elapsed)
                        local early=sourceKnown and 1.2 or 12
                        if elapsed>=(state.nextTry[index] or 0) and remaining<=early then
                            local attempts=state.attempts[index] or 0
                            local first=state.firstAttempt[index] or os.clock()
                            state.firstAttempt[index]=first
                            if attempts>=120 or os.clock()-first>360 then
                                log("PAUSED","Gift #"..index.." was not confirmed after retries")
                                notice("Presente #"..index.." não confirmado; consulte o console.")
                                state.collect=false
                                prefs.collect=false
                            else
                                state.attempts[index]=attempts+1
                                local result=sendClaim(index)
                                local later=os.clock()-state.sessionStart
                                if result=="success" then
                                    state.nextTry[index]=nil
                                elseif result=="rejected" then
                                    local delay
                                    if sourceKnown and status=="waiting" then
                                        delay=math.max(1.5,math.min(4,(nativeSeconds or 1)/2))
                                    elseif sourceKnown and status=="ready" then
                                        delay=math.min(9,1.8+attempts*0.7)
                                    else
                                        delay=math.min(12,1.8+attempts)
                                    end
                                    state.nextTry[index]=later+delay
                                else
                                    state.nextTry[index]=later+6
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.25)
    end
end)
