-- Prime Void Hub | GRAU SP | v0.4.6
-- PlaceId: 101953291486308
-- Native Obsidian UI; recovered legacy Rustcc catalog preserved.
-- New features are based on documented client interfaces in the supplied .rbxl.
-- All game-server actions are REQUESTS; neither acceptance nor entitlement is forged.
-- Published through Prime Void Hub universal loader.

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
local ContextActionService=game:GetService('ContextActionService')
local player=Players.LocalPlayer
if not player then return end
local env=type(getgenv)=='function' and getgenv() or _G
if type(env.PVH_GrauSP_Unload)=='function' then pcall(env.PVH_GrauSP_Unload) end

local VERSION='0.4.6'
local LIBRARY_URL='https://raw.githubusercontent.com/deividcomsono/Obsidian/82d402b5de7d8903915f1afe99b5b7e340e7cd28/Library.lua'
local LIBRARY_CDN='https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@82d402b5de7d8903915f1afe99b5b7e340e7cd28/Library.lua'
local LIBRARY_CACHE='primevoid_hub/Grau_SP/Configs/obsidian_82d402b5.lua' 
local CONFIG_DIR='primevoid_hub/Grau_SP/Configs'
local CONFIG_PATH=CONFIG_DIR..'/settings.json'
local LOG_DIR='primevoid_hub/Grau_SP/Logs'
local REPORT_PATH=LOG_DIR..'/PVH_GrauSP_Checker.txt'
local SESSION_PATH=LOG_DIR..'/PVH_GrauSP_Session.txt'
local runtime={} -- Shared state to keep top-level Luau registers below 200
local alive=true
runtime.connections={}
runtime.wheelOriginal={}
runtime.wheelVehicle=nil
runtime.cooldowns={}
local state={
    language='pt-BR',autoSave=true,animations=true,sounds=false,showKeybinds=false,minimizeKey='RightShift',unloadKey='Delete',ifoodLongDistance=false,
    autoIFood=false,ifoodMode='Distante',ifoodCompleted=0,ifoodAutoStatus='off',
    autoAlarm=false,autoTracker=false,autoLock=false,hideRobberyPuzzles=false,
    showGamepasses=false,allCategories={},
    selectedCategory='Motos_Gratis',selectedVehicle=nil,search='',
    categories={},vehicles={},byCategory={},catalogSource='none',
    spawns=0,deletes=0,regions=0,orders=0,errors=0,
    raceMode=false,drift=false,grip=false,wheelieAssist=false,autoWheelie=false,wheelieAngle=27,
    ejectionAttempts=0,ghostLinks=0,ghostWalls=false,antiFall=true,
    fallScriptsDisabled=0,fallScriptsFound=0,ghostDynamicCount=0,ghostStaticCount=0,
    espRange=1200,espVehicleRange=250,pmTrack=false,pmRange=250,
    pmBumper=false,bumperContacts=0,bumperModel=nil,
    espVehicleCount=0,espPlayerCount=0,pmNearest='',
    ghost=false,espPlayers=false,espVehicles=false,pmRam=false,
    raceTicks=0,raceApplied=0,raceDenied=0,ramTouches=0,ramSuccess=0,ghostParts=0,
    vehicleReason='not_seated',physicsReason='unknown',ifoodOpen='not_attempted',
    lastVehicle=nil,ifoodStage='idle',gpsTarget=nil,gpsName='',
    lastReport='',status='Aguardando interface do jogo...',teleportPoints={},
}
local Library,Window,ui={},nil,{}
local gpsAttachment,gpsBillboard=nil,nil
runtime.rebuilding=false
runtime.lastServerNotice=0
runtime.liveSpeed=0
runtime.lastPhysicsStats=0
runtime.clickSound=Instance.new('Sound')
runtime.clickSound.Name='PVH_GrauSP_Click'
runtime.clickSound.SoundId='rbxassetid://10066942189'
runtime.clickSound.Volume=0.18
runtime.clickSound.Parent=SoundService
runtime.catalogRefreshSerial=0
runtime.racePhysicsPossible=false
runtime.releaseSuspension
runtime.sessionLog={}
runtime.sessionSeq=0
runtime.lastLogFlush=0
runtime.espHighlights={}
runtime.espTags={}
runtime.fallScriptOriginal={}
runtime.lastFallCheck=0
runtime.lastFallModel=nil
runtime.pmNearestPlayer=nil
runtime.bumperPart=nil
runtime.bumperWeld=nil
runtime.bumperCollisionLinks={}
runtime.bumperContactConnection=nil
runtime.bumperModel=nil
runtime.lastBumperContact=0
runtime.lastPMLog=0
runtime.ghostVehicle=nil
runtime.ghostLinks={}
runtime.ghostGuardHum=nil
runtime.ghostGuardStates={}
runtime.lastGhostSeat=nil
runtime.lastGhostHum=nil
runtime.ghostSeatLostAt=nil
runtime.lastReseatTry=0
runtime.reseatAttempts=0
runtime.manualDismountUntil=0
runtime.lastGhostLog=0
runtime.ramConnections={}
runtime.ramVehicle=nil
runtime.lastRamContact=0
runtime.lastVehicleReason=''
runtime.lastSeatName=''
runtime.lastRaceProbe=0
runtime.lastGhostRefresh=0
runtime.legacyLogsMoved=false
local function ensureLogFolder()
    if type(makefolder)~='function' then return false end
    local folder=''
    for segment in LOG_DIR:gmatch('[^/]+') do
        folder=folder=='' and segment or folder..'/'..segment
        local ok,exists=pcall(function()
            return type(isfolder)=='function' and isfolder(folder)
        end)
        if not (ok and exists) then
            local made=pcall(makefolder,folder)
            if not made and type(isfolder)=='function' then
                local verified,present=pcall(isfolder,folder)
                if not (verified and present) then return false end
            elseif not made then return false end
        end
    end
    if not runtime.legacyLogsMoved then
        runtime.legacyLogsMoved=true
        if type(isfile)=='function' and type(readfile)=='function'
            and type(writefile)=='function' and type(delfile)=='function' then
            for _,entry in ipairs({
                {'PVH_GrauSP_Checker.txt',LOG_DIR..'/PVH_GrauSP_Checker_legacy.txt'},
                {'PVH_GrauSP_Session.txt',LOG_DIR..'/PVH_GrauSP_Session_legacy.txt'},
            }) do
                local okOld,oldPresent=pcall(isfile,entry[1])
                local okNew,newPresent=pcall(isfile,entry[2])
                if okOld and oldPresent and okNew and not newPresent then
                    local got,body=pcall(readfile,entry[1])
                    if got and type(body)=='string' then
                        local copied=pcall(writefile,entry[2],body)
                        if copied then pcall(delfile,entry[1]) end
                    end
                end
            end
        end
    end
    return true
end
local function writeSession(force)
    if type(writefile)~='function' or not ensureLogFolder() then return false end
    if not force and os.clock()-runtime.lastLogFlush<1.0 then return true end
    runtime.lastLogFlush=os.clock()
    return pcall(function()
        writefile(SESSION_PATH,table.concat(runtime.sessionLog,'\n')..'\n')
    end)
end
local function diagnosticSnapshot()
    return string.format('vehicle=%s seat=%s physics=%s speed=%.1f race=%s ticks=%d applied=%d denied=%d ghost=%d ramTouches=%d ramSuccess=%d ifood=%s',
        tostring(state.vehicleReason),tostring(runtime.lastSeatName),tostring(state.physicsReason),runtime.liveSpeed,
        tostring(state.raceMode),state.raceTicks,state.raceApplied,state.raceDenied,
        state.ghostLinks,state.ramTouches,state.ramSuccess,tostring(state.ifoodOpen))
end

