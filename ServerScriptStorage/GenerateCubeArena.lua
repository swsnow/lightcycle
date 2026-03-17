local Workspace = game:GetService("Workspace")

local function destroyIfExists(name)
    local existing = Workspace:FindFirstChild(name)
    if existing then
        existing:Destroy()
    end
end

local function createPart(parent, name, size, cframe, color, material, transparency, anchored)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material
    part.Transparency = transparency or 0
    part.Anchored = anchored ~= false
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function createNeonPart(parent, name, size, cframe, color, transparency)
    local part = createPart(
        parent,
        name,
        size,
        cframe,
        color,
        Enum.Material.Neon,
        transparency or 0,
        true
    )
    part.CanCollide = false
    return part
end

local function createSpawnMarker(parent, name, position, color)
    local marker = Instance.new("Part")
    marker.Name = name
    marker.Shape = Enum.PartType.Cylinder
    marker.Size = Vector3.new(1, 0.4, 1)
    marker.Color = color
    marker.Material = Enum.Material.Neon
    marker.Anchored = true
    marker.CanCollide = false
    marker.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    marker.Parent = parent

    local attachment = Instance.new("Attachment")
    attachment.Parent = marker

    local light = Instance.new("PointLight")
    light.Brightness = 2
    light.Range = 18
    light.Color = color
    light.Parent = marker

    return marker
end

local function createFaceGrid(parent, namePrefix, faceCFrame, planeSize, cellSize, lineThickness, lineLift, color)
    local folder = Instance.new("Folder")
    folder.Name = namePrefix .. "_Grid"
    folder.Parent = parent

    local half = planeSize / 2
    local lineCount = math.floor(planeSize / cellSize)

    for i = -lineCount / 2, lineCount / 2 do
        local offset = i * cellSize

        -- vertical line in local face space
        createNeonPart(
            folder,
            namePrefix .. "_LineU_" .. tostring(i),
            Vector3.new(lineThickness, 0.12, planeSize),
            faceCFrame * CFrame.new(offset, lineLift, 0),
            color,
            0.05
        )

        -- horizontal line in local face space
        createNeonPart(
            folder,
            namePrefix .. "_LineV_" .. tostring(i),
            Vector3.new(planeSize, 0.12, lineThickness),
            faceCFrame * CFrame.new(0, lineLift, offset),
            color,
            0.05
        )
    end
end

local function createFaceBorder(parent, namePrefix, faceCFrame, planeSize, borderWidth, color)
    local folder = Instance.new("Folder")
    folder.Name = namePrefix .. "_Border"
    folder.Parent = parent

    local half = planeSize / 2

    createNeonPart(
        folder,
        namePrefix .. "_North",
        Vector3.new(planeSize, 0.18, borderWidth),
        faceCFrame * CFrame.new(0, 0.08, -half + borderWidth / 2),
        color,
        0
    )

    createNeonPart(
        folder,
        namePrefix .. "_South",
        Vector3.new(planeSize, 0.18, borderWidth),
        faceCFrame * CFrame.new(0, 0.08, half - borderWidth / 2),
        color,
        0
    )

    createNeonPart(
        folder,
        namePrefix .. "_West",
        Vector3.new(borderWidth, 0.18, planeSize),
        faceCFrame * CFrame.new(-half + borderWidth / 2, 0.08, 0),
        color,
        0
    )

    createNeonPart(
        folder,
        namePrefix .. "_East",
        Vector3.new(borderWidth, 0.18, planeSize),
        faceCFrame * CFrame.new(half - borderWidth / 2, 0.08, 0),
        color,
        0
    )
end

