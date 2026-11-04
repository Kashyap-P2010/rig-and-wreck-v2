--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SystemLimits = require(ReplicatedStorage.RigAndWreck.Config.SystemLimits)

local WorldBoundaryCleaner = {}

local running = false

function WorldBoundaryCleaner.Start()

	if running then return end
	running = true
	task.spawn(function()

		while running do
			task.wait(3)
			local propsFolder = workspace:FindFirstChild("RigAndWreckProps")

			if propsFolder then

				for _, inst in ipairs(propsFolder:GetChildren()) do

					if inst:IsA("BasePart") then

						if inst.Position.Y < SystemLimits.WorldYBoundary then
							ConstraintRegistry.DestroyPart(inst)
						end

					end

				end

			end

		end

	end)

end

function WorldBoundaryCleaner.Stop()
	running = false
end

return WorldBoundaryCleaner
