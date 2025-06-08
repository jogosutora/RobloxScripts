-- ============================================================================
-- ADVANCED FPS COUNTER + SETTINGS PANEL
-- ROBLOX AFTERBURNER V1

-- ============================================================================
-- VARIABLES
-- ============================================================================

-- GUI Positioning & Size
local GUI_SIZE = UDim2.new(0, 150, 0, 40)           -- Size of the FPS counter
local GUI_POSITION = UDim2.new(0, 10, 0, 10)       -- Position (top-left corner)
local GUI_ANCHOR_POINT = Vector2.new(0, 0)          -- Anchor point for positioning

-- Visual Styling
local BACKGROUND_COLOR = Color3.fromRGB(0, 0, 0)    -- Background color (black)
local BACKGROUND_TRANSPARENCY = 0.3                  -- Background transparency (30%)
local CORNER_RADIUS = 8                             -- Corner radius in pixels
local TEXT_SIZE = 18                                -- Font size
local TEXT_FONT = Enum.Font.RobotoMono              -- Font style

-- FPS Thresholds & Colors
local HIGH_FPS_THRESHOLD = 50                       -- FPS threshold for green color
local HIGH_FPS_COLOR = Color3.fromRGB(0, 255, 0)   -- Green color for good FPS
local LOW_FPS_COLOR = Color3.fromRGB(255, 0, 0)    -- Red color for poor FPS
local LABEL_COLOR = Color3.fromRGB(255, 255, 255)  -- Color for "FPS:" label

-- Performance Settings
local UPDATE_INTERVAL = 0.1                         -- How often to update FPS (seconds)
local FPS_SMOOTHING = 0.8                          -- Smoothing factor (0-1, higher = smoother)

-- Text Formatting
local FPS_PREFIX = "FPS: "                          -- Text before the FPS number
local FPS_SUFFIX = "/s"                             -- Text after the FPS number

-- Settings Panel
local SETTINGS_PANEL_SIZE = UDim2.new(0, 400, 0, 600)
local SETTINGS_BUTTON_SIZE = UDim2.new(0, 25, 0, 25)

-- ============================================================================
-- SCRIPT LOGIC
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Variables for FPS calculation
local lastTime = tick()
local frameCount = 0
local smoothedFPS = 60
local currentFPS = 60

-- Settings state variables
local settingsVisible = false
local lagPartsEnabled = false
local lagParts = {}
local lagConnection = nil
local wireframeEnabled = false
local fullbrightEnabled = false
local antiAliasEnabled = true
local shadowsEnabled = true
local particlesEnabled = true
local showPing = false
local showMemory = false
local vsyncEnabled = false
local currentPing = 0
local currentMemory = 0

-- Create the main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FPSCounterGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Create the background frame
local backgroundFrame = Instance.new("Frame")
backgroundFrame.Name = "FPSFrame"
backgroundFrame.Size = GUI_SIZE
backgroundFrame.Position = GUI_POSITION
backgroundFrame.AnchorPoint = GUI_ANCHOR_POINT
backgroundFrame.BackgroundColor3 = BACKGROUND_COLOR
backgroundFrame.BackgroundTransparency = BACKGROUND_TRANSPARENCY
backgroundFrame.BorderSizePixel = 0
backgroundFrame.Parent = screenGui

-- Add rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, CORNER_RADIUS)
corner.Parent = backgroundFrame

