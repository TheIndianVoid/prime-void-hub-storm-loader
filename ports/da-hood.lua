-- Prime Void Hub | Da Hood | v0.1.1
-- Adapted from PVHub_DaHood_v0.1.0_TEST: shop, ESP, crosshair, FOV and movement.
-- No anticheat hooks, remote rewriting, webhook or misleading server confirmations.
local validPlaces={[2788229376]=true,[7213786345]=true}
if not validPlaces[tonumber(game.PlaceId)] and tonumber(game.GameId)~=1008451066 then
    error("[PVH Da Hood] Wrong experience",0)
end
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local HttpService=game:GetService("HttpService")
local TeleportService=game:GetService("TeleportService")
local SoundService=game:GetService("SoundService")
local player=Players.LocalPlayer
if not player then error("[PVH Da Hood] LocalPlayer unavailable",0) end
local env=(type(getgenv)=="function" and getgenv()) or _G
if type(env.PV_DaHoodUnload)=="function" then pcall(env.PV_DaHoodUnload) end

local VERSION="v0.1.1"
local rootDir="primevoid_hub/Da_Hood"
local cfgPath=rootDir.."/Configs/ui_settings.json"
local logPath=rootDir.."/Logs/PVH_DaHood_Session.txt"
local alive=true
local conn,objects={},{}
local Library,overlay,window
local visualCache={}
local sound
local sfxId="rbxassetid://10066942189"
local logLines={}
local lastLogFlush=0
local function ensureFolder(path)
    if type(makefolder)~="function" then return false end
    local partial=""
    for part in path:gmatch("[^/]+") do
        partial=partial=="" and part or partial.."/"..part
        local exists=type(isfolder)=="function" and isfolder(partial)
        if not exists then
            local ok=pcall(makefolder,partial)
            if not ok and (type(isfolder)~="function" or not isfolder(partial)) then
                return false
            end
        end
    end
    return true
