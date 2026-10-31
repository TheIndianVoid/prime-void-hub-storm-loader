-- Prime Void Hub | Universal Loader
local placeId=tonumber(game.PlaceId) or 0
local universeId=tonumber(game.GameId) or 0
local ports={
    {
        name='Storm Suite',
        version='v1.0.0',
        officialName='Ride Storm',
        placeIds={[12593620250]=true},
        universeIds={[4420562665]=true},
        url='https://prime-void-hub-storm-gateway.vercel.app/prime-void-hub.lua',
        markers={'SOURCE GITHUB v','local function setupInterfaceAndLoops()','Prime Void Hub - Storm Suite'},
    },
    {
        name='Huntress',
        officialName='HUNTRESS',
        version='v1.1.1',
        placeIds={[104259439179020]=true,[110394010715338]=true},
        universeIds={[10416475193]=true},
        url='https://prime-void-hub-huntress-gateway.vercel.app/huntress.lua',
        markers={'Prime Void Hub - Huntress','PVHuntressUnload','Library:CreateWindow'},
    },
    {
        name='Exu Security Lab',
        version='v1.1.2',
        officialName='Steal An Exu',
        placeIds={[103076400317371]=true},
        universeIds={},
        url='https://prime-void-hub-exu-gateway.vercel.app/exu-security-lab.lua',
        markers={'local rarityList=','Prime Void | Exu Security Lab'},
    },
    {
        name='Dont Splash Explorer',
        version='v0.1.2',
        officialName="Don't Splash",
        placeIds={[139386728420706]=true},
        universeIds={},
        url='https://prime-void-hub-splash-gateway.vercel.app/dont-splash.lua',
        markers={'-- Prime Void Hub - Dont Splash','PVDontSplashUnload','Library:CreateWindow'},
    },
}
local selected
for _,port in ipairs(ports) do
    if port.placeIds[placeId] or port.universeIds[universeId] then
        selected=port
        break
    end
end
-- Friendly unsupported-game dialog. Copying uses the executor clipboard when available.
-- If clipboard support is missing, show a selectable address instead of claiming success.
local function showUnsupportedGame()
    -- Use the same pinned Obsidian library as the supported Prime Void Hub ports.
    -- This UI does not execute a game port or change the supported-game roster.
    local gameLink='https://www.roblox.com/games/'..tostring(placeId)
    local discordLink='https://discord.gg/PD3PeyG8aq'
    local env=type(getgenv)=='function' and getgenv() or _G
    if type(env.PVH_UnsupportedUIUnload)=='function' then
        pcall(env.PVH_UnsupportedUIUnload)
    end

    local Library
    local ok,reason=pcall(function()
        local loaded,lib=pcall(function()
            return loadstring(game:HttpGet(
                'https://raw.githubusercontent.com/deividcomsono/Obsidian/82d402b5de7d8903915f1afe99b5b7e340e7cd28/Library.lua'
            ))()
        end)
        if not loaded or type(lib)~='table' then
            error('Biblioteca Obsidian indisponível: '..tostring(lib))
        end
        Library=lib
        Library.ShowCustomCursor=false

        local Window=Library:CreateWindow({
            Title='Prime Void Hub',
            Footer='Universal Loader | Jogo não suportado',
            Center=true,
            AutoShow=true,
            Resizable=true,
            Size=UDim2.fromOffset(600,390),
            ShowCustomCursor=false,
            ToggleKeybind=Enum.KeyCode.Unknown,
            NotifySide='Right',
            MinSidebarWidth=140,
            EnableCompacting=true,
            SidebarCompactWidth=48,
            Animations={
                ToggleWindow=false,TabSwitch=false,Groupbox=false,
                Dropdown=false,KeyPicker=false,
            },
        })
        local tab=Window:AddTab('Suporte','life-buoy')

        local details=tab:AddGroupbox({
            Side='Left',Name='Jogo não suportado',IconName='circle-alert',
            DisableCollapsing=true,
        })
        details:AddLabel('Este jogo ainda não é suportado pelo Prime Void Hub.',true)
        details:AddLabel('Quer sugerir um port? Envie o link do jogo em nosso Discord.',true)
        details:AddDivider()
        details:AddLabel('PlaceId: '..tostring(placeId),true)

        local links=tab:AddGroupbox({
            Side='Right',Name='Links e comunidade',IconName='link',
            DisableCollapsing=true,
        })
        local linkInput=links:AddInput('PVH_UnsupportedLink',{
            Text='Link para copiar',
            Default=gameLink,
            ClearTextOnFocus=false,
            ClearTextOnBlur=false,
            AllowEmpty=false,
            Finished=true,
        })
        local status=links:AddLabel('Use os botões abaixo ou copie o campo acima.',true)
        local function copyLink(url,successMessage)
            linkInput:SetValue(url)
            local clipboard=type(setclipboard)=='function' and setclipboard
                or (type(toclipboard)=='function' and toclipboard)
            if clipboard and pcall(clipboard,url) then
                status:SetText(successMessage)
            else
                status:SetText('Cópia indisponível: selecione o campo acima para copiar.')
            end
        end
        links:AddButton({
            Text='Copiar link do jogo',IconName='copy',
            Func=function()
                copyLink(gameLink,'Link do jogo copiado!')
            end,
        })
        links:AddButton({
            Text='Copiar Discord',IconName='message-circle',
            Func=function()
                copyLink(discordLink,'Convite do Discord copiado!')
            end,
        })
        links:AddDivider()
        links:AddButton({
            Text='Fechar',IconName='x',
            Func=function() Library:Unload() end,
        })

        local function unload()
            if Library and not Library.Unloaded then
                Library:Unload()
            end
        end
        env.PVH_UnsupportedUIUnload=unload
        Library:OnUnload(function()
            if env.PVH_UnsupportedUIUnload==unload then
                env.PVH_UnsupportedUIUnload=nil
            end
        end)
    end)
    if not ok then
        if Library and not Library.Unloaded then
            pcall(function() Library:Unload() end)
        end
        warn('[Prime Void Hub] Jogo não suportado | PlaceId='..tostring(placeId)
            ..' | UI Obsidian falhou: '..tostring(reason)
            ..' | Discord: '..discordLink)
        pcall(function()
            game:GetService('StarterGui'):SetCore('SendNotification',{
                Title='Prime Void Hub',
                Text='Jogo não suportado. Sugira este jogo no Discord!',
                Duration=8,
            })
        end)
    end
