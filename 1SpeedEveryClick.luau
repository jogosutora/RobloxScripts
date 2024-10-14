local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Create Window
local Window = OrionLib:MakeWindow({
    Name = "Speed Shit",
    IntroText = "lol",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "SpeedShitConfig"
})

-- Variables
local isTeleporting = false
local isAutoClicking = false
local isAutoRebirthing = false
local clickInterval = 0.1
local teleportInterval = 0.4
local rebirthInterval = 0.1
local isDebugMode = false

-- Debug function
local function debugPrint(message)
    if isDebugMode then
        print("[Debug] " .. message)
        OrionLib:MakeNotification({
            Name = "Debug",
            Content = message,
            Image = "rbxassetid://4483345998",
            Time = 5
        })
    end
end

-- Functions
local function teleportToHighestWins()
    debugPrint("Attempting to teleport...")
    local wins = workspace:FindFirstChild("Wins")
    if not wins then 
        debugPrint("No 'Wins' folder found in workspace")
        return 
    end
    
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
        debugPrint("Teleporting to highest wins: " .. highestWinsValue)
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = highestWinsChild.CFrame
        else
            debugPrint("Character or HumanoidRootPart not found")
        end
    else
        debugPrint("No valid teleport destination found")
    end
end

local function autoClick()
    ReplicatedStorage.IncreaseSpeed:FireServer()
end

local function autoRebirth()
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local wins = leaderstats:FindFirstChild("Wins")
        if wins and wins.Value >= player.requiredwins.Value then
            ReplicatedStorage.RebirthEvent:FireServer()
        end
    end
end

-- Main Tab
local MainTab = Window:MakeTab({
    Name = "Main Features",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

MainTab:AddToggle({
    Name = "Auto Teleport",
    Default = false,
    Save = true,
    Flag = "autoTeleport",
    Callback = function(Value)
        isTeleporting = Value
        debugPrint("Auto Teleport " .. (Value and "enabled" or "disabled"))
    end    
})

MainTab:AddToggle({
    Name = "Auto Click",
    Default = false,
    Save = true,
    Flag = "autoClick",
    Callback = function(Value)
        isAutoClicking = Value
        debugPrint("Auto Click " .. (Value and "enabled" or "disabled"))
    end    
})

MainTab:AddToggle({
    Name = "Auto Rebirth",
    Default = false,
    Save = true,
    Flag = "autoRebirth",
    Callback = function(Value)
        isAutoRebirthing = Value
        debugPrint("Auto Rebirth " .. (Value and "enabled" or "disabled"))
    end    
})

-- Automation Tab
local AutomationTab = Window:MakeTab({
    Name = "Automation",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

AutomationTab:AddSlider({
    Name = "Click Interval",
    Min = 0.1,
    Max = 1,
    Default = 0.1,
    Color = Color3.fromRGB(255,255,255),
    Increment = 0.1,
    ValueName = "seconds",
    Save = true,
    Flag = "clickInterval",
    Callback = function(Value)
        clickInterval = Value
        debugPrint("Click Interval set to " .. Value)
    end    
})

AutomationTab:AddSlider({
    Name = "Teleport Interval",
    Min = 0.1,
    Max = 2,
    Default = 0.4,
    Color = Color3.fromRGB(255,255,255),
    Increment = 0.1,
    ValueName = "seconds",
    Save = true,
    Flag = "teleportInterval",
    Callback = function(Value)
        teleportInterval = Value
        debugPrint("Teleport Interval set to " .. Value)
    end    
})

AutomationTab:AddSlider({
    Name = "Rebirth Interval",
    Min = 0.1,
    Max = 1,
    Default = 0.1,
    Color = Color3.fromRGB(255,255,255),
    Increment = 0.1,
    ValueName = "seconds",
    Save = true,
    Flag = "rebirthInterval",
    Callback = function(Value)
        rebirthInterval = Value
        debugPrint("Rebirth Interval set to " .. Value)
    end    
})

-- Settings Tab
local SettingsTab = Window:MakeTab({
    Name = "Settings",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

SettingsTab:AddToggle({
    Name = "Debug Mode",
    Default = false,
    Save = true,
    Flag = "debugMode",
    Callback = function(Value)
        isDebugMode = Value
        print("Debug Mode " .. (Value and "enabled" or "disabled"))
    end    
})

SettingsTab:AddButton({
    Name = "Save Configuration",
    Callback = function()
        OrionLib:SaveConfiguration()
        OrionLib:MakeNotification({
            Name = "Configuration Saved",
            Content = "Your current settings have been saved.",
            Image = "rbxassetid://4483345998",
            Time = 5
        })
    end    
})

SettingsTab:AddButton({
    Name = "Load Configuration",
    Callback = function()
        OrionLib:LoadConfiguration()
        OrionLib:MakeNotification({
            Name = "Configuration Loaded",
            Content = "Your saved settings have been loaded.",
            Image = "rbxassetid://4483345998",
            Time = 5
        })
    end    
})

SettingsTab:AddButton({
    Name = "Destroy UI",
    Callback = function()
        OrionLib:Destroy()
    end    
})

-- Stats Section
local StatsSection = MainTab:AddSection({
    Name = "Player Stats"
})

local WinsLabel = StatsSection:AddLabel("Wins: 0")
local SpeedLabel = StatsSection:AddLabel("Speed: 0")

-- Update Stats
local function updateStats()
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local wins = leaderstats:FindFirstChild("Wins")
        local speed = leaderstats:FindFirstChild("Speed")
        if wins then
            WinsLabel:Set("Wins: " .. wins.Value)
        end
        if speed then
            SpeedLabel:Set("Speed: " .. speed.Value)
        end
    end
end

-- Loops
spawn(function()
    while wait(teleportInterval) do
        if isTeleporting then
            teleportToHighestWins()
        end
    end
end)

spawn(function()
    while wait(clickInterval) do
        if isAutoClicking then
            autoClick()
        end
    end
end)

spawn(function()
    while wait(rebirthInterval) do
        if isAutoRebirthing then
            autoRebirth()
        end
    end
end)

spawn(function()
    while wait(1) do
        updateStats()
    end
end)

-- Initialize
OrionLib:Init()

-- Load saved configuration
OrionLib:LoadConfiguration()
