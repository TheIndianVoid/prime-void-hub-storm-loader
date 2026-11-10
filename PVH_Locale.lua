-- Prime Void Hub | Shared UI localization v1.1
-- Correct legacy/untranslated UI labels without patching gameplay source.
-- Applies to both the official loader and the already-obfuscated test ports.
local HttpService=game:GetService("HttpService")
local env=(type(getgenv)=="function" and getgenv()) or _G
local active=false

local sources={
    ["Storm Suite"]={"primevoid_hub/Storm_Suite/Config/settings.json"},
    ["Huntress"]={"primevoid_hub/Huntress/Configs/ui_settings.json",
        "primevoid_hub/Huntress/Config/settings.json",
        "primevoid_hub/Huntress/Config/ui_settings.json"},
    ["Exu Security Lab"]={"primevoid_hub/Exu_Security_Lab/Configs/ui_settings.json"},
    ["Destruction Simulator"]={"primevoid_hub/Destruction_Simulator/Configs/ui_settings.json"},
    ["Dont Splash Explorer"]={"primevoid_hub/Dont_Splash/Configs/ui_settings.json"},
    ["Grau SP"]={"primevoid_hub/Grau_SP/Configs/settings.json"},
    ["War Tycoon"]={"primevoid_hub/War_Tycoon/Configs/ui_settings.json"},
    ["Clover Legends"]={"primevoid_hub/Clover_Legends/Configs/ui_settings.json"},
    ["RIVALS"]={"primevoid_hub/RIVALS/Configs/ui_settings.json"},
    ["Da Hood"]={"primevoid_hub/Da_Hood/Configs/ui_settings.json"},
    ["Roube um Espírito Santo"]={"primevoid_hub/Spirit_Sanctuary/Configs/ui_settings.json"},
}

local function normalize(value)
    if type(value)~="string" then return nil end
    local code=value:lower():gsub("_","-"):gsub("%s+","")
    if code=="en" or code=="en-us" or code=="english" then return "en-US" end
    if code=="pt" or code=="pt-br" or code=="portuguese" then return "pt-BR" end
    return nil
end

local function readLanguage(path)
    if type(path)~="string" or type(isfile)~="function" or type(readfile)~="function" then
        return nil
    end
    local ok,result=pcall(function()
        if not isfile(path) then return nil end
        local data=HttpService:JSONDecode(readfile(path))
        if type(data)~="table" then return nil end
        local language=data.language or (type(data.ui)=="table" and data.ui.language)
        return normalize(language)
    end)
    return ok and result or nil
end

