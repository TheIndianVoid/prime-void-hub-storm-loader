-- Prime Void Hub | Spirit Sanctuary (provisional title) | v0.1.2 TEST
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
local version="v0.1.2 TEST"
local settingsPath="primevoid_hub/Spirit_Sanctuary/Configs/ui_settings.json"
local testURL="https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/test/all-obfuscated-sources/SpiritSanctuary_TEST.lua"
local default={
    language="pt-BR",autoSave=true,autoExec=false,animations=true,sounds=false,
    mode="Blink",tweenSpeed=1800,zone="Auto",priority="Raridade",
    minRarity="Common",minIncome=0,ignoreSpeedLimit=false,stealPlayers=false,
    autoPlace=true,stealTimeout=4,interactDelay=0.1,
    espMaxDistance=8000,espRarity="Common",espPlayers=false,espGuardians=false,
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
    -- A previously saved long-distance Blink farm can send the player outside
    -- the world at startup. Do not auto-start movement on this migration.
    if type(prior.cfg)=="table" then
        prior.cfg.autoSteal=false
        -- Migrate the old 80..800 flight slider to the new FAST Tween range.
        -- Do not keep a saved 260-stud speed for the new 1800-stud default.
        if tonumber(prior.cfg.tweenSpeed)
            and prior.cfg.tweenSpeed<=800 then
            prior.cfg.tweenSpeed=1800
        end
    end
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
local SpiritConfig,ZoneConfig,Placement,RewardsConfig
pcall(function()SpiritConfig=require(config:WaitForChild("SpiritConfig",3))end)
pcall(function()ZoneConfig=require(config:WaitForChild("ZoneConfig",3))end)
pcall(function()Placement=require(shared:WaitForChild("Placement",3))end)
pcall(function()RewardsConfig=require(config:WaitForChild("RewardsConfig",3))end)
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
    if obj:IsA("Model") then return obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart",true) end
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
    local found={}
    local characterNow=LP.Character
    local backpack=LP:FindFirstChildOfClass("Backpack")
    for _,container in ipairs({characterNow or LP,backpack or LP}) do
        if container~=LP then
            for _,item in ipairs(container:GetChildren()) do
                if item:IsA("Tool")
                    and type(item:GetAttribute("SpiritId"))=="string"
                    and type(item:GetAttribute("SpiritKey"))=="string" then
                    found[#found+1]=item
                end
            end
        end
    end
    return found
end
-- Bounds are grounded in the provided map (plots near Z=-200..100,
-- zones from Z=211..2174). Refuse arbitrary, unknown coordinates.
local function safeDestination(p)
    if typeof(p)~="Vector3" then return false,"not_vector"end
    if p.X~=p.X or p.Y~=p.Y or p.Z~=p.Z then return false,"invalid_position"end
    if math.abs(p.X)>240 or p.Y< -35 or p.Y>240 or p.Z< -270 or p.Z>2300 then
        return false,"outside_map"
    end
    return true
end
-- Blink and Tween are strictly different modes. No hidden fallback to
-- sluggish AlignPosition flight, including for long destinations.
local function stopMovement()
    local m=runtime.activeMove
    runtime.activeMove=nil
    if not m then return end
    m.cancelled=true
    if m.tween then pcall(function()m.tween:Cancel()end)end
    if m.root and m.root.Parent then
        pcall(function()
            m.root.Anchored=m.oldAnchor
            m.root.CanCollide=m.oldCollide
        end)
    end
end
local function moveTo(position,reach)
    if not running then return false end
    local valid,reason=safeDestination(position)
    if not valid then
        runtime.lastError="unsafe_destination:"..tostring(reason)
        warn("[PVH SPIRIT MOVE] Invalid destination "..tostring(position))
        return false
    end
    local _,hum,root=character()
    if not root or root.Anchored or runtime.activeMove then return false end
    local distance=(root.Position-position).Magnitude
    if distance<=(reach or 4) then return true end
    if distance>2900 then runtime.lastError="distance_outside_map"return false end
    -- Keep the root near the prompt's actual Root, not inside the floor.
    local goal=position+Vector3.new(0,2.3,0)
    local horizontal=Vector3.new(position.X-root.Position.X,0,position.Z-root.Position.Z)
    local goalCF=CFrame.new(goal)*root.CFrame.Rotation
    if horizontal.Magnitude>0.15 then
        goalCF=CFrame.lookAt(goal,goal+horizontal.Unit)
    end
    local m={root=root,oldAnchor=root.Anchored,oldCollide=root.CanCollide,cancelled=false}
    runtime.activeMove=m
    local mode=cfg.mode
    local ok,err=pcall(function()
        if mode=="Blink" then
            -- Single nearly instant teleport at ANY supported map distance.
            -- Never switches silently to a flying mode.
            root.AssemblyLinearVelocity=Vector3.zero
            root.AssemblyAngularVelocity=Vector3.zero
            root.CFrame=goalCF
            task.wait(0.04)
        elseif mode=="Tween" then
            -- A fast, one-leg Tween with configurable studs/sec.
            root.Anchored=true
            root.CanCollide=false
            local speed=math.clamp(tonumber(cfg.tweenSpeed) or 1800,250,5000)
            local duration=math.clamp(distance/speed,0.045,2.2)
            local tw=TweenService:Create(root,TweenInfo.new(duration,Enum.EasingStyle.Linear),
                {CFrame=goalCF})
            m.tween=tw
            tw:Play()
            local deadline=os.clock()+duration+0.25
            while running and not m.cancelled and os.clock()<deadline
                and tw.PlaybackState==Enum.PlaybackState.Playing do
                task.wait(0.02)
            end
            if tw.PlaybackState==Enum.PlaybackState.Playing then
                error("tween_timeout")
            end
        else
            error("unsupported_move_mode:"..tostring(mode))
        end
    end)
    local cancelled=m.cancelled
    stopMovement()
    if not ok or cancelled or not running then
        runtime.lastError=tostring(err or "movement_cancelled")
        return false
    end
    local _,_,after=character()
    local arrived=after and (after.Position-goal).Magnitude<=math.max(reach or 4,7)
    if not arrived then
        counters.Rollbacks+=1
        runtime.lastError="server_position_correction_"..mode
        warn("[PVH SPIRIT MOVE] "..runtime.lastError)
        return false
    end
    runtime.lastError=""
    counters.Movements+=1
    return true
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
        task.wait(math.max(0.04,prompt.HoldDuration)+0.025)
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
                    and os.clock()-(recentPrompt[p] or -1e5)>0.24 then
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
    if finish then return finish:GetPivot().Position end
    local entry=zone:FindFirstChild("EntryGate")
    if entry then return entry:GetPivot().Position end
    local exit=zone:FindFirstChild("EndGate")
    if exit then return exit:GetPivot().Position end
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
        if finish then moveTo(finish,8) end
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
        task.wait(0.18)
        return
    end
    runtime.target=target
    runtime.targetZone=target.meta.zone
    runtime.phase="travel"
    if not moveTo(target.part.Position,5) then
        recentPrompt[target.prompt]=os.clock()-0.15
        task.wait(0.08)
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
    local deadline=os.clock()+math.clamp(tonumber(cfg.stealTimeout) or 4,1,12)
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
        task.wait(0.06)
    end
    counters.PromptFails+=1
    runtime.lastError="steal_not_confirmed"
    recentPrompt[target.prompt]=os.clock()-0.1 -- immediately eligible again
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
    if not carrying() and runtime.phase=="escape" then
        -- A death/drop also clears Carrying; count only actual secured loot.
        task.defer(function()
            if running and ((tonumber(LP:GetAttribute("HeldCount")) or 0)>0
                or #securedTools()>0) then
                counters.Secured+=1
            end
        end)
    end
end))
-- Rewards timing comes from the supplied game's RewardsConfig.Playtime.
-- Eight milestones are 10,20,30,40,50,60,70,80 minutes, NOT 80 seconds.
local lastRewards=0
local lastDailyRequest=-1e6
local rewardAttempts={}
worker("autoRewards",function()
    if os.clock()-lastRewards<20 then task.wait(1)return end
    lastRewards=os.clock()
    local ok,data=invoke("Rewards","Get")
    local state=ok and type(data)=="table" and data.state or nil
    local play=state and state.playtime or nil
    local elapsed=tonumber(LP:GetAttribute("Playtime"))
        or tonumber(play and play.seconds)
    if not elapsed then
        runtime.lastError="rewards_playtime_unavailable"
        task.wait(2)
        return
    end
    local milestones=RewardsConfig and RewardsConfig.Playtime
    if type(milestones)~="table" then
        runtime.lastError="rewards_config_missing"
        return
    end
    for i,entry in ipairs(milestones) do
        if not running or not cfg.autoRewards then break end
        local required=(tonumber(entry.minutes) or math.huge)*60
        local item=play and play.items and play.items[i]
        local alreadyClaimed=type(item)=="table" and item.claimed==true
        if elapsed>=required and not alreadyClaimed
            and os.clock()-(rewardAttempts[i] or -1e6)>90 then
            rewardAttempts[i]=os.clock()
            local sent,response=invoke("Rewards","ClaimPlaytime",i)
            if sent and type(response)=="table" and response.granted then
                counters.Rewards+=1
            end
            task.wait(0.2)
        end
    end
    -- Daily rewards are separate from playtime; check no more than once
    -- every twenty minutes. The server decides daily eligibility.
    if cfg.autoRewards and os.clock()-lastDailyRequest>1200 then
        lastDailyRequest=os.clock()
        local sent,response=invoke("Rewards","ClaimDaily",nil)
        if sent and type(response)=="table" and response.granted then
            counters.Rewards+=1
        end
    end
    task.wait(1)
end,0.65)
local lastBest=0
worker("autoBest",function()
    if os.clock()-lastBest<22 then task.wait(3)return end
    lastBest=os.clock()
    local ok,response=invoke("SpiritAction","EquipBest","Santuario",nil)
    if ok and response then counters.EquipBest+=1 end -- accepted response; not proof of changed equipment
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
-- Three independent ESP categories; toggling any one OFF destroys its
-- overlay immediately. Overlays are held client-side in PlayerGui, not
-- in a streamed NPC or character (which may be re-created mid-session).
local espObjects=setmetatable({},{__mode="k"})
local espRevision=0
local function clearESP()
    for source,entry in pairs(espObjects) do
        if entry.highlight then pcall(function()entry.highlight:Destroy()end)end
        if entry.billboard then pcall(function()entry.billboard:Destroy()end)end
        espObjects[source]=nil
    end
end
local function addESP(object,adornee,labelText,color)
    if not object or not object.Parent or not adornee or not adornee.Parent then return false end
    local root=rootOf(adornee)
    if not root then return false end
    if typeof(color)~="Color3" then color=Color3.fromRGB(205,205,205)end
    local prior=espObjects[object]
    if prior and prior.highlight and prior.highlight.Parent
        and prior.billboard and prior.billboard.Parent then
        prior.stamp=espRevision
        prior.highlight.Adornee=adornee
        prior.highlight.OutlineColor=color
        prior.text.Text=labelText
        prior.text.TextColor3=color
        prior.billboard.Adornee=root
        return true
    end
    local gui=LP:FindFirstChildOfClass("PlayerGui") or WS.CurrentCamera
    if not gui then return false end
    local h=Instance.new("Highlight")
    h.Name="PVSP_Highlight"
    h.Adornee=adornee
    h.Enabled=true
    h.FillTransparency=0.90
    h.OutlineTransparency=0
    h.OutlineColor=color
    h.FillColor=color
    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent=gui
    local bill=Instance.new("BillboardGui")
    bill.Name="PVSP_ESPLabel"
    bill.Adornee=root
    bill.AlwaysOnTop=true
    bill.LightInfluence=0
    bill.Size=UDim2.fromOffset(240,52)
    bill.StudsOffsetWorldSpace=Vector3.new(0,4,0)
    bill.Parent=gui
    local txt=Instance.new("TextLabel")
    txt.Size=UDim2.fromScale(1,1)
    txt.BackgroundTransparency=1
    txt.TextSize=14
    txt.Font=Enum.Font.GothamBold
    txt.TextStrokeTransparency=0.3
    txt.TextColor3=color
    txt.TextWrapped=true
    txt.Text=labelText
    txt.Parent=bill
    espObjects[object]={highlight=h,billboard=bill,text=txt,stamp=espRevision}
    return true
end
local function updateESP()
    espRevision+=1
    if not (cfg.autoESP or cfg.espPlayers or cfg.espGuardians) then
        clearESP()
        return
    end
    local _,_,hrp=character()
    if not hrp then clearESP()return end
    local count=0
    -- Roblox has a limited number of simultaneous Highlights.
    -- Prioritize PLAYERS so that Spirit ESP cannot use every slot.
    if cfg.espPlayers then
        for _,player in ipairs(Players:GetPlayers()) do
            if player~=LP and player.Character then
                local c=player.Character
                local humanoid=c:FindFirstChildOfClass("Humanoid")
                local root=c:FindFirstChild("HumanoidRootPart")
                if root and humanoid and humanoid.Health>0
                    and (hrp.Position-root.Position).Magnitude<=cfg.espMaxDistance then
                    if addESP(c,c,player.DisplayName.." (@"..player.Name..")",
                        Color3.fromRGB(96,174,255)) then count+=1 end
                end
            end
        end
    end
    local zones=WS:FindFirstChild("Zones")
    if zones and cfg.espGuardians then
        for _,zone in ipairs(zones:GetChildren()) do
            local guardian=zone:FindFirstChild("Guardian")
            local part=rootOf(guardian)
            if guardian and part and (hrp.Position-part.Position).Magnitude<=cfg.espMaxDistance then
                if addESP(guardian,guardian,
                    "GUARDIÃO | "..zone.Name,Color3.fromRGB(255,95,90)) then count+=1 end
            end
        end
    end
    if zones and cfg.autoESP then
        local candidates={}
        for _,prompt in ipairs(zones:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Name=="StealPrompt" and prompt.Enabled then
                local pos=rootOf(prompt)
                if pos then
                    local distance=(hrp.Position-pos.Position).Magnitude
                    if distance<=cfg.espMaxDistance then
                        local meta=targetMetadata(prompt)
                        if meta.rank>=(rarityRank[cfg.espRarity] or 1) then
                            candidates[#candidates+1]={obj=prompt,part=pos,meta=meta,dist=distance}
                        end
                    end
                end
            end
        end
        table.sort(candidates,function(a,b)return a.dist<b.dist end)
        for i=1,math.min(#candidates,math.max(0,28-count)) do
            local item=candidates[i]
            local m=item.meta
            local name=m.definition and m.definition.name or tostring(m.id or "Espírito")
            local rarity=SpiritConfig and SpiritConfig.Rarities and SpiritConfig.Rarities[m.rarity]
            addESP(item.obj,item.part,name.." | "..m.rarity.." | "..
                tostring(m.income).."/s",rarity and rarity.color or Color3.fromRGB(210,210,210))
        end
    end
    -- Remove only entries that were not refreshed: toggled-off ESP, distant,
    -- missing or despawned objects vanish automatically with no UI reload.
    for source,entry in pairs(espObjects) do
        if entry.stamp~=espRevision or not source.Parent then
            if entry.highlight then pcall(function()entry.highlight:Destroy()end)end
            if entry.billboard then pcall(function()entry.billboard:Destroy()end)end
            espObjects[source]=nil
        end
    end
end
task.spawn(function()
    while running do
        local ok,err=pcall(updateESP)
        if not ok then
            runtime.lastError="ESP:"..tostring(err)
            warn("[PVH SPIRIT ESP] "..tostring(err))
        end
        task.wait(0.55)
    end
    clearESP()
end)
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
    if key=="autoESP" or key=="espPlayers" or key=="espGuardians" then
        -- Never leave an old overlay from a category just turned off.
        clearESP()
        task.defer(function()if running then pcall(updateESP)end end)
    end
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
-- Character portrait inside the Home account card, same visual convention
-- as the universal Prime Void Hub ports.
task.defer(function()
    local holder=homeAccount and homeAccount.BoxHolder
    local canvas=holder and holder:FindFirstChildWhichIsA("ScrollingFrame",true)
    if not canvas then return end
    local avatar=Instance.new("ImageLabel")
    avatar.Name="PVH_SpiritAccountAvatar"
    avatar.BackgroundTransparency=1
    avatar.Size=UDim2.fromOffset(64,64)
    avatar.ScaleType=Enum.ScaleType.Crop
    avatar.LayoutOrder=-20
    avatar.Image=string.format(
        "rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150",LP.UserId)
    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(0,12)
    corner.Parent=avatar
    avatar.Parent=canvas
end)
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
farmSteal:AddLabel(words("Usa o SpiritId e SpiritKey originais. Reage rapidamente após interrupções; não força depósitos sem confirmação.",
    "Uses the original SpiritId and SpiritKey. Recovers promptly after interruptions; verifies placements."),true)
farmMovement:AddDropdown("PVSP_mode",{Text=words("Modo de deslocamento","Movement mode"),
    Values={"Tween","Blink"},Default=cfg.mode,
    Callback=function(v)change("mode",v);stopMovement()end})
farmMovement:AddSlider("PVSP_tweenSpeed",{Text=words("Velocidade Tween","Tween speed"),
    Min=250,Max=5000,Rounding=0,Default=cfg.tweenSpeed,
    Callback=function(v)change("tweenSpeed",v)end})
farmMovement:AddLabel(words("Blink: teleporte direto, sem voo. Tween: deslocamento aéreo rápido em uma etapa, com velocidade configurável.",
    "Blink: direct teleport, no flight. Tween: fast one-leg aerial movement with adjustable speed."),true)
toggle(farmProgress,"PVSP_autoTreadmill","autoTreadmill","Auto Esteira","Auto Treadmill")
toggle(farmProgress,"PVSP_autoBest","autoBest","Equipar melhores espíritos","Auto Equip Best")
toggle(farmProgress,"PVSP_autoRebirth","autoRebirth","Auto Renascimento","Auto Rebirth")
farmProgress:AddLabel(words("Renascimento só se a quantia necessária estiver disponível; desligado por padrão.",
    "Rebirth only if affordable; disabled by default."),true)
toggle(farmRewards,"PVSP_autoRewards","autoRewards","Resgatar recompensas","Auto Claim Rewards")
farmRewards:AddLabel(words("8 prêmios por tempo jogado: 10, 20, 30, 40, 50, 60, 70 e 80 minutos. Resgata somente quando elegível.",
    "8 playtime milestones at 10, 20, 30, 40, 50, 60, 70 and 80 minutes. Claims only when eligible."),true)
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
    record("ReplicatedStorage.RewardsConfig",RewardsConfig~=nil,
        "Playtime milestones="..tostring(RewardsConfig and #RewardsConfig.Playtime or 0))
    record("ESP.Flags",true,"Spirits="..tostring(cfg.autoESP).."; Players="..tostring(cfg.espPlayers)..
        "; Guardians="..tostring(cfg.espGuardians))
    record("Movement.Safety",true,"Mode="..cfg.mode.."; LastError="..tostring(runtime.lastError))
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