-- Create the FPS label
local fpsLabel = Instance.new("TextLabel")
fpsLabel.Name = "FPSLabel"
fpsLabel.Size = UDim2.new(0.8, 0, 1, 0)
fpsLabel.Position = UDim2.new(0, 0, 0, 0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = FPS_PREFIX .. "60" .. FPS_SUFFIX
fpsLabel.TextColor3 = LABEL_COLOR
fpsLabel.TextSize = TEXT_SIZE
fpsLabel.Font = TEXT_FONT
fpsLabel.TextStrokeTransparency = 0.5
fpsLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
fpsLabel.TextYAlignment = Enum.TextYAlignment.Center
fpsLabel.Parent = backgroundFrame

-- Create ping label (initially hidden)
local pingLabel = Instance.new("TextLabel")
pingLabel.Name = "PingLabel"
pingLabel.Size = UDim2.new(1, 0, 0, 20)
pingLabel.Position = UDim2.new(0, 0, 1, 5)
pingLabel.BackgroundColor3 = BACKGROUND_COLOR
pingLabel.BackgroundTransparency = BACKGROUND_TRANSPARENCY
pingLabel.BorderSizePixel = 0
pingLabel.Text = "Ping: 0ms"
pingLabel.TextColor3 = LABEL_COLOR
pingLabel.TextSize = 14
pingLabel.Font = TEXT_FONT
pingLabel.TextStrokeTransparency = 0.5
pingLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
pingLabel.Visible = false
pingLabel.Parent = backgroundFrame

local pingCorner = Instance.new("UICorner")
pingCorner.CornerRadius = UDim.new(0, CORNER_RADIUS)
pingCorner.Parent = pingLabel

-- Create memory label (initially hidden)
local memoryLabel = Instance.new("TextLabel")
memoryLabel.Name = "MemoryLabel"
memoryLabel.Size = UDim2.new(1, 0, 0, 20)
memoryLabel.Position = UDim2.new(0, 0, 1, 30)
memoryLabel.BackgroundColor3 = BACKGROUND_COLOR
memoryLabel.BackgroundTransparency = BACKGROUND_TRANSPARENCY
memoryLabel.BorderSizePixel = 0
memoryLabel.Text = "Memory: 0MB"
memoryLabel.TextColor3 = LABEL_COLOR
memoryLabel.TextSize = 14
memoryLabel.Font = TEXT_FONT
memoryLabel.TextStrokeTransparency = 0.5
memoryLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
memoryLabel.Visible = false
memoryLabel.Parent = backgroundFrame

local memoryCorner = Instance.new("UICorner")
memoryCorner.CornerRadius = UDim.new(0, CORNER_RADIUS)
memoryCorner.Parent = memoryLabel

-- Create the toggle button
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = SETTINGS_BUTTON_SIZE
toggleButton.Position = UDim2.new(1, -30, 0, 5)
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleButton.BackgroundTransparency = 0.2
toggleButton.BorderSizePixel = 0
toggleButton.Text = "+"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 16
toggleButton.Font = Enum.Font.RobotoMono
toggleButton.Parent = backgroundFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 4)
toggleCorner.Parent = toggleButton

-- Create settings panel
local settingsPanel = Instance.new("Frame")
settingsPanel.Name = "SettingsPanel"
settingsPanel.Size = SETTINGS_PANEL_SIZE
settingsPanel.Position = UDim2.new(0, 200, 0, 10)
settingsPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
settingsPanel.BackgroundTransparency = 0.1
settingsPanel.BorderSizePixel = 0
settingsPanel.Visible = false
settingsPanel.Parent = screenGui

local settingsCorner = Instance.new("UICorner")
settingsCorner.CornerRadius = UDim.new(0, 8)
settingsCorner.Parent = settingsPanel

-- Add scrolling frame for settings
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -60)
scrollFrame.Position = UDim2.new(0, 10, 0, 50)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 8
scrollFrame.Parent = settingsPanel

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = scrollFrame

