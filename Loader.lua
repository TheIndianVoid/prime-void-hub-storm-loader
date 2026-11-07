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
        name='Destruction Simulator',
        version='v0.2.4',
        officialName='Destruction Simulator',
        placeIds={[2248408710]=true},
        universeIds={},
        url='https://prime-void-hub-destruction-gateway.vercel.app/destruction-simulator.lua',
        markers={'-- Prime Void Hub | Destruction Simulator | v0.2.4 TEST','local Airflow={}','global.PVDestructionUnload'},
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
-- Carry a supported port across sibling places of the same experience.
-- Queue handoff state is embedded in the teleport payload, so it works even
-- when the executor's file workspace is scoped per place or experience.
local transportEnv=(type(getgenv)=='function' and getgenv()) or _G
local carry=transportEnv.PVH_AutoexecCarry
transportEnv.PVH_AutoexecCarry=nil
local carriedPort
if type(carry)=='table' and carry.autoexec==true then
    for _,port in ipairs(ports) do
        if port.name==carry.port then carriedPort=port break end
    end
end
if not selected and carriedPort and universeId~=0
    and tonumber(carry.originUniverse)==universeId then
    selected=carriedPort
end
if type(carry)=="table" and carry.autoexec==true then
    warn("[PVH Autoexec] ROUTING | place="..tostring(placeId)
        .." | universe="..tostring(universeId)
        .." | carried="..tostring(carry.port)
        .." | selected="..tostring(selected and selected.name or "unsupported"))
end
-- Friendly unsupported-game dialog. Copying uses the executor clipboard when available.
-- If clipboard support is missing, show a selectable address instead of claiming success.
local function showUnsupportedGame(isPaused)
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
            Footer=isPaused and 'Universal Loader | Port em manutenção' or 'Universal Loader | Aviso v1.0.1 (31/10)',
            Center=true,
            AutoShow=true,
            Resizable=true,
            Size=UDim2.fromOffset(600,390),
            ShowCustomCursor=false,
            -- Never use Unknown: mouse/touch clicks also report that KeyCode.
            ToggleKeybind=Enum.KeyCode.RightControl,
            NotifySide='Right',
            MinSidebarWidth=140,
            EnableCompacting=true,
            SidebarCompactWidth=48,
            Animations={
                ToggleWindow=false,TabSwitch=false,Groupbox=false,
                Dropdown=false,KeyPicker=false,
            },
        })
        -- This informational window has no minimize keybind.
        -- nil never matches an Input.KeyCode; only 'Fechar' dismisses it.
        Library.ToggleKeybind=nil
        local tab=Window:AddTab('Suporte','life-buoy')
        -- Visible UI build marker: verify what code actually reached the executor.
        local uiBuild=isPaused and 'Aviso de manutenção | 07/11/2026' or 'Aviso v1.0.1 | 31/10/2026'

        local details=tab:AddGroupbox({
            Side='Left',Name='Jogo não suportado',IconName='circle-alert',
            DisableCollapsing=true,
        })
        details:AddLabel(isPaused and 'Roube um Exu está temporariamente sem suporte no Prime Void Hub.' or 'Este jogo ainda não é suportado pelo Prime Void Hub.',true)
        details:AddLabel(uiBuild,false)
        details:AddLabel(isPaused and 'Script pausado para manutenção. A versão atual encontra-se detectada. Aguarde a atualização antes de utilizar.' or 'Quer sugerir um port? Envie o link do jogo em nosso Discord.',true)
        details:AddDivider()
        details:AddLabel('PlaceId: '..tostring(placeId),true)

        local links=tab:AddGroupbox({
            Side='Right',Name='Links e comunidade',IconName='link',
            DisableCollapsing=true,
        })
        -- Obsidian Input uses TextScaled=true, shrinking long URLs to tiny text.
        -- Show the full URL in a readable, wrapping label too.
        links:AddLabel({Text=gameLink,DoesWrap=true,Size=16})
        local linkInput=links:AddInput('PVH_UnsupportedLink',{
            Text='Link para copiar',
            Default=gameLink,
            ClearTextOnFocus=false,
            ClearTextOnBlur=false,
            AllowEmpty=false,
            Finished=true,
        })
        -- Keep the editable field legible even for long PlaceIds.
        -- The TextBox can scroll horizontally when selected.
        local linkBox=linkInput.Holder and linkInput.Holder:FindFirstChildOfClass('TextBox')
        if linkBox then
            linkBox.TextScaled=false
            linkBox.TextSize=14
            linkBox.TextXAlignment=Enum.TextXAlignment.Left
        end
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
        warn('[Prime Void Hub] '..(isPaused and 'Roube um Exu pausado para manutenção (versão detectada)' or 'Jogo não suportado')..' | PlaceId='..tostring(placeId)
            ..' | UI Obsidian falhou: '..tostring(reason)
            ..' | Discord: '..discordLink)
        pcall(function()
            game:GetService('StarterGui'):SetCore('SendNotification',{
                Title='Prime Void Hub',
                Text=isPaused and 'Roube um Exu pausado para manutenção: versão detectada.' or 'Jogo não suportado. Sugira este jogo no Discord!',
                Duration=8,
            })
        end)
    end
end
-- Temporary safety pause: intercept Exu before downloading or executing its gameplay source.
-- Reuse the universal unsupported-game Obsidian UI; keep other ports unchanged.
if selected and selected.name=='Exu Security Lab' then
    warn('[Prime Void Hub] Roube um Exu temporariamente pausado: versão detectada.')
    -- Prevent any pending auto-execution bridge from continuing the paused port.
    local oldPersistence=transportEnv.PVH_Persistence
    if type(oldPersistence)=='table' and type(oldPersistence.Stop)=='function' then
        pcall(function() oldPersistence:Stop() end)
    end
    transportEnv.PVH_Persistence=nil
    showUnsupportedGame(true)
    return
