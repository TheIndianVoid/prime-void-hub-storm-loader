-- Prime Void Hub | Spirit Sanctuary (provisional title) | v0.1.0 TEST
-- Based on user-provided place snapshot 86004028558873.rbxlx.
-- Test branch only. All real rewards, steals, placements and rebirths are server-authoritative.
-- Never purchase Robux items; destructive actions are OFF by default.
local PLACE_ID=86004028558873
if game.PlaceId~=PLACE_ID then error("[PVH SPIRIT] PlaceId incompatível: "..tostring(game.PlaceId),0) end
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local WS=game:GetService("Workspace")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local TeleportService=game:GetService("TeleportService")
local HttpService=game:GetService("HttpService")
local VirtualUser=game:GetService("VirtualUser")
local UserInputService=game:GetService("UserInputService")
local LP=Players.LocalPlayer
local env=(type(getgenv)=="function" and getgenv()) or _G
if type(env.PVH_SpiritUnload)=="function" then pcall(env.PVH_SpiritUnload) end
local running=true
local version="v0.1.0 TEST"
local settingsPath="primevoid_hub/Spirit_Sanctuary/Configs/ui_settings.json"
local testURL="https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/test/all-obfuscated-sources/SpiritSanctuary_TEST.lua"
local default={
    language="pt-BR",autoSave=true,autoExec=false,animations=true,sounds=false,
    mode="Blink",tweenSpeed=260,zone="Auto",priority="Raridade",
    minRarity="Common",minIncome=0,ignoreSpeedLimit=false,stealPlayers=false,
    autoPlace=true,stealTimeout=8,interactDelay=0.5,
    espMaxDistance=8000,espRarity="Common",espPlayers=false,espGuardians=true,
    autoSteal=false,autoTreadmill=false,autoRewards=false,autoBest=false,autoRebirth=false,
    autoESP=false,autoNoclip=false,antiAFK=false,
    minimizeKey="RightShift",unloadKey="Delete"
}
local cfg=table.clone(default)
local savedSnapshot=nil
local loading=true
local function ensureDir(path)
    if type(makefolder)~="function" then return end
    local folder=""
    for name in string.gmatch(path,"[^/]+") do
        folder=(folder=="" and name or folder.."/"..name)
        local exists=false
        if type(isfolder)=="function" then
            local ok,v=pcall(isfolder,folder)
            exists=ok and v or false
        end
        if not exists then pcall(makefolder,folder) end
    end
end
local function readJson(path)
    if type(readfile)~="function" or type(isfile)~="function" then return nil end
    local ok,v=pcall(function()
        if not isfile(path) then return nil end
        return HttpService:JSONDecode(readfile(path))
    end)
    return ok and type(v)=="table" and v or nil
end
local function writeJson(path,t)
    if type(writefile)~="function" then return false end
    local ok=pcall(function()
        ensureDir("primevoid_hub/Spirit_Sanctuary/Configs")
        writefile(path,HttpService:JSONEncode(t))
    end)
    return ok
end
local prior=readJson(settingsPath)
if prior then
    if prior.autoSave==false then cfg.autoSave=false end
    if type(prior.autoExec)=="boolean" then cfg.autoExec=prior.autoExec end
    if cfg.autoSave and type(prior.cfg)=="table" then
        for k,v in pairs(prior.cfg) do
            if default[k]~=nil and type(default[k])==type(v) then cfg[k]=v end
        end
        savedSnapshot=prior
    end
end
local function W(pt,en)
    return cfg.language=="en-US" and en or pt
end
local labels={}
local groupHeaders={}
local function words(pt,en)
    labels[pt]={pt=pt,en=en}
    labels[en]={pt=pt,en=en}
    return W(pt,en)
