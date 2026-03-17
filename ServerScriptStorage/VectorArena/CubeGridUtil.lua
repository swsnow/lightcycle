local CubeGridUtil = {}

local function getArena()
    return workspace:WaitForChild("CubeArena")
end

local function getAttr(name, fallback)
    local arena = getArena()
    local value = arena:GetAttribute(name)
    if value == nil then
        return fallback
    end
    return value
end

local function sign(n)
    if n > 0 then
        return 1
    elseif n < 0 then
        return -1
    end
    return 0
end

local DIRECTION_VECTORS = {
    Up = Vector2.new(0, -1),
    Down = Vector2.new(0, 1),
    Left = Vector2.new(-1, 0),
    Right = Vector2.new(1, 0),
}

function CubeGridUtil.GetDirectionVector(directionName)
    return DIRECTION_VECTORS[directionName]
end

function CubeGridUtil.RotateLeft(directionName)
    if directionName == "Up" then
        return "Left"
    elseif directionName == "Left" then
        return "Down"
    elseif directionName == "Down" then
        return "Right"
    else
        return "Up"
    end
end

function CubeGridUtil.RotateRight(directionName)
    if directionName == "Up" then
        return "Right"
    elseif directionName == "Right" then
        return "Down"
    elseif directionName == "Down" then
        return "Left"
    else
        return "Up"
    end
end

function CubeGridUtil.GetCommonConfig()
    local arena = getArena()
    local innerSize = arena:GetAttribute("CubeInnerSize") or 520
    local faceThickness = arena:GetAttribute("FaceThickness") or 8
    local cellSize = arena:GetAttribute("GridCellSize") or 16

    return {
        Center = Vector3.new(
            arena:GetAttribute("CubeCenterX") or 0,
            arena:GetAttribute("CubeCenterY") or 60,
            arena:GetAttribute("CubeCenterZ") or 0
        ),
        InnerSize = innerSize,
        HalfSize = innerSize / 2,
        FaceThickness = faceThickness,
        CellSize = cellSize,
        MaxIndex = math.floor((innerSize / 2) / cellSize) - 1,
    }
end

function CubeGridUtil.GetFaceConfig(faceName)
    local common = CubeGridUtil.GetCommonConfig()
    local center = common.Center
    local h = common.HalfSize

    local faces = {
        Floor = {
            Name = "Floor",
            Center = center + Vector3.new(0, -h, 0),
            Normal = Vector3.new(0, 1, 0),
            Right = Vector3.new(1, 0, 0),
            Up = Vector3.new(0, 0, -1),
        },
        Ceiling = {
            Name = "Ceiling",
            Center = center + Vector3.new(0, h, 0),
            Normal = Vector3.new(0, -1, 0),
            Right = Vector3.new(1, 0, 0),
            Up = Vector3.new(0, 0, 1),
        },
        NorthWall = {
            Name = "NorthWall",
            Center = center + Vector3.new(0, 0, -h),
            Normal = Vector3.new(0, 0, 1),
            Right = Vector3.new(1, 0, 0),
            Up = Vector3.new(0, 1, 0),
        },
        SouthWall = {
            Name = "SouthWall",
            Center = center + Vector3.new(0, 0, h),
            Normal = Vector3.new(0, 0, -1),
            Right = Vector3.new(-1, 0, 0),
            Up = Vector3.new(0, 1, 0),
        },
        EastWall = {
            Name = "EastWall",
            Center = center + Vector3.new(h, 0, 0),
            Normal = Vector3.new(-1, 0, 0),
            Right = Vector3.new(0, 0, 1),
            Up = Vector3.new(0, 1, 0),
        },
        WestWall = {
            Name = "WestWall",
            Center = center + Vector3.new(-h, 0, 0),
            Normal = Vector3.new(1, 0, 0),
            Right = Vector3.new(0, 0, -1),
            Up = Vector3.new(0, 1, 0),
        },
    }

    local face = faces[faceName]
    if not face then
        error("Unknown cube face: " .. tostring(faceName))
    end

    face.CellSize = common.CellSize
    face.MaxIndex = common.MaxIndex
    face.InnerSize = common.InnerSize
    face.HalfSize = common.HalfSize
    face.FaceThickness = common.FaceThickness

    return face
end

function CubeGridUtil.GetAllFaceConfigs()
    return {
        Floor = CubeGridUtil.GetFaceConfig("Floor"),
        Ceiling = CubeGridUtil.GetFaceConfig("Ceiling"),
        NorthWall = CubeGridUtil.GetFaceConfig("NorthWall"),
        SouthWall = CubeGridUtil.GetFaceConfig("SouthWall"),
        EastWall = CubeGridUtil.GetFaceConfig("EastWall"),
        WestWall = CubeGridUtil.GetFaceConfig("WestWall"),
    }
end

function CubeGridUtil.FaceCellToWorld(faceName, cellU, cellV, offsetFromFace)
    local face = CubeGridUtil.GetFaceConfig(faceName)
    local offset = offsetFromFace or 0

    return face.Center
        + face.Right * (cellU * face.CellSize)
        + face.Up * (cellV * face.CellSize)
        + face.Normal * offset
end

function CubeGridUtil.WorldToFaceCell(faceName, worldPos)
    local face = CubeGridUtil.GetFaceConfig(faceName)
    local relative = worldPos - face.Center

    local u = relative:Dot(face.Right) / face.CellSize
    local v = relative:Dot(face.Up) / face.CellSize

    return math.round(u), math.round(v)
end

function CubeGridUtil.IsInsideFace(faceName, cellU, cellV)
    local face = CubeGridUtil.GetFaceConfig(faceName)
    return math.abs(cellU) <= face.MaxIndex and math.abs(cellV) <= face.MaxIndex