end
local function log(code,description,force)
    local line=string.format("[%s] [%s] %s",os.date("!%Y-%m-%d %H:%M:%S"),tostring(code),
        tostring(description or ""):sub(1,240))
    warn("[PVH Da Hood] "..line)
    logLines[#logLines+1]=line
    if #logLines>400 then table.remove(logLines,1) end
    if type(writefile)~="function" then return end
    if not force and os.clock()-lastLogFlush<1.5 then return end
    lastLogFlush=os.clock()
    pcall(function()
        if ensureFolder(rootDir.."/Logs") then
            writefile(logPath,table.concat(logLines,"\n").."\n")
        end
    end)
end
local function autoSaveEnabled()
    return type(env.PVH_Persistence)~="table" or env.PVH_Persistence.AutoSave~=false
end
local cfg={
    language="pt-BR",uiAnimations=true,uiSounds=false,showKeybinds=false,
    esp=false,box=true,health=true,names=true,distance=false,
    espColor={182,134,255},crosshairColor={235,227,255},
    crosshair=false,crosshairSize=9,crosshairGap=5,
    fov=false,fovAmount=90,speed=false,speedAmount=22,
    weapon="Revolver",autoLoadout=false,autoArmor=false,autoAmmo=false,
    interval=3,
    minimizeKey="RightShift",unloadKey="Delete",
}
local function loadConfig()
    if not autoSaveEnabled() or type(isfile)~="function"
        or type(readfile)~="function" then return end
    local ok,prefs=pcall(function()
        if isfile(cfgPath) then return HttpService:JSONDecode(readfile(cfgPath)) end
    end)
    if not ok or type(prefs)~="table" then return end
    for key,val in pairs(prefs) do
        if cfg[key]~=nil and type(cfg[key])==type(val) then cfg[key]=val end
    end
    if cfg.language~="en-US" then cfg.language="pt-BR" end
end
local function saveConfig()
    if not alive or not autoSaveEnabled() or type(writefile)~="function" then return end
    pcall(function()
        if ensureFolder(rootDir.."/Configs") then
            writefile(cfgPath,HttpService:JSONEncode(cfg))
        end
    end)
end
loadConfig()
local phrasePairs={}
local phraseKeys={}
local function T(pt,en)
    if type(pt)=="string" and type(en)=="string" and not phraseKeys[pt] then
        phrasePairs[#phrasePairs+1]={pt,en}
        phraseKeys[pt]=true
    end
    return cfg.language=="en-US" and en or pt
end
local function refreshLanguage()
    if not Library or not Library.ScreenGui then return end
    for _,node in ipairs(Library.ScreenGui:GetDescendants()) do
        if node:IsA("TextLabel") or node:IsA("TextButton") then
            for _,pair in ipairs(phrasePairs) do
                if node.Text==pair[1] or node.Text==pair[2] then
                    node.Text=cfg.language=="en-US" and pair[2] or pair[1]
                    break
                end
            end
        end
    end
end
local function track(c)conn[#conn+1]=c return c end
local function keep(obj) objects[#objects+1]=obj return obj end
local function getHumanoid()
    local c=player.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local c=player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function beep()
    if cfg.uiSounds and sound then pcall(function()sound:Play()end) end
end
local function notify(pt,en)
    if Library and not Library.Unloaded then
        pcall(function()Library:Notify({
            Title="Prime Void Hub",Description=T(pt,en),Time=3
        })end)
    end
end
local function destroy(obj)if obj then pcall(function()obj:Destroy()end)end end
local function color(triple)
    return Color3.fromRGB(triple[1] or 255,triple[2] or 255,triple[3] or 255)
end
overlay=keep(Instance.new("ScreenGui"))
overlay.Name="PVH_DaHood_Visuals"
overlay.ResetOnSpawn=false
overlay.IgnoreGuiInset=true
overlay.DisplayOrder=990
overlay.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
overlay.Parent=player:WaitForChild("PlayerGui")
sound=keep(Instance.new("Sound"))
sound.Name="PVH_DaHood_UI"
sound.SoundId=sfxId
sound.Volume=0.15
sound.Parent=SoundService

local function frame(bg,parent)
    local item=Instance.new("Frame")
    item.BorderSizePixel=0
    item.BackgroundColor3=bg
    item.Parent=parent or overlay
    return item
end
local function textItem(size)
    local item=Instance.new("TextLabel")
    item.BackgroundTransparency=1
    item.Font=Enum.Font.GothamBold
    item.TextSize=size
    item.TextColor3=Color3.new(1,1,1)
    item.TextStrokeTransparency=0.4
    item.Parent=overlay
    return item
end
local crosshair={}
for i=1,4 do crosshair[i]=frame(color(cfg.crosshairColor)) crosshair[i].Visible=false end
local function clearPlayer(plr)
    local visual=visualCache[plr]
    if not visual then return end
    visualCache[plr]=nil
    for _,obj in pairs(visual) do destroy(obj) end
end
track(Players.PlayerRemoving:Connect(clearPlayer))
local function ensurePlayer(plr)
    if visualCache[plr] then return visualCache[plr] end
    local rectangle=frame(Color3.new(1,1,1))
    rectangle.BackgroundTransparency=1
    rectangle.Visible=false
    local stroke=Instance.new("UIStroke")
    stroke.Thickness=1.5
    stroke.Color=color(cfg.espColor)
    stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    stroke.Parent=rectangle
    local result={
        box=rectangle,stroke=stroke,
        hpBack=frame(Color3.fromRGB(22,22,28)),
        hpFill=frame(Color3.fromRGB(92,220,132)),
        name=textItem(12),dist=textItem(11)
    }
    visualCache[plr]=result
    return result
end
local function hidePlayer(v)
    v.box.Visible=false;v.hpBack.Visible=false;v.hpFill.Visible=false
    v.name.Visible=false;v.dist.Visible=false
end
local function bounds(model,cam)
    local cf,sz=model:GetBoundingBox()
    local half=sz*0.5
    local minx,miny,maxx,maxy=math.huge,math.huge,-math.huge,-math.huge
    for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
        local p=cam:WorldToViewportPoint(cf:PointToWorldSpace(Vector3.new(
            half.X*x,half.Y*y,half.Z*z)))
        if p.Z<=0 then return end
        minx=math.min(minx,p.X);miny=math.min(miny,p.Y)
        maxx=math.max(maxx,p.X);maxy=math.max(maxy,p.Y)
    end end end
    if maxx-minx<3 or maxy-miny<3 then return end
    if maxx-minx>cam.ViewportSize.X*0.5 or maxy-miny>cam.ViewportSize.Y*0.95 then return end
    return minx,miny,maxx,maxy
end
local function drawESP()
    if not cfg.esp then
        for _,v in pairs(visualCache) do hidePlayer(v) end
        return
    end
    local cam=workspace.CurrentCamera
    if not cam then return end
    local me=getRoot()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=player then
            local v=ensurePlayer(plr)
            local char=plr.Character
            local humanoid=char and char:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health<=0 then hidePlayer(v) else
                local x1,y1,x2,y2=bounds(char,cam)
                if not x1 then hidePlayer(v) else
                    local height=y2-y1
                    v.box.Visible=cfg.box
                    v.box.Position=UDim2.fromOffset(x1,y1)
                    v.box.Size=UDim2.fromOffset(x2-x1,height)
                    v.stroke.Color=color(cfg.espColor)
                    local ratio=math.clamp(humanoid.Health/math.max(1,humanoid.MaxHealth),0,1)
                    v.hpBack.Visible=cfg.health
                    v.hpFill.Visible=cfg.health
                    v.hpBack.Position=UDim2.fromOffset(x1-8,y1)
                    v.hpBack.Size=UDim2.fromOffset(4,height)
                    v.hpFill.Position=UDim2.fromOffset(x1-7,y2-height*ratio)
                    v.hpFill.Size=UDim2.fromOffset(2,height*ratio)
                    v.hpFill.BackgroundColor3=Color3.fromRGB(
                        math.floor(255*(1-ratio)),math.floor(230*ratio),65)
                    v.name.Visible=cfg.names
                    v.name.Text=plr.DisplayName
                    v.name.Position=UDim2.fromOffset(x1-30,y1-20)
                    v.name.Size=UDim2.fromOffset(x2-x1+60,19)
                    local other=char:FindFirstChild("HumanoidRootPart")
                    v.dist.Visible=cfg.distance and me~=nil and other~=nil
                    if v.dist.Visible then
                        v.dist.Text=tostring(math.floor((other.Position-me.Position).Magnitude)).." studs"
                        v.dist.Position=UDim2.fromOffset(x1,y2+1)
                        v.dist.Size=UDim2.fromOffset(x2-x1,17)
                    end
                end
            end
        end
    end
end
local function drawCrosshair()
    if not cfg.crosshair then
        for _,part in ipairs(crosshair) do part.Visible=false end
        return
    end
    local cam=workspace.CurrentCamera
    if not cam then return end
    local cx,cy=cam.ViewportSize.X/2,cam.ViewportSize.Y/2
    local gap,arm=cfg.crosshairGap,cfg.crosshairSize
    local positions={
        {cx-gap-arm,cy-1,arm,2},{cx+gap,cy-1,arm,2},
        {cx-1,cy-gap-arm,2,arm},{cx-1,cy+gap,2,arm}
    }
    for i,part in ipairs(crosshair) do
        local p=positions[i]
        part.Position=UDim2.fromOffset(p[1],p[2])
        part.Size=UDim2.fromOffset(p[3],p[4])
        part.BackgroundColor3=color(cfg.crosshairColor)
        part.Visible=true
    end
end
local elapsed=0
track(RunService.RenderStepped:Connect(function(dt)
    if not alive then return end
    drawCrosshair()
    elapsed+=dt
    if elapsed>=0.1 then
        elapsed=0
        local ok,err=pcall(drawESP)
        if not ok then log("ESP_ERROR",err)end
    end
end))
local originalFov,originalCamera,originalSpeed,originalHum=nil,nil,nil,nil
local function resetFov()
    if originalCamera and originalCamera.Parent and originalFov then
        pcall(function()originalCamera.FieldOfView=originalFov end)
    end
    originalCamera=nil;originalFov=nil
end
local function resetSpeed()
    if originalHum and originalHum.Parent and originalSpeed then
        pcall(function()originalHum.WalkSpeed=originalSpeed end)
    end
    originalHum=nil;originalSpeed=nil
end
local function visualProperties()
    local cam=workspace.CurrentCamera
    if cfg.fov and cam then
        if originalCamera~=cam then resetFov();originalCamera=cam;originalFov=cam.FieldOfView end
        cam.FieldOfView=cfg.fovAmount
    else resetFov() end
    local hum=getHumanoid()
    if cfg.speed and hum then
        if originalHum~=hum then resetSpeed();originalHum=hum;originalSpeed=hum.WalkSpeed end
        hum.WalkSpeed=cfg.speedAmount
    else resetSpeed() end
end
track(RunService.Heartbeat:Connect(function()
    if alive then visualProperties() end
end))

-- Native shop layout recovered from the original Da Hood test port.
local WEAPONS={
    "AK47","AR","AUG","Deagle","Double-Barrel SG","DrumGun",
    "Flamethrower","Flintlock","Glock","Grenade","LMG","P90",
    "Revolver","Rifle","RPG","Shotgun","Silencer","SilencerAR",
    "SMG","Tactical Shotgun"
}
local function hasTool(name)
    local wanted="["..name.."]"
    local c=player.Character
    local bp=player:FindFirstChildOfClass("Backpack")
    return (c and c:FindFirstChild(wanted)~=nil)
        or (bp and bp:FindFirstChild(wanted)~=nil) or false
end
local function shop()
    local ignored=workspace:FindFirstChild("Ignored")
    return ignored and ignored:FindFirstChild("Shop")
end
local function normalized(v)
    return tostring(v or ""):lower():gsub("[^%w]","")
end
local function findShopItem(name,ammo)
    local root=shop()
    if not root then return nil end
    for _,item in ipairs(root:GetChildren()) do
        local b=item.Name:match("%[([^%]]+)%]")
        if b then
            local isAmmo=b:lower():find("ammo",1,true)~=nil
            local base=b:gsub("%s*[Aa][Mm][Mm][Oo]%s*","")
            if isAmmo==ammo and normalized(base)==normalized(name) then
                local part=item:FindFirstChild("Head")
                    or item:FindFirstChildWhichIsA("BasePart")
                local click=item:FindFirstChildWhichIsA("ClickDetector",true)
                if part and click then return part,click end
            end
        end
    end
end
local busy=false
local lastBuy=-100
local function purchase(name,ammo)
    if not alive or busy then return false,"busy" end
    if type(fireclickdetector)~="function" then return false,"unsupported input" end
    if os.clock()-lastBuy<1 then return false,"cooldown" end
    local root=getRoot()
    local part,click=findShopItem(name,ammo)
    if not root or not part or not click then return false,"shop item unavailable" end
    busy=true
    local previous=root.CFrame
    local ok,err=pcall(function()
        root.CFrame=part.CFrame*CFrame.new(0,2.8,0)
        task.wait(0.15)
        if alive and root.Parent and click.Parent then fireclickdetector(click) end
        task.wait(0.15)
    end)
    if root.Parent then pcall(function()root.CFrame=previous end) end
    lastBuy=os.clock()
    busy=false
    log("SHOP_ATTEMPT",name..(ammo and "/ammo" or "/weapon")..
        " request="..tostring(ok)..(ok and "" or (" error="..tostring(err))))
    return ok,ok and "request_sent_not_confirmed" or tostring(err)
end
local function buyArmor()
    local root=shop()
    local partItem=root and root:FindFirstChild("[High-Medium Armor] - $2513")
    local me=getRoot()
    local part=partItem and (partItem:FindFirstChild("Head")
        or partItem:FindFirstChildWhichIsA("BasePart"))
    local click=partItem and partItem:FindFirstChildWhichIsA("ClickDetector",true)
    if not me or not part or not click or busy
        or type(fireclickdetector)~="function" then return false end
    busy=true
    local previous=me.CFrame
    local ok,err=pcall(function()
        me.CFrame=part.CFrame*CFrame.new(0,2.8,0)
        task.wait(0.15)
        if alive and me.Parent and click.Parent then fireclickdetector(click) end
        task.wait(0.15)
    end)
    if me.Parent then pcall(function()me.CFrame=previous end) end
    busy=false
    log("ARMOR_ATTEMPT",ok and "sent_not_confirmed" or tostring(err))
    return ok
end
local function armorValue()
    local body=player.Character and player.Character:FindFirstChild("BodyEffects")
    local val=body and body:FindFirstChild("Armor")
    return val and tonumber(val.Value)
end
local lastCycle=0
track(RunService.Heartbeat:Connect(function()
    if not alive or busy or os.clock()-lastCycle<cfg.interval then return end
    lastCycle=os.clock()
    if not (cfg.autoLoadout or cfg.autoArmor or cfg.autoAmmo) then return end
    local tasks={}
    if cfg.autoLoadout and not hasTool(cfg.weapon) then
        tasks[#tasks+1]=function()purchase(cfg.weapon,false)end
    end
    if cfg.autoArmor and armorValue() and armorValue()<75 then
        tasks[#tasks+1]=buyArmor
    end
    if cfg.autoAmmo and hasTool(cfg.weapon) then
        tasks[#tasks+1]=function()purchase(cfg.weapon,true)end
    end
    if #tasks>0 then
        local index=math.floor(os.clock()/cfg.interval)%#tasks+1
        task.spawn(tasks[index])
    end
end))
local function unload()
    if not alive then return end
    alive=false
    cfg.esp=false;cfg.crosshair=false;cfg.fov=false;cfg.speed=false
    resetFov();resetSpeed()
    for _,c in ipairs(conn) do pcall(function()c:Disconnect()end) end
    for plr in pairs(visualCache) do clearPlayer(plr)end
    for _,obj in ipairs(objects) do destroy(obj)end
    if Library and not Library.Unloaded then pcall(function()Library:Unload()end)end
    if env.PV_DaHoodUnload==unload then env.PV_DaHoodUnload=nil end
    log("UNLOAD","Da Hood port unloaded",true)
end
env.PV_DaHoodUnload=unload

-- Pinned Obsidian version shared by existing Prime Void Hub ports.
local obsidianUrl="https://raw.githubusercontent.com/deividcomsono/Obsidian/82d402b5de7d8903915f1afe99b5b7e340e7cd28/Library.lua"
local loaded,lib=pcall(function()
    return loadstring(game:HttpGet(obsidianUrl))()
end)
if not loaded or type(lib)~="table" then
    log("UI_FATAL",lib,true)
    unload()
    error("[PVH Da Hood] Obsidian unavailable: "..tostring(lib),0)
end
Library=lib
env.Library=Library
Library.ShowCustomCursor=false
local okUI,errUI=pcall(function()
    window=Library:CreateWindow({
        Title="Prime Void Hub | Da Hood",Footer="Da Hood | "..VERSION,
        Center=true,AutoShow=true,Resizable=true,
        Size=UDim2.fromOffset(680,475),
        ToggleKeybind=Enum.KeyCode.RightControl, -- safe placeholder
        ShowCustomCursor=false,NotifySide="Right",MinSidebarWidth=155,
        Animations={
            ToggleWindow=cfg.uiAnimations,TabSwitch=cfg.uiAnimations,
            Groupbox=cfg.uiAnimations,Dropdown=cfg.uiAnimations,
            KeyPicker=cfg.uiAnimations,
        }
    })
    -- Only the native Button keypicker owns the minimize hotkey.
    -- Built-in RightShift and the keypicker previously toggled twice.
    Library.ToggleKeybind=nil
    local home=window:AddTab(T("Início","Home"),"house")
    local farm=window:AddTab(T("Farm","Farm"),"shopping-cart")
    local visuals=window:AddTab(T("Visuais","Visuals"),"eye")
    local misc=window:AddTab(T("Miscelânea","Miscellaneous"),"wrench")
    local config=window:AddTab(T("Configurações","Settings"),"settings")
    local function group(tab,pt,en,side,iconName)
        return tab:AddGroupbox({Name=T(pt,en),Side=side,IconName=iconName})
    end
    local account=group(home,"Conta","Account","Left","user-round")
    account:AddLabel(player.DisplayName.." (@"..player.Name..")",true)
    account:AddLabel("UserId: "..tostring(player.UserId),true)
    account:AddLabel("PlaceId: "..tostring(game.PlaceId),true)
    local status=group(home,"Estado da sessão","Session status","Left","activity")
    status:AddLabel(T("Da Hood ativo","Da Hood active").." | "..VERSION,true)
    local roster=group(home,"Jogos suportados","Supported games","Right","gamepad-2")
    roster:AddLabel("Ride Storm • HUNTRESS • Steal An Exu",true)
    roster:AddLabel("Clover Legends • Grau SP • RIVALS",true)
    roster:AddLabel("War Tycoon • Da Hood • Steal a Brainrot",true)
    roster:AddLabel("Don't Splash • Destruction Simulator",true)
    local community=group(home,"Comunidade","Community","Right","message-circle")
    community:AddButton({Text=T("Copiar Discord","Copy Discord"),Func=function()
        beep()
        if type(setclipboard)=="function" then
            pcall(setclipboard,"https://discord.gg/PD3PeyG8aq")
        end
    end})
    local function toggle(g,id,pt,en,key)
        g:AddToggle(id,{Text=T(pt,en),Default=cfg[key],
            Callback=function(v)cfg[key]=v==true;saveConfig()end})
    end
    local function slider(g,id,pt,en,key,lo,hi)
        g:AddSlider(id,{Text=T(pt,en),Min=lo,Max=hi,
            Default=cfg[key],Rounding=0,
            Callback=function(v)cfg[key]=v;saveConfig()end})
    end
    local weapons=group(farm,"Armas","Weapons","Left","target")
    weapons:AddDropdown("PVDH_Weapon",{
        Text=T("Arma selecionada","Selected weapon"),
        Values=WEAPONS,Default=cfg.weapon,
        Callback=function(v)cfg.weapon=v;saveConfig()end
    })
    weapons:AddButton({Text=T("Comprar arma","Buy weapon"),Func=function()
        beep()
        task.spawn(function()
            local ok,reason=purchase(cfg.weapon,false)
            if not ok then notify("Arma indisponível: "..reason,"Weapon unavailable: "..reason) end
        end)
    end})
    weapons:AddButton({Text=T("Comprar munição","Buy ammo"),Func=function()
        beep()
        task.spawn(function()
            local ok,reason=purchase(cfg.weapon,true)
            if not ok then notify("Munição indisponível: "..reason,"Ammo unavailable: "..reason) end
        end)
    end})
    local automation=group(farm,"Compras automáticas","Auto purchases","Right","refresh-cw")
    toggle(automation,"PVDH_AutoLoadout","Auto Loadout","Auto Loadout","autoLoadout")
    toggle(automation,"PVDH_AutoArmor","Auto Armor","Auto Armor","autoArmor")
    toggle(automation,"PVDH_AutoAmmo","Auto Ammo","Auto Ammo","autoAmmo")
    slider(automation,"PVDH_Interval","Intervalo (s)","Interval (s)","interval",2,15)
    local esp=group(visuals,"ESP Jogadores","Player ESP","Left","scan-eye")
    toggle(esp,"PVDH_ESP","Ativar ESP","Enable ESP","esp")
    toggle(esp,"PVDH_ESPBox","Contorno","Box","box")
    toggle(esp,"PVDH_ESPHealth","Vida","Health","health")
    toggle(esp,"PVDH_ESPNames","Nomes","Names","names")
    toggle(esp,"PVDH_ESPDistance","Distância","Distance","distance")
    local colorControl=esp:AddLabel(T("Cor do ESP","ESP color"))
    colorControl:AddColorPicker("PVDH_ESPColor",{
        Default=color(cfg.espColor),Title=T("Cor do ESP","ESP color")
    })
    local cross=group(visuals,"Mira","Crosshair","Right","crosshair")
    toggle(cross,"PVDH_Crosshair","Exibir mira","Show crosshair","crosshair")
    slider(cross,"PVDH_CrosshairLength","Tamanho","Length","crosshairSize",2,30)
    slider(cross,"PVDH_CrosshairGap","Espaçamento","Gap","crosshairGap",0,20)
    cross:AddLabel(T("Cor da mira","Crosshair color")):AddColorPicker("PVDH_CrosshairColor",{
        Default=color(cfg.crosshairColor),Title=T("Cor da mira","Crosshair color")
    })
    local movement=group(misc,"Movimento","Movement","Left","move-3d")
    toggle(movement,"PVDH_Speed","Velocidade","Speed","speed")
    slider(movement,"PVDH_SpeedValue","WalkSpeed","WalkSpeed","speedAmount",16,60)
    local camera=group(misc,"Câmera","Camera","Right","camera")
    toggle(camera,"PVDH_FOV","FOV personalizado","Custom FOV","fov")
    slider(camera,"PVDH_FOVValue","Campo de visão","Camera FOV","fovAmount",60,120)
    local prefs=group(config,"Preferências","Preferences","Left","sliders-horizontal")
    prefs:AddDropdown("PVDH_Language",{
        Text=T("Idioma","Language"),Values={"Português","English"},
        Default=cfg.language=="en-US" and "English" or "Português",
        Callback=function(v)
            local lang=v=="English" and "en-US" or "pt-BR"
            if cfg.language~=lang then
                cfg.language=lang;saveConfig()
                task.defer(refreshLanguage)
            end
        end
    })
    prefs:AddToggle("PVDH_Animations",{
        Text=T("Animações","Animations"),Default=cfg.uiAnimations,
        Callback=function(v)
            cfg.uiAnimations=v==true
            if type(Library.Animations)=="table" then
                for key in pairs(Library.Animations) do
                    if type(Library.Animations[key])=="boolean" then
                        Library.Animations[key]=cfg.uiAnimations
                    end
                end
            end
            saveConfig()
        end
    })
    toggle(prefs,"PVDH_Sounds","Sons da interface","UI sounds","uiSounds")
    prefs:AddToggle("PVDH_KeyPanel",{
        Text=T("Mostrar atalhos","Show keybind panel"),
        Default=cfg.showKeybinds,Callback=function(v)
            cfg.showKeybinds=v==true
            if Library.KeybindFrame then
                Library.KeybindFrame.Visible=cfg.showKeybinds
            end
            saveConfig()
        end
    })
    local session=group(config,"Sessão e atalhos","Session & keybinds","Right","settings")
    session:AddButton({Text=T("Reentrar","Rejoin"),Func=function()
        beep()
        pcall(function()TeleportService:Teleport(game.PlaceId,player)end)
    end})
    local minimize=session:AddButton({Text=T("Minimizar o hub","Minimize hub"),
        Func=function()
            beep()
            if Library then
                if type(Library.Toggle)=="function" then Library:Toggle()
                elseif type(Library.ToggleWindow)=="function" then Library:ToggleWindow()
                end
            end
        end})
    local kmin=minimize:AddKeyPicker("PVDH_KeyMinimize",{
        Text=T("Minimizar","Minimize"),Default=cfg.minimizeKey,Mode="Press",
        SyncToggleState=false,ChangedCallback=function(v)
            cfg.minimizeKey=v and v.Name or "RightShift";saveConfig()
        end
    })
    local unloadBtn=session:AddButton({Text=T("Descarregar o hub","Unload hub"),Func=unload})
    unloadBtn:AddKeyPicker("PVDH_KeyUnload",{
        Text=T("Descarregar","Unload"),Default=cfg.unloadKey,Mode="Press",
        SyncToggleState=false,ChangedCallback=function(v)
            cfg.unloadKey=v and v.Name or "Delete";saveConfig()
        end
    })
    local options=Library.Options or {}
    if options.PVDH_ESPColor and type(options.PVDH_ESPColor.OnChanged)=="function" then
        options.PVDH_ESPColor:OnChanged(function()
            local v=options.PVDH_ESPColor.Value
            if typeof(v)=="Color3" then
                cfg.espColor={math.floor(v.R*255+0.5),math.floor(v.G*255+0.5),math.floor(v.B*255+0.5)}
                saveConfig()
            end
        end)
    end
    if options.PVDH_CrosshairColor and type(options.PVDH_CrosshairColor.OnChanged)=="function" then
        options.PVDH_CrosshairColor:OnChanged(function()
            local v=options.PVDH_CrosshairColor.Value
            if typeof(v)=="Color3" then
                cfg.crosshairColor={math.floor(v.R*255+0.5),math.floor(v.G*255+0.5),math.floor(v.B*255+0.5)}
                saveConfig()
            end
        end)
    end
    if Library.KeybindFrame then Library.KeybindFrame.Visible=cfg.showKeybinds end
    if Library.KeybindMenu and Library.KeybindMenu.SetVisibilityControl then
        pcall(function()Library.KeybindMenu:SetVisibilityControl(true)end)
    end
    Library:OnUnload(function()if alive then unload()end end)
end)
if not okUI then
    log("UI_FATAL",errUI,true)
    unload()
    error("[PVH Da Hood] UI initialization error: "..tostring(errUI),0)
end
env.PV_Hub_ActivePort="Da Hood"
log("PORT_READY",VERSION,true)
