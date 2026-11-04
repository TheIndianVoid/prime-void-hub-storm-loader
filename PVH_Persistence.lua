-- Prime Void Hub | Universal session preferences v0.1
-- Shared bootstrap for current and future Obsidian-based ports.
-- This module is intentionally independent from individual gameplay logic.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local user = Players.LocalPlayer
local env = (type(getgenv) == "function" and getgenv()) or _G

local function safeName(s)
    return tostring(s or "port"):lower():gsub("[^%w_-]", "_"):sub(1,64)
end

local function ensurePath(path)
    if type(makefolder) ~= "function" then return false end
    local parent = ""
    for part in string.gmatch(path, "[^/]+") do
        parent = parent == "" and part or (parent .. "/" .. part)
        local ok, exists = pcall(function()
            return type(isfolder) == "function" and isfolder(parent)
        end)
        if not (ok and exists) then pcall(makefolder, parent) end
    end
    return true
end

local function readJSON(path)
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return nil end
    local ok, data = pcall(function()
        if not isfile(path) then return nil end
        return HttpService:JSONDecode(readfile(path))
    end)
    return ok and type(data) == "table" and data or nil
end

local function writeJSON(path, data)
    if type(writefile) ~= "function" then return false end
    local ok = pcall(function()
        writefile(path, HttpService:JSONEncode(data))
    end)
    return ok
end

local function finite(x)
    return type(x) == "number" and x == x and math.abs(x) < math.huge
end

