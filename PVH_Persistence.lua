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
    local toggles = type(env.Toggles) == "table" and env.Toggles
        or (type(_G.Toggles) == "table" and _G.Toggles or {})
    local options = type(env.Options) == "table" and env.Options
        or (type(_G.Options) == "table" and _G.Options or {})
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
                    local safe = encodeValue(value)
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
    local c = {env.queue_on_teleport, env.queueonteleport}
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
        AutoExec = previous ~= nil and previous.autoExec == true,
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
        _queued = false,
        _lastWritten = nil,
    }

    function self:WritePrefs()
        if not self.HasStorage then return false end
        return writeJSON(prefsPath, {schema = 1, autoSave = self.AutoSave, autoExec = self.AutoExec})
    end

    function self:QueueAutoExec()
        if self._queued or not self.AutoExec or not self.HasAutoexec or not self.HasStorage then return false end
        local queue = resolveQueue()
        if not queue then return false end
        -- The target checks the latest preference, so switching Autoexec OFF
        -- also disables an already queued operation on the next server.
        local loaderUrl = tostring(options.loaderUrl or
            "https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Loader.lua")
        local script = string.format([=[
task.wait(0.65)
local ok, prefs = pcall(function()
    return game:GetService("HttpService"):JSONDecode(readfile(%q))
end)
if ok and type(prefs) == "table" and prefs.autoExec == true then
    local ran, failure = pcall(function()
        local content = game:HttpGet(%q)
        local run = loadstring(content)
        if type(run) == "function" then run() end
    end)
    if not ran then warn("[PVH Autoexec] " .. tostring(failure)) end
end
]=], prefsPath, loaderUrl)
        local ok = pcall(queue, script)
        if ok then self._queued = true end
        return ok
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
        self.AutoExec = on == true
        self:WritePrefs()
        if self.AutoExec then self:QueueAutoExec() end
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
                groupbox:AddLabel("Auto Save/Autoexec: executor sem arquivos locais.", true)
            elseif not self.HasAutoexec then
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
        self:QueueAutoExec()
    end

    function self:AfterPort()
        -- Destruction Simulator exports a native Obsidian settings groupbox.
        if not self.Bound then
            self:Bind(env.PVDS_SettingsPolish or env.PVH_SettingsPolish)
        end
        self:QueueAutoExec()
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
                if self.AutoSave and self.HasStorage then
                    local snapshot, count = capture()
                    if count > 0 then
                        local ok, encoded = pcall(function() return HttpService:JSONEncode(snapshot) end)
                        if ok and encoded ~= self._lastWritten then
                            if writeJSON(snapshotPath, snapshot) then
                                self._lastWritten = encoded
                            end
                        end
                    end
                end
                task.wait(0.85)
            end
        end)
    end

    function self:Stop()
        self.Alive = false
    end

    return self
end
