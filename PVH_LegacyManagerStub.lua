-- Prime Void Hub | obsolete ThemeManager/SaveManager compatibility layer
-- Old third-party theme/config libraries are replaced; the Prime Void UI bridge
-- handles named profiles, native settings and universal AutoSave/AutoExecute.
local manager={}
local function noop(...) return nil end
function manager:ExportConfig() return '{}' end
function manager:ImportConfig(...) return false end
function manager:LoadConfigFromJSON(...) return false end
function manager:LoadAutoloadConfig(...) return nil end
function manager:BuildConfigSection(...) return nil end
return setmetatable(manager,{__index=function(_,key)
    return noop
end})