end

function CubeGridUtil.GetNeighborFace(faceName, directionName)
    local neighbors = {
        Floor = {
            Up = "NorthWall",
            Down = "SouthWall",
            Left = "WestWall",
            Right = "EastWall",
        },
        Ceiling = {
            Up = "SouthWall",
            Down = "NorthWall",
            Left = "WestWall",
            Right = "EastWall",
        },
        NorthWall = {
            Up = "Ceiling",
            Down = "Floor",
            Left = "WestWall",
            Right = "EastWall",
        },
        SouthWall = {
            Up = "Ceiling",
            Down = "Floor",
            Left = "EastWall",
            Right = "WestWall",
        },
        EastWall = {
            Up = "Ceiling",
            Down = "Floor",
            Left = "NorthWall",
            Right = "SouthWall",
        },
        WestWall = {
            Up = "Ceiling",
            Down = "Floor",
            Left = "SouthWall",
            Right = "NorthWall",
        },
    }

    local faceNeighbors = neighbors[faceName]
    if not faceNeighbors then
        error("No neighbor mapping for face: " .. tostring(faceName))
    end

    local nextFace = faceNeighbors[directionName]
    if not nextFace then
        error("No neighbor for face " .. tostring(faceName) .. " in direction " .. tostring(directionName))
    end

    return nextFace
end

function CubeGridUtil.GetWorldDirection(faceName, directionName)
    local face = CubeGridUtil.GetFaceConfig(faceName)

    if directionName == "Up" then
        return face.Up
    elseif directionName == "Down" then
        return -face.Up
    elseif directionName == "Right" then
        return face.Right
    elseif directionName == "Left" then
        return -face.Right
    end

    error("Unknown direction name: " .. tostring(directionName))
end

function CubeGridUtil.GetLocalDirectionFromWorld(faceName, worldDir)
    local face = CubeGridUtil.GetFaceConfig(faceName)

    local rightDot = worldDir:Dot(face.Right)
    local upDot = worldDir:Dot(face.Up)

    if math.abs(rightDot) > math.abs(upDot) then
        return rightDot > 0 and "Right" or "Left"
    else
        return upDot > 0 and "Up" or "Down"
    end
end

function CubeGridUtil.Step(faceName, cellU, cellV, directionName)
    local dir = CubeGridUtil.GetDirectionVector(directionName)
    local nextU = cellU + dir.X
    local nextV = cellV + dir.Y

    if CubeGridUtil.IsInsideFace(faceName, nextU, nextV) then
        return {
            Face = faceName,
            CellU = nextU,
            CellV = nextV,
            Direction = directionName,
            Transitioned = false,
        }
    end

    local face = CubeGridUtil.GetFaceConfig(faceName)
    local maxIndex = face.MaxIndex

    local nextFace = CubeGridUtil.GetNeighborFace(faceName, directionName)

    -- Preserve the coordinate along the crossed edge.
    -- We derive the new world forward and remap it to the new face.
    local worldForward = CubeGridUtil.GetWorldDirection(faceName, directionName)
    local newDirection = CubeGridUtil.GetLocalDirectionFromWorld(nextFace, worldForward)

    local newU = cellU
    local newV = cellV

    if directionName == "Up" then
        newV = -maxIndex
    elseif directionName == "Down" then
        newV = maxIndex
    elseif directionName == "Left" then
        newU = maxIndex
    elseif directionName == "Right" then
        newU = -maxIndex
    end

    -- Map edge coordinate to the adjacent face.
    -- We use world position at the edge to compute the new face cell cleanly.
    local edgeWorld = CubeGridUtil.FaceCellToWorld(faceName, cellU, cellV, 0)
    local mappedU, mappedV = CubeGridUtil.WorldToFaceCell(nextFace, edgeWorld)

    -- Clamp to valid range.
    mappedU = math.clamp(mappedU, -maxIndex, maxIndex)
    mappedV = math.clamp(mappedV, -maxIndex, maxIndex)

    -- Move one step inward on the new face in the travel direction so the bike actually crosses.
    local inwardDir = CubeGridUtil.GetDirectionVector(newDirection)
    mappedU += inwardDir.X
    mappedV += inwardDir.Y

    mappedU = math.clamp(mappedU, -maxIndex, maxIndex)
    mappedV = math.clamp(mappedV, -maxIndex, maxIndex)

    return {
        Face = nextFace,
        CellU = mappedU,
        CellV = mappedV,
        Direction = newDirection,
        Transitioned = true,
        FromFace = faceName,
    }
end

function CubeGridUtil.GetRideOffset()
    local common = CubeGridUtil.GetCommonConfig()
    return (common.FaceThickness / 2) + 2.25
end

function CubeGridUtil.GetSpawnWorld(spawnName)
    local arena = getArena()
    local spawnFolder = arena:WaitForChild("SpawnMarkers")
    local spawn = spawnFolder:FindFirstChild(spawnName)
    if not spawn then
        error("Spawn marker not found: " .. tostring(spawnName))
    end
    return spawn.Position
end

function CubeGridUtil.GetClosestFaceFromWorld(worldPos)
    local faces = CubeGridUtil.GetAllFaceConfigs()

    local bestFace = nil
    local bestDistance = math.huge

    for faceName, face in pairs(faces) do
        local relative = worldPos - face.Center
        local distance = math.abs(relative:Dot(face.Normal))
        if distance < bestDistance then
            bestDistance = distance
            bestFace = faceName
        end
    end

    return bestFace
end

return CubeGridUtil
