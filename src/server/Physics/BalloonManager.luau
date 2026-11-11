--!strict

local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToolConfigs = require(ReplicatedStorage.RigAndWreck.Config.ToolConfigs)

local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)

local OwnershipManager = require(script.Parent.Parent.Core.OwnershipManager)

local BudgetManager = require(script.Parent.Parent.Core.BudgetManager)

local ConstraintRegistry = require(script.Parent.ConstraintRegistry)

local BalloonManager = {}


local function getPropsFolder(): Folder
	local f = Workspace:FindFirstChild("RigAndWreckProps")

	if not f then
		f = Instance.new("Folder")
		f.Name = "RigAndWreckProps"
		f.Parent = Workspace
	end

	return f :: Folder

end


function BalloonManager.CreateBalloon(player: Player, targetPart: BasePart, hitPosition: Vector3, customLift: number?, customColor: Color3?): BasePart?

	if not targetPart or not targetPart.Parent or not targetPart:IsA("BasePart") then return nil end

	if not OwnershipManager.CanModify(player, targetPart) then return nil end

	if not BudgetManager.CanSpawnProp(player) or not BudgetManager.CanCreateConstraint(player) then return nil end
	local colors = ToolConfigs.Balloon.Colors
	local balloonColor = customColor or colors[math.random(1, #colors)]
	local lift = customLift or ToolConfigs.Balloon.DefaultLiftForce
	-- make balloon part
	local balloon = Instance.new("Part")
	balloon.Name = "RigWreck_Balloon"
	balloon.Shape = Enum.PartType.Ball
	balloon.Size = Vector3.new(2.4, 3.0, 2.4)
	balloon.Color = balloonColor
	balloon.Material = Enum.Material.SmoothPlastic
	balloon.TopSurface = Enum.SurfaceType.Smooth
	balloon.BottomSurface = Enum.SurfaceType.Smooth
	balloon.CustomPhysicalProperties = PhysicalProperties.new(0.02, 0.2, 0.7)
	balloon.CanCollide = true
	balloon:SetAttribute("IsBalloon", true)
	balloon:SetAttribute("PropType", "Balloon")
	-- float above hit point
	local ropeLength = ToolConfigs.Balloon.RopeLength or 5
	balloon.CFrame = CFrame.new(hitPosition + Vector3.new(0, ropeLength + 1.5, 0))
	-- upward float force
	local attForce = Instance.new("Attachment")
	attForce.Name = "BalloonForceAtt"
	attForce.Position = Vector3.zero
	attForce.Parent = balloon
	local vForce = Instance.new("VectorForce")
	vForce.Name = "BalloonLift"
	vForce.Attachment0 = attForce
	vForce.RelativeTo = Enum.ActuatorRelativeTo.World
	vForce.Force = Vector3.new(0, lift, 0)
	vForce.Parent = balloon
	-- rope to target part
	local attBalloonBottom = Instance.new("Attachment")
	attBalloonBottom.Name = "BalloonKnotAtt"
	attBalloonBottom.Position = Vector3.new(0, -1.3, 0)
	attBalloonBottom.Parent = balloon
	local attTarget = Instance.new("Attachment")
	attTarget.Name = "BalloonTargetAtt"
	attTarget.Position = targetPart.CFrame:PointToObjectSpace(hitPosition)
	attTarget.Parent = targetPart
	local rope = Instance.new("RopeConstraint")
	rope.Name = "BalloonRope"
	rope.Attachment0 = attBalloonBottom
	rope.Attachment1 = attTarget
	rope.Length = ropeLength
	rope.Thickness = 0.08
	rope.Visible = true
	rope.Color = BrickColor.new("Institutional white")
	rope.Parent = balloon
	-- tag owner
	OwnershipManager.TagProp(balloon, player)
	balloon.Parent = getPropsFolder()
	BudgetManager.AddProp(player, balloon)
	-- track joint
	ConstraintRegistry.RegisterRope(player, balloon, targetPart, attBalloonBottom, attTarget, ropeLength)
	-- pop on hard hit
	balloon.Touched:Connect(function(other)

		if not other or not other:IsA("BasePart") then return end
		local relVel = (balloon.AssemblyLinearVelocity - other.AssemblyLinearVelocity).Magnitude

		if relVel > 45 then
			BalloonManager.PopBalloon(balloon, player)
		end

	end)

	local playSound = RemoteDefinitions.GetEvent("PlaySoundEffect")

	playSound:FireClient(player, "Spawn", hitPosition)

	return balloon

end

function BalloonManager.PopBalloon(balloon: BasePart, triggeringPlayer: Player?)

	if not balloon or not balloon.Parent or not balloon:GetAttribute("IsBalloon") then return end
	local pos = balloon.Position
	local color = balloon.Color
	-- pop particles
	local burstAtt = Instance.new("Attachment")
	burstAtt.Position = pos
	burstAtt.Parent = Workspace.Terrain
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Speed = NumberRange.new(18, 30)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Lifetime = NumberRange.new(0.25, 0.45)
	emitter.Rate = 0
	emitter.LightEmission = 0.5
	emitter.Parent = burstAtt
	emitter:Emit(30)
	task.delay(0.6, function()
		burstAtt:Destroy()
	end)

	-- pop sound

	local playSound = RemoteDefinitions.GetEvent("PlaySoundEffect")

	playSound:FireAllClients("RopeSnap", pos)

	-- destroy balloon

	ConstraintRegistry.DestroyPart(balloon, triggeringPlayer)

end

return BalloonManager
