local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("VectorArenaRemotes")
local bikeInputRemote = remotes:WaitForChild("BikeInput")

local held = {
    Boost = false,
}

local function setAction(action, isDown)
    if held[action] == isDown then
        return
    end
    held[action] = isDown
    bikeInputRemote:FireServer(action, isDown)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
        bikeInputRemote:FireServer("Left")
    elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
        bikeInputRemote:FireServer("Right")
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        setAction("Boost", true)
    elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        setAction("Boost", true)
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        setAction("Boost", false)
    elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        setAction("Boost", false)
    end
end)
