local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("VectorArenaRemotes")
local bikeHudRemote = remotes:WaitForChild("BikeHud")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BikeHudGui"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.AnchorPoint = Vector2.new(0.5, 1)
root.Position = UDim2.new(0.5, 0, 1, -30)
root.Size = UDim2.new(0, 460, 0, 110)
root.BackgroundTransparency = 1
root.Parent = screenGui

local function makePanel(name, pos, size)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Position = pos
    frame.Size = size
    frame.BackgroundColor3 = Color3.fromRGB(10, 16, 24)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = root

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 255, 255)
    stroke.Thickness = 1
    stroke.Transparency = 0.25
    stroke.Parent = frame

    return frame
end

local speedPanel = makePanel("SpeedPanel", UDim2.new(0, 0, 0, 0), UDim2.new(0, 220, 0, 110))
local boostPanel = makePanel("BoostPanel", UDim2.new(0, 240, 0, 0), UDim2.new(0, 220, 0, 110))

local function makeLabel(parent, text, pos, size, textSize)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = pos
    label.Size = size
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = Color3.fromRGB(235, 245, 255)
    label.TextSize = textSize
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local speedTitle = makeLabel(speedPanel, "SPEED", UDim2.new(0, 14, 0, 10), UDim2.new(0, 120, 0, 24), 16)
local speedValue = makeLabel(speedPanel, "0", UDim2.new(0, 14, 0, 30), UDim2.new(1, -28, 0, 32), 28)

local boostTitle = makeLabel(boostPanel, "BOOST", UDim2.new(0, 14, 0, 10), UDim2.new(0, 120, 0, 24), 16)
local boostReady = makeLabel(boostPanel, "", UDim2.new(0, 14, 0, 30), UDim2.new(1, -28, 0, 24), 18)

local function makeBar(parent, pos, size, fillColor)
    local barBg = Instance.new("Frame")
    barBg.Position = pos
    barBg.Size = size
    barBg.BackgroundColor3 = Color3.fromRGB(24, 32, 44)
    barBg.BorderSizePixel = 0
    barBg.Parent = parent

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 8)
    bgCorner.Parent = barBg

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = fillColor
    fill.BorderSizePixel = 0
    fill.Parent = barBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 8)
    fillCorner.Parent = fill

    return barBg, fill
end

local speedBarBg, speedFill = makeBar(speedPanel, UDim2.new(0, 14, 0, 72), UDim2.new(1, -28, 0, 20), Color3.fromRGB(0, 255, 255))
local boostBarBg, boostFill = makeBar(boostPanel, UDim2.new(0, 14, 0, 72), UDim2.new(1, -28, 0, 20), Color3.fromRGB(255, 0, 200))

local boostPercent = makeLabel(boostPanel, "0%", UDim2.new(0, 14, 0, 90), UDim2.new(1, -28, 0, 16), 14)

local function setBar(fill, ratio)
    ratio = math.clamp(ratio, 0, 1)
    fill.Size = UDim2.new(ratio, 0, 1, 0)
end

bikeHudRemote.OnClientEvent:Connect(function(data)
    if not data then
        screenGui.Enabled = false
        return
    end

    if data.Visible == false then
        screenGui.Enabled = false
        return
    end

    screenGui.Enabled = true

    local speed = data.Speed or 0
    local maxSpeed = math.max(1, data.MaxSpeed or 1)
    local boost = data.Boost or 0
    local maxBoost = math.max(1, data.MaxBoost or 1)

    speedValue.Text = tostring(math.floor(speed + 0.5))
    setBar(speedFill, speed / maxSpeed)

    boostPercent.Text = tostring(math.floor((boost / maxBoost) * 100 + 0.5)) .. "%"
    setBar(boostFill, boost / maxBoost)

    if data.BoostActive then
        boostReady.Text = "BOOSTING"
        boostFill.BackgroundColor3 = Color3.fromRGB(255, 120, 220)
        boostReady.TextColor3 = Color3.fromRGB(255, 120, 220)
    elseif data.BoostReady then
        boostReady.Text = "BOOST READY"
        boostFill.BackgroundColor3 = Color3.fromRGB(255, 120, 220)
        boostReady.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        boostReady.Text = "CHARGING"
        boostFill.BackgroundColor3 = Color3.fromRGB(255, 0, 200)
        boostReady.TextColor3 = Color3.fromRGB(180, 210, 255)
    end
    
    if boost / maxBoost <= 0.2 then
        boostPercent.TextColor3 = Color3.fromRGB(255, 120, 120)
    else
        boostPercent.TextColor3 = Color3.fromRGB(235, 245, 255)
    end
    
end)