-- Settings panel title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.Position = UDim2.new(0, 0, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Settings Panel"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 20
titleLabel.Font = Enum.Font.RobotoMono
titleLabel.Parent = settingsPanel

-- Infinite Yield button
local iyButton = Instance.new("ImageButton")
iyButton.Name = "InfiniteYieldButton"
iyButton.Size = UDim2.new(0, 30, 0, 30)
iyButton.Position = UDim2.new(1, -40, 0, 5)
iyButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
iyButton.BackgroundTransparency = 0.2
iyButton.BorderSizePixel = 0
iyButton.Image = "rbxassetid://126350002319868"
iyButton.Parent = settingsPanel

local iyCorner = Instance.new("UICorner")
iyCorner.CornerRadius = UDim.new(0, 4)
iyCorner.Parent = iyButton

-- Function to create toggle button
local function createToggleButton(name, defaultState, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundTransparency = 1
    frame.Parent = scrollFrame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 60, 0, 25)
    button.Position = UDim2.new(1, -65, 0, 2.5)
    button.BackgroundColor3 = defaultState and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
    button.BorderSizePixel = 0
    button.Text = defaultState and "ON" or "OFF"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 12
    button.Font = Enum.Font.RobotoMono
    button.Parent = frame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = button
    
    local state = defaultState
    button.MouseButton1Click:Connect(function()
        state = not state
        button.Text = state and "ON" or "OFF"
        button.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
        callback(state)
    end)
    
    return frame
end

-- Function to create slider
local function createSlider(name, minVal, maxVal, defaultVal, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundTransparency = 1
    frame.Parent = scrollFrame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. defaultVal
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, -20, 0, 20)
    sliderFrame.Position = UDim2.new(0, 10, 0, 25)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = frame
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 10)
    sliderCorner.Parent = sliderFrame
    
    local sliderButton = Instance.new("TextButton")
    local buttonWidth = 20
    sliderButton.Size = UDim2.new(0, buttonWidth, 1, 0)
    sliderButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    sliderButton.BorderSizePixel = 0
    sliderButton.Text = ""
    sliderButton.Parent = sliderFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 10)
    buttonCorner.Parent = sliderButton
    
    local function updateSlider(value)
        local percent = (value - minVal) / (maxVal - minVal)
        sliderButton.Position = UDim2.new(percent, -buttonWidth/2, 0, 0)
        label.Text = name .. ": " .. math.floor(value * 10) / 10
        callback(value)
    end
    
    updateSlider(defaultVal)
    
    local dragging = false
    local connection = nil
    
    -- Function to handle slider dragging
    local function handleSliderDrag(inputPosition)
        if dragging and sliderFrame.Parent then
            local relativeX = inputPosition.X - sliderFrame.AbsolutePosition.X
            local percent = math.clamp(relativeX / sliderFrame.AbsoluteSize.X, 0, 1)
            local value = minVal + (maxVal - minVal) * percent
            updateSlider(value)
        end
    end
    
    -- Mouse input for desktop
    sliderButton.MouseButton1Down:Connect(function()
        dragging = true
        connection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                handleSliderDrag(input.Position)
            end
        end)
    end)
    
    -- Touch input for mobile
    sliderButton.TouchTap:Connect(function()
        dragging = true
    end)
    
    sliderFrame.TouchTap:Connect(function(touch, gameProcessedEvent)
        if not gameProcessedEvent then
            local relativeX = touch.X - sliderFrame.AbsolutePosition.X
            local percent = math.clamp(relativeX / sliderFrame.AbsoluteSize.X, 0, 1)
            local value = minVal + (maxVal - minVal) * percent
            updateSlider(value)
        end
    end)
    
    -- Handle touch movement
    UserInputService.TouchMoved:Connect(function(touch, gameProcessedEvent)
        if dragging and not gameProcessedEvent then
            handleSliderDrag(touch.Position)
        end
    end)
    
    -- End dragging for both mouse and touch
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end)
    
    return frame
end

-- Function to create action button
local function createActionButton(name, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 30)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.BorderSizePixel = 0
    button.Text = name
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.Font = Enum.Font.Gotham
    button.Parent = scrollFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = button
    
    button.MouseButton1Click:Connect(callback)
    
    return button
end

-- Lag simulation functions
local function startLagSimulation(delay)
    if lagConnection then lagConnection:Disconnect() end
    lagConnection = RunService.Heartbeat:Connect(function()
        if lagPartsEnabled then
            local part = Instance.new("Part")
            part.Name = "LagPart"
            part.Size = Vector3.new(1, 1, 1)
            part.Position = Vector3.new(math.random(-100, 100), math.random(0, 50), math.random(-100, 100))
            part.BrickColor = BrickColor.random()
            part.Parent = Workspace
            table.insert(lagParts, part)
            wait(delay)
        end
    end)
end

local function stopLagSimulation()
    if lagConnection then
        lagConnection:Disconnect()
        lagConnection = nil
    end
end

local function deleteAllLagParts()
    for _, part in pairs(lagParts) do
        if part and part.Parent then
            part:Destroy()
        end
    end
    lagParts = {}
    
    -- Also delete any remaining LagParts in workspace
    for _, part in pairs(Workspace:GetChildren()) do
        if part.Name == "LagPart" then
            part:Destroy()
        end
    end
