--// Serviços
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")

--// Função utilitária para criar botões bonitos
local function createButton(parent, text, position, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35) -- Ajustado para 35
    btn.Position = position
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16 -- Ajustado para 16
    btn.Parent = parent

    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0,12)

    return btn
end

--// Criar ScreenGui e frame principal
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "MegaHub"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 240, 0, 300) -- Ajustado para 240x300
frame.Position = UDim2.new(0, 30, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local frameCorner = Instance.new("UICorner", frame)
frameCorner.CornerRadius = UDim.new(0,16)
local frameStroke = Instance.new("UIStroke", frame)
frameStroke.Color = Color3.fromRGB(0,150,255)
frameStroke.Thickness = 2

--// Título
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,35) -- Ajustado para 35
title.Position = UDim2.new(0,0,0,5)
title.BackgroundTransparency = 1
title.Text = "Survive Flight Gui"
title.TextColor3 = Color3.fromRGB(0,150,255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18 -- Ajustado para 18

--// Fluxo vertical para botões
local currentY = 45 -- Ajustado para 45
local function nextPos()
    local pos = UDim2.new(0.05,0,0,currentY)
    currentY = currentY + 45 -- Ajustado para 45
    return pos
end

--// Fast Build
local fastBuildEnabled = false
local fastBuildBtn = createButton(frame,"Fast Proximity: OFF",nextPos(), Color3.fromRGB(200,70,70))
local function acceleratePrompts()
    while fastBuildEnabled do
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                obj.HoldDuration = 0.1
            end
        end
        wait(0.5)
    end
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            obj.HoldDuration = 2
        end
    end
end
fastBuildBtn.MouseButton1Click:Connect(function()
    fastBuildEnabled = not fastBuildEnabled
    fastBuildBtn.Text = fastBuildEnabled and "Fast proximity: ON" or "Fast Proximity: OFF"
    fastBuildBtn.BackgroundColor3 = fastBuildEnabled and Color3.fromRGB(70,200,70) or Color3.fromRGB(200,70,70)
    if fastBuildEnabled then
        spawn(acceleratePrompts)
    end
end)

--// Touch Wood
local touchWoodEnabled = false
local touchWoodBtn = createButton(frame,"Collect Wood: OFF",nextPos(), Color3.fromRGB(0,150,0))
local touchLoop
local function touchAllWoods()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name:lower():find("wood") then
            for _, touch in pairs(obj:GetChildren()) do
                if touch:IsA("TouchTransmitter") or touch:IsA("TouchInterest") then
                    pcall(function()
                        firetouchinterest(HRP, obj, 0)
                        firetouchinterest(HRP, obj, 1)
                    end)
                end
            end
        end
    end
end
touchWoodBtn.MouseButton1Click:Connect(function()
    touchWoodEnabled = not touchWoodEnabled
    touchWoodBtn.Text = touchWoodEnabled and "Collect Wood: ON" or "Touch Wood: OFF"
    touchWoodBtn.BackgroundColor3 = touchWoodEnabled and Color3.fromRGB(200,0,0) or Color3.fromRGB(0,150,0)
    if touchWoodEnabled then
        touchLoop = RunService.RenderStepped:Connect(touchAllWoods)
    else
        if touchLoop then touchLoop:Disconnect() end
    end
end)

--// Get All Tools
local statusLabel
local getToolsBtn = createButton(frame,"Get Tools",nextPos(), Color3.fromRGB(0,100,200))
statusLabel = Instance.new("TextLabel", frame)
statusLabel.Size = UDim2.new(0.9,0,0,25) -- Ajustado para 25
statusLabel.Position = UDim2.new(0.05,0,0,currentY-10)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(200,0,0)
statusLabel.TextSize = 14 -- Ajustado para 14
statusLabel.Font = Enum.Font.SourceSans
local guEvent = ReplicatedStorage:FindFirstChild("gu")
getToolsBtn.MouseButton1Click:Connect(function()
    if not guEvent then
        statusLabel.Text = ""
        statusLabel.TextColor3 = Color3.fromRGB(200,0,0)
        return
    end
    local argsList = {{8},{6},{1},{4},{3},{2}}
    for _,args in pairs(argsList) do
        pcall(function() guEvent:FireServer(unpack(args)) end)
        wait(0.1)
    end
    statusLabel.Text = ""
    statusLabel.TextColor3 = Color3.fromRGB(0,200,0)
end)

--// Suitcase Teleport (alinhado corretamente)
local suitcaseBtn = createButton(frame,"Suitcase Loot",nextPos(), Color3.fromRGB(70,130,250))
suitcaseBtn.MouseButton1Click:Connect(function()
    local suitcase = workspace:FindFirstChild("suitcase")
    if suitcase and suitcase:FindFirstChild("main") then
        local main = suitcase.main
        local prompt = main:FindFirstChildWhichIsA("ProximityPrompt")
        if prompt then
            HRP.CFrame = suitcase:GetModelCFrame() + Vector3.new(0,3,0)
            pcall(function()
                fireproximityprompt(prompt)
            end)
        end
    end
end)

--// Drag Mobile/PC
local dragging, dragInput, dragStart, startPos
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

print("Mega Hub carregado com sucesso!")
