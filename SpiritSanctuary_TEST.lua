-- Prime Void Hub | Spirit Sanctuary (provisional title) | v0.1.4 TEST
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
local ContextActionService=game:GetService("ContextActionService")
local LP=Players.LocalPlayer
local env=(type(getgenv)=="function" and getgenv()) or _G
if type(env.PVH_SpiritUnload)=="function" then pcall(env.PVH_SpiritUnload) end
local running=true
local version="v0.1.4 TEST"
local settingsPath="primevoid_hub/Spirit_Sanctuary/Configs/ui_settings.json"
local testURL="https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/test/all-obfuscated-sources/SpiritSanctuary_TEST.lua"
local default={
    language="pt-BR",autoSave=true,autoExec=false,animations=true,sounds=false,
    mode="Blink",tweenSpeed=1800,zone="Auto",priority="Rápido",
    minRarity="Common",minIncome=0,ignoreSpeedLimit=false,stealPlayers=false,
    autoPlace=true,autoPlaceStandalone=false,lockControls=true,carryTweenSpeed=900,
    stealTimeout=4,interactDelay=0.1,
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
local counters={Targets=0,StealAttempts=0,Secured=0,Placed=0,PlaceAttempts=0,
    EscapeAttempts=0,EscapeConfirmed=0,EscapeFailed=0,ControlLocks=0,ControlRestores=0,
    PromptFails=0,Rewards=0,
    EquipBest=0,Rebirths=0,Rollbacks=0,Movements=0,Skipped=0}
local runtime={phase="idle",target=nil,targetZone=nil,busy=false,activeMove=nil,
    lastSecure=0,lastPrompt=0,lastProgress=os.clock(),lastError="",lastPosition=nil,
    escapeNeeded=false,lastEscape=-1e6,escapeRetries=0,lockOwner="none",
    lastCarryAt=0,carryStartedAt=0,carryLostAt=0,carryLossPhase="",
    carryLossPosition="",carryTransitions=0,claimAttempts=0,claimConfirmed=0,
    lastClaimCheck="",lastCarryState=false}
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
-- Unified character ownership: user movement, jumping and manual prompts
-- cannot steal the character from Auto Steal / Auto Place / Auto Treadmill.
-- The Obsidian UI is NOT blocked. Everything is restored on disable/unload.
local automationLock={active=false,humanoid=nil,original=nil,controls=nil,
    actionBound=false,lastCheck=0,errors=0}
local ACTION_NAME="PVSP_AutomationMovementLock"
local blockedKeys={
    Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,
    Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right,
    Enum.KeyCode.Space,Enum.KeyCode.E,Enum.KeyCode.F,Enum.KeyCode.G,
    Enum.KeyCode.ButtonA,Enum.KeyCode.ButtonX,Enum.KeyCode.ButtonY,
    Enum.KeyCode.DPadUp,Enum.KeyCode.DPadDown,Enum.KeyCode.DPadLeft,
    Enum.KeyCode.DPadRight,Enum.KeyCode.Thumbstick1,
}
local function desiredControlLock()
    return running and cfg.lockControls
        and (cfg.autoSteal or cfg.autoPlaceStandalone or cfg.autoTreadmill)
end
local function getPlayerControls()
    if automationLock.controls then return automationLock.controls end
    local ps=LP:FindFirstChildOfClass("PlayerScripts")
    local module=ps and ps:FindFirstChild("PlayerModule")
    if not module then return nil end
    local ok,ctrl=pcall(function()
        local playerModule=require(module)
        return playerModule:GetControls()
    end)
    if ok and type(ctrl)=="table" then
        automationLock.controls=ctrl
        return ctrl
    end
    return nil
end
local function releaseControlLock()
    if automationLock.actionBound then
        pcall(function()ContextActionService:UnbindAction(ACTION_NAME)end)
        automationLock.actionBound=false
    end
    if automationLock.controls then
        pcall(function()automationLock.controls:Enable()end)
    end
    local hum=automationLock.humanoid
    local old=automationLock.original
    if hum and hum.Parent and old then
        pcall(function()
            hum.WalkSpeed=old.WalkSpeed
            hum.JumpPower=old.JumpPower
            hum.JumpHeight=old.JumpHeight
            hum.AutoRotate=old.AutoRotate
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,old.Jumping)
        end)
    end
    if automationLock.active then counters.ControlRestores+=1 end
    automationLock.active=false
    automationLock.humanoid=nil
    automationLock.original=nil
    runtime.lockOwner="none"
