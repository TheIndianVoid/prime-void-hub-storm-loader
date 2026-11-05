-- Prime Void Hub | Feature Checker v1.0 | TEST ONLY
-- Read-only per-feature health audit: no movement, farm, combat or teleport.
-- A valid UI callback is NOT proof that the action had the intended game effect.
local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local env=(type(getgenv)=="function" and getgenv()) or _G
local MANIFEST_URL="https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/refs/heads/test/all-obfuscated-sources/obfuscated/checker-manifest.json"
local TRANSLATIONS={
    ["pt-BR"]={
        title="Diagnóstico",run="Verificar todas as funções",
        export="Copiar relatório",status="Nenhuma verificação realizada.",
        installed="Estrutura OK",missing="Não encontrado",bad="Problema",
        unable="Não verificável",scope="Efeito real não testado",
        report="Relatório completo no F9; use Copiar relatório.",
        noCopy="Área de transferência indisponível; consulte o F9.",
        summary="Verificação concluída",
    },
    ["en-US"]={
        title="Diagnostics",run="Check all features",
        export="Copy report",status="No checks performed yet.",
        installed="Structure OK",missing="Not found",bad="Problem",
        unable="Unable to verify",scope="Actual effect not tested",
        report="Full report in F9; use Copy report.",
        noCopy="Clipboard unavailable; see F9.",
        summary="Check completed",
    }
}
local PORT_KEYS={
    ["Storm Suite"]="storm",
    ["Huntress"]="huntress",
    ["Exu Security Lab"]="exu",
    ["Destruction Simulator"]="destruction",
    ["Dont Splash Explorer"]="splash",
}

local function getLanguage()
    local preference=env.PVH_Persistence
    if type(preference)=="table" and type(preference.GetLanguage)=="function" then
        local ok,code=pcall(function()return preference:GetLanguage()end)
        if ok and (code=="en-US" or code=="pt-BR") then return code end
    end
    return "pt-BR"
end

local function groupboxTab(library)
    if type(library)~="table" or type(library.Tabs)~="table" then return nil end
    for name,tab in pairs(library.Tabs) do
        local key=tostring(name):lower()
        if key:find("settings",1,true) or key:find("config",1,true)
            or key:find("ajustes",1,true) then
            return tab
        end
    end
    return nil
end

