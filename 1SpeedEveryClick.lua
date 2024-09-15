local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = playerGui

-- Function to create a stylized button
local function createStylizedButton(text, position)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 150, 0, 50)
    button.Position = position
    button.Text = text
    button.Font = Enum.Font.GothamSemibold
    button.TextColor3 = Color3.new(1, 1, 1)
    button.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    button.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(1, 1, 1)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Thickness = 2
    stroke.Parent = button

    return button
end

-- Create Teleport Button
local teleportButton = createStylizedButton("Toggle Teleport", UDim2.new(0, 10, 0, 10))

-- Create Auto Click Button
local autoClickButton = createStylizedButton("Toggle Auto Click", UDim2.new(0, 10, 0, 70))

-- Create Auto Rebirth Button
local autoRebirthButton = createStylizedButton("Toggle Auto Rebirth", UDim2.new(0, 10, 0, 130))

-- Teleport function
local function teleportToHighestWins()
    local wins = workspace:FindFirstChild("Wins")
    if not wins then return end
    
    local highestWinsChild = nil
    local highestWinsValue = -math.huge
    
    for _, child in pairs(wins:GetChildren()) do
        local winsValue = child:FindFirstChild("Wins")
        if winsValue and winsValue:IsA("IntValue") and winsValue.Value > highestWinsValue then
            highestWinsChild = child
            highestWinsValue = winsValue.Value
        end
    end
    
    if highestWinsChild then
        player.Character:SetPrimaryPartCFrame(highestWinsChild.CFrame)
    end
end

-- Auto Click function
local function autoClick()
    ReplicatedStorage.IncreaseSpeed:FireServer()
end

-- Auto Rebirth function
local function autoRebirth()
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local wins = leaderstats:FindFirstChild("Wins")
        if wins and wins.Value >= player.requiredwins.Value then
            ReplicatedStorage.RebirthEvent:FireServer()
        end
    end
end

-- Toggle variables
local isTeleporting = false
local isAutoClicking = false
local isAutoRebirthing = false

-- Teleport loop
spawn(function()
    while wait(0.4) do
        if isTeleporting then
            teleportToHighestWins()
        end
    end
end)

-- Auto Click loop
spawn(function()
    while wait(0.1) do
        if isAutoClicking then
            autoClick()
        end
    end
end)

-- Auto Rebirth loop
spawn(function()
    while wait(0.1) do
        if isAutoRebirthing then
            autoRebirth()
        end
    end
end)

-- Function to toggle button state
local function toggleButton(button, isActive)
    button.Text = isActive and button.Text:gsub("Toggle", "ON:") or button.Text:gsub("ON:", "Toggle")
    button.BackgroundColor3 = isActive and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(52, 152, 219)
end

-- Teleport Button functionality
teleportButton.MouseButton1Click:Connect(function()
    isTeleporting = not isTeleporting
    toggleButton(teleportButton, isTeleporting)
end)

-- Auto Click Button functionality
autoClickButton.MouseButton1Click:Connect(function()
    isAutoClicking = not isAutoClicking
    toggleButton(autoClickButton, isAutoClicking)
end)

-- Auto Rebirth Button functionality
autoRebirthButton.MouseButton1Click:Connect(function()
    isAutoRebirthing = not isAutoRebirthing
    toggleButton(autoRebirthButton, isAutoRebirthing)
end)

-- Make buttons draggable
local function makeButtonDraggable(button)
    local dragging
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = button.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    button.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

makeButtonDraggable(teleportButton)
makeButtonDraggable(autoClickButton)
makeButtonDraggable(autoRebirthButton)