end

-- Ping measurement functions
local function measurePing()
    local startTime = tick()
    local success, result = pcall(function()
        -- Use Stats service to get network ping
        local networkStats = Stats.Network
        if networkStats and networkStats.ServerStatsItem then
            local pingStats = networkStats.ServerStatsItem["Data Ping"]
            if pingStats then
                return pingStats:GetValue()
            end
        end
        return 0
    end)
    
    if success and result then
        currentPing = math.floor(result + 0.5)
    else
        -- Fallback ping measurement using remote timing
        currentPing = math.floor((tick() - startTime) * 1000)
    end
end

-- Memory measurement function
local function measureMemory()
    local success, result = pcall(function()
        local memoryStats = Stats:FindFirstChild("MemoryStoreService")
        if memoryStats then
            return memoryStats:GetTotalMemoryUsageMb()
        else
            -- Fallback: estimate memory usage
            local totalObjects = 0
            for _, obj in pairs(game:GetDescendants()) do
                totalObjects = totalObjects + 1
            end
            return math.floor(totalObjects / 1000) -- Rough estimate
        end
    end)
    
    if success and result then
        currentMemory = math.floor(result + 0.5)
    else
        -- Another fallback method
        local gc = collectgarbage("count")
        currentMemory = math.floor(gc / 1024) -- Convert KB to MB
    end
end

-- VSync implementation
local vsyncConnection = nil
local targetFPS = 60

local function enableVSync()
    if vsyncConnection then vsyncConnection:Disconnect() end
    
    vsyncConnection = RunService.Heartbeat:Connect(function()
        local frameTime = 1 / targetFPS
        local currentTime = tick()
        local nextFrameTime = math.ceil(currentTime / frameTime) * frameTime
        local waitTime = nextFrameTime - currentTime
        
        if waitTime > 0 then
            wait(waitTime)
        end
    end)
end

local function disableVSync()
    if vsyncConnection then
        vsyncConnection:Disconnect()
        vsyncConnection = nil
    end
end

-- Function to update UI layout based on visible elements
local function updateUILayout()
    local yOffset = 0
    
    if showPing then
        pingLabel.Position = UDim2.new(0, 0, 1, 5)
        yOffset = yOffset + 25
    end
    
    if showMemory then
        memoryLabel.Position = UDim2.new(0, 0, 1, yOffset + 5)
        yOffset = yOffset + 25
    end
    
    -- Adjust main frame size if needed
    local extraHeight = yOffset > 0 and yOffset + 1 or 0
    backgroundFrame.Size = UDim2.new(GUI_SIZE.X.Scale, GUI_SIZE.X.Offset, GUI_SIZE.Y.Scale, GUI_SIZE.Y.Offset + extraHeight)
end
local function lerpColor(color1, color2, alpha)
    return Color3.new(
        color1.R + (color2.R - color1.R) * alpha,
        color1.G + (color2.G - color1.G) * alpha,
        color1.B + (color2.B - color1.B) * alpha
    )
end

local function getFPSColor(fps)
    if fps >= HIGH_FPS_THRESHOLD then
        return HIGH_FPS_COLOR
    else
        local factor = math.min(fps / HIGH_FPS_THRESHOLD, 1)
        return lerpColor(LOW_FPS_COLOR, HIGH_FPS_COLOR, factor)
    end
end

-- Create all settings
createToggleButton("Replicate Lag", false, function(state)
    lagPartsEnabled = state
    if state then
        startLagSimulation(0.1)
    else
        stopLagSimulation()
    end
end)

createActionButton("Delete All Lag Parts", deleteAllLagParts)

createSlider("Lag Delay", 0.01, 1, 0.1, function(value)
    if lagPartsEnabled then
        stopLagSimulation()
        startLagSimulation(value)
    end
end)

createSlider("UI Size Scale", 0.5, 3, 1, function(value)
    backgroundFrame.Size = UDim2.new(GUI_SIZE.X.Scale * value, GUI_SIZE.X.Offset * value, GUI_SIZE.Y.Scale * value, GUI_SIZE.Y.Offset * value)
end)

createSlider("UI Transparency", 0, 1, BACKGROUND_TRANSPARENCY, function(value)
    backgroundFrame.BackgroundTransparency = value
end)