end
if not selected then
    -- An unsupported lobby is not the end of an autoexec chain. Stay armed
    -- for the next teleport without executing a wrong game's port.
    if carriedPort then
        local okBridge,errBridge=pcall(function()
            local moduleURL='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/PVH_Persistence.lua'
            local factory,loadErr=loadstring(game:HttpGet(moduleURL..'?pvht='..tostring(os.time())))
            if not factory then error(loadErr) end
            local constructor=factory()
            if type(constructor)~='function' then error('Persistence constructor unavailable') end
            local old=transportEnv.PVH_Persistence
            if type(old)=='table' and type(old.Stop)=='function' then pcall(function()old:Stop()end) end
            local bridge=constructor({
                port=carriedPort.name,originUniverse=tonumber(carry.originUniverse),
                carryAutoexec=true,
                loaderUrl='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Loader.lua',
            })
            transportEnv.PVH_Persistence=bridge
            bridge:Bridge()
        end)
        if not okBridge then warn('[PVH Autoexec] Bridge unavailable: '..tostring(errBridge)) end
    end
    showUnsupportedGame()
    return
end
local genv=type(getgenv)=='function' and getgenv() or _G
-- Clear an existing test overlay or previous universal loader overlay before rerunning.
local oldUXCleanup = genv.PVH_UX_UniversalCleanup or genv.PVH_UX_TestCleanup
if type(oldUXCleanup) == 'function' then
    pcall(oldUXCleanup)
end
genv.PVH_UX_TestCleanup = nil

-- Avoid duplicate launches only inside the SAME Roblox world.
-- Earlier guard used os.clock() alone; after a rejoin that clock may reset,
-- making a *negative* elapsed time incorrectly look like a duplicate.
local currentWorld=tostring(game.PlaceId)..':'..tostring(game.JobId)
local previousWorld=genv.PVH_UniversalBootWorld
local lastBoot=genv.PVH_UniversalStartedAt
local elapsed=type(lastBoot)=='number' and (os.clock()-lastBoot) or nil
if previousWorld==currentWorld and genv.PVH_UniversalBootGame==game
    and type(elapsed)=='number' and elapsed>=0 and elapsed<2.5
    and genv.PV_Hub_ActivePort==selected.name then
    warn('[PVH Autoexec v3] Duplicate loader invocation ignored in same server')
    return
end
genv.PVH_UniversalBootWorld=currentWorld
genv.PVH_UniversalBootGame=game
genv.PVH_UniversalStartedAt=os.clock()
genv.PV_Hub_ActivePort=selected.name
local ok,source=pcall(function()
    return game:HttpGet(selected.url..'?t='..tostring(os.time()))
end)
if not ok or type(source)~='string' then
    error('[Prime Void Hub] Download falhou ('..selected.name..'): '..tostring(source),0)
end
-- Destruction Simulator obfuscated build. Keep legacy source checks for all other ports.
local isObfuscatedDestruction = selected.name=='Destruction Simulator'
    and source:find('-- Obscura [eafdcc1119758bec]',1,true) ~= nil
