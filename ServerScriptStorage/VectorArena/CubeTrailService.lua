local CubeTrailService = {}

local Workspace = game:GetService("Workspace")

local trailFolder = Workspace:FindFirstChild("CubeBikeTrails")
if not trailFolder then
	trailFolder = Instance.new("Folder")
	trailFolder.Name = "CubeBikeTrails"
	trailFolder.Parent = Workspace
end

local occupiedCells = {}
local bikeTrails = {}
local activeSegments = {}

local function makeCellKey(faceName, cellU, cellV)
	return tostring(faceName) .. ":" .. tostring(cellU) .. "," .. tostring(cellV)
end

function CubeTrailService.ResetAllTrails()
	for _, child in ipairs(trailFolder:GetChildren()) do
		child:Destroy()
	end

	table.clear(occupiedCells)
	table.clear(bikeTrails)
	table.clear(activeSegments)
end

function CubeTrailService.ClearBikeTrail(bikeId)
	local segments = bikeTrails[bikeId]
	if segments then
		for _, part in ipairs(segments) do
			if part and part.Parent then
				part:Destroy()
			end
		end
	end

	bikeTrails[bikeId] = nil
	activeSegments[bikeId] = nil

	for key, data in pairs(occupiedCells) do
		if data.BikeId == bikeId then
			occupiedCells[key] = nil
		end
	end
end

function CubeTrailService.IsOccupied(faceName, cellU, cellV)
	local key = makeCellKey(faceName, cellU, cellV)
	return occupiedCells[key] ~= nil
end

function CubeTrailService.GetOccupant(faceName, cellU, cellV)
	local key = makeCellKey(faceName, cellU, cellV)
	return occupiedCells[key]
end

function CubeTrailService.MarkCell(faceName, bikeId, cellU, cellV)
	local key = makeCellKey(faceName, cellU, cellV)

	occupiedCells[key] = {
		BikeId = bikeId,
		Face = faceName,
		CellU = cellU,
		CellV = cellV,
	}
end

function CubeTrailService.StartSegment(bikeId, startWorld, color, cellSize)
	local part = Instance.new("Part")
	part.Name = "CubeTrail_" .. tostring(bikeId)
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Transparency = 0.35
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = trailFolder

	local width = math.max(1.2, cellSize * 0.14)
	local height = 5

	part.Size = Vector3.new(width, height, 0.01)
	part.CFrame = CFrame.new(startWorld)

	activeSegments[bikeId] = {
		Part = part,
		Start = startWorld,
		CellSize = cellSize,
	}

	bikeTrails[bikeId] = bikeTrails[bikeId] or {}
	table.insert(bikeTrails[bikeId], part)

	return part
end

function CubeTrailService.ExtendSegment(bikeId, currentWorld, surfaceNormal)
	local seg = activeSegments[bikeId]
	if not seg then
		return
	end

	local part = seg.Part
	local start = seg.Start
	local delta = currentWorld - start
	local length = delta.Magnitude

	if length < 0.001 then
		return
	end

	local direction = delta.Unit
	local up = surfaceNormal.Unit
	local right = direction:Cross(up).Unit

	local width = part.Size.X
	local height = part.Size.Y
	local midpoint = start + delta / 2

	part.Size = Vector3.new(width, height, length)
	part.CFrame = CFrame.fromMatrix(midpoint, right, up)
end

function CubeTrailService.EndSegment(bikeId)
	activeSegments[bikeId] = nil
end

return CubeTrailService
