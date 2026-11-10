-- Prime Void Hub | Universal Loader
local placeId=tonumber(game.PlaceId) or 0
local universeId=tonumber(game.GameId) or 0
local ports={
    {
        name='Storm Suite',
        version='v1.0.0',
        officialName='Ride Storm',
        placeIds={[12593620250]=true},
        universeIds={[4420562665]=true},
        url='https://prime-void-hub-storm-gateway.vercel.app/prime-void-hub.lua',
        markers={'SOURCE GITHUB v','local function setupInterfaceAndLoops()','Prime Void Hub - Storm Suite'},
    },
    {
        name='Grau SP',
        version='v0.4.4',
        officialName='Grau SP',
        placeIds={[101953291486308]=true},
        universeIds={[7938305201]=true},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/ports/grau-sp.lua',
        markers={'-- Prime Void Hub | GRAU SP | v0.4.3','env.PVH_GrauSP_Unload'},
    },
    {
        name='Huntress',
        officialName='HUNTRESS',
        version='v1.1.1',
        placeIds={[104259439179020]=true,[110394010715338]=true},
        universeIds={[10416475193]=true},
        url='https://prime-void-hub-huntress-gateway.vercel.app/huntress.lua',
        markers={'Prime Void Hub - Huntress','PVHuntressUnload','Library:CreateWindow'},
    },
    {
        name='Exu Security Lab',
        version='v1.1.2',
        officialName='Steal An Exu',
        placeIds={[103076400317371]=true},
        universeIds={},
        url='https://prime-void-hub-exu-gateway.vercel.app/exu-security-lab.lua',
        markers={'local rarityList=','Prime Void | Exu Security Lab'},
    },
    {
        name='Destruction Simulator',
        version='v0.2.4',
        officialName='Destruction Simulator',
        placeIds={[2248408710]=true},
        universeIds={},
        url='https://prime-void-hub-destruction-gateway.vercel.app/destruction-simulator.lua',
        markers={'-- Prime Void Hub | Destruction Simulator | v0.2.4 TEST','local Airflow={}','global.PVDestructionUnload'},
    },
    {
        name='Dont Splash Explorer',
        version='v0.1.2',
        officialName="Don't Splash",
        placeIds={[139386728420706]=true},
        universeIds={},
        url='https://prime-void-hub-splash-gateway.vercel.app/dont-splash.lua',
        markers={'-- Prime Void Hub - Dont Splash','PVDontSplashUnload','Library:CreateWindow'},
    },
    {
        name='Clover Legends',
        version='v0.1.9',
        officialName='Clover Legends: Devil Fusion',
        placeIds={[109813591245812]=true},
        universeIds={[10769707586]=true},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/ports/clover.lua',
        markers={'Prime Void Hub | Clover Legends','PVH_CloverUnload'},
    },
    {
        name='RIVALS',
        version='v0.1.1',
        officialName='RIVALS',
        placeIds={[17625359962]=true},
        universeIds={[6035872082]=true},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/ports/rivals.lua',
        markers={'-- Prime Void Hub | RIVALS | v0.1.0'},
    },
    {
        name='Steal a Brainrot',
        version='v0.1.0',
        officialName='Steal a Brainrot',
        placeIds={[109983668079237]=true},
        universeIds={[7709344486]=true},
        url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/brainrot.lua',
        markers={'-- Obscura ['},
    },
}
local selected
for _,port in ipairs(ports) do
    if port.placeIds[placeId] or port.universeIds[universeId] then
        selected=port
        break
    end
end
-- Carry a supported port across sibling places of the same experience.
-- Queue handoff state is embedded in the teleport payload, so it works even
-- when the executor's file workspace is scoped per place or experience.
local transportEnv=(type(getgenv)=='function' and getgenv()) or _G
local carry=transportEnv.PVH_AutoexecCarry
transportEnv.PVH_AutoexecCarry=nil
local carriedPort
if type(carry)=='table' and carry.autoexec==true then
    for _,port in ipairs(ports) do
        if port.name==carry.port then carriedPort=port break end
    end
end
if not selected and carriedPort and universeId~=0
    and tonumber(carry.originUniverse)==universeId then
    selected=carriedPort
end
if type(carry)=="table" and carry.autoexec==true then
    warn("[PVH Autoexec] ROUTING | place="..tostring(placeId)
        .." | universe="..tostring(universeId)
        .." | carried="..tostring(carry.port)
        .." | selected="..tostring(selected and selected.name or "unsupported"))
