-- Prime Void Hub | Clover Legends: Devil Fusion | v0.1.0 TEST
-- PlaceId 109813591245812 | 4 initial features; no server-side fake success.
-- Built from the supplied place snapshot, not guessed remote names.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Workspace=game:GetService("Workspace")
local UIS=game:GetService("UserInputService")
local HttpService=game:GetService("HttpService")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local LocalPlayer=Players.LocalPlayer
local env=(type(getgenv)=="function" and getgenv()) or _G

if type(env.PVH_CloverUnload)=="function" then
    pcall(env.PVH_CloverUnload)
end
local alive=true
local connections={}
local Library
local SettingsPath="primevoid_hub/Clover_Legends/Configs/ui_settings.json"
local ProfileDir="primevoid_hub/Clover_Legends/Configs/Profiles"
local SpinBudgetPath="primevoid_hub/Clover_Legends/Configs/spin_budget.json"
local functionsEnabled={Level=false,Chest=false,Mine=false,Spin=false}
local counters={Kills=0,Chests=0,Ore=0,Spins=0,AttackAttempts=0,Hits=0,DirectAttackAttempts=0,ScanTrips=0}
local activeMove=nil
local hoverMob=nil
local hitboxAutoOwned=false
local hitboxSyncing=false
local spinResult=nil
local spinSequence=0
local statusText=nil
local labels={}
local groupHeaders={}
local statusLines={}
local buildVersion="v0.1.0 TEST"
local cfg={
    language="pt-BR",uiAnimations=true,uiSounds=false,showKeybinds=false,
    moveMode="Blink",flySpeed=360,
    farmRadius=12000,attackInterval=0.08,attackBurst=2,hoverHeight=5.5,useAutoQuest=true,
    hitboxExpander=false,hitboxSize=18,searchSpawns=true,
    chestRadius=12000,chestDelay=1.2,
    mineRadius=12000,mineDelay=1.65,oreType="Auto",
    spinMax=10,spinDelay=5,spinRarity="Legendary",
    minimizeKey="RightShift",unloadKey="Delete",
}
local rootDir="primevoid_hub/Clover_Legends/Configs"

