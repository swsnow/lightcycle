local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local remotes = ReplicatedStorage:WaitForChild("VectorArenaRemotes")
local bikeCameraRemote = remotes:WaitForChild("BikeCamera")

local currentBike = nil
local currentCFrame = nil

local DISTANCE = 14
local HEIGHT = 5
local LOOK_AHEAD = 12

local POSITION_SMOOTHNESS = 0.12
local ORIENTATION_SMOOTHNESS = 0.14

local yawOffset = 0
local pitchOffset = 0

local MAX_YAW = math.rad(90)
local MAX_PITCH_UP = math.rad(90)
local MAX_PITCH_DOWN = math.rad(25)

local MOUSE_SENSITIVITY_X = 0.003
local MOUSE_SENSITIVITY_Y = 0.0025

local RECENTER_YAW_SPEED = 1.7
local RECENTER_PITCH_SPEED = 1.9

local smoothedForward = nil
local smoothedUp = nil

local function setRidingCameraEnabled(enabled)
	if enabled then
		camera.CameraType = Enum.CameraType.Scriptable
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	else
		camera.CameraType = Enum.CameraType.Custom
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

bikeCameraRemote.OnClientEvent:Connect(function(bikeModel)
	print("CubeBikeCamera got bike:", bikeModel)
	currentBike = bikeModel

	if currentBike then
		setRidingCameraEnabled(true)
		currentCFrame = camera.CFrame
		yawOffset = 0
		pitchOffset = 0

		local root = currentBike:FindFirstChild("RootPart")
		if root then
			smoothedForward = root.CFrame.LookVector
			smoothedUp = root.CFrame.UpVector
		else
			smoothedForward = nil
			smoothedUp = nil
		end
	else
		setRidingCameraEnabled(false)
		currentCFrame = nil
		smoothedForward = nil
		smoothedUp = nil
		yawOffset = 0
		pitchOffset = 0
	end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if gameProcessed or not currentBike then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseMovement then
		yawOffset -= input.Delta.X * MOUSE_SENSITIVITY_X
		yawOffset = math.clamp(yawOffset, -MAX_YAW, MAX_YAW)

		pitchOffset -= input.Delta.Y * MOUSE_SENSITIVITY_Y
		pitchOffset = math.clamp(pitchOffset, -MAX_PITCH_DOWN, MAX_PITCH_UP)
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if not currentBike then
		return
	end

	local root = currentBike:FindFirstChild("RootPart")
	if not root then
		return
	end

	local rootCF = root.CFrame
	local bikeForward = rootCF.LookVector.Unit
	local bikeUp = rootCF.UpVector.Unit
	local bikeRight = rootCF.RightVector.Unit

	if smoothedForward then
		smoothedForward = smoothedForward:Lerp(bikeForward, ORIENTATION_SMOOTHNESS).Unit
	else
		smoothedForward = bikeForward
	end

	if smoothedUp then
		smoothedUp = smoothedUp:Lerp(bikeUp, ORIENTATION_SMOOTHNESS).Unit
	else
		smoothedUp = bikeUp
	end

	-- rebuild orthonormal basis
	local smoothedRight = smoothedForward:Cross(smoothedUp).Unit
	smoothedUp = smoothedRight:Cross(smoothedForward).Unit

	-- recenter freelook
	if math.abs(yawOffset) > 0.0001 then
		local sign = yawOffset > 0 and 1 or -1
		local amount = math.min(math.abs(yawOffset), RECENTER_YAW_SPEED * dt)
		yawOffset -= sign * amount
	end

	if math.abs(pitchOffset) > 0.0001 then
		local sign = pitchOffset > 0 and 1 or -1
		local amount = math.min(math.abs(pitchOffset), RECENTER_PITCH_SPEED * dt)
		pitchOffset -= sign * amount
	end

	-- yaw around bike up
	local yawCF = CFrame.fromAxisAngle(smoothedUp, yawOffset)
	local yawedLook = yawCF:VectorToWorldSpace(smoothedForward).Unit

	-- recompute right after yaw
	local yawedRight = yawedLook:Cross(smoothedUp).Unit

	-- pitch around yawed right
	local pitchCF = CFrame.fromAxisAngle(yawedRight, pitchOffset)
	local lookDir = pitchCF:VectorToWorldSpace(yawedLook).Unit

	local targetPos =
		root.Position
	- lookDir * DISTANCE
		+ smoothedUp * HEIGHT

	local lookAt =
		root.Position
		+ lookDir * LOOK_AHEAD

	local targetCFrame = CFrame.lookAt(targetPos, lookAt, smoothedUp)

	if currentCFrame then
		currentCFrame = currentCFrame:Lerp(targetCFrame, POSITION_SMOOTHNESS)
	else
		currentCFrame = targetCFrame
	end

	camera.CFrame = currentCFrame
end)