end
-- Friendly unsupported-game dialog. Copying uses the executor clipboard when available.
-- If clipboard support is missing, show a selectable address instead of claiming success.
local function showUnsupportedGame(isPaused)
    -- Use the same pinned Obsidian library as the supported Prime Void Hub ports.
    -- This UI does not execute a game port or change the supported-game roster.
    local gameLink='https://www.roblox.com/games/'..tostring(placeId)
    local discordLink='https://discord.gg/PD3PeyG8aq'
    local env=type(getgenv)=='function' and getgenv() or _G
    if type(env.PVH_UnsupportedUIUnload)=='function' then
        pcall(env.PVH_UnsupportedUIUnload)
    end

    local Library
    local ok,reason=pcall(function()
        local loaded,lib=pcall(function()
            return loadstring(game:HttpGet(
                'https://raw.githubusercontent.com/deividcomsono/Obsidian/82d402b5de7d8903915f1afe99b5b7e340e7cd28/Library.lua'
            ))()
        end)
        if not loaded or type(lib)~='table' then
            error('Biblioteca Obsidian indisponível: '..tostring(lib))
        end
        Library=lib
        Library.ShowCustomCursor=false

        local Window=Library:CreateWindow({
            Title='Prime Void Hub',
            Footer=isPaused and 'Universal Loader | Port em manutenção' or 'Universal Loader | Aviso v1.0.1 (31/10)',
            Center=true,
            AutoShow=true,
            Resizable=true,
            Size=UDim2.fromOffset(600,390),
            ShowCustomCursor=false,
            -- Never use Unknown: mouse/touch clicks also report that KeyCode.
            ToggleKeybind=Enum.KeyCode.RightControl,
            NotifySide='Right',
            MinSidebarWidth=140,
            EnableCompacting=true,
            SidebarCompactWidth=48,
            Animations={
                ToggleWindow=false,TabSwitch=false,Groupbox=false,
                Dropdown=false,KeyPicker=false,
            },
        })
        -- This informational window has no minimize keybind.
        -- nil never matches an Input.KeyCode; only 'Fechar' dismisses it.
        Library.ToggleKeybind=nil
        local tab=Window:AddTab('Suporte','life-buoy')
        -- Visible UI build marker: verify what code actually reached the executor.
        local uiBuild=isPaused and 'Aviso de manutenção | 07/11/2026' or 'Aviso v1.0.1 | 31/10/2026'

        local details=tab:AddGroupbox({
            Side='Left',Name='Jogo não suportado',IconName='circle-alert',
            DisableCollapsing=true,
        })
        details:AddLabel(isPaused and 'Roube um Exu está temporariamente sem suporte no Prime Void Hub.' or 'Este jogo ainda não é suportado pelo Prime Void Hub.',true)
        details:AddLabel(uiBuild,false)
        details:AddLabel(isPaused and 'Script pausado para manutenção. A versão atual encontra-se detectada. Aguarde a atualização antes de utilizar.' or 'Quer sugerir um port? Envie o link do jogo em nosso Discord.',true)
        details:AddDivider()
        details:AddLabel('PlaceId: '..tostring(placeId),true)

        local links=tab:AddGroupbox({
            Side='Right',Name='Links e comunidade',IconName='link',
            DisableCollapsing=true,
        })
        -- Obsidian Input uses TextScaled=true, shrinking long URLs to tiny text.
        -- Show the full URL in a readable, wrapping label too.
        links:AddLabel({Text=gameLink,DoesWrap=true,Size=16})
        local linkInput=links:AddInput('PVH_UnsupportedLink',{
            Text='Link para copiar',
            Default=gameLink,
            ClearTextOnFocus=false,
            ClearTextOnBlur=false,
            AllowEmpty=false,
            Finished=true,
        })
        -- Keep the editable field legible even for long PlaceIds.
        -- The TextBox can scroll horizontally when selected.
        local linkBox=linkInput.Holder and linkInput.Holder:FindFirstChildOfClass('TextBox')
        if linkBox then
            linkBox.TextScaled=false
            linkBox.TextSize=14
            linkBox.TextXAlignment=Enum.TextXAlignment.Left
        end
        local status=links:AddLabel('Use os botões abaixo ou copie o campo acima.',true)
        local function copyLink(url,successMessage)
            linkInput:SetValue(url)
            local clipboard=type(setclipboard)=='function' and setclipboard
                or (type(toclipboard)=='function' and toclipboard)
            if clipboard and pcall(clipboard,url) then
                status:SetText(successMessage)
            else
                status:SetText('Cópia indisponível: selecione o campo acima para copiar.')
            end
        end
        links:AddButton({
            Text='Copiar link do jogo',IconName='copy',
            Func=function()
                copyLink(gameLink,'Link do jogo copiado!')
            end,
        })
        links:AddButton({
            Text='Copiar Discord',IconName='message-circle',
            Func=function()
                copyLink(discordLink,'Convite do Discord copiado!')
            end,
        })
        links:AddDivider()
        links:AddButton({
            Text='Fechar',IconName='x',
            Func=function() Library:Unload() end,
        })

        local function unload()
            if Library and not Library.Unloaded then
                Library:Unload()
            end
        end
        env.PVH_UnsupportedUIUnload=unload
        Library:OnUnload(function()
            if env.PVH_UnsupportedUIUnload==unload then
                env.PVH_UnsupportedUIUnload=nil
            end
        end)
    end)
    if not ok then
        if Library and not Library.Unloaded then
            pcall(function() Library:Unload() end)
        end
        warn('[Prime Void Hub] '..(isPaused and 'Roube um Exu pausado para manutenção (versão detectada)' or 'Jogo não suportado')..' | PlaceId='..tostring(placeId)
            ..' | UI Obsidian falhou: '..tostring(reason)
            ..' | Discord: '..discordLink)
        pcall(function()
            game:GetService('StarterGui'):SetCore('SendNotification',{
                Title='Prime Void Hub',
                Text=isPaused and 'Roube um Exu pausado para manutenção: versão detectada.' or 'Jogo não suportado. Sugira este jogo no Discord!',
                Duration=8,
            })
        end)
    end
end
-- Exu is available again; Auto Farm is locked after the UI loads.
-- Unsupported games are also meaningful analytics events. Do not require
-- an active gameplay port or execute any unsupported port code.
local function sendUnsupportedRunLog()
    local env=transportEnv
    local world=tostring(game.PlaceId)..":"..tostring(game.JobId)
    if env.PVH_UnsupportedLogGame==game and env.PVH_UnsupportedLogWorld==world then return end
    env.PVH_UnsupportedLogGame=game
    env.PVH_UnsupportedLogWorld=world
    local ok,accepted=pcall(function()
        local req=env.request or env.http_request or request or http_request
            or (type(syn)=="table" and syn.request)
        if type(req)~="function" then return false end
        local player=game:GetService("Players").LocalPlayer
        if not player then return false end
        local gameName=""
        local infoOK,info=pcall(function()
            return game:GetService("MarketplaceService"):GetProductInfo(
                game.PlaceId,Enum.InfoType.Asset)
        end)
        if infoOK and type(info)=="table" and type(info.Name)=="string" then
            gameName=info.Name
        end
        if gameName=="" then
            gameName=tostring(game.Name or ("PlaceId "..tostring(game.PlaceId)))
        end
        local executor="Não identificado"
        for _,fn in ipairs({env.identifyexecutor,env.getexecutorname}) do
            if type(fn)=="function" then
                local identified,name=pcall(fn)
                if identified and type(name)=="string" and #name>0 then
                    executor=name:sub(1,60)
                    break
                end
            end
        end
        local payload=game:GetService("HttpService"):JSONEncode({
            username=player.Name,userId=tostring(player.UserId),
            placeId=tostring(game.PlaceId),gameName=gameName:sub(1,80),
            executor=executor,version="Universal",
            supported=false,supportStatus="unsupported",
        })
        local response=req({
            Url="https://prime-void-hub-exu-gateway.vercel.app/api/telemetry",
            Method="POST",Headers={["Content-Type"]="application/json"},
            Body=payload,
        })
        if type(response)=="table" then
            local status=tonumber(response.StatusCode or response.Status)
            if status and (status<200 or status>=300) then return false end
        end
        return true
    end)
    if not ok or accepted~=true then
        env.PVH_UnsupportedLogGame=nil
        env.PVH_UnsupportedLogWorld=nil
        warn("[PVH Analytics] Unsupported experience delivery not confirmed")
    end
end
if not selected then
    task.spawn(sendUnsupportedRunLog)
    -- An unsupported lobby is not the end of an autoexec chain. Stay armed
    -- for the next teleport without executing a wrong game's port.
    if carriedPort then
        local okBridge,errBridge=pcall(function()
            local moduleURL='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/PVH_Persistence.lua'
            local factory,loadErr=loadstring(game:HttpGet(moduleURL..'?pvht='..tostring(os.time())))
            if not factory then error(loadErr) end
            local constructor=factory()
            if type(constructor)~='function' then error('Persistence constructor unavailable') end
            local old=transportEnv.PVH_Persistence
            if type(old)=='table' and type(old.Stop)=='function' then pcall(function()old:Stop()end) end
            local bridge=constructor({
                port=carriedPort.name,originUniverse=tonumber(carry.originUniverse),
                carryAutoexec=true,
                loaderUrl='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Loader.lua',
            })
            transportEnv.PVH_Persistence=bridge
            bridge:Bridge()
        end)
        if not okBridge then warn('[PVH Autoexec] Bridge unavailable: '..tostring(errBridge)) end
    end
    showUnsupportedGame()
    return
