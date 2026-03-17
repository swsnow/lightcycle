local CubeBikeRuntime = {}

local CubeGridUtil = require(script.Parent:WaitForChild("CubeGridUtil"))
local CubeTrailService = require(script.Parent:WaitForChild("CubeTrailService"))

local RunService = game:GetService("RunService")

local MOVE_INTERVAL = 0.06
local BASE_SPEED = 1
local BOOST_SPEED = 2

local activeBikes = {}

--local MODEL_YAW_OFFSET = math.rad(-90) -- try -90 first; if wrong, use 90

local function updateBikeWorld(bikeState)
	local worldPos = CubeGridUtil.FaceCellToWorld(
		bikeState.Face,
		bikeState.CellU,
		bikeState.CellV,
		CubeGridUtil.GetRideOffset()
	)

	local forward = CubeGridUtil.GetWorldDirection(
		bikeState.Face,
		bikeState.Direction
	).Unit

	local up = CubeGridUtil.GetFaceConfig(bikeState.Face).Normal.Unit

	bikeState.RootPart.CFrame = CFrame.lookAt(worldPos, worldPos + forward, up)
end


function CubeBikeRuntime.SpawnBike(bikeModel, player, spawnName, directionName, trailColor)
	local root = bikeModel:WaitForChild("RootPart")

	local spawnPos = CubeGridUtil.GetSpawnWorld(spawnName)

	-- For now, all arena spawns are on the Floor face
	local face = "Floor"

	local cellU, cellV = CubeGridUtil.WorldToFaceCell(face, spawnPos)

	local bikeId = bikeModel.Name

	local state = {
		BikeId = bikeId,
		Model = bikeModel,
		Player = player,
		RootPart = root,
		Face = face,
		CellU = cellU,
		CellV = cellV,
		Direction = directionName or "Up",
		LastMove = 0,
		Boosting = false,
		TrailColor = trailColor or Color3.fromRGB(0, 255, 255),
	}

	activeBikes[bikeId] = state

	updateBikeWorld(state)

	CubeTrailService.MarkCell(face, bikeId, cellU, cellV)

	local startPos = CubeGridUtil.FaceCellToWorld(
		face,
		cellU,
		cellV,
		CubeGridUtil.GetRideOffset()
	)

	CubeTrailService.StartSegment(
		bikeId,
		startPos,
		state.TrailColor,
		CubeGridUtil.GetCommonConfig().CellSize
	)

	return state
end

function CubeBikeRuntime.TurnLeft(bikeId)
    local bike = activeBikes[bikeId]
    if not bike then return end

    bike.Direction = CubeGridUtil.RotateLeft(bike.Direction)
end

function CubeBikeRuntime.TurnRight(bikeId)
    local bike = activeBikes[bikeId]
    if not bike then return end

    bike.Direction = CubeGridUtil.RotateRight(bike.Direction)
end

function CubeBikeRuntime.SetBoost(bikeId, enabled)
    local bike = activeBikes[bikeId]
    if not bike then return end

    bike.Boosting = enabled
end

local function stepBike(bike)
    local result = CubeGridUtil.Step(
        bike.Face,
        bike.CellU,
        bike.CellV,
        bike.Direction
    )

    local nextFace = result.Face
    local nextU = result.CellU
    local nextV = result.CellV

    if CubeTrailService.IsOccupied(nextFace, nextU, nextV) then
        return false
    end

    bike.Face = nextFace
    bike.CellU = nextU
    bike.CellV = nextV
    bike.Direction = result.Direction

    CubeTrailService.MarkCell(nextFace, bike.BikeId, nextU, nextV)

    updateBikeWorld(bike)

    local worldPos = CubeGridUtil.FaceCellToWorld(
        nextFace,
        nextU,
        nextV,
        CubeGridUtil.GetRideOffset()
    )

    local normal = CubeGridUtil.GetFaceConfig(nextFace).Normal

    CubeTrailService.ExtendSegment(bike.BikeId, worldPos, normal)

    return true
end

RunService.Heartbeat:Connect(function(dt)

    for bikeId, bike in pairs(activeBikes) do

        local speed = BASE_SPEED

        if bike.Boosting then
            speed = BOOST_SPEED
        end

        bike.LastMove += dt * speed

        if bike.LastMove >= MOVE_INTERVAL then
            bike.LastMove = 0

            local alive = stepBike(bike)

            if not alive then
                CubeTrailService.EndSegment(bikeId)
                activeBikes[bikeId] = nil
                if bike.Model then
                    bike.Model:Destroy()
                end
            end
        end
    end

end)

return CubeBikeRuntime
