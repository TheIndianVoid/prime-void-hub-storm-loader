-- Prime Void Hub | legacy gameplay → native Obsidian adapter v0.2.0
-- Adaptation boundary: gameplay callbacks in the source are preserved; the source's
-- third-party interface and previous branding/config system are replaced here.
-- No game remote is executed by this UI adapter.
return function(spec)
    assert(type(spec)=='table' and type(spec.name)=='string' and type(spec.slug)=='string'
        and tonumber(spec.placeId), '[PVH Bridge] invalid port descriptor')
    local env=(type(getgenv)=='function' and getgenv()) or _G
    if tonumber(game.PlaceId)~=tonumber(spec.placeId) then
        error('[PVH Bridge] PlaceId incompatible for '..spec.name,0)
    end
    local Players=game:GetService('Players')
    local Http=game:GetService('HttpService')
    local VirtualUser=game:GetService('VirtualUser')
    local player=Players.LocalPlayer
    if not player then error('[PVH Bridge] LocalPlayer unavailable',0) end
    local libraryURL='https://raw.githubusercontent.com/deividcomsono/Obsidian/82d402b5de7d8903915f1afe99b5b7e340e7cd28/Library.lua'
    local data=game:HttpGet(libraryURL)
    local compiler,compileError=loadstring(data)
    if not compiler then error('[PVH Bridge] Obsidian dependency: '..tostring(compileError),0) end
    local lib=compiler()
    if type(lib)~='table' or type(lib.CreateWindow)~='function' then
        error('[PVH Bridge] native Obsidian unavailable',0)
    end
    local base='primevoid_hub/'..spec.slug
    local logPath=base..'/Logs/PVH_SourceBridge_Events.txt'
    local profilePath=base..'/Configs/Profiles'
    local configPath=base..'/Configs/ui_settings.json'
    local state={active=true,language='pt-BR',profileName='Default',animations=true,sounds=false,
        showKeybinds=false,antiAfk=false,minimizeKey='RightShift',unloadKey='Delete'}
    local hooks, seen, shown={}, {}, false
    local function mkdir(path)
        if type(makefolder)~='function' then return end
        local p=''
        for part in path:gmatch('[^/]+') do
            p=p=='' and part or (p..'/'..part)
            if type(isfolder)~='function' or not isfolder(p) then pcall(makefolder,p) end
        end
    end
    local function log(kind,detail)
        local message=os.date('!%Y-%m-%dT%H:%M:%SZ')..' ['..tostring(kind)..'] '..tostring(detail or '')
        warn('[PVH '..spec.name..'] '..message)
        if type(writefile)=='function' then
            mkdir(base..'/Logs')
            pcall(function()
                if type(appendfile)=='function' then appendfile(logPath,message..'\n')
                elseif type(readfile)=='function' and type(isfile)=='function' then
                    writefile(logPath,(isfile(logPath) and readfile(logPath) or '')..message..'\n')
                else writefile(logPath,message..'\n') end
            end)
        end
    end
    local function tr(pt,en) return state.language=='en-US' and en or pt end
    local function configSnapshot()
        local result={_pvhBridgeVersion=2,language=state.language,profileName=state.profileName,
            animations=state.animations,sounds=state.sounds,showKeybinds=state.showKeybinds,
            antiAfk=state.antiAfk,minimizeKey=state.minimizeKey,unloadKey=state.unloadKey,
            toggles={},options={}}
        for id,ctrl in pairs(lib.Toggles or {}) do
            if type(ctrl)=='table' and type(ctrl.Value)=='boolean' then result.toggles[tostring(id)]=ctrl.Value end
        end
        for id,ctrl in pairs(lib.Options or {}) do
            if type(ctrl)=='table' and (type(ctrl.Value)=='string' or type(ctrl.Value)=='number' or type(ctrl.Value)=='boolean') then
                result.options[tostring(id)]=ctrl.Value
            end
        end
        return result
    end
    local function writeConfig(path)
        if type(writefile)~='function' then return false end
        mkdir(path:match('^(.*)/[^/]*$') or base)
        local ok,err=pcall(function()writefile(path,Http:JSONEncode(configSnapshot()))end)
        if not ok then log('SAVE_ERROR',err) end
        return ok
    end
    local function readConfig(path)
        if type(isfile)~='function' or type(readfile)~='function' then return nil end
        local ok,v=pcall(function()
            if not isfile(path) then return nil end
            return Http:JSONDecode(readfile(path))
        end)
        return ok and type(v)=='table' and v or nil
    end
    local function applyConfig(saved)
        if type(saved)~='table' then return false end
        for key,value in pairs(saved) do
            if state[key]~=nil and type(value)==type(state[key]) then state[key]=value end
        end
        for id,value in pairs(saved.toggles or {}) do
            local obj=(lib.Toggles or {})[id]
            if type(obj)=='table' and type(obj.SetValue)=='function' and type(value)=='boolean' then
                pcall(function() obj:SetValue(value) end)
            end
        end
        for id,value in pairs(saved.options or {}) do
            local obj=(lib.Options or {})[id]
            if type(obj)=='table' and type(obj.SetValue)=='function' and type(value)==type(obj.Value) then
                pcall(function() obj:SetValue(value) end)
            end
        end
        return true
    end
    local function profileFile()
        local name=tostring(state.profileName or 'Default'):gsub('[^%w_-]','_'):sub(1,48)
        if name=='' then name='Default' end
        return profilePath..'/'..name..'.json'
    end
    local function unload()
        if not state.active then return end
        state.active=false
        for _,c in ipairs(hooks) do pcall(function()c:Disconnect()end)end
        if type(env.PVH_LegacyBridgeStop)=='function' and env.PVH_LegacyBridgeStop==unload then
            env.PVH_LegacyBridgeStop=nil
        end
        if lib and type(lib.Unload)=='function' and not lib.Unloaded then pcall(function()lib:Unload()end)end
        log('UNLOAD','Port closed')
    end
    if type(env.PVH_LegacyBridgeStop)=='function' then pcall(env.PVH_LegacyBridgeStop)end
    env.PVH_LegacyBridgeStop=unload
    local originalWindow=lib.CreateWindow
    local windowCreated=false
    lib.CreateWindow=function(self,options)
        if windowCreated then return originalWindow(self,options) end
        windowCreated=true
        local opts=type(options)=='table' and options or {}
        opts.Title='Prime Void Hub'
        opts.Footer=spec.name..' | '..tostring(spec.version or 'v0.1.0')..' | EXPERIMENTAL'
        opts.ShowCustomCursor=false
        opts.AutoShow=true
        opts.Center=true
        opts.Resizable=true
        opts.Size=UDim2.fromOffset(670,520)
        opts.ToggleKeybind=nil
        opts.MinSidebarWidth=150
        opts.EnableCompacting=true
        opts.SidebarCompactWidth=48
        local win=originalWindow(self,opts)
        local nativeTab=win.AddTab
        local home=nativeTab(win, tr('Início','Home'),'house')
        local settings=nativeTab(win,tr('Configurações','Settings'),'settings')
        local function group(tab,title,side,icon)
            return tab:AddGroupbox({Name=title,Side=side,IconName=icon})
        end
        local account=group(home,tr('Conta','Account'),'Left','user-round')
        local ok,avatar=pcall(function()
            return Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.AvatarBust,Enum.ThumbnailSize.Size180x180)
        end)
        if ok and type(avatar)=='string' then
            pcall(function()account:AddImage('PVHLB_Avatar',{Image=avatar,Height=175})end)
        end
        account:AddLabel(player.DisplayName..' (@'..player.Name..')',true)
        account:AddLabel('UserId: '..tostring(player.UserId)..' | PlaceId: '..tostring(game.PlaceId),true)
        local status=group(home,tr('Sessão','Session'),'Left','activity')
        status:AddLabel(spec.name..' | '..tostring(spec.version or 'v0.1.0')..' • EXPERIMENTAL',true)
        local supported=group(home,tr('Ports disponíveis','Available ports'),'Right','gamepad-2')
        local ports=type(env.PVH_SupportedGames)=='table' and env.PVH_SupportedGames or {spec.name}
        local list=Instance.new('ScrollingFrame')
        list.Name='PVH_SupportedGamesScroll'
        list.BackgroundTransparency=1
        list.BorderSizePixel=0
        list.ScrollBarThickness=5
        list.ScrollBarImageColor3=Color3.fromRGB(135,145,160)
        list.Size=UDim2.fromScale(1,1)
        list.ScrollingDirection=Enum.ScrollingDirection.Y
        list.AutomaticCanvasSize=Enum.AutomaticSize.Y
        local layout=Instance.new('UIListLayout')
        layout.Padding=UDim.new(0,5)
        layout.Parent=list
        for i,name in ipairs(ports) do
            local label=Instance.new('TextLabel')
            label.Name='Game'..tostring(i)
            label.LayoutOrder=i
            label.BackgroundTransparency=1
            label.Text=tostring(name)
            label.TextWrapped=true
            label.TextSize=12
            label.TextColor3=Color3.fromRGB(225,229,240)
            label.Font=Enum.Font.Gotham
            label.TextXAlignment=Enum.TextXAlignment.Left
            label.Size=UDim2.new(1,-12,0,19)
            label.Parent=list
        end
        pcall(function()supported:AddUIPassthrough('PVHLB_GamesScroll',{Instance=list,Height=160})end)
        local tips=group(home,tr('Dicas úteis','Useful tips'),'Right','lightbulb')
        tips:AddLabel(tr('Funções do jogo preservadas da source; confira os logs antes de confiar no resultado.',
            'Original gameplay callbacks are preserved; review logs before trusting effects.'),true)
        local community=group(home,tr('Suporte','Support'),'Left','message-circle')
        community:AddButton({Text=tr('Copiar convite Discord','Copy Discord invite'),Func=function()
            if type(setclipboard)=='function' then pcall(setclipboard,'https://discord.gg/PD3PeyG8aq')end
        end})
        local session=group(settings,tr('Sessão','Session'),'Left','save')
        if type(env.PVH_Persistence)=='table' and type(env.PVH_Persistence.Bind)=='function' then
            pcall(function()env.PVH_Persistence:Bind(session)end)
        else session:AddLabel(tr('AutoSave e AutoExecute disponíveis ao iniciar pelo loader.',
            'AutoSave and AutoExecute available through the universal loader.'),true)end
        env.PVH_SettingsPolish=group(settings,tr('Controles','Controls'),'Left','sliders-horizontal')
        local controls=env.PVH_SettingsPolish
        controls:AddButton({Text=tr('Minimizar Hub','Minimize hub'),Func=function()
            if type(lib.Toggle)=='function' then pcall(function()lib:Toggle()end)end
        end})
        local exit=controls:AddButton({Text=tr('Descarregar Hub','Unload hub'),Risky=true,Func=unload})
        pcall(function()exit:AddKeyPicker('PVHLB_UnloadKey',{Text='Unload',Default='Delete',Mode='Press',NoUI=true})end)
        controls:AddToggle('PVHLB_AntiAfk',{Text='Anti-AFK',Default=false,
            Callback=function(v)state.antiAfk=(v==true)end})
        controls:AddToggle('PVHLB_KeyPanel',{Text=tr('Mostrar atalhos','Show keybinds'),Default=false,
            Callback=function(v)
                state.showKeybinds=(v==true)
                if lib.KeybindFrame then lib.KeybindFrame.Visible=state.showKeybinds end
            end})
        local appearance=group(settings,tr('Aparência','Appearance'),'Right','palette')
        appearance:AddDropdown('PVHLB_Language',{Text=tr('Idioma','Language'),Values={'pt-BR','en-US'},Default=state.language,
            Callback=function(v)state.language=(v=='en-US' and v or 'pt-BR')end})
        appearance:AddToggle('PVHLB_Animations',{Text=tr('Animações','Animations'),Default=true,
            Callback=function(v)
                state.animations=(v==true)
                if type(lib.Animations)=='table' then
                    for k in pairs(lib.Animations)do lib.Animations[k]=state.animations end
                end
            end})
        appearance:AddToggle('PVHLB_Sounds',{Text=tr('Sons','Sounds'),Default=false,
            Callback=function(v)state.sounds=(v==true)end})
        local profiles=group(settings,tr('Perfis de configuração','Config profiles'),'Right','folder')
        profiles:AddInput('PVHLB_ProfileName',{Text=tr('Nome do perfil','Profile name'),Default='Default',
            Placeholder='Default',Callback=function(v)state.profileName=tostring(v)end})
        profiles:AddButton({Text=tr('Criar perfil','Create profile'),Func=function()
            local file=profileFile()
            if type(isfile)=='function' and isfile(file)then log('PROFILE','Already exists: '..file)
            else writeConfig(file)end
        end})
        profiles:AddButton({Text=tr('Carregar perfil','Load profile'),Func=function()
            local data=readConfig(profileFile())
            if not data then log('PROFILE','Profile missing') else applyConfig(data)end
        end})
        profiles:AddButton({Text=tr('Sobrescrever perfil','Overwrite profile'),Func=function()writeConfig(profileFile())end})
        profiles:AddButton({Text=tr('Excluir perfil','Delete profile'),Risky=true,Func=function()
            if type(delfile)=='function' then pcall(delfile,profileFile())end
        end})
        local filegroup=group(settings,'Workspace','Left','folder-open')
        filegroup:AddLabel('Configs: '..base..'/Configs',true)
        filegroup:AddLabel('Logs: '..base..'/Logs',true)
        filegroup:AddLabel('Profiles: '..profilePath,true)
        win.AddTab=function(self,name,...)
            local rawName=type(name)=='table' and tostring(name.Name or name.NameText or '') or tostring(name)
            local norm=rawName:lower():gsub('%s+','')
            if norm=='uisettings' or norm=='settings' or norm=='configurações' or norm=='configuracoes'
               or norm=='configuration' then return settings end
            if norm=='about' or norm=='sobre' or norm=='information' or norm=='info' then return home end
            if norm=='home' or norm=='início' or norm=='inicio' then return home end
            return nativeTab(self,name,...)
        end
        if type(lib.OnUnload)=='function' then lib:OnUnload(function()
            state.active=false
            for _,c in ipairs(hooks)do pcall(function()c:Disconnect()end)end
            log('LIB_UNLOAD','Obsidian unloaded')
        end)end
        hooks[#hooks+1]=player.Idled:Connect(function()
            if state.active and state.antiAfk then
                pcall(function()VirtualUser:CaptureController();VirtualUser:ClickButton2(Vector2.new())end)
            end
        end)
        -- Original feature controls are attached by original source after CreateWindow.
        -- AutoSave reads/restores them only when the original initialization is complete.
        task.spawn(function()
            task.wait(2.5)
            if not state.active then return end
            local persistence=env.PVH_Persistence
            if type(persistence)~='table' or persistence.AutoSave~=false then
                applyConfig(readConfig(configPath))
            end
            for id,control in pairs(lib.Toggles or {}) do
                if type(control)=='table' and type(control.OnChanged)=='function' then
                    local captured=tostring(id)
                    pcall(function()control:OnChanged(function(v)
                        if not state.active then return end
                        log('UI_TOGGLE',captured..'='..tostring(v))
                        local p=env.PVH_Persistence
                        if type(p)~='table' or p.AutoSave~=false then writeConfig(configPath)end
                    end)end)
                end
            end
            for id,control in pairs(lib.Options or {}) do
                if type(control)=='table' and type(control.OnChanged)=='function' then
                    local captured=tostring(id)
                    pcall(function()control:OnChanged(function()
                        if not state.active then return end
                        log('UI_OPTION',captured)
                        local p=env.PVH_Persistence
                        if type(p)~='table' or p.AutoSave~=false then writeConfig(configPath)end
                    end)end)
                end
            end
            log('UI_READY','Original game features registered; gameplay effects unverified')
        end)
        log('WINDOW','Native Obsidian UI mounted; PlaceId='..tostring(game.PlaceId))
        return win
    end
    env.Library=lib
    env.Toggles=lib.Toggles
    env.Options=lib.Options
    log('BOOT','Source-derived adapter '..tostring(spec.version or 'v0.1.0'))
    return lib
end