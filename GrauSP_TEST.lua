-- Prime Void Hub | GRAU SP | TEST v0.3.2
-- PlaceId: 101953291486308
-- Native Obsidian UI; recovered legacy Rustcc catalog preserved.
-- New features are based on documented client interfaces in the supplied .rbxl.
-- All game-server actions are REQUESTS; neither acceptance nor entitlement is forged.
-- TEST universal loader only; never published on main branch.

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

local VERSION='0.3.2-test'
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
    selectedCategory='Motos_Gratis',selectedVehicle=nil,search='',
    categories={},vehicles={},byCategory={},catalogSource='none',
    spawns=0,deletes=0,regions=0,orders=0,errors=0,
    raceMode=false,cornerBrake=true,drift=false,grip=false,wheelieAssist=false,
    boostPower=48,cornerMaxSpeed=76,brakePower=6,
    boostHeld=false,brakeHeld=false,wheelieHeld=false,
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
local collisionOriginal={}
local ghostVehicle=nil
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
        state.ghostParts,state.ramTouches,state.ramSuccess,tostring(state.ifoodOpen))
end

local STR={
 ['pt-BR']={
  home='Início',vehicles='Veículos',race='Modo Corrida',delivery='iFood',police='PM',visuals='Visuais',
  travel='Teleportes',settings='Configurações',about='Sobre',
  welcome='Prime Void Hub • GRAU SP',
  hint='Seleção nativa de veículos e ferramentas de RP. Os limites e permissões são validados pelo servidor.',
  stats='Estado da sessão',catalog='Catálogo de veículos',filter='Categoria',vehicle='Veículo',
  search='Buscar veículo',searchPH='Digite parte do nome',refresh='Atualizar catálogo',
  spawn='Spawnar veículo',favorite='Favoritar veículo',unfavorite='Desfavoritar veículo',delete='Remover todos os veículos',confirmDelete='CONFIRMAR remoção (4s)',
  deleteSlot1='Remover veículo 1',deleteSlot2='Remover veículo 2',deleteTrailer='Remover carretinha',
  preview='Prévia',native='Origem: catálogo nativo',unknown='Não confirmado pelo servidor',
  raceMode='Modo Corrida',cornerBrake='Frenagem automática nas curvas',
  drift='Modo Drift (aderência reduzida)',grip='Aderência reforçada',
  wheelie='Assistência de grau (estabilidade lateral)',
  ghost='Ghost Mode (sem colisão local)',espPlayers='ESP Jogadores',espVehicles='ESP Veículos',
  pmRam='Impacto PM (experimental: autoridade física)',pmVehicles='Viatura para spawn',
  pmSpawn='Spawnar viatura',raceDebug='Estado real da física',
  logExport='Salvar logs TXT',logInfo='Logs e Checker são gerados automaticamente na workspace.',
  boostPower='Força do Boost',cornerLimit='Velocidade-alvo nas curvas (stud/s)',brakePower='Força do Super Brake',
  raceGuide='Enquanto estiver dirigindo: Shift = Boost; B = Super Brake; X = estabilizar grau. Funções físicas são experimentais.',
  raceStatus='Sem veículo controlado',driveMode='Assistências',
  ifoodHelp='Fluxo nativo: localizar pedido → coletar com prompt → entregar → informar o código. Sem completar pedidos artificialmente.',
  equipPhone='Equipar telefone',openDelivery='Abrir aplicativo iFood',
  findOrder='Localizar pedido',clearGPS='Limpar marcador GPS',ifoodLong='Preferir entregas distantes',cancelOrder='Cancelar rota atual',
  ifoodStatus='Aguardando pedido',gps='GPS de entrega',
  policeHelp='Ferramentas de RP policial. A source NÃO revela um comando verificado para se tornar PM automaticamente.',
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
  credits='Prime Void Hub • Grau SP  |  TEST v0.3.2',
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
  spawn='Spawn vehicle',favorite='Add to favorites',unfavorite='Remove favorite',delete='Delete all vehicles',confirmDelete='CONFIRM delete (4s)',
  deleteSlot1='Delete vehicle 1',deleteSlot2='Delete vehicle 2',deleteTrailer='Delete trailer',
  preview='Preview',native='Source: native catalog',unknown='Not server-confirmed',
  raceMode='Race Mode',cornerBrake='Automatic corner braking',
  drift='Drift mode (reduced traction)',grip='Enhanced grip',
  wheelie='Wheelie assist (lateral stability)',
  ghost='Ghost Mode (local collision off)',espPlayers='Player ESP',espVehicles='Vehicle ESP',
  pmRam='Police impact (experimental: physics authority)',pmVehicles='Police car to spawn',
  pmSpawn='Spawn police vehicle',raceDebug='Actual physics status',
  logExport='Save log TXT',logInfo='Session logs and Checker export automatically to workspace.',
  boostPower='Boost strength',cornerLimit='Corner target speed (stud/s)',brakePower='Super Brake strength',
  raceGuide='While driving: Shift = Boost; B = Super Brake; X = stabilize wheelie. Physics controls are experimental.',
  raceStatus='No controlled vehicle',driveMode='Assists',
  ifoodHelp='Native flow: find order → collect at prompt → deliver → enter code. No artificial mission completion.',
  equipPhone='Equip phone',openDelivery='Open iFood app',
  findOrder='Find an order',clearGPS='Clear GPS marker',ifoodLong='Prefer distant deliveries',cancelOrder='Cancel current route',
  ifoodStatus='Waiting for order',gps='Delivery GPS',
  policeHelp='Police RP tools. The client dump contains NO verified remote to join the police team automatically.',
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
  credits='Prime Void Hub • Grau SP  |  TEST v0.3.2',
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
            animations=state.animations,sounds=state.sounds,
            raceMode=state.raceMode,cornerBrake=state.cornerBrake,
            ghost=state.ghost,espPlayers=state.espPlayers,espVehicles=state.espVehicles,pmRam=state.pmRam,
            drift=state.drift,grip=state.grip,wheelieAssist=state.wheelieAssist,
            boostPower=state.boostPower,cornerMaxSpeed=state.cornerMaxSpeed,
            brakePower=state.brakePower,selectedCategory=state.selectedCategory}))
    end)