end
if not selected then
    showUnsupportedGame()
    return
end
local genv=type(getgenv)=='function' and getgenv() or _G
genv.PV_Hub_ActivePort=selected.name
local ok,source=pcall(function()
    return game:HttpGet(selected.url..'?t='..tostring(os.time()))
end)
if not ok or type(source)~='string' then
    error('[Prime Void Hub] Download falhou ('..selected.name..'): '..tostring(source),0)
end
for _,marker in ipairs(selected.markers) do
    if not source:find(marker,1,true) then
        error('[Prime Void Hub] Conteudo invalido ('..selected.name..'), source nao executada.',0)
    end
end
-- Canonical roster shared by all ports, including legacy gateway snapshots.
-- Adding a future route with officialName automatically extends the Home roster.
local officialNames={}
for _,port in ipairs(ports) do
    if type(port.officialName)=='string' and port.officialName~='' then
        officialNames[#officialNames+1]=port.officialName
    end
end
local quotedNames={}
for _,name in ipairs(officialNames) do
    quotedNames[#quotedNames+1]="'"..name:gsub("\\","\\\\"):gsub("'","\\'").."'"
end
local namesDeclaration="local supportedGames={"..table.concat(quotedNames,",").."}"
local function replaceLiteral(input,old,new)
    local at=input:find(old,1,true)
    if not at then return input end
    return input:sub(1,at-1)..new..input:sub(at+#old)
end
-- Compatibilidade com as duas interfaces publicadas antes do roster compacto.
local oldStorm=[=[homePorts:AddLabel(T('●  Storm Suite  •  Disponível','●  Storm Suite  •  Available'),true)
    homePorts:AddLabel('RSBK: Ride Storm',true)
    homePorts:AddLabel(T('Novos ports aparecerão aqui futuramente.','Future ports will be listed here.'),true)]=]
local oldExu=[=[homePorts:AddLabel(t('●  Storm Suite  •  Disponível','●  Storm Suite  •  Available'),true)
homePorts:AddLabel('RSBK: Ride Storm',true)
homePorts:AddLabel(t('●  Exu Security Lab  •  Disponível','●  Exu Security Lab  •  Available'),true)
homePorts:AddLabel('Roube um Exu (Steal an Exu)',true)
homePorts:AddLabel(t('2 ports • Loader universal ativo','2 ports • Universal loader active'),true)]=]
local stormLines,exuLines={},{}
for _,name in ipairs(officialNames) do
    local label="homePorts:AddLabel('🟢"..name:gsub("\\","\\\\"):gsub("'","\\'").."',true)"
    stormLines[#stormLines+1]=label
    exuLines[#exuLines+1]=label
end
local renderStorm=table.concat(stormLines,"\n    ")
local renderExu=table.concat(exuLines,"\n")
source=replaceLiteral(source,oldStorm,renderStorm)
source=replaceLiteral(source,oldExu,renderExu)
-- New-generation ports declare supportedGames and always inherit the latest names.
local at=source:find('local supportedGames={',1,true)
if at then
    local close=source:find('}',at,true)
    if close then
        source=source:sub(1,at-1)..namesDeclaration..source:sub(close+1)
    end
end
-- Exu Security Lab | UI-only final cleanup.
-- Applied at load-time so the already published gateway can remain untouched.
-- Each operation is an exact literal match; game logic and other ports are preserved.
if selected.name=='Exu Security Lab' then
    local replacements={
        {
            [=[farmFilters:AddLabel(t('Atacar jogadores permanece desativado.','Player combat remains disabled.'),true)]=],
            ''
        },
        {
            [=[farmProgression:AddLabel(t('A esteira usa o prompt Correr [E] original.','Treadmill uses the native Correr [E] prompt.'),true)]=],
            [=[farmProgression:AddLabel(t('A esteira usa o botão de interação [E] original.','The treadmill uses the original interaction button [E].'),true)]=]
        },
        {
            [=[farmProgression:AddLabel(t('Rebirth usa a interface nativa do jogo.','Rebirth uses the native game UI.'),true)]=],
            ''
        },
        {
            [=[miscWorld:AddLabel(t('A base é identificada pelo atributo PenName.','Your base is identified through PenName.'),true)]=],
            ''
        },
        {
            [=[miscSafety:AddLabel(t('HIT PLAYERS: congelado para investigação.','HIT PLAYERS: frozen pending review.'),true)]=],
            [=[miscSafety:AddLabel('Auto hit players: PATCHED',true)]=]
        },
        {
            [=[miscSafety:AddButton({Text=t('Diagnóstico: Step fora da esteira','Diagnostic: off-treadmill Step'),Func=remoteSpeedProbe})]=],
            [=[miscSafety:AddButton({Text='Auto hit players',Func=function() end})]=]
        },
        {
            [=[miscSafety:AddLabel(t('O teste Step não deu Speed nos últimos logs.','The Step test gave no Speed in the latest logs.'),true)]=],
            ''
        },
        {
            [=[settingsAbout:AddLabel(t('A Storm Suite possui configurações independentes.','Storm Suite has independent settings.'),true)]=],
            ''
        },
        {
            [=[settingsAbout:AddLabel(t('HIT PLAYERS continua congelado.','HIT PLAYERS remains frozen.'),true)]=],
            ''
        },
    }
    for _,change in ipairs(replacements) do
        source=replaceLiteral(source,change[1],change[2])
    end
    -- Keep the changed treadmill description localized even after live language switching.
    local languagePair=[=[["A esteira usa o botão de interação [E] original."]="The treadmill uses the original interaction button [E].",]=]
    local dictionaryAnchor=[=[local reverseTranslations={}]=]
    if not source:find(languagePair,1,true) then
        source=replaceLiteral(source,dictionaryAnchor,
            "translations['A esteira usa o botão de interação [E] original.']='The treadmill uses the original interaction button [E].'\n"..dictionaryAnchor)
    end
end
-- Prime Void Hub | Exu Security Lab runtime UI hotfix (loader only).
-- Only patch four precise UI/bind locations in the fetched Exu port.
if selected.name=='Exu Security Lab' then
    local function exuUiPatch(label,before,after)
        local first=source:find(before,1,true)
        if not first then
            warn('[Prime Void Hub] Exu UI hotfix skipped ('..label..'): source marker absent')
            return
        end
        if source:find(before,first+#before,true) then
            warn('[Prime Void Hub] Exu UI hotfix skipped ('..label..'): duplicate marker')
            return
        end
        source=source:sub(1,first-1)..after..source:sub(first+#before)
    end

    -- Avoid hide/show animation races during the rapid BLINK placement loop.
    exuUiPatch('blink visibility',
        [=[if not minimized then hiddenForDeposit=true setVisible(false) end]=],
        [=[if Config.Mode~='BLINK' and not minimized then hiddenForDeposit=true setVisible(false) end]=])

    -- F6 always stops Auto Farm, independently of the window or player movement controls.
    exuUiPatch('F6 stop farm',
        [=[local function toggleMinimized()
    if terminating then return end
    minimized=not minimized
    setVisible(not minimized)
end]=],
        [=[local function toggleMinimized()
    if terminating then return end
    minimized=not minimized
    setVisible(not minimized)
end
connections[#connections+1]=UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode~=Enum.KeyCode.F6 or terminating or not running then return end
    local farmToggle=Toggles and Toggles.PVEXU_AutoFarm
    if farmToggle then pcall(function() farmToggle:SetValue(false) end) end
    if running then stop() end
    if hiddenForDeposit then restoreObsidianAfterPlacement() end
end)]=])

    -- Bind by reference, not by value: use the wrapper that updates the mini icon.
    exuUiPatch('mini icon click',
        [=[miniIcon.MouseButton1Click:Connect(toggleMinimized)]=],
        [=[miniIcon.MouseButton1Click:Connect(function() toggleMinimized() end)]=])

    -- The old mini launcher was text-only. Show a thumbnail with a PV fallback.
    exuUiPatch('mini icon image',
        [=[miniIcon.Parent=screen
Instance.new('UICorner',miniIcon).CornerRadius=UDim.new(0,13)]=],
        [=[miniIcon.Parent=screen
Instance.new('UICorner',miniIcon).CornerRadius=UDim.new(0,13)
local miniAvatar=Instance.new('ImageLabel')
miniAvatar.Name='PVHubMiniAvatar'
miniAvatar.Size=UDim2.fromScale(1,1)
miniAvatar.BackgroundTransparency=1
miniAvatar.ImageTransparency=1
miniAvatar.ScaleType=Enum.ScaleType.Crop
miniAvatar.Active=false
miniAvatar.ZIndex=miniIcon.ZIndex+1
miniAvatar.Parent=miniIcon
Instance.new('UICorner',miniAvatar).CornerRadius=UDim.new(0,13)
task.spawn(function()
    for attempt=1,4 do
        if not miniIcon.Parent then break end
        local ok,thumb,ready=pcall(function()
            return Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150)
        end)
        if ok and ready and type(thumb)=='string' and thumb~='' then
            miniAvatar.Image=thumb
            miniAvatar.ImageTransparency=0
            miniIcon.Text=''
            break
        end
        task.wait(1)
    end
end)]=])
end

-- Exu Security Lab | Server Hop runtime port (universal loader only).
-- Apply atomically: a gateway revision with different anchors must not be partially patched.
if selected.name=='Exu Security Lab' and not source:find('PVEXU_ServerHopNoExu',1,true) then
    local hopChanges={
        {
            [==[local alive,running,token=true,false,0]==],
            [==[local alive,running,token=true,false,0
local serverHopWhenNoExu=false]==],
        },
        {
            [==[style=espStyle, ui=uiPrefs,]==],
            [==[style=espStyle, ui=uiPrefs, serverHopWhenNoExu=serverHopWhenNoExu,]==],
        },
        {
            [==[if data.placement=='VIRTUAL' or data.placement=='LEGACY' then Config.PlacementInput=data.placement end]==],
            [==[if type(data.serverHopWhenNoExu)=='boolean' then serverHopWhenNoExu=data.serverHopWhenNoExu end
    if data.placement=='VIRTUAL' or data.placement=='LEGACY' then Config.PlacementInput=data.placement end]==],
        },
        {
            [==[loadSettings()
local function profilePath(raw)]==],
            [==[loadSettings()
if getgenv and getgenv().PVExuAutoHopResume==true then
    serverHopWhenNoExu=true
    getgenv().PVExuAutoHopResume=nil
end
local function profilePath(raw)]==],
        },
        {
            [==[-- Storm Suite v1.0.0 shared presentation pattern: account, tips, ports and community.]==],
            [==[-- Server Hop: UI-only extension, without changes to the farming loop.
local hopBusy=false
local hopLastAttempt=-math.huge
local noExuSince=nil
local function serverHop(reason)
    if hopBusy or terminating or not alive then return end
    if os.clock()-hopLastAttempt<5 then return end
    hopBusy=true
    hopLastAttempt=os.clock()
    task.spawn(function()
        local currentJob=tostring(game.JobId)
        local cursor=nil
        local destination=nil
        for _=1,5 do
            local url='https://games.roblox.com/v1/games/'..tostring(game.PlaceId)..'/servers/Public?sortOrder=Asc&limit=100'
            if cursor then url=url..'&cursor='..HttpService:UrlEncode(cursor) end
            local ok,response=pcall(function() return HttpService:JSONDecode(game:HttpGet(url)) end)
            if not ok or type(response)~='table' then
                log('HOP','Server listing failed | '..tostring(response))
                notify(t('Não foi possível consultar os servidores.','Could not list public servers.'))
                hopBusy=false
                return
            end
            local choices={}
            for _,entry in ipairs(response.data or {}) do
                if type(entry.id)=='string' and entry.id~=currentJob
                    and tonumber(entry.playing) and tonumber(entry.maxPlayers)
                    and tonumber(entry.playing)<tonumber(entry.maxPlayers) then
                    choices[#choices+1]=entry.id
                end
            end
            if #choices>0 then
                destination=choices[math.random(1,#choices)]
                break
            end
            cursor=type(response.nextPageCursor)=='string' and response.nextPageCursor~='' and response.nextPageCursor or nil
            if not cursor then break end
        end
        if not destination then
            log('HOP','No other non-full public server found')
            notify(t('Nenhum outro servidor disponível.','No other public server available.'))
            hopBusy=false
            return
        end
        local queue=type(queue_on_teleport)=='function' and queue_on_teleport
            or (type(syn)=='table' and type(syn.queue_on_teleport)=='function' and syn.queue_on_teleport)
        if queue then
            local resume=serverHopWhenNoExu and 'if getgenv then getgenv().PVExuAutoHopResume=true end\n' or ''
            pcall(queue,resume..'loadstring(game:HttpGet("https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Loader.lua"))()')
        end
        log('HOP','Teleport requested | '..tostring(reason)..' | from='..currentJob..' | to='..destination)
        local ok,err=pcall(function()
            game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId,destination,player)
        end)
        if not ok then
            log('HOP','Teleport failed | '..tostring(err))
            notify(t('Falha ao trocar de servidor.','Server hop failed.'))
            hopBusy=false
        else
            task.delay(15,function() if alive then hopBusy=false end end)
        end
    end)
end
connections[#connections+1]=game:GetService('TeleportService').TeleportInitFailed:Connect(function(who,result)
    if who==player and hopBusy then
        log('HOP','Teleport initialization failed | '..tostring(result))
        hopBusy=false
    end
end)
-- Storm Suite v1.0.0 shared presentation pattern: account, tips, ports and community.]==],
        },
        {
            [==[['Auto Farm Exus']='Exu Auto Farm',['Seleção de alvos']='Target selection',]==],
            [==[['Auto Farm Exus']='Exu Auto Farm',['Seleção de alvos']='Target selection',
    ['Auto trocar servidor sem Exu']='Auto server hop if no Exu',]==],
        },
        {
            [==[farmControls:AddDropdown('PVEXU_Move',]==],
            [==[farmControls:AddButton({Text='Server Hop',Func=function()
    serverHop('manual')
end})
farmControls:AddToggle('PVEXU_ServerHopNoExu',{Text=t('Auto trocar servidor sem Exu','Auto server hop if no Exu'),Default=serverHopWhenNoExu,Callback=function(on)
    if terminating then return end
    serverHopWhenNoExu=on
    noExuSince=nil
    saveSettings()
end})
farmControls:AddDropdown('PVEXU_Move',]==],
        },
        {
            [==[PVEXU_Move=Config.Mode,PVEXU_Place=Config.PlacementInput,]==],
            [==[PVEXU_Move=Config.Mode,PVEXU_Place=Config.PlacementInput,
        PVEXU_ServerHopNoExu=serverHopWhenNoExu,]==],
        },
        {
            [==[task.spawn(findAutoBase)]==],
            [==[task.spawn(findAutoBase)
-- Stable empty-server detection: allow initial loading and require 8 seconds with no Exus.
task.spawn(function()
    task.wait(10)
    while alive and not terminating do
        if serverHopWhenNoExu and not hopBusy and not pending and select(1,carry())~=true then
            local ok,items=pcall(scan)
            if ok and type(items)=='table' and #items==0 then
                noExuSince=noExuSince or os.clock()
                if os.clock()-noExuSince>=8 then
                    noExuSince=nil
                    serverHop('no_exu')
                end
            else
                noExuSince=nil
            end
        else
            noExuSince=nil
        end
        task.wait(2)
    end
end)]==],
        },
    }
    local allFound=true
    for index,change in ipairs(hopChanges) do
        local first=source:find(change[1],1,true)
        if not first or source:find(change[1],first+#change[1],true) then
            warn('[Prime Void Hub] Server Hop not applied: source marker '..tostring(index)..' missing or ambiguous')
            allFound=false
            break
        end
    end
    if allFound then
        for _,change in ipairs(hopChanges) do
            source=replaceLiteral(source,change[1],change[2])
        end
    end
end

-- Prime Void Hub | Legacy floating-icon drag correction (loader-only).
-- The Storm Suite already implements continuous pointer dragging; leave it untouched.
-- Also apply to Huntress only if its fetched source has the identical legacy UI anchors.
-- Any other Huntress layout is left untouched.
if selected.name=='Exu Security Lab' or selected.name=='Dont Splash Explorer' or selected.name=='Huntress' then
    local isExu=selected.name=='Exu Security Lab'
    local iconName=isExu and 'miniIcon' or 'iconButton'
    local oldDrag=iconName..'.Draggable=true'
    local oldClick=isExu
        and 'connections[#connections+1]=miniIcon.MouseButton1Click:Connect(function() toggleMinimized() end)'
        or 'track(iconButton.MouseButton1Click:Connect(minimize))'
    local hasDrag=source:find(oldDrag,1,true)
    local hasClick=source:find(oldClick,1,true)
    if hasDrag and not source:find(oldDrag,hasDrag+#oldDrag,true)
        and hasClick and not source:find(oldClick,hasClick+#oldClick,true) then
        local driver=[==[
-- Continuous floating-icon dragging: mouse and touch are tracked across the viewport.
local function pvHubAttachPointerDrag(button,subscribe)
    local activePointer=nil
    local startPoint=nil
    local startPosition=nil
    local startAbsolute=nil
    local moved=false
    local suppressClickUntil=0
    local function clear()
        activePointer=nil
        startPoint=nil
        startPosition=nil
        startAbsolute=nil
    end
    subscribe(button.InputBegan:Connect(function(input)
        if not button.Visible or activePointer then return end
        local kind=input.UserInputType
        if kind~=Enum.UserInputType.MouseButton1 and kind~=Enum.UserInputType.Touch then return end
        activePointer=input
        startPoint=Vector2.new(input.Position.X,input.Position.Y)
        startPosition=button.Position
        startAbsolute=button.AbsolutePosition
        moved=false
    end))
    subscribe(UserInputService.InputChanged:Connect(function(input)
        if not activePointer or not button.Visible or not startPoint then return end
        local mouseMove=activePointer.UserInputType==Enum.UserInputType.MouseButton1
            and input.UserInputType==Enum.UserInputType.MouseMovement
        local touchMove=activePointer.UserInputType==Enum.UserInputType.Touch
            and input==activePointer
        if not mouseMove and not touchMove then return end
        local delta=Vector2.new(input.Position.X,input.Position.Y)-startPoint
        if not moved and delta.Magnitude<8 then return end
        moved=true
        local camera=game:GetService('Workspace').CurrentCamera
        local viewport=camera and camera.ViewportSize or Vector2.new(1920,1080)
        local maxX=math.max(6,viewport.X-button.AbsoluteSize.X-6)
        local maxY=math.max(6,viewport.Y-button.AbsoluteSize.Y-6)
        local newX=math.clamp(startAbsolute.X+delta.X,6,maxX)
        local newY=math.clamp(startAbsolute.Y+delta.Y,6,maxY)
        button.Position=UDim2.new(
            startPosition.X.Scale,startPosition.X.Offset+newX-startAbsolute.X,
            startPosition.Y.Scale,startPosition.Y.Offset+newY-startAbsolute.Y
        )
    end))
    subscribe(UserInputService.InputEnded:Connect(function(input)
        if not activePointer then return end
        local sameTouch=input==activePointer
        local mouseRelease=activePointer.UserInputType==Enum.UserInputType.MouseButton1
            and input.UserInputType==Enum.UserInputType.MouseButton1
        if not sameTouch and not mouseRelease then return end
        if moved then suppressClickUntil=os.clock()+0.35 end
        clear()
    end))
    subscribe(UserInputService.WindowFocusReleased:Connect(clear))
    subscribe(button:GetPropertyChangedSignal('Visible'):Connect(function()
        if not button.Visible then clear() end
    end))
    return function()
        return moved or os.clock()<suppressClickUntil
    end
end
]==]
        local replacement
        if isExu then
            replacement=driver..[==[
local ignoreMiniClick=pvHubAttachPointerDrag(miniIcon,function(connection)
    connections[#connections+1]=connection
end)
connections[#connections+1]=miniIcon.MouseButton1Click:Connect(function()
    if ignoreMiniClick() then return end
    toggleMinimized()
end)]==]
        else
            replacement=driver..[==[
local ignoreMiniClick=pvHubAttachPointerDrag(iconButton,track)
track(iconButton.MouseButton1Click:Connect(function()
    if ignoreMiniClick() then return end
    minimize()
end))]==]
        end
        source=replaceLiteral(source,oldDrag,iconName..'.Draggable=false')
        source=replaceLiteral(source,oldClick,replacement)
    elseif hasDrag or hasClick then
        warn('[Prime Void Hub] Floating-icon drag fix skipped ('..selected.name..'): conflicting source layout')
    end
end

-- Prime Void Hub | Analytics universal dos ports + identificacao opcional do executor.
-- O distribuidor informa aos testers quais dados sao registrados.
-- Uma execucao por sessao; sem UI e sem coletar tokens, IP, HWID ou cookies.
local previousLog=genv.PV_Hub_AnalyticsSent==true or selected.name=='Dont Splash Explorer'
if not previousLog then
    -- Reservar antes de executar: a source antiga do Exu tambem tem logger.
    -- Assim ela nao envia uma segunda mensagem ao Discord.
    genv.PV_Hub_AnalyticsSent=true
end

local chunk,compileError=loadstring(source)
if not chunk then
    if not previousLog then genv.PV_Hub_AnalyticsSent=nil end
    error('[Prime Void Hub] Erro ao compilar '..selected.name..': '..tostring(compileError),0)
end
local success,runtimeError=pcall(chunk)
if not success then
    if not previousLog then genv.PV_Hub_AnalyticsSent=nil end
    error('[Prime Void Hub] Erro em '..selected.name..': '..tostring(runtimeError),0)
end

local function sendUniversalRunLog()
    if previousLog then return end
    local delivered,payload=pcall(function()
        local req=genv.request or genv.http_request
        local requestFn=type(req)=='function' and req
            or type(request)=='function' and request
            or type(http_request)=='function' and http_request
            or (type(syn)=='table' and type(syn.request)=='function' and syn.request)
        if type(requestFn)~='function' then return false end
        local player=game:GetService('Players').LocalPlayer
        if not player then return false end
        local executor='Não identificado'
        -- Os executores podem fornecer o próprio nome; informação não verificável.
        local candidates={identifyexecutor,getexecutorname,genv.identifyexecutor,genv.getexecutorname}
        for _,fn in pairs(candidates) do
            if type(fn)=='function' then
                local identified,name=pcall(fn)
                if identified and type(name)=='string' and name:match('%S') then
                    executor=name:sub(1,60)
                    break
                end
            end
        end
        local json=game:GetService('HttpService'):JSONEncode({
            executor=executor,
            username=player.Name,
            userId=tostring(player.UserId),
            placeId=tostring(game.PlaceId),
            version=selected.version,
        })
        local response=requestFn({
            Url='https://prime-void-hub-exu-gateway.vercel.app/api/telemetry',
            Method='POST',
            Headers={['Content-Type']='application/json'},
            Body=json,
        })
        if type(response)=='table' then
            local status=tonumber(response.StatusCode or response.Status)
            if status and (status<200 or status>=300) then return false end
        end
        return true
    end)
    if not delivered or payload~=true then
        genv.PV_Hub_AnalyticsSent=nil
    end
end
task.spawn(sendUniversalRunLog)
