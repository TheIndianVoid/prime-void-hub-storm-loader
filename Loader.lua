-- Prime Void Hub - Storm Suite | Public Vercel Gateway Loader
-- The private source is fetched and checked using version-independent markers.
local URL = 'https://prime-void-hub-storm-gateway.vercel.app/prime-void-hub.lua'
local genv = type(getgenv)=='function' and getgenv() or _G
genv.RSBK_LoaderBuild = 'Vercel gateway (stable)'

local ok, source = pcall(function()
    return game:HttpGet(URL .. '?t=' .. tostring(os.time()))
end)
if not ok or type(source)~='string' then
    error('[Prime Void Hub] Failed to download Storm Suite: '..tostring(source), 0)
end

-- Check the stable source signature instead of a hardcoded version.
-- HTML errors or gateway redirects should never be executed as Luau.
if not source:find('SOURCE GITHUB v',1,true)
    or not source:find('local function setupInterfaceAndLoops()',1,true)
    or not source:find('Prime Void Hub - Storm Suite',1,true) then
    error('[Prime Void Hub] Gateway returned unexpected content; source not executed. '..'Bytes: '..tostring(#source),0)
end

local runner, compileError = loadstring(source)
if not runner then
    error('[Prime Void Hub] Storm Suite compilation error: '..tostring(compileError),0)
end
local success, runtimeError = pcall(runner)
if not success then
    error('[Prime Void Hub] Storm Suite runtime error: '..tostring(runtimeError),0)
end