end
local function loadConfig()
    if type(isfile)~='function' or type(readfile)~='function' then return false end
    local ok,data=pcall(function()
        if isfile(CONFIG_PATH) then return HttpService:JSONDecode(readfile(CONFIG_PATH)) end
    end)
    if not ok or type(data)~='table' then return false end
    for _,k in ipairs({'autoSave','animations','sounds','raceMode','cornerBrake','drift','grip','wheelieAssist','ifoodLongDistance','ghost','espPlayers','espVehicles','pmRam'}) do
        if type(data[k])=='boolean' then state[k]=data[k] end
    end
    for _,k in ipairs({'boostPower','cornerMaxSpeed','brakePower'}) do
        if type(data[k])=='number' and data[k]==data[k] then state[k]=data[k] end
    end
    state.boostPower=math.clamp(state.boostPower,5,80)
    state.cornerMaxSpeed=math.clamp(state.cornerMaxSpeed,20,160)
    state.brakePower=math.clamp(state.brakePower,2,15)
    if data.language=='pt-BR' or data.language=='en-US' then state.language=data.language end
    if type(data.selectedCategory)=='string' then state.selectedCategory=data.selectedCategory end
    if state.drift and state.grip then state.grip=false end
    return true
end
loadConfig()
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
    state.categories=categories
    state.vehicles=flat
    state.catalogSource=origin
    if not byCategory[state.selectedCategory] then
        state.selectedCategory=byCategory.Motos_Gratis and 'Motos_Gratis' or categories[1]
    end
    log('CATALOG',string.format('source=%s categories=%d vehicles=%d',origin,#categories,total))
    return #categories>0
end
local function filteredVehicles()
    local items=state.byCategory[state.selectedCategory] or {}
    local values={}
    local needle=(state.search or ''):lower()
    for _,v in ipairs(items) do
        if needle=='' or v.name:lower():find(needle,1,true) then values[#values+1]=v.name end
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
    if os.clock()>pendingDeleteUntil then
        pendingDeleteUntil=os.clock()+4
        reportStatus(tr('removeWarning'))
        return
    end
    pendingDeleteUntil=0
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
local function changeRegion(destination)
    if not limitCall('region',1.5) then return end
    if fire('SpawnSelect',destination) then
        state.regions=state.regions+1
        reportStatus(tr('requested')..' • '..destination)
    end
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
        local friction=state.drift and 0.35 or 1.65
        pcall(function()
            wheel.CustomPhysicalProperties=PhysicalProperties.new(
                math.clamp(data.Density,0.01,100),friction,
                math.clamp(data.Elasticity,0,1),100,100)
        end)
    end
end
local function restoreGhost()
    for part,was in pairs(collisionOriginal) do
        if typeof(part)=='Instance' and part.Parent then
            pcall(function()part.CanCollide=was end)
        end
    end
    table.clear(collisionOriginal)
    ghostVehicle=nil
    state.ghostParts=0
end
local function updateGhost(model)
    if not state.ghost or not model then
        if ghostVehicle then restoreGhost()end
        return
    end
    if ghostVehicle~=model then restoreGhost();ghostVehicle=model;lastGhostRefresh=0 end
    if os.clock()-lastGhostRefresh<0.33 then return end
    lastGhostRefresh=os.clock()
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA('BasePart') then
            if collisionOriginal[part]==nil then collisionOriginal[part]=part.CanCollide end
            if part.CanCollide then pcall(function()part.CanCollide=false end)end
        end
    end
    local n=0
    for _ in pairs(collisionOriginal) do n=n+1 end
    state.ghostParts=n
end
local function clearRam()
    for _,c in ipairs(ramConnections) do pcall(function()c:Disconnect()end)end
    table.clear(ramConnections)
    ramVehicle=nil
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
local function raceTick(dt)
    local model,seat=getVehicle()
    if not model then
        if wheelVehicle then restoreWheels()end
        if ghostVehicle then restoreGhost()end
        if ramVehicle then clearRam()end
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
    if state.ghost then updateGhost(model) elseif ghostVehicle then restoreGhost()end
    if state.pmRam and not state.ghost then setRamVehicle(model,seat)
    elseif ramVehicle then clearRam()end
    if not state.raceMode then
        if wheelVehicle then restoreWheels()end
        return
    end
    state.raceTicks=state.raceTicks+1
    local style=(state.drift and 'drift') or (state.grip and 'grip') or 'normal'
    if style=='normal' then
        if wheelVehicle then restoreWheels()end
    elseif model~=wheelVehicle or style~=lastWheelStyle then
        setWheelMode(model)
    end
    lastWheelStyle=style
    -- Fail visibly: local ownership is not the same as server acceptance.
    if owner==false then
        state.raceDenied=state.raceDenied+1
        if os.clock()-lastRaceProbe>5 then
            lastRaceProbe=os.clock()
            log('RACE_BLOCKED','Assembly physics not owned: '..reason)
        end
        return
    end
    local v=assembly.AssemblyLinearVelocity
    local speed=v.Magnitude
    local attempted=false
    if state.brakeHeld and speed>1 then
        local damp=math.max(0,1-state.brakePower*dt)
        attempted=true
        pcall(function()assembly.AssemblyLinearVelocity=v*damp end)
    elseif state.boostHeld then
        local forward=seat.CFrame.LookVector
        if speed<180 then
            attempted=true
            pcall(function()
                local add=forward*(state.boostPower*dt*2.5)
                assembly.AssemblyLinearVelocity=v+add
            end)
        end
    elseif state.cornerBrake and seat:IsA('VehicleSeat')
        and math.abs(seat.SteerFloat)>=0.5 and speed>state.cornerMaxSpeed then
        attempted=true
        pcall(function()assembly.AssemblyLinearVelocity=v*math.max(0.65,1-3*dt)end)
    end
    if state.wheelieAssist and state.wheelieHeld then
        attempted=true
        local w=assembly.AssemblyAngularVelocity
        local axis=seat.CFrame.LookVector
        pcall(function()
            assembly.AssemblyAngularVelocity=w-axis*w:Dot(axis)*math.min(0.75,dt*5)
        end)
    end
    if attempted then
        state.raceApplied=state.raceApplied+1
        if os.clock()-lastRaceProbe>3 then
            lastRaceProbe=os.clock()
            log('RACE_INPUT',string.format('speed=%.1f boost=%s brake=%s wheelie=%s ownership=%s',
                speed,tostring(state.boostHeld),tostring(state.brakeHeld),
                tostring(state.wheelieHeld),reason))
        end
    end
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
    if input.KeyCode==Enum.KeyCode.LeftShift then state.boostHeld=true end
    if input.KeyCode==Enum.KeyCode.B then state.brakeHeld=true end
    if input.KeyCode==Enum.KeyCode.X then state.wheelieHeld=true end
end)
track(UserInputService.InputEnded,function(input)
    if input.KeyCode==Enum.KeyCode.LeftShift then state.boostHeld=false end
    if input.KeyCode==Enum.KeyCode.B then state.brakeHeld=false end
    if input.KeyCode==Enum.KeyCode.X then state.wheelieHeld=false end
end)

-- Real client-side ESP, includes creation, update and cleanup.
local function clearESP()
    for model,hi in pairs(espHighlights) do
        if typeof(hi)=='Instance' then pcall(function()hi:Destroy()end)end
        espHighlights[model]=nil
    end
end
local function addESP(model,color)
    if not model or not model.Parent then return end
    if espHighlights[model] and espHighlights[model].Parent then return end
    local h=Instance.new('Highlight')
    h.Name='PVH_GrauSP_ESP'
    h.Adornee=model
    h.FillColor=color
    h.OutlineColor=color
    h.FillTransparency=0.82
    h.OutlineTransparency=0
    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent=model
    espHighlights[model]=h
end
local function refreshESP()
    local wanted={}
    if state.espPlayers then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=player and p.Character and p.Character.Parent then
                wanted[p.Character]=Color3.fromRGB(255,175,60)
            end
        end
    end
    if state.espVehicles then
        local count=0
        for _,v in ipairs(workspace:GetChildren()) do
            if count>=80 then break end
            if v:IsA('Model') and v:FindFirstChild('Wheels',true)
                and v~=select(1,getVehicle()) then
                local seat=v:FindFirstChild('DriveSeat',true)
                    or v:FindFirstChildWhichIsA('VehicleSeat',true)
                if seat then
                    count=count+1
                    wanted[v]=Color3.fromRGB(110,180,255)
                end
            end
        end
    end
    for model,hi in pairs(espHighlights) do
        if not wanted[model] or not model.Parent then
            pcall(function()hi:Destroy()end);espHighlights[model]=nil
        end
    end
    for model,color in pairs(wanted) do addESP(model,color)end
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
local cancelUntil=0
local function cancelIfuudOrder()
    if os.clock()>cancelUntil then
        cancelUntil=os.clock()+4
        reportStatus('iFood: confirm cancel by clicking again within 4s')
        return
    end
    cancelUntil=0
    if fire('IfuudEvent','ResetarMissao') then
        clearGps()
        state.ifoodStage='idle'
        reportStatus('iFood: '..tr('requested')..' • ResetarMissao')
    end
end
local ifuudRemote=remote('IfuudEvent')
if ifuudRemote then
    track(ifuudRemote.OnClientEvent,function(event,argument)
        if not alive then return end
        if event=='AtivarGPS' then
            local conf=getIfuudCoordinates()
            local data=conf and conf.Locais and conf.Locais[argument]
            if data then setGps(data,argument);state.ifoodStage='pickup' end
        elseif event=='PedidoColetado' then
            local conf=getIfuudCoordinates()
            local data=conf and conf.Entrega and conf.Entrega[argument]
            if data then setGps(data,argument);state.ifoodStage='delivery' end
        elseif event=='EntregaConcluida' then
            clearGps();state.ifoodStage='done'
        elseif event=='AtivarPromptEntrega' then state.ifoodStage='arrival'
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
                if distance<250 then
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
    reportStatus(#entries>0 and table.concat(entries,' | ') or 'No players within 250 studs')
end

task.spawn(function()
    while alive do
        local ok,err=pcall(refreshESP)
        if not ok then log('ESP_ERROR',err) end
        task.wait(1.5)
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
    state.boostHeld=false;state.brakeHeld=false;state.wheelieHeld=false
    pcall(restoreWheels);pcall(restoreGhost);pcall(clearRam);pcall(clearESP);pcall(clearGps)
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
    alive=false
    state.boostHeld=false;state.brakeHeld=false;state.wheelieHeld=false
    restoreWheels()
    restoreGhost()
    clearRam()
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
    checks[#checks+1]=not state.raceMode
        and skip('RACE','Race control applied','race mode OFF')
        or (state.raceApplied>0
            and unknown('RACE','Race control server effect',
                'Local attempts='..state.raceApplied..'; server effect not measured')
            or unknown('RACE','Race control activation',
                'No local input detected; press Boost/Brake while driving'))
    checks[#checks+1]=not state.ghost
        and skip('GHOST','Ghost collision change','ghost OFF')
        or value(state.ghostParts>0,'GHOST','Collision parts modified locally',
            tostring(state.ghostParts))
    local playerCount=0
    for _,p in ipairs(Players:GetPlayers())do if p~=player then playerCount=playerCount+1 end end
    checks[#checks+1]=not state.espPlayers
        and skip('ESP','Player highlights','player ESP OFF')
        or (playerCount==0 and skip('ESP','Player highlights','no other players')
        or unknown('ESP','Player ESP visibility','visually confirm client highlights'))
    checks[#checks+1]=not state.espVehicles
        and skip('ESP','Vehicle highlights','vehicle ESP OFF')
        or unknown('ESP','Vehicle ESP visibility','visually confirm vehicle highlights')
    checks[#checks+1]=value(#getPoliceOptions()>0,'PM','Police vehicle catalog available',
        tostring(#getPoliceOptions()))
    checks[#checks+1]=not state.pmRam
        and skip('PM','Police impact mode','impact OFF')
        or unknown('PM','Police knockdown effect',
            'contacts='..state.ramTouches..' local impulses='..state.ramSuccess..
            '; server result not verifiable from client')
    local counts={PASS=0,FAIL=0,SKIP=0,UNVERIFIED=0}
    local lines={
        'PRIME VOID HUB | GRAU SP | DIAGNOSTICO | '..VERSION,
        'PlaceId='..tostring(game.PlaceId)..' JobId='..tostring(game.JobId),
        'Captured='..os.date('!%Y-%m-%d %H:%M:%S UTC'),
        'Catalog='..tostring(state.catalogSource)..' Vehicles='..#state.vehicles,
        'Requests: spawn='..state.spawns..' delete='..state.deletes..' regions='..state.regions..' orders='..state.orders,
        'Physics: '..diagnosticSnapshot(),
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
local categoryControl,vehicleControl,previewControl,vehicleCountLabel
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
updateCarOptions=function()
    local available=catalogOptions()
    if vehicleControl and type(vehicleControl.SetValues)=='function' then
        pcall(function()vehicleControl:SetValues(available)end)
    end
    local exists=false
    for _,name in ipairs(available) do
        if name==state.selectedVehicle then exists=true;break end
    end
    if not exists then state.selectedVehicle=available[1] end
    if vehicleControl and state.selectedVehicle then
        pcall(function()vehicleControl:SetValue(state.selectedVehicle)end)
    end
    updatePreview()
end
local function updateCategoryOptions()
    if categoryControl and type(categoryControl.SetValues)=='function' then
        pcall(function()categoryControl:SetValues(state.categories)end)
    end
    if categoryControl and state.selectedCategory then
        pcall(function()categoryControl:SetValue(state.selectedCategory)end)
    end
    updateCarOptions()
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

local pmSelection=nil
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
    local race=addTab(tr('race'),'flag-triangle-right')
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
    categoryControl=vLeft:AddDropdown('PVG_VehicleCategory',{
        Text=tr('filter'),Values=state.categories,
        Default=state.selectedCategory,AllowNull=false,
        Callback=function(value)
            if not alive then return end
            state.selectedCategory=tostring(value)
            state.selectedVehicle=nil
            updateCarOptions()
            changed()
        end,
    })
    vLeft:AddInput('PVG_VehicleSearch',{
        Text=tr('search'),Default='',Placeholder=tr('searchPH'),
        Finished=false,ClearTextOnFocus=false,
        Callback=function(value)
            if not alive then return end
            state.search=tostring(value or '')
            updateCarOptions()
        end,
    })
    vehicleControl=vLeft:AddDropdown('PVG_VehicleList',{
        Text=tr('vehicle'),Values=catalogOptions(),
        Default=state.selectedVehicle,AllowNull=true,
        Callback=function(value)
            state.selectedVehicle=type(value)=='string' and value or nil
            updatePreview()
        end,
    })
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

    local rLeft=group(race,tr('driveMode'),'Left','gauge')
    rLeft:AddToggle('PVG_Race',{Text=tr('raceMode'),Default=state.raceMode,
        Callback=function(value)
            state.raceMode=value==true
            if not state.raceMode then restoreWheels() end
            changed()
        end})
    rLeft:AddToggle('PVG_CornerBrake',{Text=tr('cornerBrake'),Default=state.cornerBrake,
        Callback=function(v)state.cornerBrake=v==true;changed()end})
    rLeft:AddToggle('PVG_Grip',{Text=tr('grip'),Default=state.grip,
        Callback=function(v)
            state.grip=v==true
            if state.grip then
                state.drift=false
                local t=Library.Toggles and Library.Toggles.PVG_Drift
                if t and t.Value then pcall(function()t:SetValue(false)end)end
            end
            lastWheelStyle='';restoreWheels();changed()
        end})
    rLeft:AddToggle('PVG_Drift',{Text=tr('drift'),Default=state.drift,
        Callback=function(v)
            state.drift=v==true
            if state.drift then
                state.grip=false
                local t=Library.Toggles and Library.Toggles.PVG_Grip
                if t and t.Value then pcall(function()t:SetValue(false)end)end
            end
            lastWheelStyle='';restoreWheels();changed()
        end})
    rLeft:AddToggle('PVG_Wheelie',{Text=tr('wheelie'),Default=state.wheelieAssist,
        Callback=function(v)state.wheelieAssist=v==true;changed()end})
    rLeft:AddToggle('PVG_Ghost',{Text=tr('ghost'),Default=state.ghost,
        Callback=function(v)
            state.ghost=v==true
            if not state.ghost then restoreGhost()end
            if state.ghost and state.pmRam then
                state.pmRam=false
                local t=Library.Toggles and Library.Toggles.PVG_PMRam
                if t and t.Value then pcall(function()t:SetValue(false)end)end
            end
            log('GHOST',tostring(state.ghost));changed()
        end})
    ui.raceDiagnostics=rLeft:AddLabel(tr('raceDebug')..': --',true)

    local rRight=group(race,'Boost • Brake • Grau','Right','zap')
    rRight:AddSlider('PVG_BoostPower',{Text=tr('boostPower'),Default=state.boostPower,Min=5,Max=80,Rounding=0,
        Callback=function(value)state.boostPower=value;changed()end})
    rRight:AddSlider('PVG_CornerLimit',{Text=tr('cornerLimit'),Default=state.cornerMaxSpeed,Min=20,Max=160,Rounding=0,
        Callback=function(value)state.cornerMaxSpeed=value;changed()end})
    rRight:AddSlider('PVG_BrakePower',{Text=tr('brakePower'),Default=state.brakePower,Min=2,Max=15,Rounding=0,
        Callback=function(value)state.brakePower=value;changed()end})
    rRight:AddLabel(tr('raceGuide'),true)
    rRight:AddLabel('Ghost/Race: depends on vehicle network ownership. See Checker and session log.',true)
    makeButton(rRight,'Boost (1 s)',function()
        state.boostHeld=true
        task.delay(1,function()state.boostHeld=false end)
    end)
    makeButton(rRight,'Super Brake (1 s)',function()
        state.brakeHeld=true
        task.delay(1,function()state.brakeHeld=false end)
    end)

    local iLeft=group(ifood,tr('delivery'),'Left','package-check')
    iLeft:AddLabel(tr('ifoodHelp'),true)
    makeButton(iLeft,tr('equipPhone'),equipPhone)
    makeButton(iLeft,tr('openDelivery'),openIfuud)
    makeButton(iLeft,tr('findOrder'),requestIfuudOrder)
    iLeft:AddToggle('PVG_IFoodLong',{
        Text=tr('ifoodLong'),Default=state.ifoodLongDistance,
        Callback=function(on)requestIfuudPreference(on)end,
    })
    makeButton(iLeft,tr('cancelOrder'),cancelIfuudOrder)
    makeButton(iLeft,tr('clearGPS'),function()
        clearGps();state.ifoodStage='idle';reportStatus(tr('gpsNone'))
    end)
    local iRight=group(ifood,tr('gps'),'Right','navigation')
    ui.ifoodStage=iRight:AddLabel(tr('ifoodStatus'),true)
    ui.ifoodDistance=iRight:AddLabel(tr('gpsNone'),true)
    iRight:AddLabel('IfuudEvent: AtivarGPS / PedidoColetado / EntregaConcluida',true)
    iRight:AddLabel(tr('unknown'),true)

    local pLeft=group(police,tr('police'),'Left','shield-check')
    pLeft:AddLabel(tr('policeHelp'),true)
    local pmOpts=getPoliceOptions()
    pmSelection=pmSelection or pmOpts[1]
    if #pmOpts>0 then
        pLeft:AddDropdown('PVG_PMSelect',{
            Text=tr('pmVehicles'),Values=pmOpts,Default=pmSelection,AllowNull=true,
            Callback=function(v)pmSelection=v end,
        })
        makeButton(pLeft,tr('pmSpawn'),spawnPM)
    else
        pLeft:AddLabel('Viaturas indisponíveis no catálogo atual.',true)
    end
    makeButton(pLeft,tr('policeCars'),policeCategory)
    makeButton(pLeft,tr('nearPlayers'),listNearby)
    pLeft:AddLabel(tr('noRole'),true)
    local pRight=group(police,'ESP / RP','Right','scan-eye')
    pRight:AddToggle('PVG_PMRam',{Text=tr('pmRam'),Default=state.pmRam,
        Callback=function(v)
            state.pmRam=v==true
            if state.pmRam and state.ghost then
                state.ghost=false
                local t=Library.Toggles and Library.Toggles.PVG_Ghost
                if t and t.Value then pcall(function()t:SetValue(false)end)end
                restoreGhost()
            end
            if not state.pmRam then clearRam()end
            log('PM_RAM',tostring(state.pmRam)..' (requires target physics authority)')
            changed()
        end})
    ui.policeSpeed=pRight:AddLabel('Radar: --')
    pRight:AddLabel('PM impact only applies on valid contact with physics authority. See session TXT.',true)
    pRight:AddLabel(tr('policeStatus'),true)

    local espLeft=group(visuals,tr('visuals'),'Left','scan-eye')
    espLeft:AddToggle('PVG_ESPPlayers',{Text=tr('espPlayers'),Default=state.espPlayers,
        Callback=function(v)state.espPlayers=v==true;refreshESP();log('ESP_PLAYERS',tostring(v));changed()end})
    espLeft:AddToggle('PVG_ESPVehicles',{Text=tr('espVehicles'),Default=state.espVehicles,
        Callback=function(v)state.espVehicles=v==true;refreshESP();log('ESP_VEHICLES',tostring(v));changed()end})
    espLeft:AddLabel('ESP is client-side: player highlights and nearby vehicle outlines.',true)
    local espRight=group(visuals,'Visual Status','Right','activity')
    ui.espState=espRight:AddLabel('ESP: off',true)

    local tLeft=group(tp,tr('spawnRegions'),'Left','map-pinned')
    makeButton(tLeft,tr('sao'),function()changeRegion('SaoLuis_Spawn')end)
    makeButton(tLeft,tr('guaruja'),function()changeRegion('Guaruja_Spawn')end)
    makeButton(tLeft,tr('vidigal'),function()changeRegion('Vidigal_Spawn')end)
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
    categoryControl=nil;vehicleControl=nil;previewControl=nil;vehicleCountLabel=nil
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
        if ui.homeCount then
            pcall(function()ui.homeCount:SetText(tr('vehicle')..': '..#state.vehicles..' | '..tr('filter')..': '..#state.categories)end)
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
            pcall(function()ui.policeSpeed:SetText('Radar: '..math.floor(liveSpeed*1.008+0.5)..' km/h (local)')end)
        end
        if ui.espState then
            local n=0;for _ in pairs(espHighlights)do n=n+1 end
            pcall(function()ui.espState:SetText('ESP: '..n..' highlighted objects')end)
        end
        if ui.raceDiagnostics then
            pcall(function()ui.raceDiagnostics:SetText('Seat: '..tostring(state.vehicleReason)..
                ' | Physics: '..tostring(state.physicsReason)..' | Local attempts: '..state.raceApplied)
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
