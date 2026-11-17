-- Prime Void Hub | Fluent -> Obsidian compatibility for VINQ SB
-- Visible UI is native PVH Obsidian. Only the game's callbacks are forwarded.
return function(spec)
    assert(type(spec)=='table' and tonumber(spec.placeId)==tonumber(game.PlaceId),
        '[PVH VINQ] Unsupported game')
    local bridgeUrl='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/PVH_LegacyPortBridge.lua'
    local code=game:HttpGet(bridgeUrl)
    local makeBridge,err=loadstring(code)
    if not makeBridge then error('[PVH VINQ] Missing bridge: '..tostring(err),0) end
    local build=makeBridge()
    assert(type(build)=='function','[PVH VINQ] Bridge factory missing')
    local lib=build(spec)
    assert(type(lib)=='table' and type(lib.CreateWindow)=='function','[PVH VINQ] Obsidian unavailable')
    local ui={Options=lib.Options or {},Toggles=lib.Toggles or {}}
    local nativeWindow
    local idCounters={}
    local groups={}
    local function controlId(raw)
        local key=tostring(raw or 'control'):gsub('[^%w_]','_')
        if key=='' then key='control' end
        key='VINQ_'..key:sub(1,60)
        idCounters[key]=(idCounters[key] or 0)+1
        if idCounters[key]>1 then key=key..'_'..idCounters[key] end
        return key
    end
    local function safeLabel(value,default)
        if type(value)~='string' or value:gsub('%s','')=='' then return default or 'Opção' end
        return value
    end
    local function notify(title,body)
        if type(lib.Notify)=='function' then
            pcall(function()lib:Notify({Title=tostring(title or 'Prime Void Hub'),Description=tostring(body or ''),Time=6})end)
        else warn('[PVH VINQ] '..tostring(title or '')..': '..tostring(body or '')) end
    end
    local function makeSection(group)
        local section={}
        function section:AddToggle(rawId,o)
            o=type(o)=='table' and o or {}
            local title=safeLabel(o.Title or o.Text,tostring(rawId or 'Toggle'))
            local id=controlId(rawId)
            return group:AddToggle(id,{Text=title,Default=o.Default==true,Callback=function(v)
                if type(o.Callback)=='function' then o.Callback(v==true) end
            end})
        end
        function section:AddButton(o)
            o=type(o)=='table' and o or {Title=tostring(o)}
            return group:AddButton({Text=safeLabel(o.Title or o.Text,'Ação'),Func=function()
                if type(o.Callback)=='function' then o.Callback() end
            end})
        end
        function section:AddSlider(rawId,o)
            o=type(o)=='table' and o or {}
            return group:AddSlider(controlId(rawId),{
                Text=safeLabel(o.Title or o.Text,tostring(rawId)),
                Min=tonumber(o.Min) or 0,Max=tonumber(o.Max) or 100,
                Default=tonumber(o.Default) or tonumber(o.Min) or 0,
                Rounding=tonumber(o.Rounding) or 0,
                Callback=function(v)if type(o.Callback)=='function' then o.Callback(v)end end,
            })
        end
        function section:AddDropdown(rawId,o)
            o=type(o)=='table' and o or {}
            return group:AddDropdown(controlId(rawId),{
                Text=safeLabel(o.Title or o.Text,tostring(rawId)),
                Values=o.Values or {},Default=o.Default,Multi=o.Multi==true,
                AllowNull=o.AllowNull==true,
                Callback=function(v)if type(o.Callback)=='function' then o.Callback(v)end end,
            })
        end
        function section:AddInput(rawId,o)
            o=type(o)=='table' and o or {}
            return group:AddInput(controlId(rawId),{
                Text=safeLabel(o.Title or o.Text,tostring(rawId)),
                Default=tostring(o.Default or ''),Placeholder=o.Placeholder or '',
                Numeric=o.Numeric==true,Finished=o.Finished==true,
                Callback=function(v)if type(o.Callback)=='function' then o.Callback(v)end end,
            })
        end
        function section:AddParagraph(o)
            o=type(o)=='table' and o or {Title=tostring(o)}
            local title=safeLabel(o.Title or o.Text,'Informação')
            local contents=tostring(o.Content or ''):sub(1,650)
            return group:AddLabel(title..(contents~='' and ' — '..contents or ''),true)
        end
        function section:AddSection(title)
            -- Keep a single compact PVH groupbox per legacy section; no nested UI.
            if title then pcall(function() group:AddLabel(tostring(title),true) end) end
            return section
        end
        return section
    end
    function ui:CreateWindow(_opts)
        if nativeWindow then error('[PVH VINQ] Window already initialized',0)end
        nativeWindow=lib:CreateWindow({Title='Prime Void Hub',Footer='Slap Battles | VINQ source | EXPERIMENTAL'})
        local window={}
        local side=false
        function window:AddTab(opts)
            opts=type(opts)=='table' and opts or {Title=tostring(opts)}
            local title=safeLabel(opts.Title,'Funções')
            local norm=title:lower():gsub('[^%w]','')
            local native
            if norm=='information' or norm=='info' or norm=='changelogs' then
                native=nativeWindow:AddTab('Home','house')
            elseif norm=='settings' or norm=='config' then
                native=nativeWindow:AddTab('Settings','settings')
            else
                native=nativeWindow:AddTab(title,opts.Icon or 'gamepad-2')
            end
            local key=tostring(title)
            if not groups[key] then
                side=not side
                groups[key]=native:AddGroupbox({Name=title,Side=side and 'Left' or 'Right',IconName=opts.Icon or 'gamepad-2'})
            end
            local group=groups[key]
            local section=makeSection(group)
            local tab={}
            for _,method in ipairs({'AddToggle','AddButton','AddSlider','AddDropdown','AddInput','AddParagraph'}) do
                tab[method]=function(_,...)return section[method](section,...)end
            end
            function tab:AddSection(name,config)
                local label=safeLabel(type(config)=='table' and config.Title or name,name)
                local child=native:AddGroupbox({Name=label,Side='Left',IconName='settings-2'})
                return makeSection(child)
            end
            return tab
        end
        function window:SelectTab(_) return end
        function window:Dialog(config)
            config=type(config)=='table' and config or {}
            local buttons=config.Buttons or {}
            notify(config.Title,config.Content)
            -- Never auto-confirm legacy actions. Render callbacks as explicit buttons
            -- so a potentially destructive 'Continue' requires a second user click.
            if #buttons==0 then return end
            local confirm=groups['PVH_Confirm']
            if not confirm then
                local tab=nativeWindow:AddTab('Confirmações','shield-alert')
                confirm=tab:AddGroupbox({Name='Confirmação de ações',Side='Left',IconName='shield-alert'})
                groups['PVH_Confirm']=confirm
            end
            for _,button in ipairs(buttons)do
                if type(button.Callback)=='function' then
                    confirm:AddButton({Text=tostring(config.Title or 'Ação')..' • '..tostring(button.Title or 'Confirmar'),
                        Risky=true,Func=button.Callback})
                end
            end
        end
        return window
    end
    function ui:Notify(o)
        o=type(o)=='table' and o or {Content=tostring(o)}
        notify(o.Title,o.Content or o.SubContent)
    end
    return ui
end