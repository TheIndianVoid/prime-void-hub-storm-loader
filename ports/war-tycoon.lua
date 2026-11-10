-- Prime Void Hub | War Tycoon | v0.1.1
-- ACS / FastCast port from the supplied wartycoon.lua. Client effects are not proof of server validation.
if tonumber(game.PlaceId)~=4639625707 and tonumber(game.GameId)~=1526814825 then
    error("[PVH War Tycoon] Wrong experience",0)
end

local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local SoundService=game:GetService("SoundService")
local player=Players.LocalPlayer
local env=(type(getgenv)=="function" and getgenv()) or _G
if type(env.PVH_WarTycoonUnload)=="function" then pcall(env.PVH_WarTycoonUnload)end
local VERSION="v0.1.1"
local cfgPath="primevoid_hub/War_Tycoon/Configs/ui_settings.json"
local cfg={
 language="pt-BR",uiAnimations=true,uiSounds=false,showKeybinds=false,
 minimizeKey="RightShift",unloadKey="Delete",
 enabled=false,team_check=true,target_part="Head",fov_radius=150,
 prediction=0.13,hit_chance=1,no_recoil=false,no_spread=false,
 inf_ammo=false,no_reload=false,no_bolt=false,firerate_enabled=false,
 bullet_speed_enabled=false,bullet_distance_enabled=false,
 bullet_speed=99999,bullet_distance=99999,
}
local alive=true
local conns={}
local Library=nil
local uiStatus
local audio
local ptToEn,enToPt={},{}
local function T(pt,en)
 ptToEn[pt]=en enToPt[en]=pt
 return cfg.language=="en-US" and en or pt
