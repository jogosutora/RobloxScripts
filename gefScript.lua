local repo = 'https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
local Options = getgenv().Linoria.Options
local Toggles = getgenv().Linoria.Toggles

-- Window Configuration
local Window = Library:CreateWindow({
    Title = 'XE Hub - GEF',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Tabs
local Tabs = {
    Main = Window:AddTab('Main'),
    Visual = Window:AddTab('Visual'),
    Misc = Window:AddTab('Misc'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

-- Utility Functions
local function changeValue(instance, property, value)
    local success, error = pcall(function()
        if typeof(instance) == "Instance" then
            if instance:IsA("ValueBase") then
                instance.Value = value
            else
                instance[property] = value
            end
            return true
        end
        return false
    end)
    
    if success then
        Library:Notify(string.format("Changed %s to %s", property, tostring(value)), 3)
        return true
    else
        Library:Notify(string.format("Failed to change %s: %s", property, error), 3)
        return false
    end
end

local function teleportTo(item)
    if _G.StopItemTeleport then
        Library:Notify('Item teleportation cancelled', 3)
        return
    end

    local rootPart = game.Players.LocalPlayer.Character.HumanoidRootPart
    local pickup = game:GetService("Workspace").Pickups:FindFirstChild(item)
    
    if rootPart and pickup then
        local originalPosition = rootPart.CFrame
        local prompt = pickup:FindFirstChildWhichIsA("ProximityPrompt")
        
        repeat
            if _G.StopItemTeleport then
                if Toggles.ReturnAfterTeleport.Value then
                    rootPart.CFrame = originalPosition
                end
                Library:Notify('Item teleportation cancelled', 3)
                return
            end
            rootPart.CFrame = pickup.CFrame
            if prompt then
                fireproximityprompt(prompt)
            end
            task.wait()
        until not pickup:IsDescendantOf(game:GetService("Workspace").Pickups)
        
        if Toggles.ReturnAfterTeleport.Value then
            rootPart.CFrame = originalPosition
        end
        
        Library:Notify('Collected ' .. item, 3)
    else
        Library:Notify('Failed to find ' .. item, 3)
    end
end

local function applyReach(size)
    for _, v in pairs(game:GetService'Players'.LocalPlayer.Character:GetChildren()) do
        if v:isA("Tool") then
            local a = Instance.new("SelectionBox", v.Handle)
            a.Adornee = v.Handle
            v.Handle.Size = Vector3.new(size, size, size)
            v.GripPos = Vector3.new(0, 0, 0)
            game.Players.LocalPlayer.Character.Humanoid:UnequipTools()
        end
    end
    Library:Notify("Reach set to " .. size, 3)
end

-- Main Tab
local ItemGroupBox = Tabs.Main:AddLeftGroupbox('Items')
local ReachGroupBox = Tabs.Main:AddRightGroupbox('Reach')
local StatsGroupBox = Tabs.Main:AddRightGroupbox('Stats Changer (op)')

-- Items GroupBox
ItemGroupBox:AddLabel('Food Items')
ItemGroupBox:AddButton('Food', function() teleportTo('Food') end)
ItemGroupBox:AddButton('Soda', function() teleportTo('Soda') end)
ItemGroupBox:AddButton('Medkit', function() teleportTo('Medkit') end)

ItemGroupBox:AddDivider()

ItemGroupBox:AddLabel('Weapons')
ItemGroupBox:AddButton('Bat', function() teleportTo('Bat') end)
ItemGroupBox:AddButton('Hammer', function() teleportTo('Hammer') end)
ItemGroupBox:AddButton('Crowbar', function() teleportTo('Crowbar') end)

ItemGroupBox:AddDivider()

ItemGroupBox:AddLabel('Guns')
ItemGroupBox:AddButton('Handgun', function() teleportTo('Handgun') end)
ItemGroupBox:AddButton('Shotgun', function() teleportTo('Shotgun') end)
ItemGroupBox:AddButton('Shells', function() teleportTo('Shells') end)
ItemGroupBox:AddButton('Bullet', function() teleportTo('Bullet') end)

ItemGroupBox:AddDivider()

ItemGroupBox:AddLabel('Miscellaneous')
ItemGroupBox:AddButton('Lantern', function() teleportTo('Lantern') end)
ItemGroupBox:AddButton('Money', function() teleportTo('Money') end)
ItemGroupBox:AddButton('GPS', function() teleportTo('GPS') end)
ItemGroupBox:AddButton('Stop All Item TP Attempts', function()
    _G.StopItemTeleport = true
    task.wait(1)
    _G.StopItemTeleport = false
end)

-- Reach GroupBox
ReachGroupBox:AddDropdown('ReachSize', {
    Values = { '10', '20', '30', '50' },
    Default = 1,
    Text = 'Reach Size'
})

ReachGroupBox:AddButton('Apply Reach', function()
    applyReach(tonumber(Options.ReachSize.Value))
end)

-- stats group box

StatsGroupBox:AddInput('MaxStamina', {
    Default = tostring(game.Players.LocalPlayer.Upgrades.MaxStamina.Value),
    Numeric = true,
    Finished = true,
    Text = 'Max Stamina',
    Tooltip = 'Set your maximum stamina',
    Placeholder = 'Enter value...',

    Callback = function(Value)
        changeValue(game.Players.LocalPlayer.Upgrades.MaxStamina, nil, tonumber(Value))
    end
})

-- Stamina Regen Input
StatsGroupBox:AddInput('StaminaRegen', {
    Default = tostring(game.Players.LocalPlayer.Upgrades.StaminaRegen.Value),
    Numeric = true,
    Finished = true,
    Text = 'Stamina Regen',
    Tooltip = 'Set your stamina regeneration rate',
    Placeholder = 'Enter value...',

    Callback = function(Value)
        changeValue(game.Players.LocalPlayer.Upgrades.StaminaRegen, nil, tonumber(Value))
    end
})

-- Storage Input
StatsGroupBox:AddInput('Storage', {
    Default = tostring(game.Players.LocalPlayer.Upgrades.Storage.Value),
    Numeric = true,
    Finished = true,
    Text = 'Storage',
    Tooltip = 'Set your storage capacity',
    Placeholder = 'Enter value...',

    Callback = function(Value)
        changeValue(game.Players.LocalPlayer.Upgrades.Storage, nil, tonumber(Value))
    end
})

-- Visual Tab
local VisualGroupBox = Tabs.Visual:AddLeftGroupbox('Visual')

-- ESP Functions
local function createItemESP(item)
    -- Remove existing ESP
    if item:FindFirstChild("ESP") then
        item.ESP:Destroy()
    end
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP"
    billboardGui.Parent = item
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 100, 0, 25)
    -- Use item's size and position for offset
    local offset = (item:IsA("BasePart") and item.Size.Y / 2 + 2) or 2
    billboardGui.StudsOffset = Vector3.new(0, offset, 0)
    
    local frame = Instance.new("Frame")
    frame.Name = "ESPFrame"
    frame.Parent = billboardGui
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 1, 0)
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = frame
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextScaled = true
    textLabel.Text = item.Name
    
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Parent = textLabel
    uiStroke.Color = Color3.fromRGB(0, 0, 0)
    uiStroke.Thickness = 1.5
    
    local gradient = Instance.new("UIGradient")
    gradient.Parent = textLabel
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 200)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })
    gradient.Rotation = 90
    
    -- Add highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "ItemHighlight"
    highlight.Parent = item
    highlight.FillColor = Color3.fromRGB(255, 255, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
end

local function updateItemESP()
    if Toggles.ItemESP.Value then
        for _, item in pairs(workspace.Pickups:GetChildren()) do
            if not item:FindFirstChild("ESP") then
                createItemESP(item)
            end
        end
    else
        for _, item in pairs(workspace.Pickups:GetChildren()) do
            if item:FindFirstChild("ESP") then
                item.ESP:Destroy()
            end
            if item:FindFirstChild("ItemHighlight") then
                item.ItemHighlight:Destroy()
            end
        end
    end
end

-- Connect to new items
workspace.Pickups.ChildAdded:Connect(function(item)
    if Toggles.ItemESP.Value then
        task.wait() -- Wait a frame for the item to load properly
        createItemESP(item)
    end
end)

-- Connect to toggle
VisualGroupBox:AddToggle('ItemESP', {
    Text = 'Item ESP',
    Default = false,
    Callback = function(Value)
        updateItemESP()
    end
})

-- Utility function for managing ESP elements
local function cleanupESP(instance)
    if instance:FindFirstChild("ESP") then instance.ESP:Destroy() end
    if instance:FindFirstChild("GefHighlight") then instance.GefHighlight:Destroy() end
    if instance:FindFirstChild("PlayerHighlight") then instance.PlayerHighlight:Destroy() end
end

-- Improved GEF ESP
local function createGefESP(gef)
    cleanupESP(gef)
    
    local root = gef:FindFirstChild("HumanoidRootPart") or gef.PrimaryPart or gef:FindFirstChild("Torso")
    if not root then return end
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP"
    billboardGui.Parent = root
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 100, 0, 25)
    billboardGui.StudsOffset = Vector3.new(0, 7, 0) -- Fixed offset above GEF
    billboardGui.Adornee = root
    
    local frame = Instance.new("Frame")
    frame.Name = "ESPFrame"
    frame.Parent = billboardGui
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 1, 0)
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = frame
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextScaled = true
    textLabel.Text = "GEF"
    
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Parent = textLabel
    uiStroke.Color = Color3.fromRGB(0, 0, 0)
    uiStroke.Thickness = 1.5
    
    local gradient = Instance.new("UIGradient")
    gradient.Parent = textLabel
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })
    gradient.Rotation = 90
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "GefEsp"
    highlight.Parent = gef
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
end

