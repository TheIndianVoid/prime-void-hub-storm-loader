-- Prime Void Hub - Storm Suite v9.0.3 | Vercel gateway
-- Loader publico: source mantida no repositorio privado do GitHub.
local URL = 'https://prime-void-hub-storm-gateway.vercel.app/prime-void-hub.lua'
local genv = type(getgenv) == 'function' and getgenv() or _G
genv.RSBK_LoaderBuild = 'Vercel gateway v9.0.3'
local ok, source = pcall(function()
    return game:HttpGet(URL .. '?v=9.0.3&t=' .. tostring(os.time()))
end)
if not ok or type(source) ~= 'string' then
    error('[Prime Void Hub] Falha ao baixar a Storm Suite: ' .. tostring(source), 0)
end
if not source:find('SOURCE GITHUB v9.0.3', 1, true) or not source:find('setupInterfaceAndLoops()', 1, true) then
    error('[Prime Void Hub] Gateway retornou conteudo inesperado; source nao executada.', 0)
end
local run, err = loadstring(source)
if not run then error('[Prime Void Hub] Erro ao compilar Storm Suite: ' .. tostring(err), 0) end
run()
