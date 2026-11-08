-- Prime Void Hub | GRAU SP | TEST v0.4.2
-- PlaceId: 101953291486308
-- Native Obsidian UI; recovered legacy Rustcc catalog preserved.
-- New features are based on documented client interfaces in the supplied .rbxl.
-- All game-server actions are REQUESTS; neither acceptance nor entitlement is forged.
-- TEST universal loader only; main branch unchanged.

local PLACE_ID=101953291486308
if tonumber(game.PlaceId)~=PLACE_ID then
    warn('[PVH Grau SP] Unsupported PlaceId: '..tostring(game.PlaceId))
    return
end
local Players=game:GetService('Players')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local StarterGui=game:GetService('StarterGui')
local UserInputService=game:GetService('UserInputService')
local RunService=game:GetService('RunService')
local HttpService=game:GetService('HttpService')
local TeleportService=game:GetService('TeleportService')
local SoundService=game:GetService('SoundService')
local player=Players.LocalPlayer
if not player then return end
local env=type(getgenv)=='function' and getgenv() or _G
if type(env.PVH_GrauSP_Unload)=='function' then pcall(env.PVH_GrauSP_Unload) end

local VERSION='0.4.2-test'
local LIBRARY_URL='https://raw.githubusercontent.com/deividcomsono/Obsidian/82d402b5de7d8903915f1afe99b5b7e340e7cd28/Library.lua'
local LIBRARY_CDN='https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@82d402b5de7d8903915f1afe99b5b7e340e7cd28/Library.lua'
local LIBRARY_CACHE='primevoid_hub/Grau_SP/Configs/obsidian_82d402b5.lua' 
local CONFIG_DIR='primevoid_hub/Grau_SP/Configs'
local CONFIG_PATH=CONFIG_DIR..'/settings.json'
local REPORT_PATH='PVH_GrauSP_Checker.txt'
local SESSION_PATH='PVH_GrauSP_Session.txt'
local alive=true
local connections={}
local wheelOriginal={}
local wheelVehicle=nil
local cooldowns={}
local state={
    language='pt-BR',autoSave=true,animations=true,sounds=false,ifoodLongDistance=false,
    autoIFood=false,ifoodMode='Distante',ifoodCompleted=0,ifoodAutoStatus='off',
    showGamepasses=false,allCategories={},
    selectedCategory='Motos_Gratis',selectedVehicle=nil,search='',
    categories={},vehicles={},byCategory={},catalogSource='none',
    spawns=0,deletes=0,regions=0,orders=0,errors=0,
    raceMode=false,drift=false,grip=false,wheelieAssist=false,autoWheelie=false,wheelieAngle=27,
    ejectionAttempts=0,ghostLinks=0,ghostWalls=false,antiFall=true,
    fallScriptsDisabled=0,fallScriptsFound=0,ghostDynamicCount=0,ghostStaticCount=0,
    espRange=1200,espVehicleRange=250,espOccupiedOnly=true,pmTrack=false,pmRange=250,
    pmBumper=false,bumperContacts=0,bumperModel=nil,
    espVehicleCount=0,espPlayerCount=0,pmNearest='',
    ghost=false,espPlayers=false,espVehicles=false,pmRam=false,
    raceTicks=0,raceApplied=0,raceDenied=0,ramTouches=0,ramSuccess=0,ghostParts=0,
    vehicleReason='not_seated',physicsReason='unknown',ifoodOpen='not_attempted',
    lastVehicle=nil,ifoodStage='idle',gpsTarget=nil,gpsName='',
    lastReport='',status='Aguardando interface do jogo...',
}
local Library,Window,ui={},nil,{}
local gpsAttachment,gpsBillboard=nil,nil
local rebuilding=false
local lastServerNotice=0
local liveSpeed=0
local lastPhysicsStats=0
local clickSound=Instance.new('Sound')
clickSound.Name='PVH_GrauSP_Click'
clickSound.SoundId='rbxassetid://10066942189'
clickSound.Volume=0.18
clickSound.Parent=SoundService
local catalogRefreshSerial=0
local racePhysicsPossible=false
local releaseSuspension
local sessionLog={}
local sessionSeq=0
local lastLogFlush=0
local espHighlights={}
local espTags={}
local fallScriptOriginal={}
local lastFallCheck=0
local lastFallModel=nil
local pmNearestPlayer=nil
local bumperPart=nil
local bumperWeld=nil
local bumperCollisionLinks={}
local bumperContactConnection=nil
local bumperModel=nil
local lastBumperContact=0
local lastPMLog=0
local ghostVehicle=nil
local ghostLinks={}
local ghostGuardHum=nil
local ghostGuardStates={}
local lastGhostSeat=nil
local lastGhostHum=nil
local ghostSeatLostAt=nil
local lastReseatTry=0
local reseatAttempts=0
local manualDismountUntil=0
local lastGhostLog=0
local ramConnections={}
local ramVehicle=nil
local lastRamContact=0
local lastVehicleReason=''
local lastSeatName=''
local lastRaceProbe=0
local lastGhostRefresh=0
local function writeSession(force)
    if type(writefile)~='function' then return false end
    if not force and os.clock()-lastLogFlush<1.0 then return true end
    lastLogFlush=os.clock()
    return pcall(function()
        writefile(SESSION_PATH,table.concat(sessionLog,'\n')..'\n')
    end)
end
local function diagnosticSnapshot()
    return string.format('vehicle=%s seat=%s physics=%s speed=%.1f race=%s ticks=%d applied=%d denied=%d ghost=%d ramTouches=%d ramSuccess=%d ifood=%s',
        tostring(state.vehicleReason),tostring(lastSeatName),tostring(state.physicsReason),liveSpeed,
        tostring(state.raceMode),state.raceTicks,state.raceApplied,state.raceDenied,
        state.ghostLinks,state.ramTouches,state.ramSuccess,tostring(state.ifoodOpen))
end