-- Improved Player ESP
local function createPlayerESP(player)
    if not player.Character then return end
    local character = player.Character
    cleanupESP(character)
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP"
    billboardGui.Parent = root
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 100, 0, 25)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0) -- Fixed offset above player
    billboardGui.Adornee = root
    
    local frame = Instance.new("Frame")
    frame.Name = "ESPFrame"
    frame.Parent = billboardGui
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 1, 0)
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = frame
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextScaled = true
    textLabel.Text = player.Name
    
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Parent = textLabel
    uiStroke.Color = Color3.fromRGB(0, 0, 0)
    uiStroke.Thickness = 1.5
    
    local gradient = Instance.new("UIGradient")
    gradient.Parent = textLabel
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 255, 100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })
    gradient.Rotation = 90
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "PlayerHighlight"
    highlight.Parent = character
    highlight.FillColor = Color3.fromRGB(0, 255, 0)
    highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
end

-- Update functions
local function updateGefESP()
    if Toggles.GefESP.Value then
        for _, gef in pairs(workspace.GEFs:GetChildren()) do
            if not gef:FindFirstChild("ESP") then
                createGefESP(gef)
            end
        end
    else
        for _, gef in pairs(workspace.GEFs:GetChildren()) do
            cleanupESP(gef)
        end
    end