end
local function applyControlLock()
    if not desiredControlLock() then
        if automationLock.active then releaseControlLock()end
        return
    end
    local _,hum=character()
    if not hum then
        if automationLock.active then releaseControlLock()end
        return
    end
    if automationLock.humanoid~=hum then
        if automationLock.active then releaseControlLock()end
        automationLock.humanoid=hum
        local jumpAllowed=true
        pcall(function()jumpAllowed=hum:GetStateEnabled(Enum.HumanoidStateType.Jumping)end)
        automationLock.original={
            WalkSpeed=hum.WalkSpeed,JumpPower=hum.JumpPower,
            JumpHeight=hum.JumpHeight,AutoRotate=hum.AutoRotate,
            Jumping=jumpAllowed,
        }
        automationLock.active=true
        counters.ControlLocks+=1
        if not automationLock.actionBound then
            local ok=pcall(function()
                ContextActionService:BindActionAtPriority(ACTION_NAME,function()
                    return Enum.ContextActionResult.Sink
                end,false,4200,table.unpack(blockedKeys))
            end)
            automationLock.actionBound=ok
            if not ok then automationLock.errors+=1 end
        end
        local controls=getPlayerControls()
        if controls then pcall(function()controls:Disable()end)end
    end
    -- One owner only. The hub still controls CFrame/Tween normally.
    pcall(function()
        if hum.WalkSpeed~=0 then hum.WalkSpeed=0 end
        if hum.JumpPower~=0 then hum.JumpPower=0 end
        if hum.JumpHeight~=0 then hum.JumpHeight=0 end
        hum.Jump=false
        hum.AutoRotate=false
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
        hum:Move(Vector3.zero,false)
    end)
    runtime.lockOwner=cfg.autoSteal and "Auto Steal"
        or (cfg.autoPlaceStandalone and "Auto Place" or "Auto Treadmill")