-- Keep technical names (ESP, Noclip, Autoexec) and game titles unchanged.
-- Exact mappings only: do not translate usernames, chat, game descriptions
-- or strings that happen to include a translation word as a substring.
local common={
    {"Miscellaneous","Miscelânea"},
    {"Misc","Miscelânea"},
    {"Session","Sessão"},
    {"Last session","Última sessão"},
    {"Auto Save (last session)","Auto Save (última sessão)"},
    {"Autoexec (teleport)","Autoexec (teleporte)"},
    {"Language","Idioma"},
    {"Language / Idioma","Idioma"},
    {"Idioma / Language","Idioma"},
    {"Selecione um idioma / Choose a language","Selecione um idioma"},
    {"Choose a language","Selecione um idioma"},
    {"Select a language","Selecione um idioma"},
    {"🌐 Idioma / Language","🌐 Idioma"},
    {"Language: English (USA)","Idioma: Inglês (EUA)"},
    {"Language: Portuguese (Brazil)","Idioma: Português (Brasil)"},
    {"🌐 Language / Idioma","🌐 Idioma"},
    {"Settings","Configurações"},
    {"Config.","Config."},
    {"Home","Início"},
    {"Main Farm","Farm principal"},
    {"Farm Principal","Farm principal"},
    {"Race Mode","Modo Corrida"},
    {"Vehicles","Veículos"},
    {"Visuals","Visuais"},
    {"Fun","Diversão"},
    {"Movement","Movimento"},
    {"Assistants","Assistentes"},
    {"Automation","Automação"},
    {"Tools","Ferramentas"},
    {"Features","Funções"},
    {"Controls","Controles"},
    {"World","Mundo"},
    {"Player","Jogador"},
    {"Players","Jogadores"},
    {"Vehicle","Veículo"},
    {"Vehicle ESP","ESP Veículos"},
    {"Player ESP","ESP Jogadores"},
    {"Players ESP","ESP Jogadores"},
    {"Friends","Amigos"},
    {"Friend ESP","ESP Amigos"},
    {"Monster","Monstro"},
    {"Monster ESP","ESP Monstro"},
    {"Rooms","Salas"},
    {"Room ESP","ESP Salas"},
    {"Exit ESP","ESP Saída"},
    {"Teleport","Teleporte"},
    {"Teleport to Base","Teletransportar à base"},
    {"Teleport Base","Teleporte à base"},
    {"Teleports","Teleportes"},
    {"Minimize","Minimizar"},
    {"Unload","Descarregar"},
    {"Close","Fechar"},
    {"Open","Abrir"},
    {"Open Shop","Abrir loja"},
    {"Shop","Loja"},
    {"Refresh","Atualizar"},
    {"Update","Atualizar"},
    {"Reset","Redefinir"},
    {"Save","Salvar"},
    {"Load","Carregar"},
    {"Delete","Excluir"},
    {"Save Config","Salvar configuração"},
    {"Load Config","Carregar configuração"},
    {"Delete Config","Excluir configuração"},
    {"Save Profile","Salvar perfil"},
    {"Load Profile","Carregar perfil"},
    {"Delete Profile","Excluir perfil"},
    {"Profiles","Perfis"},
    {"Configuration","Configuração"},
    {"Configurations","Configurações"},
    {"Options","Opções"},
    {"Keybinds","Atalhos"},
    {"Keybind","Atalho"},
    {"Shortcuts","Atalhos"},
    {"Hotkeys","Teclas de atalho"},
    {"Animations","Animações"},
    {"Sounds","Sons"},
    {"UI Sounds","Sons da interface"},
    {"UI Animations","Animações da interface"},
    {"Show Keybinds","Mostrar atalhos"},
    {"Fullbright","Iluminação máxima"},
    {"No Fog","Sem neblina"},
    {"Fog","Neblina"},
    {"Fly","Voar"},
    {"Fly Speed","Velocidade de voo"},
    {"WalkSpeed","Velocidade de caminhada"},
    {"Walk Speed","Velocidade de caminhada"},
    {"Jump Boost","Impulso de salto"},
    {"JumpPower","Força do salto"},
    {"Jump Power","Força do salto"},
    {"Ghost Glide","Deslize fantasma"},
    {"Smooth Ghost Glide","Deslize fantasma suave"},
    {"Instant Interact","Interação instantânea"},
    {"Auto Jump Gaps","Pular vãos automaticamente"},
    {"Anti Splash (jump assist)","Anti Splash (auxílio de salto)"},
    {"Auto Self-Rescue","Autorresgate"},
    {"Auto Rope Rescue","Resgate automático por corda"},
    {"Auto Aim (RMB)","Mira automática (botão direito)"},
    {"Auto Aim","Mira automática"},
    {"Auto Steal","Roubo automático"},
    {"Auto Rebirth","Renascimento automático"},
    {"Auto Treadmill","Esteira automática"},
    {"Auto Farm","Farm automático"},
    {"Farm Money","Farm de dinheiro"},
    {"Auto Pilot","Piloto automático"},
    {"Autopilot","Piloto automático"},
    {"Fast Spawn","Spawn rápido"},
    {"Super Brake","Super freio"},
    {"Vehicle Boxes","Caixas dos veículos"},
    {"Player Boxes","Caixas dos jogadores"},
    {"Players Boxes","Caixas dos jogadores"},
    {"Monster Boxes","Caixas dos monstros"},
    {"ESP Settings","Configurações do ESP"},
    {"Visual Settings","Configurações visuais"},
    {"Speed","Velocidade"},
    {"Distance","Distância"},
    {"Range","Alcance"},
    {"Opacity","Opacidade"},
    {"Transparency","Transparência"},
    {"Outline","Contorno"},
    {"Fill","Preenchimento"},
    {"Text Size","Tamanho do texto"},
    {"Status","Estado"},
    {"Running","Executando"},
    {"Stopped","Parado"},
    {"Enabled","Ativado"},
    {"Disabled","Desativado"},
    {"On","Ligado"},
    {"Off","Desligado"},
    {"Active","Ativo"},
    {"Inactive","Inativo"},
    {"Ready","Pronto"},
    {"Loading","Carregando"},
    {"Available","Disponível"},
    {"Unavailable","Indisponível"},
    {"Current money","Dinheiro atual"},
    {"Earnings this session","Ganhos nesta sessão"},
    {"Available races","Corridas disponíveis"},
    {"Claim Rewards","Resgatar recompensas"},
    {"Auto-claim gifts","Resgate automático de presentes"},
    {"Auto-claim","Resgate automático"},
    {"Server Hop","Trocar de servidor"},
    {"Serverhop","Trocar de servidor"},
    {"Rejoin","Reconectar"},
    {"Server","Servidor"},
    {"Servers","Servidores"},
    {"About","Sobre"},
    {"Support","Suporte"},
    {"Help","Ajuda"},
    {"Discord","Discord"},
    {"Anti-AFK","Anti-AFK"},
    {"No options","Sem opções"},
    {"None","Nenhum"},
    {"All","Todos"},
    {"Select","Selecionar"},
    {"Select All","Selecionar todos"},
    {"Select a game","Selecione um jogo"},
    {"Apply","Aplicar"},
    {"Cancel","Cancelar"},
    {"Confirm","Confirmar"},
    {"Back","Voltar"},
    {"Next","Próximo"},
    {"Report Bug","Reportar erro"},
    {"Suggestion","Sugestão"},
    {"Bug Report","Relatório de erro"},
}
local localized={}
for _,pair in ipairs(common) do
    localized[pair[1]]={en=pair[1],pt=pair[2]}
    -- Several labels share one Portuguese term. Keep the FIRST canonical
    -- English translation rather than letting later synonyms override it.
    if not localized[pair[2]] then
        localized[pair[2]]={en=pair[1],pt=pair[2]}
    end