end
local genv=type(getgenv)=='function' and getgenv() or _G
-- Clear an existing test overlay or previous universal loader overlay before rerunning.
local oldUXCleanup = genv.PVH_UX_UniversalCleanup or genv.PVH_UX_TestCleanup
if type(oldUXCleanup) == 'function' then
    pcall(oldUXCleanup)
end
genv.PVH_UX_TestCleanup = nil

-- Avoid duplicate launches only inside the SAME Roblox world.
-- Earlier guard used os.clock() alone; after a rejoin that clock may reset,
-- making a *negative* elapsed time incorrectly look like a duplicate.
local currentWorld=tostring(game.PlaceId)..':'..tostring(game.JobId)
-- Keep one successful telemetry delivery per port and server instance.
local analyticsRunKey=currentWorld..':'..selected.name
local previousWorld=genv.PVH_UniversalBootWorld
local previousLog=genv.PVH_UniversalAnalyticsSentKey==analyticsRunKey
if previousWorld~=currentWorld then genv.PV_Hub_AnalyticsSent=nil end
local lastBoot=genv.PVH_UniversalStartedAt
local elapsed=type(lastBoot)=='number' and (os.clock()-lastBoot) or nil
if previousWorld==currentWorld and genv.PVH_UniversalBootGame==game
    and type(elapsed)=='number' and elapsed>=0 and elapsed<2.5
    and genv.PV_Hub_ActivePort==selected.name then
    warn('[PVH Autoexec v3] Duplicate loader invocation ignored in same server')
    return
end
genv.PVH_UniversalBootWorld=currentWorld
genv.PVH_UniversalBootGame=game
genv.PVH_UniversalStartedAt=os.clock()
genv.PV_Hub_ActivePort=selected.name
-- Crash-safe boot trace: write before downloading or executing the RIVALS module.
if selected.name=='RIVALS' and type(writefile)=='function' then
    pcall(writefile,'PVH_Rivals_BootTrace.txt',
        '[PVH RIVALS] loader_selected | place='..tostring(placeId)
        ..' | version='..tostring(selected.version)..'\n')
end

local function sendUniversalRunLog()
    if previousLog or genv.PVH_UniversalAnalyticsSentKey==analyticsRunKey
        or genv.PV_Hub_AnalyticsSent==true
        or genv.PVH_UniversalAnalyticsPendingKey==analyticsRunKey then return end
    genv.PVH_UniversalAnalyticsPendingKey=analyticsRunKey
    local delivered,payload=pcall(function()
        local req=genv.request or genv.http_request
        local requestFn=type(req)=='function' and req
            or type(request)=='function' and request
            or type(http_request)=='function' and http_request
            or (type(syn)=='table' and type(syn.request)=='function' and syn.request)
        if type(requestFn)~='function' then return false end
        local player=game:GetService('Players').LocalPlayer
        if not player then return false end
        local executor='Não identificado'
        -- Os executores podem fornecer o próprio nome; informação não verificável.
        local candidates={identifyexecutor,getexecutorname,genv.identifyexecutor,genv.getexecutorname}
        for _,fn in pairs(candidates) do
            if type(fn)=='function' then
                local identified,name=pcall(fn)
                if identified and type(name)=='string' and name:match('%S') then
                    executor=name:sub(1,60)
                    break
                end
            end
        end
        local json=game:GetService('HttpService'):JSONEncode({
            executor=executor,
            username=player.Name,
            userId=tostring(player.UserId),
            placeId=tostring(game.PlaceId),
            gameName=selected.officialName,
            supported=true,
            version=selected.version,
        })
        local response=requestFn({
            Url=selected.name=='Grau SP'
                and 'https://prime-void-hub-exu-gateway.vercel.app/api/telemetry-grau'
                or 'https://prime-void-hub-exu-gateway.vercel.app/api/telemetry',
            Method='POST',
            Headers={['Content-Type']='application/json'},
            Body=json,
        })
        if type(response)=='table' then
            local status=tonumber(response.StatusCode or response.Status)
            if status and (status<200 or status>=300) then return false end
        end
        return true
    end)
    if genv.PVH_UniversalAnalyticsPendingKey==analyticsRunKey then
        genv.PVH_UniversalAnalyticsPendingKey=nil
    end
    if delivered and payload==true then
        genv.PV_Hub_AnalyticsSent=true
        genv.PVH_UniversalAnalyticsSentKey=analyticsRunKey
    else
        genv.PV_Hub_AnalyticsSent=nil
    end
end
if selected.name=='RIVALS' then
    -- Confirm the launch attempt before loading any RIVALS scripts.
    -- The normal post-load call is deduplicated by the sent-key.
    sendUniversalRunLog()
end

-- This production loader executes validated PRE-PATCHED Obscura builds.
-- Runtime source transforms from the normal loader must never modify these VM sources.
local obfuscatedNames={
    ['Storm Suite']='storm.lua',
    ['Huntress']='huntress.lua',
    ['Exu Security Lab']='exu.lua',
    ['Destruction Simulator']='destruction.lua',
    ['Dont Splash Explorer']='splash.lua',
    ['Steal a Brainrot']='brainrot.lua',
    ['RIVALS']='rivals.lua',
}
-- Audited direct ports are explicit exceptions; other VM-protected sources are unchanged.
local directPorts={
    ['Grau SP']={file='grau-sp.lua',marker='-- Prime Void Hub | GRAU SP | v0.4.4'},
    ['Clover Legends']={file='clover.lua',marker='-- Prime Void Hub | Clover Legends: Devil Fusion | v0.1.9'},
    ['RIVALS']={file='rivals.lua',marker='-- Prime Void Hub | RIVALS | v0.1.1'},
}
local direct=directPorts[selected.name]
local obfuscatedFile=obfuscatedNames[selected.name]
if not direct and not obfuscatedFile then
    error('[PVH PORT] Unrecognized port: '..tostring(selected.name),0)
end
selected.url=direct
    and 'https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/ports/'..direct.file
    or 'https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/'..obfuscatedFile
local ok,source=pcall(function()
    return game:HttpGet(selected.url..'?t='..tostring(os.time()))
end)
if not ok or type(source)~='string' or #source<800 then
    error('[PVH OBF] Download failed ('..selected.name..'): '..tostring(source),0)
end
if direct then
    if not source:find(direct.marker,1,true) then
        error('[PVH PORT] Unexpected direct module for '..selected.name,0)
    end
elseif not source:find('-- Obscura [',1,true) then
    error('[PVH OBF] Expected protected Obscura source for '..selected.name,0)
end

-- Universal session policy (Auto Save + teleport Autoexec).
-- Kept independent from gameplay sources, so new Obsidian ports inherit it.
local previousPersistence=genv.PVH_Persistence
if type(previousPersistence)=='table' and type(previousPersistence.Stop)=='function' then
    pcall(function()previousPersistence:Stop()end)
