--!strict

local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConstraintRegistry = require(script.Parent.ConstraintRegistry)

local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)

local ExplosivesManager = {}

local detonated: { [BasePart]: boolean } = {}

function ExplosivesManager.Detonate(tntPart: BasePart, triggeringPlayer: Player?)

	if not tntPart or not tntPart.Parent or detonated[tntPart] then return end
	detonated[tntPart] = true
	local origin = tntPart.Position
	local propsFolder = Workspace:FindFirstChild("RigAndWreckProps")
	-- explosion instance
	local exp = Instance.new("Explosion")
	exp.Position = origin
	exp.BlastRadius = 22
	exp.BlastPressure = 450000
	exp.DestroyJointRadiusPercent = 0 -- only damage props not players
	exp.Parent = Workspace
	-- blast sound
	local playSoundRemote = RemoteDefinitions.GetEvent("PlaySoundEffect")
	playSoundRemote:FireAllClients("RopeSnap", origin)
	-- fling nearby props

	if propsFolder then
		local nearbyTnt: { BasePart } = {}

		for _, prop in ipairs(propsFolder:GetChildren()) do

			if prop:IsA("BasePart") and prop ~= tntPart and prop.Parent then
				local dist = (prop.Position - origin).Magnitude

				if dist <= 24 then
					-- snap joints

					if dist <= 14 then
						ConstraintRegistry.TriggerBreakableImpact(prop, 80)
					end

					-- push impulse

					if not prop.Anchored then

						local dir = (prop.Position - origin)

						if dir.Magnitude < 0.1 then dir = Vector3.new(0, 1, 0) else dir = dir.Unit end

						local falloff = math.clamp(1 - (dist / 24), 0.2, 1)

						local impulse = (dir + Vector3.new(0, 0.45, 0)).Unit * (prop:GetMass() * 70 * falloff)

						pcall(function()

							prop.AssemblyLinearVelocity += (impulse / prop:GetMass())

							prop:ApplyAngularImpulse(Vector3.new(

								(math.random() - 0.5) * 50 * prop:GetMass(),

								(math.random() - 0.5) * 50 * prop:GetMass(),

								(math.random() - 0.5) * 50 * prop:GetMass()

							))

						end)

					end

					-- check chain reaction

					if prop:GetAttribute("PropType") == "TNT" and not detonated[prop] then

						table.insert(nearbyTnt, prop)

					end

				end

			end

		end

		-- chain delay

		for _, nextTnt in ipairs(nearbyTnt) do

			task.delay(0.12 + math.random() * 0.08, function()

				ExplosivesManager.Detonate(nextTnt, triggeringPlayer)

			end)

		end

	end

	-- destroy tnt

	ConstraintRegistry.DestroyPart(tntPart, triggeringPlayer)

	detonated[tntPart] = nil

end


return ExplosivesManager
