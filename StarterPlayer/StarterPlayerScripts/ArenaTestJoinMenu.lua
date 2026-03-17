local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("VectorArenaRemotes")
local modeRequestRemote = remotes:WaitForChild("ModeRequest")
local matchStateRemote = remotes:WaitForChild("MatchState")

local gui = Instance.new("ScreenGui")
gui.Name = "ArenaTestJoinMenuGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.new(0.5, 0, 0.5, 0)
root.Size = UDim2.new(0, 440, 0, 340)
root.BackgroundColor3 = Color3.fromRGB(10, 16, 24)
root.BackgroundTransparency = 0.12
root.BorderSizePixel = 0
root.Parent = gui

local rootCorner = Instance.new("UICorner")
rootCorner.CornerRadius = UDim.new(0, 14)
rootCorner.Parent = root

local rootStroke = Instance.new("UIStroke")
rootStroke.Color = Color3.fromRGB(0, 255, 255)
rootStroke.Thickness = 1
rootStroke.Transparency = 0.2
rootStroke.Parent = root

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 20, 0, 16)
title.Size = UDim2.new(1, -40, 0, 34)
title.Font = Enum.Font.GothamBold
title.Text = "VECTOR ARENA TEST"
title.TextColor3 = Color3.fromRGB(235, 245, 255)
title.TextSize = 26
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = root

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.new(0, 20, 0, 50)
subtitle.Size = UDim2.new(1, -40, 0, 22)
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "Arena-place temporary match menu"
subtitle.TextColor3 = Color3.fromRGB(160, 190, 220)
subtitle.TextSize = 14
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = root

local status = Instance.new("TextLabel")
status.Name = "Status"
status.BackgroundTransparency = 1
status.Position = UDim2.new(0, 20, 0, 80)
status.Size = UDim2.new(1, -40, 0, 24)
status.Font = Enum.Font.Gotham
status.Text = "Select a mode"
status.TextColor3 = Color3.fromRGB(190, 220, 255)
status.TextSize = 16
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = root

local function makeButton(text, y, enabled, modeName)
	local button = Instance.new("TextButton")
	button.Name = modeName .. "Button"
	button.Position = UDim2.new(0, 20, 0, y)
	button.Size = UDim2.new(1, -40, 0, 48)
	button.BackgroundColor3 = enabled and Color3.fromRGB(20, 30, 45) or Color3.fromRGB(28, 28, 34)
	button.BorderSizePixel = 0
	button.AutoButtonColor = enabled
	button.Text = text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 18
	button.TextColor3 = enabled and Color3.fromRGB(235, 245, 255) or Color3.fromRGB(130, 140, 150)
	button.Parent = root

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	if enabled then
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(0, 255, 255)
		stroke.Thickness = 1
		stroke.Transparency = 0.35
		stroke.Parent = button

		button.MouseButton1Click:Connect(function()
			status.Text = "Requesting " .. modeName .. "..."
			modeRequestRemote:FireServer(modeName)
		end)
	else
		button.MouseButton1Click:Connect(function()
			status.Text = modeName .. " is not enabled yet."
		end)
	end

	return button
end

makeButton("Practice", 120, true, "Practice")
makeButton("1v1", 176, true, "1v1")
makeButton("2v2", 232, false, "2v2")
makeButton("4 Player", 288, false, "4 Player")

local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "Message"
messageLabel.BackgroundTransparency = 1
messageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
messageLabel.Position = UDim2.new(0.5, 0, 0.18, 0)
messageLabel.Size = UDim2.new(0, 700, 0, 100)
messageLabel.Font = Enum.Font.GothamBlack
messageLabel.Text = ""
messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
messageLabel.TextScaled = true
messageLabel.Visible = false
messageLabel.Parent = gui

local function showMenu()
	root.Visible = true
end

local function hideMenu()
	root.Visible = false
end

local function showMessage(text)
	messageLabel.Visible = true
	messageLabel.Text = text or ""
end

local function hideMessage()
	messageLabel.Visible = false
	messageLabel.Text = ""
end

matchStateRemote.OnClientEvent:Connect(function(data)
	if not data then
		return
	end

	if data.State == "Queueing" then
		showMenu()
		hideMessage()
		status.Text = data.Text or "Waiting for another player..."
	elseif data.State == "Info" then
		showMenu()
		hideMessage()
		status.Text = data.Text or ""
	elseif data.State == "HideMenu" then
		hideMenu()
		hideMessage()
	elseif data.State == "ShowMenu" then
		showMenu()
		hideMessage()
		status.Text = "Select a mode"
	elseif data.State == "Countdown" then
		hideMenu()
		showMessage(data.Text)
	elseif data.State == "RoundInfo" then
		hideMenu()
		showMessage(data.Text)
	elseif data.State == "RoundResult" then
		hideMenu()
		showMessage(data.Text)
	elseif data.State == "MatchResult" then
		hideMenu()
		showMessage(data.Text)
	end
end)
