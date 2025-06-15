animateStatusDot()

-- ===============================
-- HVH FUNCTIONS IMPLEMENTATION
-- ===============================

-- Utility Functions
local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (player.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closestPlayer = v
            end
        end
    end
    
    return closestPlayer
end

local function getPlayerHealth(targetPlayer)
    if targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") then
        return targetPlayer.Character.Humanoid.Health / targetPlayer.Character.Humanoid.MaxHealth
    end
    return 1
end

local function worldToScreen(position)
    local camera = workspace.CurrentCamera
    local point, onScreen = camera:WorldToScreenPoint(position)
    return Vector2.new(point.X, point.Y), onScreen
end

-- ESP Functions
local function createESP(targetPlayer)
    if ESPObjects[targetPlayer] then return end
    
    local espFolder = Instance.new("Folder")
    espFolder.Name = "ESP_" .. targetPlayer.Name
    espFolder.Parent = screenGui
    
    ESPObjects[targetPlayer] = {
        folder = espFolder,
        boxes = {},
        text = {},
        skeleton = {},
        chams = {}
    }
    
    -- Create 2D Box ESP
    local box = Instance.new("Frame")
    box.Name = "Box"
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 2
    box.BorderColor3 = Color3.fromRGB(255, 0, 0)
    box.Parent = espFolder
    ESPObjects[targetPlayer].boxes.box2D = box
    
    -- Create Name Tag
    local nameTag = Instance.new("TextLabel")
    nameTag.Name = "NameTag"
    nameTag.BackgroundTransparency = 1
    nameTag.Font = Enum.Font.GothamBold
    nameTag.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameTag.TextSize = 12
    nameTag.TextStrokeTransparency = 0
    nameTag.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameTag.Text = targetPlayer.Name
    nameTag.Parent = espFolder
    ESPObjects[targetPlayer].text.nameTag = nameTag
    
    -- Create Chams
    if targetPlayer.Character then
        for _, part in pairs(targetPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                local highlight = Instance.new("Highlight")
                highlight.Parent = part
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
                ESPObjects[targetPlayer].chams[part] = highlight
            end
        end
    end
end

local function updateESP()
    for targetPlayer, espData in pairs(ESPObjects) do
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = targetPlayer.Character.HumanoidRootPart
            local head = targetPlayer.Character:FindFirstChild("Head")
            
            if head then
                local screenPos, onScreen = worldToScreen(hrp.Position)
                local headScreenPos = worldToScreen(head.Position + Vector3.new(0, 1, 0))
                
                if onScreen then
                    -- Update 2D Box
                    if HVHSettings.ESP.Boxes2D and espData.boxes.box2D then
                        local box = espData.boxes.box2D
                        local distance = (player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                        local size = math.max(2000 / distance, 4)
                        
                        box.Size = UDim2.new(0, size, 0, size * 1.5)
                        box.Position = UDim2.new(0, screenPos.X - size/2, 0, screenPos.Y - size * 0.75)
                        box.Visible = true
                        
                        -- Health-based coloring
                        if HVHSettings.ESP.HealthBased then
                            local health = getPlayerHealth(targetPlayer)
                            box.BorderColor3 = Color3.fromRGB(255 * (1-health), 255 * health, 0)
                        end
                    else
                        if espData.boxes.box2D then espData.boxes.box2D.Visible = false end
                    end
                    
                    -- Update Name Tag
                    if HVHSettings.ESP.NameTags and espData.text.nameTag then
                        local nameTag = espData.text.nameTag
                        nameTag.Position = UDim2.new(0, headScreenPos.X - 50, 0, headScreenPos.Y - 30)
                        nameTag.Size = UDim2.new(0, 100, 0, 20)
                        nameTag.Visible = true
                    else
                        if espData.text.nameTag then espData.text.nameTag.Visible = false end
                    end
                    
                    -- Update Chams
                    for part, highlight in pairs(espData.chams) do
                        if highlight then
                            highlight.Enabled = HVHSettings.ESP.Chams
                            if HVHSettings.ESP.HealthBased then
                                local health = getPlayerHealth(targetPlayer)
                                highlight.FillColor = Color3.fromRGB(255 * (1-health), 255 * health, 0)
                            end
                        end
                    end
                else
                    -- Hide ESP when off-screen
                    if espData.boxes.box2D then espData.boxes.box2D.Visible = false end
                    if espData.text.nameTag then espData.text.nameTag.Visible = false end
                end
            end
        end
    end
end

-- Aimbot Functions
local function aimbot()
    if not HVHSettings.Aimbot.Enabled then return end
    
    local target = getClosestPlayer()
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local targetHead = target.Character.Head
        local targetPos = targetHead.Position
        
        -- Add prediction for moving targets
        if target.Character:FindFirstChild("HumanoidRootPart") then
            local velocity = target.Character.HumanoidRootPart.Velocity
            targetPos = targetPos + (velocity * 0.1)
        end
        
        local camera = workspace.CurrentCamera
        local currentCFrame = camera.CFrame
        local targetCFrame = CFrame.lookAt(currentCFrame.Position, targetPos)
        
        -- Smooth aiming
        local smoothedCFrame = currentCFrame:Lerp(targetCFrame, 1 / HVHSettings.Aimbot.Smoothness)
        camera.CFrame = smoothedCFrame
    end
end

-- CamLock Functions
local function camLock()
    if not HVHSettings.CamLock.Enabled then return end
    
    if not CamLockTarget then
        CamLockTarget = getClosestPlayer()
    end
    
    if CamLockTarget and CamLockTarget.Character and CamLockTarget.Character:FindFirstChild("Head") then
        local targetHead = CamLockTarget.Character.Head
        local targetPos = targetHead.Position
        
        -- Prediction
        if HVHSettings.CamLock.Prediction and CamLockTarget.Character:FindFirstChild("HumanoidRootPart") then
            local velocity = CamLockTarget.Character.HumanoidRootPart.Velocity
            targetPos = targetPos + (velocity * HVHSettings.CamLock.PredictionAmount)
        end
        
        local camera = workspace.CurrentCamera
        camera.CFrame = CFrame.lookAt(camera.CFrame.Position, targetPos)
    end
end

-- Anti-Aim Functions
local function antiAim()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = player.Character.HumanoidRootPart
    local currentTime = tick()
    
    if HVHSettings.AntiAim.PitchDown then
        -- Pitch down (look down)
        local camera = workspace.CurrentCamera
        local currentCFrame = camera.CFrame
        local pitchDown = CFrame.Angles(math.rad(-89), 0, 0)
        camera.CFrame = currentCFrame * pitchDown
    end
    
    if HVHSettings.AntiAim.YawSpin then
        -- Yaw spinning
        local spinAngle = currentTime * HVHSettings.AntiAim.SpinSpeed
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinAngle), 0)
    end
end

-- Movement Functions
local function speedHack()
    if not HVHSettings.Movement.SpeedHack or not player.Character then return end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 16 * HVHSettings.Movement.SpeedMultiplier
    end
end

local function flyMode()
    if not HVHSettings.Movement.FlyMode or not player.Character then return end
    
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local bodyVelocity = hrp:FindFirstChild("FlyVelocity") or Instance.new("BodyVelocity")
        bodyVelocity.Name = "FlyVelocity"
        bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = hrp
        
        -- Simple WASD fly controls
        local camera = workspace.CurrentCamera
        local moveVector = Vector3.new(0, 0, 0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveVector = moveVector + camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveVector = moveVector - camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveVector = moveVector - camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveVector = moveVector + camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVector = moveVector + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveVector = moveVector - Vector3.new(0, 1, 0)
        end
        
        bodyVelocity.Velocity = moveVector * 50
    end
end

local function disableFly()
    if player.Character then
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local bodyVelocity = hrp:FindFirstChild("FlyVelocity")
            if bodyVelocity then
                bodyVelocity:Destroy()
            end
        end
    end
end

-- Toggle Handler
function handleToggleAction(settingPath, enabled)
    if settingPath == "ESP.PlayerESP" then
        if enabled then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player then
                    createESP(p)
                end
            end
        else
            for _, espData in pairs(ESPObjects) do
                if espData.folder then
                    espData.folder:Destroy()
                end
            end
            ESPObjects = {}
        end
    elseif settingPath == "CamLock.Enabled" then
        if not enabled then
            CamLockTarget = nil
        end
    elseif settingPath == "AntiAim.PitchDown" or settingPath == "AntiAim.YawSpin" then
        if enabled and not AntiAimConnection then
            AntiAimConnection = RunService.Heartbeat:Connect(antiAim)
        elseif not enabled and AntiAimConnection then
            AntiAimConnection:Disconnect()
            AntiAimConnection = nil
        end
    elseif settingPath == "Movement.SpeedHack" then
        if enabled and not SpeedConnection then
            SpeedConnection = RunService.Heartbeat:Connect(speedHack)
        elseif not enabled and SpeedConnection then
            SpeedConnection:Disconnect()
            -- SynTest HVH GUI
-- Created for Roblox HVH Game

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Mouse = game.Players.LocalPlayer:GetMouse()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- HVH Settings Storage
local HVHSettings = {
    Aimbot = {
        Enabled = true,
        SilentAim = false,
        FOV = 100,
        Smoothness = 5
    },
    CamLock = {
        Enabled = true,
        Prediction = true,
        PredictionAmount = 0.12
    },
    Triggerbot = {
        AutoTrigger = false,
        BurstMode = true,
        Delay = 0.1
    },
    AntiAim = {
        PitchDown = true,
        YawSpin = false,
        SpinSpeed = 10
    },
    Resolver = {
        Enabled = true,
        Bruteforce = false
    },
    ESP = {
        PlayerESP = true,
        NameTags = false,
        Boxes2D = true,
        Boxes3D = false,
        Skeleton = false,
        HealthBased = true,
        Chams = true,
        Wireframe = false
    },
    Movement = {
        AutoBhop = false,
        LegitMode = true,
        SpeedHack = false,
        FlyMode = false,
        SpeedMultiplier = 2
    },
    Misc = {
        NoRecoil = true,
        InfiniteAmmo = false,
        RageQuit = false,
        ChatSpam = false
    }
}

-- ESP Storage
local ESPObjects = {}
local CamLockTarget = nil
local AntiAimConnection = nil
local SpeedConnection = nil
local FlyConnection = nil

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SynTestGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 450, 0, 350)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Gradient for main frame
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))
})
gradient.Rotation = 45
gradient.Parent = mainFrame