createSlider("Corner Radius", 0, 20, CORNER_RADIUS, function(value)
    corner.CornerRadius = UDim.new(0, value)
end)

createSlider("Text Size", 8, 36, TEXT_SIZE, function(value)
    fpsLabel.TextSize = value
end)

createSlider("Update Rate", 0.01, 1, UPDATE_INTERVAL, function(value)
    UPDATE_INTERVAL = value
end)

createSlider("FPS Smoothing", 0, 1, FPS_SMOOTHING, function(value)
    FPS_SMOOTHING = value
end)

createSlider("FPS Threshold", 20, 120, HIGH_FPS_THRESHOLD, function(value)
    HIGH_FPS_THRESHOLD = value
end)

createToggleButton("Wireframe Mode", false, function(state)
    wireframeEnabled = state
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            if state then
                local selection = Instance.new("SelectionBox")
                selection.Adornee = obj
                selection.Parent = obj
                selection.Name = "WireframeBox"
                obj.Transparency = 0.8
            else
                local wireframe = obj:FindFirstChild("WireframeBox")
                if wireframe then wireframe:Destroy() end
                obj.Transparency = 0
            end
        end
    end
end)

createToggleButton("Fullbright", false, function(state)
    fullbrightEnabled = state
    if state then
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Brightness = 1
        Lighting.Ambient = Color3.fromRGB(70, 70, 70)
    end
end)

createToggleButton("Anti-Aliasing", true, function(state)
    antiAliasEnabled = state
    -- This would typically affect render settings
end)

createToggleButton("Shadows", true, function(state)
    shadowsEnabled = state
    Lighting.GlobalShadows = state
end)

createToggleButton("Particles", true, function(state)
    particlesEnabled = state
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
            obj.Enabled = state
        end
    end
end)

createSlider("Field of View", 30, 120, 70, function(value)
    if Workspace.CurrentCamera then
        Workspace.CurrentCamera.FieldOfView = value
    end
end)

createSlider("Mouse Sensitivity", 0.1, 5, 1, function(value)
    UserInputService.MouseDeltaSensitivity = value
end)

createToggleButton("Show Ping", false, function(state)
    showPing = state
    pingLabel.Visible = state
    updateUILayout()
    if state then
        -- Start ping measurement
        spawn(function()
            while showPing do
                measurePing()
                local pingColor = currentPing < 50 and Color3.fromRGB(0, 255, 0) or 
                                 currentPing < 100 and Color3.fromRGB(255, 255, 0) or 
                                 Color3.fromRGB(255, 0, 0)
                
                pingLabel.Text = string.format(
                    '<font color="rgb(255,255,255)">Ping: </font><font color="rgb(%d,%d,%d)">%dms</font>',
                    math.floor(pingColor.R * 255), math.floor(pingColor.G * 255), math.floor(pingColor.B * 255), currentPing
                )
                pingLabel.RichText = true
                wait(1) -- Update ping every second
            end
        end)
    end
end)

createToggleButton("Show Memory Usage", false, function(state)
    showMemory = state
    memoryLabel.Visible = state
    updateUILayout()
    if state then
        -- Start memory measurement
        spawn(function()
            while showMemory do
                measureMemory()
                local memoryColor = currentMemory < 100 and Color3.fromRGB(0, 255, 0) or 
                                  currentMemory < 500 and Color3.fromRGB(255, 255, 0) or 
                                  Color3.fromRGB(255, 0, 0)
                
                memoryLabel.Text = string.format(
                    '<font color="rgb(255,255,255)">Memory: </font><font color="rgb(%d,%d,%d)">%dMB</font>',
                    math.floor(memoryColor.R * 255), math.floor(memoryColor.G * 255), math.floor(memoryColor.B * 255), currentMemory
                )
                memoryLabel.RichText = true
                wait(2) -- Update memory every 2 seconds
            end
        end)
    end
end)

createToggleButton("VSync", false, function(state)
    vsyncEnabled = state
    if state then
        enableVSync()
    else
        disableVSync()
    end
end)

