local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CubeBikeRuntime = require(game.ServerScriptService.VectorArena:WaitForChild("CubeBikeRuntime"))


local remotes = ReplicatedStorage:WaitForChild("VectorArenaRemotes")
local modeRequestRemote = remotes:WaitForChild("ModeRequest")
local matchStateRemote = remotes:WaitForChild("MatchState")
local bikeCameraRemote = remotes:WaitForChild("BikeCamera")

local bikeEliminatedEvent = game.ServerScriptService.VectorArena:WaitForChild("BikeEliminated")

local bikesFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Bikes")
local bikeTemplate = bikesFolder:WaitForChild("LightCycle") -- change if needed

local activeMatchesFolder = Workspace:FindFirstChild("ActiveMatches")
if not activeMatchesFolder then
    activeMatchesFolder = Instance.new("Folder")
    activeMatchesFolder.Name = "ActiveMatches"
    activeMatchesFolder.Parent = Workspace
end

local queue1v1 = {}
local playerBusy = {}
local activeMatches = {}
local nextMatchId = 1

local MODE_DEFS = {
	Practice = {
		PlayerCount = 1,
		BestOf = 1,
		TargetWins = 1,
		Spawns = {
			{Spawn = "Spawn_South", Direction = "Up", Color = Color3.fromRGB(0, 255, 255)},
		},
	},
	["1v1"] = {
		PlayerCount = 2,
		BestOf = 3,
		TargetWins = 2,
		Spawns = {
			{Spawn = "Spawn_North", Direction = "Down", Color = Color3.fromRGB(0, 255, 255)},
			{Spawn = "Spawn_South", Direction = "Up", Color = Color3.fromRGB(255, 0, 200)},
		},
	},
}

local function removeFromQueue(queue, player)
    for i = #queue, 1, -1 do
        if queue[i] == player then
            table.remove(queue, i)
        end
    end
end

local function notify(playersList, payload)
    for _, player in ipairs(playersList) do
        if player and player.Parent == Players then
            matchStateRemote:FireClient(player, payload)
        end
    end
end

local function getPlayerByUserId(userId)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.UserId == userId then
            return player
        end
    end
    return nil
end

local function clearMatchBikes(matchData)
    for _, bike in ipairs(matchData.Bikes) do
        if bike and bike.Parent then
            bike:Destroy()
        end
    end
    matchData.Bikes = {}
    matchData.AliveByUserId = {}
end

local function seatPlayerOnBike(player, bike)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")
	local seat = bike:WaitForChild("Body"):WaitForChild("Seat")

	hrp.CFrame = seat.CFrame + seat.CFrame.UpVector * 3
	task.wait(0.2)
	seat:Sit(humanoid)

	task.wait(0.15)
	if seat.Occupant ~= humanoid then
		hrp.CFrame = seat.CFrame + seat.CFrame.UpVector * 2.5
		task.wait(0.1)
		seat:Sit(humanoid)
	end

	-- tell the client camera which bike to follow
	bikeCameraRemote:FireClient(player, bike)
end

local function createBikeForPlayer(player, spawnDef, matchFolder, matchId)
	local bike = bikeTemplate:Clone()
	bike.Name = "LightCycle_" .. player.Name

	bike:SetAttribute("OwnerUserId", player.UserId)
	bike:SetAttribute("MatchId", matchId)
	bike:SetAttribute("MatchActive", false)

	bike.Parent = matchFolder

	CubeBikeRuntime.SpawnBike(
		bike,
		player,
		spawnDef.Spawn,
		spawnDef.Direction,
		spawnDef.Color
	)

	return bike
end

local function buildScoreText(matchData)
    local parts = {}
    for _, player in ipairs(matchData.Players) do
        local wins = matchData.RoundWins[player.UserId] or 0
        table.insert(parts, player.Name .. " " .. tostring(wins))
    end
    return table.concat(parts, "   |   ")
end

local function endMatch(matchData, winnerPlayer)
    matchData.Active = false
    clearMatchBikes(matchData)

    local playersList = matchData.Players
    notify(playersList, {
        State = "MatchResult",
        Text = winnerPlayer and (winnerPlayer.Name .. " wins the match!") or "Match over",
    })

    for _, player in ipairs(playersList) do
        playerBusy[player] = nil
    end

    task.delay(3, function()
        notify(playersList, {State = "ShowMenu"})
        if matchData.MatchFolder and matchData.MatchFolder.Parent then
            matchData.MatchFolder:Destroy()
        end
        activeMatches[matchData.MatchId] = nil
    end)
end

local function startCountdown(matchData)
    notify(matchData.Players, {
        State = "RoundInfo",
        Text = "Round " .. tostring(matchData.RoundNumber) .. "   |   " .. buildScoreText(matchData),
    })

    task.wait(1)

    for i = 3, 1, -1 do
        notify(matchData.Players, {State = "Countdown", Text = tostring(i)})
        task.wait(1)
    end

    notify(matchData.Players, {State = "Countdown", Text = "GO"})
    task.wait(0.4)

    for _, bike in ipairs(matchData.Bikes) do
        if bike and bike.Parent then
            bike:SetAttribute("MatchActive", true)
        end
    end