-- Corner rounding
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

-- Title gradient
local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 45, 85)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(85, 45, 120))
})
titleGradient.Rotation = 90
titleGradient.Parent = titleBar

-- Title Text
local titleText = Instance.new("TextLabel")
titleText.Name = "TitleText"
titleText.Size = UDim2.new(1, -80, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Font = Enum.Font.GothamBold
titleText.Text = "SynTest v2.1 | HVH Mode"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = 14
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- Status indicator
local statusDot = Instance.new("Frame")
statusDot.Name = "StatusDot"
statusDot.Size = UDim2.new(0, 8, 0, 8)
statusDot.Position = UDim2.new(1, -60, 0.5, -4)
statusDot.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
statusDot.BorderSizePixel = 0
statusDot.Parent = titleBar

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = statusDot

-- Status text
local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(0, 35, 1, 0)
statusText.Position = UDim2.new(1, -45, 0, 0)
statusText.BackgroundTransparency = 1
statusText.Font = Enum.Font.Gotham
statusText.Text = "ACTIVE"
statusText.TextColor3 = Color3.fromRGB(0, 255, 0)
statusText.TextSize = 10
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = titleBar

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 25, 0, 25)
closeButton.Position = UDim2.new(1, -30, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "×"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 16
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeButton

-- Content Frame
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -20, 1, -50)
contentFrame.Position = UDim2.new(0, 10, 0, 40)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Tabs
local tabFrame = Instance.new("Frame")
tabFrame.Name = "TabFrame"
tabFrame.Size = UDim2.new(1, 0, 0, 30)
tabFrame.Position = UDim2.new(0, 0, 0, 0)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = contentFrame