createActionButton("Reset All Settings", function()
    -- Reset to defaults
    lagPartsEnabled = false
    stopLagSimulation()
    deleteAllLagParts()
    backgroundFrame.Size = GUI_SIZE
    backgroundFrame.BackgroundTransparency = BACKGROUND_TRANSPARENCY
    corner.CornerRadius = UDim.new(0, CORNER_RADIUS)
    fpsLabel.TextSize = TEXT_SIZE
    
    -- Reset new features
    showPing = false
    showMemory = false
    vsyncEnabled = false
    pingLabel.Visible = false
    memoryLabel.Visible = false
    disableVSync()
    updateUILayout()
end)

-- Toggle settings panel
toggleButton.MouseButton1Click:Connect(function()
    settingsVisible = not settingsVisible
    settingsPanel.Visible = settingsVisible
    toggleButton.Text = settingsVisible and "-" or "+"
end)

-- Infinite Yield button
iyButton.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
end)

-- FPS update function
local function updateFPS()
    local currentTime = tick()
    local deltaTime = currentTime - lastTime
    
    if deltaTime >= UPDATE_INTERVAL then
        currentFPS = frameCount / deltaTime
        smoothedFPS = smoothedFPS * FPS_SMOOTHING + currentFPS * (1 - FPS_SMOOTHING)
        local displayFPS = math.floor(smoothedFPS + 0.5)
        local fpsColor = getFPSColor(smoothedFPS)
        
        local richText = string.format(
            '<font color="rgb(%d,%d,%d)">%s</font><font color="rgb(%d,%d,%d)">%d</font><font color="rgb(%d,%d,%d)">%s</font>',
            math.floor(LABEL_COLOR.R * 255), math.floor(LABEL_COLOR.G * 255), math.floor(LABEL_COLOR.B * 255), FPS_PREFIX,
            math.floor(fpsColor.R * 255), math.floor(fpsColor.G * 255), math.floor(fpsColor.B * 255), displayFPS,
            math.floor(LABEL_COLOR.R * 255), math.floor(LABEL_COLOR.G * 255), math.floor(LABEL_COLOR.B * 255), FPS_SUFFIX
        )
        
        fpsLabel.RichText = true
        fpsLabel.Text = richText
        
        frameCount = 0
        lastTime = currentTime
    end
    
    frameCount = frameCount + 1
end

-- Connect update function
local connection = RunService.RenderStepped:Connect(updateFPS)

-- Auto-resize scroll frame
scrollFrame.ChildAdded:Connect(function()
    local contentSize = listLayout.AbsoluteContentSize
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + 20)
end)

-- Cleanup
Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        connection:Disconnect()
        if lagConnection then lagConnection:Disconnect() end
        if vsyncConnection then vsyncConnection:Disconnect() end
        deleteAllLagParts()
        screenGui:Destroy()
    end
end)

print("roblox afterburner successfully loaded")

-- Extra
local Camera = workspace.CurrentCamera

-- Configuration
local playerBoxEsp = true -- adjust ts
local BOX_COLOR = Color3.fromRGB(0, 255, 0) -- Green color
local BOX_THICKNESS = 2
local BOX_TRANSPARENCY = 0.8

-- Storage for ESP objects
local espBoxes = {}
local connections = {}

-- Create box drawing function
local function createESPBox()
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = BOX_COLOR
    box.Thickness = BOX_THICKNESS
    box.Transparency = BOX_TRANSPARENCY
    box.Filled = false
    return box
end

-- Get character's bounding box in screen space
local function getCharacterBounds(character)
    if not character or not character.Parent then
        return nil
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return nil
    end
    
    local cf = humanoidRootPart.CFrame
    local size = character:GetExtentsSize()
    
    -- Calculate 3D bounding box corners
    local corners = {
        cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
        cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
        cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
        cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
        cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
        cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
        cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
        cf * CFrame.new(size.X/2, size.Y/2, size.Z/2)
    }
    
    -- Convert to screen space and find bounds
    local screenPoints = {}
    local allPointsOnScreen = true
    
    for i, corner in ipairs(corners) do
        local screenPoint, onScreen = Camera:WorldToViewportPoint(corner.Position)
        if onScreen then
            table.insert(screenPoints, Vector2.new(screenPoint.X, screenPoint.Y))
        else
            allPointsOnScreen = false
        end
    end
    
    if #screenPoints == 0 then
        return nil
    end
    
    -- Find min/max bounds
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    
    for _, point in ipairs(screenPoints) do
        minX = math.min(minX, point.X)
        minY = math.min(minY, point.Y)
        maxX = math.max(maxX, point.X)
        maxY = math.max(maxY, point.Y)
    end
    
    return {
        position = Vector2.new(minX, minY),
        size = Vector2.new(maxX - minX, maxY - minY),
        onScreen = allPointsOnScreen
    }
