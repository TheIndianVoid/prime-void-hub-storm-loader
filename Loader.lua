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
        name='Exu Security Lab',
        version='v1.1.2',
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
-- Prime Void Hub | Analytics universal dos ports.
-- O distribuidor informa aos testers quais dados sao registrados.
-- Uma execucao por sessao; sem UI e sem coletar tokens, IP, HWID ou cookies.
local previousLog=genv.PV_Hub_AnalyticsSent==true
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
        local json=game:GetService('HttpService'):JSONEncode({
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