local function track(signal)
    connections[#connections+1]=signal
    return signal
end

local function safeInfo(...)
    warn("[PVH CLOVER]",...)
end

local function ensureFolder(path)
    if type(makefolder)~="function" then return false end
    local p=""
    for name in string.gmatch(path,"[^/]+") do
        p=(p=="" and name or p.."/"..name)
        local exists=type(isfolder)=="function" and isfolder(p)
        if not exists then pcall(makefolder,p) end
    end
    return true
end

local function readJSON(path)
    if type(isfile)~="function" or type(readfile)~="function" then return nil end
    local ok,value=pcall(function()
        if not isfile(path) then return nil end
        return HttpService:JSONDecode(readfile(path))
    end)
    return ok and type(value)=="table" and value or nil
end

local function writeJSON(path,value)
    if type(writefile)~="function" then return false end
    local ok=pcall(function()
        writefile(path,HttpService:JSONEncode(value))
    end)
    return ok
end

local function autoSaveAllowed()
    local shared=env.PVH_Persistence
    return not (type(shared)=="table" and shared.AutoSave==false)
end

local saved=autoSaveAllowed() and readJSON(SettingsPath) or nil
if saved then
    if saved.language=="en-US" or saved.language=="pt-BR" then
        cfg.language=saved.language
    end
    for _,key in ipairs({"uiAnimations","uiSounds","showKeybinds","minimizeKey","unloadKey","moveMode","flySpeed"}) do
        if type(saved[key])==type(cfg[key]) then cfg[key]=saved[key] end
    end
    -- Migrate the previous test-only movement names without changing keys.
    if cfg.moveMode=="Teleport" then cfg.moveMode="Blink" end
    if cfg.moveMode=="Fly" then cfg.moveMode="Tween" end
    if cfg.moveMode~="Blink" and cfg.moveMode~="Tween" then cfg.moveMode="Blink" end
    if type(saved.useAutoQuest)=="boolean" then cfg.useAutoQuest=saved.useAutoQuest end
    if type(saved.manualHitbox)=="boolean" then cfg.hitboxExpander=saved.manualHitbox end
end

local function saveUi()
    if not alive or not autoSaveAllowed() then return end
    ensureFolder(rootDir)
    writeJSON(SettingsPath,{
        language=cfg.language,uiAnimations=cfg.uiAnimations,
        uiSounds=cfg.uiSounds,showKeybinds=cfg.showKeybinds,
        minimizeKey=cfg.minimizeKey,unloadKey=cfg.unloadKey,
        moveMode=cfg.moveMode,flySpeed=cfg.flySpeed,useAutoQuest=cfg.useAutoQuest,
        manualHitbox=cfg.hitboxExpander,tuningSchema=4,
    })
end

local function T(pt,en)
    return cfg.language=="en-US" and en or pt
end

-- Text pairs are directional; refreshes translate already displayed text too.
local localization={}
local function words(pt,en)
    localization[pt]={pt=pt,en=en}
    localization[en]={pt=pt,en=en}
    return T(pt,en)
end

local function registerHeader(group,pt,en)
    groupHeaders[#groupHeaders+1]={group=group,pt=pt,en=en}
    return group
end

local function translateUI()
    if not Library or not Library.ScreenGui then return end
    for _,entry in ipairs(groupHeaders) do
        local group=entry.group
        local name=T(entry.pt,entry.en)
        if type(group)=="table" then
            group.Name=name
            if typeof(group.Holder)=="Instance" then
                for _,node in ipairs(group.Holder:GetDescendants()) do
                    if node:IsA("TextLabel") and (node.Text==entry.pt or node.Text==entry.en) then
                        pcall(function()node.Text=name end)
                    end
                end
            end
        end
    end
    for _,obj in ipairs(Library.ScreenGui:GetDescendants()) do
        local property=nil
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then property="Text"
        elseif obj:IsA("TextBox") then property="PlaceholderText" end
        if property then
            local ok,text=pcall(function()return obj[property]end)
            local mapping=ok and localization[text] or nil
            if mapping then pcall(function()obj[property]=mapping[cfg.language=="en-US" and "en" or "pt"]end) end
        end
    end
    local current=statusLines.main
    if current then current:SetText(T("Port de testes ativo","Test port active").." | "..buildVersion) end
end

local function notify(pt,en)
    local msg=T(pt,en)
    if Library then
        pcall(function()
            Library:Notify({Title="Prime Void Hub",Description=msg,Time=4,Icon="info"})
        end)
    end
    safeInfo(msg)
end

local function updateStatus(section,pt,en)
    local value=T(pt,en)
    if section and statusLines[section] and type(statusLines[section].SetText)=="function" then
        pcall(function()statusLines[section]:SetText(value)end)
    end
end

local function humanoidRoot()
    local character=LocalPlayer.Character
    if not character then return nil,nil end
    local hum=character:FindFirstChildOfClass("Humanoid")
    local root=character:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health<=0 then return nil,nil end
    return hum,root
end

local function fire(event,...)
    if not alive or not event or not event:IsA("RemoteEvent") then return false end
    local ok,err=pcall(function(...)event:FireServer(...)end,...)
    if not ok then safeInfo("Remote failure",event.Name,err) end
    return ok
end

local remotes=ReplicatedStorage:WaitForChild("Remotes",15)
local function remote(name)
    if not remotes then return nil end
    local r=remotes:FindFirstChild(name)
    return r and r:IsA("RemoteEvent") and r or nil
end
local chestFolder=Workspace:FindFirstChild("WK_Chests")
local enemyFolder=Workspace:FindFirstChild("Enemies")
local oreFolder=Workspace:FindFirstChild("WK_OreNodes")
local shared=ReplicatedStorage:FindFirstChild("Shared")
local miningConfig
local grimoires
if shared and shared:FindFirstChild("Config") then
    local ok,cfgMine=pcall(function()return require(shared.Config:WaitForChild("Mining",3))end)
    if ok then miningConfig=cfgMine end
    local okBook,books=pcall(function()return require(shared.Config:WaitForChild("Grimoires",3))end)
    if okBook then grimoires=books end
end
-- Follow the live server quest instead of repeatedly killing the nearest
-- unrelated mob. Both QuestUpdated and ShowDialogue are confirmed in the
-- supplied client scripts.
local questDefinitions
if shared and shared:FindFirstChild("Config") then
    local okDefs,defs=pcall(function()
        return require(shared.Config:WaitForChild("Quests",3))
    end)
    if okDefs and type(defs)=="table" then questDefinitions=defs end
end
local questState={activeId=nil,auto=nil,targets={},lastRequest=0,lastOffer="",lastOfferAt=0}
local function normalizedMob(value)
    if type(value)~="string" then return "" end
    return value:lower():gsub("[^%w]","")
end
local function matchesQuestMob(npc)
    local targets=questState.targets
    if not targets or not next(targets) then return false end
    for _,key in ipairs({"WK_MobId","WK_EnemyId","EnemyId","MobId","NpcId"}) do
        local v=npc:GetAttribute(key)
        if v and targets[normalizedMob(tostring(v))] then return true end
    end
    local mobName=normalizedMob(npc.Name)
    for key in pairs(targets) do
        if key~="" and (mobName==key or mobName:find(key,1,true)) then return true end
    end
    return false
end
local function updateQuest(data,authoritative)
    if type(data)~="table" then return end
    if type(data.AutoQuest)=="boolean" then questState.auto=data.AutoQuest end
    if authoritative or data.ActiveQuestId or data.ActiveSideQuestId then
        local id=data.ActiveQuestId or data.ActiveSideQuestId
        if id~=questState.activeId or authoritative then
            questState.activeId=id
            local targets={}
            local def=questDefinitions and id and questDefinitions[id]
            local progress=data.ActiveQuestId and data.Progress or data.SideProgress
            if type(def)=="table" then
                for index,objective in ipairs(def.Objectives or {}) do
                    if objective.Type=="Kill" and type(objective.Target)=="string" then
                        local completed=type(progress)=="table"
                            and type(progress.Counts)=="table"
                            and (tonumber(progress.Counts[index]) or 0)
                            or 0
                        if completed<(tonumber(objective.Count) or 1) then
                            targets[normalizedMob(objective.Target)]=true
                        end
                    end
                end
            end
            questState.targets=targets
        end
    end
end
for _,eventName in ipairs({"QuestUpdated","StateChanged"}) do
    local event=remote(eventName)
    if event then
        local full=eventName=="QuestUpdated"
        track(event.OnClientEvent:Connect(function(data)
            updateQuest(data,full)
        end))
    end
end
local function setAutoQuest(on)
    local now=os.clock()
    if on and now-questState.lastRequest<2.0 then return false end
    local sent=fire(remote("SetAutoQuest"),on==true)
    if sent then
        questState.lastRequest=now
        if not on then questState.auto=false end
    end
    return sent
end
local dialogueEvent=remote("ShowDialogue")
if dialogueEvent then
    track(dialogueEvent.OnClientEvent:Connect(function(data)
        if not functionsEnabled.Level or not cfg.useAutoQuest
            or type(data)~="table" or data.Locked==true
            or type(data.OffersQuestId)~="string" then return end
        local id=data.OffersQuestId
        if questState.lastOffer==id and
            os.clock()-questState.lastOfferAt<2.5 then return end
        if fire(remote("AcceptQuest"),id) then
            questState.lastOffer=id
            questState.lastOfferAt=os.clock()
            safeInfo("Accepted server-offered quest",id)
        end
    end))
end

local inputController
local function getInputController()
    if type(inputController)=="table" and inputController.OnBasicAttack then return inputController end
    local scripts=LocalPlayer:FindFirstChild("PlayerScripts")
    local client=scripts and scripts:FindFirstChild("Client")
    local controllers=client and client:FindFirstChild("Controllers")
    local module=controllers and controllers:FindFirstChild("InputController")
    if not module then return nil end
    local ok,result=pcall(require,module)
    if ok and type(result)=="table" then inputController=result return result end
    return nil
end

-- Decompiled MeleeClient.Handle("M1", CFrame) issues
-- Remotes.BasicAttack:FireServer(CFrame). The old OnBasicAttack:Fire()
-- was only a local input signal; it could succeed without damaging a mob.
local meleeClient
local lastMeleeLookup=0
local function getMeleeClient()
    if type(meleeClient)=="table" and type(meleeClient.Handle)=="function" then
        return meleeClient
    end
    if os.clock()-lastMeleeLookup<1 then return nil end
    lastMeleeLookup=os.clock()
    local scripts=LocalPlayer:FindFirstChild("PlayerScripts")
    if not scripts then return nil end
    local client=scripts:FindFirstChild("Client")
    local module=client and client:FindFirstChild("MeleeClient",true)
    if not module then module=scripts:FindFirstChild("MeleeClient",true) end
    if not module or not module:IsA("ModuleScript") then return nil end
    local ok,value=pcall(require,module)
    if ok and type(value)=="table" and type(value.Handle)=="function" then
        meleeClient=value
        return meleeClient
    end
    return nil
end
local attackState={mob=nil,attempts=0,lastDamage=0,lastHP=nil,lastMode="none"}
local function basicAttack(enemyRoot,preferDirect)
    local _,root=humanoidRoot()
    if not root or not enemyRoot then return false,"no_target" end
    -- Directly aim at the mob in 3D, including the downward angle while hovering.
    local target=enemyRoot.Position
    local aim
    if (target-root.Position).Magnitude<0.1 then
        aim=root.CFrame
    else
        aim=CFrame.lookAt(root.Position,target)
    end
    local event=remote("BasicAttack")
    local melee=getMeleeClient()
    local noDamage=attackState.attempts>=5
        and (os.clock()-attackState.lastDamage)>0.75
    -- The second hit in a rapid burst goes straight to the known remote:
    -- local MeleeClient animation locks need not block the next request.
    -- The server remains authoritative over attack rate, range and damage.
    if (preferDirect or noDamage) and event and fire(event,aim) then
        counters.AttackAttempts+=1
        counters.DirectAttackAttempts+=1
        attackState.lastMode="BasicAttack remote"
        return true,"BasicAttack remote"
    end
    if melee and not noDamage then
        local ok,err=pcall(melee.Handle,"M1",aim)
        if ok then
            counters.AttackAttempts+=1
            attackState.lastMode="MeleeClient"
            return true,"MeleeClient"
        end
        safeInfo("MeleeClient.Handle failed",tostring(err))
    end
    if event and fire(event,aim) then
        counters.AttackAttempts+=1
        counters.DirectAttackAttempts+=1
        attackState.lastMode="BasicAttack remote"
        return true,"BasicAttack remote"
    end
    return false,"missing_MeleeClient_and_BasicAttack"
end

-- Client-side hitbox expansion only. No server collision or remote damage
-- values are altered. Keep originals for exact restoration on disable/unload.
local originalHitboxes=setmetatable({},{__mode="k"})
local function restoreHitboxes()
    for part,original in pairs(originalHitboxes) do
        if part and part.Parent then
            pcall(function()
                part.Size=original.Size
                part.Transparency=original.Transparency
                part.LocalTransparencyModifier=original.LocalTransparencyModifier
                part.CanCollide=original.CanCollide
                part.CanQuery=original.CanQuery
                part.Massless=original.Massless
            end)
        end
        originalHitboxes[part]=nil
    end
end
local function expandHitbox(npc)
    if not (cfg.hitboxExpander or functionsEnabled.Level) or not npc or not npc:IsA("Model") then return end
    local human=npc:FindFirstChildOfClass("Humanoid")
    local part=npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
    if not human or human.Health<=0 or not part or not part:IsA("BasePart") then return end
    if not originalHitboxes[part] then
        originalHitboxes[part]={
            Size=part.Size,Transparency=part.Transparency,
            LocalTransparencyModifier=part.LocalTransparencyModifier,
            CanCollide=part.CanCollide,CanQuery=part.CanQuery,
            Massless=part.Massless,
        }
    end
    local length=math.clamp(tonumber(cfg.hitboxSize) or 18,8,40)
    pcall(function()
        part.Size=Vector3.new(length,length,length)
        part.Transparency=1
        part.LocalTransparencyModifier=1
        part.CanCollide=false
        part.CanQuery=true
        part.Massless=true
    end)
end

local function candidateEnemies()
    enemyFolder=Workspace:FindFirstChild("Enemies") or enemyFolder
    if not enemyFolder then return {} end
    local found,seen={},{}
    for _,instance in ipairs(enemyFolder:GetDescendants()) do
        if instance:IsA("Humanoid") then
            local model=instance.Parent
            if model and model:IsA("Model") and not seen[model] then
                seen[model]=true
                found[#found+1]=model
            end
        end
    end
    return found
end

task.spawn(function()
    while alive do
        if cfg.hitboxExpander or functionsEnabled.Level then
            for _,npc in ipairs(candidateEnemies()) do expandHitbox(npc) end
        elseif next(originalHitboxes) then
            restoreHitboxes()
        end
        task.wait(0.65)
    end
    restoreHitboxes()
end)


local function isAllowed(owner)
    return alive and functionsEnabled[owner]==true
end

-- Fast script-style movement, never vanilla Humanoid:MoveTo.
-- Standard PV Hub modes: Blink (instant) and Tween (fast airborne glide).
-- No vanilla MoveTo or pathfinding.
local function stopMovement()
    local move=activeMove
    if not move then return end
    move.cancelled=true
    if move.tween then pcall(function()move.tween:Cancel()end) end
    if move.root and move.root.Parent then
        pcall(function()
            if move.anchoredBefore~=nil then
                move.root.Anchored=move.anchoredBefore
                move.root.CanCollide=move.collideBefore
            end
        end)
    end
    if activeMove==move then activeMove=nil end
end

local movementFailures={}
local function moveNear(owner,target,reach,timeout)
    if not isAllowed(owner) or typeof(target)~="Vector3" then return false end
    local hum,root=humanoidRoot()
    if not hum or root.Anchored then return false end
    if activeMove then return false end
    local distance=(root.Position-target).Magnitude
    local hoverLanding=owner=="Level" and (target+Vector3.new(0,math.clamp(tonumber(cfg.hoverHeight) or 5.5,4,8),0)) or nil
    if owner=="Level" then
        if (root.Position-hoverLanding).Magnitude<=0.9 then return true end
    elseif distance<=reach then return true end
    local since=movementFailures[owner]
    if type(since)=="number" and os.clock()-since<0.25 then return false end

    -- Land slightly beside/above the interactable: within attack, mine, and
    -- prompt range, instead of occupying the exact same CFrame as the target.
    local toward=root.Position-target
    local horizontal=Vector3.new(toward.X,0,toward.Z)
    if horizontal.Magnitude<0.01 then
        local look=root.CFrame.LookVector
        horizontal=Vector3.new(look.X,0,look.Z)
    end
    if horizontal.Magnitude<0.01 then horizontal=Vector3.new(1,0,0) end
    local offset=math.min(math.max(reach*0.42,1),4.5)
    local height=math.min(math.max(reach*0.24,0.5),2.2)
    local landing=hoverLanding or (target+horizontal.Unit*offset+Vector3.new(0,height,0))
    local face=owner=="Level" and (landing+horizontal.Unit) or Vector3.new(target.X,landing.Y,target.Z)
    local destination=CFrame.lookAt(landing,face)
    local mode=cfg.moveMode=="Tween" and "Tween" or "Blink"
    local move={owner=owner,root=root,cancelled=false}
    activeMove=move
    local ok,err=pcall(function()
        if mode=="Tween" then
            -- Temporary anchoring prevents gravity from turning a flight tween
            -- into a walk/fall. Restored on completion, stop, death and unload.
            move.anchoredBefore=root.Anchored
            move.collideBefore=root.CanCollide
            root.Anchored=true
            root.CanCollide=false
            local speed=math.clamp(tonumber(cfg.flySpeed) or 360,100,1000)
            local seconds=math.clamp((root.Position-landing).Magnitude/speed,0.06,6)
            move.tween=TweenService:Create(root,
                TweenInfo.new(seconds,Enum.EasingStyle.Linear),{CFrame=destination})
            move.tween:Play()
            local deadline=os.clock()+seconds+0.6
            while alive and not move.cancelled and isAllowed(owner)
                and root.Parent and os.clock()<deadline
                and move.tween.PlaybackState==Enum.PlaybackState.Playing do
                task.wait(0.04)
            end
        else
            -- Immediate CFrame teleport, not Tween/MoveTo/vanilla navigation.
            root.CFrame=destination
            task.wait(0.05)
        end
    end)
    local cancelled=move.cancelled
    stopMovement() -- also restores the anchored/collision state after flight
    if not ok then
        movementFailures[owner]=os.clock()
        safeInfo("Movement failed",owner,err)
        return false
    end
    if cancelled or not isAllowed(owner) then return false end
    local _,after=humanoidRoot()
    local verified=after and ((owner=="Level" and (after.Position-landing).Magnitude<=1.8)
        or (owner~="Level" and (after.Position-target).Magnitude<=reach))
    if not verified then
        movementFailures[owner]=os.clock()
        safeInfo("Movement correction or range failure",owner,mode)
        return false
    end
    return true
end

local function turnTo(target)
    local _,root=humanoidRoot()
    if not root or typeof(target)~="Vector3" then return end
    local flat=Vector3.new(target.X,root.Position.Y,target.Z)
    if (flat-root.Position).Magnitude>0.3 then
        pcall(function()root.CFrame=CFrame.lookAt(root.Position,flat)end)
    end
end

-- Maintain a real airborne position over the current enemy. No walking
-- and no invisible platform: released immediately when farm/movement stops.
track(RunService.Heartbeat:Connect(function()
    if not alive or not functionsEnabled.Level or activeMove or not hoverMob then return end
    local _,root=humanoidRoot()
    local enemyHum=hoverMob.Parent and hoverMob:FindFirstChildOfClass("Humanoid")
    local enemyRoot=hoverMob.Parent and
        (hoverMob:FindFirstChild("HumanoidRootPart") or hoverMob.PrimaryPart)
    if not root or not enemyHum or enemyHum.Health<=0 or not enemyRoot then
        hoverMob=nil
        return
    end
    local desired=enemyRoot.Position+Vector3.new(0,math.clamp(tonumber(cfg.hoverHeight) or 5.5,4,8),0)
    if (root.Position-desired).Magnitude>10 then
        hoverMob=nil -- MoveNear will reacquire it via Tween/Blink.
        return
    end
    local face=root.CFrame.LookVector
    local forward=Vector3.new(face.X,0,face.Z)
    if forward.Magnitude<0.01 then forward=Vector3.new(0,0,-1) end
    pcall(function()
        root.AssemblyLinearVelocity=Vector3.zero
        root.AssemblyAngularVelocity=Vector3.zero
        root.CFrame=CFrame.lookAt(desired,desired+forward.Unit)
    end)
end))

local function getLevel(object)
    if not object then return nil end
    for _,key in ipairs({"Level","WK_Level","EnemyLevel","MobLevel"}) do
        local value=object:GetAttribute(key)
        if type(value)=="number" then return value end
        local child=object:FindFirstChild(key)
        if child and child:IsA("NumberValue") then return child.Value end
    end
    return tonumber(object.Name:match("[Ll][Vv]%.?%s*(%d+)"))
end

local function playerLevel()
    local level=getLevel(LocalPlayer)
    if level then return level end
    for _,key in ipairs({"leaderstats","Stats","Data"}) do
        local node=LocalPlayer:FindFirstChild(key)
        if node then
            local child=node:FindFirstChild("Level") or node:FindFirstChild("WK_Level")
            if child and (child:IsA("IntValue") or child:IsA("NumberValue")) then
                return child.Value
            end
        end
    end
    return nil
end

-- Source-backed map anchors: the supplied place contains folder hierarchies
-- MobSpawns, BossSpawns, Chests and MiningSpawns. Scan these even when distant
-- enemies themselves are unavailable because Workspace is streamed.
-- These coordinates were decoded from the CFrame properties of actual
-- MobSpawns/Chests/MiningSpawns parts in the user's supplied .rbxl snapshot.
-- They remain available even if Workspace streaming hides distant models.
local staticSpawnAnchors={
    Level={
        Vector3.new(-941.6,25.1,1603.5),Vector3.new(-928.1,24.6,1647.6),
        Vector3.new(-963.3,24.6,1626.9),Vector3.new(-547.6,22.4,1362.9),
        Vector3.new(-605.7,22.4,1416.2),Vector3.new(-660.6,22.2,1333.6),
        Vector3.new(-678.9,21.5,1437.0),Vector3.new(-747.4,21.9,1266.8),
        Vector3.new(-621.2,22.1,1215.6),Vector3.new(-696.4,22.3,1177.2),
        Vector3.new(16.9,39.4,1189.5),Vector3.new(62.3,40.0,1252.0),
        Vector3.new(17.6,39.4,1245.9),Vector3.new(67.6,39.0,1196.1),
    },
    Chest={
        Vector3.new(-425.0,39.0,1474.4),Vector3.new(-392.9,50.5,1789.6),
        Vector3.new(-690.8,21.6,1454.5),Vector3.new(-236.8,22.0,1245.9),
        Vector3.new(119.0,22.0,1186.0),Vector3.new(-756.8,22.0,1472.8),
        Vector3.new(-740.9,21.4,1603.9),Vector3.new(-978.5,125.4,1068.0),
        Vector3.new(-979.2,22.4,1255.1),
    },
    Mine={
        Vector3.new(-769.6,22.0,1426.2),Vector3.new(-59.5,22.5,1315.5),
        Vector3.new(-526.5,22.0,1043.0),Vector3.new(-924.0,22.5,1236.8),
        Vector3.new(-907.5,21.8,1309.0),Vector3.new(155.1,21.9,1107.7),
        Vector3.new(-1015.5,72.9,1336.5),Vector3.new(138.5,22.0,1386.5),
        Vector3.new(-1023.8,24.5,1702.6),
    },
}
local spawnAnchors={
    Level=table.clone(staticSpawnAnchors.Level),
    Chest=table.clone(staticSpawnAnchors.Chest),
    Mine=table.clone(staticSpawnAnchors.Mine),
}
local scoutIndex={Level=0,Chest=0,Mine=0}
local scoutLast={Level=0,Chest=0,Mine=0}
local scanBusy=false
local lastAnchorScan=0

local function anchorTypes(part)
    if not part:IsA("BasePart") then return nil end
    local current=part
    for _=1,7 do
        if not current or current==Workspace then break end
        local name=current.Name:lower():gsub("[^a-z]","")
        if name=="mobspawns" or name=="bossspawns"
            or name=="islandmob" or name=="islandmobeasy" or name=="islandboss"
            or name=="mobspawnpoint" or name=="questspawns" then return "Level" end
        if name=="chests" or name=="chestspawns" or name=="chestspawn"
            or name=="islandchest" then return "Chest" end
        if name=="miningspawns" or name=="orespawns"
            or name=="minersspawns" then return "Mine" end
        current=current.Parent
    end
    return nil
end

local function rebuildAnchorIndex()
    if scanBusy or os.clock()-lastAnchorScan<9 then return end
    lastAnchorScan=os.clock()
    scanBusy=true
    task.spawn(function()
        local found={
            Level=table.clone(staticSpawnAnchors.Level),
            Chest=table.clone(staticSpawnAnchors.Chest),
            Mine=table.clone(staticSpawnAnchors.Mine),
        }
        local cells={Level={},Chest={},Mine={}}
        for owner,points in pairs(found) do
            for _,p in ipairs(points) do
                cells[owner][math.floor(p.X/65)..":"..math.floor(p.Z/65)]=true
            end
        end
        local map=Workspace:FindFirstChild("Map") or Workspace
        local ok,descendants=pcall(function()return map:GetDescendants()end)
        if ok then
            for i,obj in ipairs(descendants) do
                if obj:IsA("BasePart") then
                    local mode=anchorTypes(obj)
                    local target=mode and found[mode]
                    if target and #target<200 then
                        local p=obj.Position
                        if math.abs(p.X)<100000 and math.abs(p.Y)<100000
                            and math.abs(p.Z)<100000 then
                            local cell=math.floor(p.X/65)..":"..math.floor(p.Z/65)
                            if not cells[mode][cell] then
                                cells[mode][cell]=true
                                target[#target+1]=p
                            end
                        end
                    end
                end
                if i%1300==0 then task.wait() end
            end
            spawnAnchors=found
        end
        scanBusy=false
    end)
end

local function scoutArea(owner)
    if not isAllowed(owner) or not cfg.searchSpawns or activeMove then
        return false
    end
    local now=os.clock()
    if now-scoutLast[owner]<1.15 then return false end
    scoutLast[owner]=now
    rebuildAnchorIndex()
    local points=spawnAnchors[owner]
    if type(points)~="table" or #points==0 then return false end
    local _,root=humanoidRoot()
    if not root then return false end
    local candidates={}
    local ownerRadius=owner=="Level" and cfg.farmRadius
        or owner=="Chest" and cfg.chestRadius or cfg.mineRadius
    for _,pos in ipairs(points) do
        if (root.Position-pos).Magnitude<=ownerRadius then
            candidates[#candidates+1]=pos
        end
    end
    if #candidates==0 then candidates=points end
    scoutIndex[owner]=(scoutIndex[owner]%#candidates)+1
    local pos=candidates[scoutIndex[owner]]
    if (root.Position-pos).Magnitude<28 and #candidates>1 then
        scoutIndex[owner]=(scoutIndex[owner]%#candidates)+1
        pos=candidates[scoutIndex[owner]]
    end
    if (root.Position-pos).Magnitude>28 then
        if not moveNear(owner,pos,6,7) then return false end
        counters.ScanTrips+=1
    end
    task.spawn(function()
        pcall(function()LocalPlayer:RequestStreamAroundAsync(pos)end)
    end)
    task.wait(0.16)
    return true
end

local focusedEnemy=nil
local trackedDied=setmetatable({},{__mode="k"})
local trackedHP=setmetatable({},{__mode="k"})
local hitStamp=0

local function pickEnemy()
    enemyFolder=Workspace:FindFirstChild("Enemies") or enemyFolder
    local _,root=humanoidRoot()
    if not enemyFolder or not root then return nil end
    local level=playerLevel()
    local best,bestScore
    for _,npc in ipairs(candidateEnemies()) do
        if npc:IsA("Model") then
            local hum=npc:FindFirstChildOfClass("Humanoid")
            local pivot=npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
            if hum and pivot and hum.Health>0 and npc~=LocalPlayer.Character then
                local dist=(root.Position-pivot.Position).Magnitude
                local npcLevel=getLevel(npc)
                local tooStrong=level and npcLevel and npcLevel>level+6
                if not tooStrong and dist<=cfg.farmRadius then
                    -- Active-quest mobs outrank closer irrelevant mobs.
                    local wanted=matchesQuestMob(npc)
                    local score=dist+(npcLevel and level and math.abs(level-npcLevel)*0.9 or 0)
                    if wanted then score-=10000 end
                    if not best or score<bestScore then
                        best,bestScore=npc,score
                    end
                end
            end
        end
    end
    return best
end

local function farmStep()
    if cfg.useAutoQuest and questState.auto~=true then setAutoQuest(true) end
    local mob=focusedEnemy
    local hum,root=humanoidRoot()
    if mob then
        local enemyHum=mob:FindFirstChildOfClass("Humanoid")
        local enemyRoot=mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
        if not hum or not root or not enemyHum or enemyHum.Health<=0 or not enemyRoot
            or (enemyRoot.Position-root.Position).Magnitude>cfg.farmRadius+25
            or (next(questState.targets) and not matchesQuestMob(mob)) then
            mob=nil
            focusedEnemy=nil
            hoverMob=nil
        end
    end
    if not mob then
        mob=pickEnemy()
        focusedEnemy=mob
        hoverMob=nil
    end
    if not mob then
        updateStatus("Level","Buscando inimigos em outros spawns.",
            "Scanning other enemy spawn regions.")
        scoutArea("Level")
        task.wait(0.12)
        return
    end
    local enemyHum=mob:FindFirstChildOfClass("Humanoid")
    local enemyRoot=mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
    if not enemyHum or not enemyRoot or enemyHum.Health<=0 then
        focusedEnemy=nil
        return
    end
    if not trackedDied[mob] then
        trackedDied[mob]=true
        track(enemyHum.Died:Connect(function()
            counters.Kills+=1
            if focusedEnemy==mob then focusedEnemy=nil end
        end))
    end
    if not trackedHP[mob] then
        trackedHP[mob]=true
        local lastHP=enemyHum.Health
        track(enemyHum.HealthChanged:Connect(function(health)
            if health<lastHP then
                counters.Hits+=1
                attackState.lastDamage=os.clock()
                attackState.attempts=0
            end
            lastHP=health
        end))
    end
    if attackState.mob~=mob then
        attackState.mob=mob
        attackState.attempts=0
        attackState.lastDamage=os.clock()
    end
    local close=moveNear("Level",enemyRoot.Position,4.2,5)
    if not close then
        task.wait(0.08)
        return
    end
    local _,nearRoot=humanoidRoot()
    if not nearRoot or (nearRoot.Position-enemyRoot.Position).Magnitude>9 then return end
    hoverMob=mob -- heartbeat holds the overhead position during combat
    turnTo(enemyRoot.Position)
    if os.clock()-hitStamp>=cfg.attackInterval then
        local burst=math.clamp(math.floor(tonumber(cfg.attackBurst) or 2),1,4)
        -- If the server shows no HP change despite attempts, avoid needless
        -- remote spam and switch to single hits until damage is observed.
        local ineffective=attackState.attempts>=14
            and os.clock()-attackState.lastDamage>1.8
        if ineffective then burst=1 end
        local latestMode="none"
        local sentAny=false
        for i=1,burst do
            if not isAllowed("Level") or enemyHum.Health<=0 then break end
            local sent,via=basicAttack(enemyRoot,i>1)
            if sent then
                sentAny=true
                latestMode=via
                attackState.attempts+=1
            end
            if i<burst then task.wait(0.025) end
        end
        if sentAny then
            hitStamp=os.clock()
            updateStatus("Level",
                "Atacando por cima: "..mob.Name..
                    " | Quedas de HP: "..tostring(counters.Hits)..
                    " | Modo: "..tostring(latestMode),
                "Attacking from above: "..mob.Name..
                    " | HP drops: "..tostring(counters.Hits)..
                    " | Mode: "..tostring(latestMode))
        else
            updateStatus("Level","Falha ao iniciar ataque físico.",
                "Could not issue physical attack.")
        end
    end
    task.wait(math.clamp(cfg.attackInterval*0.3,0.025,0.08))
end

end

-- Count real chest confirmations; firing a prompt helper successfully is
-- NOT proof that the server granted the chest.
local chestVisits=setmetatable({},{__mode="k"})
local chestRewardSeq=0
local rewardEvent=remote("ChestEarned")
if rewardEvent then
    track(rewardEvent.OnClientEvent:Connect(function()
        chestRewardSeq+=1
    end))
end

local function getPosition(obj)
    if not obj then return nil end
    if obj:IsA("Attachment") then return obj.WorldPosition end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local part=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart",true)
        return part and part.Position or nil
    end
    if obj:IsA("ProximityPrompt") then return getPosition(obj.Parent) end
    if obj.Parent then return getPosition(obj.Parent) end
    return nil
end

local function selectChest()
    chestFolder=Workspace:FindFirstChild("WK_Chests") or chestFolder
    local _,root=humanoidRoot()
    if not root or not chestFolder then return nil end
    local best,bestDistance=nil,math.huge
    for _,prompt in ipairs(chestFolder:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled
            and (not chestVisits[prompt] or os.clock()>chestVisits[prompt]) then
            local pos=getPosition(prompt)
            local dist=pos and (root.Position-pos).Magnitude or math.huge
            if dist<=cfg.chestRadius and dist<bestDistance then
                best,bestDistance=prompt,dist
            end
        end
    end
    return best
end

local function chestAck(prompt,before,seconds)
    local deadline=os.clock()+seconds
    while isAllowed("Chest") and os.clock()<deadline do
        if chestRewardSeq>before then return true,"reward" end
        if not prompt.Parent or not prompt.Enabled then return true,"consumed" end
        task.wait(0.06)
    end
    return false,nil
end

local function triggerChest(prompt,before)
    if not prompt or not prompt.Parent then return false,nil end
    -- Keep the prompt visible to the local client even when the chest mesh
    -- blocks the camera ray; server-side acceptance still applies.
    local originalLOS=prompt.RequiresLineOfSight
    pcall(function()prompt.RequiresLineOfSight=false end)
    local ok=false
    local method
    if type(fireproximityprompt)=="function" then
        local success,returned=pcall(fireproximityprompt,prompt)
        ok=success and returned~=false
        if ok then method="executor" end
    end
    local accepted,signal=chestAck(prompt,before,0.45)
    if not accepted and isAllowed("Chest") then
        -- Native ProximityPrompt hold sequence: works with longer HoldDuration
        -- and is required by some custom prompts where fireproximityprompt()
        -- returns successfully but triggers no server interaction.
        local began=pcall(function()prompt:InputHoldBegin()end)
        if began then
            method="native_hold"
            local hold=math.clamp((tonumber(prompt.HoldDuration) or 0)+0.12,0.12,2.8)
            local endAt=os.clock()+hold
            while isAllowed("Chest") and os.clock()<endAt do
                if chestRewardSeq>before or not prompt.Parent or not prompt.Enabled then break end
                task.wait(0.05)
            end
            pcall(function()prompt:InputHoldEnd()end)
            ok=true
        end
        accepted,signal=chestAck(prompt,before,1.0)
    end
    pcall(function()if prompt.Parent then prompt.RequiresLineOfSight=originalLOS end end)
    return accepted,signal or method
end

local function chestStep()
    local prompt=selectChest()
    if not prompt then
        updateStatus("Chest","Buscando baús em outros spawns.",
            "Scanning other chest regions.")
        scoutArea("Chest")
        task.wait(0.12)
        return
    end
    local pos=getPosition(prompt)
    local maxRange=tonumber(prompt.MaxActivationDistance) or 7
    local radius=math.max(1.1,math.min(3.2,maxRange-0.65))
    if not pos or not moveNear("Chest",pos,radius,5) then
        chestVisits[prompt]=os.clock()+1.2
        return
    end
    if not prompt.Parent or not prompt.Enabled then return end
    local _,root=humanoidRoot()
    if not root or (root.Position-pos).Magnitude>=maxRange then
        chestVisits[prompt]=os.clock()+1.0
        return
    end
    local before=chestRewardSeq
    local confirmed,via=triggerChest(prompt,before)
    if confirmed then
        chestVisits[prompt]=os.clock()+45
        counters.Chests+=1
        updateStatus("Chest",
            "Baú confirmado: "..tostring(counters.Chests),
            "Chest confirmed: "..tostring(counters.Chests))
        task.wait(cfg.chestDelay)
    else
        chestVisits[prompt]=os.clock()+2.2
        updateStatus("Chest","Baú não respondeu; tentando outro.",
            "Chest did not respond; trying another.")
        safeInfo("Chest unconfirmed",tostring(prompt:GetFullName()),
            "attempt",tostring(via or "none"))
        task.wait(0.15)
    end
end

local function pickOre()
    oreFolder=Workspace:FindFirstChild("WK_OreNodes") or oreFolder
    local _,root=humanoidRoot()
    if not oreFolder or not root then return nil end
    local best,bestDist=nil,math.huge
    for _,node in ipairs(oreFolder:GetChildren()) do
        if node:IsA("Model") and node:GetAttribute("WK_OreId") then
            local resource=node:GetAttribute("WK_OreResource") or "Iron"
            if cfg.oreType=="Auto" or cfg.oreType==resource then
                local pos=getPosition(node)
                local dist=pos and (pos-root.Position).Magnitude or math.huge
                if dist<bestDist and dist<=cfg.mineRadius then
                    best,bestDist=node,dist
                end
            end
        end
    end
    return best
end

local function mineStep()
    local node=pickOre()
    if not node then
        updateStatus("Mine","Buscando minério em outras regiões.",
            "Scanning other mining regions.")
        scoutArea("Mine")
        task.wait(0.2)
        return
    end
    local pos=getPosition(node)
    local reach=math.min(9,(miningConfig and miningConfig.StrikeReach or 12)-1)
    if not pos or not moveNear("Mine",pos,reach,9) then return end
    local _,root=humanoidRoot()
    if not root then return end
    local character=LocalPlayer.Character
    if not character or character:GetAttribute("WK_PickaxeOut")==nil then
        -- Official LifeToolClient uses LifeToolAction("Use") to select its tool.
        if not fire(remote("LifeToolAction"),"Use") then
            updateStatus("Mine","Falha ao selecionar picareta.","Could not equip pickaxe.")
            return
        end
        task.wait(1)
        if not character or character:GetAttribute("WK_PickaxeOut")==nil then
            updateStatus("Mine","Equipe sua picareta na barra do jogo.",
                "Equip your pickaxe in the game hotbar.")
            task.wait(2)
            return
        end
    end
    turnTo(pos)
    local id=node:GetAttribute("WK_OreId")
    if id then
        local sent=fire(remote("MiningAction"),"Hit",id)
        fire(remote("MiningAction"),"Swing",root.CFrame.LookVector)
        if sent then
            counters.Ore+=1
            updateStatus("Mine","Golpes de mineração: "..tostring(counters.Ore),
                "Mining strikes sent: "..tostring(counters.Ore))
        end
    end
    task.wait(cfg.mineDelay)
end

local rarityRank={Common=1,Rare=2,Legendary=3,Mythical=4}
local function extractGrimoire(...)
    local args={...}
    local function probe(data,depth)
        if depth>3 then return nil end
        if type(data)=="string" then
            if rarityRank[data] then return nil,data end
            local found=grimoires and grimoires.Definitions and grimoires.Definitions[data]
            if found then return data,found.Rarity end
            return nil,nil
        end
        if type(data)~="table" then return nil,nil end
        for _,key in ipairs({"grimoireId","GrimoireId","BookId","bookId","Id","id","Result","result"}) do
            local v=data[key]
            local id,rarity=probe(v,depth+1)
            if id then return id,rarity end
        end
        local rarity=data.Rarity or data.rarity
        if type(rarity)=="string" and rarityRank[rarity] then
            return tostring(data.Name or data.name or "?"),rarity
        end
        for _,v in pairs(data) do
            local id,ra=probe(v,depth+1)
            if id or ra then return id,ra end
        end
        return nil,nil
    end
    for _,v in ipairs(args) do
        local id,rarity=probe(v,0)
        if id or rarity then return id,rarity end
    end
    return nil,nil
end

local rolled=remote("GrimoireRolled")
if rolled then
    track(rolled.OnClientEvent:Connect(function(...)
        spinSequence+=1
        local id,rarity=extractGrimoire(...)
        spinResult={id=id,rarity=rarity}
        if functionsEnabled.Spin then
            updateStatus("Spin",
                "Último livro: "..tostring(id or "?").." / "..tostring(rarity or "?"),
                "Latest book: "..tostring(id or "?").." / "..tostring(rarity or "?"))
        end
    end))
end

local priorBudget=autoSaveAllowed() and readJSON(SpinBudgetPath) or nil
local currentSpinCount=(priorBudget and tonumber(priorBudget.count)) or 0
if currentSpinCount<0 or currentSpinCount>100000 then currentSpinCount=0 end
local function writeSpinBudget()
    if not autoSaveAllowed() then return end
    ensureFolder(rootDir)
    writeJSON(SpinBudgetPath,{schema=1,count=currentSpinCount})
end
local function stopSpin(pt,en)
    functionsEnabled.Spin=false
    local toggles=Library and Library.Toggles
    local toggle=toggles and toggles.PVCL_Spin
    if toggle and toggle.Value then
        pcall(function()toggle:SetValue(false)end)
    end
    updateStatus("Spin",pt,en)
end

local function spinStep()
    if not remote("ShopSpin") or not rolled then
        stopSpin("Remotes de giro indisponíveis.","Spin remotes are unavailable.")
        return
    end
    if currentSpinCount>=cfg.spinMax then
        stopSpin("Limite de giros atingido.","Spin limit reached.")
        return
    end
    local before=spinSequence
    spinResult=nil
    if not fire(remote("ShopSpin"),{Mode="Gems"}) then
        stopSpin("Falha ao solicitar giro.","Spin request failed.")
        return
    end
    currentSpinCount+=1
    writeSpinBudget()
    counters.Spins+=1
    updateStatus("Spin",
        "Giro solicitado "..tostring(currentSpinCount).."/"..tostring(cfg.spinMax)..
            " | Gems (160 por giro)",
        "Spin requested "..tostring(currentSpinCount).."/"..tostring(cfg.spinMax)..
            " | Gems (160 per spin)")
    local timeout=os.clock()+10
    while isAllowed("Spin") and os.clock()<timeout and spinSequence==before do
        task.wait(0.25)
    end
    if not isAllowed("Spin") then return end
    if spinSequence==before then
        stopSpin("Sem confirmação do servidor: giro interrompido.",
            "No server confirmation: spinning stopped.")
        return
    end
    local result=spinResult
    local rank=result and rarityRank[result.rarity] or nil
    if not rank then
        stopSpin("Raridade não identificada: giro interrompido.",
            "Unknown rarity: spinning stopped.")
        return
    end
    if cfg.spinRarity=="Any" or rank>=(rarityRank[cfg.spinRarity] or 3) then
        stopSpin("Parou no grimório "..tostring(result.id).." ("..tostring(result.rarity)..").",
            "Stopped on "..tostring(result.id).." ("..tostring(result.rarity)..").")
        return
    end
    task.wait(cfg.spinDelay)
end

local function worker(owner,step,interval)
    task.spawn(function()
        while alive do
            if functionsEnabled[owner] then
                local ok,err=pcall(step)
                if not ok then
                    safeInfo(owner,"loop error:",err)
                    updateStatus(owner,"Erro detectado (consulte F9).",
                        "Error detected (check F9).")
                    task.wait(2)
                end
            else
                task.wait(interval or 0.5)
            end
        end
    end)
end

worker("Level",farmStep,0.45)
worker("Chest",chestStep,0.7)
worker("Mine",mineStep,0.7)
worker("Spin",spinStep,0.6)

local function safeToggle(flag,on)
    functionsEnabled[flag]=on==true
    if flag=="Level" then
        focusedEnemy=nil
        hoverMob=nil
        local hitboxToggle=Library and Library.Toggles and Library.Toggles.PVCL_HitboxExpander
        if on then
            hitboxAutoOwned=not cfg.hitboxExpander
            if hitboxAutoOwned and hitboxToggle and not hitboxToggle.Value then
                hitboxSyncing=true
                pcall(function()hitboxToggle:SetValue(true)end)
                hitboxSyncing=false
            end
        elseif hitboxAutoOwned then
            hitboxAutoOwned=false
            if hitboxToggle and hitboxToggle.Value then
                hitboxSyncing=true
                pcall(function()hitboxToggle:SetValue(false)end)
                hitboxSyncing=false
            end
            if not cfg.hitboxExpander then restoreHitboxes() end
        end
        if cfg.useAutoQuest then
            if on then questState.lastRequest=-100 else questState.lastRequest=0 end
            setAutoQuest(on)
        end
    end
    if flag=="Spin" and on and not autoSaveAllowed() then
        currentSpinCount=0
    end
    if not on then
        if activeMove and activeMove.owner==flag then stopMovement() end
        updateStatus(flag,"Desativado.","Disabled.")
    elseif flag=="Spin" then
        notify("Os giros usam Gemas e têm limite configurável.",
            "Spins use Gems and have a configurable limit.")
    end
end

-- Read-only per-feature prerequisites for the shared PVH diagnostics TXT.
-- It does not trigger a farm, spend Gems, start a fight or teleport.
env.PVH_CloverDiagnostics=function()
    local list={}
    local input=getInputController()
    enemyFolder=Workspace:FindFirstChild("Enemies") or enemyFolder
    chestFolder=Workspace:FindFirstChild("WK_Chests") or chestFolder
    oreFolder=Workspace:FindFirstChild("WK_OreNodes") or oreFolder
    local _,playerRoot=humanoidRoot()
    local function record(id,ready,note)
        list[#list+1]={
            id=id,kind="Gameplay readiness",
            status=ready and "STRUCTURE_OK" or "UNVERIFIED",
            detail=note.."; gameplay effect not tested",
        }
    end
    local mobs=#candidateEnemies()
    local meleeReady=getMeleeClient()~=nil
    record("PVCL_Level",remote("BasicAttack")~=nil and mobs>0 and playerRoot~=nil,
        "Workspace streaming="..tostring(Workspace.StreamingEnabled)..
        "; spawn markers="..tostring(#spawnAnchors.Level)..
        "; scout trips="..tostring(counters.ScanTrips)..
        "; Loaded enemies="..mobs..
        "; MeleeClient="..tostring(meleeReady)..
        "; BasicAttack remote="..tostring(remote("BasicAttack")~=nil)..
        "; scan radius="..tostring(cfg.farmRadius)..
        "; hitbox expander="..tostring(cfg.hitboxExpander)..
        " size="..tostring(cfg.hitboxSize)..
        "; attacks attempted="..tostring(counters.AttackAttempts)..
        "; HP decreases observed="..tostring(counters.Hits)..
        "; direct remote attempts="..tostring(counters.DirectAttackAttempts))
    local chestCount=0
    if chestFolder then
        for _,p in ipairs(chestFolder:GetDescendants()) do
            if p:IsA("ProximityPrompt") and p.Enabled then chestCount+=1 end
        end
    end
    record("PVCL_Chest",chestCount>0 and rewardEvent~=nil,
        "Chests available="..chestCount..
        "; spawn markers="..tostring(#spawnAnchors.Chest)..
        "; executor prompt API="..tostring(type(fireproximityprompt)=="function")..
        "; native hold available=ProximityPrompt:InputHoldBegin"..
        "; ChestEarned confirmation="..tostring(rewardEvent~=nil)..
        "; confirmed chests="..tostring(counters.Chests))
    local oreCount=0
    if oreFolder then
        for _,obj in ipairs(oreFolder:GetChildren()) do
            if obj:IsA("Model") and obj:GetAttribute("WK_OreId") then oreCount+=1 end
        end
    end
    record("PVCL_Mine",oreCount>0 and remote("MiningAction")~=nil,
        "Ore nodes="..oreCount..
        "; MiningAction="..tostring(remote("MiningAction")~=nil)..
        "; pickaxe="..tostring(LocalPlayer.Character and
            LocalPlayer.Character:GetAttribute("WK_PickaxeOut")~=nil))
    record("PVCL_Spin",remote("ShopSpin")~=nil and rolled~=nil,
        "ShopSpin="..tostring(remote("ShopSpin")~=nil)..
        "; GrimoireRolled="..tostring(rolled~=nil)..
        "; Gems per spin=160; budget used="..tostring(currentSpinCount)..
        "/"..tostring(cfg.spinMax))
    return list
end
env.PVH_CloverCounters=function()return table.clone(counters)end

local libUrl="https://raw.githubusercontent.com/deividcomsono/Obsidian/82d402b5de7d8903915f1afe99b5b7e340e7cd28/Library.lua"
local okLib,lib=pcall(function()return loadstring(game:HttpGet(libUrl))()end)
if not okLib or type(lib)~="table" then
    error("[PVH CLOVER] Obsidian indisponível: "..tostring(lib),0)
end
Library=lib
env.Library=Library
env.Toggles=Library.Toggles
env.Options=Library.Options
Library.ShowCustomCursor=false
Library.ToggleKeybind=Enum.KeyCode.Unknown
local Window=Library:CreateWindow({
    Title="PV Hub - Clover Legends",
    Footer="Prime Void Hub | Clover Legends | "..buildVersion,
    Center=true,AutoShow=true,Resizable=true,
    Size=UDim2.fromOffset(680,535),MinSidebarWidth=185,
    EnableCompacting=true,SidebarCompactWidth=48,
    MobileButtonsSide="Right",NotifySide="Right",
    Animations={
        ToggleWindow=cfg.uiAnimations,TabSwitch=cfg.uiAnimations,
        Groupbox=false,Dropdown=cfg.uiAnimations,KeyPicker=cfg.uiAnimations,
    },
})
local tabs={
    Home=Window:AddTab(words("Início","Home"),"house"),
    Farm=Window:AddTab(words("Farm","Farm"),"pickaxe"),
    Config=Window:AddTab(words("Config.","Settings"),"settings"),
    Misc=Window:AddTab(words("Miscelânea","Misc"),"wrench"),
}
-- The original PVH left sidebar uses 18px icons; avoid cropping on mobile.
pcall(function()
    for _,entry in ipairs(Library.TabButtons) do
        local icon=entry.Icon
        if icon and icon:IsA("ImageLabel") then
            icon.SizeConstraint=Enum.SizeConstraint.RelativeXY
            icon.Size=UDim2.fromOffset(18,18)
            icon.Position=UDim2.new(0,0,0.5,-9)
            icon.AnchorPoint=Vector2.new(0,0)
            icon.ClipsDescendants=false
        end
    end
end)

local homeAccount=registerHeader(tabs.Home:AddGroupbox({
    Side="Left",Name=words("Conta","Account"),IconName="user-round",
}),"Conta","Account")
local homeStatus=registerHeader(tabs.Home:AddGroupbox({
    Side="Left",Name=words("Estado da sessão","Session status"),IconName="activity",
}),"Estado da sessão","Session status")
local homeGames=registerHeader(tabs.Home:AddGroupbox({
    Side="Right",Name=words("Ports disponíveis","Available ports"),IconName="gamepad-2",
}),"Ports disponíveis","Available ports")
local homeHelp=registerHeader(tabs.Home:AddGroupbox({
    Side="Right",Name=words("Suporte e comunidade","Support and community"),IconName="message-circle",
}),"Suporte e comunidade","Support and community")
homeAccount:AddLabel(LocalPlayer.DisplayName.." (@"..LocalPlayer.Name..")",true)
homeAccount:AddLabel("PlaceId: "..tostring(game.PlaceId),true)
homeAccount:AddLabel(words("Clover Legends: Devil Fusion","Clover Legends: Devil Fusion"),true)
statusLines.main=homeStatus:AddLabel(T("Port de testes ativo","Test port active").." | "..buildVersion,true)
homeStatus:AddLabel(words("Funções iniciais: Level, Baús, Mineração e Livros.",
    "Initial features: Level, Chests, Mining and Books."),true)
homeStatus:AddLabel(words("Todas as automações começam desligadas.",
    "All automations start disabled."),true)
homeGames:AddLabel("Ride Storm  •  HUNTRESS  •  Steal An Exu",true)
homeGames:AddLabel("Don't Splash  •  Destruction Simulator",true)
homeGames:AddLabel("Clover Legends: Devil Fusion  •  "..buildVersion,true)
homeHelp:AddButton({Text=words("Copiar Discord","Copy Discord"),Func=function()
    local fn=type(setclipboard)=="function" and setclipboard or nil
    if fn and pcall(fn,"https://discord.gg/PD3PeyG8aq") then
        notify("Link do Discord copiado.","Discord link copied.")
    else
        notify("Área de transferência indisponível.","Clipboard unavailable.")
    end
end})

local farmLevel=registerHeader(tabs.Farm:AddGroupbox({
    Side="Left",Name=words("Auto Farm Level","Auto Level Farm"),IconName="swords",
}),"Auto Farm Level","Auto Level Farm")
local farmMovement=registerHeader(tabs.Farm:AddGroupbox({
    Side="Left",Name=words("Deslocamento automático","Automatic movement"),
    IconName="move-3d",
}),"Deslocamento automático","Automatic movement")
farmMovement:AddDropdown("PVCL_MoveMode",{
    Text=words("Modo de deslocamento","Movement mode"),
    Values={"Tween","Blink"},Default=cfg.moveMode,
    Callback=function(value)
        if value~="Tween" and value~="Blink" then return end
        cfg.moveMode=value
        if activeMove then stopMovement() end
        saveUi()
    end,
})
farmMovement:AddSlider("PVCL_FlySpeed",{
    Text=words("Velocidade Tween (studs/s)","Tween speed (studs/s)"),
    Default=cfg.flySpeed,Min=100,Max=1000,Rounding=0,
    Callback=function(value)
        cfg.flySpeed=value
        saveUi()
    end,
})
farmMovement:AddSlider("PVCL_HoverHeight",{
    Text=words("Altura sobre o NPC (studs)","Height above NPC (studs)"),
    Default=cfg.hoverHeight,Min=4,Max=8,Rounding=1,
    Callback=function(value)cfg.hoverHeight=value end,
})
farmMovement:AddToggle("PVCL_ScanSpawns",{
    Text=words("Buscar outras áreas automaticamente","Auto search other regions"),
    Default=cfg.searchSpawns,
    Callback=function(on)cfg.searchSpawns=on==true end,
})
farmMovement:AddLabel(words(
    "Padrão: Blink. Busca spawns pelo mapa sem caminhada. Tween: deslocamento aéreo.",
    "Default: Blink. Scan map spawn points without walking. Tween: airborne movement."),true)


local farmChest=registerHeader(tabs.Farm:AddGroupbox({
    Side="Right",Name=words("Coletar baús","Collect chests"),IconName="package",
}),"Coletar baús","Collect chests")
local farmMining=registerHeader(tabs.Farm:AddGroupbox({
    Side="Left",Name=words("Mineração","Mining"),IconName="pickaxe",
}),"Mineração","Mining")
-- Keep the exact shared PV Hub order in the LEFT Farm column:
-- Auto Farm Level -> Tween/Blink movement -> Mining.
pcall(function()
    if farmLevel.BoxHolder then farmLevel.BoxHolder.LayoutOrder=10 end
    if farmMovement.BoxHolder then farmMovement.BoxHolder.LayoutOrder=11 end
    if farmMining.BoxHolder then farmMining.BoxHolder.LayoutOrder=12 end
end)
local farmSpin=registerHeader(tabs.Farm:AddGroupbox({
    Side="Right",Name=words("Girar livros","Spin spellbooks"),IconName="book-open",
}),"Girar livros","Spin spellbooks")

farmLevel:AddToggle("PVCL_Level",{Text=words("Auto Farm Level","Auto Level Farm"),
    Default=false,Callback=function(on)safeToggle("Level",on)end})
farmLevel:AddToggle("PVCL_AutoQuest",{Text=words("Missão automática do jogo","Game auto-quest"),
    Default=cfg.useAutoQuest,Callback=function(on)
        cfg.useAutoQuest=on==true
        saveUi()
        if functionsEnabled.Level then setAutoQuest(on) end
    end})
farmLevel:AddSlider("PVCL_FarmRadius",{
    Text=words("Distância máxima dos inimigos","Max enemy distance"),
    Default=cfg.farmRadius,Min=250,Max=20000,Rounding=0,
    Callback=function(v)cfg.farmRadius=v end})
farmLevel:AddSlider("PVCL_AttackDelay",{
    Text=words("Intervalo dos ataques (s)","Attack interval (s)"),
    Default=cfg.attackInterval,Min=0.04,Max=0.5,Rounding=2,
    Callback=function(v)cfg.attackInterval=v end})
farmLevel:AddSlider("PVCL_AttackBurst",{
    Text=words("Golpes por ciclo (Multi Attack)","Hits per burst (Multi Attack)"),
    Default=cfg.attackBurst,Min=1,Max=4,Rounding=0,
    Callback=function(v)cfg.attackBurst=math.floor(v) end})
statusLines.Level=farmLevel:AddLabel(words("Desativado.","Disabled."),true)

farmChest:AddToggle("PVCL_Chest",{Text=words("Coletar baús automaticamente","Auto collect chests"),
    Default=false,Callback=function(on)safeToggle("Chest",on)end})
farmChest:AddSlider("PVCL_ChestRadius",{
    Text=words("Raio de busca dos baús","Chest search radius"),
    Default=cfg.chestRadius,Min=250,Max=20000,Rounding=0,
    Callback=function(v)cfg.chestRadius=v end})
farmChest:AddSlider("PVCL_ChestDelay",{
    Text=words("Intervalo entre baús (s)","Delay between chests (s)"),
    Default=cfg.chestDelay,Min=0.5,Max=10,Rounding=1,
    Callback=function(v)cfg.chestDelay=v end})
statusLines.Chest=farmChest:AddLabel(words("Desativado.","Disabled."),true)

farmMining:AddToggle("PVCL_Mine",{Text=words("Minerar automaticamente","Auto mine"),
    Default=false,Callback=function(on)safeToggle("Mine",on)end})
farmMining:AddDropdown("PVCL_Ore",{
    Text=words("Minério","Ore"),
    Values={"Auto","Iron","Gold","Diamond"},Default="Auto",
    Callback=function(v)cfg.oreType=v end})
farmMining:AddSlider("PVCL_MineRadius",{
    Text=words("Raio de mineração","Mining radius"),
    Default=cfg.mineRadius,Min=250,Max=20000,Rounding=0,
    Callback=function(v)cfg.mineRadius=v end})
farmMining:AddSlider("PVCL_MineDelay",{
    Text=words("Intervalo dos golpes (s)","Strike interval (s)"),
    Default=cfg.mineDelay,Min=0.9,Max=5,Rounding=2,
    Callback=function(v)cfg.mineDelay=v end})
statusLines.Mine=farmMining:AddLabel(words("Desativado.","Disabled."),true)

farmSpin:AddToggle("PVCL_Spin",{Text=words("Auto girar livros (Gemas)","Auto spin books (Gems)"),
    Default=false,Callback=function(on)safeToggle("Spin",on)end})
farmSpin:AddDropdown("PVCL_SpinRarity",{
    Text=words("Parar ao receber raridade","Stop at rarity"),
    Values={"Any","Rare","Legendary","Mythical"},Default="Legendary",
    Callback=function(v)cfg.spinRarity=v end})
farmSpin:AddSlider("PVCL_SpinMax",{
    Text=words("Limite total de giros","Total spin limit"),
    Default=cfg.spinMax,Min=1,Max=100,Rounding=0,
    Callback=function(v)cfg.spinMax=math.floor(v) end})
farmSpin:AddSlider("PVCL_SpinDelay",{
    Text=words("Intervalo entre giros (s)","Spin interval (s)"),
    Default=cfg.spinDelay,Min=4,Max=15,Rounding=1,
    Callback=function(v)cfg.spinDelay=v end})
farmSpin:AddLabel(words("Cada giro normal consome 160 Gemas. Não usa Robux.",
    "Normal spins cost 160 Gems each. No Robux purchases."),true)
farmSpin:AddButton({Text=words("Zerar contador de giros","Reset spin counter"),Func=function()
    if functionsEnabled.Spin then
        notify("Desative os giros antes de zerar o contador.",
            "Disable auto spins before resetting the counter.")
        return
    end
    currentSpinCount=0
    writeSpinBudget()
    notify("Contador zerado.","Spin counter reset.")
end})
statusLines.Spin=farmSpin:AddLabel(words("Desativado.","Disabled."),true)

-- Hitbox has its own tab and a manual state independent of the level farm.
local miscCombat=registerHeader(tabs.Misc:AddGroupbox({
    Side="Left",Name=words("Combate","Combat"),IconName="swords",
}),"Combate","Combat")
miscCombat:AddToggle("PVCL_HitboxExpander",{
    Text=words("Aumentar hitbox","Hitbox Expander"),
    Default=cfg.hitboxExpander,
    Callback=function(on)
        if hitboxSyncing then return end
        if functionsEnabled.Level and not on then
            -- Farm requires it; reenable visually without changing manual state.
            hitboxSyncing=true
            local toggle=Library.Toggles and Library.Toggles.PVCL_HitboxExpander
            if toggle then task.defer(function()
                if alive and functionsEnabled.Level then pcall(function()toggle:SetValue(true)end) end
                hitboxSyncing=false
            end) else hitboxSyncing=false end
            return
        end
        -- A toggle enabled automatically by farm is not a manual preference.
        if functionsEnabled.Level and hitboxAutoOwned then return end
        cfg.hitboxExpander=on==true
        if not on and not functionsEnabled.Level then restoreHitboxes() end
        saveUi()
    end,
})
miscCombat:AddSlider("PVCL_HitboxSize",{
    Text=words("Tamanho da hitbox invisível","Invisible hitbox size"),
    Default=cfg.hitboxSize,Min=8,Max=40,Rounding=0,
    Callback=function(v)cfg.hitboxSize=v end,
})
miscCombat:AddLabel(words(
    "Hitbox invisível. O Auto Farm ativa automaticamente e desativa ao parar; se já estava ligada manualmente, continua ligada.",
    "Invisible hitbox. Auto Farm enables it during farming and disables it afterwards, unless manually enabled before."),true)

local settingsControls=registerHeader(tabs.Config:AddGroupbox({
    Side="Left",Name=words("Controles","Controls"),IconName="keyboard",
}),"Controles","Controls")
local settingsAppearance=registerHeader(tabs.Config:AddGroupbox({
    Side="Left",Name=words("Aparência","Appearance"),IconName="sparkles",
}),"Aparência","Appearance")
local settingsProfiles=registerHeader(tabs.Config:AddGroupbox({
    Side="Right",Name=words("Configurações salvas","Saved profiles"),IconName="folder-cog",
}),"Configurações salvas","Saved profiles")
local settingsAbout=registerHeader(tabs.Config:AddGroupbox({
    Side="Right",Name=words("Sobre","About"),IconName="circle-help",
}),"Sobre","About")
-- PVH_Persistence hooks this Settings tab and puts Auto Save/Autoexec top left.
env.PVH_SettingsPolish=settingsControls

settingsControls:AddLabel(words("Atalhos de teclado","Keyboard shortcuts"),true)
local minimizeBtn=settingsControls:AddButton({
    Text=words("Minimizar o painel","Minimize panel"),
    Func=function()
        if Library and Library.Toggle then pcall(function()Library:Toggle()end) end
    end,
})
minimizeBtn:AddKeyPicker("PVCL_Key_Minimize",{
    Text=words("Minimizar","Minimize"),Default=cfg.minimizeKey,
    Mode="Press",SyncToggleState=false,
    ChangedCallback=function(key)
        cfg.minimizeKey=key and key.Name or "None"
        saveUi()
    end,
})
local function unload()
    if not alive then return end
    for key in pairs(functionsEnabled) do functionsEnabled[key]=false end
    alive=false
    stopMovement()
    hoverMob=nil
    restoreHitboxes()
    for _,connection in ipairs(connections) do pcall(function()connection:Disconnect()end) end
    if env.PVH_CloverUnload==unload then env.PVH_CloverUnload=nil end
    env.PVH_CloverDiagnostics=nil
    env.PVH_CloverCounters=nil
    if env.PVH_SettingsPolish==settingsControls then env.PVH_SettingsPolish=nil end
    if Library and not Library.Unloaded then pcall(function()Library:Unload()end) end
end
env.PVH_CloverUnload=unload

local unloadBtn=settingsControls:AddButton({
    Text=words("Descarregar o hub","Unload hub"),Func=unload,
})
unloadBtn:AddKeyPicker("PVCL_Key_Unload",{
    Text=words("Descarregar","Unload"),Default=cfg.unloadKey,
    Mode="Press",SyncToggleState=false,
    ChangedCallback=function(key)
        cfg.unloadKey=key and key.Name or "None"
        saveUi()
    end,
})
settingsControls:AddToggle("PVCL_KeyPanel",{
    Text=words("Mostrar painel de atalhos","Show keybind panel"),
    Default=cfg.showKeybinds,
    Callback=function(on)
        cfg.showKeybinds=on;saveUi()
        if Library.KeybindFrame then Library.KeybindFrame.Visible=on end
    end,
})
settingsAppearance:AddDropdown("PVCL_Language",{
    Text=words("Idioma","Language"),
    Values={"pt-BR","en-US"},Default=cfg.language,
    Callback=function(v)
        if v~="pt-BR" and v~="en-US" then return end
        cfg.language=v
        saveUi()
        task.defer(translateUI)
    end,
})
settingsAppearance:AddToggle("PVCL_UIAnimations",{
    Text=words("Animações da interface","UI animations"),
    Default=cfg.uiAnimations,
    Callback=function(on)
        cfg.uiAnimations=on==true
        saveUi()
        if Library.Animations then
            for _,key in ipairs({"ToggleWindow","TabSwitch","Groupbox","Dropdown","KeyPicker"}) do
                Library.Animations[key]=cfg.uiAnimations
            end
        end
    end,
})
settingsAppearance:AddToggle("PVCL_UISounds",{
    Text=words("Sons da interface","UI sounds"),Default=cfg.uiSounds,
    Callback=function(on)cfg.uiSounds=on==true;saveUi()end,
})
settingsAbout:AddLabel(words("Clover Legends: Devil Fusion | testes v0.1.0",
    "Clover Legends: Devil Fusion | test v0.1.0"),true)
settingsAbout:AddLabel(words("Fonte analisada: place.rbxl fornecido para testes.",
    "Source analyzed: the provided place.rbxl snapshot."),true)
settingsAbout:AddLabel(words("Farm, mineração, baús e giro dependem da validação do servidor.",
    "Farming, mining, chests and spinning depend on server validation."),true)

local profileName=""
local selectedProfile=nil
local function profilePath(name)
    local clean=tostring(name or ""):lower():gsub("[^%w_-]","_"):sub(1,32)
    if clean=="" then clean="default" end
    return ProfileDir.."/"..clean..".json"
end
local function listProfiles()
    local values={}
    if type(listfiles)=="function" then
        local ok,files=pcall(listfiles,ProfileDir)
        if ok and type(files)=="table" then
            for _,file in ipairs(files) do
                local name=file:gsub("\\","/"):match("/([^/]+)%.json$")
                if name then values[#values+1]=name end
            end
        end
    end
    table.sort(values)
    return values
end
local function snapshot()
    local result={schema=1,options={},toggles={}}
    for id,obj in pairs(Library.Options or {}) do
        if type(id)=="string" and id:sub(1,14)~="PVH_UNIVERSAL_"
            and id~="PVCL_ProfileName" and id~="PVCL_ProfileList" then
            local v=obj.Value
            if type(v)=="number" or type(v)=="string" or type(v)=="boolean" then
                result.options[id]=v
            end
        end
    end
    for id,obj in pairs(Library.Toggles or {}) do
        if type(id)=="string" and id:sub(1,14)~="PVH_UNIVERSAL_"
            and type(obj.Value)=="boolean" then
            result.toggles[id]=obj.Value
        end
    end
    return result
end
local function restore(data)
    if type(data)~="table" then return false end
    for id,value in pairs(data.options or {}) do
        local control=Library.Options[id]
        if control and type(control.SetValue)=="function" then
            pcall(function()control:SetValue(value)end)
        end
    end
    for id,value in pairs(data.toggles or {}) do
        local control=Library.Toggles[id]
        if control and type(value)=="boolean" and type(control.SetValue)=="function" then
            pcall(function()control:SetValue(value)end)
        end
    end
    return true
end
local function refreshProfiles()
    local list=listProfiles()
    local opt=Library.Options.PVCL_ProfileList
    if opt then
        opt:SetValues(#list>0 and list or {"---"})
        selectedProfile=#list>0 and list[1] or nil
        opt:SetValue(selectedProfile or "---")
    end
end
settingsProfiles:AddInput("PVCL_ProfileName",{
    Text=words("Nome da configuração","Profile name"),
    Default="",Finished=false,ClearTextOnFocus=false,
    Callback=function(v)profileName=tostring(v or "")end,
})
settingsProfiles:AddDropdown("PVCL_ProfileList",{
    Text=words("Perfis","Profiles"),Values={"---"},Default="---",
    Callback=function(v)selectedProfile=v~="---" and v or nil end,
})
settingsProfiles:AddButton({Text=words("Salvar configuração","Save profile"),
    Func=function()
        if profileName=="" then notify("Digite um nome primeiro.","Enter a name first.")return end
        ensureFolder(ProfileDir)
        if writeJSON(profilePath(profileName),snapshot()) then
            notify("Perfil salvo.","Profile saved.")
            refreshProfiles()
        else notify("Sem acesso a writefile.","writefile unavailable.")end
    end})
settingsProfiles:AddButton({Text=words("Carregar configuração","Load profile"),
    Func=function()
        if not selectedProfile then notify("Selecione um perfil.","Select a profile.")return end
        local data=readJSON(profilePath(selectedProfile))
        if data and restore(data) then
            notify("Perfil carregado.","Profile loaded.")
        else notify("Não foi possível carregar.","Could not load the profile.")end
    end})
settingsProfiles:AddButton({Text=words("Excluir configuração","Delete profile"),
    Func=function()
        if not selectedProfile then notify("Selecione um perfil.","Select a profile.")return end
        if type(delfile)=="function" and type(isfile)=="function" then
            local path=profilePath(selectedProfile)
            pcall(function()if isfile(path) then delfile(path)end end)
            refreshProfiles()
            notify("Perfil excluído.","Profile deleted.")
        end
    end})
settingsProfiles:AddButton({Text=words("Atualizar lista","Refresh list"),
    Func=refreshProfiles})
task.defer(refreshProfiles)

if Library.KeybindMenu then pcall(function()Library.KeybindMenu:SetVisibilityControl(true)end)end
if Library.KeybindFrame then Library.KeybindFrame.Visible=cfg.showKeybinds end
-- Native Obsidian button keypickers invoke the button's Func in Press
-- mode. No duplicate InputBegan handler (avoids double unload/minimize).

Library:OnUnload(function()
    if alive then unload() end
end)
-- The universal modules can inspect the UI and save/restore its controls.
-- Migrate only the legacy DEFAULT delays after universal Auto Save's three
-- restore passes (~1.8-4.8 s). Do not overwrite other customized settings.
-- The schema marker prevents repeating the migration on future launches.
local migrateDefaults=not saved or (tonumber(saved.tuningSchema) or 0)<4
task.delay(5.4,function()
    if not alive or not autoSaveAllowed() or not migrateDefaults then return end
    local attack=Library.Options and Library.Options.PVCL_AttackDelay
    if attack and tonumber(attack.Value) and
        (math.abs(tonumber(attack.Value)-0.70)<0.001 or
         math.abs(tonumber(attack.Value)-0.22)<0.001) then
        pcall(function()attack:SetValue(0.08)end)
    end
    local chest=Library.Options and Library.Options.PVCL_ChestDelay
    if chest and tonumber(chest.Value) and
        math.abs(tonumber(chest.Value)-7)<0.001 then
        pcall(function()chest:SetValue(1.2)end)
    end
    -- Previous tests saved tiny default radii (250/500, 550, 260).
    -- Migrate those exact defaults after universal Auto Save finishes.
    local oldRadii={
        {"PVCL_FarmRadius",{250,500},12000},
        {"PVCL_ChestRadius",{400,550},12000},
        {"PVCL_MineRadius",{260},12000},
    }
    for _,item in ipairs(oldRadii) do
        local option=Library.Options and Library.Options[item[1]]
        if option and type(option.SetValue)=="function" then
            for _,legacy in ipairs(item[2]) do
                if tonumber(option.Value)==legacy then
                    pcall(function()option:SetValue(item[3])end)
                    break
                end
            end
        end
    end
    local movement=Library.Options and Library.Options.PVCL_MoveMode
    if movement and type(movement.SetValue)=="function" then
        if movement.Value=="Teleport" then
            pcall(function()movement:SetValue("Blink")end)
        elseif movement.Value=="Fly" then
            pcall(function()movement:SetValue("Tween")end)
        end
    end
    saveUi()
end)
task.defer(translateUI)
task.spawn(function()
    while alive do
        task.wait(2)
        translateUI()
    end
end)
safeInfo("Port loaded",buildVersion,"place",game.PlaceId)
