-- Prime Void Hub | Feature Checker v1.1 | MAIN
-- Read-only per-feature health audit: no movement, farm, combat or teleport.
-- A valid UI callback is NOT proof that the action had the intended game effect.
local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local env=(type(getgenv)=="function" and getgenv()) or _G
local MANIFEST_URL="https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/main/obfuscated/checker-manifest.json"
local TRANSLATIONS={
    ["pt-BR"]={
        title="Diagnóstico",run="Verificar todas as funções",
        export="Salvar relatório TXT",status="Nenhuma verificação realizada.",
        saved="TXT salvo nos Logs do port",saveFailed="Falha ao salvar TXT nos Logs",
        installed="Estrutura OK",missing="Não encontrado",bad="Problema",
        unable="Não verificável",scope="Efeito real não testado",
        report="Relatório salvo em Logs do port quando houver acesso a arquivos.",
        summary="Verificação concluída",
        missingWord="ausentes",warnWord="avisos",errorWord="erros",pendingWord="pendentes",
    },
    ["en-US"]={
        title="Diagnostics",run="Check all features",
        export="Save TXT report",status="No checks performed yet.",
        saved="TXT saved to port Logs",saveFailed="Could not save TXT to port Logs",
        installed="Structure OK",missing="Not found",bad="Problem",
        unable="Unable to verify",scope="Actual effect not tested",
        report="Detailed report saved to port Logs when file access is available.",
        summary="Check completed",
        missingWord="missing",warnWord="warnings",errorWord="errors",pendingWord="unverified",
    }
}
local PORT_KEYS={
    ["Storm Suite"]="storm",
    ["Huntress"]="huntress",
    ["Exu Security Lab"]="exu",
    ["Destruction Simulator"]="destruction",
    ["Dont Splash Explorer"]="splash",
    ["Grau SP"]="grau_sp",
    ["War Tycoon"]="war_tycoon",
    ["Clover Legends"]="clover",
    ["RIVALS"]="rivals",
    ["Da Hood"]="da_hood",
    ["Roube um Espírito Santo"]="spirit",
    ["Steal a Brainrot"]="steal_a_brainrot",
    ["RATO"]="rato",
    ["Anime RNG Defense"]="anime_rng_defense",
    ["Chicken Farm"]="chicken_farm",
    ["Spin a Car"]="spin_a_car",
    ["Merge a Nuke!"]="merge_a_nuke",
    ["Roll for Anime!"]="roll_for_anime",
    ["Build a Keyboard"]="build_a_keyboard",
    ["2omething evil will happen"]="2omething_evil_will_happen",
    ["Make a Drill Farm"]="make_a_drill_farm",
    ['+1 Clone Evolution']='1_clone_evolution',
    ['+1 Dino Evolution']='1_dino_evolution',
    ['+1 DMG FPS']='1_dmg_fps',
    ['+1 Fart to Break Doors']='1_fart_to_break_doors',
    ['+1 Mog Evolution']='1_mog_evolution',
    ['+1 Slash Per Click!']='1_slash_per_click',
    ['+1 Stone Skipping']='1_stone_skipping',
    ['+1 Strength for Eggs']='1_strength_for_eggs',
    ['+1 Sword vs Anime']='1_sword_vs_anime',
    ['+1 TNT Mining']='1_tnt_mining',
    ['+1 Chop Tree and Ride Pet']='1_cut_and_ride_pet',
    ['+1 Tongue Escape']='1_tongue_escape',
    ['Anomaly Garden']='anomaly_garden',
    ['Become a Billionaire']='become_a_billionaire',
    ['Blow up Lucky Blocks For Cars']='blow_up_lucky_blocks_for_cars',
    ['Break an Egg!']='break_an_egg',
    ['Build Golems and Fight']='build_golems_and_fight',
    ['Collect 1 Million Items']='collect_1_million_items',
    ['Drive-Thru Empire']='drive_thru_empire',
    ['Fruit Zombie Survival']='fruit_zombie_survival',
    ['Jump To Steal An Egg']='jump_to_steal_an_egg',
    ['Lift a Cube']='lift_a_cube',
    ['Make Hotsauce']='make_hotsauce',
    ['Merge a Dino']='merge_a_dino',
    ['Motorcycle for Animals']='motorcycle_for_animals',
    ['My Anime Mine']='my_anime_mine',
    ['My Dino Park!']='my_dino_park',
    ['My Lucky Train']='my_lucky_train',
    ['Open Sea For Animals!']='open_sea_for_animals',
    ['Pets Universe!']='pets_universe',
    ['Race Horses']='race_horses',
    ['Roller for Animals!']='roller_for_animals',
    ['Sail For Eggs']='sail_for_eggs',
    ['Snowcone Stand']='snowcone_stand',
    ['Steal a Giant Egg']='steal_a_giant_egg',
    ['Backrooms Simulator']='backrooms_simulator',
    ['Beat the Anime Boss!']='beat_the_anime_boss',
    ['Brainrot Card Battles']='brainrot_card_battles',
    ['Choose the Stronger Anime!']='choose_the_stronger_anime',
    ['Collect Cars and Race']='collect_cars_and_race',
    ['Fishing Chef']='fishing_chef',
    ['Fishing Wars']='fishing_wars',
    ['Hatch And Fry!']='hatch_and_fry',
    ['Magnet Fishing']='magnet_fishing',
    ['Merge a Squishy']='merge_a_squishy',
    ['Project Aura RNG']='project_aura_rng',
    ['Rescue Animals!']='rescue_animals',
    ['Roll a Sorcerer']='roll_a_sorcerer',
    ['RUNAWAYS']='runaways',
    ['Steal A Lucky Egg']='steal_a_lucky_egg',
    ['+1 Long Arm Toy Escape!']='1_long_arm_toy_escape',
    ['+1 Power Jujutsu Kaisen Evolution']='1_power_jujutsu_kaisen_evolution',
    ['+1 Speedster Escape']='1_speedster_escape',
    ['+1 Spider Evolution']='1_spider_evolution',
    ['+1 Sword Fighting Escape']='1_sword_fighting_escape',
    ['Basketball Dynasty']='basketball_dynasty',
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

local function locateHubGui(library)
    local gui=type(library)=="table" and library.ScreenGui or nil
    if typeof(gui)=="Instance" and gui.Parent then return gui end
    local roots={}
    local player=Players.LocalPlayer
    if player then
        local ui=player:FindFirstChildOfClass("PlayerGui")
        if ui then roots[#roots+1]=ui end
    end
    local ok,coreGui=pcall(function()return game:GetService("CoreGui")end)
    if ok and coreGui then roots[#roots+1]=coreGui end
    local getUI=env.gethui or gethui
    if type(getUI)=="function" then
        local ok2,hidden=pcall(getUI)
        if ok2 and typeof(hidden)=="Instance" then roots[#roots+1]=hidden end
    end
    for _,root in ipairs(roots) do
        local ok3,screens=pcall(function()return root:GetChildren()end)
        if ok3 then
            for _,screen in ipairs(screens) do
                if screen:IsA("ScreenGui") then
                    local name=screen.Name:lower()
                    if name:find("primevoid",1,true) or name:find("pvhub",1,true)
                        or name:find("obsidian",1,true) then
                        return screen
                    end
                    local ok4,desc=pcall(function()return screen:GetDescendants()end)
                    if ok4 then
                        for i=1,math.min(#desc,4000) do
                            local node=desc[i]
                            if node:IsA("TextLabel") then
                                local value=node.Text:lower()
                                if value:find("pv hub",1,true)
                                    or value:find("prime void hub",1,true) then
                                    return screen
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- Obsidian action buttons have a UIStroke directly beneath TextButton,
-- and their TextLabel is inside a child Content Frame. Toggles have direct
-- labels instead, so the old generic TextButton scanner counted toggles as
-- 43 "working buttons". Inspect ALL tabs, including currently hidden ones.
local function enumerateUI(library)
    local buttons,seen={},{}
    local gui=locateHubGui(library)
    if typeof(gui)~="Instance" or not gui.Parent then return {},false end
    local ok,nodes=pcall(function()return gui:GetDescendants()end)
    if not ok then return {},false end
    for _,node in ipairs(nodes) do
        if node:IsA("TextButton") then
            local stroke=node:FindFirstChildOfClass("UIStroke")
            -- Obsidian's Button.Content is a Lua field, not an Instance
            -- named "Content". Find the child Frame that holds its label.
            local content
            if stroke then
                for _,child in ipairs(node:GetChildren()) do
                    if child:IsA("Frame") and child:FindFirstChildOfClass("TextLabel") then
                        content=child
                        break
                    end
                end
            end
            if content then
                local label=content:FindFirstChildOfClass("TextLabel")
                if label and type(label.Text)=="string" and label.Text:match("%S") then
                    local clean=label.Text:gsub("%s+"," "):sub(1,100)
                    local key=clean:lower()
                    if not seen[key] then
                        buttons[#buttons+1]=clean
                        seen[key]=true
                    end
                end
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
    if kind=="Image" or actual=="Image" then
        return {id=id,kind="Image",status="STRUCTURE_OK",
            detail="Decorative image registered; SetValue/callback are not required; visual content not tested"}
    end
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
    local lastText=""
    local lastFilePath=nil
    local lastResults={}
    local label
    local group
    local runButton,copyButton
    local groupIsOwned=false
    local shownLanguage=getLanguage()
    local guiLibrary
    local texts=TRANSLATIONS[getLanguage()] or TRANSLATIONS["pt-BR"]

    -- Store one stable TXT in each port's Logs directory, not workspace root.
    local portDirs={
        storm="Storm_Suite",huntress="Huntress",exu="Exu_Security_Lab",
        destruction="Destruction_Simulator",splash="Dont_Splash",
        grau_sp="Grau_SP",clover="Clover_Legends",rivals="RIVALS",war_tycoon="War_Tycoon",da_hood="Da_Hood",
        spirit="Spirit_Sanctuary",
        steal_a_brainrot="Steal_Brainrot",
        rato="RATO",
        anime_rng_defense="Anime_RNG_Defense",
        chicken_farm="Chicken_Farm",
        spin_a_car="Spin_A_Car",
        merge_a_nuke="Merge_A_Nuke",
        roll_for_anime="Roll_For_Anime",
        build_a_keyboard="Build_A_Keyboard",
        ["2omething_evil_will_happen"]="2omething_Evil",
        make_a_drill_farm="Make_A_Drill_Farm",
        ['1_clone_evolution']='1-clone-evolution',
        ['1_dino_evolution']='1-dino-evolution',
        ['1_dmg_fps']='1-dmg-fps',
        ['1_fart_to_break_doors']='1-fart-to-break-doors',
        ['1_mog_evolution']='1-mog-evolution',
        ['1_slash_per_click']='1-slash-per-click',
        ['1_stone_skipping']='1-stone-skipping',
        ['1_strength_for_eggs']='1-strength-for-eggs',
        ['1_sword_vs_anime']='1-sword-vs-anime',
        ['1_tnt_mining']='1-tnt-mining',
        ['1_cut_and_ride_pet']='1-cut-and-ride-pet',
        ['1_tongue_escape']='1-tongue-escape',
        ['anomaly_garden']='anomaly-garden',
        ['become_a_billionaire']='become-a-billionaire',
        ['blow_up_lucky_blocks_for_cars']='blow-up-lucky-blocks-for-cars',
        ['break_an_egg']='break-an-egg',
        ['build_golems_and_fight']='build-golems-and-fight',
        ['collect_1_million_items']='collect-1-million-items',
        ['drive_thru_empire']='drive-thru-empire',
        ['fruit_zombie_survival']='fruit-zombie-survival',
        ['jump_to_steal_an_egg']='jump-to-steal-an-egg',
        ['lift_a_cube']='lift-a-cube',
        ['make_hotsauce']='make-hotsauce',
        ['merge_a_dino']='merge-a-dino',
        ['motorcycle_for_animals']='motorcycle-for-animals',
        ['my_anime_mine']='my-anime-mine',
        ['my_dino_park']='my-dino-park',
        ['my_lucky_train']='my-lucky-train',
        ['open_sea_for_animals']='open-sea-for-animals',
        ['pets_universe']='pets-universe',
        ['race_horses']='race-horses',
        ['roller_for_animals']='roller-for-animals',
        ['sail_for_eggs']='sail-for-eggs',
        ['snowcone_stand']='snowcone-stand',
        ['steal_a_giant_egg']='steal-a-giant-egg',
        ['backrooms_simulator']='backrooms-simulator',
        ['beat_the_anime_boss']='beat-the-anime-boss',
        ['brainrot_card_battles']='brainrot-card-battles',
        ['choose_the_stronger_anime']='choose-the-stronger-anime',
        ['collect_cars_and_race']='collect-cars-and-race',
        ['fishing_chef']='fishing-chef',
        ['fishing_wars']='fishing-wars',
        ['hatch_and_fry']='hatch-and-fry',
        ['magnet_fishing']='magnet-fishing',
        ['merge_a_squishy']='merge-a-squishy',
        ['project_aura_rng']='project-aura-rng',
        ['rescue_animals']='rescue-animals',
        ['roll_a_sorcerer']='roll-a-sorcerer',
        ['runaways']='runaways',
        ['steal_a_lucky_egg']='steal-a-lucky-egg',
        ['1_long_arm_toy_escape']='1-long-arm-toy-escape',
        ['1_power_jujutsu_kaisen_evolution']='1-power-jujutsu-kaisen-evolution',
        ['1_speedster_escape']='1-speedster-escape',
        ['1_spider_evolution']='1-spider-evolution',
        ['1_sword_fighting_escape']='1-sword-fighting-escape',
        ['basketball_dynasty']='basketball-dynasty',
    }
    local folder="primevoid_hub/"..
        (portDirs[portKey] or portKey:gsub("[^%w_-]","_")).."/Logs"
    local reportPath=folder.."/PVH_Checker_"..portKey..".txt"
    local legacyMoved=false
    local function ensureLogFolder()
        local mk=env.makefolder or makefolder
        if type(mk)~="function" then return false,"makefolder unavailable" end
        local exists=env.isfolder or isfolder
        local partial=""
        for segment in folder:gmatch("[^/]+") do
            partial=partial=="" and segment or partial.."/"..segment
            local present=false
            if type(exists)=="function" then
                local ok,value=pcall(exists,partial)
                present=ok and value==true
            end
            if not present then
                local ok,err=pcall(mk,partial)
                if not ok then
                    local verified=type(exists)=="function" and pcall(function()
                        assert(exists(partial))
                    end)
                    if not verified then return false,tostring(err) end
                end
            end
        end
        -- Archive the old workspace-root report before removing it.
        -- Do not delete anything if copying failed or an archive already exists.
        if not legacyMoved then
            legacyMoved=true
            local old="PVH_Checker_"..portKey..".txt"
            local archive=folder.."/PVH_Checker_"..portKey.."_legacy.txt"
            local exists=env.isfile or isfile
            local read=env.readfile or readfile
            local write=env.writefile or writefile
            local delete=env.delfile or delfile
            if type(exists)=="function" and type(read)=="function"
                and type(write)=="function" and type(delete)=="function" then
                local ok,oldPresent=pcall(exists,old)
                local okNew,archivePresent=pcall(exists,archive)
                if ok and oldPresent and okNew and not archivePresent then
                    local readOK,body=pcall(read,old)
                    if readOK and type(body)=="string" then
                        local savedOK,saved=pcall(write,archive,body)
                        if savedOK and saved~=false then pcall(delete,old) end
                    end
                end
            end
        end
        return true
    end

    local function txtLine(value)
        return tostring(value or ""):gsub("[\r\n]+"," "):sub(1,400)
    end

    local function formatReport(metadata)
        local words=TRANSLATIONS[getLanguage()] or TRANSLATIONS["pt-BR"]
        local pt=getLanguage()~="en-US"
        local nowOk,now=pcall(function()return os.date("!%Y-%m-%d %H:%M:%S UTC")end)
        local created=nowOk and tostring(now) or tostring(os.time())
        local lines={
            "PRIME VOID HUB - "..(pt and "RELATORIO DE FUNCOES" or "FEATURE CHECKER REPORT"),
            string.rep("=",74),
            (pt and "Jogo: " or "Port: ")..txtLine(metadata.port),
            "PlaceId: "..txtLine(metadata.placeId),
            "UniverseId: "..txtLine(metadata.universeId),
            (pt and "Data: " or "Date: ")..created,
            (pt and "Destino: " or "Location: ")..reportPath,
            "",
            pt and "RESUMO" or "SUMMARY",
            string.rep("-",74),
            "STRUCTURE_OK: "..tostring(metadata.counts.STRUCTURE_OK or 0),
            "MISSING: "..tostring(metadata.counts.MISSING or 0),
            "WARNING: "..tostring(metadata.counts.WARNING or 0),
            "ERROR: "..tostring(metadata.counts.ERROR or 0),
            "UNVERIFIED: "..tostring(metadata.counts.UNVERIFIED or 0),
            (pt and "Controles esperados: " or "Expected controls: ")..tostring(metadata.expectedControls),
            "",
            pt and "IMPORTANTE: STRUCTURE_OK verifica apenas a estrutura da interface."
                or "IMPORTANT: STRUCTURE_OK checks UI structure only.",
            pt and "Farms, teleportes, combate, ESP e outros efeitos NAO foram ativados nem comprovados."
                or "Farming, teleportation, combat, ESP and gameplay effects were NOT executed or proven.",
            "",
            pt and "RESULTADO POR FUNCAO" or "PER-FEATURE RESULTS",
            string.rep("=",74),
        }
        local priority={"ERROR","MISSING","WARNING","UNVERIFIED","STRUCTURE_OK"}
        for _,state in ipairs(priority) do
            local group={}
            for _,entry in ipairs(metadata.results) do
                if entry.status==state then group[#group+1]=entry end
            end
            if #group>0 then
                lines[#lines+1]=""
                lines[#lines+1]="["..state.."] "..tostring(#group)
                lines[#lines+1]=string.rep("-",74)
                for _,entry in ipairs(group) do
                    lines[#lines+1]="- "..txtLine(entry.id).." ("..txtLine(entry.kind)..")"
                    lines[#lines+1]="  "..txtLine(entry.detail)
                end
            end
        end
        lines[#lines+1]=""
        lines[#lines+1]=string.rep("=",74)
        return table.concat(lines,"\n").."\n"
    end

    local function saveTXT()
        if lastText=="" then return false,"No report has been generated" end
        local writer=env.writefile or writefile
        if type(writer)~="function" then
            lastFilePath=nil
            warn("[PVH CHECKER] writefile unavailable; cannot save TXT in port Logs")
            return false,"writefile unavailable"
        end
        local folderOK,folderErr=ensureLogFolder()
        if not folderOK then
            lastFilePath=nil
            warn("[PVH CHECKER] Logs folder unavailable: "..tostring(folderErr))
            return false,tostring(folderErr)
        end
        local ok,err=pcall(writer,reportPath,lastText)
        if ok and err~=false then
            lastFilePath=reportPath
            warn("[PVH CHECKER] TXT SAVED: "..reportPath)
            return true,reportPath
        end
        lastFilePath=nil
        warn("[PVH CHECKER] TXT SAVE FAILED: "..tostring(err))
        return false,tostring(err)
    end

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
                    if type(registry)=="table" then
                        results[#results+1]=auditControl(feature,registry)
                    else
                        results[#results+1]={id=id,kind=feature.kind,status="UNVERIFIED",
                            detail="Control registry is inaccessible in this protected port"}
                    end
                    known[id]=true
                end
            end
        else
            probe("Source feature manifest",false,
                "Build manifest unavailable; using live control registry only",
                results,false)
        end
        listFromRegistry(toggles,"Toggle",known,results)
        -- Some source-derived VM ports have an audited control count but no
        -- distributable plaintext ID manifest. Report this limitation rather
        -- than claiming a complete per-feature audit.
        if loaded and type(loaded.metadata)=="table"
            and tonumber(loaded.metadata.originalSourceControlSignatures)
            and #loaded.controls==0 then
            probe("Source control ID coverage",false,
                "Static source signatures="..tostring(loaded.metadata.originalSourceControlSignatures)
                .."; exact source IDs unavailable from protected build. "
                .."Visible registered controls are inspected separately; missing features "
                .."cannot all be identified without a plaintext feature manifest.",
                results,false)
        end
        listFromRegistry(options,"Option",known,results)

        local uiButtons,hasUI=enumerateUI(library)
        probe("Obsidian interface",hasUI,
            hasUI and ("UI mounted; "..#uiButtons.." identifiable buttons")
                or "Main UI not accessible",results,true)
        -- Buttons are not stored in Obsidian's Toggle/Option registries.
        -- Verify their labels exist in the UI, never invoke their actions.
        local uiLabels={}
        for _,name in ipairs(uiButtons) do uiLabels[name:lower()]=true end
        -- Known PT/EN labels from PVH_Locale. Do not infer a missing feature
        -- just because its label was translated by the shared UI layer.
        local buttonAliases={
            ["minimize"]={"minimizar"},
            ["unload"]={"descarregar"},
            ["server hop"]={"trocar de servidor"},
            ["idioma / language"]={"idioma","language"},
            ["abrir servidor do discord"]={"open discord","abrir discord"},
            ["copiar link"]={"copy link"},
            ["criar configuração"]={"create configuration","save config","criar perfil"},
            ["carregar configuração"]={"load config","carregar perfil"},
            ["excluir configuração"]={"delete config","excluir perfil"},
            ["atualizar lista"]={"refresh","refresh list","atualizar"},
            ["sobrescrever configuração"]={"overwrite configuration"},
            ["teleportar à minha base"]={"teleport to my base","teleporte à base"},
        }
        local function buttonPresent(labelText)
            local key=labelText:lower()
            if uiLabels[key] then return true end
            for _,alias in ipairs(buttonAliases[key] or {}) do
                if uiLabels[alias] then return true end
            end
            return false
        end
        -- Capture every action button actually present, including dynamically
        -- generated controls absent from static source signatures.
        local discoveredButtons={}
        for _,name in ipairs(uiButtons) do discoveredButtons[name:lower()]=name end
        if loaded and type(loaded.buttons)=="table" then
            for _,feature in ipairs(loaded.buttons) do
                local labelText=tostring(feature.label or "")
                local found=buttonPresent(labelText)
                results[#results+1]={
                    id=tostring(feature.id or "button:"..labelText),kind="Button",
                    status=found and "STRUCTURE_OK" or "UNVERIFIED",
                    detail=found
                        and "Button label found in UI; action not executed"
                        or "Action button not observed in UI; may be conditional, hidden by game state, or renamed",
                }
                discoveredButtons[labelText:lower()]=nil
            end
        end
        for _,name in pairs(discoveredButtons) do
            results[#results+1]={id="ui-button:"..name,kind="Button",
                status="STRUCTURE_OK",
                detail="Action label found in UI; underlying callback and effect not verified"}
        end

        local player=Players.LocalPlayer
        probe("LocalPlayer",player~=nil,"Player object loaded",results,true)
        probe("Workspace",workspace~=nil,"Client Workspace available",results,true)
        probe("ReplicatedStorage",RS~=nil,"Roblox service available",results,true)
        local loggerStatus=env.PVH_UniversalLoggerStatus
        local loggerMatched=type(loggerStatus)=="table" and loggerStatus.port==port
            and loggerStatus.placeId==tostring(game.PlaceId)
        local loggerState=loggerMatched and tostring(loggerStatus.state) or "not_registered"
        probe("Universal execution logger",
            loggerMatched and (loggerState=="http_accepted" or loggerState=="already_sent"),
            "Port="..port.." | PlaceId="..tostring(game.PlaceId)
                .." | UniverseId="..tostring(game.GameId)
                .." | delivery="..loggerState
                .."; remote acceptance is not proof of gameplay success",
            results,false)
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
        probe("Autoexec scoped to in-game teleport",
            type(persistence)=="table" and persistence.AutoexecQueuePolicy=="OnTeleportOnly",
            "TEST policy: no queue merely on enable/load; actual queued execution not tested",
            results,false)
        if portKey=="exu" then
            local exu=env.PVH_EXU_HopStatus
            probe("Exu custom server hop controller",
                type(exu)=="table" and type(exu.enabled)=="boolean",
                "TEST overlay loaded; actual teleport must be tested in Roblox",results,false)
            probe("Exu custom no-target interval 3..20",
                type(exu)=="table" and type(exu.seconds)=="number"
                    and exu.seconds>=3 and exu.seconds<=20,
                type(exu)=="table" and ("Configured wait="..tostring(exu.seconds).."s") or "Not initialized",
                results,false)
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
            loggerDelivery=loggerState,
            expectedControls=sourceKnown,foundButtons=hasUI and #uiButtons or 0,
            counts=counts,results=results,buttonLabels=uiButtons,
            note="STRUCTURE_OK means only UI registration and callback wiring. "
                .."Gameplay effects, remotes, farm, TP, server hop, combat and ESP "
                .."were NOT executed or verified by this read-only audit.",
        }
        local ok,json=pcall(function()return HttpService:JSONEncode(metadata)end)
        lastReport=ok and json or "Unable to encode diagnostics"
        lastResults=results
        lastText=formatReport(metadata)
        local saved,fileError=saveTXT()

        local words=TRANSLATIONS[getLanguage()] or TRANSLATIONS["pt-BR"]
        local summary=string.format("%s: %d OK / %d %s / %d %s / %d %s / %d %s",
            words.summary,counts.STRUCTURE_OK,
            counts.MISSING,words.missingWord,
            counts.WARNING,words.warnWord,
            counts.ERROR,words.errorWord,
            counts.UNVERIFIED,words.pendingWord)
        if label and type(label.SetText)=="function" then
            pcall(function()
                label:SetText(summary.." | "..(saved and words.saved or words.saveFailed))
            end)
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
    env.PVH_GetCheckerReportTXT=function()return lastText,lastFilePath end

    -- Diagnostics are automatic, read-only and log-only. Nothing is injected into the UI.
    -- Initial run waits for Obsidian and its controls; later checks detect regressions.
    task.spawn(function()
        for _=1,70 do
            if not running then return end
            local library=env.Library
            if type(library)=='table' and not library.Unloaded
                and type(library.Toggles)=='table' then
                task.wait(1.8)
                break
            end
            task.wait(0.45)
        end
        if not running then return end
        pcall(run)
        while running do
            task.wait(120)
            if running then pcall(run)end
        end
    end)
    return function()
        running=false
        if env.PVH_RunChecker==run then env.PVH_RunChecker=nil end
        env.PVH_GetCheckerReportTXT=nil
    end
end