if not isObfuscatedDestruction then
    for _,marker in ipairs(selected.markers) do
        if not source:find(marker,1,true) then
            error('[Prime Void Hub] Conteudo invalido ('..selected.name..'), source nao executada.',0)
        end
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
    local dot=name=="Don't Splash" and '🟡' or '🟢'
    local label="homePorts:AddLabel('"..dot..name:gsub("\\","\\\\"):gsub("'","\\'").."',true)"
    stormLines[#stormLines+1]=label
    exuLines[#exuLines+1]=label
end
local renderStorm=table.concat(stormLines,"\n    ")
local renderExu=table.concat(exuLines,"\n")
source=replaceLiteral(source,oldStorm,renderStorm)
source=replaceLiteral(source,oldExu,renderExu)
source=replaceLiteral(source,[=[homePorts:AddLabel('🟢'..officialName,true)]=],[=[homePorts:AddLabel((officialName=="Don't Splash" and '🟡' or '🟢')..officialName,true)]=])
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
        -- Keep only Status, Target, Exus, Base and Rebirth in Session State.
        -- Counters continue operating internally; this changes display only.
        {
            [=[local homeCounts=farmSession:AddLabel('Exus: 0 | Coletas: 0 | Depósitos: 0',true)]=],
            [=[local homeCounts=farmSession:AddLabel('Exus: 0',true)]=]
        },
        {
            [=[homeCounts:SetText(uiPrefs.language=='en-US' and string.format('Exus: %d | Pickups: %d | Placements: %d',counts.found,counts.pickups,counts.placed) or string.format('Exus: %d | Coletas: %d | Depósitos: %d',counts.found,counts.pickups,counts.placed))]=],
            [=[homeCounts:SetText(string.format('Exus: %d',counts.found))]=]
        },
        {
            [=[local treadmillState=farmSession:AddLabel(t('Esteira: aguardando','Treadmill: waiting'),true)]=],
            ''
        },
        {
            [=[treadmillState:SetText(t('Esteira: ','Treadmill: ')..(hasTreadmillState() and t('ATIVA','ACTIVE') or (extra.treadmill and t('INICIANDO','STARTING') or 'OFF')))]=],
            ''
        },
        -- Remove the redundant note under Pickup timeout.
        {
            [=[farmControls:AddLabel(t('Só procura outro Exu após confirmar o depósito.','Next Exu is selected only after confirmed placement.'),true)]=],
            ''
        },
        {
            [=[farmFilters:AddLabel(t('Atacar jogadores permanece desativado.','Player combat remains disabled.'),true)]=],
            ''
        },
        -- Remove the unnecessary treadmill hint from the original port.
        {
            [=[farmProgression:AddLabel(t('A esteira usa o prompt Correr [E] original.','Treadmill uses the native Correr [E] prompt.'),true)]=],
            ''
        },
        {
            [=[farmProgression:AddLabel(t('A esteira usa o botão de interação [E] original.','The treadmill uses the original interaction button [E].'),true)]=],
            ''
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

-- Destruction Simulator | production UI labels only; gameplay stays byte-identical.
-- Roster is derived from the same universal registry as the other ports.
if selected.name=='Destruction Simulator' and not isObfuscatedDestruction then
    local oldHome=[==[    for _,name in ipairs({'Ride Storm','HUNTRESS','Steal An Exu',"Don't Splash"}) do
        ports:AddLabel('🟢'..name,true)
    end
    ports:AddLabel('🟡Destruction Simulator — TEST',true)
    ports:AddLabel(t('Port de teste • fora do loader universal','Test port • not in universal loader'),true)]==]
    local homeLines={}
    for _,name in ipairs(officialNames) do
        homeLines[#homeLines+1]="    ports:AddLabel('🟢"..name:gsub("\\","\\\\"):gsub("'","\\'").."',true)"
    end
    if source:find(oldHome,1,true) then
        source=replaceLiteral(source,oldHome,table.concat(homeLines,"\n"))
    else
        warn('[Prime Void Hub] Destruction Home roster unavailable; keeping source UI')
    end
    source=replaceLiteral(source,
        [==[Footer='Prime Void Hub | Destruction Simulator v0.2.4 TEST']==],
        [==[Footer='Prime Void Hub | Destruction Simulator v0.2.4']==])
    source=replaceLiteral(source,
        [==[settingsAbout:AddLabel('Prime Void Hub — Destruction Simulator v0.2.4 TEST',true)]==],
        [==[settingsAbout:AddLabel('Prime Void Hub — Destruction Simulator v0.2.4',true)]==])
    source=replaceLiteral(source,
        [==[settingsAbout:AddLabel(t('Source original preservada. Port ainda não integrado ao loader.',
    'Original source preserved. Port is not yet in the loader.'),true)]==],
        [==[settingsAbout:AddLabel(t('Source original preservada. Loader universal ativo.',
    'Original source preserved. Universal loader active.'),true)]==])
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

-- Prime Void Hub | Exu timed gifts | production UI integration.
-- Exact match against the deployed Exu port; fail closed on layout changes.
if selected.name=='Exu Security Lab' then
    local giftEnv=(type(getgenv)=='function' and getgenv()) or _G
    local resumeGift=giftEnv.PVEXU_GiftsResume
    if type(giftEnv.PVEXU_GiftsPrefs)~='table' then
        giftEnv.PVEXU_GiftsPrefs={
            collect=type(resumeGift)=='table' and resumeGift.collect==true or false,
            hop=type(resumeGift)=='table' and resumeGift.hop==true or false,
        }
    end
    local expected=[=[local farmSession=Tabs.Farm:AddGroupbox({Side='Right',Name=t('Estado da sessão','Session status'),IconName='activity'})]=]
    local found=source:find(expected,1,true)
    if found and not source:find(expected,found+#expected,true) then
        local giftControls=[==[
-- PVH_GIFTS_MAIN_UI | Obsidian right column, below Target selection.
local farmGifts=Tabs.Farm:AddGroupbox({
    Side='Right',Name=t('Presentes AFK','AFK Gifts'),IconName='gift',
})
local giftEnv=(type(getgenv)=='function' and getgenv()) or _G
local giftPrefs=giftEnv.PVEXU_GiftsPrefs
giftEnv.PVEXU_GiftsLegacyHopEnabled=function()
    local control=Toggles.PVEXU_ServerHopNoExu
    return control and control.Value==true or false
end
giftEnv.PVEXU_GiftsSetToggle=function(flag,on)
    local id=flag=='collect' and 'PVEXU_GiftsCollect' or 'PVEXU_GiftsHop'
    local toggle=Toggles[id]
    if toggle and toggle.Value~=on then
        pcall(function()toggle:SetValue(on)end)
    end
end
local function updateGifts(flag,on)
    on=on==true
    giftPrefs[flag]=on
    if flag=='collect' and on then
        local oldHop=Toggles.PVEXU_ServerHopNoExu
        if oldHop and oldHop.Value then
            pcall(function()oldHop:SetValue(false)end)
            warn('[PVH GIFTS] Disabled competing no-Exu server hop')
        end
    end
    local runtime=giftEnv.PVEXU_GiftsMain
    if runtime then
        local operation=flag=='collect' and runtime.SetCollect or runtime.SetHop
        if type(operation)=='function' then
            local ok,err=pcall(operation,on)
            if not ok then warn('[PVH GIFTS] Toggle error: '..tostring(err)) end
        end
    end
end
farmGifts:AddToggle('PVEXU_GiftsCollect',{
    Text=t('Resgate automático','Auto-claim gifts'),
    Default=giftPrefs.collect==true,
    Callback=function(on) updateGifts('collect',on) end,
})
farmGifts:AddToggle('PVEXU_GiftsHop',{
    Text=t('Trocar servidor ao concluir','Server hop when finished'),
    Default=giftPrefs.hop==true,
    Callback=function(on) updateGifts('hop',on) end,
})
-- Fallback for Obsidian builds that update Value without firing Callback.
task.spawn(function()
    while Library and Library.ScreenGui and Library.ScreenGui.Parent do
        local collect=Toggles.PVEXU_GiftsCollect
        local hop=Toggles.PVEXU_GiftsHop
        if collect and collect.Value~=giftPrefs.collect then
            updateGifts('collect',collect.Value)
        end
        if hop and hop.Value~=giftPrefs.hop then
            updateGifts('hop',hop.Value)
        end
        task.wait(0.5)
    end
end)
]==]
        source=source:sub(1,found-1)..giftControls..source:sub(found)
        local translationAnchor='local reverseTranslations={}'
        if source:find(translationAnchor,1,true) then
            local addTranslations=[=[
translations['Presentes AFK']='AFK Gifts'
translations['Resgate automático']='Auto-claim gifts'
translations['Trocar servidor ao concluir']='Server hop when finished'
]=]
            source=replaceLiteral(source,translationAnchor,
                addTranslations..translationAnchor)
        end
        warn('[PVH GIFTS] Native right-side Obsidian controls installed')
    else
        warn('[PVH GIFTS] Exu UI layout changed; skipped gifts controls safely')
    end
end

-- Universal session policy (Auto Save + teleport Autoexec).
-- Kept independent from gameplay sources, so new Obsidian ports inherit it.
local previousPersistence=genv.PVH_Persistence
if type(previousPersistence)=='table' and type(previousPersistence.Stop)=='function' then
    pcall(function()previousPersistence:Stop()end)
end
genv.PVH_Persistence=nil
local persistence
local persistenceOK,persistenceResult=pcall(function()
    local moduleURL='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/PVH_Persistence.lua'
    local body=game:HttpGet(moduleURL..'?pvht='..tostring(os.time()))
    local factory,loadErr=loadstring(body)
    if not factory then error(loadErr) end
    local constructor=factory()
    if type(constructor)~='function' then error('Persistence constructor unavailable') end
    local nativeFiles={
        ['Storm Suite']='primevoid_hub/Storm_Suite/Config/settings.json',
        ['Exu Security Lab']='primevoid_hub/Exu_Security_Lab/Configs/ui_settings.json',
        ['Huntress']='primevoid_hub/Huntress/Configs/ui_settings.json',
        ['Dont Splash Explorer']='primevoid_hub/Dont_Splash/Configs/ui_settings.json',
        ['Destruction Simulator']='primevoid_hub/Destruction_Simulator/Configs/ui_settings.json',
    }
    local instance=constructor({
        port=selected.name,
        nativeConfig=nativeFiles[selected.name],
        loaderUrl='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Loader.lua',
        carryAutoexec=carriedPort~=nil and carriedPort.name==selected.name and carry.autoexec==true,
        originUniverse=carriedPort and carriedPort.name==selected.name and carry.originUniverse or universeId,
    })
    instance:BeforePort()
    return instance
end)
if persistenceOK then
    persistence=persistenceResult
    genv.PVH_Persistence=persistence
else
    warn('[PVH Common] Persistence unavailable, port starts unchanged: '..tostring(persistenceResult))
end
-- When Auto Save is disabled, ignore legacy native settings.json on this run.
-- Named profiles and unrelated user files remain available to the port.
if persistence and persistence.AutoSave==false then
    local noLegacyConfig=[=[
local __pvh_isfile=isfile
local __pvh_readfile=readfile
local function __pvh_legacy_settings(path)
    if type(path)~='string' then return false end
    local normalized=path:gsub('\\','/')
    return normalized:match('/Config/settings%.json$')~=nil
        or normalized:match('/Configs/ui_settings%.json$')~=nil
end
local isfile=function(path)
    if __pvh_legacy_settings(path) then return false end
    return type(__pvh_isfile)=='function' and __pvh_isfile(path) or false
end
local readfile=function(path)
    if __pvh_legacy_settings(path) then
        error('PVH Auto Save disabled: default settings are used',0)
    end
    if type(__pvh_readfile)=='function' then return __pvh_readfile(path) end
    error('readfile unavailable',0)
end
]=]
    source=noLegacyConfig..source
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
if persistence then
    local okPersist,errPersist=pcall(function()persistence:AfterPort()end)
    if not okPersist then warn('[PVH Common] Post-load error: '..tostring(errPersist)) end
end

-- Shared PT-BR/EN localization for legacy UI labels across every port.
-- The port's saved language remains authoritative; no new language setting.
task.spawn(function()
    local okLocale,errLocale=pcall(function()
        local url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/PVH_Locale.lua'
        local chunk,compileErr=loadstring(game:HttpGet(url..'?t='..tostring(os.time())))
        if not chunk then error(compileErr) end
        local setup=chunk()
        if type(setup)=='function' then setup(selected.name) end
    end)
    if not okLocale then warn('[PVH Locale] initialization: '..tostring(errLocale)) end
end)

-- PVH_UX_UNIVERSAL_V1 - all supported ports: mobile restore, native minus, player avatar.
-- Only touches runtime UI instances. Never modifies fetched or obfuscated sources.
do
    local uxPort = selected.name
    local previousUxCleanup = genv.PVH_UX_UniversalCleanup
    if type(previousUxCleanup) == 'function' then
        pcall(previousUxCleanup)
    end
    genv.PVH_UX_UniversalCleanup = nil

    if type(uxPort) == 'string' then
        task.spawn(function()
            local okUx, errUx = pcall(function()
                local PlayersUX = game:GetService('Players')
                local UISUX = game:GetService('UserInputService')
                local localPlayerUX = PlayersUX.LocalPlayer
                if not localPlayerUX then return end

                local libraryUX, mainUX
                local usedGuiFallbackUX = false
                local function activateGuiFallback(screen, main)
                    if typeof(screen) ~= 'Instance' or not screen:IsA('ScreenGui')
                        or typeof(main) ~= 'Instance' or not main:IsA('GuiObject')
                        or not main.Parent or not screen.Parent then
                        return false
                    end
                    mainUX = main
                    usedGuiFallbackUX = true
                    libraryUX = {
                        ScreenGui = screen,
                        Window = { MainFrame = main },
                        Toggled = main.Visible,
                        Animations = { ToggleWindow = false },
                    }
                    function libraryUX.Window:Toggle(value)
                        local show
                        if typeof(value) == 'boolean' then
                            show = value
                        else
                            show = not libraryUX.Toggled
                        end
                        main.Visible = show
                        libraryUX.Toggled = show
                    end
                    function libraryUX:Toggle(value)
                        return self.Window:Toggle(value)
                    end
                    return true
                end

                local function findNativeObsidian()
                    local roots = {}
                    local pg = localPlayerUX:FindFirstChildOfClass('PlayerGui')
                    if pg then roots[#roots+1] = pg end
                    local okCore, core = pcall(function()
                        return game:GetService('CoreGui')
                    end)
                    if okCore and core then roots[#roots+1] = core end
                    local okHui, hui = pcall(function()
                        return type(gethui) == 'function' and gethui() or nil
                    end)
                    if okHui and typeof(hui) == 'Instance' then
                        roots[#roots+1] = hui
                    end
                    for _, root in ipairs(roots) do
                        local okDesc, descendants = pcall(function()
                            return root:GetDescendants()
                        end)
                        if okDesc and type(descendants) == 'table' then
                            for _, screen in ipairs(descendants) do
                                if screen:IsA('ScreenGui') and screen.Name == 'Obsidian'
                                    and screen.Parent then
                                    local main = screen:FindFirstChild('Main')
                                    if main and main:IsA('GuiObject') and main.Parent then
                                        return screen, main
                                    end
                                end
                            end
                        end
                    end
                    return nil, nil
                end

                for attempt = 1, 100 do
                    if genv.PV_Hub_ActivePort ~= uxPort then return end
                    local candidate = genv.Library
                    local destructionGui = uxPort == 'Destruction Simulator'
                        and genv.PVDS_ScreenGui or nil
                    local validLibrary = type(candidate) == 'table'
                        and not candidate.Unloaded
                        and typeof(candidate.ScreenGui) == 'Instance'
                        and type(candidate.Window) == 'table'
                        and typeof(candidate.Window.MainFrame) == 'Instance'
                        and candidate.ScreenGui.Parent
                        and candidate.Window.MainFrame.Parent
                    if validLibrary and (not destructionGui
                        or candidate.ScreenGui == destructionGui) then
                        libraryUX = candidate
                        mainUX = candidate.Window.MainFrame
                        break
                    end
                    if uxPort == 'Destruction Simulator'
                        and typeof(destructionGui) == 'Instance'
                        and destructionGui:IsA('ScreenGui')
                        and destructionGui.Parent then
                        local nativeMain = destructionGui:FindFirstChild('Main', true)
                        if nativeMain and activateGuiFallback(destructionGui, nativeMain) then
                            break
                        end
                    end
                    if attempt % 4 == 1 then
                        local visualGui, visualMain = findNativeObsidian()
                        if visualGui and activateGuiFallback(visualGui, visualMain) then
                            break
                        end
                    end
                    task.wait(0.12)
                end
                if not libraryUX or not mainUX then
                    warn('[PVH UX UNIVERSAL] Obsidian window not found for '..uxPort..
                        ' | PVDS_ScreenGui='..tostring(typeof(genv.PVDS_ScreenGui)))
                    return
                end
                if usedGuiFallbackUX then
                    warn('[PVH UX UNIVERSAL] GUI compatibility fallback: '..uxPort)
                end

                local connections = {}
                local gone = false
                local cleanup
                local function listen(signal, callback)
                    local connection = signal:Connect(callback)
                    connections[#connections + 1] = connection
                    return connection
                end
                local playerGuiUX = localPlayerUX:FindFirstChildOfClass('PlayerGui')
                    or localPlayerUX:WaitForChild('PlayerGui', 5)
                local oldToggle = libraryUX.Window.Toggle
                local wrappedToggle
                local miniGui
                local headerButton
                local avatarButton
                local watched = {}
                -- PVH_HOME_ROSTER_V2: restore the previous Home rows on re-run.
                local rosterOriginalVisible = {}
                local rosterOriginalText = {}
                local rosterCreated = {}
                local rosterContainer = nil

                cleanup = function()
                    if gone then return end
                    gone = true
                    for _, connection in ipairs(connections) do
                        pcall(function() connection:Disconnect() end)
                    end
                    for node, originalVisible in pairs(watched or {}) do
                        if typeof(node) == 'Instance' and node.Parent then
                            pcall(function() node.Visible = originalVisible end)
                        end
                    end
                    for _, row in ipairs(rosterCreated) do
                        pcall(function() row:Destroy() end)
                    end
                    for node, originalVisible in pairs(rosterOriginalVisible) do
                        if typeof(node) == 'Instance' and node.Parent then
                            pcall(function() node.Visible = originalVisible end)
                        end
                    end
                    for node, originalText in pairs(rosterOriginalText) do
                        if typeof(node) == 'Instance' and node.Parent then
                            pcall(function() node.Text = originalText end)
                        end
                    end
                    if libraryUX.Window and libraryUX.Window.Toggle == wrappedToggle then
                        libraryUX.Window.Toggle = oldToggle
                    end
                    if miniGui then pcall(function() miniGui:Destroy() end) end
                    if headerButton then pcall(function() headerButton:Destroy() end) end
                    if genv.PVH_UX_UniversalCleanup == cleanup then
                        genv.PVH_UX_UniversalCleanup = nil
                    end
                end
                genv.PVH_UX_UniversalCleanup = cleanup

                if type(libraryUX.Animations) == 'table' then
                    libraryUX.Animations.ToggleWindow = false
                end

                -- Independent ScreenGui: the Obsidian overlay cannot swallow mobile taps.
                miniGui = Instance.new('ScreenGui')
                miniGui.Name = 'PVH_UniversalMobileRestore'
                miniGui.IgnoreGuiInset = true
                miniGui.ResetOnSpawn = false
                miniGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                miniGui.DisplayOrder = math.max(10000, libraryUX.ScreenGui.DisplayOrder + 50)
                miniGui.Parent = libraryUX.ScreenGui.Parent

                avatarButton = Instance.new('ImageButton')
                avatarButton.Name = 'PVH_RestoreAvatar'
                avatarButton.BackgroundColor3 = Color3.fromRGB(31, 27, 43)
                avatarButton.BorderSizePixel = 0
                avatarButton.Size = UDim2.fromOffset(54, 54)
                avatarButton.Position = UDim2.new(0, 18, 0.5, -27)
                avatarButton.Visible = false
                avatarButton.Active = true
                avatarButton.AutoButtonColor = true
                avatarButton.ScaleType = Enum.ScaleType.Crop
                avatarButton.Image = string.format(
                    'rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150',
                    localPlayerUX.UserId
                )
                avatarButton.Parent = miniGui
                local avatarCorner = Instance.new('UICorner')
                avatarCorner.CornerRadius = UDim.new(0, 13)
                avatarCorner.Parent = avatarButton

                task.spawn(function()
                    for _ = 1, 4 do
                        if gone or not avatarButton.Parent then return end
                        local ok, image, ready = pcall(function()
                            return PlayersUX:GetUserThumbnailAsync(
                                localPlayerUX.UserId,
                                Enum.ThumbnailType.HeadShot,
                                Enum.ThumbnailSize.Size150x150
                            )
                        end)
                        if ok and ready and type(image) == 'string' and image ~= '' then
                            avatarButton.Image = image
                            return
                        end
                        task.wait(0.75)
                    end
                end)

                -- The rightmost ~49 px of the native Obsidian title bar are unused.
                headerButton = Instance.new('TextButton')
                headerButton.Name = 'PVH_HeaderMinimize'
                headerButton.AnchorPoint = Vector2.new(1, 0)
                headerButton.Position = UDim2.new(1, -12, 0, 10)
                headerButton.Size = UDim2.fromOffset(29, 27)
                headerButton.BackgroundTransparency = 1
                headerButton.TextColor3 = Color3.fromRGB(198, 195, 208)
                headerButton.Text = '−'
                headerButton.Font = Enum.Font.GothamMedium
                headerButton.TextSize = 20
                headerButton.AutoButtonColor = true
                headerButton.Active = true
                headerButton.ZIndex = 50
                headerButton.Parent = mainUX

                -- The Obsidian's MoveIcon is an ImageLabel under TopBar.
                -- Search by its unique right-edge position instead of the
                -- TopBar's exact Size (which can change at runtime).
                -- MoveIcon is decorative: do not disable TopBar dragging.
                local function hideObsidianMoveIcon()
                    for _, candidate in ipairs(mainUX:GetDescendants()) do
                        if candidate:IsA('ImageLabel')
                            and candidate.AnchorPoint == Vector2.new(1, 0.5)
                            and candidate.Position.X.Scale == 1
                            and candidate.Position.X.Offset == -10
                            and candidate.Position.Y.Scale == 0.5
                            and candidate.Size.X.Offset <= 34
                            and candidate.Size.Y.Offset <= 34
                            and candidate:IsDescendantOf(mainUX)
                            and candidate.Parent
                            and candidate.Parent:IsA('GuiObject') then
                            candidate.Visible = false
                            -- Place our minus inside the native TopBar, exactly
                            -- where the arrows used to be (same layout on mobile).
                            if headerButton.Parent ~= candidate.Parent then
                                headerButton.Parent = candidate.Parent
                            end
                            headerButton.AnchorPoint = Vector2.new(1, 0.5)
                            headerButton.Position = UDim2.new(1, -10, 0.5, 0)
                            headerButton.Size = UDim2.fromOffset(28, 28)
                            headerButton.ZIndex = math.max(50, candidate.ZIndex + 1)
                            return true
                        end
                    end
                    return false
                end
                if not hideObsidianMoveIcon() then
                    warn('[PVH UX UNIVERSAL] Icone move da Obsidian nao encontrado para ocultar')
                end

                -- Keep the old mini launchers hidden so a single avatar works
                -- across all five ports, including ports with different UI names.
                local function oldLauncher(node)
                    if not node or not node:IsA('GuiButton')
                        or node == avatarButton or node == headerButton
                        or node:IsDescendantOf(mainUX) then
                        return false
                    end
                    local name = node.Name:lower()
                    local screen = node:FindFirstAncestorOfClass('ScreenGui')
                    if not screen then return false end
                    local screenName = screen.Name:lower()
                    local portScreen = screen == libraryUX.ScreenGui
                        or screenName:find('prime',1,true)
                        or screenName:find('pvh',1,true)
                        or screenName:find('pvds',1,true)
                        or screenName:find('storm',1,true)
                        or screenName:find('huntress',1,true)
                        or screenName:find('splash',1,true)
                        or screenName:find('exu',1,true)
                        or screenName:find('destruction',1,true)
                    if not portScreen then return false end
                    if node:FindFirstChild('PVHubMiniAvatar')
                        or node:FindFirstChild('GitHubAvatar') then return true end
                    local known = name == 'stormmini' or name == 'pvhubmini'
                        or name == 'miniicon' or name == 'iconbutton'
                        or name:find('minimizeicon',1,true)
                        or name:find('minimizedicon',1,true)
                        or name:find('floatingicon',1,true)
                    if not known then
                        known = name:find('mini',1,true)
                            or name:find('floating',1,true)
                    end
                    if not known then return false end
                    local size = node.AbsoluteSize
                    local w = size.X > 0 and size.X or node.Size.X.Offset
                    local h = size.Y > 0 and size.Y or node.Size.Y.Offset
                    return w <= 100 and h <= 100 and w >= 20 and h >= 20
                end
                local function suppressOne(node)
                    if not oldLauncher(node) or watched[node] ~= nil then return end
                    watched[node] = node.Visible
                    node.Visible = false
                    listen(node:GetPropertyChangedSignal('Visible'), function()
                        if not gone and node.Parent and node.Visible then
                            node.Visible = false
                        end
                    end)
                end
                local function suppressLegacy(root)
                    if typeof(root) ~= 'Instance' then return end
                    suppressOne(root)
                    local okDesc, descendants = pcall(function()
                        return root:GetDescendants()
                    end)
                    if okDesc and type(descendants) == 'table' then
                        for _, node in ipairs(descendants) do
                            suppressOne(node)
                        end
                    end
                end


                -- The loader owns the canonical port list; legacy ports may
                -- still draw only 2 or 3 items. Change just this Home groupbox,
                -- not gameplay, library sources, or other Home groupboxes.
                local function findPortsGroupContainer()
                    if not libraryUX.ScreenGui or not libraryUX.ScreenGui.Parent then
                        return nil
                    end
                    for _, label in ipairs(libraryUX.ScreenGui:GetDescendants()) do
                        if label:IsA('TextLabel') and type(label.Text) == 'string' then
                            local title = label.Text:lower()
                            local isPortsHeader = (title:find('ports',1,true)
                                and (title:find('dispon',1,true)
                                    or title:find('available',1,true)))
                                or title:find('jogos suportados',1,true)
                                or title:find('supported games',1,true)
                            if isPortsHeader then
                                local textFrame = label.Parent
                                local topBar = textFrame and textFrame.Parent
                                local groupHolder = topBar and topBar.Parent
                                if groupHolder and groupHolder:IsA('Frame')
                                    and topBar:IsA('Frame') then
                                    for _, child in ipairs(groupHolder:GetChildren()) do
                                        if child:IsA('ScrollingFrame')
                                            and child.LayoutOrder == 2 then
                                            return child
                                        end
                                    end
                                end
                            end
                        end
                    end
                    return nil
                end

                local function removeDestructionTestLabels()
                    if uxPort ~= 'Destruction Simulator' then return end
                    for _, node in ipairs(libraryUX.ScreenGui:GetDescendants()) do
                        if node:IsA('TextLabel')
                            and node.Text:find('Destruction Simulator',1,true)
                            and node.Text:find('TEST',1,true) then
                            if rosterOriginalText[node] == nil then
                                rosterOriginalText[node] = node.Text
                            end
                            -- Only visual labels: never modify the signed or
                            -- obfuscated source, logs, or feature names.
                            local clean = node.Text:gsub(' — TEST','')
                                :gsub(' %- TEST','')
                                :gsub(' TEST','')
                            node.Text = clean
                        end
                    end
                end

                local function updateHomeRoster()
                    if gone or not mainUX.Parent then return false end
                    local container = findPortsGroupContainer()
                    if not container then return false end
                    if rosterContainer == container and #rosterCreated == #ports
                        and rosterCreated[1] and rosterCreated[1].Parent == container then
                        return true
                    end

                    -- Rebuild atomically if the UI was recreated.
                    for _, row in ipairs(rosterCreated) do
                        pcall(function() row:Destroy() end)
                    end
                    table.clear(rosterCreated)
                    for label, visible in pairs(rosterOriginalVisible) do
                        if label.Parent then label.Visible = visible end
                    end
                    table.clear(rosterOriginalVisible)

                    local sample = nil
                    for _, node in ipairs(container:GetChildren()) do
                        if node:IsA('TextLabel') then
                            if not sample then sample = node end
                            rosterOriginalVisible[node] = node.Visible
                            node.Visible = false
                        end
                    end

                    for index, port in ipairs(ports) do
                        local row = Instance.new('TextLabel')
                        row.Name = 'PVH_HomePort_'..tostring(index)
                        row.BackgroundTransparency = 1
                        row.BorderSizePixel = 0
                        row.Size = UDim2.new(1, 0, 0, 18)
                        row.TextSize = sample and sample.TextSize or 14
                        row.FontFace = sample and sample.FontFace
                            or Font.fromEnum(Enum.Font.Code)
                        row.TextColor3 = sample and sample.TextColor3
                            or Color3.fromRGB(235, 235, 235)
                        row.TextTransparency = sample and sample.TextTransparency or 0
                        row.TextXAlignment = Enum.TextXAlignment.Left
                        row.TextYAlignment = Enum.TextYAlignment.Center
                        row.TextWrapped = false
                        row.LayoutOrder = 100 + index
                        local dot = port.name == 'Dont Splash Explorer' and '🟡' or '🟢'
                        row.Text = dot..port.officialName
                        row.Parent = container
                        rosterCreated[#rosterCreated + 1] = row
                    end
                    rosterContainer = container
                    removeDestructionTestLabels()
                    return true
                end

                task.spawn(function()
                    for attempt = 1, 100 do
                        if gone or genv.PV_Hub_ActivePort ~= uxPort then return end
                        local okRoster, updated = pcall(updateHomeRoster)
                        if okRoster and updated then
                            warn('[PVH HOME] Roster synced (5 ports): '..uxPort)
                            return
                        end
                        if not okRoster and attempt == 1 then
                            warn('[PVH HOME] Roster scan: '..tostring(updated))
                        end
                        task.wait(0.12)
                    end
                    warn('[PVH HOME] Ports group not found: '..uxPort)
                end)

                local function sync()
                    if gone or not mainUX.Parent then return end
                    if usedGuiFallbackUX then
                        libraryUX.Toggled = mainUX.Visible
                    end
                    suppressLegacy(libraryUX.ScreenGui)
                    suppressLegacy(playerGuiUX)
                    suppressLegacy(libraryUX.ScreenGui.Parent)
                    avatarButton.Visible = (libraryUX.Toggled ~= true) or not mainUX.Visible
                end

                -- Storm currently tracks a separate "minimized" flag. If that flag
                -- desynchronizes after using this button, treat the next explicit
                -- Window:Toggle(boolean) request as a toggle, not a no-op.
                wrappedToggle = function(self, desired)
                    if type(libraryUX.Animations) == 'table' then
                        libraryUX.Animations.ToggleWindow = false
                    end
                    if uxPort == 'Storm Suite' and type(desired) == 'boolean'
                        and desired == libraryUX.Toggled then
                        desired = not desired
                    end
                    local result = oldToggle(self, desired)
                    task.defer(sync)
                    return result
                end
                libraryUX.Window.Toggle = wrappedToggle

                listen(headerButton.Activated, function()
                    if gone then return end
                    libraryUX:Toggle(false)
                    sync()
                end)
                listen(avatarButton.Activated, function()
                    if gone or not avatarButton.Parent then return end
                    if avatarButton:GetAttribute('PVH_JustDragged') then return end
                    libraryUX:Toggle(true)
                    if libraryUX.Toggled == true and mainUX.Parent then
                        mainUX.Visible = true
                    end
                    sync()
                end)

                -- Touch/mouse dragging with pointer release anywhere on screen.
                local drag, origin, originalPosition, dragged
                local function release(input)
                    if not drag then return end
                    if drag.UserInputType == Enum.UserInputType.Touch then
                        if input ~= drag then return end
                    elseif input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                        return
                    end
                    drag = nil
                    origin = nil
                    originalPosition = nil
                    if dragged then
                        avatarButton:SetAttribute('PVH_JustDragged', true)
                        task.delay(0.25, function()
                            if not gone and avatarButton.Parent then
                                avatarButton:SetAttribute('PVH_JustDragged', false)
                            end
                        end)
                    end
                end
                listen(avatarButton.InputBegan, function(input)
                    if input.UserInputType ~= Enum.UserInputType.Touch
                        and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                        return
                    end
                    drag = input
                    origin = input.Position
                    originalPosition = avatarButton.Position
                    dragged = false
                    avatarButton:SetAttribute('PVH_JustDragged', false)
                end)
                listen(UISUX.InputChanged, function(input)
                    if not drag or not origin or not originalPosition then return end
                    if drag.UserInputType == Enum.UserInputType.Touch then
                        if input ~= drag then return end
                    elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
                        return
                    end
                    local delta = input.Position - origin
                    if delta.Magnitude >= 10 then
                        dragged = true
                        avatarButton:SetAttribute('PVH_JustDragged', true)
                    end
                    if not dragged then return end
                    local parentSize = workspace.CurrentCamera
                        and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
                    local x = originalPosition.X.Scale * parentSize.X
                        + originalPosition.X.Offset + delta.X
                    local y = originalPosition.Y.Scale * parentSize.Y
                        + originalPosition.Y.Offset + delta.Y
                    x = math.clamp(x, 0, math.max(0, parentSize.X - avatarButton.AbsoluteSize.X))
                    y = math.clamp(y, 0, math.max(0, parentSize.Y - avatarButton.AbsoluteSize.Y))
                    avatarButton.Position = UDim2.fromOffset(x, y)
                end)
                listen(UISUX.InputEnded, release)
                listen(UISUX.WindowFocusReleased, function()
                    drag = nil
                    origin = nil
                    originalPosition = nil
                end)

                listen(mainUX:GetPropertyChangedSignal('Visible'), function()
                    task.defer(sync)
                end)
                listen(libraryUX.ScreenGui.DescendantAdded, function(node)
                    task.defer(function() suppressLegacy(node) end)
                end)
                if playerGuiUX then
                    listen(playerGuiUX.DescendantAdded, function(node)
                        task.defer(function() suppressLegacy(node) end)
                    end)
                end
                listen(libraryUX.ScreenGui.Destroying, cleanup)
                sync()
                warn('[PVH UX UNIVERSAL] Header − and mobile avatar installed: '..uxPort)
            end)
            if not okUx then
                warn('[PVH UX UNIVERSAL] setup failed: '..tostring(errUx))
            end
        end)
    end
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


-- Prime Void Hub | Exu gift runtime (no extra windows, no Halloween changes).
-- The primary farm UI is already loaded; this module cannot break the Hub boot.
if selected.name=='Exu Security Lab' then
    task.spawn(function()
        local ok,err=pcall(function()
            local url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Exu_Gifts_Main.lua'
            local body=game:HttpGet(url)
            local fn,compileError=loadstring(body)
            if not fn then error('Gift engine syntax: '..tostring(compileError)) end
            fn()
        end)
        if not ok then warn('[PVH GIFTS] Runtime unavailable: '..tostring(err)) end
    end)
end
