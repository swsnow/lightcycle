local bike = script.Parent
local seat = bike:WaitForChild("Body"):WaitForChild("Seat")
local prompt = bike:WaitForChild("Body"):WaitForChild("ProximityPrompt")

prompt.Triggered:Connect(function(player)
    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    -- Move player near the seat first
    hrp.CFrame = seat.CFrame + seat.CFrame.UpVector * 2

    task.wait(0.1)

    -- Force sit
    seat:Sit(humanoid)
end)