end
local function track(c)conns[#conns+1]=c return c end
local function ensureFolders()
 if type(makefolder)~="function" then return end
 local s=""
 for part in string.gmatch("primevoid_hub/War_Tycoon/Configs","[^/]+") do
  s=s=="" and part or s.."/"..part
  local ok,exists=pcall(function()return type(isfolder)=="function" and isfolder(s)end)
  if not(ok and exists)then pcall(makefolder,s)end
 end
end
local function autoSave()
 return type(env.PVH_Persistence)~="table" or env.PVH_Persistence.AutoSave~=false
end
local function loadPrefs()
 if not autoSave() or type(isfile)~="function" or type(readfile)~="function" then return end
 local ok,data=pcall(function()
  if isfile(cfgPath)then return HttpService:JSONDecode(readfile(cfgPath))end
 end)
 if not ok or type(data)~="table" then return end
 for k,v in pairs(data)do
  if cfg[k]~=nil and type(cfg[k])==type(v)then cfg[k]=v end
 end
 if cfg.language~="en-US"then cfg.language="pt-BR"end
 if cfg.target_part~="Head"and cfg.target_part~="UpperTorso"and cfg.target_part~="HumanoidRootPart"then cfg.target_part="Head"end
 cfg.fov_radius=math.clamp(cfg.fov_radius,30,600)
 cfg.prediction=math.clamp(cfg.prediction,0,0.5)
 cfg.hit_chance=math.clamp(cfg.hit_chance,0,1)
 cfg.bullet_speed=math.clamp(cfg.bullet_speed,1000,99999)
 cfg.bullet_distance=math.clamp(cfg.bullet_distance,1000,99999)
end
local function savePrefs()
 if not autoSave()or type(writefile)~="function"then return end
 ensureFolders()
 pcall(function()writefile(cfgPath,HttpService:JSONEncode(cfg))end)
end
loadPrefs()
local lastPT,lastEN="Carregando","Loading"
local function status(pt,en)
 lastPT,lastEN=pt,en
 if uiStatus then pcall(function()uiStatus:SetText(cfg.language=="en-US"and lastEN or lastPT)end)end
end
local function log(code,value)warn("[PVH WAR]["..tostring(code).."] "..tostring(value or ""))end
local function notify(pt,en)
 if Library and not Library.Unloaded then
  pcall(function()Library:Notify({Title="Prime Void Hub | War Tycoon",Description=cfg.language=="en-US"and en or pt,Time=4})end)
 end
end
local function playSound()
 if cfg.uiSounds and audio then pcall(function()audio:Play()end)end
end
local function translateUI()
 if not Library or not Library.ScreenGui then return end
 for _,obj in ipairs(Library.ScreenGui:GetDescendants())do
  if obj:IsA("TextLabel")or obj:IsA("TextButton")then
   local nextText=cfg.language=="en-US"and ptToEn[obj.Text]or enToPt[obj.Text]
   if nextText then pcall(function()obj.Text=nextText end)end
  end
 end
 status(lastPT,lastEN)
end

local savedSettings,savedAnimations,savedAmmo,savedRates={},{},{},{}
local settingKeys={"VRecoil","HRecoil","VPunchBase","HPunchBase","DPunchBase","RecoilPunch","AimRecover","MinRecoilPower","RecoilPowerStepAmount","PunchRecover","MinSpread","Ammo","Mode"}
local zeroRecoil={VRecoil={0,0},HRecoil={0,0},VPunchBase=0,HPunchBase=0,DPunchBase=0,RecoilPunch=0,AimRecover=0,MinRecoilPower=0,RecoilPowerStepAmount=0,PunchRecover=0}
local fastcast,oldFire,ourFire=nil,nil,nil
local cachedTarget=nil
local function guns()
 local conf=RS:FindFirstChild("Configurations")
 return conf and conf:FindFirstChild("ACS_Guns")
end
local function requireModule(module)
 if not module or not module:IsA("ModuleScript")then return nil end
 local ok,val=pcall(require,module)
 return ok and type(val)=="table"and val or nil
end
local function unlock(tab)
 if type(setreadonly)=="function"then pcall(setreadonly,tab,false)end
end
local function lock(tab)
 if type(setreadonly)=="function"then pcall(setreadonly,tab,true)end
end
local function put(tab,key,value)pcall(function()tab[key]=value end)end
local function gunPatch(folder)
 local sm=folder:FindFirstChild("Settings")
 local am=folder:FindFirstChild("Animations")
 local s=requireModule(sm)
 local a=requireModule(am)
 if s and not savedSettings[sm]then
  local copy={}
  for _,k in ipairs(settingKeys)do copy[k]=s[k]end
  savedSettings[sm]={ref=s,values=copy}
 end
 if a and not savedAnimations[am]then
  savedAnimations[am]={ref=a,values={
   ReloadAnim=a.ReloadAnim,ChamberAnim=a.ChamberAnim,ShellInsertAnim=a.ShellInsertAnim,
  }}
 end
 if s and savedSettings[sm]then
  local orig=savedSettings[sm].values
  unlock(s)
  for k,v in pairs(zeroRecoil)do put(s,k,cfg.no_recoil and v or orig[k])end
  put(s,"MinSpread",cfg.no_spread and 0 or orig.MinSpread)
  put(s,"Ammo",cfg.inf_ammo and 999999 or orig.Ammo)
  lock(s)
 end
 if a and savedAnimations[am]then
  local orig=savedAnimations[am].values
  local noop=function()end
  local closure=type(newcclosure)=="function"and newcclosure or function(fn)return fn end
  unlock(a)
  put(a,"ReloadAnim",cfg.no_reload and closure(noop)or orig.ReloadAnim)
  local mode=s and s.Mode
  put(a,"ChamberAnim",cfg.no_bolt and (mode=="Bolt-Action"or mode=="Pump-Action")and closure(noop)or orig.ChamberAnim)
  put(a,"ShellInsertAnim",cfg.no_bolt and mode=="Pump-Action"and closure(noop)or orig.ShellInsertAnim)
  lock(a)
 end
 local ammo=folder:FindFirstChild("Ammo")
 if ammo and ammo:IsA("NumberValue")then
  if savedAmmo[ammo]==nil then savedAmmo[ammo]=ammo.Value end
  pcall(function()ammo.Value=cfg.inf_ammo and 999999 or savedAmmo[ammo]end)
 end
end
local function patchGuns()
 local folder=guns()
 if not folder then return false end
 for _,gun in ipairs(folder:GetChildren())do
  if gun:IsA("Folder")or gun:IsA("Model")then
   local ok,err=pcall(gunPatch,gun)
   if not ok then log("PATCH_ERROR",err)end
  end
 end
 return true
end
local function patchTool(tool)
 if not tool:IsA("Tool")then return end
 if not savedRates[tool]then savedRates[tool]={original=tool:GetAttribute("FireRate")}end
 pcall(function()tool:SetAttribute("FireRate",cfg.firerate_enabled and 9999999 or savedRates[tool].original)end)
end
local function patchRates()
 local backpack=player:FindFirstChildOfClass("Backpack")
 for _,obj in ipairs(backpack and backpack:GetChildren()or {})do patchTool(obj)end
 local character=player.Character
 for _,obj in ipairs(character and character:GetChildren()or {})do patchTool(obj)end
end
local function refresh()
 patchGuns()
 patchRates()
end
local function target()
 if not cfg.enabled then cachedTarget=nil return end
 local camera=workspace.CurrentCamera
 if not camera then cachedTarget=nil return end
 local mouse=UIS:GetMouseLocation()
 if UIS.TouchEnabled and not UIS.MouseEnabled then mouse=camera.ViewportSize/2 end
 local nearest,limit=nil,cfg.fov_radius
 for _,p in ipairs(Players:GetPlayers())do
  if p~=player and (not cfg.team_check or player.Team==nil or p.Team~=player.Team)then
   local character=p.Character
   local hum=character and character:FindFirstChildOfClass("Humanoid")
   local part=character and (character:FindFirstChild(cfg.target_part)or character:FindFirstChild("Head"))
   if hum and hum.Health>0 and part and part:IsA("BasePart")then
    local projected=part.Position+part.AssemblyLinearVelocity*cfg.prediction
    local screen,visible=camera:WorldToViewportPoint(projected)
    if visible and screen.Z>0 then
     local d=(Vector2.new(screen.X,screen.Y)-mouse).Magnitude
     if d<limit then nearest=part limit=d end
    end
   end
  end
 end
 cachedTarget=nearest
end
local function hookFastcast()
 local bullet=RS:FindFirstChild("BulletFireSystem")
 local mod=bullet and bullet:FindFirstChild("FastCastRedux")
 local tbl=requireModule(mod)
 if not tbl or type(tbl.Fire)~="function"then return false end
 fastcast=tbl oldFire=tbl.Fire
 local closure=type(newcclosure)=="function"and newcclosure or function(fn)return fn end
 ourFire=closure(function(...)
  local args={...}
  if cfg.bullet_speed_enabled then args[4]=cfg.bullet_speed end
  if cfg.bullet_distance_enabled then
   local behavior=args[5]
   if not behavior and type(tbl.newBehavior)=="function"then
    behavior=tbl.newBehavior()
    args[5]=behavior
   end
   if behavior then pcall(function()
    behavior.Acceleration=Vector3.zero
    behavior.MaxDistance=cfg.bullet_distance
   end)end
  end
  local part=cachedTarget
  if cfg.enabled and part and part.Parent and math.random()<=cfg.hit_chance and typeof(args[2])=="Vector3"then
   local delta=(part.Position+part.AssemblyLinearVelocity*cfg.prediction)-args[2]
   if delta.Magnitude>0.01 then args[3]=delta.Unit end
  end
  return oldFire(table.unpack(args))
 end)
 local ok,err=pcall(function()tbl.Fire=ourFire end)
 if not ok then
  log("FASTCAST",err)
  fastcast=nil oldFire=nil ourFire=nil
  return false
 end
 return true
end
local function restore()
 for _,b in pairs(savedSettings)do
  unlock(b.ref)
  for k,v in pairs(b.values)do put(b.ref,k,v)end
  lock(b.ref)
 end
 for _,b in pairs(savedAnimations)do
  unlock(b.ref)
  for k,v in pairs(b.values)do put(b.ref,k,v)end
  lock(b.ref)
 end
 for obj,value in pairs(savedAmmo)do
  if obj.Parent then pcall(function()obj.Value=value end)end
 end
 for tool,copy in pairs(savedRates)do
  if tool.Parent then pcall(function()tool:SetAttribute("FireRate",copy.original)end)end
 end
 if fastcast and oldFire and fastcast.Fire==ourFire then pcall(function()fastcast.Fire=oldFire end)end
end
local function unload()
 if not alive then return end
 alive=false
 cfg.enabled=false
 for _,c in ipairs(conns)do pcall(function()c:Disconnect()end)end
 conns={}
 restore()
 if env.PVH_WarTycoonUnload==unload then env.PVH_WarTycoonUnload=nil end
 if env.PVH_WarTycoonDiagnostics then env.PVH_WarTycoonDiagnostics=nil end
 if env.Library==Library then env.Library=nil end
 if audio then pcall(function()audio:Destroy()end)end
 if Library and not Library.Unloaded then pcall(function()Library:Unload()end)end
 log("UNLOAD","local state restored")
end
env.PVH_WarTycoonUnload=unload
env.PVH_WarTycoonDiagnostics=function()
 local g=guns()
 return {ACS=g~=nil,gunCount=g and #g:GetChildren()or 0,
  FastCast=fastcast~=nil,UI=Library~=nil and not Library.Unloaded,
  effects="server unverified"}
end

local libURL="https://raw.githubusercontent.com/deividcomsono/Obsidian/82d402b5de7d8903915f1afe99b5b7e340e7cd28/Library.lua"
local loaded,result=pcall(function()
 local fn,err=loadstring(game:HttpGet(libURL))
 if not fn then error(err)end
 return fn()
end)
if not loaded or type(result)~="table"or type(result.CreateWindow)~="function"then
 unload()
 error("[PVH War Tycoon] Obsidian unavailable: "..tostring(result),0)
end
Library=result
env.Library=Library
Library.ShowCustomCursor=false
local Window=Library:CreateWindow({
 Title="Prime Void Hub",Footer="War Tycoon | "..VERSION,
 Center=true,AutoShow=true,Resizable=true,Size=UDim2.fromOffset(770,540),
 ToggleKeybind=Enum.KeyCode.RightControl,ShowCustomCursor=false,
 NotifySide="Right",MinSidebarWidth=140,EnableCompacting=true,SidebarCompactWidth=48,
 Animations={ToggleWindow=cfg.uiAnimations,TabSwitch=cfg.uiAnimations,
  Groupbox=cfg.uiAnimations,Dropdown=cfg.uiAnimations,KeyPicker=cfg.uiAnimations},
})
-- Obsidian has a global InputBegan listener; Unknown would match every mouse click.
Library.ToggleKeybind=nil
local Home=Window:AddTab(T("Início","Home"),"house")
local Combat=Window:AddTab(T("Combate","Combat"),"crosshair")
local Weapons=Window:AddTab(T("Armas","Weapons"),"target")
local Settings=Window:AddTab(T("Configurações","Settings"),"settings")
local function group(tab,pt,en,side,icon)
 return tab:AddGroupbox({Name=T(pt,en),Side=side,IconName=icon})
end
local account=group(Home,"Conta","Account","Left","user-round")
account:AddLabel(player.DisplayName.." (@"..player.Name..")",true)
account:AddLabel("UserId: "..tostring(player.UserId),true)
account:AddLabel("PlaceId: "..tostring(game.PlaceId),true)
local session=group(Home,"Estado da sessão","Session status","Left","activity")
uiStatus=session:AddLabel(T(lastPT,lastEN),true)
local roster=group(Home,"Jogos suportados","Supported games","Right","gamepad-2")
roster:AddLabel("Ride Storm • HUNTRESS • Steal An Exu",true)
roster:AddLabel("Destruction Simulator • Don't Splash • Grau SP",true)
roster:AddLabel("Clover Legends • RIVALS • Steal a Brainrot",true)
roster:AddLabel("War Tycoon • "..VERSION,true)
local community=group(Home,"Comunidade","Community","Right","message-circle")
community:AddButton({Text=T("Copiar Discord","Copy Discord"),Func=function()
 playSound()
 if type(setclipboard)=="function" and pcall(setclipboard,"https://discord.gg/PD3PeyG8aq")then
  notify("Link copiado.","Link copied.")
 else notify("Área de transferência indisponível.","Clipboard unavailable.")end
end})

local aim=group(Combat,"Aimbot","Aimbot","Left","crosshair")
aim:AddToggle("PVWT_Aimbot",{Text=T("Aimbot","Aimbot"),Default=cfg.enabled,
 Callback=function(v)cfg.enabled=v==true;savePrefs()end})
aim:AddToggle("PVWT_TeamCheck",{Text=T("Ignorar aliados","Ignore teammates"),
 Default=cfg.team_check,Callback=function(v)cfg.team_check=v==true;savePrefs()end})
aim:AddDropdown("PVWT_Target",{Text=T("Parte do corpo","Target part"),
 Values={"Head","UpperTorso","HumanoidRootPart"},Default=cfg.target_part,
 Callback=function(v)cfg.target_part=v;savePrefs()end})
aim:AddSlider("PVWT_FOV",{Text="FOV",Default=cfg.fov_radius,Min=30,Max=600,Rounding=0,
 Callback=function(v)cfg.fov_radius=v;savePrefs()end})
aim:AddSlider("PVWT_Prediction",{Text=T("Predição","Prediction"),Default=cfg.prediction*1000,
 Min=0,Max=500,Rounding=0,Callback=function(v)cfg.prediction=v/1000;savePrefs()end})
aim:AddSlider("PVWT_HitChance",{Text=T("Chance de acerto (%)","Hit chance (%)"),
 Default=cfg.hit_chance*100,Min=0,Max=100,Rounding=0,
 Callback=function(v)cfg.hit_chance=v/100;savePrefs()end})

local mods=group(Weapons,"Modificações","Modifications","Left","wrench")
local function gunToggle(id,pt,en,key)
 mods:AddToggle(id,{Text=T(pt,en),Default=cfg[key],Callback=function(v)
  cfg[key]=v==true;refresh();savePrefs()
 end})
end
gunToggle("PVWT_NoRecoil","Sem recoil","No recoil","no_recoil")
gunToggle("PVWT_NoSpread","Sem spread","No spread","no_spread")
gunToggle("PVWT_Ammo","Munição infinita","Infinite ammo","inf_ammo")
gunToggle("PVWT_NoReload","Sem recarga","No reload","no_reload")
gunToggle("PVWT_NoBolt","Sem bolt/pump","No bolt/pump","no_bolt")
gunToggle("PVWT_FireRate","Cadência aumentada","Faster fire rate","firerate_enabled")
local bullets=group(Weapons,"Projéteis","Projectiles","Right","zap")
bullets:AddToggle("PVWT_BSpeed",{Text=T("Velocidade personalizada","Custom bullet speed"),
 Default=cfg.bullet_speed_enabled,Callback=function(v)cfg.bullet_speed_enabled=v==true;savePrefs()end})
bullets:AddSlider("PVWT_BSpeedValue",{Text=T("Velocidade do projétil","Bullet speed"),
 Default=cfg.bullet_speed,Min=1000,Max=99999,Rounding=0,
 Callback=function(v)cfg.bullet_speed=v;savePrefs()end})
bullets:AddToggle("PVWT_Distance",{Text=T("Distância personalizada","Custom bullet distance"),
 Default=cfg.bullet_distance_enabled,Callback=function(v)cfg.bullet_distance_enabled=v==true;savePrefs()end})
bullets:AddSlider("PVWT_DistanceValue",{Text=T("Alcance do projétil","Bullet range"),
 Default=cfg.bullet_distance,Min=1000,Max=99999,Rounding=0,
 Callback=function(v)cfg.bullet_distance=v;savePrefs()end})

local universal=group(Settings,"Sessão","Session","Left","save")
local persistence=env.PVH_Persistence
if type(persistence)=="table" and type(persistence.Bind)=="function" then
 pcall(function()persistence:Bind(universal)end)
end
local controls=group(Settings,"Controles","Controls","Left","keyboard")
env.PVH_SettingsPolish=controls
local min=controls:AddButton({Text=T("Minimizar o hub","Minimize hub"),Func=function()
 playSound();if Library then pcall(function()Library:Toggle()end)end
end})
min:AddKeyPicker("PVWT_KeyMinimize",{Text=T("Minimizar","Minimize"),
 Default=cfg.minimizeKey,Mode="Press",SyncToggleState=false,
 ChangedCallback=function(k)
  if k==nil then cfg.minimizeKey="None"
  elseif typeof(k)=="EnumItem" and k.EnumType==Enum.KeyCode
   and k~=Enum.KeyCode.Unknown then cfg.minimizeKey=k.Name end
  savePrefs()
 end})
local unloadBtn=controls:AddButton({Text=T("Descarregar o hub","Unload hub"),Func=unload})
unloadBtn:AddKeyPicker("PVWT_KeyUnload",{Text=T("Descarregar","Unload"),
 Default=cfg.unloadKey,Mode="Press",SyncToggleState=false,
 ChangedCallback=function(k)
  if k==nil then cfg.unloadKey="None"
  elseif typeof(k)=="EnumItem" and k.EnumType==Enum.KeyCode
   and k~=Enum.KeyCode.Unknown then cfg.unloadKey=k.Name end
  savePrefs()
 end})
controls:AddToggle("PVWT_KeyPanel",{Text=T("Mostrar atalhos","Show keybinds"),
 Default=cfg.showKeybinds,Callback=function(v)
  cfg.showKeybinds=v==true
  if Library.KeybindFrame then Library.KeybindFrame.Visible=cfg.showKeybinds end
  savePrefs()
 end})
local appearance=group(Settings,"Aparência","Appearance","Right","palette")
appearance:AddDropdown("PVWT_Language",{Text=T("Idioma","Language"),Values={"pt-BR","en-US"},
 Default=cfg.language,Callback=function(v)
  if v~="pt-BR"and v~="en-US"then return end
  cfg.language=v;savePrefs();task.defer(translateUI)
 end})
appearance:AddToggle("PVWT_Animations",{Text=T("Animações","Animations"),
 Default=cfg.uiAnimations,Callback=function(v)
  cfg.uiAnimations=v==true
  if Library and type(Library.Animations)=="table"then
   for key in pairs(Library.Animations)do Library.Animations[key]=cfg.uiAnimations end
  end
  savePrefs()
 end})
appearance:AddToggle("PVWT_Sounds",{Text=T("Sons","Sounds"),
 Default=cfg.uiSounds,Callback=function(v)cfg.uiSounds=v==true;savePrefs()end})
if Library.KeybindMenu then pcall(function()Library.KeybindMenu:SetVisibilityControl(true)end)end
if Library.KeybindFrame then Library.KeybindFrame.Visible=cfg.showKeybinds end
Library:OnUnload(function()if alive then unload()end end)
audio=Instance.new("Sound")
audio.Name="PVH_WarTycoon_Click" audio.SoundId="rbxassetid://10066942189"
audio.Volume=0.13 audio.Parent=SoundService
-- Obsidian's Button keypickers already execute the buttons in Press mode.
-- Avoid a second InputBegan listener, which would minimize and restore instantly.
track(player.CharacterAdded:Connect(function()if cfg.firerate_enabled then task.defer(patchRates)end end))
local backpack=player:FindFirstChildOfClass("Backpack")
if backpack then track(backpack.ChildAdded:Connect(function(obj)
 if alive and cfg.firerate_enabled then patchTool(obj)end
end))end
local timeAcc=0
track(RunService.Heartbeat:Connect(function(dt)
 if not alive then return end
 timeAcc+=dt
 if timeAcc<3 then return end
 timeAcc=0
 if cfg.no_recoil or cfg.no_spread or cfg.inf_ammo or cfg.no_reload or cfg.no_bolt then patchGuns()end
 if cfg.firerate_enabled then patchRates()end
end))
track(RunService.RenderStepped:Connect(function()
 if alive and cfg.enabled then target()else cachedTarget=nil end
end))
local hookOK=hookFastcast()
refresh()
status(hookOK and "War Tycoon ativo • FastCast detectado"or "War Tycoon ativo • FastCast indisponível",
 hookOK and "War Tycoon ready • FastCast detected"or "War Tycoon ready • FastCast unavailable")
log("BOOT","v0.1.0 | place="..tostring(game.PlaceId).." | ACS="..tostring(guns()~=nil).." | FastCast="..tostring(hookOK))