end
track(RunService.Heartbeat:Connect(function()
    if not running then return end
    if os.clock()-automationLock.lastCheck<0.07 then return end
    automationLock.lastCheck=os.clock()
    local ok,err=pcall(applyControlLock)
    if not ok then
        automationLock.errors+=1
        runtime.lastError="controls_lock:"..tostring(err)
    end
end))
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
local function moveTo(position,reach,overrideMode,overrideSpeed)
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
    if distance>2900 then runtime.lastError="distance_outside_map" return false end
    local goal=position+Vector3.new(0,2.3,0)
    local direction=Vector3.new(goal.X-root.Position.X,0,goal.Z-root.Position.Z)
    local goalCF=CFrame.new(goal)*root.CFrame.Rotation
    if direction.Magnitude>0.15 then
        goalCF=CFrame.lookAt(goal,goal+direction.Unit)
    end
    local m={root=root,oldAnchor=root.Anchored,oldCollide=root.CanCollide,cancelled=false}
    runtime.activeMove=m
    local mode=overrideMode or cfg.mode
    local ok,err=pcall(function()
        if mode=="Blink" then
            -- Blink is an actual teleport. Only use it for non-carrying trips;
            -- the game's server can drop a spirit on skipped extraction.
            if carrying() then error("blink_while_carrying_prohibited")end
            root.AssemblyLinearVelocity=Vector3.zero
            root.AssemblyAngularVelocity=Vector3.zero
            root.CFrame=goalCF
            task.wait(0.045)
        elseif mode=="Tween" then
            -- REAL visible flight. Do not anchor the root (anchored tweens
            -- can replicate to the server like a one-frame teleport).
            -- Every Heartbeat advances the position along the whole route.
            local speed=math.clamp(tonumber(overrideSpeed or cfg.tweenSpeed) or 1400,150,5000)
            local duration=math.clamp(distance/speed,0.25,8)
            local startCF=root.CFrame
            root.CanCollide=false
            local startAt=os.clock()
            local frames=0
            while running and not m.cancelled do
                if not root.Parent or hum.Health<=0 then error("tween_character_lost")end
                local alpha=math.clamp((os.clock()-startAt)/duration,0,1)
                root.CFrame=startCF:Lerp(goalCF,alpha)
                root.AssemblyLinearVelocity=Vector3.zero
                root.AssemblyAngularVelocity=Vector3.zero
                frames+=1
                if alpha>=1 then break end
                RunService.Heartbeat:Wait()
            end
            if not m.cancelled and frames<2 then error("tween_no_frames")end
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
                else counters.Skipped+=1 end
            end
        end
    end
    counters.Targets=#list
    table.sort(list,function(a,b)
        if cfg.priority=="Rápido" or cfg.priority=="Distância" then
            if math.abs(a.distance-b.distance)>3 then return a.distance<b.distance end
            return a.meta.rank>b.meta.rank
        elseif cfg.priority=="Raridade" then
            if a.meta.rank~=b.meta.rank then return a.meta.rank>b.meta.rank end
            if a.meta.income~=b.meta.income then return a.meta.income>b.meta.income end
        elseif cfg.priority=="Renda" then
            if a.meta.income~=b.meta.income then return a.meta.income>b.meta.income end
        end
        return a.distance<b.distance
    end)
    return list
end
local function safeReturnPosition()
    local plot=ownPlot()
    if not plot then return nil,"no_owned_plot" end
    local spawn=plot:FindFirstChild("Spawn")
    local base=plot:FindFirstChild("Base")
    local dest=spawn and spawn.Position or (base and base.Position)
    if not dest then return nil,"owned_plot_no_spawn"end
    local safe,why=safeDestination(dest)
    return safe and dest or nil,why
end
local function finishLineRegion()
    -- In the supplied .rbxlx, Zone1.Bounds starts around Z=120.
    -- Its real FinishLine.Glow is a 110-wide stripe at Z=115.8,
    -- separating the dangerous garden from the safe sanctuary approach.
    local zones=WS:FindFirstChild("Zones")
    local one=zones and zones:FindFirstChild("Zone1")
    local line=one and one:FindFirstChild("FinishLine")
    local glow=line and line:FindFirstChild("Glow")
    local position=glow and glow.Position or nil
    if position and safeDestination(position) then return position,glow end
    return nil,nil
end
local function carryingSecured()
    return #securedTools()>0 or (tonumber(LP:GetAttribute("HeldCount")) or 0)>0
end
local function waitForClaim(seconds)
    local deadline=os.clock()+(seconds or 0.8)
    local clearedAt=nil
    repeat
        if not running or not cfg.autoSteal then return false,"farm_cancelled"end
        if not carrying() and carryingSecured() then
            runtime.claimConfirmed+=1
            runtime.lastClaimCheck="secured_after_finishline"
            return true,"secured"
        end
        if not carrying() then
            clearedAt=clearedAt or os.clock()
            -- The tool and HeldCount may replicate a few frames AFTER the
            -- Carrying attribute clears. Do not mistake that for a drop.
        else
            clearedAt=nil
        end
        task.wait(0.035)
    until os.clock()>=deadline
    if clearedAt then
        runtime.lastClaimCheck="carrying_cleared_no_secured_tool"
        return false,"lost_spirit_or_inventory_delay"
    end
    runtime.lastClaimCheck="finishline_not_confirmed"
    return false,"still_carrying_after_finishline"
end
local function escapeImmediately()
    local home,homeReason=safeReturnPosition()
    local finish=finishLineRegion()
    if not home or not finish then
        runtime.lastError="missing_claim_route:"..tostring(homeReason)
        counters.EscapeFailed+=1
        runtime.phase="escape_no_route"
        stopFeature("autoSteal")
        return false
    end
    runtime.escapeNeeded=true
    runtime.phase="to_finishline"
    counters.EscapeAttempts+=1
    runtime.claimAttempts+=1
    runtime.lastEscape=os.clock()
    -- Never Blink out of the zone while Carrying. The client screenshot
    -- shows the server returning the spirit when the route was skipped.
    -- Blink remains a real teleport for traveling WITHOUT a spirit.
    local _,_,root=character()
    if not root then
        runtime.lastError="missing_root_during_escape"
        counters.EscapeFailed+=1
        return false
    end
    local x=math.clamp(root.Position.X,finish.X-47,finish.X+47)
    local beforeLine=Vector3.new(x,0.1,finish.Z+15)
    local afterLine=Vector3.new(x,0.1,finish.Z-13)
    -- This is an uninterrupted, visible, fast route through the actual
    -- zone boundary. No instantaneous hop across the claim trigger.
    local speed=math.clamp(tonumber(cfg.carryTweenSpeed) or 900,200,2500)
    if carrying() then
        if (root.Position-beforeLine).Magnitude>9 and root.Position.Z>finish.Z+7 then
            if not moveTo(beforeLine,6,"Tween",speed) then
                runtime.lastError="route_to_finishline_failed:"..tostring(runtime.lastError)
                counters.EscapeFailed+=1
                return false
            end
        end
    end
    if not carrying() then
        runtime.lastClaimCheck="carrying_cleared_before_finishline"
    else
        runtime.phase="cross_finishline"
        if not moveTo(afterLine,5,"Tween",speed) then
            runtime.lastError="finishline_crossing_failed:"..tostring(runtime.lastError)
            counters.EscapeFailed+=1
            return false
        end
    end
    runtime.phase="verify_claim"
    local claimed,reason=waitForClaim(0.85)
    if not claimed then
        runtime.escapeRetries+=1
        counters.EscapeFailed+=1
        runtime.lastError="claim_failed:"..tostring(reason)
        -- Dropped spirits cannot be recovered by teleporting to the plot.
        -- Keep the cause visible and let the next farm tick choose a new
        -- target only after confirming no spirit is still carried.
        if carrying() and runtime.escapeRetries>=2 then
            runtime.phase="finishline_manual_check"
            stopFeature("autoSteal")
        elseif not carrying() then
            runtime.phase="lost_spirit_retry"
            runtime.escapeNeeded=false
        end
        return false
    end
    runtime.phase="return_with_secured_spirit"
    -- After the server grants the tool, Blink is safe again because there is
    -- nothing being carried. Respect the user's selected movement mode.
    if not moveTo(home,9,cfg.mode) then
        runtime.lastError="secured_home_return_failed:"..tostring(runtime.lastError)
        counters.EscapeFailed+=1
        return false
    end
    runtime.escapeRetries=0
    runtime.escapeNeeded=false
    runtime.target=nil
    runtime.lastError=""
    counters.EscapeConfirmed+=1
    counters.Secured+=1
    runtime.phase="secured_at_home"
    return true
end

local function placeOneImpl()
    local tools=securedTools()
    if #tools==0 then return false,"no_spirit_tool" end
    local plot=ownPlot()
    local base=plot and plot:FindFirstChild("Base")
    if not base or not Placement or type(Placement.findSpot)~="function"
        or type(Placement.check)~="function" then
        return false,"plot_or_Placement_missing"
    end
    local spiritCount=tonumber(LP:GetAttribute("SpiritCount")) or 0
    local capacity=tonumber(LP:GetAttribute("Capacity")) or math.huge
    if spiritCount>=capacity then return false,"sanctuary_full" end
    local tool=tools[1]
    local key=tool:GetAttribute("SpiritKey")
    if type(key)~="string" or key=="" then return false,"missing_spirit_key" end
    local _,hum=character()
    if not hum then return false,"no_humanoid" end
    -- The native PlacementController starts from an equipped spirit tool.
    if tool.Parent~=LP.Character then
        local equipped=pcall(function()hum:EquipTool(tool)end)
        if not equipped then return false,"equip_failed" end
        task.wait(0.08)
        if tool.Parent~=LP.Character then return false,"equip_not_confirmed" end
    end
    local random=Random.new()
    local lastReason="no_valid_placement"
    for _=1,12 do
        if not running or not (cfg.autoPlace or cfg.autoPlaceStandalone)
            or not tool.Parent then return false,"cancelled" end
        local found,position=pcall(Placement.findSpot,plot,nil,random)
        if not found then
            lastReason="findSpot_error:"..tostring(position)
            break
        end
        if typeof(position)~="Vector3" then
            lastReason="no_valid_placement"
            break
        end
        local valid,why=Placement.check(plot,position,{})
        if valid then
            local beforeSpirit=tonumber(LP:GetAttribute("SpiritCount")) or 0
            local beforeHeld=tonumber(LP:GetAttribute("HeldCount")) or 0
            runtime.phase="placing"
            counters.PlaceAttempts+=1
            local connected,accepted,detail=invoke("PlaceHeld",key,position)
            if not connected then
                lastReason="place_remote_error:"..tostring(detail)
            elseif accepted~=true then
                lastReason="place_rejected:"..tostring(detail or accepted)
            else
                local deadline=os.clock()+0.9
                repeat
                    local newSpirit=tonumber(LP:GetAttribute("SpiritCount")) or 0
                    local newHeld=tonumber(LP:GetAttribute("HeldCount")) or 0
                    if not tool.Parent or newSpirit>beforeSpirit or newHeld<beforeHeld then
                        counters.Placed+=1
                        runtime.lastProgress=os.clock()
                        runtime.lastError=""
                        return true,"placed_confirmed"
                    end
                    task.wait(0.045)
                until not running or os.clock()>=deadline
                lastReason="place_accepted_unconfirmed"
            end
        else
            lastReason="local_placement_rejected:"..tostring(why)
        end
    end
    runtime.lastError=lastReason
    return false,lastReason
end
local function placeOne()
    if runtime.placing then return false,"placement_busy" end
    runtime.placing=true
    local ok,placed,reason=pcall(placeOneImpl)
    runtime.placing=false
    if not ok then
        runtime.lastError="placement_runtime:"..tostring(placed)
        return false,runtime.lastError
    end
    return placed,reason
end
local function autoStealStep()
    if not cfg.autoSteal then return end
    if carrying() or runtime.escapeNeeded then
        runtime.phase="escape"
        if carrying() then
            escapeImmediately()
        else
            runtime.escapeNeeded=false
            runtime.escapeRetries=0
            runtime.phase="secured_after_escape"
        end
        task.wait(0.02)
        return
    end
    if (cfg.autoPlace or cfg.autoPlaceStandalone) and #securedTools()>0 then
        runtime.phase="place"
        local plot=ownPlot()
        local base=plot and plot:FindFirstChild("Base")
        if not base then
            runtime.lastError="own_plot_base_missing"
            task.wait(0.15)
            return
        end
        if not moveTo(base.Position,9) then task.wait(0.1)return end
        local ok,reason=placeOne()
        if not ok and reason=="sanctuary_full" then
            runtime.phase="sanctuary_full"
            stopFeature("autoSteal")
        elseif not ok then
            runtime.phase="place_failed"
            runtime.lastError=tostring(reason)
        end
        task.wait(ok and 0.05 or 0.22)
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
    if not cfg.autoSteal or carrying()
        or not target.prompt.Parent or not target.prompt.Enabled then return end
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
    local deadline=os.clock()+math.clamp((tonumber(cfg.stealTimeout) or 4)*0.28,0.6,1.5)
    while running and cfg.autoSteal and os.clock()<deadline do
        if runtime.phase=="recover_after_hit" then break end
        if carrying() and not before then
            runtime.phase="carrying_confirmed"
            runtime.escapeNeeded=true
            runtime.lastProgress=os.clock()
            return
        end
        if #securedTools>0 then
            runtime.phase="secured_confirmed"
            return
        end
        task.wait(0.04)
    end
    if runtime.phase~="recover_after_hit" then
        counters.PromptFails+=1
        runtime.lastError="steal_not_confirmed"
    end
    recentPrompt[target.prompt]=nil -- same spirit can be retried immediately
end
local function worker(flag,fn,interval)
    task.spawn(function()
        while running do
            if cfg[flag] then
                local ok,err=pcall(fn)
                if not ok then
                    runtime.lastError=tostring(err)
                    warn("[PVH SPIRIT] "..flag..": "..tostring(err))
                    -- Errors during live farm/deposit/treadmill must not impose
                    -- a 1.5 second dead period while a guardian can still hit.
                    local movementWorker=flag=="autoSteal" or flag=="autoPlaceStandalone"
                        or flag=="autoTreadmill"
                    task.wait(movementWorker and 0.16 or 1.5)
                end
            else task.wait(interval or 0.35) end
        end
    end)
end
worker("autoSteal",autoStealStep,0.4)
-- The deposit toggle also operates independently when Auto Steal is off.
-- It does nothing if there is no valid spirit tool in the inventory.
worker("autoPlaceStandalone",function()
    if cfg.autoSteal or carrying() or #securedTools()==0 then
        task.wait(0.15)
        return
    end
    runtime.phase="place_only"
    local plot=ownPlot()
    local base=plot and plot:FindFirstChild("Base")
    if base and moveTo(base.Position,9) then
        local placed,reason=placeOne()
        if not placed then runtime.lastError=tostring(reason) end
    else
        runtime.lastError="place_only_base_unreachable"
    end
    task.wait(0.3)
end,0.4)
track(LP:GetAttributeChangedSignal("HeldCount"):Connect(function()
    runtime.lastSecure=os.clock()
end))
track(LP:GetAttributeChangedSignal("Carrying"):Connect(function()
    local now=os.clock()
    local nextState=carrying()
    runtime.carryTransitions+=1
    runtime.lastCarryAt=now
    local _,_,root=character()
    if nextState then
        runtime.carryStartedAt=now
        if cfg.autoSteal then
            runtime.escapeNeeded=true
            runtime.phase="escape_priority"
            -- Prioritize extraction the instant a spirit is acquired.
            if runtime.activeMove then stopMovement() end
        end
    else
        runtime.carryLostAt=now
        runtime.carryLossPhase=runtime.phase
        runtime.carryLossPosition=root and tostring(root.Position) or "no_root"
        if runtime.target and runtime.target.prompt then
            recentPrompt[runtime.target.prompt]=nil
        end
    end
    runtime.lastCarryState=nextState
end))
local healthConnection=nil
local function watchGuardianHits(char)
    if healthConnection then pcall(function()healthConnection:Disconnect()end)end
    healthConnection=nil
    local hum=char and (char:FindFirstChildOfClass("Humanoid")
        or char:WaitForChild("Humanoid",3))
    if not hum then return end
    local previous=hum.Health
    healthConnection=track(hum.HealthChanged:Connect(function(hp)
        if hp<previous and cfg.autoSteal and not carrying() then
            if runtime.target and runtime.target.prompt then
                recentPrompt[runtime.target.prompt]=nil
            end
            runtime.phase="recover_after_hit"
            runtime.lastProgress=os.clock()
        end
        previous=hp
    end))
end
track(LP.CharacterAdded:Connect(function(char)
    task.defer(watchGuardianHits,char)
end))
if LP.Character then task.defer(watchGuardianHits,LP.Character)end
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
    if carrying() or cfg.autoSteal or cfg.autoPlaceStandalone then
        task.wait(0.12)return
    end
    if os.clock()-lastTreadmill<0.8 then task.wait(0.15)return end
    lastTreadmill=os.clock()
    local plot=ownPlot()
    local belt=plot and plot:FindFirstChild("Treadmill")
        and plot.Treadmill:FindFirstChild("Belt")
    local prompt=belt and belt:FindFirstChild("Prompt",true)
    if prompt and prompt:IsA("ProximityPrompt") then
        local pt=rootOf(prompt)
        if pt and moveTo(pt.Position,6) then applyPrompt(prompt) end
    end
    task.wait(0.15)
end,0.4)
-- Three independent ESP categories; toggling any one OFF destroys its
-- overlay immediately. Overlays are held client-side in PlayerGui, not
-- in a streamed NPC or character (which may be re-created mid-session).
-- ESP engine v3: each category owns its instances, and toggle.Value
-- overrides cached cfg. Thus even a missed Obsidian Callback cannot leave
-- an ESP drawn after the user turns the control off.
local espObjects={spirits={},guardians={},players={}}
local espIteration=0
local function purgeOldESP()
    local playerGui=LP:FindFirstChildOfClass("PlayerGui")
    local roots={playerGui,WS:FindFirstChild("Zones")}
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Character then roots[#roots+1]=p.Character end
    end
    local obsolete={
        PVSP_Esp=true,PVSP_Label=true,PVSP_Highlight=true,PVSP_ESPLabel=true,
        PVSP_SpiritESP=true,PVSP_GuardianESP=true,PVSP_PlayerESP=true,
    }
    for _,root in ipairs(roots) do
        if root then
            local descendants=root:GetDescendants()
            for _,node in ipairs(descendants) do
                if obsolete[node.Name] then pcall(function()node:Destroy()end) end
            end
        end
    end
end
purgeOldESP()
local function clearESPGroup(category)
    local owned=espObjects[category]
    if not owned then return end
    for obj,entry in pairs(owned) do
        if entry.highlight then pcall(function()entry.highlight:Destroy()end)end
        if entry.billboard then pcall(function()entry.billboard:Destroy()end)end
        owned[obj]=nil
    end
end
local function clearESP()
    clearESPGroup("spirits")
    clearESPGroup("guardians")
    clearESPGroup("players")
    purgeOldESP()
end
local function espIsOn(flag)
    local control=lib and lib.Toggles and lib.Toggles["PVSP_"..flag]
    return cfg[flag]==true and (not control or control.Value==true)
end
local function addESP(category,obj,adornee,name,color)
    local owned=espObjects[category]
    if not owned or not obj or not obj.Parent or not adornee or not adornee.Parent then
        return false
    end
    local root=rootOf(adornee)
    if not root then return false end
    if typeof(color)~="Color3" then color=Color3.fromRGB(205,205,205)end
    local entry=owned[obj]
    if entry and entry.highlight and entry.highlight.Parent
        and entry.billboard and entry.billboard.Parent then
        entry.updated=espIteration
        entry.highlight.Adornee=adornee
        entry.highlight.OutlineColor=color
        entry.highlight.FillColor=color
        entry.billboard.Adornee=root
        entry.text.Text=name
        entry.text.TextColor3=color
        return true
    end
    local playerGui=LP:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return false end
    local highlight=Instance.new("Highlight")
    highlight.Name="PVSP_"..category.."_Highlight"
    highlight.Adornee=adornee
    highlight.FillColor=color
    highlight.FillTransparency=0.92
    highlight.OutlineColor=color
    highlight.OutlineTransparency=0
    highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent=playerGui
    local billboard=Instance.new("BillboardGui")
    billboard.Name="PVSP_"..category.."_Billboard"
    billboard.Adornee=root
    billboard.AlwaysOnTop=true
    billboard.LightInfluence=0
    billboard.Size=UDim2.fromOffset(220,52)
    billboard.StudsOffsetWorldSpace=Vector3.new(0,4,0)
    billboard.Parent=playerGui
    local text=Instance.new("TextLabel")
    text.Size=UDim2.fromScale(1,1)
    text.BackgroundTransparency=1
    text.Font=Enum.Font.GothamBold
    text.TextSize=14
    text.TextWrapped=true
    text.TextStrokeTransparency=0.25
    text.TextColor3=color
    text.Text=name
    text.Parent=billboard
    owned[obj]={highlight=highlight,billboard=billboard,text=text,updated=espIteration}
    return true
end
local function updateESP()
    espIteration+=1
    local onPlayers=espIsOn("espPlayers")
    local onGuardians=espIsOn("espGuardians")
    local onSpirits=espIsOn("autoESP")
    if not onPlayers then clearESPGroup("players")end
    if not onGuardians then clearESPGroup("guardians")end
    if not onSpirits then clearESPGroup("spirits")end
    if not (onPlayers or onGuardians or onSpirits) then return end
    local _,_,hrp=character()
    if not hrp then clearESP()return end
    local count=0
    if onPlayers then
        for _,player in ipairs(Players:GetPlayers()) do
            if player~=LP and player.Character then
                local c=player.Character
                local humanoid=c:FindFirstChildOfClass("Humanoid")
                local root=c:FindFirstChild("HumanoidRootPart")
                if root and humanoid and humanoid.Health>0
                    and (hrp.Position-root.Position).Magnitude<=cfg.espMaxDistance then
                    if addESP("players",c,c,player.DisplayName.." (@"..player.Name..")",
                        Color3.fromRGB(110,176,255)) then count+=1 end
                end
            end
        end
    end
    local zones=WS:FindFirstChild("Zones")
    if zones and onGuardians then
        for _,zone in ipairs(zones:GetChildren()) do
            local g=zone:FindFirstChild("Guardian")
            local part=rootOf(g)
            if g and part and (hrp.Position-part.Position).Magnitude<=cfg.espMaxDistance then
                if addESP("guardians",g,g,"GUARDIÃO | "..zone.Name,
                    Color3.fromRGB(255,100,85)) then count+=1 end
            end
        end
    end
    if zones and onSpirits then
        local all={}
        for _,prompt in ipairs(zones:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Name=="StealPrompt"
                and prompt.Enabled then
                local part=rootOf(prompt)
                if part then
                    local dist=(hrp.Position-part.Position).Magnitude
                    if dist<=cfg.espMaxDistance then
                        local meta=targetMetadata(prompt)
                        if meta.rank>=(rarityRank[cfg.espRarity] or 1) then
                            all[#all+1]={prompt=prompt,part=part,meta=meta,dist=dist}
                        end
                    end
                end
            end
        end
        table.sort(all,function(a,b)return a.dist<b.dist end)
        for i=1,math.min(#all,math.max(0,30-count)) do
            local e=all[i]
            local d=e.meta.definition
            local display=d and d.name or tostring(e.meta.id or "Espírito")
            local rarityDef=SpiritConfig and SpiritConfig.Rarities
                and SpiritConfig.Rarities[e.meta.rarity]
            addESP("spirits",e.prompt,e.part,display.." | "..e.meta.rarity
                .." | "..tostring(e.meta.income).."/s",
                rarityDef and rarityDef.color or Color3.fromRGB(210,210,210))
        end
    end
    for _,category in ipairs({"spirits","guardians","players"}) do
        for obj,entry in pairs(espObjects[category]) do
            if entry.updated~=espIteration or not obj.Parent then
                if entry.highlight then pcall(function()entry.highlight:Destroy()end)end
                if entry.billboard then pcall(function()entry.billboard:Destroy()end)end
                espObjects[category][obj]=nil
            end
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
        task.wait(0.22)
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
        -- Destroy only the disabled category; other ESP switches stay on.
        local cat=key=="autoESP" and "spirits"
            or (key=="espPlayers" and "players" or "guardians")
        if value~=true then clearESPGroup(cat) end
        task.defer(function()if running then pcall(updateESP)end end)
    end
    if key=="autoSteal" and value~=true then
        runtime.phase="idle"
        runtime.target=nil
        runtime.escapeNeeded=false
        stopMovement()
    end
    if key=="lockControls" and value~=true then releaseControlLock()end
    task.defer(function()if running then pcall(applyControlLock)end end)
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
toggle(farmSteal,"PVSP_autoPlace","autoPlace","Depositar durante Auto Steal","Place during Auto Steal")
toggle(farmSteal,"PVSP_autoPlaceStandalone","autoPlaceStandalone",
    "Depositar automaticamente (sem farm)","Automatically place spirits (without farm)")
farmSteal:AddDropdown("PVSP_zone",{Text=words("Zona","Zone"),Values={
    "Auto","All","Zona 1","Zona 2","Zona 3","Zona 4","Zona 5",
    "Zona 6","Zona 7","Zona 8","Zona 9","Zona 10"},Default=cfg.zone,
    Callback=function(v)change("zone",v)end})
farmSteal:AddDropdown("PVSP_priority",{Text=words("Prioridade","Priority"),
    Values={"Rápido","Raridade","Renda","Distância"},Default=cfg.priority,
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
farmMovement:AddLabel(words("Blink: teleporte instantâneo sem espírito. Tween: voo contínuo por frames, rápido e configurável.",
    "Blink: instant teleport when not carrying. Tween: continuous frame-by-frame, fast, adjustable flight."),true)
toggle(farmProgress,"PVSP_autoTreadmill","autoTreadmill","Auto Esteira","Auto Treadmill")
farmMovement:AddSlider("PVSP_carryTweenSpeed",{
    Text=words("Velocidade de fuga com espírito","Carry escape speed"),
    Min=200,Max=2500,Rounding=0,Default=cfg.carryTweenSpeed,
    Callback=function(v)change("carryTweenSpeed",v)end
})
farmMovement:AddLabel(words(
    "Enquanto estiver carregando espírito, atravessa a FinishLine em Tween contínuo. Só volta a usar Blink após o servidor confirmar a captura.",
    "While carrying, crosses the FinishLine with continuous Tween. Blink resumes only after the server confirms the claim."),true)
toggle(farmMovement,"PVSP_lockControls","lockControls",
    "Bloquear movimento manual durante automação","Block manual movement during automation")
farmMovement:AddLabel(words(
    "Com Farm, Esteira ou Depósito ativos: bloqueia caminhada, pulo e teclas manuais; botões da interface continuam utilizáveis. Use Parar automações para liberar tudo.",
    "Farm, Treadmill or Auto Place: walking, jumping and manual keys are blocked; UI buttons remain usable. Use Stop automations to restore controls."),true)
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
    if desiredControlLock() then
        notify(W("Desative a automação antes de teleportar manualmente.",
            "Turn off automation before using manual teleports."))
        return
    end
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
    if desiredControlLock() then
        notify(W("Desative a automação antes de teleportar manualmente.",
            "Turn off automation before using manual teleports."))
        return
    end
    local idx=chosenZone:match("%d+")
    local folder=WS:FindFirstChild("Zones")
    local zone=folder and folder:FindFirstChild("Zone"..tostring(idx))
    local obj=zone and (zone:FindFirstChild("Floor") or zone:FindFirstChild("Bounds"))
    if obj then moveTo(obj.Position,4) else notify(W("Zona indisponível.","Zone unavailable."))end
end})
toggle(miscExtra,"PVSP_autoNoclip","autoNoclip","Noclip","Noclip")
toggle(miscExtra,"PVSP_antiAFK","antiAFK","Anti-AFK","Anti-AFK")
miscExtra:AddButton({Text=words("Parar movimento e automações","Stop movement and automations"),
    Func=function()
        for _,flag in ipairs({"autoSteal","autoPlaceStandalone","autoTreadmill"}) do
            if cfg[flag] then stopFeature(flag)end
        end
        stopMovement()
        releaseControlLock()
        runtime.phase="stopped_by_user"
    end})
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
    releaseControlLock()
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
    record("ReplicatedStorage.Placement",Placement~=nil,
        "Native findSpot="..tostring(Placement and type(Placement.findSpot)=="function"))
    record("Inventory.SpiritTools",true,
        "Tools with SpiritId+SpiritKey="..tostring(#securedTools()))
    record("Deposit.Status",true,
        "Attempts="..tostring(counters.PlaceAttempts)..
        "; Confirmed="..tostring(counters.Placed)..
        "; Busy="..tostring(runtime.placing==true)..
        "; LastError="..tostring(runtime.lastError))
    record("ReplicatedStorage.RewardsConfig",RewardsConfig~=nil,
        "Playtime milestones="..tostring(RewardsConfig and #RewardsConfig.Playtime or 0))
    local nSpirits,nPlayers,nGuardians=0,0,0
    for _ in pairs(espObjects.spirits) do nSpirits+=1 end
    for _ in pairs(espObjects.players) do nPlayers+=1 end
    for _ in pairs(espObjects.guardians) do nGuardians+=1 end
    record("ESP.Flags",true,"Spirits="..tostring(espIsOn("autoESP"))..
        "; Players="..tostring(espIsOn("espPlayers"))..
        "; Guardians="..tostring(espIsOn("espGuardians"))..
        " | Active overlays: "..nSpirits.."/"..nPlayers.."/"..nGuardians)
    record("Movement.Safety",true,
        "Mode="..cfg.mode.."; CarryTweenSpeed="..tostring(cfg.carryTweenSpeed)..
        "; LastError="..tostring(runtime.lastError))
    record("Farm.State",true,
        "Active="..tostring(cfg.autoSteal)..
        "; Phase="..tostring(runtime.phase)..
        "; Carrying="..tostring(carrying())..
        "; EscapePending="..tostring(runtime.escapeNeeded)..
        "; EscapeRetries="..tostring(runtime.escapeRetries)..
        "; LastEscapeAge="..tostring(math.floor(os.clock()-runtime.lastEscape))..
        "; SelectedTarget="..tostring(runtime.target and runtime.target.meta.id))
    record("Farm.FastPath",true,
        "Priority="..tostring(cfg.priority)..
        "; TotalTargets="..tostring(counters.Targets)..
        "; EscapeAttempts="..tostring(counters.EscapeAttempts)..
        "; EscapeConfirmed="..tostring(counters.EscapeConfirmed)..
        "; EscapeFailed="..tostring(counters.EscapeFailed))
    record("Carry.Claim",true,
        "Transitions="..tostring(runtime.carryTransitions)..
        "; StartAge="..tostring(math.floor(os.clock()-(runtime.carryStartedAt or 0)))..
        "; LastLossPhase="..tostring(runtime.carryLossPhase)..
        "; LastLossPosition="..tostring(runtime.carryLossPosition)..
        "; ServerClaims="..tostring(runtime.claimConfirmed)..
        "; LastCheck="..tostring(runtime.lastClaimCheck))
    record("Controls.Lock",true,
        "Desired="..tostring(desiredControlLock())..
        "; Active="..tostring(automationLock.active)..
        "; Owner="..tostring(runtime.lockOwner)..
        "; CAS="..tostring(automationLock.actionBound)..
        "; PlayerModule="..tostring(automationLock.controls~=nil)..
        "; Errors="..tostring(automationLock.errors))
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