local tabs = {"Combat", "Visuals", "Movement", "Misc", "Config"}
local tabButtons = {}
local activeTab = 1

for i, tabName in ipairs(tabs) do
    local tabButton = Instance.new("TextButton")
    tabButton.Name = tabName .. "Tab"
    tabButton.Size = UDim2.new(0, 80, 1, 0)
    tabButton.Position = UDim2.new(0, (i-1) * 85, 0, 0)
    tabButton.BackgroundColor3 = i == 1 and Color3.fromRGB(70, 50, 100) or Color3.fromRGB(40, 40, 55)
    tabButton.BorderSizePixel = 0
    tabButton.Font = Enum.Font.Gotham
    tabButton.Text = tabName
    tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabButton.TextSize = 11
    tabButton.Parent = tabFrame
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 5)
    tabCorner.Parent = tabButton
    
    tabButtons[i] = tabButton
end

-- Content Areas
local contentAreas = {}

-- Combat Tab Content
local combatContent = Instance.new("ScrollingFrame")
combatContent.Name = "CombatContent"
combatContent.Size = UDim2.new(1, 0, 1, -40)
combatContent.Position = UDim2.new(0, 0, 0, 35)
combatContent.BackgroundTransparency = 1
combatContent.BorderSizePixel = 0
combatContent.ScrollBarThickness = 5
combatContent.ScrollBarImageColor3 = Color3.fromRGB(70, 50, 100)
combatContent.CanvasSize = UDim2.new(0, 0, 0, 480)
combatContent.Parent = contentFrame
contentAreas[1] = combatContent