end
genv.PVH_Persistence=nil
local persistence
local persistenceOK,persistenceResult=pcall(function()
    local moduleURL='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/PVH_Persistence.lua'
    local body=game:HttpGet(moduleURL..'?pvht='..tostring(os.time()))
    local factory,loadErr=loadstring(body)
    if not factory then error(loadErr) end
    local constructor=factory()
    if type(constructor)~='function' then error('Persistence constructor unavailable') end
    local nativeFiles={
        ['Storm Suite']='primevoid_hub/Storm_Suite/Config/settings.json',
        ['Exu Security Lab']='primevoid_hub/Exu_Security_Lab/Configs/ui_settings.json',
        ['Huntress']='primevoid_hub/Huntress/Configs/ui_settings.json',
        ['Dont Splash Explorer']='primevoid_hub/Dont_Splash/Configs/ui_settings.json',
        ['Destruction Simulator']='primevoid_hub/Destruction_Simulator/Configs/ui_settings.json',
        ['Grau SP']='primevoid_hub/Grau_SP/Configs/settings.json',
        ['Clover Legends']='primevoid_hub/Clover_Legends/Configs/ui_settings.json',
        ['Steal a Brainrot']='primevoid_hub/Steal_Brainrot/Configs/ui_settings.json',
        ['RIVALS']='primevoid_hub/RIVALS/Configs/ui_settings.json',
    }
    local instance=constructor({
        port=selected.name,
        nativeConfig=nativeFiles[selected.name],
        loaderUrl='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Loader.lua',
        carryAutoexec=carriedPort~=nil and carriedPort.name==selected.name and carry.autoexec==true,
        originUniverse=carriedPort and carriedPort.name==selected.name and carry.originUniverse or universeId,
    })
    instance:BeforePort()
    return instance
end)
if persistenceOK then
    persistence=persistenceResult
    genv.PVH_Persistence=persistence
else
    warn('[PVH Common] Persistence unavailable, port starts unchanged: '..tostring(persistenceResult))
end
-- When Auto Save is disabled, ignore legacy native settings.json on this run.
-- Named profiles and unrelated user files remain available to the port.
if persistence and persistence.AutoSave==false then
    local noLegacyConfig=[=[
local __pvh_isfile=isfile
local __pvh_readfile=readfile
local function __pvh_legacy_settings(path)
    if type(path)~='string' then return false end
    local normalized=path:gsub('\\','/')
    return normalized:match('/Config/settings%.json$')~=nil
        or normalized:match('/Configs/ui_settings%.json$')~=nil
end
local isfile=function(path)
    if __pvh_legacy_settings(path) then return false end
    return type(__pvh_isfile)=='function' and __pvh_isfile(path) or false
end
local readfile=function(path)
    if __pvh_legacy_settings(path) then
        error('PVH Auto Save disabled: default settings are used',0)
    end
    if type(__pvh_readfile)=='function' then return __pvh_readfile(path) end
    error('readfile unavailable',0)
end
]=]
    source=noLegacyConfig..source
end

-- Prepatched Exu sources include PVH_GIFTS_MAIN_UI but do not initialize
-- PVEXU_GiftsPrefs themselves. The normal loader initializes this object
-- BEFORE executing the port. Mirror that contract for the protected test.
if selected.name=='Exu Security Lab' then
    local giftEnv=(type(getgenv)=='function' and getgenv()) or _G
    local resumeGift=giftEnv.PVEXU_GiftsResume
    if type(giftEnv.PVEXU_GiftsPrefs)~='table' then
        giftEnv.PVEXU_GiftsPrefs={
            collect=type(resumeGift)=='table' and resumeGift.collect==true or false,
            hop=type(resumeGift)=='table' and resumeGift.hop==true or false,
        }
    end
end

local chunk,compileError=loadstring(source)
if not chunk then
    if not previousLog then genv.PV_Hub_AnalyticsSent=nil end
    error('[Prime Void Hub] Erro ao compilar '..selected.name..': '..tostring(compileError),0)
end
local success,runtimeError=pcall(chunk)
if not success then
    if not previousLog then genv.PV_Hub_AnalyticsSent=nil end
    error('[Prime Void Hub] Erro em '..selected.name..': '..tostring(runtimeError),0)
end
if persistence then
    local okPersist,errPersist=pcall(function()persistence:AfterPort()end)
    if not okPersist then warn('[PVH Common] Post-load error: '..tostring(errPersist)) end
end

-- Exu maintenance lock: load the normal protected port, but leave Auto Farm
-- visibly disabled. All other Obsidian controls retain their normal behavior.
-- Protect SetValue as well: universal Auto Save restores saved toggles asynchronously.
if selected.name=='Exu Security Lab' then
    local maintenanceText='UNDER MAINTENANCE — DETECTED'
    local function lockExuFarm()
        local lib=genv.Library
        if type(lib)~='table' or lib.Unloaded then return false end
        local toggles=lib.Toggles or genv.Toggles
        local farm=type(toggles)=='table' and toggles.PVEXU_AutoFarm or nil
        if type(farm)~='table' or type(farm.SetDisabled)~='function'
            or type(farm.SetValue)~='function' or typeof(farm.Holder)~='Instance' then
            return false
        end
        if farm.PVH_MaintenanceLocked then return true end
        farm.PVH_MaintenanceLocked=true

        local oldSetValue=farm.SetValue
        local oldSetDisabled=farm.SetDisabled
        local oldCallback=farm.Callback
        -- First stop any active farm before disabling UI callbacks.
        pcall(function() oldSetValue(farm,false) end)
        farm.Callback=function(value,...)
            if value==true then return end
            if type(oldCallback)=='function' then
                return oldCallback(value,...)
            end
        end
        farm.SetValue=function(self,value)
            if value==true then
                if self.Value==true then return oldSetValue(self,false) end
                return
            end
            return oldSetValue(self,false)
        end
        farm:SetDisabled(true)
        farm.SetDisabled=function(self,_) return oldSetDisabled(self,true) end
        pcall(function() farm:SetText('Auto Farm Exus [MAINTENANCE]') end)
        farm.Risky=true
        pcall(function()
            farm.TextLabel.TextColor3=Color3.fromRGB(255,105,105)
        end)

        -- A transparent child handles mouse hover and touchscreen taps.
        -- The toggle itself stays disabled by Obsidian and cannot be activated.
        local overlay=Instance.new('TextButton')
        overlay.Name='PVH_ExuFarmMaintenance'
        overlay.BackgroundTransparency=1
        overlay.BorderSizePixel=0
        overlay.Text=''
        overlay.AutoButtonColor=false
        overlay.Active=true
        overlay.Selectable=false
        overlay.Size=UDim2.fromScale(1,1)
        overlay.Position=UDim2.fromScale(0,0)
        overlay.ZIndex=farm.Holder.ZIndex+5
        overlay.Parent=farm.Holder
        local okTooltip,tooltip=pcall(function()
            return lib:AddTooltip(nil,maintenanceText,overlay)
        end)
        if okTooltip and type(tooltip)=='table' then
            tooltip.Disabled=true
        end
        overlay.Activated:Connect(function()
            pcall(function()
                lib:Notify({Title='Prime Void Hub',Description=maintenanceText,Time=5})
            end)
        end)
        warn('[PVH Exu] Auto Farm disabled: '..maintenanceText)
        return true
    end

    local locked=false
    for _=1,30 do
        local ok,result=pcall(lockExuFarm)
        if ok and result then locked=true break end
        task.wait(0.1)
    end
    if not locked then
        -- Fail closed: do not leave an accessible Auto Farm when the UI changed.
        warn('[PVH Exu] Maintenance lock unavailable; refusing to enable this port.')
        pcall(function()
            if type(genv.Library)=='table' then genv.Library:Unload() end
        end)
        return
    end