local STR={
 ['pt-BR']={
  home='Início',vehicles='Veículos',race='Modo Corrida',delivery='iFood',police='PM',visuals='Visuais',
  travel='Teleportes',settings='Configurações',about='Sobre',
  welcome='Prime Void Hub • GRAU SP',
  hint='Seleção nativa de veículos e ferramentas de RP. Os limites e permissões são validados pelo servidor.',
  stats='Estado da sessão',catalog='Catálogo de veículos',filter='Categoria',vehicle='Veículo',
  search='Buscar veículo',searchPH='Digite parte do nome',refresh='Atualizar catálogo',
  showGamepasses='Mostrar veículos de Gamepass',
  gamepassHelp='Desativado: mostra veículos gratuitos e favoritos gratuitos. Ative para incluir categorias premium; possuir Gamepass ainda é necessário.',
  policeVehiclesGroup='Viaturas PM',
  spawn='Spawnar veículo',favorite='Favoritar veículo',unfavorite='Desfavoritar veículo',delete='Remover todos os veículos',confirmDelete='CONFIRMAR remoção (4s)',
  deleteSlot1='Remover veículo 1',deleteSlot2='Remover veículo 2',deleteTrailer='Remover carretinha',
  preview='Prévia',native='Origem: catálogo nativo',unknown='Não confirmado pelo servidor',
  raceMode='Modo Corrida',
  drift='Modo Drift (aderência reduzida)',grip='Aderência reforçada',
  wheelie='Estabilidade no grau (anti-queda local)',
  ghost='Ghost: veículos/jogadores',ghostWalls='Ghost: paredes e obstáculos',
  antiFall='Anti-queda (bloquear ejeção local)',
  espPlayers='ESP Jogadores',espVehicles='ESP Veículos',
  espRange='Alcance ESP Jogadores (studs)',espVehicleRange='Alcance ESP Veículos (studs)',
  espOccupiedOnly='Apenas veículos ativos',
  pmRam='Impacto PM (experimental: autoridade física)',pmVehicles='Viatura para spawn',
  pmSpawn='Spawnar viatura',raceDebug='Estado real da física',
  logExport='Salvar logs TXT',logInfo='Logs e Checker são gerados automaticamente na workspace.',
  raceGuide='Anti-queda age no script Falling nativo. Ghost evita contatos com veículos; paredes são opcionais. Rodas e chão permanecem sólidos. O servidor pode restaurar colisões e ejetar.',
  raceStatus='Sem veículo controlado',driveMode='Assistências',
  ifoodHelp='Auto iFood: coleta/entrega e código reais. Sem confirmação do servidor, o ciclo para. Pagamento maior não é seleção disponível no remote.',
  ifoodMode='Prioridade',autoIfuud='Auto iFood (continuar entregando)',autoIfuudHelp='O servidor só expõe prioridade por distância; maior pagamento não é verificável.',
  autoWheelie='Auto Grau (experimental)',wheelieAngle='Ângulo do grau',
  equipPhone='Equipar telefone',openDelivery='Abrir aplicativo iFood',
  findOrder='Localizar pedido',clearGPS='Limpar marcador GPS',ifoodLong='Preferir entregas distantes',cancelOrder='Cancelar rota atual',
  ifoodStatus='Aguardando pedido',gps='GPS de entrega',
  policeHelp='Radar de perseguição: rastreia jogadores próximos em veículos sem alterar a física de outros jogadores.',
  pmTrack='Radar PM: rastrear motoqueiros',pmRange='Alcance do radar (studs)',
  pmBumper='Para-choque ampliado (TEST local)',
  policeCars='Abrir categoria de viaturas',nearPlayers='Ver jogadores próximos',
  policeStatus='PM • acesso depende das regras e passes do jogo',
  spawnRegions='Escolha outra área do mapa (solicitação ao servidor)',
  sao='São Luís',guaruja='Guarujá',vidigal='Vidigal',igarata='Igaratá (outro jogo / passe)',
  regionWarn='Igaratá é outra experiência e exige autorização; não implementado neste port.',
  session='Sessão',autoSave='Auto Save',rejoin='Reentrar',
  preferences='Preferências',language='Idioma',animations='Animações',sounds='Sons da interface',
  save='Salvar configuração',reload='Carregar configuração',reset='Apagar configuração',
  checker='Diagnóstico',runChecker='Verificar funcionalidades',export='Salvar relatório TXT',
  diagnostics='Verificações de estrutura não substituem testes em servidor real.',
  aboutText='Port TEST baseado na source antiga Rustcc e no .rbxl GRAU SP fornecido. As funções novas só usam interfaces identificadas no cliente.',
  credits='Prime Void Hub • Grau SP  |  TEST v0.4.2',
  notReady='Objeto ainda não carregado',noCar='Selecione um veículo válido',
  requested='Solicitação enviada (resultado no servidor não confirmado)',
  error='Falha local',saved='Configuração salva',noStorage='Executor sem escrita local',
  removeWarning='Clique novamente para remover TODOS os seus veículos.',
  noRole='A fonte não mostra mecanismo de alistamento ou seleção de PM.',
  gpsNone='Nenhuma rota de entrega recebida',
 },
 ['en-US']={
  home='Home',vehicles='Vehicles',race='Race Mode',delivery='iFood',police='Police',visuals='Visuals',
  travel='Teleports',settings='Settings',about='About',
  welcome='Prime Void Hub • GRAU SP',
  hint='Native vehicle selector and RP tools. The server enforces vehicle limits and entitlements.',
  stats='Session status',catalog='Vehicle catalog',filter='Category',vehicle='Vehicle',
  search='Search vehicle',searchPH='Type part of the name',refresh='Refresh catalog',
  showGamepasses='Show Gamepass vehicles',
  gamepassHelp='Off: free vehicles and free favorites only. Enable to show premium categories; gamepass ownership is still required.',
  policeVehiclesGroup='Police vehicles',
  spawn='Spawn vehicle',favorite='Add to favorites',unfavorite='Remove favorite',delete='Delete all vehicles',confirmDelete='CONFIRM delete (4s)',
  deleteSlot1='Delete vehicle 1',deleteSlot2='Delete vehicle 2',deleteTrailer='Delete trailer',
  preview='Preview',native='Source: native catalog',unknown='Not server-confirmed',
  raceMode='Race Mode',
  drift='Drift mode (reduced traction)',grip='Enhanced grip',
  wheelie='Wheelie stability (local anti-fall)',
  ghost='Ghost: vehicles/players',ghostWalls='Ghost: walls/obstacles',
  antiFall='Anti-fall (disable local ejection)',
  espPlayers='Player ESP',espVehicles='Vehicle ESP',
  espRange='Player ESP range (studs)',espVehicleRange='Vehicle ESP range (studs)',
  espOccupiedOnly='Occupied vehicles only',
  pmRam='Police impact (experimental: physics authority)',pmVehicles='Police car to spawn',
  pmSpawn='Spawn police vehicle',raceDebug='Actual physics status',
  logExport='Save log TXT',logInfo='Session logs and Checker export automatically to workspace.',
  raceGuide='Anti-fall targets the native Falling script. Ghost avoids vehicles; walls are optional. Wheels and ground remain solid. The server can override both.',
  raceStatus='No controlled vehicle',driveMode='Assists',
  ifoodHelp='Auto iFood: real pickup/delivery and server-provided code. Stops if server rejects the action. High-pay selection is not exposed.',
  ifoodMode='Priority',autoIfuud='Auto iFood (repeat deliveries)',autoIfuudHelp='The server only exposes distance priority; ',
  autoWheelie='Auto Wheelie (experimental)',wheelieAngle='Wheelie angle',
  equipPhone='Equip phone',openDelivery='Open iFood app',
  findOrder='Find an order',clearGPS='Clear GPS marker',ifoodLong='Prefer distant deliveries',cancelOrder='Cancel current route',
  ifoodStatus='Waiting for order',gps='Delivery GPS',
  policeHelp='Pursuit radar: tracks nearby mounted players without changing other players physics.',
  pmTrack='Police radar: track riders',pmRange='Radar range (studs)',
  pmBumper='Extended bumper (local TEST)',
  policeCars='Show police vehicles',nearPlayers='Show nearby players',
  policeStatus='Police • access is subject to game rules and passes',
  spawnRegions='Choose a different map spawn (server request)',
  sao='São Luís',guaruja='Guarujá',vidigal='Vidigal',igarata='Igaratá (other game / pass)',
  regionWarn='Igaratá is another experience and requires entitlement; not implemented here.',
  session='Session',autoSave='Auto Save',rejoin='Rejoin',
  preferences='Preferences',language='Language',animations='Animations',sounds='Interface sounds',
  save='Save config',reload='Load config',reset='Delete config',
  checker='Diagnostics',runChecker='Check features',export='Save TXT report',
  diagnostics='Structural checks do not replace live server testing.',
  aboutText='TEST port based on legacy Rustcc and the supplied GRAU SP .rbxl. New functions use documented client interfaces only.',
  credits='Prime Void Hub • Grau SP  |  TEST v0.4.2',
  notReady='Game object not loaded',noCar='Select a valid vehicle',
  requested='Request sent (server outcome unconfirmed)',
  error='Local error',saved='Config saved',noStorage='Executor has no local file write API',
  removeWarning='Click again to remove ALL of your vehicles.',
  noRole='No verified police enrollment/team selector found in client source.',
  gpsNone='No delivery route received',
 }
}
local function tr(k) return (STR[state.language] or STR['pt-BR'])[k] or k end
local function track(signal,callback)
    local c=signal:Connect(callback)
    connections[#connections+1]=c
    return c
end
local function log(code,message)
    if not alive then return end
    local msg='[PVH Grau SP]['..tostring(code)..'] '..tostring(message or '')
    warn(msg)
    sessionSeq=sessionSeq+1
    sessionLog[#sessionLog+1]=string.format('%05d [%s][%s] %s',sessionSeq,
        os.date('!%H:%M:%S'),tostring(code),tostring(message or ''))
    if #sessionLog>2400 then table.remove(sessionLog,1) end
    writeSession(false)
end
-- Cache helpers must be lexically declared BEFORE requestObsidianSource.
local function ensureFolder()
    if type(makefolder)~='function' then return end
    for _,part in ipairs({'primevoid_hub','primevoid_hub/Grau_SP',CONFIG_DIR}) do
        pcall(function()if type(isfolder)~='function' or not isfolder(part) then makefolder(part)end end)
    end
end
local function cacheObsidianText(body)
    -- A cache failure must NEVER prevent a valid downloaded UI from opening.
    if type(writefile)~='function' then return end
    local ok,err=pcall(function()
        ensureFolder()
        writefile(LIBRARY_CACHE,body)
    end)
    if not ok then log('UI_CACHE_WARN',tostring(err)) end
end
-- Some executors expose a nonstandard HttpGet that returns a Roblox Instance
-- rather than the source text. Always validate the response BEFORE loadstring.
-- Preserve the pinned Obsidian commit and keep an optional local fallback.
local verifiedObsidianText=nil
local function verifyObsidianText(candidate)
    return type(candidate)=='string' and #candidate>20000
        and candidate:find('return Library',1,true)~=nil
end
local function requestObsidianSource()
    if verifyObsidianText(verifiedObsidianText) then
        return verifiedObsidianText,'memory'
    end
    local attempts={}
    local requestFns={
        {'request',env.request or request},
        {'http_request',env.http_request or http_request},
        {'syn.request',(type(env.syn)=='table' and env.syn.request)
            or (type(syn)=='table' and syn.request)},
        {'fluxus.request',(type(env.fluxus)=='table' and env.fluxus.request)
            or (type(fluxus)=='table' and fluxus.request)},
    }
    local urls={LIBRARY_URL,LIBRARY_CDN}
    for _,url in ipairs(urls) do
        for _,entry in ipairs(requestFns) do
            if type(entry[2])=='function' then
                local ok,response=pcall(entry[2],{
                    Url=url,Method='GET',Headers={Accept='text/plain'}
                })
                local body=type(response)=='table' and (response.Body or response.body)
                    or response
                if ok and verifyObsidianText(body) then
                    verifiedObsidianText=body
                    log('UI_FETCH','OK via '..entry[1]..' | bytes='..#body)
                    cacheObsidianText(body)
                    return body,entry[1]
                end
                attempts[#attempts+1]=entry[1]..'='..(ok and typeof(body)
                    or tostring(response):sub(1,100))
            end
        end
        local nativeMethods={
            {'game:HttpGet',function() return game:HttpGet(url) end},
            {'game:HttpGetAsync',function() return game:HttpGetAsync(url) end},
            {'HttpService:GetAsync',function() return HttpService:GetAsync(url) end},
        }
        for _,entry in ipairs(nativeMethods) do
            local ok,body=pcall(entry[2])
            if ok and verifyObsidianText(body) then
                verifiedObsidianText=body
                log('UI_FETCH','OK via '..entry[1]..' | bytes='..#body)
                cacheObsidianText(body)
                return body,entry[1]
            end
            attempts[#attempts+1]=entry[1]..'='..(ok and typeof(body)
                or tostring(body):sub(1,100))
        end
    end
    if type(isfile)=='function' and type(readfile)=='function' then
        local ok,body=pcall(function()
            if isfile(LIBRARY_CACHE) then return readfile(LIBRARY_CACHE) end
        end)
        if ok and verifyObsidianText(body) then
            verifiedObsidianText=body
            log('UI_FETCH','OK via local cached pinned Obsidian')
            return body,'cache'
        end
        attempts[#attempts+1]='cache='..(ok and typeof(body) or tostring(body):sub(1,100))
    end
    local summary=table.concat(attempts,'; ')
    log('UI_FETCH_ERROR',summary)
    error('Obsidian source unavailable as Lua string: '..summary,0)
end
local function loadObsidianLibrary()
    local src,method=requestObsidianSource()
    -- Do not ever pass a Roblox Instance or a response table to loadstring.
    if type(src)~='string' then
        error('Unexpected Obsidian type: '..typeof(src),0)
    end
    local fn,err=loadstring(src)
    if not fn then error('Obsidian compile ('..method..'): '..tostring(err),0) end
    local result=fn()
    if type(result)~='table' or type(result.CreateWindow)~='function' then
        error('Obsidian returned invalid library ('..typeof(result)..')',0)
    end
    return result
end
local function reportStatus(message)
    state.status=tostring(message or '')
    log('STATUS',state.status)
    if ui.lastStatus and ui.lastStatus.SetText then pcall(function()ui.lastStatus:SetText(state.status)end) end
end
local function saveConfig()
    if type(writefile)~='function' then return false end
    ensureFolder()
    return pcall(function()
        writefile(CONFIG_PATH,HttpService:JSONEncode({schema=2,
            language=state.language,autoSave=state.autoSave,ifoodLongDistance=state.ifoodLongDistance,
            ifoodMode=state.ifoodMode,autoWheelie=state.autoWheelie,wheelieAngle=state.wheelieAngle,
            showGamepasses=state.showGamepasses,
            ghostWalls=state.ghostWalls,antiFall=state.antiFall,
            espRange=state.espRange,espVehicleRange=state.espVehicleRange,
            espOccupiedOnly=state.espOccupiedOnly,
            pmTrack=state.pmTrack,pmRange=state.pmRange,pmBumper=state.pmBumper,
            animations=state.animations,sounds=state.sounds,
            raceMode=state.raceMode,
            ghost=state.ghost,espPlayers=state.espPlayers,espVehicles=state.espVehicles,pmRam=state.pmRam,
            drift=state.drift,grip=state.grip,wheelieAssist=state.wheelieAssist,
            selectedCategory=state.selectedCategory}))
    end)
end
local function loadConfig()
    if type(isfile)~='function' or type(readfile)~='function' then return false end
    local ok,data=pcall(function()
        if isfile(CONFIG_PATH) then return HttpService:JSONDecode(readfile(CONFIG_PATH)) end
    end)
    if not ok or type(data)~='table' then return false end
    for _,k in ipairs({'autoSave','animations','sounds','raceMode','drift','grip','wheelieAssist','autoWheelie','ifoodLongDistance','showGamepasses','ghost','ghostWalls','antiFall','espPlayers','espVehicles','espOccupiedOnly','pmTrack','pmBumper','pmRam'}) do
        if type(data[k])=='boolean' then state[k]=data[k] end
    end
    if data.language=='pt-BR' or data.language=='en-US' then state.language=data.language end
    if type(data.selectedCategory)=='string' then state.selectedCategory=data.selectedCategory end
    if data.ifoodMode=='Distante' or data.ifoodMode=='Maior pagamento' then state.ifoodMode=data.ifoodMode end
    state.wheelieAngle=math.clamp(math.floor(tonumber(data.wheelieAngle) or 27),12,45)
    state.autoIFood=false -- opt-in per session
    state.autoWheelie=false -- physical torque opt-in per session
    if state.drift and state.grip then state.grip=false end
    state.espRange=math.clamp(math.floor(tonumber(data.espRange) or 1200),100,2500)
    state.espVehicleRange=math.clamp(math.floor(tonumber(data.espVehicleRange) or 250),50,800)
    state.pmRange=math.clamp(math.floor(tonumber(data.pmRange) or 250),50,800)
    -- Legacy PM impact could not affect other server-owned vehicles; don't auto-enable.
    state.pmRam=false
    -- Local bumper is opt-in every fresh session; never reapply physical proxies silently.
    state.pmBumper=false
    return true
end
loadConfig()
-- Retire experimental racing, ghost collision and bumper modes from old saved profiles.
state.raceMode=false;state.drift=false;state.grip=false;state.ghost=false;state.ghostWalls=false;state.pmBumper=false
state.autoWheelie=false
local function changed() if state.autoSave then saveConfig()end end
local function remote(name)
    local dir=ReplicatedStorage:FindFirstChild('Remotes')
    local r=dir and dir:FindFirstChild(name)
    return r and r:IsA('RemoteEvent') and r or nil
end
local function fire(name,...)
    local r=remote(name)
    if not r then
        state.errors=state.errors+1
        reportStatus(tr('notReady')..': Remotes.'..name)
        return false
    end
    local ok,err=pcall(r.FireServer,r,...)
    if not ok then
        state.errors=state.errors+1
        reportStatus(tr('error')..': '..tostring(err))
        return false
    end
    log('REMOTE_'..name,'request dispatched')
    return true
end
local function limitCall(key,seconds)
    if (os.clock()-(cooldowns[key] or -math.huge))<seconds then return false end
    cooldowns[key]=os.clock()
    return true
end

-- Gamepass categories are deliberately opt-in; this affects ONLY what the
-- selector displays. It does not bypass the game's entitlement checks.
local function freeCategory(name)
    if name=='Favoritos' then return true end
    return type(name)=='string' and name:lower():find('gratis',1,true)~=nil
end
local function visibleCategories()
    local result={}
    for _,cat in ipairs(state.allCategories) do
        if state.showGamepasses or freeCategory(cat) then result[#result+1]=cat end
    end
    return result
end

-- Rustcc-preserving catalog discovery: reuse existing CarMenu inventory + thumbnails.
local function getMenu()
    local pg=player:FindFirstChildOfClass('PlayerGui')
    local live=pg and pg:FindFirstChild('CarMenu')
    local template=StarterGui:FindFirstChild('CarMenu')
    local root=live or template
    local holders=root and root:FindFirstChild('Holders')
    local menu=holders and holders:FindFirstChild('Menu')
    local list=menu and menu:FindFirstChild('ScrollVeiculos')
    return list,live and 'PlayerGui' or (template and 'StarterGui' or 'missing')
end
local function nativePreview(button)
    local im=button:FindFirstChild('Image')
    if im and (im:IsA('ImageLabel') or im:IsA('ImageButton')) then return im.Image end
    for _,v in ipairs(button:GetChildren()) do
        if (v:IsA('ImageLabel') or v:IsA('ImageButton')) and v.Name~='Favoritar' then return v.Image end
    end
    return nil
end
local function refreshCatalog()
    local root,origin=getMenu()
    if not root then return false end
    local categories,byCategory,flat,index={},{},{},{}
    local total=0
    for _,folder in ipairs(root:GetChildren()) do
        if folder:IsA('Folder') and folder.Name~='Favoritos' then
            local items={}
            for _,item in ipairs(folder:GetChildren()) do
                if item:IsA('TextButton') and item.Name~='Template' then
                    local entry={name=item.Name,category=folder.Name,image=nativePreview(item)}
                    items[#items+1]=entry
                    index[item.Name]=entry
                    flat[#flat+1]=entry
                    total=total+1
                end
            end
            if #items>0 then
                table.sort(items,function(a,b)return a.name:lower()<b.name:lower()end)
                categories[#categories+1]=folder.Name
                byCategory[folder.Name]=items
            end
        end
    end
    if root:FindFirstChild('Favoritos') then
        local favorites={}
        for _,item in ipairs(root.Favoritos:GetChildren()) do
            if item:IsA('TextButton') and item.Name~='Template' and index[item.Name] then
                favorites[#favorites+1]=index[item.Name]
            end
        end
        categories[#categories+1]='Favoritos'
        byCategory.Favoritos=favorites
    end
    local priority={Motos_Gratis=1,Carros_Gratis=2,Viaturas_Gratis=3,['Pack policia']=4,Favoritos=99}
    table.sort(categories,function(a,b)
        local ap,bp=priority[a] or 50,priority[b] or 50
        if ap~=bp then return ap<bp end
        return a:lower()<b:lower()
    end)
    state.byCategory=byCategory
    state.allCategories=categories
    state.categories=visibleCategories()
    state.vehicles=flat
    state.catalogSource=origin
    local isVisible=false
    for _,cat in ipairs(state.categories) do
        if cat==state.selectedCategory then isVisible=true;break end
    end
    if not isVisible then
        state.selectedCategory=byCategory.Motos_Gratis and 'Motos_Gratis' or state.categories[1]
    end
    log('CATALOG',string.format('source=%s categories=%d visible=%d vehicles=%d premium=%s',
        origin,#categories,#state.categories,total,tostring(state.showGamepasses)))
    return #categories>0
end
local function filteredVehicles()
    local items=state.byCategory[state.selectedCategory] or {}
    local values={}
    local needle=(state.search or ''):lower()
    for _,v in ipairs(items) do
        if (state.showGamepasses or freeCategory(v.category))
            and (needle=='' or v.name:lower():find(needle,1,true)) then
            values[#values+1]=v.name
        end
    end
    return values
end
local function chosenVehicle()
    for _,item in ipairs(state.byCategory[state.selectedCategory] or {}) do
        if item.name==state.selectedVehicle then return item end
    end
    return nil
end
local function requestSpawn()
    local car=chosenVehicle()
    if not car then reportStatus(tr('noCar'));return end
    if not state.showGamepasses and not freeCategory(car.category) then
        log('SPAWN_BLOCKED','premium category hidden by gamepass filter')
        return
    end
    if not limitCall('spawn',0.85) then return end
    if fire('SpawnCar',car.category,car.name) then
        state.spawns=state.spawns+1
        reportStatus(tr('requested')..': '..car.name)
        log('SPAWN',car.category..'/'..car.name..' (pending server validation)')
    end
end
local updateCarOptions
local function setFavorite(on)
    local chosen=chosenVehicle()
    if not chosen then reportStatus(tr('noCar'));return end
    if not limitCall('favorite',0.5) then return end
    if fire('FavoritesCar','Salvar',chosen.name,on==true) then
        reportStatus(tr('requested')..' • FavoritesCar('..chosen.name..')')
        -- The native CarMenu handles the server's persistent favorites list.
        -- Refresh its category once the client UI receives the updated state.
        task.delay(0.8,function()
            if alive then refreshCatalog();updateCarOptions()end
        end)
    end
end
local pendingDeleteUntil=0
local function deleteAll()
    -- A single Obsidian click sends exactly one native DeleteCar request.
    if not limitCall('delete',1.1) then return end
    if fire('DeleteCar','tudo') then
        state.deletes=state.deletes+1
        reportStatus(tr('requested')..' • DeleteCar(tudo)')
    end
end
local function deleteSpecific(which,num)
    if not limitCall('delete',0.8) then return end
    if fire('DeleteCar',which,num) then
        state.deletes=state.deletes+1
        reportStatus(tr('requested')..' • DeleteCar('..tostring(which)..')')
    end
end
local zoneReferences={
    SaoLuis_Spawn={9128.0,237.0,5208.0},
    Guaruja_Spawn={8497.6,-45.8,-4194.3},
    Vidigal_Spawn={13348.6,-42.6,-2917.3},
}
local function travelNow(position,label)
    if typeof(position)~='Vector3' then return false,'destination_missing' end
    local char=player.Character
    local hum=char and char:FindFirstChildOfClass('Humanoid')
    local root=char and char:FindFirstChild('HumanoidRootPart')
    if not root or not hum or hum.Health<=0 then return false,'character_unavailable' end
    local seat=hum.SeatPart
    local model=seat and seat:FindFirstAncestorWhichIsA('Model') or nil
    if seat and model then
        local checker=env.isnetworkowner or isnetworkowner
        local owner=nil
        if type(checker)=='function' then
            local okOwner,owned=pcall(checker,seat.AssemblyRootPart or seat)
            if okOwner then owner=owned end
        end
        if owner~=true then return false,'vehicle_network_ownership_unavailable' end
        local ok,err=pcall(function()
            model:PivotTo(CFrame.new(position+Vector3.new(0,5,0))*(model:GetPivot()-model:GetPivot().Position))
        end)
        if not ok then return false,tostring(err) end
    elseif seat then
        return false,'not_a_drivable_vehicle'
    else
        local ok,err=pcall(function()
            char:PivotTo(CFrame.new(position+Vector3.new(0,4,0))*root.CFrame.Rotation)
        end)
        if not ok then return false,tostring(err) end
    end
    log('TELEPORT_LOCAL','target='..tostring(label)..' | awaiting replication')
    task.delay(1.2,function()
        if not alive then return end
        local current=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
        if current then
            local dist=(current.Position-position).Magnitude
            if dist>90 then
                log('TELEPORT_REJECTED',tostring(label)..' distance='..math.floor(dist))
                reportStatus('Teleporte não aceito pelo servidor: '..tostring(label))
            else
                log('TELEPORT_NEAR','target='..tostring(label)..' | '..math.floor(dist)..' studs')
            end
        end
    end)
    return true
end
local function findLocationInMap(key)
    -- Names and hierarchy taken from the submitted .rbxl, not guessed coords.
    local avenida=workspace:FindFirstChild('Avenida Paulista')
    if not avenida then return nil,'Avenida Paulista não replicada' end
    local pm=avenida:FindFirstChild('Policia Militar')
    local shop=avenida:FindFirstChild('Outlet Dichava')
    local target
    if key=='PM_Batalhao' then
        target=pm and (pm:FindFirstChild('Patio') or pm)
    elseif key=='PM_Uniforme' then
        local clothes=pm and pm:FindFirstChild('Roupa')
        target=clothes and (clothes:FindFirstChild('Uniform PM') or clothes:FindFirstChild('Uniform ROCAM'))
        target=target or clothes or pm
    elseif key=='LojaCapacetes' then
        target=shop and (shop:FindFirstChild('Capacetes') or shop:FindFirstChild('Porta') or shop)
    end
    if not target then return nil,'Local ainda não carregado no mapa' end
    local part=target:IsA('BasePart') and target or target:FindFirstChildWhichIsA('BasePart',true)
    if not part then
        local fallback=key=='LojaCapacetes' and shop or pm
        part=fallback and fallback:FindFirstChildWhichIsA('BasePart',true)
    end
    if not part then return nil,'Sem posição física replicada para '..key end
    return part.Position,nil,part
end
local function changeRegion(destination)
    if not limitCall('region',1.5) then return end
    local fixed=zoneReferences[destination]
    local pos,locationReason
    if destination=='PM_Batalhao' or destination=='PM_Uniforme' or destination=='LojaCapacetes' then
        pos,locationReason=findLocationInMap(destination)
        if not pos then
            reportStatus('TP indisponível: '..tostring(locationReason))
            log('MAP_LOCATION_UNAVAILABLE',destination..' : '..tostring(locationReason))
            return
        end
    elseif fixed then
        pos=Vector3.new(fixed[1],fixed[2],fixed[3])
    else
        reportStatus('Destino indisponível')
        return
    end
    for _,marker in ipairs(workspace:GetDescendants()) do
        if marker.Name==destination or marker.Name==destination:gsub('_Spawn','') then
            if marker:IsA('BasePart') then pos=marker.Position;break end
            if marker:IsA('Model') and marker.PrimaryPart then pos=marker.PrimaryPart.Position;break end
        end
    end
    local ok,reason=travelNow(pos,destination)
    if ok then state.regions=state.regions+1;reportStatus('Teleporte local: '..destination)
    else reportStatus('Teleporte indisponível: '..tostring(reason))end
end

-- Vehicle handling is based on Humanoid.SeatPart, A-Chassis DriveSeat and
-- explicit diagnostic reasons. The source dump contains undecodable Drive.lua,
-- so the actual server authority MUST be checked in each live session.
local function getVehicle()
    local char=player.Character
    local hum=char and char:FindFirstChildOfClass('Humanoid')
    local seat=hum and hum.SeatPart
    if not seat then state.vehicleReason='not_seated';return nil,nil end
    if not seat:IsA('Seat') and not seat:IsA('VehicleSeat') then
        state.vehicleReason='not_drive_seat';return nil,nil
    end
    if seat.Occupant and seat.Occupant~=hum then
        state.vehicleReason='seat_other_occupant';return nil,nil
    end
    local model=seat:FindFirstAncestorWhichIsA('Model')
    local best=model
    for i=1,5 do
        if not model or model==workspace then break end
        if model:FindFirstChild('Wheels') or model:FindFirstChild('Tuner')
            or model:FindFirstChild('DriveSeat') then best=model;break end
        model=model.Parent and model.Parent:FindFirstAncestorWhichIsA('Model') or nil
    end
    if not best then state.vehicleReason='no_vehicle_model';return nil,nil end
    local root=seat.AssemblyRootPart or seat
    if root.Anchored then state.vehicleReason='anchored_assembly';return nil,nil end
    state.vehicleReason='drive_seat_ok'
    return best,seat
end
local function ownsPhysics(part)
    if not part then return false,'missing_part' end
    local fn=env.isnetworkowner or isnetworkowner
    if type(fn)=='function' then
        local ok,yes=pcall(fn,part)
        if ok then return yes==true,yes and 'owner_confirmed' or 'not_owner' end
        return false,'ownership_check_error'
    end
    return nil,'ownership_not_detectable'
end
local function restoreWheels()
    for part,props in pairs(wheelOriginal) do
        if typeof(part)=='Instance' and part.Parent then
            pcall(function()part.CustomPhysicalProperties=props==false and nil or props end)
        end
    end
    table.clear(wheelOriginal)
    wheelVehicle=nil
end
local function wheelParts(model)
    local w=model and model:FindFirstChild('Wheels',true)
    if not w then return {} end
    local parts={}
    for _,v in ipairs(w:GetDescendants()) do
        if v:IsA('BasePart') and v.CanCollide then parts[#parts+1]=v end
    end
    return parts
end
local lastWheelStyle=''
local function setWheelMode(model)
    if wheelVehicle~=model then restoreWheels()end
    if not (state.raceMode and (state.drift or state.grip)) then restoreWheels();return end
    wheelVehicle=model
    for _,wheel in ipairs(wheelParts(model)) do
        if wheelOriginal[wheel]==nil then wheelOriginal[wheel]=wheel.CustomPhysicalProperties or false end
        local original=wheelOriginal[wheel]
        local data=original~=false and original or wheel.CurrentPhysicalProperties
        if not data then data=PhysicalProperties.new(0.7,0.8,0.5,100,100)end
        local friction=state.drift and 0.60 or 1.18
        pcall(function()
            wheel.CustomPhysicalProperties=PhysicalProperties.new(
                math.clamp(data.Density,0.01,100),friction,
                math.clamp(data.Elasticity,0,1),20,20)
        end)
    end
end
-- Falling scripts are the source of ejections in the supplied Grau SP place.
-- In several native bikes, Tuner.Interface.Falling detects a sudden drop in
-- AssemblyLinearVelocity.Magnitude (20-25 studs/s), destroys SeatWeld and
-- fires variableserver("ragdoll", true, DriveSeat). Merely changing Humanoid
-- states does not prevent that script from detaching the rider.
-- Disable ONLY local Falling LocalScripts of the occupied bike while the
-- anti-fall guard is enabled; preserve original Enabled/Disabled values.
local function restoreFallScripts()
    lastFallModel=nil
    lastFallCheck=0
    for scriptObj,original in pairs(fallScriptOriginal) do
        if typeof(scriptObj)=='Instance' and scriptObj.Parent then
            pcall(function()scriptObj.Disabled=original end)
        end
        fallScriptOriginal[scriptObj]=nil
    end
    state.fallScriptsDisabled=0
end
local function refreshFallScripts(model)
    local shouldGuard=state.antiFall
    if not model or not shouldGuard then
        if next(fallScriptOriginal) then restoreFallScripts() end
        return
    end
    if lastFallModel==model and os.clock()-lastFallCheck<0.3 then return end
    lastFallModel=model
    lastFallCheck=os.clock()
    local desired={}
    local found=0
    for _,node in ipairs(model:GetDescendants()) do
        if node:IsA('LocalScript') and node.Name=='Falling' then
            desired[node]=true
            found=found+1
            if fallScriptOriginal[node]==nil then
                local ok,wasDisabled=pcall(function()return node.Disabled end)
                if ok then
                    fallScriptOriginal[node]=wasDisabled
                    local disabled=pcall(function()node.Disabled=true end)
                    log('FALL_SCRIPT',node:GetFullName()..' | disabled='..tostring(disabled))
                end
            else
                local ok,disabled=pcall(function()return node.Disabled end)
                if ok and not disabled then pcall(function()node.Disabled=true end) end
            end
        end
    end
    for node,original in pairs(fallScriptOriginal) do
        if not desired[node] then
            if node.Parent then pcall(function()node.Disabled=original end) end
            fallScriptOriginal[node]=nil
        end
    end
    state.fallScriptsFound=found
    local n=0;for _ in pairs(fallScriptOriginal) do n=n+1 end
    state.fallScriptsDisabled=n
end
local function restoreFallGuard()
    if ghostGuardHum and ghostGuardHum.Parent then
        for kind,old in pairs(ghostGuardStates) do
            pcall(function()ghostGuardHum:SetStateEnabled(kind,old)end)
        end
    end
    ghostGuardHum=nil
    table.clear(ghostGuardStates)
end
local function guardRider(hum,seat)
    if not state.antiFall or not hum or not seat then return end
    if ghostGuardHum~=hum then
        restoreFallGuard()
        ghostGuardHum=hum
        for _,kind in ipairs({Enum.HumanoidStateType.FallingDown,Enum.HumanoidStateType.Ragdoll}) do
            local ok,old=pcall(function()return hum:GetStateEnabled(kind)end)
            if ok then
                ghostGuardStates[kind]=old
                pcall(function()hum:SetStateEnabled(kind,false)end)
            end
        end
        log('FALL_GUARD','Local rider states guarded; Falling LocalScripts handled separately')
    end
    lastGhostSeat=seat
    lastGhostHum=hum
    ghostSeatLostAt=nil
    reseatAttempts=0
end

local function clearGhostLinks()
    for part,others in pairs(ghostLinks) do
        for other,link in pairs(others) do
            if typeof(link)=='Instance' then pcall(function()link:Destroy()end)end
            others[other]=nil
        end
        ghostLinks[part]=nil
    end
    state.ghostLinks=0
    state.ghostParts=0
end
local function restoreGhost()
    clearGhostLinks()
    restoreFallGuard()
    ghostVehicle=nil
    lastGhostSeat=nil
    lastGhostHum=nil
    ghostSeatLostAt=nil
    state.ghostParts=0
    state.ghostStaticCount=0
    state.ghostDynamicCount=0
end
local function ghostTargetType(part,model,character,seatPosition)
    if not part:IsA('BasePart') or not part.CanCollide
        or part:IsDescendantOf(model) or (character and part:IsDescendantOf(character)) then
        return nil
    end
    -- Exclude roads, floors and terrain so the bike remains supported.
    -- This is a geometry heuristic, never a guarantee on arbitrary maps.
    local ancestor=part:FindFirstAncestorWhichIsA('Model')
    for _=1,5 do
        if not ancestor or ancestor==workspace then break end
        if ancestor:FindFirstChildOfClass('Humanoid')
            or ancestor:FindFirstChild('DriveSeat')
            or ancestor:FindFirstChild('Wheels')
            or ancestor:FindFirstChildWhichIsA('VehicleSeat') then
            return state.ghost and 'dynamic' or nil
        end
        ancestor=ancestor.Parent and ancestor.Parent:FindFirstAncestorWhichIsA('Model') or nil
    end
    if not state.ghostWalls then return nil end
    if not part.Anchored then return nil end
    local low=part.Name:lower()
    for _,bad in ipairs({'road','asfalto','street','piso','floor','chao','chão','calçada','calcada','rua','terreno','grass','ground','pavement','bridge'}) do
        if low:find(bad,1,true) then return nil end
    end
    local size=part.Size
    -- A very wide, flat horizontal surface is probably road/floor, not wall.
    if size.Y<=math.min(size.X,size.Z)*0.45 and
        part.CFrame.UpVector.Y>0.75 then return nil end
    if size.Y<2.7 and size.X>6 and size.Z>6 then return nil end
    return 'static'
end
local function updateGhost(model,seat)
    if not (state.ghost or state.ghostWalls) or not model then return end
    if ghostVehicle~=model then clearGhostLinks();ghostVehicle=model;lastGhostRefresh=0 end
    local hum=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
    if state.antiFall then guardRider(hum,seat) end
    -- Refresh frequently enough for moving vehicles. No global map-wide scan.
    if os.clock()-lastGhostRefresh<0.18 then return end
    lastGhostRefresh=os.clock()
    local origin=seat and (seat.AssemblyRootPart or seat)
    if not origin then return end
    local own={}
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA('BasePart') and part.CanCollide then
            own[#own+1]=part
            if #own>=24 then break end
        end
    end
    if hum and player.Character then
        for _,part in ipairs(player.Character:GetDescendants()) do
            if part:IsA('BasePart') and part.CanCollide then
                own[#own+1]=part
                if #own>=34 then break end
            end
        end
    end
    local velocity=origin.AssemblyLinearVelocity
    local speed=velocity.Magnitude
    local range=math.clamp(35+speed*0.6,45,95)
    local params=OverlapParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={model,player.Character}
    params.MaxParts=350
    local success,near=pcall(function()
        return workspace:GetPartBoundsInRadius(origin.Position,range,params)
    end)
    if not success then
        if os.clock()-lastGhostLog>10 then
            lastGhostLog=os.clock()
            log('GHOST_SCAN_UNAVAILABLE',tostring(near))
        end
        return
    end
    local foreign={}
    local types={}
    for _,part in ipairs(near) do
        local kind=ghostTargetType(part,model,player.Character,origin.Position)
        if kind then
            foreign[#foreign+1]=part
            types[part]=kind
        end
    end
    local function distanceToBounds(point,part)
        local v=part.CFrame:PointToObjectSpace(point)
        local half=part.Size*0.5
        local dx=math.max(0,math.abs(v.X)-half.X)
        local dy=math.max(0,math.abs(v.Y)-half.Y)
        local dz=math.max(0,math.abs(v.Z)-half.Z)
        return math.sqrt(dx*dx+dy*dy+dz*dz)
    end
    table.sort(foreign,function(a,b)
        return distanceToBounds(origin.Position,a)<distanceToBounds(origin.Position,b)
    end)
    while #foreign>90 do table.remove(foreign)end
    local wanted={}
    local count=0
    for _,part0 in ipairs(own) do
        for _,part1 in ipairs(foreign) do
            if distanceToBounds(part0.Position,part1)<=12 and count<420 then
                local links=wanted[part0]
                if not links then links={};wanted[part0]=links end
                links[part1]=true
                count=count+1
            end
        end
    end
    for part0,links in pairs(ghostLinks) do
        for part1,link in pairs(links) do
            if not wanted[part0] or not wanted[part0][part1] or not link.Parent then
                pcall(function()link:Destroy()end)
                links[part1]=nil
            end
        end
        if not next(links) then ghostLinks[part0]=nil end
    end
    for part0,parts in pairs(wanted) do
        ghostLinks[part0]=ghostLinks[part0] or {}
        for part1 in pairs(parts) do
            if ghostLinks[part0][part1]==nil then
                local ok,link=pcall(function()
                    local nc=Instance.new('NoCollisionConstraint')
                    nc.Name='PVH_GrauSP_Ghost'
                    nc.Part0=part0
                    nc.Part1=part1
                    nc.Parent=part0
                    return nc
                end)
                if ok then ghostLinks[part0][part1]=link end
            end
        end
    end
    local actual,actualDynamic,actualStatic=0,0,0
    for _,links in pairs(ghostLinks) do
        for part,link in pairs(links) do
            if link and link.Parent then
                actual=actual+1
                if types[part]=='static' then actualStatic=actualStatic+1
                else actualDynamic=actualDynamic+1 end
            end
        end
    end
    state.ghostLinks=actual
    state.ghostParts=actual
    state.ghostDynamicCount=actualDynamic
    state.ghostStaticCount=actualStatic
end

local function attemptGhostReseat()
    if not state.antiFall or not lastGhostSeat or not lastGhostHum then return end
    if not ghostSeatLostAt then ghostSeatLostAt=os.clock() end
    local now=os.clock()
    local char=player.Character
    local hum=lastGhostHum
    local seat=lastGhostSeat
    if now<manualDismountUntil or now-ghostSeatLostAt>1.5
        or not seat.Parent or not hum.Parent or hum.Health<=0
        or not char or hum.Parent~=char then
        if reseatAttempts>0 then
            log('GHOST_RESEAT_STOP','Rider could not be restored; server ownership/seat may prevent reseating')
        end
        restoreGhost()
        return
    end
    local root=char:FindFirstChild('HumanoidRootPart')
    if root and seat.Occupant==nil and (root.Position-seat.Position).Magnitude<=12
        and now-lastReseatTry>=0.45 and reseatAttempts<2 then
        lastReseatTry=now
        reseatAttempts=reseatAttempts+1
        state.ejectionAttempts=state.ejectionAttempts+1
        local ok,err=pcall(function()seat:Sit(hum)end)
        log('GHOST_RESEAT',string.format('attempt=%d/%d ok=%s %s',reseatAttempts,2,tostring(ok),tostring(err or '')))
    end
end
local function clearRam()
    for _,c in ipairs(ramConnections) do pcall(function()c:Disconnect()end)end
    table.clear(ramConnections)
    ramVehicle=nil
end
-- PM expanded bumper: experimental CLIENT-SIDE contact area, not a server
-- hitbox bypass. Attached to the locally occupied vehicle ONLY when enabled.
-- It can interact locally with physics, but other clients/the server may ignore it.
local function clearPMBumper()
    if bumperContactConnection then pcall(function()bumperContactConnection:Disconnect()end)end
    bumperContactConnection=nil
    for _,link in ipairs(bumperCollisionLinks) do
        pcall(function()link:Destroy()end)
    end
    table.clear(bumperCollisionLinks)
    if bumperPart then pcall(function()bumperPart:Destroy()end)end
    bumperPart=nil
    bumperWeld=nil
    bumperModel=nil
    state.bumperModel=nil
end
local function updatePMBumper(model,seat)
    if not state.pmBumper or not model or not seat then
        if bumperPart then clearPMBumper()end
        return
    end
    if bumperModel==model and bumperPart and bumperPart.Parent then return end
    clearPMBumper()
    local root=seat.AssemblyRootPart or seat
    local ok,err=pcall(function()
        local bumper=Instance.new('Part')
        bumper.Name='PVH_GrauSP_PM_BumperLocal'
        bumper.Size=Vector3.new(5.8,1.5,3)
        bumper.Transparency=1
        bumper.CanCollide=true
        bumper.CanTouch=true
        bumper.CanQuery=false
        bumper.Massless=true
        bumper.CastShadow=false
        bumper.Anchored=false
        bumper.CFrame=root.CFrame*CFrame.new(0,0,-4.8)
        bumper.Parent=model
        local weld=Instance.new('WeldConstraint')
        weld.Part0=root
        weld.Part1=bumper
        weld.Parent=bumper
        bumperWeld=weld
        bumperPart=bumper
        for _,own in ipairs(model:GetDescendants()) do
            if own:IsA('BasePart') and own~=bumper and own.CanCollide then
                local nc=Instance.new('NoCollisionConstraint')
                nc.Part0=bumper
                nc.Part1=own
                nc.Parent=bumper
                bumperCollisionLinks[#bumperCollisionLinks+1]=nc
                if #bumperCollisionLinks>=60 then break end
            end
        end
        bumperContactConnection=bumper.Touched:Connect(function(other)
            if not alive or not state.pmBumper or not other or other:IsDescendantOf(model) then return end
            if os.clock()-lastBumperContact<0.8 then return end
            local candidate=other:FindFirstAncestorWhichIsA('Model')
            if not candidate or not candidate:FindFirstChild('Wheels',true) then return end
            lastBumperContact=os.clock()
            state.bumperContacts=state.bumperContacts+1
            log('PM_BUMPER_CONTACT',candidate.Name..' | local contact only; remote knockdown UNVERIFIED')
        end)
    end)
    if ok and bumperPart then
        bumperModel=model
        state.bumperModel=model.Name
        log('PM_BUMPER','local bumper attached to '..model.Name..' | server effects unverified')
    else
        clearPMBumper()
        log('PM_BUMPER_ERROR',err)
    end
end
local function setRamVehicle(model,seat)
    if ramVehicle==model then return end
    clearRam()
    if not state.pmRam or not model or state.ghost then return end
    -- Detect contacts made by the player's occupied vehicle. Never claim
    -- another player's assembly is controllable without ownership.
    ramVehicle=model
    local parts=0
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA('BasePart') and part.CanCollide and parts<20 then
            parts=parts+1
            ramConnections[#ramConnections+1]=part.Touched:Connect(function(hit)
                if not alive or not state.pmRam or state.ghost then return end
                if not hit or hit:IsDescendantOf(model) then return end
                if os.clock()-lastRamContact<0.5 then return end
                local other=hit:FindFirstAncestorWhichIsA('Model')
                if not other or not other:FindFirstChild('Wheels',true) then return end
                local own=seat.AssemblyRootPart or seat
                local otherRoot=hit.AssemblyRootPart or hit
                if own.AssemblyLinearVelocity.Magnitude<18 then return end
                lastRamContact=os.clock()
                state.ramTouches=state.ramTouches+1
                local owner,reason=ownsPhysics(otherRoot)
                if owner~=true then
                    log('PM_RAM_DENIED','contact='..other.Name..' | '..reason)
                    return
                end
                local dir=(otherRoot.Position-own.Position)
                if dir.Magnitude<0.05 then return end
                local ok,err=pcall(function()
                    otherRoot:ApplyImpulse(dir.Unit*otherRoot.AssemblyMass*35)
                end)
                if ok then state.ramSuccess=state.ramSuccess+1
                    log('PM_RAM_APPLIED',other.Name..' | local physics authority confirmed')
                else log('PM_RAM_ERROR',err)end
            end)
        end
    end
    log('PM_RAM_WATCH','vehicle='..model.Name..' parts='..parts)
end
-- Use the game's own T wheelie input instead of an artificial AlignOrientation.
-- Input methods are executor-dependent; never claim an actual wheelie if unavailable.
local nativeWheelieHeld=false
local function nativeWheelieKey(press)
    local fn=press and (env.keypress or keypress) or (env.keyrelease or keyrelease)
    if type(fn)=='function' then
        local ok,err=pcall(fn,0x54)
        if ok then return true end
        log('NATIVE_WHEELIE_INPUT',tostring(err))
    end
    local ok,err=pcall(function()
        local vim=game:GetService('VirtualInputManager')
        vim:SendKeyEvent(press,Enum.KeyCode.T,false,game)
    end)
    if not ok then log('NATIVE_WHEELIE_INPUT',tostring(err))end
    return ok
end
local function stopWheelie()
    if nativeWheelieHeld then
        nativeWheelieKey(false)
        nativeWheelieHeld=false
        log('NATIVE_WHEELIE','released T')
    end
end
local function wheelieTick(model,seat,owner)
    if not state.autoWheelie or not model or not seat then
        if nativeWheelieHeld then stopWheelie()end
        return
    end
    if nativeWheelieHeld then return end
    if nativeWheelieKey(true) then
        nativeWheelieHeld=true
        log('NATIVE_WHEELIE','holding T while seated in '..model.Name)
    else
        state.autoWheelie=false
        reportStatus('Auto Grau indisponível: executor não envia tecla T ao Roblox')
        local toggle=Library and Library.Toggles and Library.Toggles.PVG_AutoWheelie
        if toggle and toggle.Value then task.defer(function()toggle:SetValue(false)end)end
    end
end
local function raceTick(dt)
    local model,seat=getVehicle()
    if not model then
        if next(fallScriptOriginal) then restoreFallScripts() end
        if wheelVehicle then restoreWheels()end
        if nativeWheelieHeld then stopWheelie()end
        if state.antiFall then
            attemptGhostReseat()
        elseif ghostVehicle then
            restoreGhost()
        elseif ghostGuardHum then
            restoreFallGuard()
        end
        if ramVehicle then clearRam()end
        if bumperPart then clearPMBumper()end
        liveSpeed=0;racePhysicsPossible=false;state.physicsReason='no_driving_vehicle'
        if lastVehicleReason~=state.vehicleReason then
            lastVehicleReason=state.vehicleReason
            log('VEHICLE_STATUS',state.vehicleReason)
        end
        return
    end
    local assembly=seat.AssemblyRootPart or seat
    liveSpeed=assembly.AssemblyLinearVelocity.Magnitude
    local owner,reason=ownsPhysics(assembly)
    racePhysicsPossible=owner==true
    state.physicsReason=reason
    if lastVehicleReason~=model.Name..':'..reason then
        lastVehicleReason=model.Name..':'..reason
        lastSeatName=seat.Name
        log('VEHICLE_STATUS',model.Name..' seat='..seat.Name..' physics='..reason)
    end
    if state.antiFall then refreshFallScripts(model) else refreshFallScripts(nil) end
    if state.ghost or state.ghostWalls then
        updateGhost(model,seat)
    elseif ghostVehicle then
        restoreGhost()
    elseif state.antiFall then
        local hum=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
        guardRider(hum,seat)
    elseif ghostGuardHum then
        restoreFallGuard()
    end
    -- The obsolete PM impulse mode could not control other player's vehicle assemblies.
    -- Keep the old feature disabled rather than misreporting knockdowns.
    if ramVehicle then clearRam()end
    if state.pmBumper then updatePMBumper(model,seat)
    elseif bumperPart then clearPMBumper()end
    wheelieTick(model,seat,owner)
    if not state.raceMode then
        if wheelVehicle then restoreWheels()end
        return
    end
    state.raceTicks=state.raceTicks+1
    -- Do not alter another assembly's wheels if physics ownership is absent.
    if owner~=true then
        if wheelVehicle then restoreWheels()end
        state.raceDenied=state.raceDenied+1
        if os.clock()-lastRaceProbe>5 then
            lastRaceProbe=os.clock()
            log('RACE_BLOCKED','Assembly physics not owner-confirmed: '..reason)
        end
        return
    end
    local style=(state.drift and 'drift') or (state.grip and 'grip') or 'normal'
    if style=='normal' then
        if wheelVehicle then restoreWheels()end
    elseif model~=wheelVehicle or style~=lastWheelStyle then
        setWheelMode(model)
    end
    lastWheelStyle=style
    -- Do not modify AssemblyLinearVelocity or AssemblyAngularVelocity.
    -- Boost / Super Brake / corner braking previously ejected the rider.
    -- Drift and grip remain opt-in wheel-property experiments (reversible).
    -- Wheelie stability is a fall-state guard, not a velocity impulse.
    -- The guard is applied by guardRider before this race-mode section.
end
track(RunService.Heartbeat,function(dt)
    if alive then
        local ok,err=pcall(raceTick,math.clamp(dt,0,0.1))
        if not ok and os.clock()-lastPhysicsStats>5 then
            lastPhysicsStats=os.clock();log('RACE_ERROR',err)
        end
    end
end)
track(UserInputService.InputBegan,function(input,processed)
    if processed then return end
    if input.KeyCode==Enum.KeyCode.Space
        and state.antiFall then
        manualDismountUntil=os.clock()+2
    end
end)

-- Spatial ESP: never outline every static vehicle in the map.
-- Draw labels/boxes for loaded characters, and dynamically occupied vehicles
-- inside an adjustable distance; ignore the game's decorative bike models.
local function clearESP()
    for model,hi in pairs(espHighlights) do
        if typeof(hi)=='Instance' then pcall(function()hi:Destroy()end) end
        espHighlights[model]=nil
    end
    for model,gui in pairs(espTags) do
        if typeof(gui)=='Instance' then pcall(function()gui:Destroy()end) end
        espTags[model]=nil
    end
    state.espPlayerCount=0
    state.espVehicleCount=0
end
local function removeESP(model)
    local hi=espHighlights[model]
    if hi then pcall(function()hi:Destroy()end)end
    espHighlights[model]=nil
    local tag=espTags[model]
    if tag then pcall(function()tag:Destroy()end)end
    espTags[model]=nil
end
local function tagESP(model,anchor,title,color,kind,distance)
    if not model or not model.Parent or not anchor then return end
    if not espHighlights[model] then
        local ok,created=pcall(function()
            local hi=Instance.new('Highlight')
            hi.Name='PVH_GrauSP_ESP'
            hi.Adornee=model
            hi.FillColor=color
            hi.OutlineColor=color
            hi.FillTransparency=0.95
            hi.OutlineTransparency=0.12
            hi.DepthMode=Enum.HighlightDepthMode.Occluded
            hi.Parent=model
            return hi
        end)
        if ok then espHighlights[model]=created end
    end
    local labelGui=espTags[model]
    if not labelGui or not labelGui.Parent then
        local pg=player:FindFirstChildOfClass('PlayerGui')
        if not pg then return end
        labelGui=Instance.new('BillboardGui')
        labelGui.Name='PVH_GrauSP_'..kind..'_Tag'
        labelGui.Adornee=anchor
        labelGui.AlwaysOnTop=false
        labelGui.LightInfluence=0
        labelGui.MaxDistance=650
        labelGui.Size=UDim2.fromOffset(215,44)
        labelGui.StudsOffsetWorldSpace=Vector3.new(0,kind=='player' and 3 or 3.8,0)
        labelGui.Parent=pg
        local name=Instance.new('TextLabel')
        name.Name='NameTag'
        name.Size=UDim2.new(1,0,0,22)
        name.BackgroundTransparency=1
        name.TextColor3=color
        name.TextScaled=false
        name.TextSize=14
        name.TextWrapped=false
        name.TextStrokeColor3=Color3.fromRGB(0,0,0)
        name.TextStrokeTransparency=0.22
        name.Font=Enum.Font.GothamSemibold
        name.Parent=labelGui
        local distanceLabel=Instance.new('TextLabel')
        distanceLabel.Name='DistanceTag'
        distanceLabel.Position=UDim2.fromOffset(0,22)
        distanceLabel.Size=UDim2.new(1,0,0,17)
        distanceLabel.BackgroundTransparency=1
        distanceLabel.TextColor3=Color3.fromRGB(240,240,250)
        distanceLabel.TextSize=11
        distanceLabel.TextStrokeTransparency=0.32
        distanceLabel.Font=Enum.Font.Gotham
        distanceLabel.Parent=labelGui
        espTags[model]=labelGui
    end
    labelGui.Adornee=anchor
    local label=labelGui:FindFirstChild('NameTag')
    if label then label.Text=tostring(title):sub(1,31)end
    local distanceLabel=labelGui:FindFirstChild('DistanceTag')
    if distanceLabel then distanceLabel.Text=math.floor(distance)..' studs' end
end
local function vehicleRoot(model)
    local seat=model:FindFirstChild('DriveSeat',true)
        or model:FindFirstChildWhichIsA('VehicleSeat',true)
    if not seat then return nil end
    if seat:IsA('BasePart') then return seat end
    return nil
end
local function refreshESP()
    local myChar=player.Character
    local ownRoot=myChar and myChar:FindFirstChild('HumanoidRootPart')
    local origin=ownRoot and ownRoot.Position or (workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position)
    if not origin then return end
    local playerRange=state.espRange
    local vehicleRange=state.espVehicleRange
    local wanted={}
    local livePlayers,liveVehicles=0,0
    if state.espPlayers or state.pmTrack then
        for _,other in ipairs(Players:GetPlayers()) do
            if other~=player and other.Character and other.Character.Parent then
                local char=other.Character
                local head=char:FindFirstChild('Head')
                local root=char:FindFirstChild('HumanoidRootPart')
                local hum=char:FindFirstChildOfClass('Humanoid')
                if root and hum and hum.Health>0 then
                    local dist=(root.Position-origin).Magnitude
                    if (state.espPlayers and dist<=playerRange)
                        or (state.pmTrack and hum.SeatPart~=nil and dist<=state.pmRange) then
                        local policeMarked=state.pmTrack and hum.SeatPart~=nil
                            and dist<=state.pmRange
                        local color=policeMarked and Color3.fromRGB(255,90,90)
                            or Color3.fromRGB(255,183,73)
                        wanted[char]=true
                        tagESP(char,head or root,other.DisplayName..' (@'..other.Name..')',color,'player',dist)
                        livePlayers=livePlayers+1
                    end
                end
            end
        end
    end
    if state.espVehicles then
        local ownModel=select(1,getVehicle())
        local processed=0
        for _,candidate in ipairs(workspace:GetChildren()) do
            if candidate:IsA('Model') and candidate~=ownModel then
                local seat=vehicleRoot(candidate)
                if seat and candidate:FindFirstChild('Tuner') and candidate:FindFirstChild('Wheels')
                    and not seat.Anchored and (not state.espOccupiedOnly or seat.Occupant~=nil) then
                    local dist=(seat.Position-origin).Magnitude
                    if dist<=vehicleRange then
                        processed=processed+1
                        wanted[candidate]=true
                        tagESP(candidate,seat,candidate.Name,Color3.fromRGB(105,185,255),'vehicle',dist)
                        liveVehicles=liveVehicles+1
                    end
                end
                if processed>=60 then break end
            end
        end
    end
    for model in pairs(espHighlights) do
        if not wanted[model] or not model.Parent then removeESP(model)end
    end
    for model in pairs(espTags) do
        if not wanted[model] or not model.Parent then removeESP(model)end
    end
    state.espPlayerCount=livePlayers
    state.espVehicleCount=liveVehicles
end

-- Genuine iFood/Ifuud mission state; no order-completion spoofing.
local ifuudModule
local function getIfuudCoordinates()
    if ifuudModule then return ifuudModule end
    local mods=ReplicatedStorage:FindFirstChild('Modules')
    local module=mods and mods:FindFirstChild('IfuudCoordinates')
    if module and module:IsA('ModuleScript') then
        local ok,data=pcall(require,module)
        if ok and type(data)=='table' then ifuudModule=data end
    end
    return ifuudModule
end
local function vector3Of(p)
    if typeof(p)=='Vector3' then return p end
    if (type(p)=='table' or typeof(p)=='vector')
        and type(p.x)=='number' and type(p.y)=='number' and type(p.z)=='number' then
        return Vector3.new(p.x,p.y,p.z)
    end
    return nil
end
local function clearGps()
    state.gpsTarget=nil
    state.gpsName=''
    if gpsBillboard then pcall(function()gpsBillboard:Destroy()end);gpsBillboard=nil end
    if gpsAttachment then pcall(function()gpsAttachment:Destroy()end);gpsAttachment=nil end
end
local function setGps(target,name)
    local point=vector3Of(target)
    if not point then return false end
    clearGps()
    state.gpsTarget=point
    state.gpsName=tostring(name or '')
    local ok,err=pcall(function()
        local attach=Instance.new('Attachment')
        attach.Name='PVH_GrauSP_iFoodGPS'
        attach.WorldPosition=point
        attach.Parent=workspace.Terrain
        gpsAttachment=attach
        local bil=Instance.new('BillboardGui')
        bil.Name='PVH_GrauSP_DeliveryWaypoint'
        bil.Adornee=attach
        bil.AlwaysOnTop=true
        bil.MaxDistance=20000
        bil.Size=UDim2.fromOffset(240,44)
        bil.StudsOffsetWorldSpace=Vector3.new(0,7,0)
        bil.Parent=(player:FindFirstChildOfClass('PlayerGui') or StarterGui)
        local text=Instance.new('TextLabel')
        text.BackgroundColor3=Color3.fromRGB(24,24,30)
        text.BackgroundTransparency=0.18
        text.TextColor3=Color3.fromRGB(215,185,255)
        text.TextScaled=true
        text.Font=Enum.Font.GothamBold
        text.Size=UDim2.fromScale(1,1)
        text.Text='iFood • '..tostring(name)
        text.Parent=bil
        local corner=Instance.new('UICorner')
        corner.CornerRadius=UDim.new(0,7)
        corner.Parent=text
        gpsBillboard=bil
    end)
    if not ok then log('GPS_ERROR',err) end
    return true
end
local function equipPhone()
    local char=player.Character
    local backpack=player:FindFirstChildOfClass('Backpack')
    local hum=char and char:FindFirstChildOfClass('Humanoid')
    local tool=(char and char:FindFirstChild('Phone')) or (backpack and backpack:FindFirstChild('Phone'))
    if tool and tool:IsA('Tool') and hum then
        pcall(function()hum:EquipTool(tool)end)
        reportStatus(tr('equipPhone'))
        return tool
    end
    reportStatus(tr('notReady')..': Phone')
end
local function locatePhoneApps(tool)
    if not tool then return nil end
    -- Native hierarchy (source: StarterPack.Phone.Phone.Holder.Phone.Apps.Settings).
    local candidates={tool}
    local char=player.Character
    local pg=player:FindFirstChildOfClass('PlayerGui')
    if char then candidates[#candidates+1]=char end
    if pg then candidates[#candidates+1]=pg end
    for _,root in ipairs(candidates) do
        for _,v in ipairs(root:GetDescendants()) do
            if v.Name=='Apps' and v:FindFirstChild('Ifood') and v:FindFirstChild('AbaPrincipal') then
                return v
            end
        end
    end
    return nil
end
local function openIfuud()
    local tool=equipPhone()
    if not tool then
        state.ifoodOpen='phone_not_equipped'
        log('IFOOD_OPEN','FAIL phone not equipped')
        return false
    end
    local apps=locatePhoneApps(tool)
    if not apps then
        state.ifoodOpen='apps_not_found'
        reportStatus(tr('notReady')..': Phone.Apps.Ifood')
        log('IFOOD_OPEN','FAIL Apps container missing (check game version)')
        return false
    end
    local app=apps:FindFirstChild('Ifood')
    local home=apps:FindFirstChild('AbaPrincipal')
    local button=home and home:FindFirstChild('AppsButton')
    button=button and button:FindFirstChild('Ifuud')
    local fired=false
    local fireSignal=env.firesignal or firesignal
    if button and type(fireSignal)=='function' then
        fired=pcall(fireSignal,button.MouseButton1Click)
    end
    if not fired then
        -- Fallback reproduces the actual native OpenAppsAnimation, including
        -- app size, Opened attribute and wallpaper state, not just Visible.
        local ok,err=pcall(function()
            local lock=apps:FindFirstChild('TelaDeBloqueio') or apps:FindFirstChild('Teladebloqueio')
            if lock and lock:IsA('GuiObject') then lock.Visible=false end
            if home and home:IsA('GuiObject') then home.Visible=false end
            if app and app:IsA('GuiObject') then
                app.AnchorPoint=Vector2.new(0.5,0.5)
                app.Position=UDim2.fromScale(0.5,0.5)
                app.Size=UDim2.new(0.916,0,0.967,0)
                app.Visible=true
                app:SetAttribute('Opened',true)
                if app:IsA('CanvasGroup') then app.GroupTransparency=0 end
                local wallpaper=apps.Parent and apps.Parent:FindFirstChild('Wallpaper')
                if wallpaper and wallpaper:IsA('GuiObject') then wallpaper.Visible=false end
            end
        end)
        if not ok then
            state.ifoodOpen='native_open_error'
            log('IFOOD_OPEN','FAIL fallback '..tostring(err));return false
        end
    end
    local visible=app and app:IsA('GuiObject') and app.Visible
    state.ifoodOpen=visible and (fired and 'native_button' or 'native_layout') or 'not_visible'
    log('IFOOD_OPEN',state.ifoodOpen..' | path='..apps:GetFullName())
    reportStatus('iFood • '..(visible and 'aberto' or tr('notReady')))
    return visible==true
end
local function requestIfuudOrder()
    if not limitCall('order',1.5) then return end
    if fire('IfuudEvent','LocalizarPedido') then
        state.orders=state.orders+1
        state.ifoodStage='searching'
        reportStatus('iFood: '..tr('requested')..' • LocalizarPedido')
    end
end
local function requestIfuudPreference(on)
    state.ifoodLongDistance=on==true
    if fire('IfuudEvent','AtualizarPreferenca',{PrefLonge=state.ifoodLongDistance}) then
        log('IFOOD_PREF',state.ifoodLongDistance and 'distant' or 'nearby')
    end
    changed()
end
local function cancelIfuudOrder()
    -- One native request per click; no synthetic second-click confirmation.
    if fire('IfuudEvent','ResetarMissao') then
        clearGps()
        state.ifoodStage='idle'
        reportStatus('iFood: '..tr('requested')..' • ResetarMissao')
    end
end
local autoIfuudToken=0
local autoIfuudLastEvent=os.clock()
local function stopAutoIfuud(reason)
    state.autoIFood=false
    autoIfuudToken=autoIfuudToken+1
    state.ifoodAutoStatus=tostring(reason or 'off')
    local t=Library and Library.Toggles and Library.Toggles.PVG_AutoIFood
    if t and t.Value then pcall(function()t:SetValue(false)end)end
    log('IFOOD_AUTO_STOP',state.ifoodAutoStatus)
end
local function autoIfuudDispatch(action,stage,argument)
    if not state.autoIFood then return false end
    if not limitCall('auto_ifood_'..action,0.8) then return false end
    local args=argument~=nil and {action,argument} or {action}
    if fire('IfuudEvent',table.unpack(args)) then
        state.ifoodAutoStatus=stage
        return true
    end
    stopAutoIfuud('Remotes.IfuudEvent indisponível')
    return false
end
local function performPrompt(parentPath,promptName,targetName)
    local root=workspace:FindFirstChild('Ifuud')
    if not root then return false end
    for _,name in ipairs(parentPath) do
        root=root:FindFirstChild(name)
        if not root then return false end
    end
    root=root:FindFirstChild(targetName)
    local prompt=root and root:FindFirstChild(promptName)
    if not prompt or not prompt:IsA('ProximityPrompt') or not prompt.Enabled then return false end
    local char=player.Character
    local hrp=char and char:FindFirstChild('HumanoidRootPart')
    local targetPart=prompt.Parent
    if targetPart and targetPart:IsA('Attachment') then targetPart=targetPart.Parent end
    if not hrp or not targetPart or not targetPart:IsA('BasePart')
        or (hrp.Position-targetPart.Position).Magnitude>math.max(14,prompt.MaxActivationDistance+5) then return false end
    local f=env.fireproximityprompt or fireproximityprompt
    if type(f)=='function' and pcall(f,prompt) then return true end
    return pcall(function()
        prompt:InputHoldBegin()
        task.wait(math.max(0.1,tonumber(prompt.HoldDuration) or 0)+0.08)
        prompt:InputHoldEnd()
    end)
end
local function dispatchAutoIfuudTarget(stage,targetName)
    if not state.autoIFood then return end
    local token=autoIfuudToken
    task.spawn(function()
        local coords=getIfuudCoordinates()
        local data=coords and (stage=='pickup' and coords.Locais or coords.Entrega)
        local destination=data and vector3Of(data[targetName])
        if not destination then stopAutoIfuud('Coordenada nativa ausente');return end
        local moved,why=travelNow(destination,targetName)
        if not moved then stopAutoIfuud('Falha de teleporte: '..tostring(why));return end
        task.wait(1.3)
        if not alive or not state.autoIFood or token~=autoIfuudToken then return end
        local hrp=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
        if not hrp or (hrp.Position-destination).Magnitude>70 then
            stopAutoIfuud('Movimentação revertida pelo servidor');return
        end
        if stage=='delivery' then
            autoIfuudDispatch('AguardandoEntregaMundo','aguardando_prompt',targetName)
        end
        local path=stage=='pickup' and {'GetOrders','Pedidos'} or {'DeliverOrder','LocalDeEntrega'}
        local promptName=stage=='pickup' and 'PegarPedido' or 'Entregar'
        local deadline=os.clock()+9
        while state.autoIFood and token==autoIfuudToken and alive and os.clock()<deadline do
            if performPrompt(path,promptName,targetName) then
                state.ifoodAutoStatus='aguardando confirmação: '..stage
                log('IFOOD_AUTO_PROMPT',stage..'/'..targetName)
                return
            end
            task.wait(0.35)
        end
        if state.autoIFood and token==autoIfuudToken then stopAutoIfuud('Prompt indisponível ou distante')end
    end)
end
local function startAutoIfuud()
    if state.autoIFood then return true end
    if not remote('IfuudEvent') then
        reportStatus('Auto iFood: evento IfuudEvent não encontrado')
        log('IFOOD_AUTO_ERROR','remote missing')
        return false
    end
    state.autoIFood=true
    autoIfuudToken=autoIfuudToken+1
    autoIfuudLastEvent=os.clock()
    local token=autoIfuudToken
    requestIfuudPreference(state.ifoodLongDistance)
    if not autoIfuudDispatch('LocalizarPedido','procurando_pedido') then
        stopAutoIfuud('LocalizarPedido não enviado')
        reportStatus('Auto iFood: não foi possível solicitar o pedido')
        return false
    end
    reportStatus('Auto iFood ligado: aguardando pedido do servidor')
    task.spawn(function()
        while alive and state.autoIFood and autoIfuudToken==token do
            if os.clock()-autoIfuudLastEvent>28 then
                stopAutoIfuud('Nenhum pedido confirmado em 28s')
                reportStatus('Auto iFood: servidor não confirmou um pedido')
                return
            end
            task.wait(0.8)
        end
    end)
    log('IFOOD_AUTO_START',state.ifoodLongDistance and 'priority=far' or 'priority=near')
    return true
end
local ifuudRemote=remote('IfuudEvent')
if ifuudRemote then
    track(ifuudRemote.OnClientEvent,function(event,argument)
        if not alive then return end
        if event=='AtivarGPS' then
            autoIfuudLastEvent=os.clock()
            if state.autoIFood then dispatchAutoIfuudTarget('pickup',tostring(argument))end
            local conf=getIfuudCoordinates()
            local data=conf and conf.Locais and conf.Locais[argument]
            if data then setGps(data,argument);state.ifoodStage='pickup' end
        elseif event=='PedidoColetado' then
            autoIfuudLastEvent=os.clock()
            if state.autoIFood then dispatchAutoIfuudTarget('delivery',tostring(argument))end
            local conf=getIfuudCoordinates()
            local data=conf and conf.Entrega and conf.Entrega[argument]
            if data then setGps(data,argument);state.ifoodStage='delivery' end
        elseif event=='EntregaConcluida' then
            clearGps();state.ifoodStage='done'
            autoIfuudLastEvent=os.clock()
            if state.autoIFood then
                state.ifoodCompleted=state.ifoodCompleted+1
                local token=autoIfuudToken
                task.delay(2,function()
                    if alive and state.autoIFood and autoIfuudToken==token then
                        autoIfuudDispatch('LocalizarPedido','procurando_pedido')
                    end
                end)
            end
        elseif event=='AtivarPromptEntrega' then
            state.ifoodStage='arrival'
            autoIfuudLastEvent=os.clock()
        elseif event=='AbrirPainelCodigo' then
            autoIfuudLastEvent=os.clock()
            if state.autoIFood and argument~=nil and tostring(argument):match('^%d%d%d%d$') then
                autoIfuudDispatch('VerificarCodigoFinal','validando_codigo',tostring(argument))
            end
        elseif event=='CodigoErrado' then
            if state.autoIFood then stopAutoIfuud('Código rejeitado pelo servidor')end
        end
        if event=='AtivarGPS' or event=='PedidoColetado' or event=='EntregaConcluida' then
            log('IFOOD_EVENT',tostring(event)..' / '..tostring(argument))
        end
    end)
end

local function listNearby()
    local char=player.Character
    local root=char and char:FindFirstChild('HumanoidRootPart')
    if not root then reportStatus(tr('notReady')..': HumanoidRootPart');return end
    local nearby={}
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=player and p.Character then
            local other=p.Character:FindFirstChild('HumanoidRootPart')
            if other then
                local distance=(root.Position-other.Position).Magnitude
                if distance<=state.pmRange then
                    nearby[#nearby+1]={p=p.Name,d=distance}
                end
            end
        end
    end
    table.sort(nearby,function(a,b)return a.d<b.d end)
    local entries={}
    for i=1,math.min(#nearby,6) do
        local e=nearby[i]
        entries[#entries+1]=e.p..' ('..math.floor(e.d)..' studs)'
    end
    reportStatus(#entries>0 and table.concat(entries,' | ')
        or ('No players within '..state.pmRange..' studs'))
end
local function updatePMRadar()
    if not state.pmTrack then
        state.pmNearest='Radar OFF'
        return
    end
    local char=player.Character
    local root=char and char:FindFirstChild('HumanoidRootPart')
    if not root then state.pmNearest='Sem personagem';return end
    local nearest,shortest=nil,math.huge
    for _,other in ipairs(Players:GetPlayers()) do
        if other~=player and other.Character then
            local hum=other.Character:FindFirstChildOfClass('Humanoid')
            local riderRoot=other.Character:FindFirstChild('HumanoidRootPart')
            local seat=hum and hum.SeatPart
            if seat and riderRoot then
                local dist=(riderRoot.Position-root.Position).Magnitude
                if dist<=state.pmRange and dist<shortest then
                    nearest,shortest={name=other.Name,seat=seat,part=riderRoot},dist
                end
            end
        end
    end
    if nearest then
        local speed=math.floor(nearest.part.AssemblyLinearVelocity.Magnitude*1.008+0.5)
        state.pmNearest=string.format('%s | %d studs | %d km/h',nearest.name,math.floor(shortest),speed)
        if nearest.name~=pmNearestPlayer then
            pmNearestPlayer=nearest.name
            log('PM_TARGET',state.pmNearest)
        end
    else
        state.pmNearest='Sem motociclistas próximos'
        pmNearestPlayer=nil
    end
end

task.spawn(function()
    while alive do
        local ok,err=pcall(refreshESP)
        if not ok then log('ESP_ERROR',err) end
        local okPM,pmErr=pcall(updatePMRadar)
        if not okPM and os.clock()-lastPMLog>10 then lastPMLog=os.clock();log('PM_ERROR',pmErr) end
        task.wait(0.6)
    end
end)

-- UI creation is delayed until the native catalog is available; no invented entries.
log('UI_BOOT','Loading pinned Obsidian UI; verifying source type before compile')
local okLibrary,resLibrary=pcall(loadObsidianLibrary)
if not okLibrary then
    log('UI_FATAL',resLibrary)
    warn('[PVH Grau SP] Obsidian could not load: '..tostring(resLibrary))
    -- The old version exited here while leaving background loops running.
    -- v0.3.1 fails cleanly and preserves an actionable startup report.
    if type(writefile)=='function' then
        pcall(writefile,REPORT_PATH,'PVH GRAU SP '..VERSION..' | BOOT FAILURE\n'
            ..'CHECK [FAIL] Obsidian library source download or load\n'
            ..tostring(resLibrary)..'\n'
            ..'The vehicle spawner and other features were not started.\n')
    end
    alive=false
    pcall(restoreWheels);pcall(restoreGhost);pcall(restoreFallScripts);pcall(clearRam);pcall(clearPMBumper);pcall(clearESP);pcall(clearGps)
    for _,c in ipairs(connections) do pcall(function()c:Disconnect()end) end
    pcall(function()clickSound:Destroy()end)
    writeSession(true)
    return
end
Library=resLibrary
env.Library=Library
Library.ShowCustomCursor=false

local function unload()
    if rebuilding or not alive then return end
    log('UNLOAD','cleanup requested')
    if state.autoIFood then stopAutoIfuud('Unload')end
    alive=false
    restoreWheels()
    stopWheelie()
    restoreGhost()
    restoreFallScripts()
    clearRam()
    clearPMBumper()
    clearESP()
    writeSession(true)
    clearGps()
    for _,c in ipairs(connections) do pcall(function()c:Disconnect()end) end
    connections={}
    if Window and Library and not Library.Unloaded then pcall(function()Library:Unload()end) end
    pcall(function()clickSound:Destroy()end)
    if env.PVH_GrauSP_Unload==unload then env.PVH_GrauSP_Unload=nil end
    if env.PVH_GrauSP_Check then env.PVH_GrauSP_Check=nil end
    if env.Library==Library then env.Library=nil end
    warn('[PVH Grau SP] unloaded')
end
env.PVH_GrauSP_Unload=unload
track(UserInputService.InputBegan,function(input,processed)
    if not processed and input.KeyCode==Enum.KeyCode.Delete then unload()end
end)

local getPoliceOptions
local function runChecker()
    local catalog=getMenu()
    local mdl,seat=getVehicle()
    local backpack=player:FindFirstChildOfClass('Backpack')
    local app=(player.Character and player.Character:FindFirstChild('Phone'))
        or (backpack and backpack:FindFirstChild('Phone'))
    local apps=locatePhoneApps(app)
    local function value(ok,group,label,detail)
        return {ok and 'PASS' or 'FAIL',group,label,detail or ''}
    end
    local function skip(group,label,detail)
        return {'SKIP',group,label,detail or 'not enabled / not in context'}
    end
    local function unknown(group,label,detail)
        return {'UNVERIFIED',group,label,detail or 'needs live game test'}
    end
    local checks={
        value(game.PlaceId==PLACE_ID,'CORE','Supported PlaceId'),
        value(type(Library)=='table' and not Library.Unloaded,'CORE','Obsidian UI loaded'),
        value(catalog~=nil,'SPAWNER','Native vehicle catalog exists'),
        value(#state.vehicles>0,'SPAWNER','Vehicle catalog not empty',tostring(#state.vehicles)),
        value(remote('SpawnCar')~=nil,'SPAWNER','SpawnCar remote exists'),
        value(remote('DeleteCar')~=nil,'SPAWNER','DeleteCar remote exists'),
        value(remote('FavoritesCar')~=nil,'SPAWNER','FavoritesCar remote exists'),
        value(remote('SpawnSelect')~=nil,'TELEPORT','SpawnSelect remote exists'),
        value(remote('IfuudEvent')~=nil,'IFOOD','IfuudEvent remote exists'),
        value(getIfuudCoordinates()~=nil,'IFOOD','Delivery coordinates module exists'),
        value(type(writefile)=='function' and writeSession(true),'LOGGING','Session log is writable',SESSION_PATH),
    }
    checks[#checks+1]=app and value(apps~=nil,'IFOOD','Phone Apps hierarchy found')
        or skip('IFOOD','Native phone GUI','equip Phone first')
    checks[#checks+1]=state.ifoodOpen=='not_attempted'
        and skip('IFOOD','Open iFood app','not attempted yet')
        or value(state.ifoodOpen=='native_button' or state.ifoodOpen=='native_layout',
            'IFOOD','Open iFood app state',state.ifoodOpen)
    checks[#checks+1]=seat and value(true,'RACE','Driver seat detected',seat.Name)
        or skip('RACE','Driver seat detected',state.vehicleReason)
    checks[#checks+1]=seat and (racePhysicsPossible
        and value(true,'RACE','Network physics ownership',state.physicsReason)
        or unknown('RACE','Network physics ownership',state.physicsReason))
        or skip('RACE','Physics ownership','not driving')
    checks[#checks+1]=value(true,'SAFETY',
        'Unsafe boost/brake paths removed','Race Mode no longer writes assembly velocities')
    checks[#checks+1]=not state.raceMode
        and skip('RACE','Drift/grip test','race mode OFF')
        or unknown('RACE','Drift/grip test','physical wheel configuration; test in-game')
    checks[#checks+1]=not (state.ghost or state.ghostWalls)
        and skip('GHOST','Dynamic no-collision constraints','Ghost OFF')
        or unknown('GHOST','Dynamic no-collision constraints',
            'dynamic='..state.ghostDynamicCount..' wall='..state.ghostStaticCount..'; ground preserved')
    checks[#checks+1]=not state.antiFall
        and skip('GHOST','Rider fall guard','both Ghost and wheelie stability OFF')
        or unknown('GHOST','Rider anti-fall guard',
            'native Falling scripts disabled='..state.fallScriptsDisabled..' found='..state.fallScriptsFound..
            ' humanoid protected='..tostring(ghostGuardHum~=nil)..
            ' reseat attempts='..tostring(state.ejectionAttempts)..'; server rejection possible')
    local playerCount=0
    for _,p in ipairs(Players:GetPlayers())do if p~=player then playerCount=playerCount+1 end end
    checks[#checks+1]=not state.espPlayers
        and skip('ESP','Player highlights','player ESP OFF')
        or (playerCount==0 and skip('ESP','Player highlights','no other players')
        or unknown('ESP','Player ESP visibility','visually confirm client highlights'))
    checks[#checks+1]=not state.espVehicles
        and skip('ESP','Vehicle highlights','vehicle ESP OFF')
        or unknown('ESP','Nearby occupied vehicle ESP',
            'nearby='..state.espVehicleCount..' radius='..state.espVehicleRange..
            ' only occupied='..tostring(state.espOccupiedOnly))
    checks[#checks+1]=value(#getPoliceOptions()>0,'SPAWNER','Police vehicle catalog available',
        tostring(#getPoliceOptions()))
    local premiumHidden=not state.showGamepasses
    if premiumHidden then
        for _,category in ipairs(state.categories) do
            if not freeCategory(category) then premiumHidden=false;break end
        end
    end
    checks[#checks+1]=value(state.showGamepasses or premiumHidden,'SPAWNER',
        'Gamepass visibility filter',
        state.showGamepasses and 'premium categories shown; entitlement still server-checked'
            or 'premium categories hidden by default')
    local toggles=type(Library)=='table' and Library.Toggles or nil
    local options=type(Library)=='table' and Library.Options or nil
    checks[#checks+1]=value(type(toggles)=='table' and toggles.PVG_ShowGamepasses~=nil,
        'SPAWNER','Gamepass filter control registered')
    checks[#checks+1]=value(type(options)=='table' and options.PVG_PMSelect~=nil,
        'SPAWNER','PM selection available inside the Vehicles tab')
    checks[#checks+1]=state.pmTrack
        and unknown('PM','Pursuit radar',state.pmNearest)
        or skip('PM','Pursuit radar','radar OFF')
    checks[#checks+1]=state.pmBumper
        and unknown('PM','Local bumper contact proxy',
            'part='..tostring(bumperPart and bumperPart.Parent~=nil)..
            ' contacts='..state.bumperContacts..' server knockdown UNVERIFIED')
        or skip('PM','Local bumper contact proxy','experimental OFF')
    checks[#checks+1]=state.antiFall
        and unknown('GHOST','Native Falling script suppression',
            'active local scripts='..state.fallScriptsDisabled..' / found='..state.fallScriptsFound)
        or skip('GHOST','Native Falling suppression','anti-fall OFF')
    local counts={PASS=0,FAIL=0,SKIP=0,UNVERIFIED=0}
    local lines={
        'PRIME VOID HUB | GRAU SP | DIAGNOSTICO | '..VERSION,
        'PlaceId='..tostring(game.PlaceId)..' JobId='..tostring(game.JobId),
        'Captured='..os.date('!%Y-%m-%d %H:%M:%S UTC'),
        'Catalog='..tostring(state.catalogSource)..' Vehicles='..#state.vehicles..
            ' VisibleCategories='..#state.categories..' ShowGamepasses='..tostring(state.showGamepasses),
        'Requests: spawn='..state.spawns..' delete='..state.deletes..' regions='..state.regions..' orders='..state.orders,
        'Physics: '..diagnosticSnapshot(),
        'ESP: players='..state.espPlayerCount..' vehicles='..state.espVehicleCount..
          ' playerRange='..state.espRange..' vehicleRange='..state.espVehicleRange..
          ' occupiedOnly='..tostring(state.espOccupiedOnly),
        'PM bumper: contacts='..state.bumperContacts..' enabled='..tostring(state.pmBumper)..
          ' localPart='..tostring(bumperPart~=nil),
        'Ghost: dynamicPairs='..state.ghostDynamicCount..' wallsPairs='..state.ghostStaticCount..
          ' fallingScriptsDisabled='..state.fallScriptsDisabled..' found='..state.fallScriptsFound,
        'Session workspace log: '..SESSION_PATH,
        'NOTE: PASS confirms only an actual local condition; server approval NOT guaranteed.',
        ''
    }
    for _,it in ipairs(checks)do
        counts[it[1]]=counts[it[1]]+1
        lines[#lines+1]='['..it[1]..']['..it[2]..'] '..it[3]..' | '..it[4]
    end
    lines[#lines+1]=string.format('SUMMARY: PASS=%d FAIL=%d SKIP=%d UNVERIFIED=%d TOTAL=%d',
        counts.PASS,counts.FAIL,counts.SKIP,counts.UNVERIFIED,#checks)
    state.lastReport=table.concat(lines,'\n')..'\n'
    log('CHECKER',lines[#lines])
    if type(writefile)=='function' then
        local ok,err=pcall(function()writefile(REPORT_PATH,state.lastReport)end)
        if not ok then log('CHECKER_WRITE_ERROR',err)end
    end
    return counts.PASS,#checks
end
env.PVH_GrauSP_Check=runChecker
local function exportChecker()
    if state.lastReport=='' then runChecker() end
    if type(writefile)~='function' then reportStatus(tr('noStorage'));return end
    local ok,err=pcall(function()writefile(REPORT_PATH,state.lastReport)end)
    reportStatus(ok and ('workspace/'..REPORT_PATH) or tostring(err))
end

local function addTab(name,icon)
    return Window:AddTab(name,icon)
end
local function group(tab,name,side,icon)
    return tab:AddGroupbox({Name=name,Side=side,IconName=icon})
end
local function safeGroup(label,action)
    local ok,err=pcall(action)
    if not ok then
        state.errors=state.errors+1
        log('UI_'..tostring(label),err)
    end
end
local function makeButton(g,text,func)
    return g:AddButton({Text=text,Func=function()
        if not alive then return end
        if state.sounds and clickSound then pcall(function()clickSound:Play()end)end
        local ok,err=pcall(func)
        if not ok then log('BUTTON',err);state.errors=state.errors+1 end
    end})
end
local function catalogOptions()
    local values=filteredVehicles()
    return values
end
local pmSelection=nil
local categoryControl,vehicleControl,previewControl,vehicleCountLabel,pmVehicleControl
local categoryLabel,vehicleButtons,vehiclePageLabel,vehiclePage=nil,{},nil,1
local vehicleNamesShown={}
local function updatePreview()
    local car=chosenVehicle()
    if previewControl and type(previewControl.SetImage)=='function'
        and car and type(car.image)=='string' and car.image~='' then
        pcall(function()previewControl:SetImage(car.image)end)
    end
    if vehicleCountLabel then
        pcall(function()vehicleCountLabel:SetText(
            tostring(#catalogOptions())..' / '..tostring(#(state.byCategory[state.selectedCategory] or {}))
            ..' • '..tostring(state.selectedCategory or '-'))end)
    end
end
local function updateVehicleGallery()
    local options=catalogOptions()
    local pageCount=math.max(1,math.ceil(#options/8))
    vehiclePage=math.clamp(vehiclePage,1,pageCount)
    vehicleNamesShown={}
    for index,control in ipairs(vehicleButtons) do
        local name=options[(vehiclePage-1)*8+index]
        vehicleNamesShown[index]=name
        control:SetVisible(name~=nil)
        if name then
            local selected=state.selectedVehicle==name
            control:SetText((selected and '[*] ' or '     ')..name)
        end
    end
    if categoryLabel then
        categoryLabel:SetText('  <  '..tostring(state.selectedCategory or '-')..'  >')
    end
    if vehiclePageLabel then
        vehiclePageLabel:SetText(tostring(#options)..' veículos • página '..vehiclePage..'/'..pageCount)
    end
end
updateCarOptions=function()
    local available=catalogOptions()
    if not table.find(available,state.selectedVehicle) then state.selectedVehicle=available[1] end
    updatePreview()
    updateVehicleGallery()
end
local function updateCategoryOptions()
    state.categories=visibleCategories()
    if not table.find(state.categories,state.selectedCategory) then
        state.selectedCategory=state.categories[1]
        state.selectedVehicle=nil
    end
    vehiclePage=1
    updateCarOptions()
    if pmVehicleControl and type(pmVehicleControl.SetValues)=='function' then
        local options=getPoliceOptions()
        if not table.find(options,pmSelection) then pmSelection=options[1] end
        pcall(function()pmVehicleControl:SetValues(options)end)
        if pmSelection then pcall(function()pmVehicleControl:SetValue(pmSelection)end)end
    end
end
local function switchCategory(step)
    local cats=state.categories
    if #cats<1 then return end
    local index=table.find(cats,state.selectedCategory) or 1
    state.selectedCategory=cats[((index-1+step)%#cats)+1]
    state.selectedVehicle=nil
    vehiclePage=1
    updateCarOptions()
    changed()
end
local function createVehicleNavigation(parent)
    -- Only public Obsidian controls. No custom Frames, cards or unsupported
    -- Unicode arrow glyphs: those rendered as squares on the user's device.
    categoryLabel=parent:AddLabel('  <  '..tostring(state.selectedCategory or '-')..'  >',true)
    local previous=parent:AddButton({Text='<  '..(state.language=='pt-BR' and 'Anterior' or 'Previous'),
        Func=function()switchCategory(-1)end})
    previous:AddButton({Text=(state.language=='pt-BR' and 'Próxima' or 'Next')..'  >',
        Func=function()switchCategory(1)end})
    vehiclePageLabel=parent:AddLabel('0 veículos',true)
    for index=1,8 do
        local button=parent:AddButton({
            Text='-',Visible=false,
            Func=function()
                local name=vehicleNamesShown[index]
                if not name then return end
                state.selectedVehicle=name
                updatePreview()
                updateVehicleGallery()
            end,
        })
        vehicleButtons[index]=button
    end
    local pageNav=parent:AddButton({Text='< Página',Func=function()
        vehiclePage=math.max(1,vehiclePage-1)
        updateVehicleGallery()
    end})
    pageNav:AddButton({Text='Página >',Func=function()
        vehiclePage=vehiclePage+1
        updateVehicleGallery()
    end})
end
local function policeCategory()
    local choice=nil
    for _,cat in ipairs(state.categories) do
        local low=cat:lower()
        if low:find('policia',1,true) or low:find('viatura',1,true) then
            choice=cat;break
        end
    end
    if choice then
        state.selectedCategory=choice
        state.search=''
        updateCategoryOptions()
        reportStatus(tr('policeCars')..': '..choice)
    else
        reportStatus(tr('notReady')..': Pack policia')
    end
end

getPoliceOptions=function()
    local items={}
    for _,cat in ipairs(state.categories) do
        local low=cat:lower()
        if low:find('policia',1,true) or low:find('viatura',1,true) then
            for _,entry in ipairs(state.byCategory[cat] or {}) do
                items[#items+1]=cat..' / '..entry.name
            end
        end
    end
    table.sort(items)
    return items
end
local function spawnPM()
    if type(pmSelection)~='string' then reportStatus(tr('noCar'));return end
    local cat,name=pmSelection:match('^(.-) / (.*)$')
    if not cat or not name then return end
    if not state.showGamepasses and not freeCategory(cat) then
        log('PM_SPAWN_BLOCKED','gamepass vehicles are hidden')
        return
    end
    if not limitCall('pm_spawn',1.0) then return end
    if fire('SpawnCar',cat,name) then
        state.spawns=state.spawns+1
        log('PM_SPAWN','request '..cat..'/'..name)
        reportStatus(tr('requested')..' • '..name)
    end
end
local rebuildUI
local function buildUI()
    Window=Library:CreateWindow({
        Title='Prime Void Hub',Footer='Grau SP • TEST '..VERSION,
        Center=true,AutoShow=true,Resizable=true,
        Size=UDim2.fromOffset(770,560),
        ToggleKeybind=Enum.KeyCode.RightControl,
        ShowCustomCursor=false,NotifySide='Right',
        MinSidebarWidth=135,EnableCompacting=true,SidebarCompactWidth=48,
        Animations={ToggleWindow=state.animations,TabSwitch=state.animations,
            Groupbox=state.animations,Dropdown=state.animations,KeyPicker=state.animations}
    })
    local home=addTab(tr('home'),'house')
    local vehicles=addTab(tr('vehicles'),'bike')
    local race=addTab(state.language=='pt-BR' and 'Moto' or 'Motorcycle','bike')
    local ifood=addTab(tr('delivery'),'map-pin')
    local police=addTab(tr('police'),'shield')
    local visuals=addTab(tr('visuals'),'eye')
    local tp=addTab(tr('travel'),'map')
    local settings=addTab(tr('settings'),'settings')
    local about=addTab(tr('about'),'info')

    local homeLeft=group(home,tr('welcome'),'Left','house')
    homeLeft:AddLabel(tr('hint'),true)
    ui.homeCount=homeLeft:AddLabel('...')
    ui.homeVehicle=homeLeft:AddLabel('...')
    makeButton(homeLeft,tr('refresh'),function()
        refreshCatalog();updateCategoryOptions()
    end)
    local homeRight=group(home,tr('stats'),'Right','activity')
    ui.homeStatus=homeRight:AddLabel('...')
    ui.homeSpeed=homeRight:AddLabel('...')
    ui.lastStatus=homeRight:AddLabel(state.status,true)
    makeButton(homeRight,tr('runChecker'),function()
        local p,n=runChecker()
        reportStatus(string.format('Checker: %d/%d',p,n))
    end)

    local vLeft=group(vehicles,tr('catalog'),'Left','list')
    vLeft:AddToggle('PVG_ShowGamepasses',{
        Text=tr('showGamepasses'),Default=state.showGamepasses,
        Callback=function(on)
            state.showGamepasses=on==true
            state.selectedVehicle=nil
            updateCategoryOptions()
            log('GAMEPASS_FILTER','visible='..tostring(state.showGamepasses))
            changed()
        end,
    })
    vLeft:AddLabel(tr('gamepassHelp'),true)
    searchBox=vLeft:AddInput('PVG_VehicleSearch',{
        Text=tr('search'),Default=state.search,Placeholder=tr('searchPH'),
        Finished=false,ClearTextOnFocus=false,
        Callback=function(value)
            if not alive then return end
            state.search=tostring(value or '')
            vehiclePage=1
            updateCarOptions()
        end,
    })
    createVehicleNavigation(vLeft)
    updateCarOptions()
    vehicleCountLabel=vLeft:AddLabel('...')
    makeButton(vLeft,tr('spawn'),requestSpawn)
    makeButton(vLeft,tr('favorite'),function()setFavorite(true)end)
    makeButton(vLeft,tr('unfavorite'),function()setFavorite(false)end)
    makeButton(vLeft,tr('refresh'),function()
        if refreshCatalog() then updateCategoryOptions()end
    end)
    local vRight=group(vehicles,tr('preview'),'Right','image')
    local first=chosenVehicle()
    local image=first and first.image
    if type(image)~='string' or image=='' then image='rbxasset://textures/ui/GuiImagePlaceholder.png' end
    local okImg,preview=pcall(function()
        return vRight:AddImage('PVG_CarPreview',{Image=image,Height=165})
    end)
    if okImg then previewControl=preview else
        vRight:AddLabel(tr('preview')..' (thumbnail unavailable)')
    end
    vRight:AddLabel(tr('native'),true)
    local vCleanup=group(vehicles,'Garagem / Garage','Right','trash-2')
    makeButton(vCleanup,tr('delete'),deleteAll)
    makeButton(vCleanup,tr('deleteSlot1'),function()deleteSpecific('livre',1)end)
    makeButton(vCleanup,tr('deleteSlot2'),function()deleteSpecific('livre',2)end)
    makeButton(vCleanup,tr('deleteTrailer'),function()deleteSpecific('carretinha')end)
    vCleanup:AddLabel(tr('unknown'),true)
    -- Both general and PM vehicle spawners live exclusively under Vehicles.
    local pmGarage=group(vehicles,tr('policeVehiclesGroup'),'Right','shield-check')
    local pmOpts=getPoliceOptions()
    pmSelection=pmSelection or pmOpts[1]
    if #pmOpts>0 then
        pmVehicleControl=pmGarage:AddDropdown('PVG_PMSelect',{
            Text=tr('pmVehicles'),Values=pmOpts,Default=pmSelection,AllowNull=true,
            Callback=function(v)pmSelection=v end,
        })
        makeButton(pmGarage,tr('pmSpawn'),spawnPM)
        makeButton(pmGarage,tr('policeCars'),policeCategory)
    else
        pmGarage:AddLabel(tr('notReady')..': Viaturas',true)
    end

    local rLeft=group(race,state.language=='pt-BR' and 'Pilotagem' or 'Riding','Left','shield')
    rLeft:AddToggle('PVG_AntiFall',{
        Text=state.language=='pt-BR' and 'Anti Queda de Moto' or 'Motorcycle Anti-Fall',
        Default=state.antiFall,
        Callback=function(v)
            state.antiFall=v==true
            if not state.antiFall then restoreFallScripts();restoreFallGuard()end
            log('ANTI_FALL',tostring(v)..' | local Falling script guard')
            changed()
        end,
    })
    rLeft:AddToggle('PVG_AutoWheelie',{
        Text=state.language=='pt-BR' and 'Manter grau (tecla T)' or 'Hold wheelie (T key)',
        Default=false,
        Callback=function(v)
            state.autoWheelie=v==true
            if not state.autoWheelie then stopWheelie() end
            if state.autoWheelie then reportStatus('Grau nativo: manter T quando estiver sentado na moto')end
        end,
    })
    local rRight=group(race,state.language=='pt-BR' and 'Estado da moto' or 'Bike status','Right','activity')
    ui.raceDiagnostics=rRight:AddLabel(tr('raceDebug')..': --',true)
    rRight:AddLabel('Anti Queda protege o personagem do script local Falling. O servidor pode ainda desmontar a moto.',true)
    rRight:AddLabel('Auto Grau mantém a entrada T nativa; requer um executor que aceite enviar tecla.',true)

    local iLeft=group(ifood,tr('delivery'),'Left','package-check')
    iLeft:AddToggle('PVG_IFoodLong',{
        Text=state.language=='pt-BR' and 'Priorizar entregas distantes' or 'Prioritize distant deliveries',
        Default=state.ifoodLongDistance,
        Callback=function(v)
            requestIfuudPreference(v==true)
        end,
    })
    makeButton(iLeft,tr('findOrder'),requestIfuudOrder)
    makeButton(iLeft,tr('cancelOrder'),function()
        if state.autoIFood then stopAutoIfuud('Cancelado pelo usuário')end
        cancelIfuudOrder()
    end)
    iLeft:AddToggle('PVG_AutoIFood',{
        Text=tr('autoIfuud'),Default=false,
        Callback=function(v)
            if v then
                if not startAutoIfuud() then
                    task.defer(function()
                        if Library and Library.Toggles and Library.Toggles.PVG_AutoIFood then
                            Library.Toggles.PVG_AutoIFood:SetValue(false)
                        end
                    end)
                end
            elseif state.autoIFood then stopAutoIfuud('desativado pelo usuário')end
        end,
    })
    local iRight=group(ifood,tr('gps'),'Right','navigation')
    ui.ifoodStage=iRight:AddLabel(tr('ifoodStatus'),true)
    ui.ifoodDistance=iRight:AddLabel(tr('gpsNone'),true)
    ui.ifoodAuto=iRight:AddLabel('Auto iFood: OFF',true)

    local pLeft=group(police,tr('police'),'Left','shield-check')
    pLeft:AddLabel(tr('policeHelp'),true)
    pLeft:AddLabel(tr('policeVehiclesGroup')..': '..tr('vehicles'),true)
    makeButton(pLeft,state.language=='pt-BR' and 'Ir ao uniforme PM' or 'Go to police uniform',function()
        changeRegion('PM_Uniforme')
        reportStatus('PM: aproxime-se e vista o uniforme da delegacia. Sem cargo remoto fictício.')
    end)
    pLeft:AddLabel('A roupa de PM fica no batalhão de Avenida Paulista. O servidor aplica o uniforme no local.',true)
    local pRight=group(police,state.language=='pt-BR' and 'Locais da PM' or 'Police locations','Right','map-pin')
    makeButton(pRight,state.language=='pt-BR' and 'Batalhão da PM' or 'Police Station',function()
        changeRegion('PM_Batalhao')
    end)
    pRight:AddLabel('A roupa é aplicada pela interação original do jogo no local, não por um comando remoto.',true)

    local espLeft=group(visuals,tr('visuals'),'Left','scan-eye')
    espLeft:AddToggle('PVG_ESPPlayers',{Text=tr('espPlayers'),Default=state.espPlayers,
        Callback=function(v)state.espPlayers=v==true;refreshESP();log('ESP_PLAYERS',tostring(v));changed()end})
    espLeft:AddToggle('PVG_ESPVehicles',{Text=tr('espVehicles'),Default=state.espVehicles,
        Callback=function(v)state.espVehicles=v==true;refreshESP();log('ESP_VEHICLES',tostring(v));changed()end})
    espLeft:AddSlider('PVG_ESPRange',{
        Text=tr('espRange'),Min=100,Max=2500,Rounding=0,Default=state.espRange,
        Callback=function(v)
            state.espRange=math.clamp(math.floor(tonumber(v) or 1200),100,2500)
            refreshESP();changed()
        end})
    espLeft:AddSlider('PVG_ESPVehRange',{
        Text=tr('espVehicleRange'),Min=50,Max=800,Rounding=0,Default=state.espVehicleRange,
        Callback=function(v)
            state.espVehicleRange=math.clamp(math.floor(tonumber(v) or 250),50,800)
            refreshESP();changed()
        end})
    espLeft:AddToggle('PVG_ESPActiveOnly',{Text=tr('espOccupiedOnly'),Default=state.espOccupiedOnly,
        Callback=function(v)
            state.espOccupiedOnly=v==true;refreshESP();changed()
        end})
    espLeft:AddLabel('ESP mostra nomes e distância dos alvos carregados e próximos. Não revela objetos ainda não replicados.',true)
    local espRight=group(visuals,'Visual Status','Right','activity')
    ui.espState=espRight:AddLabel('ESP: off',true)

    local tLeft=group(tp,tr('spawnRegions'),'Left','map-pinned')
    makeButton(tLeft,tr('sao'),function()changeRegion('SaoLuis_Spawn')end)
    makeButton(tLeft,tr('guaruja'),function()changeRegion('Guaruja_Spawn')end)
    makeButton(tLeft,tr('vidigal'),function()changeRegion('Vidigal_Spawn')end)
    makeButton(tLeft,state.language=='pt-BR' and 'Batalhão da PM' or 'Police Station',function()
        changeRegion('PM_Batalhao')
    end)
    makeButton(tLeft,state.language=='pt-BR' and 'Loja de capacetes' or 'Helmet Shop',function()
        changeRegion('LojaCapacetes')
    end)
    local tRight=group(tp,tr('igarata'),'Right','triangle-alert')
    tRight:AddLabel(tr('regionWarn'),true)
    tRight:AddLabel(tr('unknown'),true)

    local sLeft=group(settings,tr('preferences'),'Left','sliders-horizontal')
    sLeft:AddDropdown('PVG_Language',{
        Text=tr('language'),Values={'Português','English'},
        Default=state.language=='pt-BR' and 'Português' or 'English',
        Callback=function(v)
            local nextLang=v=='English' and 'en-US' or 'pt-BR'
            if state.language~=nextLang then
                state.language=nextLang;changed()
                reportStatus('Language updated')
                task.defer(function()if alive and rebuildUI then rebuildUI()end end)
            end
        end,
    })
    sLeft:AddToggle('PVG_AutoSave',{Text=tr('autoSave'),Default=state.autoSave,
        Callback=function(v)state.autoSave=v==true;if state.autoSave then saveConfig()end end})
    sLeft:AddToggle('PVG_Animations',{Text=tr('animations'),Default=state.animations,
        Callback=function(v)
            local changedValue=state.animations~=(v==true)
            state.animations=v==true;changed()
            if changedValue then task.defer(function()if alive and rebuildUI then rebuildUI()end end)end
        end})
    sLeft:AddToggle('PVG_Sounds',{Text=tr('sounds'),Default=state.sounds,
        Callback=function(v)state.sounds=v==true;changed()end})
    makeButton(sLeft,tr('save'),function()
        reportStatus(saveConfig() and tr('saved') or tr('noStorage'))
    end)
    makeButton(sLeft,tr('reload'),function()
        if loadConfig() then reportStatus(tr('saved')..' • reload script to rebind controls')
        else reportStatus(tr('notReady'))end
    end)
    makeButton(sLeft,tr('reset'),function()
        local ok=type(isfile)=='function' and type(delfile)=='function'
        if ok then ok=pcall(function()if isfile(CONFIG_PATH)then delfile(CONFIG_PATH)end end)end
        reportStatus(ok and 'Config file deleted' or tr('noStorage'))
    end)
    local sSession=group(settings,tr('session'),'Right','history')
    makeButton(sSession,tr('rejoin'),function()
        if tostring(game.JobId)=='' then reportStatus('JobId unavailable');return end
        local ok,err=pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId,game.JobId,player)
        end)
        if not ok then reportStatus(tostring(err))end
    end)
    sSession:AddLabel('Autoexec: TEST via universal loader.',true)
    local sChecker=group(settings,tr('checker'),'Right','list-checks')
    makeButton(sChecker,tr('runChecker'),function()
        local passed,total=runChecker()
        reportStatus('Checker '..passed..'/'..total..' | '..tr('diagnostics'))
    end)
    makeButton(sChecker,tr('export'),exportChecker)
    makeButton(sChecker,tr('logExport'),function()
        local ok=writeSession(true)
        reportStatus(ok and ('workspace/'..SESSION_PATH) or tr('noStorage'))
    end)
    sChecker:AddLabel(tr('logInfo'),true)
    sChecker:AddLabel(tr('diagnostics'),true)

    local a=group(about,tr('about'),'Left','info')
    a:AddLabel(tr('aboutText'),true)
    a:AddLabel(tr('credits'),true)
    a:AddLabel('PlaceId '..tostring(PLACE_ID),true)
    a:AddLabel('Obsidian UI • native remotes • no server assumptions',true)
    makeButton(a,'Unload',unload)

    if type(Library.OnUnload)=='function' then pcall(function()Library:OnUnload(unload)end)end
    updateCategoryOptions()
end

-- Recreate the Obsidian window after a language change, preserving runtime state.
-- No extra loader, ScreenGui or duplicated physics listeners remain alive.
rebuildUI=function()
    if rebuilding or not alive then return end
    rebuilding=true
    if Library and not Library.Unloaded then
        pcall(function()Library:Unload()end)
    end
    local okNew,newLibrary=pcall(loadObsidianLibrary)
    if not okNew or type(newLibrary)~='table' or type(newLibrary.CreateWindow)~='function' then
        rebuilding=false
        log('LANGUAGE_ERROR',newLibrary)
        unload();return
    end
    Library=newLibrary
    Library.ShowCustomCursor=false
    env.Library=Library
    Window=nil
    ui={}
    categoryControl=nil;vehicleControl=nil;previewControl=nil;vehicleCountLabel=nil;pmVehicleControl=nil
    categoryLabel=nil;vehicleButtons={};vehiclePageLabel=nil;vehiclePage=1
    rebuilding=false
    local ok,err=pcall(buildUI)
    if not ok then log('LANGUAGE_ERROR',err);unload()end
end

-- The native catalog can load asynchronously as the game joins.
for attempt=1,18 do
    if refreshCatalog() then break end
    task.wait(0.4)
end
state.selectedVehicle=filteredVehicles()[1]
local okUI,errUI=pcall(buildUI)
if not okUI then
    log('UI_FATAL',errUI)
    warn('[PVH Grau SP] Failed to initialize native Obsidian UI: '..tostring(errUI))
    unload()
    return
end

-- Lightweight session and GPS HUD updates; no infinite GUI duplication.
task.spawn(function()
    while alive do
        local mdl,seat=getVehicle()
        local pos=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
        local dist=state.gpsTarget and pos and (state.gpsTarget-pos.Position).Magnitude
        local stage=state.ifoodStage
        if ui.ifoodAuto then
            pcall(function()ui.ifoodAuto:SetText('Auto: '..tostring(state.ifoodAutoStatus)..' | Entregas confirmadas: '..tostring(state.ifoodCompleted))end)
        end
        if ui.homeCount then
            pcall(function()ui.homeCount:SetText(tr('vehicle')..': '..#state.vehicles..' | '..tr('filter')..': '..#state.categories..
                ' | Gamepass='..tostring(state.showGamepasses))end)
        end
        if ui.homeVehicle then
            pcall(function()ui.homeVehicle:SetText('Spawn: '..state.spawns..' | Delete: '..state.deletes)end)
        end
        if ui.homeStatus then
            pcall(function()ui.homeStatus:SetText('iFood: '..tostring(stage)..' | Region requests: '..state.regions)end)
        end
        if ui.homeSpeed then
            pcall(function()ui.homeSpeed:SetText('Vehicle: '..(mdl and mdl.Name or '-')..' | '..math.floor(liveSpeed*1.008+0.5)..' km/h')end)
        end
        if ui.policeSpeed then
            pcall(function()ui.policeSpeed:SetText('Velocidade: '..math.floor(liveSpeed*1.008+0.5)..' km/h (local)')end)
        end
        if ui.policeTarget then
            pcall(function()ui.policeTarget:SetText('Alvo: '..tostring(state.pmNearest))end)
        end
        if ui.espState then
            pcall(function()ui.espState:SetText('ESP: '..state.espPlayerCount..' players, '..state.espVehicleCount..
                ' veiculos (jogadores '..state.espRange..' / veiculos '..state.espVehicleRange..' studs)')end)
        end
        if ui.raceDiagnostics then
            pcall(function()ui.raceDiagnostics:SetText('Seat: '..tostring(state.vehicleReason)..
                ' | Ghost veiculos: '..state.ghostDynamicCount..' paredes: '..state.ghostStaticCount..
                ' | Falling scripts: '..state.fallScriptsDisabled)
            end)
        end
        if ui.ifoodStage then
            pcall(function()ui.ifoodStage:SetText('iFood: '..stage)end)
        end
        if ui.ifoodDistance then
            local message=dist and (state.gpsName..' • '..math.floor(dist)..' studs') or tr('gpsNone')
            pcall(function()ui.ifoodDistance:SetText(message)end)
        end
        task.wait(0.7)
    end
end)

-- Checker bootstrap is read-only. Does NOT fire remotes or modify world state.
local passed,total=runChecker()
log('BOOT',string.format('Grau SP TEST %s | Obsidian ready | checker=%d/%d | cars=%d',
    VERSION,passed,total,#state.vehicles))

-- Continuous bounded workspace logs; explicit flush on unload.
task.spawn(function()
    while alive do
        writeSession(true)
        task.wait(2)
    end
end)
