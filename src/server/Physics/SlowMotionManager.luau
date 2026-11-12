--!strict

local Workspace = game:GetService("Workspace")

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToolConfigs = require(ReplicatedStorage.RigAndWreck.Config.ToolConfigs)

local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)

local SlowMotionManager = {}

local isSlowMo = false

local normalGravity = 196.2

local TIME_SCALE = ToolConfigs.SlowMotion.TimeScale -- 0.3 timescale

local function applyHumanoidScale(hum: Humanoid, enabled: boolean)

	if enabled then
		hum.WalkSpeed = 16 * TIME_SCALE
		hum.JumpPower = 50 * TIME_SCALE
	else
		hum.WalkSpeed = 16
		hum.JumpPower = 50
	end

end


function SlowMotionManager.IsSlowMotion(): boolean

	return isSlowMo
end

function SlowMotionManager.SetSlowMotion(enabled: boolean)

	if isSlowMo == enabled then return end
	isSlowMo = enabled
	local propsFolder = Workspace:FindFirstChild("RigAndWreckProps")
	local timeFactor = if enabled then TIME_SCALE else (1 / TIME_SCALE)
	-- scale gravity

	if enabled then
		normalGravity = Workspace.Gravity
		Workspace.Gravity = normalGravity * (TIME_SCALE * TIME_SCALE)
	else
		Workspace.Gravity = normalGravity
	end

	-- scale velocities

	if propsFolder then

		for _, prop in ipairs(propsFolder:GetChildren()) do

			if prop:IsA("BasePart") and not prop.Anchored then

				local lin = prop.AssemblyLinearVelocity * timeFactor

				local ang = prop.AssemblyAngularVelocity * timeFactor

				prop.AssemblyLinearVelocity = Vector3.new(

					math.clamp(lin.X, -150, 150),

					math.clamp(lin.Y, -150, 150),

					math.clamp(lin.Z, -150, 150)

				)

				prop.AssemblyAngularVelocity = Vector3.new(

					math.clamp(ang.X, -50, 50),

					math.clamp(ang.Y, -50, 50),

					math.clamp(ang.Z, -50, 50)

				)

			end

		end

	end

	-- slow players down

	for _, player in ipairs(Players:GetPlayers()) do

		local char = player.Character

		if char then

			local hum = char:FindFirstChildOfClass("Humanoid")

			if hum then

				applyHumanoidScale(hum, enabled)

			end

		end

	end

	-- tell clients to toggle matrix effect

	local updateSettingsRemote = RemoteDefinitions.GetEvent("UpdateSettings")

	updateSettingsRemote:FireAllClients({

		Setting = "SlowMotion",

		Value = enabled,

	})

end

local function onCharacter(char: Model)
	local hum = char:WaitForChild("Humanoid", 4) :: Humanoid?

	if hum and isSlowMo then
		applyHumanoidScale(hum, true)
	end

end

for _, p in ipairs(Players:GetPlayers()) do

	p.CharacterAdded:Connect(onCharacter)

	if p.Character then onCharacter(p.Character) end

end

Players.PlayerAdded:Connect(function(p)

	p.CharacterAdded:Connect(onCharacter)

end)

return SlowMotionManager