end

-- Exu no-eligible-target hop override. UI stays in the existing Farm panel.
-- Protected Obscura sources are left untouched; the old loop is disabled.
if selected.name=='Exu Security Lab' then
    task.spawn(function()
        local okHop,errHop=pcall(function()
            local url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/PVH_ExuAutoHop.lua'
            local chunk,compileError=loadstring(game:HttpGet(url..'?t='..tostring(os.time())))
            if not chunk then error(compileError) end
            local setup=chunk()
            if type(setup)=='function' then setup() end
        end)
        if not okHop then warn('[PVH EXU HOP] initialization failed: '..tostring(errHop)) end
    end)
end

-- Safe integrated read-only feature diagnostics.
-- Does not enable Auto Farm, TP, combat, ESP or any gameplay feature.
task.spawn(function()
    local okChecker,errChecker=pcall(function()
        local url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/PVH_Checker.lua'
        local chunk,err=loadstring(game:HttpGet(url..'?t='..tostring(os.time())))
        if not chunk then error(err) end
        local construct=chunk()
        if type(construct)=='function' then construct(selected.name) end
    end)
    if not okChecker then warn('[PVH CHECKER] initialization failed: '..tostring(errChecker)) end
end)

-- Shared PT-BR/EN localization for legacy UI labels across every port.
-- The port's saved language remains authoritative; no new language setting.
task.spawn(function()
    local okLocale,errLocale=pcall(function()
        local url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/PVH_Locale.lua'
        local chunk,compileErr=loadstring(game:HttpGet(url..'?t='..tostring(os.time())))
        if not chunk then error(compileErr) end
        local setup=chunk()
        if type(setup)=='function' then setup(selected.name) end
    end)
    if not okLocale then warn('[PVH Locale] initialization: '..tostring(errLocale)) end
end)