end

-- Update ESP box for a specific player
local function updateESPBox(player)
    local box = espBoxes[player.UserId]
    if not box then return end
    
    local character = player.Character
    if not character then
        box.Visible = false
        return
    end
    
    local bounds = getCharacterBounds(character)
    if not bounds or bounds.size.X <= 0 or bounds.size.Y <= 0 then
        box.Visible = false
        return
    end
    
    -- Update box properties
    box.Position = bounds.position
    box.Size = bounds.size
    box.Visible = playerBoxEsp and bounds.onScreen
end

-- Create ESP for a player
local function createPlayerESP(player)
    if player == player then return end
    
    local box = createESPBox()
    espBoxes[player.UserId] = box
    
    -- Update immediately if character exists
    if player.Character then
        updateESPBox(player)
    end
end

-- Remove ESP for a player
local function removePlayerESP(player)
    local box = espBoxes[player.UserId]
    if box then
        box:Remove()
        espBoxes[player.UserId] = nil
    end
end

-- Initialize ESP for all existing players
local function initializeESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= player then
            createPlayerESP(player)
        end
    end
end

-- Clean up all ESP
local function cleanupESP()
    for userId, box in pairs(espBoxes) do
        box:Remove()
    end
    espBoxes = {}
    
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    connections = {}
end

-- Main update loop
local function updateAllESP()
    if not playerBoxEsp then
        for _, box in pairs(espBoxes) do
            box.Visible = false
        end
        return
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= player and espBoxes[player.UserId] then
            updateESPBox(player)
        end
    end
end

-- Event connections
local function setupConnections()
    -- Player joined
    table.insert(connections, Players.PlayerAdded:Connect(function(player)
        createPlayerESP(player)
    end))
    
    -- Player left
    table.insert(connections, Players.PlayerRemoving:Connect(function(player)
        removePlayerESP(player)
    end))
    
    -- Character respawned
    table.insert(connections, Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            wait(0.1) -- Small delay to ensure character is fully loaded
            if espBoxes[player.UserId] then
                updateESPBox(player)
            end
        end)
    end))
    
    -- Handle existing players' character respawning
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= player then
            player.CharacterAdded:Connect(function()
                wait(0.1)
                if espBoxes[player.UserId] then
                    updateESPBox(player)
                end
            end)
        end
    end
    
    -- Main update loop
    table.insert(connections, RunService.Heartbeat:Connect(updateAllESP))
end

-- Main execution
if playerBoxEsp then
    print("Player Box ESP: Enabled")
    initializeESP()
    setupConnections()
else
    print("Player Box ESP: Disabled")
end

-- Public functions for external control
_G.PlayerBoxESP = {
    toggle = function()
        playerBoxEsp = not playerBoxEsp
        print("Player Box ESP:", playerBoxEsp and "Enabled" or "Disabled")
        if not playerBoxEsp then
            for _, box in pairs(espBoxes) do
                box.Visible = false
            end
        end
    end,
    
    enable = function()
        if not playerBoxEsp then
            playerBoxEsp = true
            print("Player Box ESP: Enabled")
            if next(espBoxes) == nil then
                initializeESP()
                setupConnections()
            end
        end
    end,
    
    disable = function()
        playerBoxEsp = false
        print("Player Box ESP: Disabled")
        for _, box in pairs(espBoxes) do
            box.Visible = false
        end
    end,
    
    cleanup = function()
        cleanupESP()
        print("Player Box ESP: Cleaned up")
    end,
    
    setColor = function(color)
        BOX_COLOR = color
        for _, box in pairs(espBoxes) do
            box.Color = color
        end
        print("Player Box ESP: Color updated")
    end
}
-- end ~1055 lines
