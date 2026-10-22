-- Prime Void Hub - Storm Suite | GitHub-only loader
-- A source permanece PRIVADA. Nunca coloque um token neste arquivo publico.
local API = 'https://api.github.com/repos/TheIndianVoid/prime-void-hub-storm-suite/contents/PrimeVoidHub_StormSuite.lua?ref=main'
local HttpService = game:GetService('HttpService')
local Players = game:GetService('Players')
local genv = type(getgenv)=='function' and getgenv() or _G
local function fetchSource(token)
    local send = (syn and syn.request) or http_request or request or (http and http.request)
    if type(send)~='function' then return false,'Executor sem suporte a requisicoes HTTP com headers' end
    local ok,res=pcall(send,{
        Url=API..'&cache='..tostring(os.time()),
        Method='GET',
        Headers={
            ['Authorization']='Bearer '..token,
            ['Accept']='application/vnd.github.raw+json',
            ['X-GitHub-Api-Version']='2022-11-28',
            ['Cache-Control']='no-cache',
        }
    })
    if not ok then return false,'Falha de rede: '..tostring(res) end
    local status=tonumber(res.StatusCode or res.Status) or 0
    if status~=200 then
        return false,'GitHub HTTP '..status..' (confira permissao Contents: Read do token)'
    end
    local body=res.Body or res.body
    if type(body)~='string' then return false,'Resposta vazia do GitHub' end
    if body:sub(1,1)=='{' then
        local parsedOk,obj=pcall(function()return HttpService:JSONDecode(body)end)
        if parsedOk and type(obj)=='table' and obj.encoding=='base64' and type(obj.content)=='string' then
            local chars='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
            local bits=obj.content:gsub('[^'..chars..'=]','')
            local decoded={}
            for i=1,#bits,4 do
                local a,b,c,d=bits:sub(i,i),bits:sub(i+1,i+1),bits:sub(i+2,i+2),bits:sub(i+3,i+3)
                local x=chars:find(a,1,true)
                local y=chars:find(b,1,true)
                local z=chars:find(c,1,true)
                local w=chars:find(d,1,true)
                if not x or not y then return false,'Base64 invalido' end
                local v=(x-1)*262144+(y-1)*4096+((z or 1)-1)*64+((w or 1)-1)
                decoded[#decoded+1]=string.char(math.floor(v/65536)%256)
                if c~='=' then decoded[#decoded+1]=string.char(math.floor(v/256)%256) end
                if d~='=' then decoded[#decoded+1]=string.char(v%256) end
            end
            body=table.concat(decoded)
        end
    end
    if #body<120000 or not body:find('setupInterfaceAndLoops()',1,true) then
        return false,'Resposta nao parece ser a source completa da Storm Suite'
    end
    local fn,err=loadstring(body)
    if not fn then return false,'Source invalida: '..tostring(err) end
    return true,fn
end

local function launch(token)
    local ok,result=fetchSource(token)
    if not ok then return false,result end
    -- O token nao e salvo, impresso nem transmitido para outro endereco.
    local ran,err=pcall(result)
    if not ran then return false,'Erro na execucao: '..tostring(err) end
    return true
end

local token=genv.PRIME_VOID_GITHUB_TOKEN
if type(token)=='string' and #token>10 then
    local ok,err=launch(token)
    if not ok then error('Prime Void Hub: '..err,0) end
    return
end

-- Solicita credencial localmente, sem inclui-la no loader publico.
local parent
local okGui,guiParent=pcall(function()return type(gethui)=='function' and gethui() or nil end)
if okGui and guiParent then parent=guiParent end
if not parent then parent=Players.LocalPlayer:WaitForChild('PlayerGui') end
local ui=Instance.new('ScreenGui')
ui.Name='PrimeVoidHub_GitHub_Access'
ui.ResetOnSpawn=false
ui.DisplayOrder=10000
ui.Parent=parent
local frame=Instance.new('Frame')
frame.Size=UDim2.fromOffset(440,205)
frame.Position=UDim2.new(0.5,-220,0.5,-102)
frame.BackgroundColor3=Color3.fromRGB(20,22,28)
frame.BorderSizePixel=0
frame.Parent=ui
local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,10);corner.Parent=frame
local function label(text,y,h)
    local o=Instance.new('TextLabel')
    o.BackgroundTransparency=1
    o.Position=UDim2.fromOffset(16,y)
    o.Size=UDim2.new(1,-32,0,h)
    o.Font=Enum.Font.Gotham
    o.TextSize=14
    o.TextWrapped=true
    o.TextColor3=Color3.fromRGB(235,235,240)
    o.Text=text
    o.Parent=frame
    return o
end
label('Prime Void Hub - Acesso a source privada do GitHub',12,30)
label('Cole um token fine-grained com Contents: Read apenas para o repositorio Storm Suite.',42,38)
local input=Instance.new('TextBox')
input.Position=UDim2.fromOffset(16,89)
input.Size=UDim2.new(1,-32,0,35)
input.PlaceholderText='GitHub token (nao sera salvo)'
input.Text=''
input.ClearTextOnFocus=false
input.Font=Enum.Font.Code
input.TextSize=13
input.TextColor3=Color3.new(1,1,1)
input.BackgroundColor3=Color3.fromRGB(40,43,52)
input.Parent=frame
local button=Instance.new('TextButton')
button.Position=UDim2.fromOffset(16,133)
button.Size=UDim2.new(1,-32,0,30)
button.Text='Carregar Storm Suite'
button.Font=Enum.Font.GothamBold
button.TextSize=14
button.TextColor3=Color3.new(1,1,1)
button.BackgroundColor3=Color3.fromRGB(72,56,140)
button.Parent=frame
local status=label('',168,31)
local busy=false
button.MouseButton1Click:Connect(function()
    if busy then return end
    local submitted=input.Text:gsub('%s','')
    input.Text=''
    if #submitted<10 then status.Text='Insira um token valido';return end
    busy=true;button.Text='Carregando...'
    task.spawn(function()
        local success,message=launch(submitted)
        submitted=nil
        if success then ui:Destroy()
        else status.Text=message;button.Text='Tentar novamente';busy=false end
    end)
end)