end

local function updatePlayerESP()
    if Toggles.PlayerESP.Value then
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer then -- Optional: don't ESP yourself
                createPlayerESP(player)
            end
        end
    else
        for _, player in pairs(game.Players:GetPlayers()) do
            if player.Character then
                cleanupESP(player.Character)
            end
        end
    end
end

-- Connect everything
workspace.GEFs.ChildAdded:Connect(function(gef)
    if Toggles.GefESP.Value then
        task.wait(0.1) -- Wait for character to load
        createGefESP(gef)
    end
end)

workspace.GEFs.ChildRemoved:Connect(function(gef)
    cleanupESP(gef)
end)

game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        if Toggles.PlayerESP.Value then
            task.wait(0.1) -- Wait for character to load
            createPlayerESP(player)
        end
    end)
end)

game.Players.PlayerRemoving:Connect(function(player)
    if player.Character then
        cleanupESP(player.Character)
    end
end)

-- Add toggles to your Visual tab
VisualGroupBox:AddToggle('GefESP', {
    Text = 'GEF ESP',
    Default = false,
    Callback = function(Value)
        updateGefESP()
    end
})

VisualGroupBox:AddToggle('PlayerESP', {
    Text = 'Player ESP',
    Default = false,
    Callback = function(Value)
        updatePlayerESP()
    end
})

-- Fullbright Toggle
VisualGroupBox:AddToggle('FullbrightEnabled', {
    Text = 'Fullbright',
    Default = false,
    Tooltip = 'Toggles fullbright',
    Callback = function(Value)
        if Value then
            game:GetService("Lighting").Brightness = 1
            game:GetService("Lighting").ClockTime = 12
            game:GetService("Lighting").FogEnd = 786543
            game:GetService("Lighting").GlobalShadows = false
            game:GetService("Lighting").Ambient = Color3.fromRGB(178, 178, 178)
        else
            game:GetService("Lighting").Brightness = _G.NormalLightingSettings.Brightness
            game:GetService("Lighting").ClockTime = _G.NormalLightingSettings.ClockTime
            game:GetService("Lighting").FogEnd = _G.NormalLightingSettings.FogEnd
            game:GetService("Lighting").GlobalShadows = _G.NormalLightingSettings.GlobalShadows
            game:GetService("Lighting").Ambient = _G.NormalLightingSettings.Ambient
        end
    end
})

-- Misc Tab
local MiscGroupBox = Tabs.Misc:AddLeftGroupbox('Misc')

-- Player Teleport
local playerList = {}
for _, player in pairs(game.Players:GetPlayers()) do
    table.insert(playerList, player.Name)
end

local PlayerDropdown = MiscGroupBox:AddDropdown('PlayerTeleport', {
    Values = playerList,
    Default = 1,
    Text = 'Select Player'
})

-- Update player list when players join/leave
game.Players.PlayerAdded:Connect(function(player)
    table.insert(playerList, player.Name)
    PlayerDropdown:SetValues(playerList)
end)

game.Players.PlayerRemoving:Connect(function(player)
    for i, name in ipairs(playerList) do
        if name == player.Name then
            table.remove(playerList, i)
            break
        end
    end
    PlayerDropdown:SetValues(playerList)
end)

MiscGroupBox:AddButton('Teleport to Player', function()
    local selectedPlayer = game.Players:FindFirstChild(Options.PlayerTeleport.Value)
    if selectedPlayer and selectedPlayer.Character then
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame
    end
end)

-- Return after teleport toggle
MiscGroupBox:AddToggle('ReturnAfterTeleport', {
    Text = 'Return After Item Teleport',
    Default = false,
    Tooltip = 'Automatically return to original position after teleporting to an item'
})

-- UI Settings Tab
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' }) 

Library.ToggleKeybind = Options.MenuKeybind

-- Theme manager
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

ThemeManager:SetFolder('XEHub')
SaveManager:SetFolder('XEHub/GEF')

SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

-- Load
SaveManager:LoadAutoloadConfig()