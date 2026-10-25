-- Prime Void Hub | Universal Loader
local placeId=tonumber(game.PlaceId) or 0
local universeId=tonumber(game.GameId) or 0
local ports={
    {
        name='Storm Suite',
        placeIds={[12593620250]=true},
        universeIds={[4420562665]=true},
        url='https://prime-void-hub-storm-gateway.vercel.app/prime-void-hub.lua',
        markers={'SOURCE GITHUB v','local function setupInterfaceAndLoops()','Prime Void Hub - Storm Suite'},
    },
    {
        name='Exu Security Lab',
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
local chunk,compileError=loadstring(source)
if not chunk then
    error('[Prime Void Hub] Erro ao compilar '..selected.name..': '..tostring(compileError),0)
end
local success,runtimeError=pcall(chunk)
if not success then
    error('[Prime Void Hub] Erro em '..selected.name..': '..tostring(runtimeError),0)
end