local STR={
 ['pt-BR']={
  home='Início',steal='Roubar',vehicles='Veículos',race='Modo Corrida',delivery='iFood',police='PM',visuals='Visuais',
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
  pmRam='Impacto PM (experimental: autoridade física)',pmVehicles='Viatura para spawn',
  pmSpawn='Spawnar viatura',raceDebug='Estado real da física',
  logExport='Salvar logs TXT',logInfo='Logs e Checker são salvos na pasta Logs deste jogo.',
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
  credits='Prime Void Hub • Grau SP  |  v0.4.3',
  notReady='Objeto ainda não carregado',noCar='Selecione um veículo válido',
  requested='Solicitação enviada (resultado no servidor não confirmado)',
  error='Falha local',saved='Configuração salva',noStorage='Executor sem escrita local',
  removeWarning='Clique novamente para remover TODOS os seus veículos.',
  noRole='A fonte não mostra mecanismo de alistamento ou seleção de PM.',
  gpsNone='Nenhuma rota de entrega recebida',
 },
 ['en-US']={
  home='Home',steal='Steal',vehicles='Vehicles',race='Race Mode',delivery='iFood',police='Police',visuals='Visuals',
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
  pmRam='Police impact (experimental: physics authority)',pmVehicles='Police car to spawn',
  pmSpawn='Spawn police vehicle',raceDebug='Actual physics status',
  logExport='Save log TXT',logInfo='Session logs and Checker are saved inside this port Logs folder.',
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
  credits='Prime Void Hub • Grau SP  |  v0.4.3',
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
    runtime.connections[#runtime.connections+1]=c
    return c
end
local function log(code,message)
    if not alive then return end
    local msg='[PVH Grau SP]['..tostring(code)..'] '..tostring(message or '')
    warn(msg)
    runtime.sessionSeq=runtime.sessionSeq+1
    runtime.sessionLog[#runtime.sessionLog+1]=string.format('%05d [%s][%s] %s',runtime.sessionSeq,
        os.date('!%H:%M:%S'),tostring(code),tostring(message or ''))
    if #runtime.sessionLog>2400 then table.remove(runtime.sessionLog,1) end
    writeSession(false)
end
-- Cache helpers must be lexically declared BEFORE requestObsidianSource.
local function ensureFolder()
    if type(makefolder)~='function' then return end
    for _,part in ipairs({'primevoid_hub','primevoid_hub/Grau_SP',CONFIG_DIR,LOG_DIR}) do
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
    local p=env.PVH_Persistence
    if type(p)=='table' and p.AutoSave==false then return false end
    if type(writefile)~='function' then return false end
    ensureFolder()
    return pcall(function()
        writefile(CONFIG_PATH,HttpService:JSONEncode({schema=2,
            language=state.language,autoSave=state.autoSave,showKeybinds=state.showKeybinds,
            minimizeKey=state.minimizeKey,unloadKey=state.unloadKey,ifoodLongDistance=state.ifoodLongDistance,
            ifoodMode=state.ifoodMode,autoWheelie=state.autoWheelie,wheelieAngle=state.wheelieAngle,
            showGamepasses=state.showGamepasses,
            autoAlarm=state.autoAlarm,autoTracker=state.autoTracker,
            autoLock=state.autoLock,
            ghostWalls=state.ghostWalls,antiFall=state.antiFall,
            espRange=state.espRange,espVehicleRange=state.espVehicleRange,
            pmTrack=state.pmTrack,pmRange=state.pmRange,pmBumper=state.pmBumper,
            animations=state.animations,sounds=state.sounds,
            raceMode=state.raceMode,
            ghost=state.ghost,espPlayers=state.espPlayers,espVehicles=state.espVehicles,pmRam=state.pmRam,
            drift=state.drift,grip=state.grip,wheelieAssist=state.wheelieAssist,
            selectedCategory=state.selectedCategory,teleportPoints=state.teleportPoints}))
    end)
end
local function loadConfig()
    if type(isfile)~='function' or type(readfile)~='function' then return false end
    local ok,data=pcall(function()
        if isfile(CONFIG_PATH) then return HttpService:JSONDecode(readfile(CONFIG_PATH)) end
    end)
    if not ok or type(data)~='table' then return false end
    for _,k in ipairs({'autoSave','animations','sounds','showKeybinds','raceMode','drift','grip','wheelieAssist','autoWheelie','ifoodLongDistance','showGamepasses','autoAlarm','autoTracker','autoLock','hideRobberyPuzzles','ghost','ghostWalls','antiFall','espPlayers','espVehicles','pmTrack','pmBumper','pmRam'}) do
        if type(data[k])=='boolean' then state[k]=data[k] end
    end
    if data.language=='pt-BR' or data.language=='en-US' then state.language=data.language end
    if type(data.teleportPoints)=='table' then
        for _,key in ipairs({'PM_Batalhao','LojaCapacetes'}) do
            local a=data.teleportPoints[key]
            if type(a)=='table' and #a==3 then
                local x,y,z=tonumber(a[1]),tonumber(a[2]),tonumber(a[3])
                if x and y and z and math.abs(x)<200000 and math.abs(y)<200000
                    and math.abs(z)<200000 and x==x and y==y and z==z then
                    state.teleportPoints[key]={x,y,z}
                end
            end
        end
    end
    for _,k in ipairs({'minimizeKey','unloadKey'}) do
        if type(data[k])=='string' and Enum.KeyCode[data[k]] then state[k]=data[k]end
    end
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
state.autoSave=true -- Universal persistence owns AutoSave, not this port.
state.hideRobberyPuzzles=false -- Native minigames must remain interactive.
-- Retire experimental racing, ghost collision and bumper modes from old saved profiles.
state.raceMode=false;state.drift=false;state.grip=false;state.ghost=false;state.ghostWalls=false;state.pmBumper=false
state.autoWheelie=false
state.antiFall=false -- no active UI while server-side ejection remains unverified
state.pmTrack=false
local function changed()
    local p=env.PVH_Persistence
    if type(p)=='table' and p.AutoSave==false then return end
    if state.autoSave then saveConfig()end
end
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
    if (os.clock()-(runtime.cooldowns[key] or -math.huge))<seconds then return false end
    runtime.cooldowns[key]=os.clock()
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
        if owner~=true then
            -- Teleport the avatar alone; never seize a vehicle we do not own.
            hum.Sit=false
            task.wait(0.15)
            local ok,err=pcall(function()
                char:PivotTo(CFrame.new(position+Vector3.new(0,4,0))*root.CFrame.Rotation)
            end)
            if not ok then return false,'character_fallback: '..tostring(err) end
            log('TELEPORT_DISMOUNT','vehicle ownership unavailable; moved avatar only')
        else
            local ok,err=pcall(function()
                model:PivotTo(CFrame.new(position+Vector3.new(0,5,0))*(model:GetPivot()-model:GetPivot().Position))
            end)
            if not ok then return false,tostring(err) end
        end
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
-- Resolve map locations from live replicated geography, not from GUI-only folders.
-- Never pretend that a named Folder has a CFrame when no map parts are streamed.
local function physicalPosition(node)
    if not node then return nil end
    if node:IsA('Attachment') then return node.WorldPosition end
    if node:IsA('BasePart') then return node.Position end
    if node:IsA('Model') then
        local part=node.PrimaryPart or node:FindFirstChildWhichIsA('BasePart',true)
        if part then
            local ok,pivot=pcall(function()return node:GetPivot()end)
            return ok and pivot.Position or part.Position
        end
    end
    local prompt=node:FindFirstChildWhichIsA('ProximityPrompt',true)
        or node:FindFirstChildWhichIsA('ClickDetector',true)
    if prompt then
        local p=prompt.Parent
        if p and p:IsA('Attachment') then return p.WorldPosition end
        if p and p:IsA('BasePart') then return p.Position end
    end
    local part=node:FindFirstChildWhichIsA('BasePart',true)
    return part and part.Position or nil
end
local function findLocationInMap(key)
    local avenue=workspace:FindFirstChild('Avenida Paulista')
        or workspace:FindFirstChild('Avenida Paulista',true)
    if not avenue then return nil,'Avenida Paulista não carregada' end
    local selections={
        PM_Batalhao={parent='Policia Militar',targets={'Patio','Pátio','Entrada','Batalhao','Batalhão','Portao','Portão'}},
        PM_Uniforme={parent='Policia Militar',targets={'Roupa','Uniform PM','Uniform ROCAM'}},
        LojaCapacetes={parent='Outlet Dichava',targets={'Capacetes','Capacete','Helmet','Entrada'}},
    }
    local spec=selections[key]
    if not spec then return nil,'Destino desconhecido: '..tostring(key) end
    local parent=avenue:FindFirstChild(spec.parent,true)
    if not parent then return nil,'Local não carregado: '..spec.parent end
    local physicalCandidates={}
    for _,name in ipairs(spec.targets) do
        local target=parent:FindFirstChild(name,true)
        if target then
            local pos=physicalPosition(target)
            if pos then physicalCandidates[#physicalCandidates+1]={pos=pos,name=name} end
        end
    end
    if #physicalCandidates>0 then
        local chosen=physicalCandidates[1]
        log('MAP_RESOLVED',key..' -> '..chosen.name)
        return chosen.pos,nil
    end
    -- Some versions use a Model for the complete establishment, without 'Patio'/'Capacetes'.
    -- Its actual physical bounds are a valid fallback; a bare Folder is NOT.
    if parent:IsA('Model') then
        local pos=physicalPosition(parent)
        if pos then
            log('MAP_RESOLVED',key..' -> '..parent.Name..' (model)')
            return pos,nil
        end
    end
    return nil,'Local encontrado, mas geometria física não carregada: '..spec.parent
end

local nativeSpawns={
    SaoLuis_Spawn='SaoLuis_Spawn',
    Guaruja_Spawn='Guaruja_Spawn',
    Vidigal_Spawn='Vidigal_Spawn',
}
local function groundedPoint(around,isWorldRegion)
    if typeof(around)~='Vector3' then return nil end
    local ray=RaycastParams.new()
    ray.FilterType=Enum.RaycastFilterType.Exclude
    ray.FilterDescendantsInstances={player.Character}
    ray.IgnoreWater=true
    local lift=isWorldRegion and 120 or 7
    local depth=isWorldRegion and 235 or 20
    local offsets={Vector3.zero,Vector3.new(3,0,0),Vector3.new(-3,0,0),
        Vector3.new(0,0,3),Vector3.new(0,0,-3)}
    local best=nil
    local score=math.huge
    for _,offset in ipairs(offsets) do
        local origin=around+offset+Vector3.new(0,lift,0)
        local hit=workspace:Raycast(origin,Vector3.new(0,-depth,0),ray)
        if hit and hit.Instance and hit.Normal.Y>0.65 and hit.Instance.CanCollide then
            local point=hit.Position+Vector3.new(0,3.3,0)
            local dist=(Vector3.new(point.X,0,point.Z)-Vector3.new(around.X,0,around.Z)).Magnitude
            if dist<score then best=point;score=dist end
        end
    end
    return best
end
local function changeRegion(destination)
    if not limitCall('region',1.0) then return false end
    state.regions+=1
    local native=nativeSpawns[destination]
    if native then
        local reference=zoneReferences[destination]
        if not reference then
            reportStatus('Região sem coordenadas no mapa nativo: '..destination)
            return false
        end
        local point=Vector3.new(reference[1],reference[2],reference[3])
        task.spawn(function()
            -- Request streaming before the local blink. Use only confirmed floor parts.
            for attempt=1,3 do
                if not alive then return end
                pcall(function()player:RequestStreamAroundAsync(point,3)end)
                local floor=groundedPoint(point,true)
                if floor then
                    local ok,reason=travelNow(floor-Vector3.new(0,4,0),native)
                    if ok then
                        log('REGION_LOCAL','blink '..native..' | attempt='..attempt)
                        reportStatus('Teleporte iniciado: '..native..' (verificando posição)')
                        return
                    end
                    log('REGION_LOCAL_FAILED',native..' | '..tostring(reason))
                    if reason~='vehicle_network_ownership_unavailable' then break end
                end
                task.wait(0.55)
            end
            -- This is an explicit native SPAWN request, not a claim of a successful teleport.
            if fire('SpawnSelect',native) then
                log('REGION_NATIVE','SpawnSelect '..native..' | local floor unavailable')
                reportStatus('Piso não carregado; solicitação de spawn enviada: '..native)
            else
                reportStatus('Destino não carregado e SpawnSelect indisponível: '..native)
            end
        end)
        return true
    end
    -- For point-of-interest destinations the source contains no trustworthy coordinates.
    -- Resolve a real BasePart/Model in the streamed map and do not invent XYZ.
    task.spawn(function()
        local reason
        for attempt=1,4 do
            if not alive then return end
            local point,why=findLocationInMap(destination)
            if not point then
                local saved=state.teleportPoints[destination]
                if type(saved)=='table' and #saved==3 then
                    point=Vector3.new(saved[1],saved[2],saved[3])
                    log('WAYPOINT_FALLBACK',destination..' | saved position')
                end
            end
            if point then
                pcall(function()player:RequestStreamAroundAsync(point,2)end)
                local grounded=groundedPoint(point,false)
                if grounded then
                    local ok,failed=travelNow(grounded-Vector3.new(0,4,0),destination)
                    if ok then
                        reportStatus('Teleporte iniciado: '..destination..' (verificando posição)')
                        return
                    end
                    reason=tostring(failed)
                else
                    reason='Não foi encontrado piso seguro junto ao destino'
                end
            else
                reason=why
            end
            task.wait(0.4)
        end
        reportStatus('Teleporte indisponível: '..tostring(reason))
        log('MAP_LOCATION_UNAVAILABLE',destination..' | '..tostring(reason))
    end)
    return true
end

-- No hardcoded PM/helmet XYZ in the supplied decompiled source. Capture a REAL
-- server-replicated player location once; then persist the named waypoint.
local function captureWaypoint(key)
    if key~='PM_Batalhao' and key~='LojaCapacetes' then return end
    local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
    if not root then reportStatus('Personagem não encontrado para marcar local');return end
    local p=root.Position
    state.teleportPoints[key]={p.X,p.Y,p.Z}
    changed()
    log('WAYPOINT_SAVED',key..' | '..math.floor(p.X)..','..math.floor(p.Y)..','..math.floor(p.Z))
    reportStatus('Destino salvo: '..key)
end
local lastWaypointDiscovery=0
local function discoverNearbyWaypoints()
    if os.clock()-lastWaypointDiscovery<8 then return end
    lastWaypointDiscovery=os.clock()
    local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
    if not root then return end
    for _,key in ipairs({'PM_Batalhao','LojaCapacetes'}) do
        if not state.teleportPoints[key] then
            local p=findLocationInMap(key)
            if p and (root.Position-p).Magnitude<350 then
                state.teleportPoints[key]={p.X,p.Y,p.Z}
                changed()
                log('WAYPOINT_AUTO_SAVED',key)
            end
        end
    end
end

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
    for part,props in pairs(runtime.wheelOriginal) do
        if typeof(part)=='Instance' and part.Parent then
            pcall(function()part.CustomPhysicalProperties=props==false and nil or props end)
        end
    end
    table.clear(runtime.wheelOriginal)
    runtime.wheelVehicle=nil
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
    if runtime.wheelVehicle~=model then restoreWheels()end
    if not (state.raceMode and (state.drift or state.grip)) then restoreWheels();return end
    runtime.wheelVehicle=model
    for _,wheel in ipairs(wheelParts(model)) do
        if runtime.wheelOriginal[wheel]==nil then runtime.wheelOriginal[wheel]=wheel.CustomPhysicalProperties or false end
        local original=runtime.wheelOriginal[wheel]
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
    runtime.lastFallModel=nil
    runtime.lastFallCheck=0
    for scriptObj,original in pairs(runtime.fallScriptOriginal) do
        if typeof(scriptObj)=='Instance' and scriptObj.Parent then
            pcall(function()scriptObj.Disabled=original end)
        end
        runtime.fallScriptOriginal[scriptObj]=nil
    end
    state.fallScriptsDisabled=0
end
local function refreshFallScripts(model)
    local shouldGuard=state.antiFall
    if not model or not shouldGuard then
        if next(runtime.fallScriptOriginal) then restoreFallScripts() end
        return
    end
    if runtime.lastFallModel==model and os.clock()-runtime.lastFallCheck<0.3 then return end
    runtime.lastFallModel=model
    runtime.lastFallCheck=os.clock()
    local desired={}
    local found=0
    for _,node in ipairs(model:GetDescendants()) do
        if node:IsA('LocalScript') and node.Name=='Falling' then
            desired[node]=true
            found=found+1
            if runtime.fallScriptOriginal[node]==nil then
                local ok,wasDisabled=pcall(function()return node.Disabled end)
                if ok then
                    runtime.fallScriptOriginal[node]=wasDisabled
                    local disabled=pcall(function()node.Disabled=true end)
                    log('FALL_SCRIPT',node:GetFullName()..' | disabled='..tostring(disabled))
                end
            else
                local ok,disabled=pcall(function()return node.Disabled end)
                if ok and not disabled then pcall(function()node.Disabled=true end) end
            end
        end
    end
    for node,original in pairs(runtime.fallScriptOriginal) do
        if not desired[node] then
            if node.Parent then pcall(function()node.Disabled=original end) end
            runtime.fallScriptOriginal[node]=nil
        end
    end
    state.fallScriptsFound=found
    local n=0;for _ in pairs(runtime.fallScriptOriginal) do n=n+1 end
    state.fallScriptsDisabled=n
end
local function restoreFallGuard()
    if runtime.ghostGuardHum and runtime.ghostGuardHum.Parent then
        for kind,old in pairs(runtime.ghostGuardStates) do
            pcall(function()runtime.ghostGuardHum:SetStateEnabled(kind,old)end)
        end
    end
    runtime.ghostGuardHum=nil
    table.clear(runtime.ghostGuardStates)
end
local function guardRider(hum,seat)
    if not state.antiFall or not hum or not seat then return end
    if runtime.ghostGuardHum~=hum then
        restoreFallGuard()
        runtime.ghostGuardHum=hum
        for _,kind in ipairs({Enum.HumanoidStateType.FallingDown,Enum.HumanoidStateType.Ragdoll}) do
            local ok,old=pcall(function()return hum:GetStateEnabled(kind)end)
            if ok then
                runtime.ghostGuardStates[kind]=old
                pcall(function()hum:SetStateEnabled(kind,false)end)
            end
        end
        log('FALL_GUARD','Local rider states guarded; Falling LocalScripts handled separately')
    end
    runtime.lastGhostSeat=seat
    runtime.lastGhostHum=hum
    runtime.ghostSeatLostAt=nil
    runtime.reseatAttempts=0
end

local function clearGhostLinks()
    for part,others in pairs(runtime.ghostLinks) do
        for other,link in pairs(others) do
            if typeof(link)=='Instance' then pcall(function()link:Destroy()end)end
            others[other]=nil
        end
        runtime.ghostLinks[part]=nil
    end
    state.ghostLinks=0
    state.ghostParts=0
end
local function restoreGhost()
    clearGhostLinks()
    restoreFallGuard()
    runtime.ghostVehicle=nil
    runtime.lastGhostSeat=nil
    runtime.lastGhostHum=nil
    runtime.ghostSeatLostAt=nil
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
    if runtime.ghostVehicle~=model then clearGhostLinks();runtime.ghostVehicle=model;runtime.lastGhostRefresh=0 end
    local hum=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
    if state.antiFall then guardRider(hum,seat) end
    -- Refresh frequently enough for moving vehicles. No global map-wide scan.
    if os.clock()-runtime.lastGhostRefresh<0.18 then return end
    runtime.lastGhostRefresh=os.clock()
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
        if os.clock()-runtime.lastGhostLog>10 then
            runtime.lastGhostLog=os.clock()
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
    for part0,links in pairs(runtime.ghostLinks) do
        for part1,link in pairs(links) do
            if not wanted[part0] or not wanted[part0][part1] or not link.Parent then
                pcall(function()link:Destroy()end)
                links[part1]=nil
            end
        end
        if not next(links) then runtime.ghostLinks[part0]=nil end
    end
    for part0,parts in pairs(wanted) do
        runtime.ghostLinks[part0]=runtime.ghostLinks[part0] or {}
        for part1 in pairs(parts) do
            if runtime.ghostLinks[part0][part1]==nil then
                local ok,link=pcall(function()
                    local nc=Instance.new('NoCollisionConstraint')
                    nc.Name='PVH_GrauSP_Ghost'
                    nc.Part0=part0
                    nc.Part1=part1
                    nc.Parent=part0
                    return nc
                end)
                if ok then runtime.ghostLinks[part0][part1]=link end
            end
        end
    end
    local actual,actualDynamic,actualStatic=0,0,0
    for _,links in pairs(runtime.ghostLinks) do
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
    if not state.antiFall or not runtime.lastGhostSeat or not runtime.lastGhostHum then return end
    if not runtime.ghostSeatLostAt then runtime.ghostSeatLostAt=os.clock() end
    local now=os.clock()
    local char=player.Character
    local hum=runtime.lastGhostHum
    local seat=runtime.lastGhostSeat
    if now<runtime.manualDismountUntil or now-runtime.ghostSeatLostAt>1.5
        or not seat.Parent or not hum.Parent or hum.Health<=0
        or not char or hum.Parent~=char then
        if runtime.reseatAttempts>0 then
            log('GHOST_RESEAT_STOP','Rider could not be restored; server ownership/seat may prevent reseating')
        end
        restoreGhost()
        return
    end
    local root=char:FindFirstChild('HumanoidRootPart')
    if root and seat.Occupant==nil and (root.Position-seat.Position).Magnitude<=12
        and now-runtime.lastReseatTry>=0.45 and runtime.reseatAttempts<2 then
        runtime.lastReseatTry=now
        runtime.reseatAttempts=runtime.reseatAttempts+1
        state.ejectionAttempts=state.ejectionAttempts+1
        local ok,err=pcall(function()seat:Sit(hum)end)
        log('GHOST_RESEAT',string.format('attempt=%d/%d ok=%s %s',runtime.reseatAttempts,2,tostring(ok),tostring(err or '')))
    end
end
local function clearRam()
    for _,c in ipairs(runtime.ramConnections) do pcall(function()c:Disconnect()end)end
    table.clear(runtime.ramConnections)
    runtime.ramVehicle=nil
end
-- PM expanded bumper: experimental CLIENT-SIDE contact area, not a server
-- hitbox bypass. Attached to the locally occupied vehicle ONLY when enabled.
-- It can interact locally with physics, but other clients/the server may ignore it.
local function clearPMBumper()
    if runtime.bumperContactConnection then pcall(function()runtime.bumperContactConnection:Disconnect()end)end
    runtime.bumperContactConnection=nil
    for _,link in ipairs(runtime.bumperCollisionLinks) do
        pcall(function()link:Destroy()end)
    end
    table.clear(runtime.bumperCollisionLinks)
    if runtime.bumperPart then pcall(function()runtime.bumperPart:Destroy()end)end
    runtime.bumperPart=nil
    runtime.bumperWeld=nil
    runtime.bumperModel=nil
    state.bumperModel=nil
end
local function updatePMBumper(model,seat)
    if not state.pmBumper or not model or not seat then
        if runtime.bumperPart then clearPMBumper()end
        return
    end
    if runtime.bumperModel==model and runtime.bumperPart and runtime.bumperPart.Parent then return end
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
        runtime.bumperWeld=weld
        runtime.bumperPart=bumper
        for _,own in ipairs(model:GetDescendants()) do
            if own:IsA('BasePart') and own~=bumper and own.CanCollide then
                local nc=Instance.new('NoCollisionConstraint')
                nc.Part0=bumper
                nc.Part1=own
                nc.Parent=bumper
                runtime.bumperCollisionLinks[#runtime.bumperCollisionLinks+1]=nc
                if #runtime.bumperCollisionLinks>=60 then break end
            end
        end
        runtime.bumperContactConnection=bumper.Touched:Connect(function(other)
            if not alive or not state.pmBumper or not other or other:IsDescendantOf(model) then return end
            if os.clock()-runtime.lastBumperContact<0.8 then return end
            local candidate=other:FindFirstAncestorWhichIsA('Model')
            if not candidate or not candidate:FindFirstChild('Wheels',true) then return end
            runtime.lastBumperContact=os.clock()
            state.bumperContacts=state.bumperContacts+1
            log('PM_BUMPER_CONTACT',candidate.Name..' | local contact only; remote knockdown UNVERIFIED')
        end)
    end)
    if ok and runtime.bumperPart then
        runtime.bumperModel=model
        state.bumperModel=model.Name
        log('PM_BUMPER','local bumper attached to '..model.Name..' | server effects unverified')
    else
        clearPMBumper()
        log('PM_BUMPER_ERROR',err)
    end
end
local function setRamVehicle(model,seat)
    if runtime.ramVehicle==model then return end
    clearRam()
    if not state.pmRam or not model or state.ghost then return end
    -- Detect contacts made by the player's occupied vehicle. Never claim
    -- another player's assembly is controllable without ownership.
    ramVehicle=model
    local parts=0
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA('BasePart') and part.CanCollide and parts<20 then
            parts=parts+1
            runtime.ramConnections[#runtime.ramConnections+1]=part.Touched:Connect(function(hit)
                if not alive or not state.pmRam or state.ghost then return end
                if not hit or hit:IsDescendantOf(model) then return end
                if os.clock()-runtime.lastRamContact<0.5 then return end
                local other=hit:FindFirstAncestorWhichIsA('Model')
                if not other or not other:FindFirstChild('Wheels',true) then return end
                local own=seat.AssemblyRootPart or seat
                local otherRoot=hit.AssemblyRootPart or hit
                if own.AssemblyLinearVelocity.Magnitude<18 then return end
                runtime.lastRamContact=os.clock()
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
        if next(runtime.fallScriptOriginal) then restoreFallScripts() end
        if runtime.wheelVehicle then restoreWheels()end
        if nativeWheelieHeld then stopWheelie()end
        if state.antiFall then
            attemptGhostReseat()
        elseif runtime.ghostVehicle then
            restoreGhost()
        elseif runtime.ghostGuardHum then
            restoreFallGuard()
        end
        if runtime.ramVehicle then clearRam()end
        if runtime.bumperPart then clearPMBumper()end
        runtime.liveSpeed=0;runtime.racePhysicsPossible=false;state.physicsReason='no_driving_vehicle'
        if runtime.lastVehicleReason~=state.vehicleReason then
            runtime.lastVehicleReason=state.vehicleReason
            log('VEHICLE_STATUS',state.vehicleReason)
        end
        return
    end
    local assembly=seat.AssemblyRootPart or seat
    runtime.liveSpeed=assembly.AssemblyLinearVelocity.Magnitude
    local owner,reason=ownsPhysics(assembly)
    runtime.racePhysicsPossible=owner==true
    state.physicsReason=reason
    if runtime.lastVehicleReason~=model.Name..':'..reason then
        runtime.lastVehicleReason=model.Name..':'..reason
        runtime.lastSeatName=seat.Name
        log('VEHICLE_STATUS',model.Name..' seat='..seat.Name..' physics='..reason)
    end
    if state.antiFall then refreshFallScripts(model) else refreshFallScripts(nil) end
    if state.ghost or state.ghostWalls then
        updateGhost(model,seat)
    elseif runtime.ghostVehicle then
        restoreGhost()
    elseif state.antiFall then
        local hum=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
        guardRider(hum,seat)
    elseif runtime.ghostGuardHum then
        restoreFallGuard()
    end
    -- The obsolete PM impulse mode could not control other player's vehicle assemblies.
    -- Keep the old feature disabled rather than misreporting knockdowns.
    if runtime.ramVehicle then clearRam()end
    if state.pmBumper then updatePMBumper(model,seat)
    elseif runtime.bumperPart then clearPMBumper()end
    wheelieTick(model,seat,owner)
    if not state.raceMode then
        if runtime.wheelVehicle then restoreWheels()end
        return
    end
    state.raceTicks=state.raceTicks+1
    -- Do not alter another assembly's wheels if physics ownership is absent.
    if owner~=true then
        if runtime.wheelVehicle then restoreWheels()end
        state.raceDenied=state.raceDenied+1
        if os.clock()-runtime.lastRaceProbe>5 then
            runtime.lastRaceProbe=os.clock()
            log('RACE_BLOCKED','Assembly physics not owner-confirmed: '..reason)
        end
        return
    end
    local style=(state.drift and 'drift') or (state.grip and 'grip') or 'normal'
    if style=='normal' then
        if runtime.wheelVehicle then restoreWheels()end
    elseif model~=runtime.wheelVehicle or style~=lastWheelStyle then
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
        if not ok and os.clock()-runtime.lastPhysicsStats>5 then
            runtime.lastPhysicsStats=os.clock();log('RACE_ERROR',err)
        end
    end
end)
track(UserInputService.InputBegan,function(input,processed)
    if processed then return end
    if input.KeyCode==Enum.KeyCode.Space
        and state.antiFall then
        runtime.manualDismountUntil=os.clock()+2
    end
end)

-- Spatial ESP: never outline every static vehicle in the map.
-- Draw labels/boxes for loaded characters, and dynamically occupied vehicles
-- inside an adjustable distance; ignore the game's decorative bike models.
local function clearESP()
    for model,hi in pairs(runtime.espHighlights) do
        if typeof(hi)=='Instance' then pcall(function()hi:Destroy()end) end
        runtime.espHighlights[model]=nil
    end
    for model,gui in pairs(runtime.espTags) do
        if typeof(gui)=='Instance' then pcall(function()gui:Destroy()end) end
        runtime.espTags[model]=nil
    end
    state.espPlayerCount=0
    state.espVehicleCount=0
end
local function removeESP(model)
    local hi=runtime.espHighlights[model]
    if hi then pcall(function()hi:Destroy()end)end
    runtime.espHighlights[model]=nil
    local tag=runtime.espTags[model]
    if tag then pcall(function()tag:Destroy()end)end
    runtime.espTags[model]=nil
end
local function tagESP(model,anchor,title,color,kind,distance)
    if not model or not model.Parent or not anchor then return end
    if not runtime.espHighlights[model] then
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
        if ok then runtime.espHighlights[model]=created end
    end
    local labelGui=runtime.espTags[model]
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
        runtime.espTags[model]=labelGui
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
                        tagESP(char,head or root,other.Name,color,'player',dist)
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
                    and not seat.Anchored then
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
    for model in pairs(runtime.espHighlights) do
        if not wanted[model] or not model.Parent then removeESP(model)end
    end
    for model in pairs(runtime.espTags) do
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
    -- The original phone script already renders GPSBil in the world.
    -- Avoid a second billboard that previously overlapped the native marker.
    clearGps()
    state.gpsTarget=point
    state.gpsName=tostring(name or '')
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
local function realDeliveryPrompt(stage,targetName)
    local root=workspace:FindFirstChild('Ifuud')
    if not root then return nil,'Workspace.Ifuud não carregado' end
    local path=stage=='pickup' and {'GetOrders','Pedidos'} or {'DeliverOrder','LocalDeEntrega'}
    for _,name in ipairs(path) do
        root=root:FindFirstChild(name)
        if not root then return nil,'Área de entrega ainda não carregada' end
    end
    local entry=root:FindFirstChild(tostring(targetName))
    if not entry then return nil,'Destino da entrega não encontrado no mapa: '..tostring(targetName) end
    local prompt=entry:FindFirstChild(stage=='pickup' and 'PegarPedido' or 'Entregar')
    if not prompt or not prompt:IsA('ProximityPrompt') then
        return nil,'Prompt físico da entrega ausente'
    end
    return prompt,nil
end

local function safeGroundNearPrompt(prompt)
    local anchor=prompt.Parent
    local attachment=anchor and anchor:IsA('Attachment') and anchor or nil
    local base=attachment and attachment.Parent or anchor
    if not base or not base:IsA('BasePart') then return nil,'Prompt não ligado a uma peça física' end
    local point=attachment and attachment.WorldPosition or base.Position
    local maxD=math.max(5,(tonumber(prompt.MaxActivationDistance) or 8)+1)
    local lateral=math.clamp(maxD*0.38,1.75,4)
    local vectors={
        Vector3.zero,
        base.CFrame.LookVector*lateral,-base.CFrame.LookVector*lateral,
        base.CFrame.RightVector*lateral,-base.CFrame.RightVector*lateral,
    }
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={player.Character}
    params.IgnoreWater=true
    local best,score=nil,math.huge
    for _,offset in ipairs(vectors) do
        local top=point+Vector3.new(offset.X,14,offset.Z)
        local hit=workspace:Raycast(top,Vector3.new(0,-28,0),params)
        if hit and hit.Instance and hit.Normal.Y>0.63
            and hit.Instance.CanCollide then
            local candidate=hit.Position+Vector3.new(0,3.0,0)
            local dist=(candidate-point).Magnitude
            if dist<=maxD and dist<score then
                best,score=candidate,dist
            end
        end
    end
    if not best then return nil,'Sem piso acessível dentro do alcance do prompt' end
    return best,nil,point,maxD
end

local function dispatchAutoIfuudTarget(stage,targetName)
    if not state.autoIFood then return end
    local token=autoIfuudToken
    task.spawn(function()
        -- GPS coordinates are ONLY used to request streamed map content.
        -- Travel itself targets the real collection/delivery prompt.
        local coords=getIfuudCoordinates()
        local tableForStage=coords and (stage=='pickup' and coords.Locais or coords.Entrega)
        local streamPosition=tableForStage and vector3Of(tableForStage[targetName])
        if streamPosition then
            pcall(function() player:RequestStreamAroundAsync(streamPosition,2) end)
        end
        if not alive or not state.autoIFood or token~=autoIfuudToken then return end
        local prompt=nil
        local deadline=os.clock()+10
        local reason='Prompt não carregado'
        while alive and state.autoIFood and token==autoIfuudToken and os.clock()<deadline do
            prompt,reason=realDeliveryPrompt(stage,targetName)
            if prompt then break end
            task.wait(0.35)
        end
        if not alive or not state.autoIFood or token~=autoIfuudToken then return end
        if not prompt then
            stopAutoIfuud(reason)
            reportStatus('iFood: '..tostring(reason))
            return
        end
        local target,groundReason,anchorPoint,maxDistance=safeGroundNearPrompt(prompt)
        if not target then
            stopAutoIfuud(groundReason)
            reportStatus('iFood: '..tostring(groundReason))
            return
        end
        -- travelNow adds +4 studs to root. Convert safe standing position.
        local moved,why=travelNow(target-Vector3.new(0,4,0),stage..':'..targetName)
        if not moved then
            stopAutoIfuud('Falha de teleporte: '..tostring(why))
            return
        end
        task.wait(1.25)
        if not alive or not state.autoIFood or token~=autoIfuudToken then return end
        local hrp=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
        if not hrp or (hrp.Position-anchorPoint).Magnitude>maxDistance then
            stopAutoIfuud('Servidor recusou o deslocamento ou o ponto está inacessível')
            reportStatus('iFood: não chegou ao prompt; ciclo interrompido')
            return
        end
        if stage=='delivery' then
            autoIfuudDispatch('AguardandoEntregaMundo','aguardando_prompt',targetName)
        end
        local path=stage=='pickup' and {'GetOrders','Pedidos'} or {'DeliverOrder','LocalDeEntrega'}
        local promptName=stage=='pickup' and 'PegarPedido' or 'Entregar'
        local promptDeadline=os.clock()+8
        while alive and state.autoIFood and token==autoIfuudToken and os.clock()<promptDeadline do
            if performPrompt(path,promptName,targetName) then
                state.ifoodAutoStatus='aguardando confirmação: '..stage
                log('IFOOD_AUTO_PROMPT',stage..'/'..targetName)
                return
            end
            task.wait(0.30)
        end
        if state.autoIFood and token==autoIfuudToken then
            stopAutoIfuud('Prompt não ativou após teleporte')
        end
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
        if nearest.name~=runtime.pmNearestPlayer then
            runtime.pmNearestPlayer=nearest.name
            log('PM_TARGET',state.pmNearest)
        end
    else
        state.pmNearest='Sem motociclistas próximos'
        runtime.pmNearestPlayer=nil
    end
end

task.spawn(function()
    while alive do
        local ok,err=pcall(refreshESP)
        if not ok then log('ESP_ERROR',err) end
        local okPM,pmErr=pcall(updatePMRadar)
        if not okPM and os.clock()-runtime.lastPMLog>10 then runtime.lastPMLog=os.clock();log('PM_ERROR',pmErr) end
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
        pcall(function()
            if not ensureLogFolder() then return end
            writefile(REPORT_PATH,'PVH GRAU SP '..VERSION..' | BOOT FAILURE\n'
            ..'CHECK [FAIL] Obsidian library source download or load\n'
            ..tostring(resLibrary)..'\n'
            ..'The vehicle spawner and other features were not started.\n')
        end)
    end
    alive=false
    pcall(restoreWheels);pcall(restoreGhost);pcall(restoreFallScripts);pcall(clearRam);pcall(clearPMBumper);pcall(clearESP);pcall(clearGps)
    for _,c in ipairs(runtime.connections) do pcall(function()c:Disconnect()end) end
    pcall(function()runtime.clickSound:Destroy()end)
    writeSession(true)
    return
end
Library=resLibrary
env.Library=Library
Library.ShowCustomCursor=false

local function unload()
    if runtime.rebuilding or not alive then return end
    log('UNLOAD','cleanup requested')
    if state.autoIFood then stopAutoIfuud('Unload')end
    -- Disable automation; lifecycle events terminate when alive becomes false.
    state.autoAlarm=false;state.autoTracker=false;state.autoLock=false
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
    for _,c in ipairs(runtime.connections) do pcall(function()c:Disconnect()end) end
    runtime.connections={}
    if Window and Library and not Library.Unloaded then pcall(function()Library:Unload()end) end
    pcall(function()runtime.clickSound:Destroy()end)
    if env.PVH_GrauSP_Unload==unload then env.PVH_GrauSP_Unload=nil end
    if env.PVH_GrauSP_Check then env.PVH_GrauSP_Check=nil end
    if env.Library==Library then env.Library=nil end
    warn('[PVH Grau SP] unloaded')
end
env.PVH_GrauSP_Unload=unload
track(UserInputService.InputBegan,function(input,processed)
    if processed or not alive then return end
    if input.KeyCode==Enum.KeyCode[state.unloadKey] then
        unload()
    elseif input.KeyCode==Enum.KeyCode[state.minimizeKey] then
        if Library and not Library.Unloaded and type(Library.Toggle)=='function' then
            pcall(function()Library:Toggle()end)
        end
    end
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
    checks[#checks+1]=seat and (runtime.racePhysicsPossible
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
            ' humanoid protected='..tostring(runtime.ghostGuardHum~=nil)..
            ' reseat attempts='..tostring(state.ejectionAttempts)..'; server rejection possible')
    local playerCount=0
    for _,p in ipairs(Players:GetPlayers())do if p~=player then playerCount=playerCount+1 end end
    checks[#checks+1]=not state.espPlayers
        and skip('ESP','Player highlights','player ESP OFF')
        or (playerCount==0 and skip('ESP','Player highlights','no other players')
        or unknown('ESP','Player ESP visibility','visually confirm client highlights'))
    checks[#checks+1]=not state.espVehicles
        and skip('ESP','Vehicle highlights','vehicle ESP OFF')
        or unknown('ESP','Nearby spawned vehicle ESP',
            'nearby='..state.espVehicleCount..' radius='..state.espVehicleRange)
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
            'part='..tostring(runtime.bumperPart and runtime.bumperPart.Parent~=nil)..
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
          ' spawnedVehiclesOnly=true',
        'PM bumper: contacts='..state.bumperContacts..' enabled='..tostring(state.pmBumper)..
          ' localPart='..tostring(runtime.bumperPart~=nil),
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
        local ok,err=pcall(function()
            assert(ensureLogFolder(),"Logs folder unavailable")
            writefile(REPORT_PATH,state.lastReport)
        end)
        if not ok then log('CHECKER_WRITE_ERROR',err)end
    end
    return counts.PASS,#checks
end
env.PVH_GrauSP_Check=runChecker
local function exportChecker()
    if state.lastReport=='' then runChecker() end
    if type(writefile)~='function' then reportStatus(tr('noStorage'));return end
    local ok,err=pcall(function()
        assert(ensureLogFolder(),"Logs folder unavailable")
        writefile(REPORT_PATH,state.lastReport)
    end)
    reportStatus(ok and ('workspace/'..REPORT_PATH) or tostring(err))
end


-- New Grau SP 2026-11-10 robbery remotes, from the supplied place dump.
-- Never forge client attribute changes or report a request as server confirmation.
local robbery={alarmToken=0,alarmBusy=false,lastAlarmData=nil,trackerToken=0,trackerBusy=false,searching=false,searchComplete=false,lockToken=0,lockBusy=false,lastLockAttempt=0,lockPrompts={},lockEvents=0}
local function robberyStatus(pt,en,code)
    local msg=state.language=='pt-BR' and pt or en
    if ui.robberyStatus then
        pcall(function()ui.robberyStatus:SetText(msg)end)
    end
    log(code or 'ROUBAR',msg)
end
local function robberyGui(name,shouldHide)
    local pg=player:FindFirstChildOfClass('PlayerGui')
    local gui=pg and pg:FindFirstChild(name)
    if gui and gui:IsA('ScreenGui') then
        if shouldHide then gui.Enabled=false end
        return gui
    end
end
local function alarmCall(action,index)
    local r=remote('AlarmeMinigame')
    if not r or not r:IsA('RemoteFunction') then
        return nil,'AlarmeMinigame unavailable'
    end
    local ok,result=pcall(function()
        if index==nil then return r:InvokeServer(action) end
        return r:InvokeServer(action,index)
    end)
    if not ok then return nil,tostring(result) end
    if type(result)~='table' then return nil,'invalid server response' end
    return result,nil
end
-- Source-verified native cancel path (AlarmeMinigame LocalScript).
-- F8 recovery works even when the native Cancel button cannot be clicked.
local function cancelAlarmMinigame()
    local pg=player:FindFirstChildOfClass('PlayerGui')
    local gui=pg and pg:FindFirstChild('AlarmeMinigameGui')
    if not (gui and gui:IsA('ScreenGui') and gui.Enabled)
        and robbery.lastAlarmData==nil then
        return false
    end
    robbery.alarmToken+=1
    robbery.alarmBusy=false
    robbery.lastAlarmData=nil
    local cancelRemote=remote('AlarmeMinigame')
    if cancelRemote and cancelRemote:IsA('RemoteFunction') then
        task.spawn(function()
            local ok,response=pcall(function()return cancelRemote:InvokeServer('Cancelar')end)
            log('ALARM_CANCEL_REMOTE',ok and 'sent' or tostring(response))
        end)
    else
        log('ALARM_CANCEL_REMOTE','RemoteFunction absent')
    end
    pcall(function()ContextActionService:UnbindAction('AlarmeMinigameInput')end)
    if gui then pcall(function()gui.Enabled=false end)end
    robberyStatus('Alarme cancelado e controles liberados.','Alarm cancelled and input released.','ALARM_CANCEL_RECOVER')
    return true
end
track(UserInputService.InputBegan,function(input)
    if alive and input.KeyCode==Enum.KeyCode.F8 then
        cancelAlarmMinigame()
    end
end)

local function solveAlarm(info)
    if robbery.alarmBusy or not alive then return end
    robbery.alarmBusy=true
    robbery.alarmToken=robbery.alarmToken+1
    local token=robbery.alarmToken
    local function valid()
        return alive and robbery.alarmToken==token
    end
    task.spawn(function()
        local confirmed=false
        local ok,err=pcall(function()
            if type(info)~='table' then
                robberyStatus('Abra o alarme da moto primeiro.','Open the vehicle alarm first.','ALARM_WAIT')
                return
            end
            -- Keep the native alarm GUI visible and its Cancel button usable.
            local phase=(info.fase==2 and info.fase2) or nil
            if not phase then
                local clicks=math.clamp(tonumber(info.cliques) or 3,1,8)
                for screw=1,4 do
                    if not valid() then return end
                    local completed=math.clamp(tonumber(info.parafusos and info.parafusos[screw]) or 0,0,clicks)
                    local retries=0
                    while completed<clicks and valid() and retries<15 do
                        local result,errorText=alarmCall('Parafuso',screw)
                        if errorText then
                            robberyStatus('Alarme: '..errorText,'Alarm: '..errorText,'ALARM_ERROR')
                            return
                        end
                        if result.fase==2 and type(result.fase2)=='table' then
                            phase=result.fase2
                            break
                        end
                        local nextCount=tonumber(result.contagem)
                        if result.removido then completed=clicks
                        elseif nextCount and nextCount>completed then completed=nextCount
                        else retries=retries+1 end
                        task.wait(result.ignorado and 0.22 or 0.11)
                    end
                    if phase then break end
                    if completed<clicks then
                        robberyStatus('Alarme: parafuso não confirmado.','Alarm: screw not confirmed.','ALARM_STOP')
                        return
                    end
                end
            end
            if not valid() then return end
            if not phase then
                robberyStatus('Alarme: aguardando fase 2.','Alarm: waiting for phase 2.','ALARM_PENDING')
                return
            end
            local targetHz=tonumber(phase.hz)
            if not targetHz then
                robberyStatus('Alarme: frequência indisponível.','Alarm: siren frequency unavailable.','ALARM_PENDING')
                return
            end
            local bestIndex,bestDiff=nil,math.huge
            for fuse=1,8 do
                if not valid() then return end
                local result=alarmCall('Medir',fuse)
                if result and tonumber(result.hz) then
                    local delta=math.abs(tonumber(result.hz)-targetHz)
                    if delta<bestDiff then bestIndex,bestDiff=fuse,delta end
                    if delta<=0.08 then break end
                end
                task.wait(0.09)
            end
            if not valid() then return end
            if not bestIndex or bestDiff>0.20 then
                robberyStatus('Alarme: nenhum fusível corresponde à sirene.','Alarm: no fuse matched the siren.','ALARM_NO_MATCH')
                return
            end
            -- The native client measures its selected fuse before pulling it.
            local measure=alarmCall('Medir',bestIndex)
            if not measure or math.abs((tonumber(measure.hz) or -100)-targetHz)>0.20 then
                robberyStatus('Alarme: medição não confirmada.','Alarm: measurement not confirmed.','ALARM_STOP')
                return
            end
            task.wait(0.10)
            local result,errorText=alarmCall('Puxar',bestIndex)
            if errorText then
                robberyStatus('Alarme: '..errorText,'Alarm: '..errorText,'ALARM_ERROR')
            elseif result.correto==true then
                confirmed=true
                robberyStatus('Alarme: fusível correto confirmado pelo servidor.','Alarm: correct fuse confirmed by server.','ALARM_CONFIRMED')
            else
                robberyStatus('Alarme: servidor não confirmou.','Alarm: server did not confirm.','ALARM_DENIED')
            end
        end)
        if not ok then robberyStatus('Alarme: erro local.','Alarm: local error.','ALARM_EXCEPTION');log('ALARM_EXCEPTION',err) end
        robbery.alarmBusy=false
        if valid() and not confirmed then
            local gui=robberyGui('AlarmeMinigameGui',false)
            if gui and gui.Enabled==false then gui.Enabled=true end
        end
    end)
end
local function actionPrompt(keywords,limit)
    local character=player.Character
    local root=character and character:FindFirstChild('HumanoidRootPart')
    if not root then
        robberyStatus('Personagem indisponível.','Character unavailable.','ROUBAR_NO_CHAR')
        return false
    end
    local nearest,dist=nil,limit or 12
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA('ProximityPrompt') and obj.Enabled then
            local node=obj.Parent
            local test=(obj.Name..' '..obj.ActionText..' '..obj.ObjectText..' '..(node and node.Name or '')):lower()
            local hit=false
            for _,needle in ipairs(keywords) do
                if test:find(needle,1,true) then hit=true break end
            end
            if hit then
                local part=node and (node:IsA('BasePart') and node or node:FindFirstAncestorWhichIsA('BasePart'))
                local pos=part and part.Position
                if pos and (root.Position-pos).Magnitude<dist then
                    dist=(root.Position-pos).Magnitude
                    nearest=obj
                end
            end
        end
    end
    if not nearest then
        robberyStatus('Aproxime-se da moto e da interação.','Approach the motorcycle and its interaction.','ROUBAR_NO_PROMPT')
        return false
    end
    local trigger=type(fireproximityprompt)=='function' and fireproximityprompt or nil
    if not trigger then
        robberyStatus('Executor sem fireproximityprompt.','Executor has no fireproximityprompt.','ROUBAR_NO_TRIGGER')
        return false
    end
    local ok,result=pcall(trigger,nearest)
    if not ok then
        log('ROUBAR_TRIGGER_ERROR',result)
        robberyStatus('Falha ao iniciar interação.','Could not start interaction.','ROUBAR_FAILED')
        return false
    end
    robberyStatus('Interação solicitada: '..nearest.Name,'Interaction requested: '..nearest.Name,'ROUBAR_TRIGGER')
    return true
end

-- LockCore settings found in the supplied 2026-11-10 place dump:
-- tool="Chave T", prompt parents={"PromptPick","LckPick"},
-- server distance margin=6 studs, stage windows={{1.5,.4},{2,.3},{2.6,.26},{3,.25}}.
-- Server logic is not replicated; stage timing is an experimental native-input attempt.
local lockStages={{1.5,0.4},{2,0.3},{2.6,0.26},{3,0.25}}
local function isLockPrompt(prompt)
    if not prompt or not prompt:IsA('ProximityPrompt') then return false end
    local node=prompt
    for _=1,4 do
        if not node then break end
        local name=tostring(node.Name):lower()
        if name=='promptpick' or name=='lckpick' then return true end
        node=node.Parent
    end
    return false
end
for _,node in ipairs(workspace:GetDescendants()) do
    if node:IsA('ProximityPrompt') then robbery.lockPrompts[node]=true end
end
track(workspace.DescendantAdded,function(node)
    if node:IsA('ProximityPrompt') then robbery.lockPrompts[node]=true end
end)
local function lockTool()
    local character=player.Character
    local backpack=player:FindFirstChildOfClass('Backpack')
    local tool=(character and character:FindFirstChild('Chave T'))
        or (backpack and backpack:FindFirstChild('Chave T'))
    return tool and tool:IsA('Tool') and tool or nil
end
local function lockPromptPosition(prompt)
    local node=prompt.Parent
    if node and node:IsA('Attachment') then return node.WorldPosition end
    local part=node and (node:IsA('BasePart') and node
        or node:FindFirstAncestorWhichIsA('BasePart'))
    return part and part.Position or nil
end
local function nearestLockPrompt()
    local character=player.Character
    local root=character and character:FindFirstChild('HumanoidRootPart')
    if not root then return nil,nil end
    local best,nearest=nil,math.huge
    for prompt in pairs(robbery.lockPrompts) do
        if not prompt:IsDescendantOf(workspace) then
            robbery.lockPrompts[prompt]=nil
        elseif prompt.Enabled and isLockPrompt(prompt) then
            local position=lockPromptPosition(prompt)
            local maxDistance=math.min(6,tonumber(prompt.MaxActivationDistance) or 6)
            if position then
                local d=(position-root.Position).Magnitude
                if d<=maxDistance and d<nearest then
                    nearest=d best=prompt
                end
            end
        end
    end
    return best,nearest
end
local function lockState(prompt)
    local node=prompt
    for _=1,8 do
        if not node or node==workspace then break end
        for _,key in ipairs({'CadeadoAtivo','Trancado','Locked','LockActive'}) do
            local value=node:GetAttribute(key)
            if type(value)=='boolean' then return value,node,key end
            local child=node:FindFirstChild(key)
            if child and child:IsA('BoolValue') then return child.Value,node,key end
        end
        node=node.Parent
    end
    return nil,nil,nil
end
local function nativeLockPrompt(prompt)
    local trigger=type(fireproximityprompt)=='function' and fireproximityprompt or nil
    if trigger then
        local ok,err=pcall(trigger,prompt)
        if ok then return true,'executor' end
        log('LOCK_TRIGGER_ERROR',err)
    end
    -- Public Roblox prompt methods as fallback; server still validates distance.
    local ok,err=pcall(function()
        prompt:InputHoldBegin()
        task.wait(math.max(0,tonumber(prompt.HoldDuration) or 0)+0.08)
        prompt:InputHoldEnd()
    end)
    if not ok then log('LOCK_TRIGGER_ERROR',err) end
    return ok,ok and 'native' or 'failed'
end
local function attemptLock(force)
    if not alive or robbery.lockBusy then return false end
    if not force and not state.autoLock then return false end
    if os.clock()-robbery.lastLockAttempt<7 then return false end
    local character=player.Character
    local humanoid=character and character:FindFirstChildOfClass('Humanoid')
    local tool=lockTool()
    if not tool or not humanoid then
        if os.clock()-(robbery.lastLockNotice or 0)>7 then
            robbery.lastLockNotice=os.clock()
            robberyStatus('Cadeado: obtenha a Chave T.','Lock: obtain Chave T.','LOCK_NO_TOOL')
        end
        return false
    end
    -- Prompts sometimes spawn only once the required tool is equipped.
    if tool.Parent~=character then
        pcall(function()humanoid:EquipTool(tool)end)
        task.wait(0.18)
    end
    if not alive or tool.Parent~=character then
        robberyStatus('Cadeado: não foi possível equipar a Chave T.','Lock: Chave T could not be equipped.','LOCK_TOOL_FAILED')
        return false
    end
    local prompt,distance=nearestLockPrompt()
    if not prompt then
        if os.clock()-(robbery.lastLockNotice or 0)>7 then
            robbery.lastLockNotice=os.clock()
            robberyStatus('Cadeado: aproxime-se a até 6 studs.','Lock: come within 6 studs.','LOCK_NO_PROMPT')
        end
        return false
    end
    robbery.lockBusy=true
    robbery.lockToken+=1
    local token=robbery.lockToken
    robbery.lastLockAttempt=os.clock()
    task.spawn(function()
        local function valid()
            return alive and robbery.lockToken==token and (force or state.autoLock)
        end
        local confirmed=false
        local ok,err=pcall(function()
            if tool.Parent~=character then humanoid:EquipTool(tool) end
            task.wait(0.15)
            if not valid() or tool.Parent~=character then
                robberyStatus('Cadeado: Chave T não equipada.','Lock: Chave T not equipped.','LOCK_TOOL_FAILED')
                return
            end
            -- Test only the exact LockCore prompt. Never trigger unrelated prompts.
            local before,owner,key=lockState(prompt)
            if before==false then
                robberyStatus('Cadeado: já está destravado.','Lock already unlocked.','LOCK_ALREADY_OPEN')
                return
            end
            if not valid() then return end
            local sent,via=nativeLockPrompt(prompt)
            if not sent then
                robberyStatus('Cadeado: interação recusada.','Lock: interaction failed.','LOCK_TRIGGER_ERROR')
                return
            end
            robberyStatus('Cadeado: interação enviada ao jogo.','Lock: interaction sent to game.','LOCK_REQUESTED')
            log('LOCK_TARGET','prompt='..prompt:GetFullName()..' distance='..string.format('%.1f',distance or 0)..' via='..via)
            -- Try the tool's native Activate/Deactivate sequence using LockCore timing.
            -- Only the game server can decide whether any stage was accepted.
            for stage,spec in ipairs(lockStages) do
                if not valid() then return end
                if before==true and lockState(prompt)==false then
                    confirmed=true break
                end
                local waitFor=math.max(0.1,spec[1]-spec[2]/2)
                local deadline=os.clock()+waitFor
                while valid() and os.clock()<deadline do
                    if before==true and lockState(prompt)==false then confirmed=true break end
                    task.wait(math.min(0.1,deadline-os.clock()))
                end
                if confirmed or not valid() then break end
                local activated,activationErr=pcall(function()
                    tool:Activate()
                    task.wait(0.09)
                    tool:Deactivate()
                end)
                log('LOCK_STEP','stage='..stage..' tool='..tostring(activated))
                if not activated then log('LOCK_ACTIVATE_ERROR',activationErr) end
            end
            if not confirmed and valid() then
                task.wait(0.7)
                if before==true and lockState(prompt)==false then confirmed=true end
            end
            if confirmed then
                robberyStatus('Cadeado: destravamento confirmado.','Lock: server state unlocked.','LOCK_CONFIRMED')
            elseif valid() then
                robberyStatus('Cadeado: servidor não confirmou; tente manualmente.','Lock: server did not confirm; use native minigame.','LOCK_UNVERIFIED')
                log('LOCK_UNVERIFIED','initial='..tostring(before)..' attribute='..tostring(key))
            end
        end)
        if not ok then
            log('LOCK_EXCEPTION',err)
            robberyStatus('Cadeado: falha local.','Lock: local error.','LOCK_EXCEPTION')
        end
        robbery.lockBusy=false
    end)
    return true
end
local function setAutoLock(enabled)
    state.autoLock=enabled==true
    if not state.autoLock then
        robbery.lockToken+=1
        robberyStatus('Auto cadeado desligado.','Auto lock disabled.','LOCK_STOP')
    elseif not robbery.lockLoop then
        robbery.lockLoop=true
        robberyStatus('Auto cadeado ligado.','Auto lock enabled.','LOCK_ARMED')
        task.spawn(function()
            while alive and state.autoLock do
                if not robbery.lockBusy then attemptLock(false) end
                task.wait(1.2)
            end
            robbery.lockLoop=false
        end)
    end
    changed()
end

local function installRobberyEvents()
    local alarmEv=remote('AlarmeMinigameEvento')
    if alarmEv and alarmEv:IsA('RemoteEvent') then
        track(alarmEv.OnClientEvent,function(action,data)
            if action=='Abrir' and type(data)=='table' then
                robbery.lastAlarmData=data
                if state.autoAlarm then solveAlarm(data) end
            elseif action=='Fechar' then
                robbery.alarmToken=robbery.alarmToken+1
                robbery.lastAlarmData=nil
                robbery.alarmBusy=false
                robberyStatus('Alarme: minigame encerrado.','Alarm: minigame ended.','ALARM_CLOSED')
            end
        end)
    else
        log('ROUBAR_ALARM','AlarmeMinigameEvento not found')
    end
    local tracker=ReplicatedStorage:FindFirstChild('MinigameRastreadorRemote')
    if tracker and tracker:IsA('RemoteEvent') then
        track(tracker.OnClientEvent,function(info)
            if not state.autoTracker or type(info)~='table' then return end
            if typeof(info.Vehicle)~='Instance' then
                robberyStatus('Rastreador: veículo não informado.','Tracker: vehicle missing.','TRACKER_INVALID')
                return
            end
            local vehicle=info.Vehicle
            if robbery.trackerBusy then return end
            robbery.trackerBusy=true
            robbery.trackerToken=robbery.trackerToken+1
            local attempt=robbery.trackerToken
            local beforeActive=vehicle:GetAttribute('RastreadorAtivo')
            local beforeRemoved=vehicle:GetAttribute('RastreadorRemovido')
            task.defer(function()
                if not alive or not state.autoTracker then robbery.trackerBusy=false return end
                -- Keep the native tracker minigame visible for fallback.
                local success,errorText=pcall(function()
                    -- Native event protocol: success, vehicle instance, canceled.
                    tracker:FireServer(true,vehicle,false)
                end)
                if success then
                    robberyStatus('Rastreador: conclusão solicitada ao servidor.','Tracker: completion requested from server.','TRACKER_REQUEST')
                    task.delay(1.8,function()
                        if not alive or robbery.trackerToken~=attempt then return end
                        local afterActive=vehicle:GetAttribute('RastreadorAtivo')
                        local afterRemoved=vehicle:GetAttribute('RastreadorRemovido')
                        local confirmed=(afterRemoved==true and beforeRemoved~=true)
                            or (beforeActive==true and afterActive==false)
                        if confirmed then
                            robberyStatus('Rastreador: remoção confirmada pelo servidor.','Tracker: server confirmed removal.','TRACKER_CONFIRMED')
                        else
                            robberyStatus('Rastreador: confirmação pendente; puzzle disponível.','Tracker: not confirmed; puzzle available.','TRACKER_UNVERIFIED')
                            local gui=robberyGui('MinigameRastreadorGui',false)
                            if gui and gui.Enabled==false then gui.Enabled=true end
                        end
                    end)
                else
                    log('TRACKER_ERROR',errorText)
                    robberyStatus('Rastreador: erro ao enviar.','Tracker: request failed.','TRACKER_ERROR')
                    local gui=robberyGui('MinigameRastreadorGui',false)
                    if gui then gui.Enabled=true end
                end
                robbery.trackerBusy=false
            end)
        end)
    else
        log('ROUBAR_TRACKER','MinigameRastreadorRemote not found')
    end
    local search=remote('RastreadorBusca')
    if search and search:IsA('RemoteEvent') then
        track(search.OnClientEvent,function(action)
            if action=='Iniciar' then
                robbery.searching=true
                robberyStatus('Busca iniciada pelo servidor.','Search started by server.','SCAN_STARTED')
            elseif action=='Concluir' then
                robbery.searching=false
                robbery.searchComplete=true
                robberyStatus('Rastreador localizado pelo servidor.','Tracker located by server.','SCAN_CONFIRMED')
            elseif action=='Cancelar' then
                robbery.searching=false
                robberyStatus('Busca cancelada.','Search canceled.','SCAN_CANCELED')
            end
        end)
    end
end
installRobberyEvents()
if state.autoLock then task.defer(function()setAutoLock(true)end)end

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
        if state.sounds and runtime.clickSound then pcall(function()runtime.clickSound:Play()end)end
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
local function displayCategory(name)
    local titles={
        Motos_Gratis={'Motos grátis','Free motorcycles'},
        Carros_Gratis={'Carros grátis','Free cars'},
        Viaturas_Gratis={'Viaturas grátis','Free police vehicles'},
        Favoritos={'Favoritos','Favorites'},
    }
    local found=titles[tostring(name or '')]
    if found then return found[state.language=='pt-BR' and 1 or 2]end
    return (tostring(name or '-'):gsub('_',' '))
end
local function safeObsidianText(raw)
    return tostring(raw or ''):gsub('&','&amp;'):gsub('<','&lt;'):gsub('>','&gt;')
end
local function updateVehicleGallery()
    local options=catalogOptions()
    local pageCount=math.max(1,math.ceil(#options/8))
    vehiclePage=math.clamp(vehiclePage,1,pageCount)
    vehicleNamesShown={}
    for index,control in ipairs(vehicleButtons) do
        local name=options[(vehiclePage-1)*8+index]
        vehicleNamesShown[index]=name
        -- Obsidian's SetVisible controls its holder, not the initial button Base.
        -- Creating these buttons with Visible=false left Base.Visible=false forever.
        control:SetVisible(name~=nil)
        if name then
            local selected=state.selectedVehicle==name
            control:SetText((selected and '[*] ' or '     ')..safeObsidianText(name))
        end
    end
    if categoryLabel then
        categoryLabel:SetText('Categoria: '..safeObsidianText(displayCategory(state.selectedCategory)))
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
    categoryLabel=parent:AddLabel('Categoria: '..safeObsidianText(displayCategory(state.selectedCategory)),true)
    local previous=parent:AddButton({Text=(state.language=='pt-BR' and 'Anterior' or 'Previous'),Icon='chevron-left',
        Func=function()switchCategory(-1)end})
    previous:AddButton({Text=(state.language=='pt-BR' and 'Próxima' or 'Next'),Icon='chevron-right',
        Func=function()switchCategory(1)end})
    vehiclePageLabel=parent:AddLabel('0 veículos',true)
    for index=1,8 do
        local button=parent:AddButton({
            Text='-',Visible=true,
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
    local pageNav=parent:AddButton({Text=(state.language=='pt-BR' and 'Página anterior' or 'Previous page'),Icon='chevron-left',Func=function()
        vehiclePage=math.max(1,vehiclePage-1)
        updateVehicleGallery()
    end})
    pageNav:AddButton({Text=(state.language=='pt-BR' and 'Próxima página' or 'Next page'),Icon='chevron-right',Func=function()
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
local function refreshUILanguage(from,to)
    local replacements={}
    for key,oldValue in pairs(STR[from] or {}) do
        local newValue=(STR[to] or {})[key]
        if type(oldValue)=='string' and type(newValue)=='string'
            and oldValue~=newValue then replacements[oldValue]=newValue end
    end
    local captions={
        {'Conta','Account'},{'Jogos suportados','Supported games'},
        {'Suporte e comunidade','Support and community'},
        {'Controles','Controls'},{'Aparência','Appearance'},
        {'Configurações salvas','Saved configurations'},
        {'Automação','Automation'},{'Interações','Interactions'},
        {'Minimizar painel','Minimize panel'},{'Descarregar hub','Unload hub'},
        {'Mostrar painel de atalhos','Show keybind panel'},
        {'Minimizar','Minimize'},{'Descarregar','Unload'},
        {'Auto quebrar cadeado','Auto break lock'},
    }
    for _,pair in ipairs(captions) do
        replacements[from=='pt-BR' and pair[1] or pair[2]]=to=='pt-BR' and pair[1] or pair[2]
    end
    if not Library or not Library.ScreenGui then return end
    for _,node in ipairs(Library.ScreenGui:GetDescendants()) do
        if node:IsA('TextLabel') or node:IsA('TextButton') then
            local translated=replacements[node.Text]
            if translated then pcall(function()node.Text=translated end)end
        end
    end
end

local rebuildUI
local function buildUI()
    Window=Library:CreateWindow({
        Title='Prime Void Hub',Footer='Grau SP • '..VERSION,
        Center=true,AutoShow=true,Resizable=true,
        Size=UDim2.fromOffset(770,560),
        ToggleKeybind=Enum.KeyCode.Unknown,
        ShowCustomCursor=false,NotifySide='Right',
        MinSidebarWidth=135,EnableCompacting=true,SidebarCompactWidth=48,
        Animations={ToggleWindow=state.animations,TabSwitch=state.animations,
            Groupbox=state.animations,Dropdown=state.animations,KeyPicker=state.animations}
    })
    local home=addTab(tr('home'),'house')
    local vehicles=addTab(tr('vehicles'),'bike')
    local ifood=addTab(tr('delivery'),'map-pin')
    local steal=addTab(tr('steal'),'key-round')
    local visuals=addTab(tr('visuals'),'eye')
    local tp=addTab(tr('travel'),'map')
    local settings=addTab(tr('settings'),'settings')

    local homeAccount=group(home,state.language=='pt-BR' and 'Conta' or 'Account','Left','user-round')
    homeAccount:AddLabel(player.DisplayName..' (@'..player.Name..')',true)
    homeAccount:AddLabel('UserId: '..tostring(player.UserId),true)
    homeAccount:AddLabel('PlaceId: '..tostring(game.PlaceId),true)
    local homeSession=group(home,tr('stats'),'Left','activity')
    ui.homeStatus=homeSession:AddLabel('...')
    ui.homeSpeed=homeSession:AddLabel('...')
    ui.lastStatus=homeSession:AddLabel(state.status,true)
    ui.homeCount=homeSession:AddLabel('...')
    ui.homeVehicle=homeSession:AddLabel('...')
    local homeGames=group(home,state.language=='pt-BR' and 'Jogos suportados' or 'Supported games','Right','gamepad-2')
    homeGames:AddLabel('Ride Storm • HUNTRESS • Steal An Exu',true)
    homeGames:AddLabel("Don't Splash • Destruction Simulator • War Tycoon",true)
    homeGames:AddLabel('Clover Legends • Grau SP • RIVALS • Steal a Brainrot',true)
    local support=group(home,state.language=='pt-BR' and 'Suporte e comunidade' or 'Support and community','Right','message-circle')
    makeButton(support,'Discord',function()
        if type(setclipboard)=='function' then
            local ok=pcall(setclipboard,'https://discord.gg/PD3PeyG8aq')
            reportStatus(ok and 'Discord copiado' or 'Clipboard indisponível')
        else
            reportStatus('Discord: https://discord.gg/PD3PeyG8aq')
        end
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
    local vCleanup=group(vehicles,'Garagem / Garage','Right','trash-2')
    makeButton(vCleanup,tr('delete'),deleteAll)
    makeButton(vCleanup,tr('deleteSlot1'),function()deleteSpecific('livre',1)end)
    makeButton(vCleanup,tr('deleteSlot2'),function()deleteSpecific('livre',2)end)
    makeButton(vCleanup,tr('deleteTrailer'),function()deleteSpecific('carretinha')end)
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

    local stealLeft=group(steal,state.language=='pt-BR' and 'Automação' or 'Automation','Left','key-round')
    stealLeft:AddToggle('PVG_AutoAlarm',{
        Text=state.language=='pt-BR' and 'Auto desativar alarme' or 'Auto disable alarm',
        Default=state.autoAlarm,
        Callback=function(on)state.autoAlarm=on==true;changed()
            if state.autoAlarm and robbery.lastAlarmData then solveAlarm(robbery.lastAlarmData)end
        end,
    })
    stealLeft:AddToggle('PVG_AutoTracker',{
        Text=state.language=='pt-BR' and 'Auto remover rastreador' or 'Auto remove tracker',
        Default=state.autoTracker,
        Callback=function(on)state.autoTracker=on==true;changed()end,
    })
    local stealRight=group(steal,state.language=='pt-BR' and 'Interações' or 'Interactions','Right','wrench')
    makeButton(stealRight,state.language=='pt-BR' and 'Cancelar alarme (F8)' or 'Cancel alarm (F8)',cancelAlarmMinigame)
    makeButton(stealRight,state.language=='pt-BR' and 'Iniciar desativação do alarme' or 'Start disabling alarm',function()
        actionPrompt({'alarme','alicate'},13)
    end)
    makeButton(stealRight,state.language=='pt-BR' and 'Iniciar busca de rastreador' or 'Start tracker search',function()
        actionPrompt({'rastreador','buscar','procurar','busca'},13)
    end)
    stealRight:AddToggle('PVG_AutoLock',{
        Text=state.language=='pt-BR' and 'Auto quebrar cadeado' or 'Auto break lock',
        Default=state.autoLock,
        Callback=function(on)setAutoLock(on)end,
    })
    makeButton(stealRight,state.language=='pt-BR' and 'Quebrar cadeado agora' or 'Break lock now',function()
        attemptLock(true)
    end)
    
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
    local waypointGroup=group(tp,state.language=='pt-BR' and 'Locais salvos' or 'Saved locations','Right','map-pin')
    makeButton(waypointGroup,state.language=='pt-BR' and 'Marcar Batalhão aqui' or 'Mark police station here',function()
        captureWaypoint('PM_Batalhao')
    end)
    makeButton(waypointGroup,state.language=='pt-BR' and 'Marcar loja aqui' or 'Mark shop here',function()
        captureWaypoint('LojaCapacetes')
    end)

    -- Universal AutoSave/AutoExecute, rejoin and shared session policy at upper-left.
    local settingsSession=group(settings,tr('session'),'Left','save')
    local persistence=env.PVH_Persistence
    if type(persistence)=='table' and type(persistence.Bind)=='function' then
        -- Rebind safely if a UI rebuild occurred in an old session.
        if persistence._sessionGroupbox~=settingsSession then persistence.Bound=false end
        local ok,result=pcall(function()return persistence:Bind(settingsSession)end)
        if not ok then log('PERSISTENCE_BIND_ERROR',result) end
    end
    local settingsControls=group(settings,state.language=='pt-BR' and 'Controles' or 'Controls','Left','keyboard')
    env.PVH_SettingsPolish=settingsControls
    local minimizeBtn=makeButton(settingsControls,state.language=='pt-BR' and 'Minimizar painel' or 'Minimize panel',function()
        if Library and type(Library.Toggle)=='function' then pcall(function()Library:Toggle()end)end
    end)
    minimizeBtn:AddKeyPicker('PVG_KeyMinimize',{
        Text=state.language=='pt-BR' and 'Minimizar' or 'Minimize',
        Default=state.minimizeKey,Mode='Press',SyncToggleState=false,
        ChangedCallback=function(key)state.minimizeKey=key and key.Name or 'None';changed()end,
    })
    local unloadBtn=makeButton(settingsControls,state.language=='pt-BR' and 'Descarregar hub' or 'Unload hub',unload)
    unloadBtn:AddKeyPicker('PVG_KeyUnload',{
        Text=state.language=='pt-BR' and 'Descarregar' or 'Unload',
        Default=state.unloadKey,Mode='Press',SyncToggleState=false,
        ChangedCallback=function(key)state.unloadKey=key and key.Name or 'None';changed()end,
    })
    settingsControls:AddToggle('PVG_KeyPanel',{
        Text=state.language=='pt-BR' and 'Mostrar painel de atalhos' or 'Show keybind panel',
        Default=state.showKeybinds,
        Callback=function(on)
            state.showKeybinds=on==true;changed()
            if Library.KeybindFrame then Library.KeybindFrame.Visible=state.showKeybinds end
        end,
    })
    local appearance=group(settings,state.language=='pt-BR' and 'Aparência' or 'Appearance','Left','palette')
    appearance:AddDropdown('PVG_Language',{
        Text=tr('language'),Values={'Português','English'},
        Default=state.language=='pt-BR' and 'Português' or 'English',
        Callback=function(v)
            local nextLang=v=='English' and 'en-US' or 'pt-BR'
            if state.language~=nextLang then
                local oldLang=state.language
                state.language=nextLang;changed()
                if alive then task.defer(function()refreshUILanguage(oldLang,nextLang)end)end
            end
        end,
    })
    appearance:AddToggle('PVG_Animations',{Text=tr('animations'),Default=state.animations,
        Callback=function(v)
            state.animations=v==true;changed()
            if Library and type(Library.Animations)=='table' then
                for key in pairs(Library.Animations) do Library.Animations[key]=state.animations end
            end
        end})
    appearance:AddToggle('PVG_Sounds',{Text=tr('sounds'),Default=state.sounds,
        Callback=function(v)state.sounds=v==true;changed()end})
    local profiles=group(settings,state.language=='pt-BR' and 'Configurações salvas' or 'Saved configurations','Right','folder-cog')
    makeButton(profiles,tr('save'),function()
        reportStatus(saveConfig() and tr('saved') or tr('noStorage'))
    end)
    makeButton(profiles,tr('reload'),function()
        if loadConfig() then reportStatus(state.language=='pt-BR' and
            'Configuração lida; reinicie o hub para aplicar todos os controles.' or
            'Config loaded; restart hub to update all controls.')
        else reportStatus(tr('notReady'))end
    end)
    makeButton(profiles,tr('reset'),function()
        local ok=type(isfile)=='function' and type(delfile)=='function'
        if ok then ok=pcall(function()if isfile(CONFIG_PATH)then delfile(CONFIG_PATH)end end)end
        reportStatus(ok and (state.language=='pt-BR' and 'Configuração apagada' or 'Configuration deleted') or tr('noStorage'))
    end)
    if Library.KeybindFrame then Library.KeybindFrame.Visible=state.showKeybinds end

    if type(Library.OnUnload)=='function' then pcall(function()Library:OnUnload(unload)end)end
    updateCategoryOptions()
end

-- Recreate the Obsidian window after a language change, preserving runtime state.
-- No extra loader, ScreenGui or duplicated physics listeners remain alive.
rebuildUI=function()
    if runtime.rebuilding or not alive then return end
    runtime.rebuilding=true
    if Library and not Library.Unloaded then
        pcall(function()Library:Unload()end)
    end
    local okNew,newLibrary=pcall(loadObsidianLibrary)
    if not okNew or type(newLibrary)~='table' or type(newLibrary.CreateWindow)~='function' then
        runtime.rebuilding=false
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
    runtime.rebuilding=false
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
        discoverNearbyWaypoints()
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
            pcall(function()ui.homeSpeed:SetText('Vehicle: '..(mdl and mdl.Name or '-')..' | '..math.floor(runtime.liveSpeed*1.008+0.5)..' km/h')end)
        end
        if ui.policeSpeed then
            pcall(function()ui.policeSpeed:SetText('Velocidade: '..math.floor(runtime.liveSpeed*1.008+0.5)..' km/h (local)')end)
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
log('BOOT',string.format('Grau SP %s | Obsidian ready | checker=%d/%d | cars=%d',
    VERSION,passed,total,#state.vehicles))

-- Continuous bounded workspace logs; explicit flush on unload.
task.spawn(function()
    while alive do
        writeSession(true)
        task.wait(2)
    end
end)
