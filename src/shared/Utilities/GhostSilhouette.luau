--!strict

local TweenService = game:GetService("TweenService")

local GhostSilhouette = {}

function GhostSilhouette.SpawnRedGhost(cframe: CFrame, size: Vector3, shape: Enum.PartType?)
	local ghost = Instance.new("Part")
	ghost.Name = "RigWreck_RedGhost"
	ghost.CFrame = cframe
	ghost.Size = size

	if shape and shape ~= Enum.PartType.Block then
		ghost.Shape = shape
	end

	ghost.Material = Enum.Material.Neon

	ghost.Color = Color3.fromRGB(255, 40, 40)

	ghost.Transparency = 0.4

	ghost.CanCollide = false

	ghost.CanTouch = false

	ghost.CanQuery = false

	ghost.Anchored = true

	ghost.Parent = workspace

	local tween = TweenService:Create(ghost, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {

		Transparency = 1,

		Size = size * 1.05,

	})

	tween:Play()

	tween.Completed:Connect(function()

		ghost:Destroy()

	end)

end


return GhostSilhouette
