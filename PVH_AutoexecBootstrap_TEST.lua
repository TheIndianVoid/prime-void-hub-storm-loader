-- Prime Void Hub | Minimal teleport bootstrap TEST v4
-- Loaded by a tiny queue_on_teleport payload; keep this separate from the port.
local HttpService = game:GetService("HttpService")
local env = (type(getgenv) == "function" and getgenv()) or _G
local LOADER_URL = "https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/refs/heads/test/all-obfuscated-sources/Loader_Obfuscated_TEST.lua"

local function userPrefersOff(path)
    if type(path) ~= "string" or path == "" then return false end
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return false end
    local ok, data = pcall(function()
        if not isfile(path) then return nil end
        return HttpService:JSONDecode(readfile(path))
    end)
    return ok and type(data) == "table" and data.autoExec == false
end

return function(originPort, originUniverse, prefsPath)
    local port = tostring(originPort or "")
    local universe = tonumber(originUniverse) or 0
    warn("[PVH Autoexec v3] PAYLOAD RECEIVED | origin=" .. port
        .. " | currentPlace=" .. tostring(game.PlaceId)
        .. " | currentUniverse=" .. tostring(game.GameId))

    -- A user who switches Autoexec OFF after queuing must not be ignored
    -- when settings or the executor's process state survive the teleport.
    if env.PVH_AutoexecExplicitlyDisabled == true or userPrefersOff(prefsPath) then
        warn("[PVH Autoexec v3] CANCELED | Autoexec switched OFF")
        return
    end

    -- Follow the original port across matchmaking and same-universe subplaces.
    -- The loader itself checks whether the target is supported.
    env.PVH_AutoexecCarry = {
        port = port,
        originUniverse = universe,
        autoexec = true,
    }

    if not game:IsLoaded() then
        local ready = false
        local connection = game.Loaded:Connect(function() ready = true end)
        local started = os.clock()
        while not ready and not game:IsLoaded() and os.clock()-started < 30 do
            task.wait(0.2)
        end
        connection:Disconnect()
    end

    local placeId = tonumber(game.PlaceId) or 0
    local worldKey = tostring(placeId) .. ":" .. tostring(game.JobId)
    local elapsed = type(env.PVH_AutoexecBootTime) == "number"
        and (os.clock() - env.PVH_AutoexecBootTime) or nil
    -- Even a rejoin to the *same* JobId is a new Roblox DataModel.
    -- Do not mistake it for an old payload when executor globals survive.
    if env.PVH_AutoexecBootGame == game and env.PVH_AutoexecBootWorld == worldKey
        and type(elapsed) == "number" and elapsed >= 0 and elapsed < 3 then
        warn("[PVH Autoexec v3] Duplicate bootstrap in this session ignored")
        return
    end
    env.PVH_AutoexecBootWorld = worldKey
    env.PVH_AutoexecBootGame = game
    env.PVH_AutoexecBootTime = os.clock()

    local lastError
    for attempt=1,4 do
        local ok, err = pcall(function()
            local separator = LOADER_URL:find("?", 1, true) and "&" or "?"
            local source = game:HttpGet(LOADER_URL .. separator .. "t=" .. tostring(os.time()))
            local fn, syntaxError = loadstring(source)
            if not fn then error(syntaxError or "invalid loader") end
            fn()
        end)
        if ok then
            warn("[PVH Autoexec v3] LOADER EXECUTED | place=" .. tostring(game.PlaceId))
            return
        end
        lastError = err
        warn("[PVH Autoexec v3] LOADER ATTEMPT " .. attempt .. " FAILED: " .. tostring(err))
        task.wait(0.6 * attempt)
    end

    env.PVH_AutoexecBootWorld = nil
    warn("[PVH Autoexec v3] BOOT FAILED | " .. tostring(lastError))
end
