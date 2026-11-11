--!strict

local Workspace = game:GetService("Workspace")

local SoundService = game:GetService("SoundService")

local CollisionFX = {}

local sparkColor = ColorSequence.new({

	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 250, 150)),

	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 140, 30)),

	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 40, 10)),

})

local sparkSize = NumberSequence.new({

	NumberSequenceKeypoint.new(0, 0.35),

	NumberSequenceKeypoint.new(0.6, 0.2),

	NumberSequenceKeypoint.new(1, 0.02),

})

function CollisionFX.EmitSparks(position: Vector3, normal: Vector3?, particleCount: number?)
	local count = particleCount or math.random(16, 26)
	local att = Instance.new("Attachment")
	att.Position = position

	if normal and normal.Magnitude > 0.1 then
		att.Axis = normal.Unit
	else
		att.Axis = Vector3.new(0, 1, 0)
	end

	att.Parent = Workspace.Terrain

	local emitter = Instance.new("ParticleEmitter")

	emitter.Name = "CollisionSparks"

	emitter.Color = sparkColor

	emitter.Size = sparkSize

	emitter.Speed = NumberRange.new(22, 50)

	emitter.SpreadAngle = Vector2.new(65, 65)

	emitter.Lifetime = NumberRange.new(0.18, 0.36)

	emitter.LightEmission = 1.0

	emitter.Rate = 0

	emitter.Drag = 2.5

	emitter.Acceleration = Vector3.new(0, -35, 0)

	emitter.Parent = att

	emitter:Emit(count)

	task.delay(0.5, function()

		att:Destroy()

	end)

end


function CollisionFX.PlayImpactSound(position: Vector3, intensity: number?)
	local snd = Instance.new("Sound")
	snd.Name = "CollisionCrunch"
	snd.SoundId = "rbxassetid://6215849605" -- weld snap sound
	snd.Volume = math.clamp((intensity or 20) / 40, 0.3, 0.8)
	snd.PlaybackSpeed = 0.85 + (math.random(-15, 15) / 100)
	snd.RollOffMaxDistance = 120
	snd.RollOffMinDistance = 10
	local anchor = Instance.new("Part")
	anchor.Name = "SndAnchor"
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.Anchored = true
	anchor.Position = position
	anchor.Parent = Workspace
	snd.Parent = anchor
	snd:Play()
	snd.Ended:Connect(function()
		anchor:Destroy()
	end)

end


return CollisionFX