end
-- Override historically bilingual strings: never reuse PT/EN mixed input
-- as the English output. This also handles old labels already on screen.
for key,words in pairs({
    ["Language / Idioma"]={"Language","Idioma"},
    ["Idioma / Language"]={"Language","Idioma"},
    ["Idioma"]={"Language","Idioma"},
    ["🌐 Language / Idioma"]={"🌐 Language","🌐 Idioma"},
    ["🌐 Idioma / Language"]={"🌐 Language","🌐 Idioma"},
    ["🌐 Idioma"]={"🌐 Language","🌐 Idioma"},
    ["Selecione um idioma / Choose a language"]={"Choose a language","Selecione um idioma"},
    ["Selecione um idioma"]={"Choose a language","Selecione um idioma"},
    ["Choose a language"]={"Choose a language","Selecione um idioma"},
    ["Select a language"]={"Choose a language","Selecione um idioma"},
}) do
    localized[key]={en=words[1],pt=words[2]}
end

local destructionLabels={
    ["Rocket"]={"Rocket","Foguete"},
    ["Bomb"]={"Bomb","Bomba"},
    ["Cooldown"]={"Cooldown","Tempo de recarga"},
    ["RocketSpeed"]={"RocketSpeed","Velocidade do foguete"},
    ["BlastRadius"]={"BlastRadius","Raio da explosão"},
    ["Apply attributes"]={"Apply attributes","Aplicar atributos"},
    ["Aplicar atributos"]={"Apply attributes","Aplicar atributos"},
    ["Aumentar nível"]={"Max level","Nível máximo"},
    ["Max level"]={"Max level","Nível máximo"},
    ["Nível máximo"]={"Max level","Nível máximo"},
    ["Níveis"]={"Levels","Níveis"},
    ["Levels"]={"Levels","Níveis"},
}
local function translate(original,lang,port)
    if type(original)~="string" or original=="" then return original end
    -- Some legacy labels were written bilingual rather than localized.
    local raw=original
    local prefix,body=original:match("^(%s*)(.-)%s*$")
    local trim=body or original
    local specific=port=="Destruction Simulator" and destructionLabels[trim] or nil
    if specific then return (prefix or "")..(lang=="en-US" and specific[1] or specific[2]) end
    local pair=localized[trim]
    if pair then return (prefix or "")..(lang=="en-US" and pair.en or pair.pt) end
    -- Translation for known dynamic status lines only. Preserve changing values.
    local dynamic={
        {"^Earnings this session:%s*","Ganhos nesta sessão: "},
        {"^Ganhos nessa sessão:%s*","Ganhos nesta sessão: "},
        {"^Current money:%s*","Dinheiro atual: "},
        {"^Dinheiro atual:%s*","Dinheiro atual: "},
        {"^Available races:%s*","Corridas disponíveis: "},
        {"^Corridas disponíveis:%s*","Corridas disponíveis: "},
    }
    local prefixes={
        ["Earnings this session: "]={"Earnings this session: ","Ganhos nesta sessão: "},
        ["Ganhos nesta sessão: "]={"Earnings this session: ","Ganhos nesta sessão: "},
        ["Current money: "]={"Current money: ","Dinheiro atual: "},
        ["Dinheiro atual: "]={"Current money: ","Dinheiro atual: "},
        ["Available races: "]={"Available races: ","Corridas disponíveis: "},
        ["Corridas disponíveis: "]={"Available races: ","Corridas disponíveis: "},
        ["Ganhos nessa sessão: "]={"Earnings this session: ","Ganhos nesta sessão: "},
    }
    for from,pair2 in pairs(prefixes) do
        if original:sub(1,#from)==from then
            return (lang=="en-US" and pair2[1] or pair2[2])..original:sub(#from+1)
        end
    end
    return original
end

return function(port)
    port=tostring(port or "")
    if type(env.PVH_LocaleStop)=="function" then pcall(env.PVH_LocaleStop) end
    local running=true
    local localPort=port
    local lastLanguage=nil
    local library=nil
    local lastGui=nil
    local paths=sources[port] or {}
    local function language()
        -- The port's native, saved language is authoritative.
        for _,path in ipairs(paths) do
            local code=readLanguage(path)
            if code then return code end
        end
        local pers=env.PVH_Persistence
        if type(pers)=="table" and type(pers.GetLanguage)=="function" then
            local ok,code=pcall(function() return pers:GetLanguage() end)
            if ok and normalize(code) then return normalize(code) end
        end
        return lastLanguage or "pt-BR"
    end
    local function updateTree(root,lang)
        local ok,nodes=pcall(function() return root:GetDescendants() end)
        if not ok then return end
        for _,node in ipairs(nodes) do
            if node:IsA("TextLabel") or node:IsA("TextButton") then
                local text=node.Text
                local new=translate(text,lang,localPort)
                if new~=text then pcall(function()node.Text=new end) end
            elseif node:IsA("TextBox") then
                local text=node.PlaceholderText
                local new=translate(text,lang,localPort)
                if new~=text then pcall(function()node.PlaceholderText=new end) end
            end
        end
    end
    local function stop()
        running=false
        if env.PVH_LocaleStop==stop then env.PVH_LocaleStop=nil end
    end
    env.PVH_LocaleStop=stop
    task.spawn(function()
        local missing=0
        while running and env.PV_Hub_ActivePort==localPort do
            local lang=language()
            library=env.Library
            local gui=type(library)=="table" and library.ScreenGui or nil
            if typeof(gui)=="Instance" and gui.Parent then
                missing=0
                if gui~=lastGui or lang~=lastLanguage then
                    lastGui=gui
                end
                updateTree(gui,lang)
                lastLanguage=lang
            else
                missing+=1
                if missing>15 then break end
            end
            task.wait(0.75)
        end
        stop()
    end)
    return stop
end
