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
    local gameLink='https://www.roblox.com/games/'..tostring(placeId)
    local discordLink='https://discord.gg/PD3PeyG8aq'
    local ok,reason=pcall(function()
        local Players=game:GetService('Players')
        local player=Players.LocalPlayer
        local pg=player and player:WaitForChild('PlayerGui',8)
        if not pg then error('PlayerGui unavailable') end
        local previous=pg:FindFirstChild('PVH_UnsupportedGame')
        if previous then previous:Destroy() end
        local gui=Instance.new('ScreenGui')
        gui.Name='PVH_UnsupportedGame'
        gui.ResetOnSpawn=false
        gui.IgnoreGuiInset=true
        gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
        gui.DisplayOrder=11000
        gui.Parent=pg
        local shade=Instance.new('Frame')
        shade.Name='Backdrop'
        shade.Size=UDim2.fromScale(1,1)
        shade.BackgroundColor3=Color3.fromRGB(0,0,0)
        shade.BackgroundTransparency=0.38
        shade.BorderSizePixel=0
        shade.Parent=gui
        local card=Instance.new('Frame')
        card.Name='UnsupportedPanel'
        card.AnchorPoint=Vector2.new(0.5,0.5)
        card.Position=UDim2.fromScale(0.5,0.5)
        card.Size=UDim2.new(0.88,0,0,257)
        card.BackgroundColor3=Color3.fromRGB(18,18,21)
        card.BorderSizePixel=0
        card.Parent=shade
        local limit=Instance.new('UISizeConstraint')
        limit.MaxSize=Vector2.new(420,257)
        limit.MinSize=Vector2.new(275,257)
        limit.Parent=card
        local corner=Instance.new('UICorner')
        corner.CornerRadius=UDim.new(0,9)
        corner.Parent=card
        local outline=Instance.new('UIStroke')
        outline.Color=Color3.fromRGB(104,72,181)
        outline.Thickness=1.5
        outline.Parent=card
        local function label(name,text,pos,size,color,font,scale,align)
            local obj=Instance.new('TextLabel')
            obj.Name=name
            obj.BackgroundTransparency=1
            obj.Position=pos
            obj.Size=size
            obj.Text=text
            obj.TextColor3=color
            obj.Font=font or Enum.Font.Gotham
            obj.TextSize=scale or 14
            obj.TextWrapped=true
            obj.TextXAlignment=align or Enum.TextXAlignment.Left
            obj.Parent=card
            return obj
        end
        label('Title','Jogo não suportado',UDim2.new(0,18,0,18),UDim2.new(1,-55,0,28),
            Color3.fromRGB(248,248,252),Enum.Font.GothamBold,19)
        label('Message','Caso queira sugerir um script para este jogo, entre em nosso Discord!',
            UDim2.new(0,18,0,58),UDim2.new(1,-36,0,49),
            Color3.fromRGB(211,207,219),Enum.Font.Gotham,14)
        label('PlaceId','PlaceId: '..tostring(placeId),
            UDim2.new(0,18,0,112),UDim2.new(1,-36,0,19),
            Color3.fromRGB(153,147,168),Enum.Font.Code,12)
        local close=Instance.new('TextButton')
        close.Name='Close'
        close.Text='×'
        close.TextSize=22
        close.Font=Enum.Font.GothamBold
        close.TextColor3=Color3.fromRGB(188,182,197)
        close.BackgroundTransparency=1
        close.Position=UDim2.new(1,-41,0,14)
        close.Size=UDim2.fromOffset(27,29)
        close.Parent=card
        close.MouseButton1Click:Connect(function() gui:Destroy() end)
        local function button(name,text,x,width,color)
            local obj=Instance.new('TextButton')
            obj.Name=name
            obj.Text=text
            obj.Font=Enum.Font.GothamMedium
            obj.TextSize=13
            obj.TextColor3=Color3.fromRGB(255,255,255)
            obj.AutoButtonColor=true
            obj.BackgroundColor3=color
            obj.BorderSizePixel=0
            obj.Position=UDim2.new(x,0,0,150)
            obj.Size=UDim2.new(width,0,0,39)
            obj.Parent=card
            local round=Instance.new('UICorner')
            round.CornerRadius=UDim.new(0,6)
            round.Parent=obj
            return obj
        end
        local copyGame=button('CopyGameLink','Copiar link do jogo',0.043,0.55,Color3.fromRGB(118,73,243))
        local copyDiscord=button('CopyDiscord','Copiar Discord',0.615,0.342,Color3.fromRGB(53,49,67))
        local notice=label('Feedback','',UDim2.new(0,18,0,199),UDim2.new(1,-36,0,39),
            Color3.fromRGB(181,165,232),Enum.Font.Gotham,12)
        local function copyLink(link,successMessage)
            local clipboard=type(setclipboard)=='function' and setclipboard
                or (type(toclipboard)=='function' and toclipboard)
            if clipboard then
                local copied=pcall(clipboard,link)
                if copied then notice.Text=successMessage return end
            end
            notice.Text='Área de transferência indisponível. Selecione e copie o link:'
            local fallback=card:FindFirstChild('ManualLink')
            if not fallback then
                fallback=Instance.new('TextBox')
                fallback.Name='ManualLink'
                fallback.Font=Enum.Font.Code
                fallback.TextSize=12
                fallback.TextColor3=Color3.fromRGB(238,230,255)
                fallback.BackgroundColor3=Color3.fromRGB(43,39,53)
                fallback.ClearTextOnFocus=false
                fallback.Position=UDim2.new(0,18,0,236)
                fallback.Size=UDim2.new(1,-36,0,22)
                fallback.Parent=card
                card.Size=UDim2.new(0.88,0,0,282)
                limit.MaxSize=Vector2.new(420,282)
                limit.MinSize=Vector2.new(275,282)
            end
            fallback.Text=link
            fallback:CaptureFocus()
        end
        copyGame.MouseButton1Click:Connect(function()
            copyLink(gameLink,'Link do jogo copiado! Envie no Discord para sugerir o port.')
        end)
        copyDiscord.MouseButton1Click:Connect(function()
            copyLink(discordLink,'Convite do Discord copiado!')
        end)
    end)
    if not ok then
        warn('[Prime Void Hub] Jogo não suportado. PlaceId='..tostring(placeId)..
            ' | '..tostring(reason)..' | Discord: https://discord.gg/PD3PeyG8aq')
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
