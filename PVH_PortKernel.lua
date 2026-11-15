-- Prime Void Hub | Portable Obsidian Kernel v0.1.0
-- Shared UI/state/diagnostics for individually reviewed game adapters.
-- Does not execute unknown scripts, request game currency, or infer gameplay success.
return function(spec)
    assert(type(spec)=='table' and type(spec.name)=='string' and type(spec.placeId)=='number', 'PVH kernel: invalid specification')
    assert(tonumber(game.PlaceId)==spec.placeId or (type(spec.universeId)=='number' and tonumber(game.GameId)==spec.universeId),'PVH kernel: unsupported game')
    assert(type(spec.features)=='table','PVH kernel: features required')
    local Players=game:GetService('Players')
    local HTTP=game:GetService('HttpService')
    local VirtualUser=game:GetService('VirtualUser')
    local TeleportService=game:GetService('TeleportService')
    local player=Players.LocalPlayer
    assert(player,'PVH kernel: LocalPlayer unavailable')
    local env=(type(getgenv)=='function' and getgenv()) or _G
    local slug=tostring(spec.slug or spec.name):gsub('[^%w_-]','_')
    local PREFIX=tostring(spec.prefix or 'PVHGEN_')
    local ROOT='primevoid_hub/'..slug
    local CONFIG=ROOT..'/Configs/ui_settings.json'
    local PROFILE=ROOT..'/Configs/Profiles'
    local LOG=ROOT..'/Logs/PVH_'..slug..'_Events.txt'
    local active=true
    local conns={}
    local highlights={}
    local ui,window,statusLabel
    local replacements={}
    local failures={}
    local version=tostring(spec.version or 'v0.1.0')
    local cfg={language='pt-BR',animations=true,sounds=false,showKeybinds=false,
      minimizeKey='RightShift',unloadKey='Delete',antiAfk=false,playerESP=false,profileName='Default'}
    for _,o in ipairs(spec.options or {})do
        assert(type(o.id)=='string' and o.id:match('^[%w_]+$'),'PVH invalid option id')
        cfg[o.id]=o.default
    end
    for _,f in ipairs(spec.features)do
        assert(type(f.id)=='string' and f.id:match('^[%w_]+$'),'PVH invalid feature id')
        assert(type(f.run)=='function','PVH function missing for '..f.id)
        cfg[f.id]=false
    end
    local function T(pt,en)
        replacements[pt]=en
        return cfg.language=='en-US' and en or pt
    end
    local function track(c) if c then conns[#conns+1]=c end return c end
    local function mkdir(path)
        if type(makefolder)~='function' then return false end
        local cur=''
        for seg in path:gmatch('[^/]+')do
            cur=cur=='' and seg or (cur..'/'..seg)
            local ok,exists=pcall(function()return type(isfolder)=='function' and isfolder(cur)end)
            if not(ok and exists)then pcall(makefolder,cur)end
        end
        return true
    end
    local function log(kind,message)
        local line=os.date('!%Y-%m-%dT%H:%M:%SZ')..' ['..tostring(kind)..'] '..tostring(message or '')
        warn('[PVH '..spec.name..'] '..line)
        if type(writefile)=='function' then
            mkdir(ROOT..'/Logs')
            pcall(function()
                if type(appendfile)=='function' then appendfile(LOG,line..'\n')
                elseif type(isfile)=='function' and type(readfile)=='function' then
                    writefile(LOG,(isfile(LOG) and readfile(LOG) or '')..line..'\n')
                else writefile(LOG,line..'\n')end
            end)
        end
    end
    local function errorOnce(id,errorDetail)
        local at=os.clock()
        if not failures[id] or at-failures[id]>12 then
            failures[id]=at
            log('ERROR_'..id,tostring(errorDetail))
        end
    end
    local function safely(id,fn)
        local ok,result=pcall(fn)
        if not ok then errorOnce(id,result) end
        return ok,result
    end
    local function save(force)
        if not force and type(env.PVH_Persistence)=='table' and env.PVH_Persistence.AutoSave==false then return false end
        if type(writefile)~='function' then return false end
        mkdir(ROOT..'/Configs')
        return safely('SAVE',function()writefile(CONFIG,HTTP:JSONEncode(cfg))end)
    end
    local function read(path)
        if type(readfile)~='function' or type(isfile)~='function' then return nil end
        local ok,obj=pcall(function()
            if not isfile(path) then return nil end
            return HTTP:JSONDecode(readfile(path))
        end)
        return ok and type(obj)=='table' and obj or nil
    end
    local function applyValues(data)
        if type(data)~='table' then return false end
        for k,v in pairs(data)do
            if cfg[k]~=nil and type(cfg[k])==type(v)then cfg[k]=v end
        end
        if cfg.language~='en-US'then cfg.language='pt-BR'end
        return true
    end
    local autoSaveOn=type(env.PVH_Persistence)~='table' or env.PVH_Persistence.AutoSave~=false
    if autoSaveOn then applyValues(read(CONFIG))end
    local function profilePath()
        local name=tostring(cfg.profileName or 'Default'):gsub('[^%w_-]','_'):sub(1,48)
        if #name==0 then name='Default'end
        return PROFILE..'/'..name..'.json'
    end
    local function writeProfile(overwrite)
        if type(writefile)~='function' then log('PROFILE','write unavailable')return end
        local path=profilePath()
        if not overwrite and type(isfile)=='function' and isfile(path)then
            log('PROFILE','already exists: '..path)return
        end
        mkdir(PROFILE)
        safely('PROFILE_WRITE',function()writefile(path,HTTP:JSONEncode(cfg))end)
    end
    local function updateUI()
        if not ui then return end
        for _,f in ipairs(spec.features)do
            local node=ui.Toggles and ui.Toggles[PREFIX..f.id]
            if node then pcall(function()node:SetValue(cfg[f.id])end)end
        end
        for _,o in ipairs(spec.options or {})do
            local node=ui.Options and ui.Options[PREFIX..o.id]
            if node then pcall(function()node:SetValue(cfg[o.id])end)end
        end
        local t=ui.Toggles and ui.Toggles[PREFIX..'PlayerESP']
        if t then pcall(function()t:SetValue(cfg.playerESP)end)end
        local t2=ui.Toggles and ui.Toggles[PREFIX..'AntiAfk']
        if t2 then pcall(function()t2:SetValue(cfg.antiAfk)end)end
        local t3=ui.Toggles and ui.Toggles[PREFIX..'KeyPanel']
        if t3 then pcall(function()t3:SetValue(cfg.showKeybinds)end)end
    end
    local function loadProfile()
        local data=read(profilePath())
        if not data then log('PROFILE','not found '..profilePath())return end
        applyValues(data)
        updateUI()
        save(false)
        log('PROFILE','loaded '..profilePath())
    end
    local function deleteProfile()
        local path=profilePath()
        if type(delfile)=='function' and type(isfile)=='function' and isfile(path)then
            safely('PROFILE_DELETE',function()delfile(path)end)
        end
    end
    local function cleanESP()
        for char,h in pairs(highlights)do
            pcall(function()h:Destroy()end)
            highlights[char]=nil
        end
    end
    local function renderESP()
        if not cfg.playerESP then cleanESP()return end
        for _,p in ipairs(Players:GetPlayers())do
            if p~=player and p.Character and not highlights[p.Character]then
                local h=Instance.new('Highlight')
                h.Name='PVH_PlayerESP'
                h.FillTransparency=0.82
                h.OutlineTransparency=0
                h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                h.Adornee=p.Character
                h.Parent=p.Character
                highlights[p.Character]=h
            end
        end
        for char,h in pairs(highlights)do
            if not char.Parent then pcall(function()h:Destroy()end)highlights[char]=nil end
        end
    end
    local function unload()
        if not active then return end
        active=false
        for _,f in ipairs(spec.features)do
            if type(f.stop)=='function' then safely('STOP_'..f.id,function()f.stop()end)end
        end
        for _,conn in ipairs(conns)do pcall(function()conn:Disconnect()end)end
        cleanESP()
        if ui and not ui.Unloaded then pcall(function()ui:Unload()end)end
        if env.PVH_AdaptedUnload==unload then env.PVH_AdaptedUnload=nil end
        log('UNLOAD','stop completed')
    end
    if type(env.PVH_AdaptedUnload)=='function' then pcall(env.PVH_AdaptedUnload)end
    env.PVH_AdaptedUnload=unload
    local ctx={player=player,config=cfg,log=log,safe=safely,alive=function()return active end,
        fail=errorOnce,root=ROOT}
    if type(spec.setup)=='function' then
        local ok,err=pcall(spec.setup,ctx)
        if not ok then errorOnce('SETUP',err)end
    end
    local ok,lib=pcall(function()
        local code=game:HttpGet('https://raw.githubusercontent.com/deividcomsono/Obsidian/82d402b5de7d8903915f1afe99b5b7e340e7cd28/Library.lua')
        local run,err=loadstring(code)
        if not run then error(err)end
        return run()
    end)
    if not ok or type(lib)~='table' then
        unload()
        error('[PVH] Obsidian unavailable: '..tostring(lib),0)
    end
    ui=lib
    local Window=ui:CreateWindow({Title='Prime Void Hub | '..spec.name,Footer=version,
        NotifySide='Right',AutoShow=true,Center=true,Resizable=true,
        Size=UDim2.fromOffset(685,540),MinSidebarWidth=150,
        EnableCompacting=true,SidebarCompactWidth=48,
        Animations={ToggleWindow=cfg.animations,TabSwitch=cfg.animations,
            Groupbox=cfg.animations,Dropdown=cfg.animations,KeyPicker=cfg.animations}})
    window=Window
    ui.ToggleKeybind=nil
    env.Library=ui;env.Toggles=ui.Toggles;env.Options=ui.Options
    local home=Window:AddTab(T('Início','Home'),'house')
    local gameTab=Window:AddTab(T(spec.gameTabPT or 'Farm',spec.gameTabEN or 'Farm'),'zap')
    local visual=Window:AddTab(T('Visuais','Visuals'),'eye')
    local settings=Window:AddTab(T('Configurações','Settings'),'settings')
    local function g(tab,pt,en,side,icon)
        return tab:AddGroupbox({Name=T(pt,en),Side=side,IconName=icon})
    end
    local function scrolling(box,id,items,height)
        local frame=Instance.new('ScrollingFrame')
        frame.Name=id
        frame.BackgroundTransparency=1
        frame.BorderSizePixel=0
        frame.Size=UDim2.fromScale(1,1)
        frame.ScrollBarThickness=4
        frame.CanvasSize=UDim2.new()
        frame.AutomaticCanvasSize=Enum.AutomaticSize.Y
        local l=Instance.new('UIListLayout')
        l.Padding=UDim.new(0,6)
        l.SortOrder=Enum.SortOrder.LayoutOrder
        l.Parent=frame
        for i,info in ipairs(items)do
            local v=Instance.new('TextLabel')
            v.Name='Row'..i
            v.LayoutOrder=i
            v.BackgroundTransparency=1
            v.TextColor3=Color3.fromRGB(226,228,236)
            v.TextSize=12
            v.Font=Enum.Font.Gotham
            v.TextXAlignment=Enum.TextXAlignment.Left
            v.TextYAlignment=Enum.TextYAlignment.Top
            v.TextWrapped=true
            v.Size=UDim2.new(1,-12,0,0)
            v.AutomaticSize=Enum.AutomaticSize.Y
            v.Text='• '..T(info[1],info[2] or info[1])
            v.Parent=frame
        end
        box:AddUIPassthrough(id,{Instance=frame,Height=height})
    end
    local account=g(home,'Conta','Account','Left','user-round')
    local thumbOk,thumbnail=pcall(function()
        return Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.AvatarBust,Enum.ThumbnailSize.Size180x180)
    end)
    if thumbOk and type(thumbnail)=='string' then
        pcall(function()account:AddImage(PREFIX..'Avatar',{Image=thumbnail,Height=180})end)
    end
    account:AddLabel(player.DisplayName..' (@'..player.Name..')',true)
    account:AddLabel('UserId '..tostring(player.UserId)..' | PlaceId '..tostring(game.PlaceId),true)
    account:AddLabel(spec.name..' | '..version,true)
    local session=g(home,'Sessão','Session','Left','activity')
    statusLabel=session:AddLabel(T('Funções experimentais • servidor decide','Experimental features • server decides'),true)
    local games=g(home,'Ports disponíveis','Supported games','Right','gamepad-2')
    local names=type(env.PVH_SupportedGames)=='table' and env.PVH_SupportedGames or {spec.name}
    local items={}
    for _,name in ipairs(names)do items[#items+1]={name}end
    scrolling(games,PREFIX..'Games',items,145)
    local tipBox=g(home,'Dicas úteis','Useful tips','Right','lightbulb')
    scrolling(tipBox,PREFIX..'Tips',spec.tips or {{'Ative uma função por vez para testar.','Test one function at a time.'}},140)
    local support=g(home,'Suporte','Support','Left','message-circle')
    support:AddLabel(T('Discord Prime Void Hub','Prime Void Hub Discord'),true)
    support:AddButton({Text=T('Copiar convite','Copy invite'),Func=function()
        if type(setclipboard)=='function' then
            safely('CLIPBOARD',function()setclipboard('https://discord.gg/PD3PeyG8aq')end)
        end
    end})
    local groups={}
    local function target(section,side)
        local k=section or 'Farm'
        if groups[k] then return groups[k]end
        local group=g(gameTab,k,k,side or (next(groups) and 'Right' or 'Left'),'activity')
        groups[k]=group
        return group
    end
    for _,f in ipairs(spec.features)do
        local box=target(f.section or 'Farm',f.side)
        box:AddToggle(PREFIX..f.id,{Text=T(f.pt,f.en),Default=cfg[f.id],Callback=function(on)
            cfg[f.id]=on==true
            if not cfg[f.id] and type(f.stop)=='function' then safely('STOP_'..f.id,f.stop)end
            save(false)
        end})
    end
    for _,o in ipairs(spec.options or {})do
        local box=target(o.section or 'Farm',o.side)
        if o.kind=='Dropdown' then
            box:AddDropdown(PREFIX..o.id,{Text=T(o.pt,o.en),Values=o.values or {},
                Default=cfg[o.id],Callback=function(v)
                    cfg[o.id]=v;save(false)
                end})
        elseif o.kind=='Slider' then
            box:AddSlider(PREFIX..o.id,{Text=T(o.pt,o.en),Default=cfg[o.id],
                Min=o.min or 0,Max=o.max or 100,Rounding=o.rounding or 0,
                Callback=function(v)cfg[o.id]=v;save(false)end})
        end
    end
    local vbox=g(visual,'Jogadores','Players','Left','users')
    vbox:AddToggle(PREFIX..'PlayerESP',{Text=T('ESP jogadores','Player ESP'),Default=cfg.playerESP,
        Callback=function(v)cfg.playerESP=v==true;if not cfg.playerESP then cleanESP()end;save(false)end})
    local universal=g(settings,'Sessão','Session','Left','save')
    if type(env.PVH_Persistence)=='table' and type(env.PVH_Persistence.Bind)=='function' then
        safely('PERSISTENCE',function()env.PVH_Persistence:Bind(universal)end)
    else universal:AddLabel(T('Use o Loader universal para AutoSave/AutoExecute/Rejoin.',
        'Use the universal Loader for AutoSave/AutoExecute/Rejoin.'),true)end
    local ctrl=g(settings,'Controles','Controls','Left','settings-2')
    env.PVH_SettingsPolish=ctrl
    ctrl:AddButton({Text=T('Salvar configurações','Save settings'),Func=function()save(true)end})
    ctrl:AddButton({Text=T('Carregar configurações','Load settings'),Func=function()
        local d=read(CONFIG);if d then applyValues(d);updateUI();log('CONFIG','loaded')end
    end})
    ctrl:AddToggle(PREFIX..'AntiAfk',{Text='Anti-AFK',Default=cfg.antiAfk,
        Callback=function(on)cfg.antiAfk=on==true;save(false)end})
    local min=ctrl:AddButton({Text=T('Minimizar hub','Minimize hub'),Func=function()
        if ui and type(ui.Toggle)=='function' then safely('MINIMIZE',function()ui:Toggle()end)end
    end})
    min:AddKeyPicker(PREFIX..'Minimize',{Text=T('Minimizar','Minimize'),Default=cfg.minimizeKey,
        Mode='Press',Callback=function(v)cfg.minimizeKey=typeof(v)=='EnumItem' and v.Name or tostring(v);save(false)end})
    local exit=ctrl:AddButton({Text=T('Descarregar Hub','Unload hub'),Risky=true,Func=unload})
    exit:AddKeyPicker(PREFIX..'Unload',{Text=T('Descarregar','Unload'),Default=cfg.unloadKey,
        Mode='Press',Callback=function(v)cfg.unloadKey=typeof(v)=='EnumItem' and v.Name or tostring(v);save(false)end})
    ctrl:AddToggle(PREFIX..'KeyPanel',{Text=T('Mostrar atalhos','Show keybinds'),Default=cfg.showKeybinds,
        Callback=function(on)
            cfg.showKeybinds=on==true
            if ui.KeybindFrame then ui.KeybindFrame.Visible=cfg.showKeybinds end
            save(false)
        end})
    if ui.KeybindFrame then ui.KeybindFrame.Visible=cfg.showKeybinds end
    local profiles=g(settings,'Perfis de configuração','Configuration profiles','Right','folder-open')
    profiles:AddInput(PREFIX..'ProfileName',{Text=T('Nome do perfil','Profile name'),Default=cfg.profileName,
        Finished=true,Callback=function(text)
            cfg.profileName=tostring(text or 'Default'):sub(1,48);save(false)
        end})
    profiles:AddButton({Text=T('Criar perfil','Create profile'),Func=function()writeProfile(false)end})
    profiles:AddButton({Text=T('Carregar perfil','Load profile'),Func=loadProfile})
    profiles:AddButton({Text=T('Sobrescrever perfil','Overwrite profile'),Func=function()writeProfile(true)end})
    profiles:AddButton({Text=T('Excluir perfil','Delete profile'),Risky=true,Func=deleteProfile})
    local appear=g(settings,'Aparência','Appearance','Right','palette')
    appear:AddDropdown(PREFIX..'Language',{Text=T('Idioma','Language'),Values={'pt-BR','en-US'},
        Default=cfg.language,Callback=function(v)
            if v~='pt-BR' and v~='en-US' then return end
            cfg.language=v;save(false)
            if ui and ui.ScreenGui then
                for _,node in ipairs(ui.ScreenGui:GetDescendants())do
                    if node:IsA('TextLabel') or node:IsA('TextButton')then
                        for pt,en in pairs(replacements)do
                            if v=='en-US' and node.Text==pt then node.Text=en
                            elseif v=='pt-BR' and node.Text==en then node.Text=pt end
                        end
                    end
                end
            end
        end})
    appear:AddToggle(PREFIX..'Animations',{Text=T('Animações','Animations'),Default=cfg.animations,
        Callback=function(on)
            cfg.animations=on==true
            if type(ui.Animations)=='table' then for k in pairs(ui.Animations)do ui.Animations[k]=cfg.animations end end
            save(false)
        end})
    appear:AddToggle(PREFIX..'Sounds',{Text=T('Sons','Sounds'),Default=cfg.sounds,
        Callback=function(on)cfg.sounds=on==true;save(false)end})
    local workspaceGroup=g(settings,'Workspace','Workspace','Right','folder')
    workspaceGroup:AddLabel('Configs: '..ROOT..'/Configs',true)
    workspaceGroup:AddLabel('Logs: '..ROOT..'/Logs',true)
    workspaceGroup:AddLabel('Profiles: '..PROFILE,true)
    if type(ui.OnUnload)=='function' then ui:OnUnload(unload)end
    track(player.Idled:Connect(function()
        if active and cfg.antiAfk then safely('AFK',function()
            VirtualUser:CaptureController();VirtualUser:ClickButton2(Vector2.new())
        end)end
    end))
    local last={}
    task.spawn(function()
        local lastESP=0
        while active do
            task.wait(0.15)
            local now=os.clock()
            for _,f in ipairs(spec.features)do
                if cfg[f.id] and (now-(last[f.id] or 0))>=math.max(0.3,tonumber(f.interval) or 1) then
                    last[f.id]=now
                    safely('RUN_'..f.id,function()f.run(ctx)end)
                end
            end
            if now-lastESP>=0.8 then
                lastESP=now
                safely('ESP',renderESP)
            end
        end
    end)
    local total=0
    if type(spec.check)=='function' then
        local ok,n=pcall(spec.check,ctx)
        total=ok and tonumber(n) or 0
    end
    log('BOOT','PlaceId='..game.PlaceId..' version='..version..' features='..#spec.features..' dependencies='..total)
    if statusLabel then pcall(function()
        statusLabel:SetText(T('Port experimental • '..#spec.features..' funções',
            'Experimental port • '..#spec.features..' features'))
    end)end
    return ctx
end