local function createSpectatorCube(parent, center, size)
    local cubeFolder = Instance.new("Folder")
    cubeFolder.Name = "SpectatorCube"
    cubeFolder.Parent = parent

    local glassColor = Color3.fromRGB(180, 220, 255)
    local frameColor = Color3.fromRGB(255, 255, 255)
    local frameThickness = 1.2
    local half = size / 2

    -- central glass cube body
    local cube = createPart(
        cubeFolder,
        "GlassCube",
        Vector3.new(size, size, size),
        CFrame.new(center),
        glassColor,
        Enum.Material.Glass,
        0.72,
        true
    )
    cube.CanCollide = true

    -- inner spectator platform
    local platform = createPart(
        cubeFolder,
        "SpectatorPlatform",
        Vector3.new(size - 8, 1, size - 8),
        CFrame.new(center.X, center.Y - (size / 2) + 4, center.Z),
        Color3.fromRGB(230, 240, 255),
        Enum.Material.Glass,
        0.45,
        true
    )
    platform.CanCollide = true

    -- neon frame edges
    local edges = {
        -- top square
        {"Top_North", Vector3.new(size, frameThickness, frameThickness), CFrame.new(center.X, center.Y + half, center.Z - half)},
        {"Top_South", Vector3.new(size, frameThickness, frameThickness), CFrame.new(center.X, center.Y + half, center.Z + half)},
        {"Top_West", Vector3.new(frameThickness, frameThickness, size), CFrame.new(center.X - half, center.Y + half, center.Z)},
        {"Top_East", Vector3.new(frameThickness, frameThickness, size), CFrame.new(center.X + half, center.Y + half, center.Z)},

        -- bottom square
        {"Bottom_North", Vector3.new(size, frameThickness, frameThickness), CFrame.new(center.X, center.Y - half, center.Z - half)},
        {"Bottom_South", Vector3.new(size, frameThickness, frameThickness), CFrame.new(center.X, center.Y - half, center.Z + half)},
        {"Bottom_West", Vector3.new(frameThickness, frameThickness, size), CFrame.new(center.X - half, center.Y - half, center.Z)},
        {"Bottom_East", Vector3.new(frameThickness, frameThickness, size), CFrame.new(center.X + half, center.Y - half, center.Z)},

        -- verticals
        {"Vertical_NW_Top", Vector3.new(frameThickness, size, frameThickness), CFrame.new(center.X - half, center.Y, center.Z - half)},
        {"Vertical_NE_Top", Vector3.new(frameThickness, size, frameThickness), CFrame.new(center.X + half, center.Y, center.Z - half)},
        {"Vertical_SW_Top", Vector3.new(frameThickness, size, frameThickness), CFrame.new(center.X - half, center.Y, center.Z + half)},
        {"Vertical_SE_Top", Vector3.new(frameThickness, size, frameThickness), CFrame.new(center.X + half, center.Y, center.Z + half)},
    }

    for _, edge in ipairs(edges) do
        createNeonPart(
            cubeFolder,
            edge[1],
            edge[2],
            edge[3],
            frameColor,
            0.05
        )
    end

    return cubeFolder
end