-- Function to create sections
local function createSection(parent, title, yPos)
    local section = Instance.new("Frame")
    section.Name = title .. "Section"
    section.Size = UDim2.new(1, -10, 0, 80)
    section.Position = UDim2.new(0, 5, 0, yPos)
    section.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    section.BorderSizePixel = 0
    section.Parent = parent
    
    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = UDim.new(0, 6)
    sectionCorner.Parent = section
    
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Size = UDim2.new(1, -10, 0, 20)
    sectionTitle.Position = UDim2.new(0, 5, 0, 5)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.Text = title
    sectionTitle.TextColor3 = Color3.fromRGB(150, 120, 200)
    sectionTitle.TextSize = 12
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Parent = section
    
    return section
end

-- Function to create toggle
local function createToggle(parent, text, xPos, yPos, defaultState, settingPath)
    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(0, 15, 0, 15)
    toggle.Position = UDim2.new(0, xPos, 0, yPos)
    toggle.BackgroundColor3 = defaultState and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(60, 60, 80)
    toggle.BorderSizePixel = 0
    toggle.Parent = parent
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 3)
    toggleCorner.Parent = toggle
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(1, 0, 1, 0)
    toggleButton.BackgroundTransparency = 1
    toggleButton.Text = ""
    toggleButton.Parent = toggle
    
    local toggleText = Instance.new("TextLabel")
    toggleText.Size = UDim2.new(0, 200, 1, 0)
    toggleText.Position = UDim2.new(0, 25, 0, 0)
    toggleText.BackgroundTransparency = 1
    toggleText.Font = Enum.Font.Gotham
    toggleText.Text = text
    toggleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleText.TextSize = 11
    toggleText.TextXAlignment = Enum.TextXAlignment.Left
    toggleText.Parent = toggle
    
    local isEnabled = defaultState
    
    -- Set initial setting
    if settingPath then
        local categories = string.split(settingPath, ".")
        local setting = HVHSettings
        for i = 1, #categories - 1 do
            setting = setting[categories[i]]
        end
        setting[categories[#categories]] = isEnabled
    end
    
    toggleButton.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        toggle.BackgroundColor3 = isEnabled and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(60, 60, 80)
        
        -- Update setting
        if settingPath then
            local categories = string.split(settingPath, ".")
            local setting = HVHSettings
            for i = 1, #categories - 1 do
                setting = setting[categories[i]]
            end
            setting[categories[#categories]] = isEnabled
            
            -- Handle specific toggle actions
            handleToggleAction(settingPath, isEnabled)
        end
        
        -- Add toggle effect
        local tween = TweenService:Create(toggle, TweenInfo.new(0.2), {Size = UDim2.new(0, 18, 0, 18)})
        tween:Play()
        tween.Completed:Connect(function()
            TweenService:Create(toggle, TweenInfo.new(0.2), {Size = UDim2.new(0, 15, 0, 15)}):Play()
        end)
    end)
    
    return toggle
end

-- Create Combat sections
local aimSection = createSection(combatContent, "🎯 Aimbot", 10)
createToggle(aimSection, "Enable Aimbot", 10, 30, true, "Aimbot.Enabled")
createToggle(aimSection, "Silent Aim", 10, 50, false, "Aimbot.SilentAim")

local triggerSection = createSection(combatContent, "⚡ Triggerbot", 100)
createToggle(triggerSection, "Auto Trigger", 10, 30, false, "Triggerbot.AutoTrigger")
createToggle(triggerSection, "Burst Mode", 10, 50, true, "Triggerbot.BurstMode")

local camLockSection = createSection(combatContent, "🔒 CamLock", 190)
createToggle(camLockSection, "Enable CamLock", 10, 30, true, "CamLock.Enabled")
createToggle(camLockSection, "Prediction", 10, 50, true, "CamLock.Prediction")

local antiAimSection = createSection(combatContent, "🌀 Anti-Aim", 280)
createToggle(antiAimSection, "Pitch: Down", 10, 30, true, "AntiAim.PitchDown")
createToggle(antiAimSection, "Yaw: Spin", 10, 50, false, "AntiAim.YawSpin")

local resolverSection = createSection(combatContent, "🔄 Resolver", 370)
createToggle(resolverSection, "Enable Resolver", 10, 30, true, "Resolver.Enabled")
createToggle(resolverSection, "Bruteforce", 10, 50, false, "Resolver.Bruteforce")

-- Create other content areas (simplified)
for i = 2, 5 do
    local content = Instance.new("ScrollingFrame")
    content.Name = tabs[i] .. "Content"
    content.Size = UDim2.new(1, 0, 1, -40)
    content.Position = UDim2.new(0, 0, 0, 35)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 5
    content.ScrollBarImageColor3 = Color3.fromRGB(70, 50, 100)
    content.CanvasSize = UDim2.new(0, 0, 0, 400)
    content.Visible = false
    content.Parent = contentFrame
    contentAreas[i] = content
end

-- Visuals Tab Content (i=2)
local visualsContent = contentAreas[2]

local espSection = createSection(visualsContent, "👁️ ESP", 10)
createToggle(espSection, "Player ESP", 10, 30, true, "ESP.PlayerESP")
createToggle(espSection, "Name Tags", 10, 50, false, "ESP.NameTags")

local boxSection = createSection(visualsContent, "📦 Box ESP", 100)
createToggle(boxSection, "2D Boxes", 10, 30, true, "ESP.Boxes2D")
createToggle(boxSection, "3D Boxes", 10, 50, false, "ESP.Boxes3D")

local skeletonSection = createSection(visualsContent, "🦴 Skeleton", 190)
createToggle(skeletonSection, "Skeleton ESP", 10, 30, false, "ESP.Skeleton")
createToggle(skeletonSection, "Health Based", 10, 50, true, "ESP.HealthBased")

local chamsSection = createSection(visualsContent, "✨ Chams", 280)
createToggle(chamsSection, "Player Chams", 10, 30, true, "ESP.Chams")
createToggle(chamsSection, "Wireframe", 10, 50, false, "ESP.Wireframe")

-- Movement Tab Content (i=3)
local movementContent = contentAreas[3]

local bhopSection = createSection(movementContent, "🦘 Bhop", 10)
createToggle(bhopSection, "Auto Bhop", 10, 30, false, "Movement.AutoBhop")
createToggle(bhopSection, "Legit Mode", 10, 50, true, "Movement.LegitMode")

local speedSection = createSection(movementContent, "💨 Speed", 100)
createToggle(speedSection, "Speed Hack", 10, 30, false, "Movement.SpeedHack")
createToggle(speedSection, "Fly Mode", 10, 50, false, "Movement.FlyMode")

-- Misc Tab Content (i=4)
local miscContent = contentAreas[4]

local otherSection = createSection(miscContent, "🔧 Other", 10)
createToggle(otherSection, "No Recoil", 10, 30, true, "Misc.NoRecoil")
createToggle(otherSection, "Infinite Ammo", 10, 50, false, "Misc.InfiniteAmmo")

local rageSection = createSection(miscContent, "😡 Rage", 100)
createToggle(rageSection, "Rage Quit", 10, 30, false, "Misc.RageQuit")
createToggle(rageSection, "Chat Spam", 10, 50, false, "Misc.ChatSpam")

-- Config Tab Content (i=5)
local configContent = contentAreas[5]

-- Add config buttons
local configSection = createSection(configContent, "💾 Config", 10)

local saveButton = Instance.new("TextButton")
saveButton.Size = UDim2.new(0, 80, 0, 25)
saveButton.Position = UDim2.new(0, 10, 0, 30)
saveButton.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
saveButton.BorderSizePixel = 0
saveButton.Font = Enum.Font.Gotham
saveButton.Text = "Save Config"
saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
saveButton.TextSize = 10
saveButton.Parent = configSection

local saveCorner = Instance.new("UICorner")
saveCorner.CornerRadius = UDim.new(0, 4)
saveCorner.Parent = saveButton

local loadButton = Instance.new("TextButton")
loadButton.Size = UDim2.new(0, 80, 0, 25)
loadButton.Position = UDim2.new(0, 100, 0, 30)
loadButton.BackgroundColor3 = Color3.fromRGB(100, 200, 50)
loadButton.BorderSizePixel = 0
loadButton.Font = Enum.Font.Gotham
loadButton.Text = "Load Config"
loadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
loadButton.TextSize = 10
loadButton.Parent = configSection

local loadCorner = Instance.new("UICorner")
loadCorner.CornerRadius = UDim.new(0, 4)
loadCorner.Parent = loadButton

-- Tab switching functionality
for i, button in ipairs(tabButtons) do
    button.MouseButton1Click:Connect(function()
        -- Hide all content areas
        for j, area in ipairs(contentAreas) do
            area.Visible = false
        end
        
        -- Update tab appearances
        for j, tab in ipairs(tabButtons) do
            tab.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        end
        
        -- Show selected content and highlight tab
        contentAreas[i].Visible = true
        button.BackgroundColor3 = Color3.fromRGB(70, 50, 100)
        activeTab = i
    end)
end

-- Close button functionality
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Animate GUI entrance
mainFrame.Size = UDim2.new(0, 0, 0, 0)
local entranceTween = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
    Size = UDim2.new(0, 450, 0, 350)
})
entranceTween:Play()

-- Animate status dot
local function animateStatusDot()
    local tween1 = TweenService:Create(statusDot, TweenInfo.new(1, Enum.EasingStyle.Sine), {
        BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    })
    local tween2 = TweenService:Create(statusDot, TweenInfo.new(1, Enum.EasingStyle.Sine), {
        BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    })
    
    tween1:Play()
    tween1.Completed:Connect(function()
        tween2:Play()
        tween2.Completed:Connect(animateStatusDot)
    end)
end

animateStatusDot()

print("SynTest HVH GUI loaded successfully!")