local function encodeValue(value, depth)
    depth = depth or 0
    if depth > 4 then return nil end
    local kind = typeof(value)
    if kind == "nil" then return nil end
    if kind == "boolean" then return value end
    if kind == "number" then return finite(value) and value or nil end
    if kind == "string" then return #value <= 4096 and value or nil end
    if kind == "Color3" then
        return {__pvh_kind = "Color3", r = value.R, g = value.G, b = value.B}
    end
    if kind == "EnumItem" then
        return {__pvh_kind = "EnumItem", value = tostring(value)}
    end
    if kind ~= "table" then return nil end
    local result, count = {}, 0
    for key, item in pairs(value) do
        if (type(key) == "string" and #key <= 150)
            or (type(key) == "number" and key == math.floor(key) and key >= 1 and key <= 256) then
            count += 1
            if count > 256 then break end
            local normalized = encodeValue(item, depth + 1)
            if normalized ~= nil then result[key] = normalized end
        end
    end
    return result
end

local function decodeValue(value)
    if type(value) ~= "table" then return value end
    if value.__pvh_kind == "KeyPicker" then
        return {tostring(value.key or "None"), tostring(value.mode or "Toggle"),
            decodeValue(value.modifiers or {})}
    end
    if value.__pvh_kind == "Color3" then
        if finite(value.r) and finite(value.g) and finite(value.b) then
            return Color3.new(math.clamp(value.r, 0, 1), math.clamp(value.g, 0, 1), math.clamp(value.b, 0, 1))
        end
        return nil
    end
    if value.__pvh_kind == "EnumItem" and type(value.value) == "string" then
        local enumType, name = value.value:match("^Enum%.([%w_]+)%.([%w_]+)$")
        local ok, item = pcall(function() return Enum[enumType][name] end)
        return ok and item or nil
    end
    local decoded = {}
    for key, entry in pairs(value) do
        decoded[key] = decodeValue(entry)
    end
    return decoded
end

local function locateControls()
    -- Obsidian exposes both registries through Library, not through _G.
    local lib = env.Library
    local toggles = type(lib) == "table" and type(lib.Toggles) == "table" and lib.Toggles
        or (type(env.Toggles) == "table" and env.Toggles or {})
    local options = type(lib) == "table" and type(lib.Options) == "table" and lib.Options
        or (type(env.Options) == "table" and env.Options or {})
    return toggles, options
end

local function capture()
    local toggles, options = locateControls()
    local result = {schema = 1, toggles = {}, options = {}}
    local count = 0
    for groupName, group in pairs({toggles = toggles, options = options}) do
        for id, control in pairs(group) do
            if type(id) == "string" and id:sub(1, 14) ~= "PVH_UNIVERSAL_"
                and type(control) == "table" then
                local ok, value = pcall(function() return control.Value end)
                if ok then
                    local safe
                    if groupName == "options" and type(value) == "string"
                        and type(control.Mode) == "string" then
                        safe = {__pvh_kind = "KeyPicker", key = value,
                            mode = control.Mode, modifiers = encodeValue(control.Modifiers or {})}
                    else
                        safe = encodeValue(value)
                    end
                    if safe ~= nil then
                        result[groupName][id] = safe
                        count += 1
                    end
                end
            end
        end
    end
    return result, count
end

local function priority(id)
    local lower = tostring(id):lower()
    if lower:find("pilot", 1, true) or lower:find("autofarm", 1, true) then return 1 end
    if lower:find("espvehicles", 1, true) or lower:find("espplayers", 1, true) then return 2 end
    if lower:find("money", 1, true) or lower:find("hop", 1, true) then return 5 end
    if lower:find("box", 1, true) or lower:find("friend", 1, true) then return 6 end
    return 3
end

local function restore(snapshot)
    if type(snapshot) ~= "table" then return end
    local toggles, options = locateControls()
    local function apply(control, target)
        if type(control) ~= "table" or type(control.SetValue) ~= "function" then return end
        local value = decodeValue(target)
        if value == nil then return end
        local ok, current = pcall(function() return control.Value end)
        if ok and type(value) ~= "table" and current == value then return end
        pcall(function() control:SetValue(value) end)
    end
    -- Keybinds and dropdowns first: some Obsidian keypickers reset their paired toggle.
    for id, value in pairs(snapshot.options or {}) do
        if type(id) == "string" and id:sub(1, 14) ~= "PVH_UNIVERSAL_" then
            apply(options[id], value)
        end
    end
    local ordered = {}
    for id, value in pairs(snapshot.toggles or {}) do
        if type(id) == "string" and id:sub(1, 14) ~= "PVH_UNIVERSAL_" then
            ordered[#ordered + 1] = {id = id, value = value}
        end
    end
    table.sort(ordered, function(a, b)
        local pa, pb = priority(a.id), priority(b.id)
        if pa ~= pb then return pa < pb end
        return a.id < b.id
    end)
    for _, entry in ipairs(ordered) do
        if entry.value == false then apply(toggles[entry.id], false) end
    end
    for _, entry in ipairs(ordered) do
        if entry.value ~= false then apply(toggles[entry.id], entry.value) end
    end
end

local function resolveQueue()
    local c = {env.queue_on_teleport or queue_on_teleport,
        env.queueonteleport or queueonteleport}
    local synApi = env.syn or (type(syn) == "table" and syn or nil)
    if type(synApi) == "table" then
        c[#c + 1] = synApi.queue_on_teleport
    end
    local fluxApi = env.fluxus
    if type(fluxApi) == "table" then
        c[#c + 1] = fluxApi.queue_on_teleport
    end
    for _, fn in pairs(c) do
        if type(fn) == "function" then return fn end
    end
    return nil
end

return function(options)
    options = options or {}
    local port = safeName(options.port)
    local userId = user and tostring(user.UserId) or "0"
    local root = "primevoid_hub/_Universal"
    local prefsPath = root .. "/" .. port .. "_" .. userId .. "_prefs.json"
    local snapshotPath = root .. "/" .. port .. "_" .. userId .. "_last_run.json"
    local previous = readJSON(prefsPath)
    local available = type(writefile) == "function" and type(readfile) == "function"
        and type(isfile) == "function" and type(makefolder) == "function"
    if available then ensurePath(root) end

    local self = {
        AutoSave = previous == nil or previous.autoSave ~= false,
        -- During a queued cross-place handoff, executor file storage may be scoped
        -- differently. Carry the enabled state only when no local preference exists.
        AutoExec = previous ~= nil and previous.autoExec == true
            or (previous == nil and options.carryAutoexec == true),
        HasStorage = available,
        HasAutoexec = resolveQueue() ~= nil,
        Alive = true,
        Bound = false,
        Ready = false,
        Port = port,
        PrefsPath = prefsPath,
        SnapshotPath = snapshotPath,
        LastSnapshot = readJSON(snapshotPath),
        NativeConfig = options.nativeConfig,
        OriginUniverse = tonumber(options.originUniverse) or tonumber(game.GameId) or 0,
        _queued = false,
        _lastWritten = nil,
    }

    function self:WritePrefs()
        if not self.HasStorage then return false end
        return writeJSON(prefsPath, {schema = 1, autoSave = self.AutoSave, autoExec = self.AutoExec})
    end

    -- Infinite Yield's keepiy registers the queued script from OnTeleport.
    -- Do not depend on readfile() in the DESTINATION: some executors isolate
    -- their workspace by experience/place even when queue_on_teleport works.
    function self:QueueAutoExec()
        if self._queued or not self.AutoExec or not self.HasAutoexec then return false end
        local queue = resolveQueue()
        if not queue then return false end
        local loaderUrl = tostring(options.loaderUrl or
            "https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Loader.lua")
        local script = string.format([=[
if not game:IsLoaded() then game.Loaded:Wait() end
local env = (type(getgenv) == "function" and getgenv()) or _G
-- Carries the origin identity across different executor workspace partitions.
-- The universal loader matches same-universe subplaces using this hint.
env.PVH_AutoexecCarry = {port = %q, originUniverse = %d, autoexec = true}
task.wait(0.85)
local ok, err = pcall(function()
    local content = game:HttpGet(%q)
    local run, compileErr = loadstring(content)
    if type(run) ~= "function" then error(compileErr or "invalid loader") end
    run()
end)
if not ok then warn("[PVH Autoexec] Destination load failed: " .. tostring(err)) end
]=], self.Port, self.OriginUniverse, loaderUrl)
        local ok, err = pcall(queue, script)
        if ok then
            self._queued = true
            warn("[PVH Autoexec] queued for teleport | port=" .. self.Port)
        else
            warn("[PVH Autoexec] queue_on_teleport failed: " .. tostring(err))
        end
        return ok
    end

    function self:AttachTeleport()
        if self._onTeleport then return true end
        local playerObj = Players.LocalPlayer
        if not playerObj then return false end
        local ok, connection = pcall(function()
            return playerObj.OnTeleport:Connect(function(state)
                if state == Enum.TeleportState.Failed then
                    -- A failed teleport must not lock out the next attempt.
                    self._queued = false
                    return
                end
                if not self.Alive then return end
                -- Queue first: a potentially slow file write must not miss the
                -- executor's short teleport preparation window.
                if self.AutoExec then
                    self:QueueAutoExec()
                end
                self:SaveNow()
            end)
        end)
        if ok and connection then
            self._onTeleport = connection
            -- Roblox reports some failed teleports via TeleportInitFailed rather
            -- than an OnTeleport(Failed) transition.
            pcall(function()
                self._teleportInitFailed = game:GetService("TeleportService").TeleportInitFailed:Connect(function(p)
                    if p == playerObj then self._queued = false end
                end)
            end)
            return true
        end
        warn("[PVH Autoexec] OnTeleport unavailable: " .. tostring(connection))
        return false
    end

    -- Intermediate places that are not a supported port still need to forward
    -- the queue to the next teleport (e.g. lobby -> matchmaking -> actual map).
    function self:Bridge()
        return self:AttachTeleport()
    end

    function self:SetAutoSave(on)
        self.AutoSave = on == true
        self:WritePrefs()
        if not self.AutoSave then
            self.LastSnapshot = nil
            self._lastWritten = nil
            if type(delfile) == "function" then
                pcall(function() if isfile(snapshotPath) then delfile(snapshotPath) end end)
            end
        else
            self._lastWritten = nil
        end
    end

    function self:SetAutoExec(on)
        if on == true and not self.HasAutoexec then
            self.AutoExec = false
            warn("[PVH Autoexec] queue_on_teleport is required.")
            task.defer(function()
                local toggles = locateControls()
                local toggle = toggles.PVH_UNIVERSAL_AUTOEXEC
                if toggle and toggle.Value ~= false then
                    pcall(function() toggle:SetValue(false) end)
                end
            end)
        else
            self.AutoExec = on == true
        end
        self:WritePrefs()
        -- The next teleport event queues execution; enabling here only arms it.
        self._queued = false
    end

    function self:Bind(groupbox)
        if self.Bound or not groupbox or type(groupbox.AddToggle) ~= "function" then return false end
        local ok = pcall(function()
            groupbox:AddToggle("PVH_UNIVERSAL_AUTOSAVE", {
                Text = "Auto Save (ultima sessao / last run)",
                Default = self.AutoSave,
                Tooltip = "Ativado por padrao. Desativado: iniciar as proximas sessoes com padroes do port.",
                Callback = function(on) self:SetAutoSave(on) end
            })
            groupbox:AddToggle("PVH_UNIVERSAL_AUTOEXEC", {
                Text = "Autoexec (Server Hop / Teleport)",
                Default = self.AutoExec,
                Tooltip = "Reexecuta o loader em outro servidor/experiencia se o executor suportar queue_on_teleport.",
                Callback = function(on) self:SetAutoExec(on) end
            })
            if not self.HasStorage then
                groupbox:AddLabel("Auto Save sem armazenamento; Autoexec vale so nesta sessao.", true)
            end
            if not self.HasAutoexec then
                groupbox:AddLabel("Autoexec indisponivel neste executor (queue_on_teleport).", true)
            end
        end)
        self.Bound = ok
        return ok
    end

    function self:BeforePort()
        if not self.AutoSave and type(delfile) == "function" and type(self.NativeConfig) == "string" then
            pcall(function()
                if type(isfile) == "function" and isfile(self.NativeConfig) then
                    delfile(self.NativeConfig)
                end
            end)
        end
        self:AttachTeleport()
    end

    function self:SaveNow()
        if not self.Alive or not self.Ready or not self.AutoSave or not self.HasStorage then return false end
        local snapshot, count = capture()
        if count < 1 then return false end
        local ok, encoded = pcall(function() return HttpService:JSONEncode(snapshot) end)
        if not ok then return false end
        if encoded == self._lastWritten then return true end
        if writeJSON(snapshotPath, snapshot) then
            self._lastWritten = encoded
            return true
        end
        return false
    end

    function self:AfterPort()
        -- Attach to the actual Settings tab through Obsidian's public tab registry.
        -- Works even for ports whose gameplay source was minified/obfuscated.
        local library = env.Library
        if not self.Bound and type(library) == "table" and type(library.Tabs) == "table" then
            for name, tab in pairs(library.Tabs) do
                local key = tostring(name):lower()
                if key:find("settings", 1, true) or key:find("config", 1, true) then
                    local ok, groupbox = pcall(function()
                        return tab:AddGroupbox({Side = "Right",
                            Name = "Sessao / Session", IconName = "save"})
                    end)
                    if ok and groupbox and self:Bind(groupbox) then break end
                end
            end
        end
        if not self.Bound then
            self:Bind(env.PVDS_SettingsPolish or env.PVH_SettingsPolish)
        end
        self:AttachTeleport()
        if type(library) == "table" and type(library.OnUnload) == "function" then
            pcall(function() library:OnUnload(function()self:Stop()end) end)
        end
        task.spawn(function()
            task.wait(1.8)
            if self.AutoSave and self.LastSnapshot then
                -- Allow late-added options (e.g. Exu gifts) to become available.
                for _ = 1, 3 do
                    if not self.Alive or not self.AutoSave then break end
                    restore(self.LastSnapshot)
                    task.wait(1)
                end
            end
            self.Ready = true
            while self.Alive do
                self:SaveNow()
                task.wait(0.35)
            end
        end)
    end

    function self:Stop()
        if not self.Alive then return end
        self:SaveNow()
        self.Alive = false
        if self._onTeleport then
            pcall(function() self._onTeleport:Disconnect() end)
        end
        if self._teleportInitFailed then
            pcall(function() self._teleportInitFailed:Disconnect() end)
        end
    end

    return self
end
