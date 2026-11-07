-- Prime Void Hub | Clover Legends: Devil Fusion | v0.1.0 TEST
-- PlaceId 109813591245812 | 4 initial features; no server-side fake success.
-- Built from the supplied place snapshot, not guessed remote names.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Workspace=game:GetService("Workspace")
local UIS=game:GetService("UserInputService")
local HttpService=game:GetService("HttpService")
local Pathfinding=game:GetService("PathfindingService")
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
local counters={Kills=0,Chests=0,Ore=0,Spins=0}
local activeMove=nil
local spinResult=nil
local spinSequence=0
local statusText=nil
local labels={}
local groupHeaders={}
local statusLines={}
local buildVersion="v0.1.0 TEST"
local cfg={
    language="pt-BR",uiAnimations=true,uiSounds=false,showKeybinds=false,
    farmRadius=250,attackInterval=0.70,useAutoQuest=false,
    chestRadius=400,chestDelay=7,
    mineRadius=260,mineDelay=1.65,oreType="Auto",
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
    for _,key in ipairs({"uiAnimations","uiSounds","showKeybinds","minimizeKey","unloadKey"}) do
        if type(saved[key])==type(cfg[key]) then cfg[key]=saved[key] end
    end
end

local function saveUi()
    if not alive or not autoSaveAllowed() then return end
    ensureFolder(rootDir)
    writeJSON(SettingsPath,{
        language=cfg.language,uiAnimations=cfg.uiAnimations,
        uiSounds=cfg.uiSounds,showKeybinds=cfg.showKeybinds,
        minimizeKey=cfg.minimizeKey,unloadKey=cfg.unloadKey,
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

local function basicAttack()
    local input=getInputController()
    if input and input.OnBasicAttack and type(input.OnBasicAttack.Fire)=="function" then
        local ok=pcall(function()input.OnBasicAttack:Fire()end)
        return ok
    end
    return false
end

local function isAllowed(owner)
    return alive and functionsEnabled[owner]==true
end

local function moveNear(owner,target,reach,timeout)
    if not isAllowed(owner) then return false end
    local hum,root=humanoidRoot()
    if not hum or typeof(target)~="Vector3" then return false end
    if activeMove and activeMove~=owner then return false end
    if (root.Position-target).Magnitude<=reach then return true end
    activeMove=owner
    local start=os.clock()
    local reached=false
    while isAllowed(owner) and os.clock()-start<(timeout or 9) do
        hum,root=humanoidRoot()
        if not hum then break end
        local distance=(root.Position-target).Magnitude
        if distance<=reach then reached=true break end
        -- Roblox's native MoveTo rather than instant CFrame teleport.
        local direction=target-root.Position
        local destination=target-direction.Unit*math.min(math.max(reach-1,2),5)
        hum:MoveTo(destination)
        task.wait(0.35)
    end
    activeMove=nil
    if not isAllowed(owner) then
        hum,root=humanoidRoot()
        if hum and root then hum:MoveTo(root.Position) end
    end
    return reached
end

local function turnTo(target)
    local _,root=humanoidRoot()
    if not root or typeof(target)~="Vector3" then return end
    local flat=Vector3.new(target.X,root.Position.Y,target.Z)
    if (flat-root.Position).Magnitude>0.3 then
        pcall(function()root.CFrame=CFrame.lookAt(root.Position,flat)end)
    end
end

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

local function pickEnemy()
    enemyFolder=Workspace:FindFirstChild("Enemies") or enemyFolder
    local _,root=humanoidRoot()
    if not enemyFolder or not root then return nil end
    local level=playerLevel()
    local best,bestScore
    for _,npc in ipairs(enemyFolder:GetChildren()) do
        if npc:IsA("Model") then
            local hum=npc:FindFirstChildOfClass("Humanoid")
            local pivot=npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
            if hum and pivot and hum.Health>0 and npc~=LocalPlayer.Character then
                local dist=(root.Position-pivot.Position).Magnitude
                local npcLevel=getLevel(npc)
                local tooStrong=level and npcLevel and npcLevel>level+6
                if not tooStrong and dist<=cfg.farmRadius then
                    local score=dist+(npcLevel and level and math.abs(level-npcLevel)*0.9 or 0)
                    if not best or score<bestScore then
                        best=npc
                        bestScore=score
                    end
                end
            end
        end
    end
    return best
end

local hitStamp=0
local defeated=setmetatable({},{__mode="k"})
local function farmStep()
    local mob=pickEnemy()
    if not mob then
        updateStatus("Level","Nenhum inimigo adequado próximo.","No suitable nearby enemy.")
        task.wait(2)
        return
    end
    local enemyHum=mob:FindFirstChildOfClass("Humanoid")
    local enemyRoot=mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
    if not enemyHum or not enemyRoot then return end
    local close=moveNear("Level",enemyRoot.Position,9,8)
    if not close then return end
    local _,root=humanoidRoot()
    if not root or (root.Position-enemyRoot.Position).Magnitude>16 then return end
    turnTo(enemyRoot.Position)
    if os.clock()-hitStamp>=cfg.attackInterval then
        if basicAttack() then
            hitStamp=os.clock()
            updateStatus("Level",
                "Atacando: "..mob.Name.." | Nível "..tostring(playerLevel() or "?"),
                "Attacking: "..mob.Name.." | Level "..tostring(playerLevel() or "?"))
        else
            updateStatus("Level","Controle de combate ainda não carregou.",
                "Combat input controller is not ready.")
        end
    end
    if enemyHum.Health<=0 and not defeated[mob] then
        defeated[mob]=true
        counters.Kills+=1
    end
    task.wait(cfg.attackInterval)
end

local chestVisits=setmetatable({},{__mode="k"})
local function getPosition(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local part=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart",true)
        return part and part.Position or nil
    end
    if obj:IsA("ProximityPrompt") then
        return getPosition(obj.Parent)
    end
    return nil
end

local function selectChest()
    chestFolder=Workspace:FindFirstChild("WK_Chests") or chestFolder
    local _,root=humanoidRoot()
    if not root or not chestFolder then return nil end
    local best,bestDistance=nil,math.huge
    for _,obj in ipairs(chestFolder:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled
            and (not chestVisits[obj] or os.clock()-chestVisits[obj]>50) then
            local pos=getPosition(obj)
            local dist=pos and (root.Position-pos).Magnitude or math.huge
            if dist<=cfg.chestRadius and dist<bestDistance then
                best,bestDistance=obj,dist
            end
        end
    end
    return best
end

local function triggerPrompt(prompt)
    if type(fireproximityprompt)=="function" then
        local ok=pcall(fireproximityprompt,prompt)
        return ok
    end
    -- The standard game interaction uses ProximityPrompt. Don't claim a
    -- successful collection when the executor has no prompt API.
    return false
end

local function chestStep()
    local prompt=selectChest()
    if not prompt then
        updateStatus("Chest","Aguardando baú próximo.","Waiting for a nearby chest.")
        task.wait(3)
        return
    end
    local pos=getPosition(prompt)
    local radius=math.max(3,math.min(prompt.MaxActivationDistance-1,8))
    if not pos or not moveNear("Chest",pos,radius,11) then return end
    if prompt.Parent and prompt.Enabled then
        if triggerPrompt(prompt) then
            chestVisits[prompt]=os.clock()
            counters.Chests+=1
            updateStatus("Chest","Interação enviada: "..tostring(counters.Chests),
                "Interaction sent: "..tostring(counters.Chests))
        else
            functionsEnabled.Chest=false
            updateStatus("Chest","Executor sem fireproximityprompt.",
                "Executor lacks fireproximityprompt.")
            safeInfo("Chest helper missing: cannot confirm collection")
        end
    end
    task.wait(cfg.chestDelay)
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
        updateStatus("Mine","Nenhum minério disponível próximo.",
            "No nearby ore nodes found.")
        task.wait(2)
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

local function setAutoQuest(on)
    fire(remote("SetAutoQuest"),on)
end

local function safeToggle(flag,on)
    functionsEnabled[flag]=on==true
    if flag=="Level" and cfg.useAutoQuest then setAutoQuest(on) end
    if flag=="Spin" and on and not autoSaveAllowed() then
        currentSpinCount=0
    end
    if not on then
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
    local mobs=enemyFolder and #enemyFolder:GetChildren() or 0
    record("PVCL_Level",input~=nil and mobs>0 and playerRoot~=nil,
        "Enemies="..mobs.."; BasicAttack signal="..tostring(input~=nil)..
        "; character ready="..tostring(playerRoot~=nil))
    local chestCount=0
    if chestFolder then
        for _,p in ipairs(chestFolder:GetDescendants()) do
            if p:IsA("ProximityPrompt") and p.Enabled then chestCount+=1 end
        end
    end
    record("PVCL_Chest",chestCount>0 and type(fireproximityprompt)=="function",
        "Chests available="..chestCount..
        "; executor prompt API="..tostring(type(fireproximityprompt)=="function"))
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
local farmChest=registerHeader(tabs.Farm:AddGroupbox({
    Side="Right",Name=words("Coletar baús","Collect chests"),IconName="package",
}),"Coletar baús","Collect chests")
local farmMining=registerHeader(tabs.Farm:AddGroupbox({
    Side="Left",Name=words("Mineração","Mining"),IconName="pickaxe",
}),"Mineração","Mining")
local farmSpin=registerHeader(tabs.Farm:AddGroupbox({
    Side="Right",Name=words("Girar livros","Spin spellbooks"),IconName="book-open",
}),"Girar livros","Spin spellbooks")

farmLevel:AddToggle("PVCL_Level",{Text=words("Auto Farm Level","Auto Level Farm"),
    Default=false,Callback=function(on)safeToggle("Level",on)end})
farmLevel:AddToggle("PVCL_AutoQuest",{Text=words("Missão automática do jogo","Game auto-quest"),
    Default=false,Callback=function(on)
        cfg.useAutoQuest=on==true
        if functionsEnabled.Level then setAutoQuest(on) end
    end})
farmLevel:AddSlider("PVCL_FarmRadius",{
    Text=words("Distância máxima dos inimigos","Max enemy distance"),
    Default=cfg.farmRadius,Min=40,Max=800,Rounding=0,
    Callback=function(v)cfg.farmRadius=v end})
farmLevel:AddSlider("PVCL_AttackDelay",{
    Text=words("Intervalo dos ataques","Attack interval"),
    Default=cfg.attackInterval,Min=0.4,Max=2,Rounding=2,
    Callback=function(v)cfg.attackInterval=v end})
statusLines.Level=farmLevel:AddLabel(words("Desativado.","Disabled."),true)

farmChest:AddToggle("PVCL_Chest",{Text=words("Coletar baús automaticamente","Auto collect chests"),
    Default=false,Callback=function(on)safeToggle("Chest",on)end})
farmChest:AddSlider("PVCL_ChestRadius",{
    Text=words("Raio de busca dos baús","Chest search radius"),
    Default=cfg.chestRadius,Min=20,Max=1200,Rounding=0,
    Callback=function(v)cfg.chestRadius=v end})
farmChest:AddSlider("PVCL_ChestDelay",{
    Text=words("Intervalo entre baús (s)","Delay between chests (s)"),
    Default=cfg.chestDelay,Min=3,Max=25,Rounding=1,
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
    Default=cfg.mineRadius,Min=20,Max=1000,Rounding=0,
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
    local hum,root=humanoidRoot()
    if hum and root then hum:MoveTo(root.Position) end
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
task.defer(translateUI)
task.spawn(function()
    while alive do
        task.wait(2)
        translateUI()
    end
end)
safeInfo("Port loaded",buildVersion,"place",game.PlaceId)