-- PVH_UX_UNIVERSAL_V1 - all supported ports: mobile restore, native minus, player avatar.
-- Only touches runtime UI instances. Never modifies fetched or obfuscated sources.
do
    local uxPort = selected.name
    local previousUxCleanup = genv.PVH_UX_UniversalCleanup
    if type(previousUxCleanup) == 'function' then
        pcall(previousUxCleanup)
    end
    genv.PVH_UX_UniversalCleanup = nil

    if type(uxPort) == 'string' then
        task.spawn(function()
            local okUx, errUx = pcall(function()
                local PlayersUX = game:GetService('Players')
                local UISUX = game:GetService('UserInputService')
                local localPlayerUX = PlayersUX.LocalPlayer
                if not localPlayerUX then return end

                local libraryUX, mainUX
                local usedGuiFallbackUX = false
                local function activateGuiFallback(screen, main)
                    if typeof(screen) ~= 'Instance' or not screen:IsA('ScreenGui')
                        or typeof(main) ~= 'Instance' or not main:IsA('GuiObject')
                        or not main.Parent or not screen.Parent then
                        return false
                    end
                    mainUX = main
                    usedGuiFallbackUX = true
                    libraryUX = {
                        ScreenGui = screen,
                        Window = { MainFrame = main },
                        Toggled = main.Visible,
                        Animations = { ToggleWindow = false },
                    }
                    function libraryUX.Window:Toggle(value)
                        local show
                        if typeof(value) == 'boolean' then
                            show = value
                        else
                            show = not libraryUX.Toggled
                        end
                        main.Visible = show
                        libraryUX.Toggled = show
                    end
                    function libraryUX:Toggle(value)
                        return self.Window:Toggle(value)
                    end
                    return true
                end

                local function findNativeObsidian()
                    local roots = {}
                    local pg = localPlayerUX:FindFirstChildOfClass('PlayerGui')
                    if pg then roots[#roots+1] = pg end
                    local okCore, core = pcall(function()
                        return game:GetService('CoreGui')
                    end)
                    if okCore and core then roots[#roots+1] = core end
                    local okHui, hui = pcall(function()
                        return type(gethui) == 'function' and gethui() or nil
                    end)
                    if okHui and typeof(hui) == 'Instance' then
                        roots[#roots+1] = hui
                    end
                    for _, root in ipairs(roots) do
                        local okDesc, descendants = pcall(function()
                            return root:GetDescendants()
                        end)
                        if okDesc and type(descendants) == 'table' then
                            for _, screen in ipairs(descendants) do
                                if screen:IsA('ScreenGui') and screen.Name == 'Obsidian'
                                    and screen.Parent then
                                    local main = screen:FindFirstChild('Main')
                                    if main and main:IsA('GuiObject') and main.Parent then
                                        return screen, main
                                    end
                                end
                            end
                        end
                    end
                    return nil, nil
                end

                for attempt = 1, 100 do
                    if genv.PV_Hub_ActivePort ~= uxPort then return end
                    local candidate = genv.Library
                    local destructionGui = uxPort == 'Destruction Simulator'
                        and genv.PVDS_ScreenGui or nil
                    local validLibrary = type(candidate) == 'table'
                        and not candidate.Unloaded
                        and typeof(candidate.ScreenGui) == 'Instance'
                        and type(candidate.Window) == 'table'
                        and typeof(candidate.Window.MainFrame) == 'Instance'
                        and candidate.ScreenGui.Parent
                        and candidate.Window.MainFrame.Parent
                    if validLibrary and (not destructionGui
                        or candidate.ScreenGui == destructionGui) then
                        libraryUX = candidate
                        mainUX = candidate.Window.MainFrame
                        break
                    end
                    if uxPort == 'Destruction Simulator'
                        and typeof(destructionGui) == 'Instance'
                        and destructionGui:IsA('ScreenGui')
                        and destructionGui.Parent then
                        local nativeMain = destructionGui:FindFirstChild('Main', true)
                        if nativeMain and activateGuiFallback(destructionGui, nativeMain) then
                            break
                        end
                    end
                    if attempt % 4 == 1 then
                        local visualGui, visualMain = findNativeObsidian()
                        if visualGui and activateGuiFallback(visualGui, visualMain) then
                            break
                        end
                    end
                    task.wait(0.12)
                end
                if not libraryUX or not mainUX then
                    warn('[PVH UX UNIVERSAL] Obsidian window not found for '..uxPort..
                        ' | PVDS_ScreenGui='..tostring(typeof(genv.PVDS_ScreenGui)))
                    return
                end
                if usedGuiFallbackUX then
                    warn('[PVH UX UNIVERSAL] GUI compatibility fallback: '..uxPort)
                end

                local connections = {}
                local gone = false
                local cleanup
                local function listen(signal, callback)
                    local connection = signal:Connect(callback)
                    connections[#connections + 1] = connection
                    return connection
                end
                local playerGuiUX = localPlayerUX:FindFirstChildOfClass('PlayerGui')
                    or localPlayerUX:WaitForChild('PlayerGui', 5)
                local oldToggle = libraryUX.Window.Toggle
                local wrappedToggle
                local miniGui
                local headerButton
                local avatarButton
                local watched = {}
                -- PVH_HOME_ROSTER_V2: restore the previous Home rows on re-run.
                local rosterOriginalVisible = {}
                local rosterOriginalText = {}
                local rosterCreated = {}
                local rosterContainer = nil
                local cloverPortrait = nil

                cleanup = function()
                    if gone then return end
                    gone = true
                    for _, connection in ipairs(connections) do
                        pcall(function() connection:Disconnect() end)
                    end
                    for node, originalVisible in pairs(watched or {}) do
                        if typeof(node) == 'Instance' and node.Parent then
                            pcall(function() node.Visible = originalVisible end)
                        end
                    end
                    for _, row in ipairs(rosterCreated) do
                        pcall(function() row:Destroy() end)
                    end
                    for node, originalVisible in pairs(rosterOriginalVisible) do
                        if typeof(node) == 'Instance' and node.Parent then
                            pcall(function() node.Visible = originalVisible end)
                        end
                    end
                    for node, originalText in pairs(rosterOriginalText) do
                        if typeof(node) == 'Instance' and node.Parent then
                            pcall(function() node.Text = originalText end)
                        end
                    end
                    if libraryUX.Window and libraryUX.Window.Toggle == wrappedToggle then
                        libraryUX.Window.Toggle = oldToggle
                    end
                    if miniGui then pcall(function() miniGui:Destroy() end) end
                    if headerButton then pcall(function() headerButton:Destroy() end) end
                    if cloverPortrait then pcall(function() cloverPortrait:Destroy() end) end
                    if genv.PVH_UX_UniversalCleanup == cleanup then
                        genv.PVH_UX_UniversalCleanup = nil
                    end
                end
                genv.PVH_UX_UniversalCleanup = cleanup

                if type(libraryUX.Animations) == 'table' then
                    libraryUX.Animations.ToggleWindow = false
                end

                -- Independent ScreenGui: the Obsidian overlay cannot swallow mobile taps.
                miniGui = Instance.new('ScreenGui')
                miniGui.Name = 'PVH_UniversalMobileRestore'
                miniGui.IgnoreGuiInset = true
                miniGui.ResetOnSpawn = false
                miniGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                miniGui.DisplayOrder = math.max(10000, libraryUX.ScreenGui.DisplayOrder + 50)
                miniGui.Parent = libraryUX.ScreenGui.Parent

                avatarButton = Instance.new('ImageButton')
                avatarButton.Name = 'PVH_RestoreAvatar'
                avatarButton.BackgroundColor3 = Color3.fromRGB(31, 27, 43)
                avatarButton.BorderSizePixel = 0
                avatarButton.Size = UDim2.fromOffset(54, 54)
                avatarButton.Position = UDim2.new(0, 18, 0.5, -27)
                avatarButton.Visible = false
                avatarButton.Active = true
                avatarButton.AutoButtonColor = true
                avatarButton.ScaleType = Enum.ScaleType.Crop
                avatarButton.Image = string.format(
                    'rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150',
                    localPlayerUX.UserId
                )
                avatarButton.Parent = miniGui
                local avatarCorner = Instance.new('UICorner')
                avatarCorner.CornerRadius = UDim.new(0, 13)
                avatarCorner.Parent = avatarButton

                task.spawn(function()
                    for _ = 1, 4 do
                        if gone or not avatarButton.Parent then return end
                        local ok, image, ready = pcall(function()
                            return PlayersUX:GetUserThumbnailAsync(
                                localPlayerUX.UserId,
                                Enum.ThumbnailType.HeadShot,
                                Enum.ThumbnailSize.Size150x150
                            )
                        end)
                        if ok and ready and type(image) == 'string' and image ~= '' then
                            avatarButton.Image = image
                            return
                        end
                        task.wait(0.75)
                    end
                end)

                -- The rightmost ~49 px of the native Obsidian title bar are unused.
                headerButton = Instance.new('TextButton')
                headerButton.Name = 'PVH_HeaderMinimize'
                headerButton.AnchorPoint = Vector2.new(1, 0)
                headerButton.Position = UDim2.new(1, -12, 0, 10)
                headerButton.Size = UDim2.fromOffset(29, 27)
                headerButton.BackgroundTransparency = 1
                headerButton.TextColor3 = Color3.fromRGB(198, 195, 208)
                headerButton.Text = '−'
                headerButton.Font = Enum.Font.GothamMedium
                headerButton.TextSize = 20
                headerButton.AutoButtonColor = true
                headerButton.Active = true
                headerButton.ZIndex = 50
                headerButton.Parent = mainUX

                -- The Obsidian's MoveIcon is an ImageLabel under TopBar.
                -- Search by its unique right-edge position instead of the
                -- TopBar's exact Size (which can change at runtime).
                -- MoveIcon is decorative: do not disable TopBar dragging.
                local function hideObsidianMoveIcon()
                    for _, candidate in ipairs(mainUX:GetDescendants()) do
                        if candidate:IsA('ImageLabel')
                            and candidate.AnchorPoint == Vector2.new(1, 0.5)
                            and candidate.Position.X.Scale == 1
                            and candidate.Position.X.Offset == -10
                            and candidate.Position.Y.Scale == 0.5
                            and candidate.Size.X.Offset <= 34
                            and candidate.Size.Y.Offset <= 34
                            and candidate:IsDescendantOf(mainUX)
                            and candidate.Parent
                            and candidate.Parent:IsA('GuiObject') then
                            candidate.Visible = false
                            -- Place our minus inside the native TopBar, exactly
                            -- where the arrows used to be (same layout on mobile).
                            if headerButton.Parent ~= candidate.Parent then
                                headerButton.Parent = candidate.Parent
                            end
                            headerButton.AnchorPoint = Vector2.new(1, 0.5)
                            headerButton.Position = UDim2.new(1, -10, 0.5, 0)
                            headerButton.Size = UDim2.fromOffset(28, 28)
                            headerButton.ZIndex = math.max(50, candidate.ZIndex + 1)
                            return true
                        end
                    end
                    return false
                end
                if not hideObsidianMoveIcon() then
                    warn('[PVH UX UNIVERSAL] Icone move da Obsidian nao encontrado para ocultar')
                end

                -- Keep the old mini launchers hidden so a single avatar works
                -- across all supported ports, including ports with different UI names.
                local function oldLauncher(node)
                    if not node or not node:IsA('GuiButton')
                        or node == avatarButton or node == headerButton
                        or node:IsDescendantOf(mainUX) then
                        return false
                    end
                    local name = node.Name:lower()
                    local screen = node:FindFirstAncestorOfClass('ScreenGui')
                    if not screen then return false end
                    local screenName = screen.Name:lower()
                    local portScreen = screen == libraryUX.ScreenGui
                        or screenName:find('prime',1,true)
                        or screenName:find('pvh',1,true)
                        or screenName:find('pvds',1,true)
                        or screenName:find('storm',1,true)
                        or screenName:find('huntress',1,true)
                        or screenName:find('clover',1,true)
                        or screenName:find('splash',1,true)
                        or screenName:find('exu',1,true)
                        or screenName:find('destruction',1,true)
                    if not portScreen then return false end
                    if node:FindFirstChild('PVHubMiniAvatar')
                        or node:FindFirstChild('GitHubAvatar') then return true end
                    local known = name == 'stormmini' or name == 'pvhubmini'
                        or name == 'miniicon' or name == 'iconbutton'
                        or name:find('minimizeicon',1,true)
                        or name:find('minimizedicon',1,true)
                        or name:find('floatingicon',1,true)
                    if not known then
                        known = name:find('mini',1,true)
                            or name:find('floating',1,true)
                    end
                    if not known then return false end
                    local size = node.AbsoluteSize
                    local w = size.X > 0 and size.X or node.Size.X.Offset
                    local h = size.Y > 0 and size.Y or node.Size.Y.Offset
                    return w <= 100 and h <= 100 and w >= 20 and h >= 20
                end
                local function suppressOne(node)
                    if not oldLauncher(node) or watched[node] ~= nil then return end
                    watched[node] = node.Visible
                    node.Visible = false
                    listen(node:GetPropertyChangedSignal('Visible'), function()
                        if not gone and node.Parent and node.Visible then
                            node.Visible = false
                        end
                    end)
                end
                local function suppressLegacy(root)
                    if typeof(root) ~= 'Instance' then return end
                    suppressOne(root)
                    local okDesc, descendants = pcall(function()
                        return root:GetDescendants()
                    end)
                    if okDesc and type(descendants) == 'table' then
                        for _, node in ipairs(descendants) do
                            suppressOne(node)
                        end
                    end
                end


                -- The loader owns the canonical port list; legacy ports may
                -- still draw only 2 or 3 items. Change just this Home groupbox,
                -- not gameplay, library sources, or other Home groupboxes.
                local function findPortsGroupContainer()
                    if not libraryUX.ScreenGui or not libraryUX.ScreenGui.Parent then
                        return nil
                    end
                    for _, label in ipairs(libraryUX.ScreenGui:GetDescendants()) do
                        if label:IsA('TextLabel') and type(label.Text) == 'string' then
                            local title = label.Text:lower()
                            local isPortsHeader = (title:find('ports',1,true)
                                and (title:find('dispon',1,true)
                                    or title:find('available',1,true)))
                                or title:find('jogos suportados',1,true)
                                or title:find('supported games',1,true)
                            if isPortsHeader then
                                local textFrame = label.Parent
                                local topBar = textFrame and textFrame.Parent
                                local groupHolder = topBar and topBar.Parent
                                if groupHolder and groupHolder:IsA('Frame')
                                    and topBar:IsA('Frame') then
                                    for _, child in ipairs(groupHolder:GetChildren()) do
                                        if child:IsA('ScrollingFrame')
                                            and child.LayoutOrder == 2 then
                                            return child
                                        end
                                    end
                                end
                            end
                        end
                    end
                    return nil
                end

                local function removeDestructionTestLabels()
                    if uxPort ~= 'Destruction Simulator' then return end
                    for _, node in ipairs(libraryUX.ScreenGui:GetDescendants()) do
                        if node:IsA('TextLabel')
                            and node.Text:find('Destruction Simulator',1,true)
                            and node.Text:find('TEST',1,true) then
                            if rosterOriginalText[node] == nil then
                                rosterOriginalText[node] = node.Text
                            end
                            -- Only visual labels: never modify the signed or
                            -- obfuscated source, logs, or feature names.
                            local clean = node.Text:gsub(' — TEST','')
                                :gsub(' %- TEST','')
                                :gsub(' TEST','')
                            node.Text = clean
                        end
                    end
                end

                local function updateHomeRoster()
                    if gone or not mainUX.Parent then return false end
                    local container = findPortsGroupContainer()
                    if not container then return false end
                    if rosterContainer == container and #rosterCreated == #ports
                        and rosterCreated[1] and rosterCreated[1].Parent == container then
                        return true
                    end

                    -- Rebuild atomically if the UI was recreated.
                    for _, row in ipairs(rosterCreated) do
                        pcall(function() row:Destroy() end)
                    end
                    table.clear(rosterCreated)
                    for label, visible in pairs(rosterOriginalVisible) do
                        if label.Parent then label.Visible = visible end
                    end
                    table.clear(rosterOriginalVisible)

                    local sample = nil
                    for _, node in ipairs(container:GetChildren()) do
                        if node:IsA('TextLabel') then
                            if not sample then sample = node end
                            rosterOriginalVisible[node] = node.Visible
                            node.Visible = false
                        end
                    end

                    for index, port in ipairs(ports) do
                        local row = Instance.new('TextLabel')
                        row.Name = 'PVH_HomePort_'..tostring(index)
                        row.BackgroundTransparency = 1
                        row.BorderSizePixel = 0
                        row.Size = UDim2.new(1, 0, 0, 18)
                        row.TextSize = sample and sample.TextSize or 14
                        row.FontFace = sample and sample.FontFace
                            or Font.fromEnum(Enum.Font.Code)
                        row.TextColor3 = sample and sample.TextColor3
                            or Color3.fromRGB(235, 235, 235)
                        row.TextTransparency = sample and sample.TextTransparency or 0
                        row.TextXAlignment = Enum.TextXAlignment.Left
                        row.TextYAlignment = Enum.TextYAlignment.Center
                        row.TextWrapped = false
                        row.LayoutOrder = 100 + index
                        local dot = port.name == 'Dont Splash Explorer' and '🟡' or '🟢'
                        row.Text = dot..port.officialName
                        row.Parent = container
                        rosterCreated[#rosterCreated + 1] = row
                    end
                    rosterContainer = container
                    removeDestructionTestLabels()
                    return true
                end

                task.spawn(function()
                    for attempt = 1, 100 do
                        if gone or genv.PV_Hub_ActivePort ~= uxPort then return end
                        local okRoster, updated = pcall(updateHomeRoster)
                        if okRoster and updated then
                            warn('[PVH HOME] Roster synced ('..tostring(#ports)..' ports): '..uxPort)
                            return
                        end
                        if not okRoster and attempt == 1 then
                            warn('[PVH HOME] Roster scan: '..tostring(updated))
                        end
                        task.wait(0.12)
                    end
                    warn('[PVH HOME] Ports group not found: '..uxPort)
                end)

                -- Clover's Home account card gets the same player portrait used
                -- by the universal minimize/restore avatar. Safe no-op on other ports.
                if uxPort == 'Clover Legends' then
                    task.spawn(function()
                        for _=1,50 do
                            if gone or not libraryUX.ScreenGui or not libraryUX.ScreenGui.Parent then return end
                            if cloverPortrait and cloverPortrait.Parent then return end
                            for _, label in ipairs(libraryUX.ScreenGui:GetDescendants()) do
                                if label:IsA('TextLabel')
                                    and (label.Text == 'Conta' or label.Text == 'Account') then
                                    local titleFrame = label.Parent
                                    local topBar = titleFrame and titleFrame.Parent
                                    local groupHolder = topBar and topBar.Parent
                                    if groupHolder and groupHolder:IsA('Frame') then
                                        for _, area in ipairs(groupHolder:GetChildren()) do
                                            if area:IsA('ScrollingFrame') and area.LayoutOrder == 2 then
                                                local portrait = Instance.new('ImageLabel')
                                                portrait.Name = 'PVH_CloverAccountAvatar'
                                                portrait.BackgroundTransparency = 1
                                                portrait.BorderSizePixel = 0
                                                portrait.Size = UDim2.fromOffset(64,64)
                                                portrait.LayoutOrder = -50
                                                portrait.ScaleType = Enum.ScaleType.Crop
                                                portrait.Image = string.format(
                                                    'rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150',
                                                    localPlayerUX.UserId
                                                )
                                                local corner = Instance.new('UICorner')
                                                corner.CornerRadius = UDim.new(0,10)
                                                corner.Parent = portrait
                                                portrait.Parent = area
                                                cloverPortrait = portrait
                                                return
                                            end
                                        end
                                    end
                                end
                            end
                            task.wait(0.15)
                        end
                    end)
                end

                local function sync()
                    if gone or not mainUX.Parent then return end
                    if usedGuiFallbackUX then
                        libraryUX.Toggled = mainUX.Visible
                    end
                    suppressLegacy(libraryUX.ScreenGui)
                    suppressLegacy(playerGuiUX)
                    suppressLegacy(libraryUX.ScreenGui.Parent)
                    avatarButton.Visible = (libraryUX.Toggled ~= true) or not mainUX.Visible
                end

                -- Storm currently tracks a separate "minimized" flag. If that flag
                -- desynchronizes after using this button, treat the next explicit
                -- Window:Toggle(boolean) request as a toggle, not a no-op.
                wrappedToggle = function(self, desired)
                    if type(libraryUX.Animations) == 'table' then
                        libraryUX.Animations.ToggleWindow = false
                    end
                    if uxPort == 'Storm Suite' and type(desired) == 'boolean'
                        and desired == libraryUX.Toggled then
                        desired = not desired
                    end
                    local result = oldToggle(self, desired)
                    task.defer(sync)
                    return result
                end
                libraryUX.Window.Toggle = wrappedToggle

                listen(headerButton.Activated, function()
                    if gone then return end
                    libraryUX:Toggle(false)
                    sync()
                end)
                listen(avatarButton.Activated, function()
                    if gone or not avatarButton.Parent then return end
                    if avatarButton:GetAttribute('PVH_JustDragged') then return end
                    libraryUX:Toggle(true)
                    if libraryUX.Toggled == true and mainUX.Parent then
                        mainUX.Visible = true
                    end
                    sync()
                end)

                -- Touch/mouse dragging with pointer release anywhere on screen.
                local drag, origin, originalPosition, dragged
                local function release(input)
                    if not drag then return end
                    if drag.UserInputType == Enum.UserInputType.Touch then
                        if input ~= drag then return end
                    elseif input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                        return
                    end
                    drag = nil
                    origin = nil
                    originalPosition = nil
                    if dragged then
                        avatarButton:SetAttribute('PVH_JustDragged', true)
                        task.delay(0.25, function()
                            if not gone and avatarButton.Parent then
                                avatarButton:SetAttribute('PVH_JustDragged', false)
                            end
                        end)
                    end
                end
                listen(avatarButton.InputBegan, function(input)
                    if input.UserInputType ~= Enum.UserInputType.Touch
                        and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                        return
                    end
                    drag = input
                    origin = input.Position
                    originalPosition = avatarButton.Position
                    dragged = false
                    avatarButton:SetAttribute('PVH_JustDragged', false)
                end)
                listen(UISUX.InputChanged, function(input)
                    if not drag or not origin or not originalPosition then return end
                    if drag.UserInputType == Enum.UserInputType.Touch then
                        if input ~= drag then return end
                    elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
                        return
                    end
                    local delta = input.Position - origin
                    if delta.Magnitude >= 10 then
                        dragged = true
                        avatarButton:SetAttribute('PVH_JustDragged', true)
                    end
                    if not dragged then return end
                    local parentSize = workspace.CurrentCamera
                        and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
                    local x = originalPosition.X.Scale * parentSize.X
                        + originalPosition.X.Offset + delta.X
                    local y = originalPosition.Y.Scale * parentSize.Y
                        + originalPosition.Y.Offset + delta.Y
                    x = math.clamp(x, 0, math.max(0, parentSize.X - avatarButton.AbsoluteSize.X))
                    y = math.clamp(y, 0, math.max(0, parentSize.Y - avatarButton.AbsoluteSize.Y))
                    avatarButton.Position = UDim2.fromOffset(x, y)
                end)
                listen(UISUX.InputEnded, release)
                listen(UISUX.WindowFocusReleased, function()
                    drag = nil
                    origin = nil
                    originalPosition = nil
                end)

                listen(mainUX:GetPropertyChangedSignal('Visible'), function()
                    task.defer(sync)
                end)
                listen(libraryUX.ScreenGui.DescendantAdded, function(node)
                    task.defer(function() suppressLegacy(node) end)
                end)
                if playerGuiUX then
                    listen(playerGuiUX.DescendantAdded, function(node)
                        task.defer(function() suppressLegacy(node) end)
                    end)
                end
                listen(libraryUX.ScreenGui.Destroying, cleanup)
                sync()
                warn('[PVH UX UNIVERSAL] Header − and mobile avatar installed: '..uxPort)
            end)
            if not okUx then
                warn('[PVH UX UNIVERSAL] setup failed: '..tostring(errUx))
            end
        end)
    end
end

-- All ports share the same logger; RIVALS prelogs before executing client code.
-- This prevents an immediate port crash from hiding the launch attempt.
task.spawn(sendUniversalRunLog)


-- Prime Void Hub | Exu gift runtime (no extra windows, no Halloween changes).
-- The primary farm UI is already loaded; this module cannot break the Hub boot.
if selected.name=='Exu Security Lab' then
    task.spawn(function()
        local ok,err=pcall(function()
            local url='https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/exu-gifts.lua'
            local body=game:HttpGet(url)
            -- The protected gifts runtime owns its queue on an intentional gift hop.
            -- Redirect only its loader URL to this already-existing TEST loader.
            -- Do not queue anything at boot or on a voluntary manual join.
            local queueShim=[=[
local __pvhLegacyQueue=(type(queue_on_teleport)=='function' and queue_on_teleport)
    or (type(syn)=='table' and syn.queue_on_teleport)
    or (type(fluxus)=='table' and fluxus.queue_on_teleport)
local queue_on_teleport=type(__pvhLegacyQueue)=='function' and function(payload)
    if type(payload)=='string' then
        payload=payload:gsub(
            'https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Loader.lua',
            'https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/Loader.lua'
        )
    end
    return __pvhLegacyQueue(payload)
end or nil
]=]
            local fn,compileError=loadstring(queueShim..body)
            if not fn then error('Gift engine syntax: '..tostring(compileError)) end
            fn()
        end)
        if not ok then warn('[PVH GIFTS] Runtime unavailable: '..tostring(err)) end
    end)
end
