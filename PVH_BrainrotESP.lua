-- Prime Void Hub | Local Player ESP for Steal a Brainrot
-- Avoids executing external unreviewed ESP modules.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local lp=Players.LocalPlayer
local env=type(getgenv)=="function" and getgenv() or _G
local parent
pcall(function()parent=(type(gethui)=="function" and gethui()) or game:GetService("CoreGui")end)
parent=parent or lp:WaitForChild("PlayerGui")
local state={
    Box=false,Name=false,Health=false,Team=false,
    Tracers=false,Skeleton=false,HeldItem=false,
}
local overlays={}
local ESP={}
local function cleanup(player)
    local obj=overlays[player]
    if not obj then return end
    for _,inst in ipairs(obj.parts) do pcall(function()inst:Destroy()end) end
    overlays[player]=nil
end
local function owned(obj,container)
    table.insert(container.parts,obj)
    return obj
end
local function makeBeam(container,from,to,width,color)
    if not from or not to then return end
    local aa=owned(Instance.new("Attachment"),container)
    aa.Parent=from
    local bb=owned(Instance.new("Attachment"),container)
    bb.Parent=to
    local beam=owned(Instance.new("Beam"),container)
    beam.Attachment0=aa
    beam.Attachment1=bb
    beam.Width0=width
    beam.Width1=width
    beam.Color=ColorSequence.new(color)
    beam.FaceCamera=true
    beam.LightEmission=0.7
    beam.Parent=parent
    return beam
end
local skeletonPairs={
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},
    {"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},
    {"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},
    {"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},
    {"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local skeletonR6={
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
    {"Torso","Left Leg"},{"Torso","Right Leg"},
}
local function visualFor(player,character)
    local existing=overlays[player]
    if existing and existing.character==character then return existing end
    cleanup(player)
    local v={character=character,parts={},lines={}}
    overlays[player]=v
    local hrp=character:FindFirstChild("HumanoidRootPart")
    local head=character:FindFirstChild("Head") or hrp
    if not hrp then return v end
    local selection=owned(Instance.new("SelectionBox"),v)
    selection.Adornee=character
    selection.Color3=Color3.fromRGB(125,210,255)
    selection.LineThickness=0.035
    selection.Parent=parent
    v.box=selection
    local billboard=owned(Instance.new("BillboardGui"),v)
    billboard.Name="PVBR_PlayerInfo"
    billboard.Adornee=head
    billboard.Size=UDim2.fromOffset(200,72)
    billboard.StudsOffsetWorldSpace=Vector3.new(0,3,0)
    billboard.AlwaysOnTop=true
    billboard.Parent=parent
    local label=Instance.new("TextLabel")
    label.BackgroundTransparency=1
    label.Size=UDim2.fromScale(1,1)
    label.Font=Enum.Font.GothamSemibold
    label.TextColor3=Color3.fromRGB(255,255,255)
    label.TextStrokeTransparency=0.4
    label.TextSize=13
    label.TextWrapped=true
    label.Parent=billboard
    v.billboard=billboard
    v.label=label
    local localChar=lp.Character
    local myRoot=localChar and localChar:FindFirstChild("HumanoidRootPart")
    if myRoot then
        v.tracer=makeBeam(v,myRoot,hrp,0.04,Color3.fromRGB(200,255,255))
    end
    for _,pair in ipairs(character:FindFirstChild("UpperTorso") and skeletonPairs or skeletonR6) do
        local one=character:FindFirstChild(pair[1])
        local two=character:FindFirstChild(pair[2])
        if one and two then
            local beam=makeBeam(v,one,two,0.06,Color3.fromRGB(160,220,255))
            if beam then table.insert(v.lines,beam) end
        end
    end
    return v
end
local function update()
    local active=false
    for _,v in pairs(state) do if v then active=true break end end
    if not active then
        for p in pairs(overlays) do cleanup(p) end
        return
    end
    local seen={}
    for _,player in ipairs(Players:GetPlayers()) do
        if player~=lp and player.Character then
            local char=player.Character
            local root=char:FindFirstChild("HumanoidRootPart")
            local hum=char:FindFirstChildOfClass("Humanoid")
            if root then
                seen[player]=true
                local v=visualFor(player,char)
                v.box.Visible=state.Box
                local parts={}
                if state.Name then table.insert(parts,player.DisplayName) end
                if state.Health and hum then
                    table.insert(parts,("HP %d/%d"):format(
                        math.floor(hum.Health),math.floor(hum.MaxHealth)))
                end
                if state.Team then
                    table.insert(parts,player.Team and player.Team.Name or "Sem time")
                end
                if state.HeldItem then
                    local tool=char:FindFirstChildWhichIsA("Tool")
                    table.insert(parts,tool and tool.Name or "Sem item")
                end
                v.billboard.Enabled=#parts>0
                v.label.Text=table.concat(parts,"\n")
                if v.tracer then v.tracer.Enabled=state.Tracers end
                for _,beam in ipairs(v.lines) do beam.Enabled=state.Skeleton end
            end
        end
    end
    for player in pairs(overlays) do
        if not seen[player] then cleanup(player) end
    end
end
function ESP:Init()
    if self.connection then return end
    local accumulator=0
    self.connection=RunService.Heartbeat:Connect(function(dt)
        accumulator+=dt
        if accumulator<0.25 then return end
        accumulator=0
        pcall(update)
    end)
    if env.Library and type(env.Library.OnUnload)=="function" then
        env.Library:OnUnload(function()self:Destroy()end)
    end
end
function ESP:Destroy()
    if self.connection then self.connection:Disconnect() self.connection=nil end
    for player in pairs(overlays) do cleanup(player) end
end
function ESP:SetBoxEsp(v)state.Box=v==true update()end
function ESP:SetNameEsp(v)state.Name=v==true update()end
function ESP:SetHealthEsp(v)state.Health=v==true update()end
function ESP:SetTeamEsp(v)state.Team=v==true update()end
function ESP:SetTracers(v)state.Tracers=v==true update()end
function ESP:SetSkeletonEsp(v)state.Skeleton=v==true update()end
function ESP:SetHeldItemEsp(v)state.HeldItem=v==true update()end
return ESP