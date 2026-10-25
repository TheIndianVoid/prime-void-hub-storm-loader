-- Prime Void Hub | Universal Loader
local placeId=tonumber(game.PlaceId) or 0
local universeId=tonumber(game.GameId) or 0
local ports={
    {
        name='Storm Suite',
        officialName='Ride Storm',
        placeIds={[12593620250]=true},
        universeIds={[4420562665]=true},
        url='https://prime-void-hub-storm-gateway.vercel.app/prime-void-hub.lua',
        markers={'SOURCE GITHUB v','local function setupInterfaceAndLoops()','Prime Void Hub - Storm Suite'},
    },
    {
        name='Exu Security Lab',
        officialName='Steal An Exu',
        placeIds={[103076400317371]=true},
        universeIds={},
        url='https://prime-void-hub-exu-gateway.vercel.app/exu-security-lab.lua',
        markers={'local rarityList=','Prime Void | Exu Security Lab'},
    },
}
local selected
for _,port in ipairs(ports) do
    if port.placeIds[placeId] or port.universeIds[universeId] then
        selected=port
        break
    end
end
if not selected then
    error(('[Prime Void Hub] Jogo nao suportado. PlaceId=%s GameId=%s'):format(tostring(placeId),tostring(universeId)),0)
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
local chunk,compileError=loadstring(source)
if not chunk then
    error('[Prime Void Hub] Erro ao compilar '..selected.name..': '..tostring(compileError),0)
end
local success,runtimeError=pcall(chunk)
if not success then
    error('[Prime Void Hub] Erro em '..selected.name..': '..tostring(runtimeError),0)
end

-- Prime Void Hub Analytics v1.0 | explicit tester opt-in.
-- This runs only after a supported port initialized successfully.
-- No account data is submitted without a click on "Enviar dados do teste".
local function offerAnalyticsConsent()
    if genv.PV_Hub_AnalyticsAsked then return end
    local endpoint='https://prime-void-hub-exu-gateway.vercel.app/api/telemetry'
    local http=game:GetService('HttpService')
    local readyOk,readyResponse=pcall(function() return game:HttpGet(endpoint) end)
    if not readyOk then return end
    local parsedOk,ready=pcall(function() return http:JSONDecode(readyResponse) end)
    if not parsedOk or type(ready)~='table' or ready.enabled~=true or ready.consentRequired~=true then return end
    local envRequest=genv.request or genv.http_request
    local requestFn=type(envRequest)=='function' and envRequest
       or type(request)=='function' and request
       or (type(syn)=='table' and type(syn.request)=='function' and syn.request)
    if type(requestFn)~='function' then return end
    local players=game:GetService('Players')
    local player=players.LocalPlayer
    if not player or not player:FindFirstChildOfClass('PlayerGui') then return end
    local gui=Instance.new('ScreenGui')
    gui.Name='PVHubAnalyticsConsent'
    gui.ResetOnSpawn=false
    gui.IgnoreGuiInset=true
    gui.DisplayOrder=20000
    local holder=Instance.new('Frame')
    holder.Name='ConsentPanel'
    holder.AnchorPoint=Vector2.new(0.5,0.5)
    holder.Position=UDim2.new(0.5,0,0.5,0)
    holder.Size=UDim2.new(0.9,0,0,226)
    holder.BackgroundColor3=Color3.fromRGB(26,27,36)
    holder.BorderSizePixel=0
    holder.Parent=gui
    local maxSize=Instance.new('UISizeConstraint')
    maxSize.MaxSize=Vector2.new(460,250)
    maxSize.Parent=holder
    local round=Instance.new('UICorner')
    round.CornerRadius=UDim.new(0,13)
    round.Parent=holder
    local stroke=Instance.new('UIStroke')
    stroke.Color=Color3.fromRGB(105,83,176)
    stroke.Thickness=1
    stroke.Parent=holder
    local heading=Instance.new('TextLabel')
    heading.BackgroundTransparency=1
    heading.Position=UDim2.new(0,16,0,15)
    heading.Size=UDim2.new(1,-32,0,32)
    heading.Font=Enum.Font.GothamBold
    heading.Text='Prime Void Hub  |  Analytics'
    heading.TextSize=18
    heading.TextColor3=Color3.fromRGB(236,230,255)
    heading.TextXAlignment=Enum.TextXAlignment.Left
    heading.Parent=holder
    local description=Instance.new('TextLabel')
    description.BackgroundTransparency=1
    description.Position=UDim2.new(0,16,0,55)
    description.Size=UDim2.new(1,-32,0,96)
    description.TextWrapped=true
    description.TextYAlignment=Enum.TextYAlignment.Top
    description.TextXAlignment=Enum.TextXAlignment.Left
    description.Font=Enum.Font.Gotham
    description.TextSize=13
    description.TextColor3=Color3.fromRGB(215,211,224)
    description.Text='Autoriza enviar uma notificacao de teste ao Prime Void Feedback Bot?\nDados: username, UserId, jogo, versao do Hub e horario.\nRecusar nao altera as funcoes do Hub.'
    description.Parent=holder
    local function makeButton(label,color,x)
        local button=Instance.new('TextButton')
        button.Size=UDim2.new(0.5,-24,0,43)
        button.Position=UDim2.new(x,12,1,-59)
        button.BackgroundColor3=color
        button.BorderSizePixel=0
        button.AutoButtonColor=true
        button.Font=Enum.Font.GothamSemibold
        button.TextSize=12
        button.TextColor3=Color3.fromRGB(255,255,255)
        button.Text=label
        button.Parent=holder
        local corner=Instance.new('UICorner')
        corner.CornerRadius=UDim.new(0,8)
        corner.Parent=button
        return button
    end
    local sendButton=makeButton('Enviar dados do teste',Color3.fromRGB(104,77,181),0)
    local skipButton=makeButton('Continuar sem enviar',Color3.fromRGB(62,62,75),0.5)
    gui.Parent=player:FindFirstChildOfClass('PlayerGui')
    genv.PV_Hub_AnalyticsAsked=true
    skipButton.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
    sendButton.MouseButton1Click:Connect(function()
        gui:Destroy()
        task.spawn(function()
            pcall(function()
                local payload=http:JSONEncode({
                    consent=true,
                    username=player.Name,
                    userId=tostring(player.UserId),
                    placeId=tostring(game.PlaceId),
                    version=selected.name=='Storm Suite' and 'v1.0.0' or 'v1.1.2',
                })
                requestFn({
                    Url=endpoint,
                    Method='POST',
                    Headers={['Content-Type']='application/json'},
                    Body=payload,
                })
            end)
        end)
    end)
end
task.spawn(function() pcall(offerAnalyticsConsent) end)