local function GenerateCubeEnvironment()
    destroyIfExists("CubeArena")

    local arenaModel = Instance.new("Model")
    arenaModel.Name = "CubeArena"
    arenaModel.Parent = Workspace

    local facesFolder = Instance.new("Folder")
    facesFolder.Name = "Faces"
    facesFolder.Parent = arenaModel

    local gridFolder = Instance.new("Folder")
    gridFolder.Name = "Grid"
    gridFolder.Parent = arenaModel

    local spawnFolder = Instance.new("Folder")
    spawnFolder.Name = "SpawnMarkers"
    spawnFolder.Parent = arenaModel

    local spectatorFolder = Instance.new("Folder")
    spectatorFolder.Name = "Spectator"
    spectatorFolder.Parent = arenaModel

    -- ===== SETTINGS =====
    local cubeCenter = Vector3.new(0, 60, 0)
    local innerSize = 520
    local faceThickness = 8

    local cellSize = 16
    local gridThickness = 0.28
    local borderWidth = 10

    local faceColor = Color3.fromRGB(20, 30, 45)
    local gridColor = Color3.fromRGB(0, 255, 255)
    local borderColor = Color3.fromRGB(255, 0, 200)
    local spectatorCubeSize = 72

    local half = innerSize / 2

    -- ===== FACE CFAMES =====
    -- Face local plane uses X/Z as grid axes and local +Y as "out from face"
    -- We orient each plane so the visible/playable side faces inward.

    local floorCF = CFrame.new(cubeCenter.X, cubeCenter.Y - half, cubeCenter.Z)
    local ceilingCF = CFrame.new(cubeCenter.X, cubeCenter.Y + half, cubeCenter.Z) * CFrame.Angles(math.rad(180), 0, 0)

    local northWallCF =
        CFrame.new(cubeCenter.X, cubeCenter.Y, cubeCenter.Z - half) *
        CFrame.Angles(math.rad(90), 0, 0)

    local southWallCF =
        CFrame.new(cubeCenter.X, cubeCenter.Y, cubeCenter.Z + half) *
        CFrame.Angles(math.rad(-90), math.rad(180), 0)

    local eastWallCF =
        CFrame.new(cubeCenter.X + half, cubeCenter.Y, cubeCenter.Z) *
        CFrame.Angles(0, 0, math.rad(-90)) *
        CFrame.Angles(0, math.rad(90), 0)

    local westWallCF =
        CFrame.new(cubeCenter.X - half, cubeCenter.Y, cubeCenter.Z) *
        CFrame.Angles(0, 0, math.rad(90)) *
        CFrame.Angles(0, math.rad(-90), 0)

    local faceDefs = {
        {
            Name = "Floor",
            CFrame = floorCF,
            Size = Vector3.new(innerSize, faceThickness, innerSize),
            Color = faceColor,
        },
        {
            Name = "Ceiling",
            CFrame = ceilingCF,
            Size = Vector3.new(innerSize, faceThickness, innerSize),
            Color = faceColor,
        },
        {
            Name = "NorthWall",
            CFrame = northWallCF,
            Size = Vector3.new(innerSize, faceThickness, innerSize),
            Color = faceColor,
        },
        {
            Name = "SouthWall",
            CFrame = southWallCF,
            Size = Vector3.new(innerSize, faceThickness, innerSize),
            Color = faceColor,
        },
        {
            Name = "EastWall",
            CFrame = eastWallCF,
            Size = Vector3.new(innerSize, faceThickness, innerSize),
            Color = faceColor,
        },
        {
            Name = "WestWall",
            CFrame = westWallCF,
            Size = Vector3.new(innerSize, faceThickness, innerSize),
            Color = faceColor,
        },
    }

    local primaryFace = nil

    for _, face in ipairs(faceDefs) do
        local part = createPart(
            facesFolder,
            face.Name,
            face.Size,
            face.CFrame,
            face.Color,
            Enum.Material.Glass,
            0.32,
            true
        )
        part.CanCollide = true

        if face.Name == "Floor" then
            primaryFace = part
        end

        createFaceGrid(
            gridFolder,
            face.Name,
            face.CFrame * CFrame.new(0, (faceThickness / 2) + 0.08, 0),
            innerSize,
            cellSize,
            gridThickness,
            0,
            gridColor
        )

        createFaceBorder(
            gridFolder,
            face.Name,
            face.CFrame * CFrame.new(0, (faceThickness / 2) + 0.12, 0),
            innerSize,
            borderWidth,
            borderColor
        )
    end

    -- ===== INNER EDGE NEON LINES =====
    local edgeFolder = Instance.new("Folder")
    edgeFolder.Name = "CubeEdges"
    edgeFolder.Parent = gridFolder

    local function edge(name, size, cf, color)
        createNeonPart(edgeFolder, name, size, cf, color, 0)
    end

    local e = half
    local t = 1.4

    -- top square
    edge("Top_North", Vector3.new(innerSize, t, t), CFrame.new(cubeCenter.X, cubeCenter.Y + e, cubeCenter.Z - e), gridColor)
    edge("Top_South", Vector3.new(innerSize, t, t), CFrame.new(cubeCenter.X, cubeCenter.Y + e, cubeCenter.Z + e), gridColor)
    edge("Top_East", Vector3.new(t, t, innerSize), CFrame.new(cubeCenter.X + e, cubeCenter.Y + e, cubeCenter.Z), gridColor)
    edge("Top_West", Vector3.new(t, t, innerSize), CFrame.new(cubeCenter.X - e, cubeCenter.Y + e, cubeCenter.Z), gridColor)

    -- bottom square
    edge("Bottom_North", Vector3.new(innerSize, t, t), CFrame.new(cubeCenter.X, cubeCenter.Y - e, cubeCenter.Z - e), gridColor)
    edge("Bottom_South", Vector3.new(innerSize, t, t), CFrame.new(cubeCenter.X, cubeCenter.Y - e, cubeCenter.Z + e), gridColor)
    edge("Bottom_East", Vector3.new(t, t, innerSize), CFrame.new(cubeCenter.X + e, cubeCenter.Y - e, cubeCenter.Z), gridColor)
    edge("Bottom_West", Vector3.new(t, t, innerSize), CFrame.new(cubeCenter.X - e, cubeCenter.Y - e, cubeCenter.Z), gridColor)

    -- verticals
    edge("Vertical_NE", Vector3.new(t, innerSize, t), CFrame.new(cubeCenter.X + e, cubeCenter.Y, cubeCenter.Z - e), gridColor)
    edge("Vertical_NW", Vector3.new(t, innerSize, t), CFrame.new(cubeCenter.X - e, cubeCenter.Y, cubeCenter.Z - e), gridColor)
    edge("Vertical_SE", Vector3.new(t, innerSize, t), CFrame.new(cubeCenter.X + e, cubeCenter.Y, cubeCenter.Z + e), gridColor)
    edge("Vertical_SW", Vector3.new(t, innerSize, t), CFrame.new(cubeCenter.X - e, cubeCenter.Y, cubeCenter.Z + e), gridColor)

    -- ===== CENTRAL SPECTATOR CUBE =====
    createSpectatorCube(spectatorFolder, cubeCenter, spectatorCubeSize)

    -- ===== FLOOR SPAWN MARKERS (for now) =====
    local floorY = cubeCenter.Y - half + (faceThickness / 2) + 1.2
    local spawnRadius = innerSize * 0.36

    createSpawnMarker(spawnFolder, "Spawn_North", Vector3.new(cubeCenter.X, floorY, cubeCenter.Z - spawnRadius), Color3.fromRGB(0, 255, 255))
    createSpawnMarker(spawnFolder, "Spawn_South", Vector3.new(cubeCenter.X, floorY, cubeCenter.Z + spawnRadius), Color3.fromRGB(255, 0, 200))
    createSpawnMarker(spawnFolder, "Spawn_West", Vector3.new(cubeCenter.X - spawnRadius, floorY, cubeCenter.Z), Color3.fromRGB(0, 170, 255))
    createSpawnMarker(spawnFolder, "Spawn_East", Vector3.new(cubeCenter.X + spawnRadius, floorY, cubeCenter.Z), Color3.fromRGB(255, 100, 255))

    -- spectator spawn markers
    createSpawnMarker(spawnFolder, "Spectator_1", cubeCenter + Vector3.new(-12, -spectatorCubeSize / 2 + 5, 0), Color3.fromRGB(255, 255, 255))
    createSpawnMarker(spawnFolder, "Spectator_2", cubeCenter + Vector3.new(12, -spectatorCubeSize / 2 + 5, 0), Color3.fromRGB(255, 255, 255))

    -- ===== ATTRIBUTES FOR FUTURE CUBE GRID UTIL =====
    arenaModel:SetAttribute("ArenaType", "Cube")
    arenaModel:SetAttribute("CubeCenterX", cubeCenter.X)
    arenaModel:SetAttribute("CubeCenterY", cubeCenter.Y)
    arenaModel:SetAttribute("CubeCenterZ", cubeCenter.Z)
    arenaModel:SetAttribute("CubeInnerSize", innerSize)
    arenaModel:SetAttribute("FaceThickness", faceThickness)
    arenaModel:SetAttribute("GridCellSize", cellSize)
    arenaModel:SetAttribute("SpectatorCubeSize", spectatorCubeSize)

    arenaModel.PrimaryPart = primaryFace
end

GenerateCubeEnvironment()
