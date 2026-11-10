-- Prime Void Hub | Steal a Brainrot | Fatality -> Obsidian UI adapter v0.1
-- UI only. All gameplay callbacks remain in the original source.
-- Do not add descriptions beneath controls.
return function()
    local sharedEnv=(type(getgenv)=="function" and getgenv()) or _G
    if type(sharedEnv.PVBR_Unload)=="function" then pcall(sharedEnv.PVBR_Unload) end
    local lib=loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/82d402b5de7d8903915f1afe99b5b7e340e7cd28/Library.lua"))()
    lib.ShowCustomCursor=false
    local root=lib:CreateWindow({
        Title="Prime Void Hub",Footer="Steal a Brainrot | v0.1 TEST",
        Center=true,AutoShow=true,Resizable=true,Size=UDim2.fromOffset(665,510),
        ToggleKeybind=Enum.KeyCode.RightControl,MinSidebarWidth=150,
        EnableCompacting=true,SidebarCompactWidth=49,
        ShowCustomCursor=false,NotifySide="Right",
        Animations={ToggleWindow=false,TabSwitch=false,Groupbox=false,Dropdown=false,KeyPicker=false},
    })
    sharedEnv.Library=lib
    sharedEnv.Toggles=lib.Toggles
    sharedEnv.Options=lib.Options
    local nameToTab={
        ["RAGE:PLAYER"]="Misc",["RAGE:FISHING"]="Farm",
        ["RAGE:SILENT AIM"]="Combat",["RAGE:COMBAT"]="Combat",
        ["STEALER:STEALER"]="Farm",["STEALER:COMBAT STEALER"]="Combat",
        ["STEALER:DUEL HELPER"]="Farm",["STEALER:BRAINROT PURCHASE"]="Farm",
        ["VISUALS:PLAYER ESP"]="Visuals",["VISUALS:BASE VISUALS"]="Visuals",
        ["VISUALS:BASE BRAINROT SPAWNER"]="Fun",
        ["VISUALS:ROAD BRAINROT SPAWNER"]="Fun",
        ["VISUALS:BRAINROT ESP"]="Visuals",["VISUALS:TRAPS ESP"]="Visuals",
        ["VISUALS:BASE ESP"]="Visuals",["VISUALS:WORLD VISUALS"]="Visuals",
        ["SERVER:FINDER"]="Misc",["SERVER:SERVER EXPLOITS"]="Misc",
    }
    local namesPT={
        ["Home"]="Início",["Farm"]="Farm",["Combat"]="Combate",
        ["Visuals"]="Visuais",["Fun"]="Diversão",["Misc"]="Miscelânea",
        ["Settings"]="Configurações",["About"]="Sobre",
        ["PLAYER"]="Jogador",["FISHING"]="Pesca",
        ["SILENT AIM"]="Mira silenciosa",["COMBAT"]="Combate",
        ["STEALER"]="Roubo",["COMBAT STEALER"]="Defesa e combate",
        ["DUEL HELPER"]="Auxílio de duelo",
        ["PLAYER ESP"]="ESP de jogadores",["BASE VISUALS"]="Bases",
        ["BASE BRAINROT SPAWNER"]="Prévia de Brainrots na base",
        ["ROAD BRAINROT SPAWNER"]="Prévia na esteira",
        ["BRAINROT ESP"]="ESP de Brainrots",["TRAPS ESP"]="ESP de armadilhas",
        ["BASE ESP"]="ESP de bases",["WORLD VISUALS"]="Ambiente",
        ["BRAINROT PURCHASE"]="Compra automática",
        ["SERVER EXPLOITS"]="Servidor",["FINDER"]="Buscador",
        ["Speed"]="Velocidade",["AFK Auto-Fishing"]="Pesca automática AFK",
        ["Hit Circle (Aura)"]="Aura de ataque",
        ["Auto Grab"]="Coleta automática",["Auto Grab Radius"]="Raio de coleta",
        ["Auto Grab Priority"]="Prioridade de coleta",["Anti Ragdoll"]="Anti-queda",
        ["Auto Right Steal"]="Roubar pela direita",["Auto Left Steal"]="Roubar pela esquerda",
        ["Base Skin Changer"]="Aparência da base",
        ["Base Tracer"]="Rastro da base",["Base Highlight"]="Destacar base",
        ["Brainrot"]="Brainrot",["Mutation"]="Mutação",
        ["Trait 1"]="Característica 1",["Trait 2"]="Característica 2",["Trait 3"]="Característica 3",
        ["Preview Amount"]="Quantidade de prévias",["Spawn Preview"]="Criar prévia",
        ["Clear Previews"]="Limpar prévias",["Walk Speed"]="Velocidade de caminhada",
        ["Spawn on Road"]="Criar na esteira",["Clear Road Brainrots"]="Limpar esteira",
        ["Box ESP"]="Caixa ESP",["Name ESP"]="Nome ESP",["Health ESP"]="Vida ESP",
        ["Team ESP"]="Equipe ESP",["Tracers"]="Rastros",
        ["Skeleton ESP"]="Esqueleto ESP",["Held Item ESP"]="Item equipado ESP",
        ["Brainrot ESP"]="Brainrot ESP",["Highlight"]="Destaque",
        ["Money Per/s"]="Dinheiro por segundo",["Filter"]="Filtro",
        ["Most Expensive In Current Base"]="Mais valioso na base atual",
        ["Better Graphics"]="Melhorar gráficos",["Fullbright"]="Iluminação total",
        ["Time of Day"]="Horário do dia",["Silent Aim"]="Mira silenciosa",
        ["All Supported Weapons"]="Todas as armas compatíveis",["FOV Radius"]="Raio de mira",
        ["Medusa Counter"]="Contra-ataque Medusa",
        ["Invisible"]="Invisível",["Auto Kick On Steal"]="Sair ao roubar",
        ["Min Rarity to Kick"]="Raridade mínima para sair",
        ["Enable Brainrot Purchase"]="Compra automática de Brainrots",
        ["All Brainrots"]="Todos os Brainrots",
        ["Brainrot Filter"]="Filtro de Brainrots",["Rarity Filter"]="Filtro de raridade",
        ["Minimum /s"]="Mínimo por segundo",
        ["Sentry Destroyer"]="Destruir sentinelas",
        ["Fake Lag"]="Lag simulado",["Fake Lag Mode"]="Modo de lag",
        ["Low Poly"]="Baixa geometria",["Timer ESP"]="Tempo das bases ESP",
        ["Camera No Collision"]="Câmera sem colisão",
        ["Base Transparency"]="Transparência das bases",["Highlight Bases"]="Destacar bases",
        ["Highlight Most Expensive Base Owner"]="Destacar dono da base mais valiosa",
        ["Highlight Filter"]="Filtro de destaque",
        ["Enable Traps ESP"]="ESP de armadilhas",
        ["Trap Max Distance"]="Distância das armadilhas",
        ["Enable Finder"]="Ativar buscador",["Blacklist Add"]="Adicionar à lista de exclusão",
        ["Blacklist Remove"]="Remover da lista de exclusão",
        ["Priority"]="Prioridade",["Copy Server ID"]="Copiar ID do servidor",
        ["Server Hop"]="Trocar servidor",["Base Tracer Color"]="Cor dos rastros de bases",
        ["Base Highlight Color"]="Cor do destaque da base",
        ["Most Expensive Only"]="Mais valioso",["All"]="Todos",
    }
    local language="pt"
    local activeControls={}
    local tabs={}
    for _,entry in ipairs({
        {"Home","house"},{"Farm","wheat"},{"Combat","crosshair"},
        {"Visuals","eye"},{"Fun","sparkles"},{"Misc","wrench"},
        {"Settings","settings"},{"About","info"},
    }) do
        tabs[entry[1]]=root:AddTab(namesPT[entry[1]] or entry[1],entry[2])
    end
    local function tr(value)
        if language=="pt" then return namesPT[value] or value end
        return value
    end
    local groupCounts={}
    local function group(tab,name,side,icon)
        local token=tab..":"..name
        groupCounts[token]=(groupCounts[token] or 0)+1
        local title=tr(name)
        if groupCounts[token]>1 then title=title.." "..tostring(groupCounts[token]) end
        return tabs[tab]:AddGroupbox({
            Name=title,Side=side==2 and "Right" or "Left",
            IconName=icon or "square",DisableCollapsing=true,
        })
    end
    local function register(raw,name)
        local box={inner=raw,name=name}
        table.insert(activeControls,box)
        function box:SetDisabled(value)
            if self.inner and type(self.inner.SetDisabled)=="function" then
                return self.inner:SetDisabled(value and true or false)
            end
        end
        function box:SetName(value)
            self.name=value
            if self.inner and type(self.inner.SetText)=="function" then
                pcall(function()self.inner:SetText(tr(value))end)
            end
        end
        function box:Destroy()
            if self.inner and type(self.inner.Destroy)=="function" then
                pcall(function()self.inner:Destroy()end)
            end
        end
        return box
    end
    local function id(options,extra)
        local val=tostring(options.SaveKey or options.Name or "item")
        return "PVBR_"..val:gsub("[^%w_]","_")..(extra or "")
    end
    local LegacySection={}
    LegacySection.__index=LegacySection
    local function optionsList(src)
        local out={}
        if type(src)=="table" then
            for _,value in ipairs(src) do
                if type(value)=="string" or type(value)=="number" then
                    table.insert(out,tostring(value))
                end
            end
        end
        if #out==0 then out={"None"} end
        return out
    end
    local function multiSetToList(value)
        local arr,set={},{}
        if type(value)=="table" then
            for key,selected in pairs(value) do
                local v=(type(key)=="string" and selected==true) and key
                    or (type(selected)=="string" and selected or nil)
                if v and not set[v] then
                    set[v]=true
                    table.insert(arr,v)
                end
            end
        end
        return arr,set
    end
    function LegacySection:AddToggle(o)
        local handle=self.box:AddToggle(id(o),{
            Text=tr(o.Name),Default=o.Default==true,
            Callback=function(value)
                if type(o.Callback)=="function" then o.Callback(value) end
            end,
        })
        local wrapper=register(handle,o.Name)
        local parent=self
        function wrapper:AddColorPicker(colorOptions)
            return parent:AddColorPicker(colorOptions)
        end
        return wrapper
    end
    function LegacySection:AddSlider(o)
        local raw=self.box:AddSlider(id(o),{
            Text=tr(o.Name),Min=tonumber(o.Min) or 0,Max=tonumber(o.Max) or 100,
            Default=tonumber(o.Default) or 0,
            Rounding=tonumber(o.Precision) or 0,
            Suffix=tostring(o.Suffix or ""),
            Callback=function(v)
                if type(o.Callback)=="function" then o.Callback(v) end
            end,
        })
        return register(raw,o.Name)
    end
    function LegacySection:AddSliderToggle(o)
        local key=id(o)
        local sw=self.box:AddToggle(key.."_toggle",{
            Text=tr(o.Name),Default=o.DefaultToggle==true,
            Callback=function(value)
                if type(o.OnToggleChange)=="function" then o.OnToggleChange(value) end
            end,
        })
        self.box:AddSlider(key.."_value",{
            Text=tr(o.Name),Min=tonumber(o.Min) or 0,Max=tonumber(o.Max) or 100,
            Default=tonumber(o.Default) or 0,Rounding=tonumber(o.Precision) or 0,
            Suffix=tostring(o.Suffix or ""),
            Callback=function(v)
                if type(o.OnSliderChange)=="function" then o.OnSliderChange(v) end
            end,
        })
        return register(sw,o.Name)
    end
    function LegacySection:AddDropdown(o)
        local values=optionsList(o.Options)
        local raw=self.box:AddDropdown(id(o),{
            Text=tr(o.Name),Values=values,Default=o.Default or values[1],
            Multi=false,
            Callback=function(value)
                if type(o.Callback)=="function" then o.Callback(value) end
            end,
        })
        return register(raw,o.Name)
    end
    function LegacySection:AddMultiDropdown(o)
        local values=optionsList(o.Options)
        local defaults={}
        for _,value in ipairs(optionsList(o.Default)) do defaults[value]=true end
        local raw=self.box:AddDropdown(id(o),{
            Text=tr(o.Name),Values=values,Default=defaults,Multi=true,
            Callback=function(value)
                if type(o.Callback)=="function" then
                    local arr,set=multiSetToList(value)
                    o.Callback(arr,set)
                end
            end,
        })
        return register(raw,o.Name)
    end
    function LegacySection:AddColorPicker(o)
        local raw=self.box:AddLabel(tr(o.Name)):AddColorPicker(id(o),{
            Default=o.Default or Color3.new(1,1,1),
            Title=tr(o.Name),
            Callback=function(color)
                if type(o.Callback)=="function" then o.Callback(color) end
            end,
        })
        return register(raw,o.Name)
    end
    function LegacySection:AddButton(o)
        local raw=self.box:AddButton({
            Text=tr(o.Name),Func=function()
                if type(o.Callback)=="function" then o.Callback() end
            end,
        })
        return register(raw,o.Name)
    end
    local bridgeWindow={}
    function bridgeWindow:AddMenu(o)
        local menu={name=o.Name}
        function menu:AddSection(sectionOpts)
            local key=self.name..":"..sectionOpts.Name
            local tab=nameToTab[key] or "Misc"
            return setmetatable({
                box=group(tab,sectionOpts.Name,sectionOpts.Column,"square"),
            },LegacySection)
        end
        return menu
    end
    local homeUser=group("Home","Conta",1,"user")
    local player=game:GetService("Players").LocalPlayer
    homeUser:AddLabel("@"..tostring(player and player.Name or "Unknown"))
    homeUser:AddLabel("Steal a Brainrot | Prime Void Hub")
    local homePorts=group("Home","Jogos disponíveis",2,"gamepad-2")
    for _,name in ipairs({"Ride Storm","HUNTRESS","Steal An Exu",
        "Destruction Simulator","Don't Splash","Clover Legends","Steal a Brainrot"}) do
        homePorts:AddLabel("• "..name)
    end
    local actions=group("Misc","Servidor",2,"server")
    actions:AddButton({Text="Copiar ID do servidor",Func=function()
        if type(setclipboard)=="function" then setclipboard(game.JobId) end
    end})
    actions:AddButton({Text="Trocar servidor",Func=function()
        task.spawn(function()
            local http=game:GetService("HttpService")
            local tp=game:GetService("TeleportService")
            local nextCursor=nil
            local found=nil
            for attempt=1,4 do
                local url="https://games.roblox.com/v1/games/"..tostring(game.PlaceId)
                    .."/servers/Public?sortOrder=Asc&limit=100"
                if nextCursor then
                    url=url.."&cursor="..http:UrlEncode(nextCursor)
                end
                local ok,record=pcall(function()
                    return http:JSONDecode(game:HttpGet(url))
                end)
                if not ok or type(record)~="table" then break end
                for _,entry in ipairs(record.data or {}) do
                    if type(entry)=="table" and entry.id~=game.JobId
                        and (tonumber(entry.playing) or 999)>=0
                        and (tonumber(entry.playing) or 999)<(tonumber(entry.maxPlayers) or 0) then
                        found=entry.id
                        break
                    end
                end
                if found then break end
                nextCursor=record.nextPageCursor
                if type(nextCursor)~="string" or nextCursor=="" then break end
            end
            if found then
                local ok,err=pcall(function()
                    tp:TeleportToPlaceInstance(game.PlaceId,found,player)
                end)
                if not ok then warn("[PVBR] Server Hop: "..tostring(err)) end
            else
                warn("[PVBR] Server Hop: nenhum servidor diferente encontrado via API")
            end
        end)
    end})
    local settingsBox=group("Settings","Interface",1,"settings")
    local function updateLanguage(code)
        language=code
        for _,obj in ipairs(activeControls) do
            if obj.inner and type(obj.inner.SetText)=="function" then
                pcall(function()obj.inner:SetText(tr(obj.name))end)
            end
        end
    end
    settingsBox:AddDropdown("PVBR_Language",{
        Text="Idioma / Language",Values={"Português","English"},
        Default="Português",Callback=function(v)
            updateLanguage(v=="English" and "en" or "pt")
        end,
    })
    settingsBox:AddToggle("PVBR_Animations",{
        Text="Animações",Default=true,
        Callback=function(v)
            lib.Animations={
                ToggleWindow=v,TabSwitch=v,Groupbox=v,Dropdown=v,KeyPicker=v,
            }
        end,
    })
    settingsBox:AddToggle("PVBR_Sounds",{
        Text="Sons",Default=false,Callback=function() end,
    })
    local keys=group("Settings","Atalhos",2,"keyboard")
    keys:AddLabel("RightControl • Minimizar / Restaurar")
    keys:AddButton({Text="Minimizar",Func=function()
        pcall(function()lib:Toggle()end)
    end})
    keys:AddButton({Text="Descarregar Hub",Func=function()
        if type(sharedEnv.PVBR_Unload)=="function" then sharedEnv.PVBR_Unload() end
    end})
    local about=group("About","Prime Void Hub",1,"info")
    about:AddLabel("Steal a Brainrot | v0.1 TEST")
    about:AddLabel("PT-BR / EN-US")
    about:AddButton({Text="Comunidade Discord",Func=function()
        if type(setclipboard)=="function" then setclipboard("https://discord.gg/PD3PeyG8aq") end
    end})
    sharedEnv.PVBR_Unload=function()
        if lib and not lib.Unloaded then lib:Unload() end
    end
    local legacyLibrary={
        _beginControlSync=function()end,_endControlSync=function()end,
        LoadConfig=function()end,SaveConfig=function()end,
    }
    return legacyLibrary,bridgeWindow,lib
end