end
local function header(group,pt,en)
    groupHeaders[#groupHeaders+1]={group=group,pt=pt,en=en}
    return group
end
local function setLabel(lbl,pt,en)
    if lbl then pcall(function()lbl:SetText(W(pt,en))end) end
end
local lib
local aliveConns={}
local function track(conn)
    if conn then table.insert(aliveConns,conn) end
    return conn
end
local statusText={}
local counters={Targets=0,StealAttempts=0,Secured=0,Placed=0,PromptFails=0,Rewards=0,
    EquipBest=0,Rebirths=0,Rollbacks=0,Movements=0,Skipped=0}
local runtime={phase="idle",target=nil,targetZone=nil,busy=false,activeMove=nil,
    lastSecure=0,lastPrompt=0,lastProgress=os.clock(),lastError="",lastPosition=nil}
local remotes=RS:FindFirstChild("Remotes") or RS:WaitForChild("Remotes",12)
local shared=RS:FindFirstChild("Shared")
local config=RS:FindFirstChild("Config")
local SpiritConfig,ZoneConfig,Placement
pcall(function()SpiritConfig=require(config:WaitForChild("SpiritConfig",3))end)
pcall(function()ZoneConfig=require(config:WaitForChild("ZoneConfig",3))end)
pcall(function()Placement=require(shared:WaitForChild("Placement",3))end)
local rarityNames={"Common","Uncommon","Rare","Epic","Legendary","Mythic","Secret"}
local rarityRank={}
for i,name in ipairs(rarityNames) do rarityRank[name]=i end
local function remote(name,expected)
    local r=remotes and remotes:FindFirstChild(name)
    if r and r:IsA(expected or "RemoteFunction") then return r end
    return nil
end
local function invoke(name,...)
    local r=remote(name)
    if not r then return false,nil,"missing_remote:"..name end
    local ok,a,b=pcall(function(...)return r:InvokeServer(...)end,...)
    if not ok then return false,nil,tostring(a) end
    return true,a,b
end
local function character()
    local c=LP.Character
    local hum=c and c:FindFirstChildOfClass("Humanoid")
    local hrp=c and c:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health<=0 or not hrp then return nil,nil,nil end
    return c,hum,hrp
end
local function ownPlot()
    local plots=WS:FindFirstChild("Plots")
    if not plots then return nil end
    local plotName=LP:GetAttribute("PlotName")
    if type(plotName)=="string" and plotName~="" then
        local found=plots:FindFirstChild(plotName)
        if found then return found end
    end
    for _,plot in ipairs(plots:GetChildren()) do
        if plot:GetAttribute("OwnerId")==LP.UserId then return plot end
    end
end
local function rootOf(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart",true) end
    if obj:IsA("ProximityPrompt") then return rootOf(obj.Parent) end
    return obj:FindFirstChildWhichIsA("BasePart",true)
end
local function zoneFrom(prompt)
    local ptr=prompt
    while ptr and ptr~=WS do
        local number=ptr.Name:match("^Zone(%d+)$")
        if number then return tonumber(number),ptr end
        ptr=ptr.Parent
    end
end
local function mySpeed()
    return tonumber(LP:GetAttribute("Speed")) or 0
end
local function myMoney()
    return tonumber(LP:GetAttribute("Money")) or 0
end
local function carrying()
    local v=LP:GetAttribute("Carrying")
    return v~=nil and v~=false and v~=""
end
local function securedTools()
    local list={}
    local c=LP.Character
    local containers={c,LP:FindFirstChildOfClass("Backpack")}
    for _,parent in ipairs(containers) do
        if parent then
            for _,obj in ipairs(parent:GetChildren()) do
                if obj:IsA("Tool") and obj:GetAttribute("Secured")==true
                    and type(obj:GetAttribute("SpiritKey"))=="string" then
                    list[#list+1]=obj
                end
            end
        end
    end
    return list
end
local function stopMovement()
    local m=runtime.activeMove
    runtime.activeMove=nil
    if not m then return end
    m.cancelled=true
    if m.tween then pcall(function()m.tween:Cancel()end) end
    if m.root and m.root.Parent then
        pcall(function()
            m.root.Anchored=m.oldAnchor
            m.root.CanCollide=m.oldCollide
        end)
    end
end
local function moveTo(position,reach)
    if not running or typeof(position)~="Vector3" then return false end
    local _,_,hrp=character()
    if not hrp or runtime.activeMove then return false end
    local dist=(hrp.Position-position).Magnitude
    if dist<=(reach or 4) then return true end
    local facing=Vector3.new(position.X,hrp.Position.Y,position.Z)
    if (facing-hrp.Position).Magnitude<0.2 then facing=hrp.Position+Vector3.zAxis end
    local offset=Vector3.new(0,2.8,0)
    local destination=position+offset
    local goal=CFrame.lookAt(destination,Vector3.new(facing.X,destination.Y,facing.Z))
    local m={root=hrp,oldAnchor=hrp.Anchored,oldCollide=hrp.CanCollide,cancelled=false}
    runtime.activeMove=m
    local ok,err=pcall(function()
        if cfg.mode=="Tween" then
            hrp.Anchored=true
            hrp.CanCollide=false
            local secs=math.clamp((hrp.Position-destination).Magnitude/
                math.clamp(cfg.tweenSpeed,80,800),0.08,8)
            local tw=TweenService:Create(hrp,TweenInfo.new(secs,Enum.EasingStyle.Linear),{CFrame=goal})
            m.tween=tw
            tw:Play()
            local deadline=os.clock()+secs+0.6
            while running and not m.cancelled and tw.PlaybackState==Enum.PlaybackState.Playing
                and os.clock()<deadline do
                task.wait(0.05)
            end
        else
            hrp.CFrame=goal
            task.wait(0.06)
        end
    end)
    local cancelled=m.cancelled
    stopMovement()
    if not ok or cancelled or not running then
        runtime.lastError=tostring(err or "movement_cancelled")
        return false
    end
    local _,_,after=character()
    local arrived=after and (after.Position-position).Magnitude<=math.max(reach or 4,6.5)
    if not arrived then
        counters.Rollbacks+=1
        runtime.lastError="movement_rollback"
    else
        counters.Movements+=1
    end
    return arrived==true
end
local function stopFeature(name)
    cfg[name]=false
    local toggle=lib and lib.Toggles and lib.Toggles["PVSP_"..name]
    if toggle and toggle.Value then pcall(function()toggle:SetValue(false)end) end
end
local function applyPrompt(prompt)
    if not prompt or not prompt.Parent or not prompt.Enabled then return false end
    if type(fireproximityprompt)=="function" then
        local ok=pcall(fireproximityprompt,prompt)
        return ok
    end
    local ok=pcall(function()
        prompt:InputHoldBegin()
        task.wait(math.max(0.05,prompt.HoldDuration)+0.12)
        prompt:InputHoldEnd()
    end)
    return ok
end
local function targetMetadata(prompt)
    local id=prompt:GetAttribute("SpiritId")
    local definition=SpiritConfig and SpiritConfig.Spirits and SpiritConfig.Spirits[id]
    local zone=zoneFrom(prompt)
    local rarity=definition and definition.rarity or "Common"
    return {
        id=id,definition=definition,zone=zone,rarity=rarity,
        rank=rarityRank[rarity] or 1,income=tonumber(definition and definition.income) or 0,
        requirement=tonumber(prompt:GetAttribute("SpeedRequired")) or
            tonumber(definition and definition.speedRequired) or 0,
        variant=tostring(prompt:GetAttribute("Variant") or "Normal"),
        size=tostring(prompt:GetAttribute("Size") or ""),
    }
end
local recentPrompt=setmetatable({},{__mode="k"})
local function allTargets()
    local zones=WS:FindFirstChild("Zones")
    if not zones then return {} end
    local list={}
    local _,_,hrp=character()
    for _,p in ipairs(zones:GetDescendants()) do
        if p:IsA("ProximityPrompt") and p.Name=="StealPrompt" and p.Enabled then
            local part=rootOf(p)
            if part then
                local meta=targetMetadata(p)
                local zoneMatch=cfg.zone=="Auto" or cfg.zone=="All"
                    or cfg.zone=="Zona "..tostring(meta.zone)
                local rarityMatch=meta.rank>=(rarityRank[cfg.minRarity] or 1)
                local speedMatch=cfg.ignoreSpeedLimit or meta.requirement<=mySpeed()
                if zoneMatch and rarityMatch and speedMatch and meta.income>=cfg.minIncome
                    and os.clock()-(recentPrompt[p] or -1e5)>cfg.stealTimeout then
                    local distance=hrp and (hrp.Position-part.Position).Magnitude or math.huge
                    list[#list+1]={prompt=p,part=part,meta=meta,distance=distance}
                else counters.Skipped+=0 end
            end
        end
    end
    counters.Targets=#list
    table.sort(list,function(a,b)
        if cfg.priority=="Raridade" then
            if a.meta.rank~=b.meta.rank then return a.meta.rank>b.meta.rank end
            if a.meta.income~=b.meta.income then return a.meta.income>b.meta.income end
        elseif cfg.priority=="Renda" then
            if a.meta.income~=b.meta.income then return a.meta.income>b.meta.income end
        end
        return a.distance<b.distance
    end)
    return list
end
local function finishTarget(target)
    local zones=WS:FindFirstChild("Zones")
    if not zones then return nil end
    local zone=zones:FindFirstChild("Zone"..tostring(target.meta.zone))
    if not zone then return nil end
    local finish=zone:FindFirstChild("FinishLine")
    if finish then return rootOf(finish) end
    local entry=zone:FindFirstChild("EntryGate")
    if entry then return rootOf(entry) end
    return nil
end
local function placeOne()
    local tools=securedTools()
    if #tools==0 then return false,"no_secured_tool" end
    local plot=ownPlot()
    local base=plot and plot:FindFirstChild("Base")
    if not base or not Placement or type(Placement.toWorld)~="function"
        or type(Placement.check)~="function" then
        return false,"plot_or_Placement_missing"
    end
    if tonumber(LP:GetAttribute("SpiritCount")) and tonumber(LP:GetAttribute("Capacity"))
        and LP:GetAttribute("SpiritCount")>=LP:GetAttribute("Capacity") then
        return false,"sanctuary_full"
    end
    local tool=tools[1]
    local key=tool:GetAttribute("SpiritKey")
    if not key then return false,"missing_spirit_key" end
    local margin=math.max(7,base.Size.X*0.10)
    local halfX=math.max(2,base.Size.X/2-margin)
    local halfZ=math.max(2,base.Size.Z/2-margin)
    -- Deterministic placement candidates avoid infinite retries and use the
    -- game's own Placement.check before requesting server placement.
    for i=1,18 do
        if not running or not tool.Parent then return false,"cancelled" end
        local x=(i%5-2)*halfX/3
        local z=(math.floor((i-1)/5)-1.5)*halfZ/2.5
        local pos=Placement.toWorld(plot,x,z)
        local valid=Placement.check(plot,pos,{})
        if valid then
            local network,ok,why=invoke("PlaceHeld",key,pos)
            if network and ok then
                task.wait(0.2)
                if not tool.Parent then
                    counters.Placed+=1
                    return true,"placed_confirmed"
                end
                return false,"awaiting_server_confirmation"
            end
            if not network then runtime.lastError=tostring(why) end
        end
    end
    return false,"no_valid_placement"
end
local function autoStealStep()
    if not cfg.autoSteal then return end
    if carrying() then
        runtime.phase="escape"
        local target=runtime.target
        local finish=target and finishTarget(target)
        if finish then moveTo(finish.Position,8) end
        if carrying() then
            local plot=ownPlot()
            local spawn=plot and plot:FindFirstChild("Spawn")
            if spawn then moveTo(spawn.Position,9) end
        end
        task.wait(0.25)
        return
    end
    if cfg.autoPlace and #securedTools>0 then
        runtime.phase="place"
        local plot=ownPlot()
        local base=plot and plot:FindFirstChild("Base")
        if base then moveTo(base.Position,10) end
        local ok,reason=placeOne()
        if not ok and reason=="sanctuary_full" then
            runtime.phase="sanctuary_full"
            stopFeature("autoSteal")
        end
        task.wait(0.5)
        return
    end
    runtime.phase="scan"
    local candidates=allTargets()
    local target=candidates[1]
    if not target then
        runtime.phase="no_eligible_target"
        task.wait(1.2)
        return
    end
    runtime.target=target
    runtime.targetZone=target.meta.zone
    runtime.phase="travel"
    if not moveTo(target.part.Position,5) then
        recentPrompt[target.prompt]=os.clock()-cfg.stealTimeout+1
        task.wait(0.25)
        return
    end
    if not cfg.autoSteal or not target.prompt.Parent or not target.prompt.Enabled then return end
    runtime.phase="steal"
    counters.StealAttempts+=1
    local before=carrying()
    local triggered=applyPrompt(target.prompt)
    if not triggered then
        counters.PromptFails+=1
        runtime.lastError="prompt_failed"
    end
    runtime.lastPrompt=os.clock()
    recentPrompt[target.prompt]=os.clock()
    local deadline=os.clock()+math.clamp(cfg.stealTimeout,3,20)
    while running and cfg.autoSteal and os.clock()<deadline do
        if carrying() and not before then
            runtime.phase="carrying_confirmed"
            runtime.lastProgress=os.clock()
            return
        end
        if #securedTools>0 then
            runtime.phase="secured_confirmed"
            return
        end
        task.wait(0.15)
    end
    counters.PromptFails+=1
    runtime.lastError="steal_not_confirmed"
end
local function worker(flag,fn,interval)
    task.spawn(function()
        while running do
            if cfg[flag] then
                local ok,err=pcall(fn)
                if not ok then
                    runtime.lastError=tostring(err)
                    warn("[PVH SPIRIT] "..flag..": "..tostring(err))
                    task.wait(1.5)
                end
            else task.wait(interval or 0.35) end
        end
    end)
end
worker("autoSteal",autoStealStep,0.4)
track(LP:GetAttributeChangedSignal("HeldCount"):Connect(function()
    runtime.lastSecure=os.clock()
end))
track(LP:GetAttributeChangedSignal("Carrying"):Connect(function()
    if not carrying() and runtime.phase=="escape" then counters.Secured+=1 end
end))
local lastRewards=0
worker("autoRewards",function()
    if os.clock()-lastRewards<80 then task.wait(3)return end
    lastRewards=os.clock()
    local connected,daily=invoke("Rewards","ClaimDaily",nil)
    if connected and type(daily)=="table" and daily.granted then counters.Rewards+=1 end
    for index=1,8 do
        if not cfg.autoRewards then break end
        local ok,data=invoke("Rewards","ClaimPlaytime",index)
        if ok and type(data)=="table" and data.granted then counters.Rewards+=1 end
        task.wait(0.14)
    end
    task.wait(3)
end,0.65)
local lastBest=0
worker("autoBest",function()
    if os.clock()-lastBest<22 then task.wait(3)return end
    lastBest=os.clock()
    local ok,response=invoke("SpiritAction","EquipBest","Santuario",nil)
    if ok and response then counters.EquipBest+=1 end
    task.wait(1)
end,0.6)
local lastRebirth=0
worker("autoRebirth",function()
    if carrying() or #securedTools>0 or os.clock()-lastRebirth<7 then task.wait(2)return end
    lastRebirth=os.clock()
    local ok,data=invoke("Rebirth","Get")
    if ok and type(data)=="table" and data.info
        and tonumber(data.info.cost) and myMoney()>=data.info.cost then
        local sent,result=invoke("Rebirth","Do")
        if sent and type(result)=="table" and result.ok==true then
            counters.Rebirths+=1
        end
    end
    task.wait(2)
end,0.6)
local lastTreadmill=0
worker("autoTreadmill",function()
    if LP:GetAttribute("OnTreadmill")==true then task.wait(1)return end
    if carrying() or cfg.autoSteal then task.wait(0.6)return end
    if os.clock()-lastTreadmill<5 then task.wait(1)return end
    lastTreadmill=os.clock()
    local plot=ownPlot()
    local belt=plot and plot:FindFirstChild("Treadmill")
        and plot.Treadmill:FindFirstChild("Belt")
    local prompt=belt and belt:FindFirstChild("Prompt",true)
    if prompt and prompt:IsA("ProximityPrompt") then
        local pt=rootOf(prompt)
        if pt and moveTo(pt.Position,6) then applyPrompt(prompt) end
    end
    task.wait(1)
end,0.6)
local espObjects=setmetatable({},{__mode="k"})
local function clearESP()
    for source,adornments in pairs(espObjects) do
        for _,instance in pairs(adornments) do pcall(function()instance:Destroy()end) end
        espObjects[source]=nil
    end
end
local function addESP(object,adornee,labelText,color)
    if not object.Parent or espObjects[object] then return end
    local highlight=Instance.new("Highlight")
    highlight.Name="PVSP_Esp"
    highlight.Adornee=adornee
    highlight.FillTransparency=0.9
    highlight.OutlineTransparency=0
    highlight.OutlineColor=color
    highlight.FillColor=color
    highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent=adornee
    local bill=Instance.new("BillboardGui")
    bill.Name="PVSP_Label"
    bill.Adornee=rootOf(object) or rootOf(adornee)
    bill.AlwaysOnTop=true
    bill.Size=UDim2.fromOffset(225,50)
    bill.StudsOffsetWorldSpace=Vector3.new(0,4.5,0)
    bill.Parent=adornee
    local txt=Instance.new("TextLabel")
    txt.Size=UDim2.fromScale(1,1)
    txt.BackgroundTransparency=1
    txt.TextScaled=false
    txt.TextSize=13
    txt.Font=Enum.Font.GothamBold
    txt.TextStrokeTransparency=0.25
    txt.TextColor3=color
    txt.TextWrapped=true
    txt.Text=labelText
    txt.Parent=bill
    espObjects[object]={highlight,bill}
end
worker("autoESP",function()
    clearESP()
    local _,_,hrp=character()
    if not hrp then task.wait(1)return end
    local zones=WS:FindFirstChild("Zones")
    if zones then
        for _,obj in ipairs(zones:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Name=="StealPrompt" and obj.Enabled then
                local m=targetMetadata(obj)
                local pos=rootOf(obj)
                if pos and (hrp.Position-pos.Position).Magnitude<=cfg.espMaxDistance
                    and m.rank>=(rarityRank[cfg.espRarity] or 1) then
                    local name=m.definition and m.definition.name or tostring(m.id or "Espírito")
                    local color=m.definition and SpiritConfig.Rarities[m.rarity]
                        and SpiritConfig.Rarities[m.rarity].color or Color3.fromRGB(200,200,200)
                    addESP(obj,pos,name.." | "..m.rarity.." | "..tostring(m.income).."/s",color)
                end
            end
        end
        if cfg.espGuardians then
            for _,zone in ipairs(zones:GetChildren()) do
                local guardian=zone:FindFirstChild("Guardian")
                local part=rootOf(guardian)
                if part and (hrp.Position-part.Position).Magnitude<=cfg.espMaxDistance then
                    addESP(guardian,guardian,"GUARDIÃO | "..zone.Name,Color3.fromRGB(255,95,90))
                end
            end
        end
    end
    if cfg.espPlayers then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LP and p.Character then
                local part=rootOf(p.Character)
                if part and (hrp.Position-part.Position).Magnitude<=cfg.espMaxDistance then
                    addESP(p.Character,p.Character,p.DisplayName,Color3.fromRGB(100,180,255))
                end
            end
        end
    end
    task.wait(1.2)
end,0.6)
local oldCollisions=setmetatable({},{__mode="k"})
track(RunService.Stepped:Connect(function()
    if not cfg.autoNoclip then return end
    local c=LP.Character
    if not c then return end
    for _,part in ipairs(c:GetDescendants()) do
        if part:IsA("BasePart") then
            if oldCollisions[part]==nil then oldCollisions[part]=part.CanCollide end
            part.CanCollide=false
        end
    end
end))
local function restoreNoclip()
    for p,v in pairs(oldCollisions) do
        if p and p.Parent then pcall(function()p.CanCollide=v end)end
        oldCollisions[p]=nil
    end
end
track(LP.Idled:Connect(function()
    if cfg.antiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0,0))
        end)
    end
end))
local function setOption(key,value)
    cfg[key]=value
    if key=="autoNoclip" and value~=true then restoreNoclip() end
    if key=="autoESP" and value~=true then clearESP() end
    if key=="autoSteal" and value~=true then
        runtime.phase="idle"
        runtime.target=nil
        stopMovement()
    end
end
local function saveAll()
    if loading or not running then return end
    local state={schema=2,autoSave=cfg.autoSave,autoExec=cfg.autoExec}
    if cfg.autoSave then
        state.cfg={}
        for k,v in pairs(cfg) do
            if k~="autoSave" and k~="autoExec" then state.cfg[k]=v end
        end
    end
    writeJson(settingsPath,state)
end
local function change(key,value)
    setOption(key,value)
    saveAll()
end
local function notify(msg)
    if lib and type(lib.Notify)=="function" then
        pcall(function()lib:Notify({Title="Prime Void Hub",Description=msg,Time=4})end)
    else warn("[PVH SPIRIT] "..msg) end
end
local url="https://raw.githubusercontent.com/deividcomsono/Obsidian/82d402b5de7d8903915f1afe99b5b7e340e7cd28/Library.lua"
local okLib,loadedLib=pcall(function()return loadstring(game:HttpGet(url))()end)
if not okLib or type(loadedLib)~="table" then error("[PVH SPIRIT] Obsidian indisponível: "..tostring(loadedLib),0)end
lib=loadedLib
env.Library=lib;env.Toggles=lib.Toggles;env.Options=lib.Options
lib.ShowCustomCursor=false
lib.ToggleKeybind=Enum.KeyCode.Unknown
local Window=lib:CreateWindow({
    Title="PV Hub - Spirit Sanctuary",
    Footer="Prime Void Hub | Spirit Sanctuary "..version,
    Center=true,AutoShow=true,Resizable=true,Size=UDim2.fromOffset(690,540),
    MinSidebarWidth=185,EnableCompacting=true,SidebarCompactWidth=48,
    MobileButtonsSide="Right",NotifySide="Right",
    Animations={ToggleWindow=cfg.animations,TabSwitch=cfg.animations,
        Groupbox=false,Dropdown=cfg.animations,KeyPicker=cfg.animations},
})
local Tabs={
    Home=Window:AddTab(words("Início","Home"),"house"),
    Farm=Window:AddTab(words("Farm","Farm"),"pickaxe"),
    Misc=Window:AddTab(words("Miscelânea","Misc"),"wrench"),
    Config=Window:AddTab(words("Config.","Settings"),"settings"),
}
local homeAccount=header(Tabs.Home:AddGroupbox({
    Side="Left",Name=words("Conta","Account"),IconName="user-round"}),"Conta","Account")
local homeSession=header(Tabs.Home:AddGroupbox({
    Side="Left",Name=words("Estado da sessão","Session status"),IconName="activity"}),"Estado da sessão","Session status")
local homeGames=header(Tabs.Home:AddGroupbox({
    Side="Right",Name=words("Ports disponíveis","Available ports"),IconName="gamepad-2"}),"Ports disponíveis","Available ports")
local homeStats=header(Tabs.Home:AddGroupbox({
    Side="Right",Name=words("Estatísticas","Statistics"),IconName="bar-chart-3"}),"Estatísticas","Statistics")
homeAccount:AddLabel(LP.DisplayName.." (@"..LP.Name..")",true)
homeAccount:AddLabel("PlaceId: "..tostring(game.PlaceId),true)
homeAccount:AddLabel("Spirit Sanctuary • "..version,true)
homeGames:AddLabel("Ride Storm  •  HUNTRESS  •  Steal An Exu",true)
homeGames:AddLabel("Don't Splash  •  Destruction Simulator",true)
homeGames:AddLabel("Clover Legends  •  Spirit Sanctuary [TEST]",true)
statusText.main=homeSession:AddLabel(words("Inativo. Automações desligadas por padrão.","Idle. Automations off by default."),true)
statusText.move=homeSession:AddLabel(words("Movimento: Blink/Tween","Movement: Blink/Tween"),true)
statusText.stats=homeStats:AddLabel("0 / 0",true)
local farmSteal=header(Tabs.Farm:AddGroupbox({
    Side="Left",Name=words("Auto Steal Espíritos","Auto Steal Spirits"),IconName="swords"}),"Auto Steal Espíritos","Auto Steal Spirits")
local farmMovement=header(Tabs.Farm:AddGroupbox({
    Side="Left",Name=words("Deslocamento automático","Automatic movement"),IconName="move-3d"}),"Deslocamento automático","Automatic movement")
local farmProgress=header(Tabs.Farm:AddGroupbox({
    Side="Right",Name=words("Progresso automático","Automatic progress"),IconName="zap"}),"Progresso automático","Automatic progress")
local farmRewards=header(Tabs.Farm:AddGroupbox({
    Side="Right",Name=words("Recompensas","Rewards"),IconName="gift"}),"Recompensas","Rewards")
local miscVisual=header(Tabs.Misc:AddGroupbox({
    Side="Left",Name=words("ESP","ESP"),IconName="eye"}),"ESP","ESP")
local miscTravel=header(Tabs.Misc:AddGroupbox({
    Side="Right",Name=words("Teleportes","Teleports"),IconName="map-pin"}),"Teleportes","Teleports")
local miscExtra=header(Tabs.Misc:AddGroupbox({
    Side="Left",Name=words("Utilitários","Utilities"),IconName="shield"}),"Utilitários","Utilities")
local settingsSession=header(Tabs.Config:AddGroupbox({
    Side="Left",Name=words("Sessão","Session"),IconName="save"}),"Sessão","Session")
local settingsControl=header(Tabs.Config:AddGroupbox({
    Side="Left",Name=words("Controles","Controls"),IconName="keyboard"}),"Controles","Controls")
local settingsAppearance=header(Tabs.Config:AddGroupbox({
    Side="Right",Name=words("Aparência","Appearance"),IconName="sparkles"}),"Aparência","Appearance")
local settingsAbout=header(Tabs.Config:AddGroupbox({
    Side="Right",Name=words("Sobre","About"),IconName="circle-help"}),"Sobre","About")
env.PVH_SettingsPolish=settingsSession
local function toggle(group,id,key,pt,en)
    group:AddToggle(id,{Text=words(pt,en),Default=cfg[key],
        Callback=function(v)change(key,v==true)end})
end
toggle(farmSteal,"PVSP_autoSteal","autoSteal","Ativar Auto Steal","Enable Auto Steal")
toggle(farmSteal,"PVSP_autoPlace","autoPlace","Depositar no santuário","Place in sanctuary")
farmSteal:AddDropdown("PVSP_zone",{Text=words("Zona","Zone"),Values={
    "Auto","All","Zona 1","Zona 2","Zona 3","Zona 4","Zona 5",
    "Zona 6","Zona 7","Zona 8","Zona 9","Zona 10"},Default=cfg.zone,
    Callback=function(v)change("zone",v)end})
farmSteal:AddDropdown("PVSP_priority",{Text=words("Prioridade","Priority"),
    Values={"Raridade","Renda","Distância"},Default=cfg.priority,
    Callback=function(v)change("priority",v)end})
farmSteal:AddDropdown("PVSP_minRarity",{Text=words("Raridade mínima","Minimum rarity"),
    Values=rarityNames,Default=cfg.minRarity,Callback=function(v)change("minRarity",v)end})
farmSteal:AddSlider("PVSP_minIncome",{Text=words("Renda mínima /s","Minimum income /s"),
    Min=0,Max=1000000,Rounding=0,Default=cfg.minIncome,
    Callback=function(v)change("minIncome",v)end})
farmSteal:AddSlider("PVSP_stealTimeout",{Text=words("Tempo limite por alvo","Timeout per target"),
    Min=3,Max=20,Rounding=0,Default=cfg.stealTimeout,
    Callback=function(v)change("stealTimeout",v)end})
farmSteal:AddLabel(words("Só seleciona espíritos compatíveis com sua velocidade. Confirma Carrying e Tool Secured antes de continuar.",
    "Selects spirits within your speed. Confirms Carrying and Secured Tool before progressing."),true)
farmMovement:AddDropdown("PVSP_mode",{Text=words("Modo de deslocamento","Movement mode"),
    Values={"Tween","Blink"},Default=cfg.mode,
    Callback=function(v)change("mode",v);stopMovement()end})
farmMovement:AddSlider("PVSP_tweenSpeed",{Text=words("Velocidade Tween","Tween speed"),
    Min=80,Max=800,Rounding=0,Default=cfg.tweenSpeed,
    Callback=function(v)change("tweenSpeed",v)end})
farmMovement:AddLabel(words("Nunca usa caminhada vanilla. Tween voa com ancoragem temporária; Blink reposiciona.",
    "Never uses vanilla walking. Tween flies with temporary anchor; Blink repositions."),true)
toggle(farmProgress,"PVSP_autoTreadmill","autoTreadmill","Auto Esteira","Auto Treadmill")
toggle(farmProgress,"PVSP_autoBest","autoBest","Equipar melhores espíritos","Auto Equip Best")
toggle(farmProgress,"PVSP_autoRebirth","autoRebirth","Auto Renascimento","Auto Rebirth")
farmProgress:AddLabel(words("Renascimento só se a quantia necessária estiver disponível; desligado por padrão.",
    "Rebirth only if affordable; disabled by default."),true)
toggle(farmRewards,"PVSP_autoRewards","autoRewards","Resgatar recompensas","Auto Claim Rewards")
farmRewards:AddLabel(words("Diárias e de tempo jogado, com intervalo de 80 segundos.",
    "Daily and playtime rewards, checked every 80 seconds."),true)
toggle(miscVisual,"PVSP_autoESP","autoESP","ESP Espíritos","Spirit ESP")
toggle(miscVisual,"PVSP_espPlayers","espPlayers","Mostrar jogadores","Show players")
toggle(miscVisual,"PVSP_espGuardians","espGuardians","Mostrar guardiões","Show guardians")
miscVisual:AddDropdown("PVSP_espRarity",{Text=words("ESP raridade mínima","ESP minimum rarity"),
    Values=rarityNames,Default=cfg.espRarity,Callback=function(v)change("espRarity",v)end})
miscVisual:AddSlider("PVSP_espMaxDistance",{Text=words("Distância do ESP","ESP distance"),
    Min=300,Max=20000,Rounding=0,Default=cfg.espMaxDistance,
    Callback=function(v)change("espMaxDistance",v)end})
miscTravel:AddButton({Text=words("Teleporte para minha base","Teleport to my base"),Func=function()
    local plot=ownPlot()
    local spawn=plot and (plot:FindFirstChild("Spawn") or plot:FindFirstChild("Base"))
    if spawn then moveTo(spawn.Position,4) else notify(W("Base indisponível.","Plot unavailable.")) end
end})
local teleportZones={"Zona 1","Zona 2","Zona 3","Zona 4","Zona 5",
    "Zona 6","Zona 7","Zona 8","Zona 9","Zona 10"}
local chosenZone="Zona 1"
miscTravel:AddDropdown("PVSP_teleportZone",{Text=words("Zona de destino","Destination zone"),
    Values=teleportZones,Default="Zona 1",Callback=function(v)chosenZone=v end})
miscTravel:AddButton({Text=words("Ir para zona","Teleport to zone"),Func=function()
    local idx=chosenZone:match("%d+")
    local folder=WS:FindFirstChild("Zones")
    local zone=folder and folder:FindFirstChild("Zone"..tostring(idx))
    local obj=zone and (zone:FindFirstChild("Floor") or zone:FindFirstChild("Bounds"))
    if obj then moveTo(obj.Position,4) else notify(W("Zona indisponível.","Zone unavailable."))end
end})
toggle(miscExtra,"PVSP_autoNoclip","autoNoclip","Noclip","Noclip")
toggle(miscExtra,"PVSP_antiAFK","antiAFK","Anti-AFK","Anti-AFK")
miscExtra:AddButton({Text=words("Interromper deslocamento","Stop movement"),Func=stopMovement})
settingsSession:AddToggle("PVSP_autoSave",{Text=words("Auto Save (última sessão)","Auto Save (last session)"),
    Default=cfg.autoSave,Callback=function(v)
        cfg.autoSave=v==true
        if not cfg.autoSave then savedSnapshot=nil end
        saveAll()
    end})
settingsSession:AddToggle("PVSP_autoExec",{Text=words("Auto Execute (teleporte)","Auto Execute (teleport)"),
    Default=cfg.autoExec,Callback=function(v)
        cfg.autoExec=v==true
        saveAll()
    end})
settingsSession:AddButton({Text=words("Reentrar no servidor","Rejoin current server"),Func=function()
    local job=tostring(game.JobId or "")
    if job=="" then notify(W("JobId indisponível.","JobId unavailable.")) return end
    local ok,err=pcall(function()TeleportService:TeleportToPlaceInstance(game.PlaceId,job,LP)end)
    if not ok then notify(tostring(err)) end
end})
settingsSession:AddLabel(words("Auto Execute desta versão TEST carrega este port somente em teleportes reais.",
    "TEST Auto Execute loads this port only after actual teleports."),true)
local function unload()
    if not running then return end
    saveAll()
    running=false
    cfg.autoSteal=false
    cfg.autoESP=false
    stopMovement()
    restoreNoclip()
    clearESP()
    for _,conn in ipairs(aliveConns) do pcall(function()conn:Disconnect()end) end
    if env.PVH_SpiritUnload==unload then env.PVH_SpiritUnload=nil end
    if env.PVH_SpiritChecker then env.PVH_SpiritChecker=nil end
    if lib and not lib.Unloaded then pcall(function()lib:Unload()end)end
end
env.PVH_SpiritUnload=unload
local mini=settingsControl:AddButton({Text=words("Minimizar painel","Minimize panel"),Func=function()
    if lib then pcall(function()lib:Toggle()end)end
end})
mini:AddKeyPicker("PVSP_MinimizeKey",{Text=words("Minimizar","Minimize"),
    Default=cfg.minimizeKey,Mode="Press",SyncToggleState=false,
    ChangedCallback=function(key)change("minimizeKey",key and key.Name or "None")end})
local exit=settingsControl:AddButton({Text=words("Descarregar Hub","Unload Hub"),Func=unload})
exit:AddKeyPicker("PVSP_UnloadKey",{Text=words("Descarregar","Unload"),
    Default=cfg.unloadKey,Mode="Press",SyncToggleState=false,
    ChangedCallback=function(key)change("unloadKey",key and key.Name or "None")end})
local function refreshLocale()
    local gui=lib.ScreenGui
    if not gui then return end
    for _,g in ipairs(groupHeaders) do
        if g.group then g.group.Name=W(g.pt,g.en) end
    end
    for _,obj in ipairs(gui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local t=labels[obj.Text]
            if t then pcall(function()obj.Text=W(t.pt,t.en)end)end
        end
    end
end
settingsAppearance:AddDropdown("PVSP_Language",{Text=words("Idioma","Language"),
    Values={"pt-BR","en-US"},Default=cfg.language,Callback=function(v)
        change("language",v)
        task.defer(refreshLocale)
    end})
toggle(settingsAppearance,"PVSP_animations","animations","Animações da interface","UI animations")
toggle(settingsAppearance,"PVSP_sounds","sounds","Sons da interface","UI sounds")
settingsAbout:AddLabel(words("Port em TESTE: StealPrompt, Carrying, PlaceHeld, Rewards, Rebirth e SpiritAction analisados do .rbxlx.",
    "TEST port: StealPrompt, Carrying, PlaceHeld, Rewards, Rebirth and SpiritAction based on supplied .rbxlx."),true)
settingsAbout:AddLabel(words("O checker verifica estrutura e pré-requisitos, não confirma efeitos reais do servidor.",
    "The checker checks structure and prerequisites, not real server-side effects."),true)
local checkerGroup=header(Tabs.Config:AddGroupbox({Side="Right",
    Name=words("Diagnóstico","Diagnostics"),IconName="list-checks"}),"Diagnóstico","Diagnostics")
local checkerStatus=checkerGroup:AddLabel(words("Nenhum teste ainda.","No tests yet."),true)
local function checker()
    local list={}
    local function record(name,ok,detail)
        list[#list+1]={name=name,ok=ok==true,detail=detail}
    end
    local plots=WS:FindFirstChild("Plots")
    local zones=WS:FindFirstChild("Zones")
    local targetCount=0
    if zones then
        for _,p in ipairs(zones:GetDescendants()) do
            if p:IsA("ProximityPrompt") and p.Name=="StealPrompt" then targetCount+=1 end
        end
    end
    record("GamePlace",game.PlaceId==PLACE_ID,"place="..tostring(game.PlaceId))
    record("Remote.PlaceHeld",remote("PlaceHeld")~=nil,"RemoteFunction")
    record("Remote.SpiritAction",remote("SpiritAction")~=nil,"RemoteFunction")
    record("Remote.Rewards",remote("Rewards")~=nil,"RemoteFunction")
    record("Remote.Rebirth",remote("Rebirth")~=nil,"RemoteFunction")
    record("Remote.GetSpirits",remote("GetSpirits")~=nil,"RemoteFunction")
    record("Workspace.Zones",zones~=nil,"StealPrompts="..tostring(targetCount))
    record("Workspace.Plots",plots~=nil,"Own plot="..tostring(ownPlot()))
    record("ReplicatedStorage.Placement",Placement~=nil,"Source check available")
    record("Player.Character",select(3,character())~=nil,
        "Speed="..tostring(mySpeed()).." Carrying="..tostring(LP:GetAttribute("Carrying")))
    for k,v in pairs(counters) do record("metric."..k,true,tostring(v))end
    local okCount=0
    local lines={"PRIME VOID HUB | SPIRIT SANCTUARY TEST", "PlaceId="..tostring(game.PlaceId),
        "Version="..version,"Diagnostics validate READINESS, not gameplay success.",""}
    for _,v in ipairs(list) do
        if v.ok then okCount+=1 end
        lines[#lines+1]=(v.ok and "[STRUCTURE_OK] " or "[WARNING] ")..v.name.." | "..v.detail
    end
    local report=table.concat(lines,"\n")
    env.PVH_SpiritCheckerResult=report
    setLabel(checkerStatus,("Verificado: "..okCount.."/"..#list),
        ("Checked: "..okCount.."/"..#list))
    if type(writefile)=="function" then
        ensureDir("primevoid_hub/Spirit_Sanctuary")
        pcall(writefile,"primevoid_hub/Spirit_Sanctuary/PVH_Checker_spirit.txt",report)
    end
    return report
end
env.PVH_SpiritChecker=checker
checkerGroup:AddButton({Text=words("Verificar todas as funções","Check all features"),Func=function()
    checker()
    notify(W("Relatório gerado na workspace.","Report saved in executor workspace."))
end})
checkerGroup:AddButton({Text=words("Copiar diagnóstico","Copy diagnostics"),Func=function()
    local txt=env.PVH_SpiritCheckerResult or checker()
    if type(setclipboard)=="function" then pcall(setclipboard,txt)end
end})
lib:OnUnload(function()if running then unload()end end)
-- Restore the complete last session after controls exist.
if cfg.autoSave and savedSnapshot and type(savedSnapshot.cfg)=="table" then
    for k,v in pairs(savedSnapshot.cfg) do
        if type(v)=="boolean" then
            local t=lib.Toggles and lib.Toggles["PVSP_"..k]
            if t and type(t.SetValue)=="function" then
                pcall(function()t:SetValue(v)end)
            end
        elseif k=="mode" or k=="zone" or k=="priority" or k=="minRarity"
            or k=="espRarity" or k=="language" then
            local id="PVSP_"..k
            local opt=lib.Options and lib.Options[id]
            if opt then pcall(function()opt:SetValue(v)end)end
        end
    end
end
loading=false
task.spawn(function()
    local lastLocale=cfg.language
    while running do
        local plot=ownPlot()
        local stage=runtime.phase
        setLabel(statusText.main,
            "Fase: "..stage.." | "..tostring(plot and plot.Name or "sem base"),
            "Phase: "..stage.." | "..tostring(plot and plot.Name or "no plot"))
        setLabel(statusText.move,
            "Velocidade: "..tostring(mySpeed()).." | Movimento: "..cfg.mode,
            "Speed: "..tostring(mySpeed()).." | Movement: "..cfg.mode)
        setLabel(statusText.stats,
            "Roubos confirmados: "..counters.Secured.." | Depósitos: "..counters.Placed..
                " | Recompensas: "..counters.Rewards,
            "Confirmed steals: "..counters.Secured.." | Placed: "..counters.Placed..
                " | Rewards: "..counters.Rewards)
        if lastLocale~=cfg.language then lastLocale=cfg.language;refreshLocale() end
        task.wait(1)
    end
end)
-- Queue only in response to an actual teleport, never when switched on.
track(LP.OnTeleport:Connect(function(state)
    if not running or not cfg.autoExec then return end
    if state~=Enum.TeleportState.Started and state~=Enum.TeleportState.InProgress then return end
    local queue=env.queue_on_teleport or queue_on_teleport
    if type(queue)=="function" then
        pcall(queue,"loadstring(game:HttpGet("..string.format("%q",testURL).."))()")
    end
end))
task.defer(checker)
warn("[PVH SPIRIT] Loaded "..version.." | TEST only | PlaceId "..tostring(game.PlaceId))