local function enumerateUI(library)
    local buttons, seen={},{}
    local gui=type(library)=="table" and library.ScreenGui or nil
    if typeof(gui)~="Instance" or not gui.Parent then return {},false end
    local ok,nodes=pcall(function()return gui:GetDescendants()end)
    if not ok then return {},false end
    for _,node in ipairs(nodes) do
        if node:IsA("TextButton") and node.Visible and node.Active then
            local candidates={}
            if node.Text and node.Text:match("%S") then
                candidates[#candidates+1]=node.Text
            end
            for _,child in ipairs(node:GetChildren()) do
                if child:IsA("TextLabel") and child.Text and child.Text:match("%S") then
                    candidates[#candidates+1]=child.Text
                end
            end
            for _,label in ipairs(candidates) do
                local clean=label:gsub("%s+"," "):sub(1,100)
                if not seen[clean] then buttons[#buttons+1]=clean seen[clean]=true end
            end
        end
    end
    table.sort(buttons)
    return buttons,true
end

local function canCallback(control)
    return type(control.Callback)=="function" or type(control.Changed)=="function"
end

local function auditControl(feature,registry)
    local id=tostring(feature.id or "")
    local kind=tostring(feature.kind or "Unknown")
    local control=type(registry)=="table" and registry[id] or nil
    if type(control)~="table" then
        return {id=id,kind=kind,status="MISSING",detail="Expected Obsidian control is not registered"}
    end
    if control.Destroyed then
        return {id=id,kind=kind,status="ERROR",detail="Control was destroyed"}
    end
    local actual=tostring(control.Type or kind)
    if kind=="Toggle" and type(control.Value)~="boolean" then
        return {id=id,kind=kind,status="WARNING",detail="Toggle value is not boolean ("..typeof(control.Value)..")"}
    end
    if type(control.SetValue)~="function" then
        return {id=id,kind=kind,status="ERROR",detail="SetValue missing: control cannot be updated"}
    end
    if (kind=="Slider") and (type(control.Min)=="number" and type(control.Max)=="number")
        and control.Min>control.Max then
        return {id=id,kind=kind,status="ERROR",detail="Invalid slider bounds"}
    end
    if (kind=="Dropdown") and type(control.Values)=="table" and #control.Values==0
        and control.SpecialType~="Player" and control.SpecialType~="Team" then
        return {id=id,kind=kind,status="WARNING",detail="Dropdown has no available options"}
    end
    if not canCallback(control) and kind~="KeyPicker" then
        return {id=id,kind=kind,status="WARNING",detail="No callback/Changed handler registered"}
    end
    if control.Disabled==true then
        return {id=id,kind=kind,status="WARNING",detail="Control is currently disabled"}
    end
    return {id=id,kind=kind,status="STRUCTURE_OK",
        detail=actual.." registered; setter and callback available; effect not executed"}
end

local function fetchExpected(portKey)
    local ok,data=pcall(function()
        local body=game:HttpGet(MANIFEST_URL.."?t="..tostring(os.time()))
        return HttpService:JSONDecode(body)
    end)
    if not ok or type(data)~="table" or type(data.ports)~="table" then return nil end
    local value=data.ports[portKey]
    if type(value)=="table" and type(value.controls)=="table" then return value end
    return nil
end

local function keyString(value)
    return tostring(value or "unknown")
end

local function listFromRegistry(registry,kind,known,results)
    if type(registry)~="table" then return end
    for id,control in pairs(registry) do
        local key=keyString(id)
        if not known[key] and key:sub(1,14)~="PVH_UNIVERSAL_" then
            local typename=type(control)=="table" and tostring(control.Type or kind) or kind
            results[#results+1]=auditControl({id=key,kind=typename},registry)
            known[key]=true
        end
    end
end

local function probe(label,available,details,results,essential)
    results[#results+1]={id=label,kind="Environment",
        status=available and "STRUCTURE_OK" or (essential and "ERROR" or "WARNING"),
        detail=details or ""}
end

return function(port)
    port=tostring(port or "")
    local portKey=PORT_KEYS[port] or port:lower():gsub("[^%w_-]","_")
    local running=true
    local lastReport=""
    local lastResults={}
    local label
    local group
    local guiLibrary
    local texts=TRANSLATIONS[getLanguage()] or TRANSLATIONS["pt-BR"]

    local function run()
        local library=env.Library
        local toggles=type(library)=="table" and library.Toggles or env.Toggles
        local options=type(library)=="table" and library.Options or env.Options
        local loaded=fetchExpected(portKey)
        local results,known={},{}
        local sourceKnown=loaded and #loaded.controls or 0

        if type(toggles)~="table" or type(options)~="table" then
            probe("Obsidian registry",false,
                "Toggles/Options not exported; cannot verify per-feature wiring",
                results,true)
        else
            probe("Obsidian registry",true,"Toggles and Options accessible",results,true)
        end
        if loaded then
            for _,feature in ipairs(loaded.controls) do
                local id=tostring(feature.id or "")
                if id~="" and not known[id] then
                    local registry=feature.kind=="Toggle" and toggles or options
                    results[#results+1]=auditControl(feature,registry)
                    known[id]=true
                end
            end
        else
            probe("Source feature manifest",false,
                "Build manifest unavailable; using live control registry only",
                results,false)
        end
        listFromRegistry(toggles,"Toggle",known,results)
        listFromRegistry(options,"Option",known,results)

        local uiButtons,hasUI=enumerateUI(library)
        probe("Obsidian interface",hasUI,
            hasUI and ("UI mounted; "..#uiButtons.." identifiable buttons")
                or "Main UI not accessible",results,true)
        -- Buttons are not stored in Obsidian's Toggle/Option registries.
        -- Verify their labels exist in the UI, never invoke their actions.
        local uiLabels={}
        for _,name in ipairs(uiButtons) do uiLabels[name:lower()]=true end
        if loaded and type(loaded.buttons)=="table" then
            for _,feature in ipairs(loaded.buttons) do
                local labelText=tostring(feature.label or "")
                local found=uiLabels[labelText:lower()]==true
                results[#results+1]={
                    id=tostring(feature.id or "button:"..labelText),kind="Button",
                    status=found and "STRUCTURE_OK" or "UNVERIFIED",
                    detail=found
                        and "Button label found in UI; action not executed"
                        or "Not matched in current UI; localized/conditional buttons may differ",
                }
            end
        end

        local player=Players.LocalPlayer
        probe("LocalPlayer",player~=nil,"Player object loaded",results,true)
        probe("Workspace",workspace~=nil,"Client Workspace available",results,true)
        probe("ReplicatedStorage",RS~=nil,"Roblox service available",results,true)
        local persistence=env.PVH_Persistence
        probe("Auto Save module",type(persistence)=="table"
            and type(persistence.SaveNow)=="function",
            "Persistence component found; file write success is not tested",results,true)
        probe("Autoexec module",type(persistence)=="table"
            and type(persistence.QueueAutoExec)=="function",
            "Queue function found; destination reinjection is not tested",results,true)
        if type(persistence)=="table" then
            probe("Local file API",persistence.HasStorage==true,
                "Needed for Auto Save between runs",results,false)
            probe("Teleport queue API",persistence.HasAutoexec==true,
                "Needed for Autoexec, but not proof of delivery",results,false)
        end

        local counts={STRUCTURE_OK=0,MISSING=0,WARNING=0,ERROR=0,UNVERIFIED=0}
        for _,entry in ipairs(results) do
            counts[entry.status]=(counts[entry.status] or 0)+1
        end
        table.sort(results,function(a,b)
            local ka=tostring(a.kind)..tostring(a.id)
            local kb=tostring(b.kind)..tostring(b.id)
            return ka<kb
        end)
        local metadata={
            schema=1,port=port,placeId=tostring(game.PlaceId),
            universeId=tostring(game.GameId),
            expectedControls=sourceKnown,foundButtons=hasUI and #uiButtons or 0,
            counts=counts,results=results,buttonLabels=uiButtons,
            note="STRUCTURE_OK means only UI registration and callback wiring. "
                .."Gameplay effects, remotes, farm, TP, server hop, combat and ESP "
                .."were NOT executed or verified by this read-only audit.",
        }
        local ok,json=pcall(function()return HttpService:JSONEncode(metadata)end)
        lastReport=ok and json or "Unable to encode diagnostics"
        lastResults=results

        local words=TRANSLATIONS[getLanguage()] or TRANSLATIONS["pt-BR"]
        local summary=string.format("%s: %d OK / %d ausentes / %d avisos / %d erros / %d pendentes",
            words.summary,counts.STRUCTURE_OK,counts.MISSING,
            counts.WARNING,counts.ERROR,counts.UNVERIFIED)
        if label and type(label.SetText)=="function" then
            pcall(function()label:SetText(summary)end)
        end
        warn("[PVH CHECKER] "..port.." | "..summary)
        for _,entry in ipairs(results) do
            warn(string.format("[PVH CHECKER] [%s] %s (%s): %s",
                entry.status,entry.id,entry.kind,entry.detail))
        end
        warn("[PVH CHECKER] "..words.scope.." | "..words.report)
        return metadata
    end

    env.PVH_RunChecker=run
    env.PVH_GetCheckerReport=function()return lastReport,lastResults end

    local function bind()
        local library=env.Library
        local tab=groupboxTab(library)
        if not tab or type(tab.AddGroupbox)~="function" then return false end
        guiLibrary=library
        local words=TRANSLATIONS[getLanguage()] or TRANSLATIONS["pt-BR"]
        local ok,g=pcall(function()
            return tab:AddGroupbox({
                Side="Left",Name=words.title,IconName="list-checks",
            })
        end)
        if not ok or type(g)~="table" then return false end
        group=g
        pcall(function()
            label=g:AddLabel(words.status,true)
            g:AddButton({Text=words.run,Func=function()run()end})
            g:AddButton({Text=words.export,Func=function()
                if lastReport=="" then run()end
                local copy=env.setclipboard or setclipboard or env.toclipboard
                if type(copy)=="function" then
                    local copied=pcall(copy,lastReport)
                    if copied then
                        warn("[PVH CHECKER] Report copied to clipboard")
                    else
                        warn("[PVH CHECKER] "..words.noCopy)
                    end
                else
                    warn("[PVH CHECKER] "..words.noCopy)
                end
            end})
        end)
        return true
    end

    task.spawn(function()
        for _=1,35 do
            if not running then return end
            if bind() then
                task.wait(2)
                -- Run once automatically to identify missing controls even
                -- when the user has not opened the Config tab.
                if running then pcall(run) end
                return
            end
            task.wait(0.4)
        end
        warn("[PVH CHECKER] UI unavailable; run getgenv().PVH_RunChecker()")
        pcall(run)
    end)
    return function()
        running=false
        if env.PVH_RunChecker==run then env.PVH_RunChecker=nil end
    end
end