end

local function spawnRound(matchData)
    clearMatchBikes(matchData)

    for index, player in ipairs(matchData.Players) do
        local spawnDef = matchData.Mode.Spawns[index]
        local bike = createBikeForPlayer(player, spawnDef, matchData.MatchFolder, matchData.MatchId)
        table.insert(matchData.Bikes, bike)
        matchData.AliveByUserId[player.UserId] = true
    end

    task.wait(0.2)

    for i, player in ipairs(matchData.Players) do
        seatPlayerOnBike(player, matchData.Bikes[i])
    end

    task.spawn(function()
        startCountdown(matchData)
    end)
end

local function beginMatch(modeName, playersList)
    local mode = MODE_DEFS[modeName]
    if not mode then
        return
    end

    local matchFolder = Instance.new("Folder")
    local matchId = "Match_" .. tostring(nextMatchId)
    matchFolder.Name = matchId
    matchFolder.Parent = activeMatchesFolder
    nextMatchId += 1

    local matchData = {
        MatchId = matchId,
        ModeName = modeName,
        Mode = mode,
        Players = playersList,
        MatchFolder = matchFolder,
        Bikes = {},
        RoundWins = {},
        AliveByUserId = {},
        RoundNumber = 1,
        Active = true,
        RoundResolved = false,
    }

    for _, player in ipairs(playersList) do
        matchData.RoundWins[player.UserId] = 0
        playerBusy[player] = true
    end

    activeMatches[matchId] = matchData

    notify(playersList, {State = "HideMenu"})
    spawnRound(matchData)
end

local function resolveRound(matchData)
    if matchData.RoundResolved or not matchData.Active then
        return
    end

    matchData.RoundResolved = true

    local alivePlayers = {}
    for _, player in ipairs(matchData.Players) do
        if matchData.AliveByUserId[player.UserId] then
            table.insert(alivePlayers, player)
        end
    end

    local roundWinner = nil
    if #alivePlayers == 1 then
        roundWinner = alivePlayers[1]
    end

    if roundWinner then
        matchData.RoundWins[roundWinner.UserId] += 1
    end

    local targetWins = matchData.Mode.TargetWins or 1

    if roundWinner and matchData.RoundWins[roundWinner.UserId] >= targetWins then
        endMatch(matchData, roundWinner)
        return
    end

    if matchData.ModeName == "Practice" then
        endMatch(matchData, roundWinner)
        return
    end

    clearMatchBikes(matchData)

    local scoreText = buildScoreText(matchData)
    notify(matchData.Players, {
        State = "RoundResult",
        Text = (roundWinner and (roundWinner.Name .. " wins the round") or "Round over") .. "   |   " .. scoreText,
    })

    task.delay(3, function()
        if not matchData.Active then
            return
        end
        matchData.RoundNumber += 1
        matchData.RoundResolved = false
        spawnRound(matchData)
    end)
end

bikeEliminatedEvent.Event:Connect(function(matchId, ownerUserId, reason, bike)
    local matchData = activeMatches[matchId]
    if not matchData or not matchData.Active then
        return
    end

    if ownerUserId == nil then
        return
    end

    matchData.AliveByUserId[ownerUserId] = false

    local aliveCount = 0
    for _, player in ipairs(matchData.Players) do
        if matchData.AliveByUserId[player.UserId] then
            aliveCount += 1
        end
    end

    if aliveCount <= 1 then
        resolveRound(matchData)
    end
end)

modeRequestRemote.OnServerEvent:Connect(function(player, modeName)
    if playerBusy[player] then
        matchStateRemote:FireClient(player, {State = "Info", Text = "Already in a match."})
        return
    end

    if modeName == "Practice" then
        beginMatch("Practice", {player})
        return
    end

    if modeName == "1v1" then
        for _, queuedPlayer in ipairs(queue1v1) do
            if queuedPlayer == player then
                matchStateRemote:FireClient(player, {State = "Info", Text = "Already queued for 1v1."})
                return
            end
        end

        table.insert(queue1v1, player)

        if #queue1v1 >= 2 then
            local p1 = table.remove(queue1v1, 1)
            local p2 = table.remove(queue1v1, 1)

            if p1 and p2 and p1.Parent == Players and p2.Parent == Players then
                beginMatch("1v1", {p1, p2})
            end
        else
            matchStateRemote:FireClient(player, {State = "Queueing", Text = "Waiting for another player..."})
        end

        return
    end

    matchStateRemote:FireClient(player, {State = "Info", Text = "That mode is not enabled yet."})
end)

Players.PlayerRemoving:Connect(function(player)
    playerBusy[player] = nil
    removeFromQueue(queue1v1, player)
end)
