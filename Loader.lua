-- Prime Void Hub - Storm Suite v9.0.2
-- Loader publico: baixa a source da hospedagem dedicada.
local endpoint = 'https://prime-void-hub-storm-gateway.vercel.app/prime-void-hub.lua'
local ok, response = pcall(function()
    return game:HttpGet(endpoint .. '?v=' .. tostring(os.time()))
end)
if not ok or type(response) ~= 'string' or #response < 120000
    or not response:find("setupInterfaceAndLoops()", 1, true) then
    error('Prime Void Hub - Storm Suite: falha ao obter a source v9.0.2. Verifique o endpoint.', 0)
end
local fn, parseError = loadstring(response)
if not fn then
    error('Prime Void Hub - Storm Suite: codigo Luau invalido: ' .. tostring(parseError), 0)
end
return fn()
