--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BudgetManager = require(script.Parent.Parent.Core.BudgetManager)
local ToolConfigs = require(ReplicatedStorage.RigAndWreck.Config.ToolConfigs)
local SystemTypes = require(ReplicatedStorage.RigAndWreck.Types.SystemTypes)

type ConstraintRecord = SystemTypes.ConstraintRecord

local ConstraintRegistry = {}

local records: { [string]: ConstraintRecord } = {}
local partConstraints: { [BasePart]: { [string]: boolean } } = {}

local function linkPart(part: BasePart, id: string)
	if not partConstraints[part] then
		partConstraints[part] = {}
	end
	partConstraints[part][id] = true
end

local function unlinkPart(part: BasePart, id: string)
	if partConstraints[part] then
		partConstraints[part][id] = nil
		local empty = true
		for _ in pairs(partConstraints[part]) do
			empty = false
			break
		end
		if empty then
			partConstraints[part] = nil
		end
	end
end

function ConstraintRegistry.GetRecord(id: string): ConstraintRecord?
	return records[id]
end

function ConstraintRegistry.GetPartConstraints(part: BasePart): { ConstraintRecord }
	local list = {}
	local set = partConstraints[part]
	if set then
		for id in pairs(set) do
			local rec = records[id]
			if rec then
				table.insert(list, rec)
			end
		end
	end
	return list
end

function ConstraintRegistry.RegisterWeld(player: Player, partA: BasePart, partB: BasePart): ConstraintRecord
	if partA == partB then
		error("RigWreck: cannot weld part to itself")
	end

	local id = HttpService:GenerateGUID(false)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "RigWreck_Weld_" .. string.sub(id, 1, 8)
	weld.Part0 = partA
	weld.Part1 = partB
	weld.Parent = partA

	-- blue visualizer beam between centers
	local att0 = Instance.new("Attachment")
	att0.Name = "RigWreck_WeldAtt0"
	att0.Position = Vector3.zero
	att0.Parent = partA

	local att1 = Instance.new("Attachment")
	att1.Name = "RigWreck_WeldAtt1"
	att1.Position = Vector3.zero
	att1.Parent = partB

	local beam = Instance.new("Beam")
	beam.Name = "RigWreck_WeldVisualizer"
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Color = ColorSequence.new(Color3.fromRGB(0, 180, 255))
	beam.Width0 = 0.14
	beam.Width1 = 0.14
	beam.FaceCamera = true
	beam.Transparency = NumberSequence.new(0.2)
	beam.Parent = partA

	-- wake assembly island so physics updates immediately
	partA:ApplyImpulse(Vector3.zero)

	local record: ConstraintRecord = {
		id = id,
		constraintType = "WeldConstraint",
		partA = partA,
		partB = partB,
		attachment0 = att0,
		attachment1 = att1,
		instance = weld,
		ownerId = player.UserId,
		meta = { visualizer = beam },
	}

	records[id] = record
	linkPart(partA, id)
	linkPart(partB, id)
	BudgetManager.AddConstraint(player, id)

	return record
end

function ConstraintRegistry.RegisterRope(player: Player, partA: BasePart, partB: BasePart, att0: Attachment, att1: Attachment, length: number): ConstraintRecord
	local id = HttpService:GenerateGUID(false)
	local rope = Instance.new("RopeConstraint")
	rope.Name = "RigWreck_Rope_" .. string.sub(id, 1, 8)
	rope.Attachment0 = att0
	rope.Attachment1 = att1
	rope.Length = math.clamp(length, ToolConfigs.Rope.MinLength, ToolConfigs.Rope.MaxLength)
	rope.Thickness = ToolConfigs.Rope.Thickness
	rope.Color = BrickColor.new(ToolConfigs.Rope.Color)
	rope.Restitution = 0.15
	rope.Visible = true
	rope.Parent = partA

	local record: ConstraintRecord = {
		id = id,
		constraintType = "RopeConstraint",
		partA = partA,
		partB = partB,
		attachment0 = att0,
		attachment1 = att1,
		instance = rope,
		ownerId = player.UserId,
		meta = { length = rope.Length },
	}

	records[id] = record
	linkPart(partA, id)
	linkPart(partB, id)
	BudgetManager.AddConstraint(player, id)

	return record
end

function ConstraintRegistry.RegisterHinge(player: Player, partA: BasePart, partB: BasePart, att0: Attachment, att1: Attachment, limitsEnabled: boolean, lower: number, upper: number, isServo: boolean?): ConstraintRecord
	local id = HttpService:GenerateGUID(false)
	local hinge = Instance.new("HingeConstraint")
	hinge.Name = "RigWreck_Hinge_" .. string.sub(id, 1, 8)
	hinge.Attachment0 = att0
	hinge.Attachment1 = att1

	if isServo then
		hinge.ActuatorType = Enum.ActuatorType.Servo
		hinge.ServoMaxTorque = 40000
		hinge.AngularSpeed = 10
		hinge.TargetAngle = 0
		hinge.LimitsEnabled = true
		hinge.LowerAngle = -45
		hinge.UpperAngle = 45
	else
		hinge.ActuatorType = Enum.ActuatorType.None
		hinge.LimitsEnabled = limitsEnabled
		if limitsEnabled then
			hinge.LowerAngle = lower
			hinge.UpperAngle = upper
			hinge.Restitution = 0.15
		end
	end

	hinge.Parent = partA

	-- yellow hinge beam
	local beam = Instance.new("Beam")
	beam.Name = "RigWreck_HingeVisualizer"
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	beam.Width0 = 0.12
	beam.Width1 = 0.12
	beam.FaceCamera = true
	beam.Transparency = NumberSequence.new(0.25)
	beam.Parent = partA

	local record: ConstraintRecord = {
		id = id,
		constraintType = "HingeConstraint",
		partA = partA,
		partB = partB,
		attachment0 = att0,
		attachment1 = att1,
		instance = hinge,
		ownerId = player.UserId,
		meta = {
			limitsEnabled = limitsEnabled,
			lower = lower,
			upper = upper,
			isServo = (isServo == true),
			visualizer = beam,
		},
	}

	records[id] = record
	linkPart(partA, id)
	linkPart(partB, id)
	BudgetManager.AddConstraint(player, id)

	return record
end

function ConstraintRegistry.RegisterMotor(player: Player, partA: BasePart, partB: BasePart, att0: Attachment, att1: Attachment, speed: number, torque: number, keyForward: string, keyReverse: string): ConstraintRecord
	local id = HttpService:GenerateGUID(false)
	local hinge = Instance.new("HingeConstraint")
	hinge.Name = "RigWreck_Motor_" .. string.sub(id, 1, 8)
	hinge.Attachment0 = att0
	hinge.Attachment1 = att1
	hinge.ActuatorType = Enum.ActuatorType.Motor
	hinge.MotorMaxTorque = math.clamp(torque, 100, ToolConfigs.Motor.MaxTorque)
	hinge.MotorMaxAcceleration = 350
	hinge.AngularVelocity = 0 -- idle until driver input
	hinge.Parent = partA

	-- orange motor beam
	local beam = Instance.new("Beam")
	beam.Name = "RigWreck_MotorVisualizer"
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 130, 30))
	beam.Width0 = 0.14
	beam.Width1 = 0.14
	beam.FaceCamera = true
	beam.Transparency = NumberSequence.new(0.2)
	beam.Parent = partA

	-- wake island on both parts
	partA:ApplyImpulse(Vector3.zero)
	partB:ApplyImpulse(Vector3.zero)

	local record: ConstraintRecord = {
		id = id,
		constraintType = "Motor",
		partA = partA,
		partB = partB,
		attachment0 = att0,
		attachment1 = att1,
		instance = hinge,
		ownerId = player.UserId,
		meta = {
			targetSpeed = speed,
			maxTorque = torque,
			keyForward = keyForward,
			keyReverse = keyReverse,
			activeDirection = 0,
			visualizer = beam,
		},
	}

	records[id] = record
	linkPart(partA, id)
	linkPart(partB, id)
	BudgetManager.AddConstraint(player, id)

	return record
end

function ConstraintRegistry.TriggerBreakableImpact(part: BasePart, impactSpeed: number)
	if impactSpeed < 45 then return end
	local connected = ConstraintRegistry.GetPartConstraints(part)
	if #connected > 0 then
		local chosen = connected[math.random(1, #connected)]
		ConstraintRegistry.DestroyConstraint(chosen.id)
	end
end

function ConstraintRegistry.RegisterThruster(player: Player, partA: BasePart, att: Attachment, force: number, key: string): ConstraintRecord
	local id = HttpService:GenerateGUID(false)
	local vf = Instance.new("VectorForce")
	vf.Name = "RigWreck_Thruster_" .. string.sub(id, 1, 8)
	vf.Attachment0 = att
	vf.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
	vf.ApplyAtCenterOfMass = false
	vf.Force = Vector3.zero
	vf.Parent = partA

	partA:ApplyImpulse(Vector3.zero)

	local record: ConstraintRecord = {
		id = id,
		constraintType = "Thruster",
		partA = partA,
		partB = nil,
		attachment0 = att,
		attachment1 = nil,
		instance = vf,
		ownerId = player.UserId,
		meta = {
			targetForce = math.clamp(force, ToolConfigs.Thruster.MinForce, ToolConfigs.Thruster.MaxForce),
			key = key,
			active = false,
		},
	}

	records[id] = record
	linkPart(partA, id)
	BudgetManager.AddConstraint(player, id)

	return record
end

function ConstraintRegistry.DestroyConstraint(id: string)
	local record = records[id]
	if not record then return end

	local player = Players:GetPlayerByUserId(record.ownerId)
	if record.instance and record.instance.Parent then
		record.instance:Destroy()
	end

	if record.meta and record.meta.visualizer and record.meta.visualizer.Parent then
		record.meta.visualizer:Destroy()
	end

	if record.attachment0 and record.attachment0.Parent and record.attachment0.Name:find("RigWreck") then
		record.attachment0:Destroy()
	end

	if record.attachment1 and record.attachment1.Parent and record.attachment1.Name:find("RigWreck") then
		record.attachment1:Destroy()
	end

	if record.partA then unlinkPart(record.partA, id) end
	if record.partB then unlinkPart(record.partB, id) end
	records[id] = nil

	if player then
		BudgetManager.RemoveConstraint(player, id)
	end
end

function ConstraintRegistry.DestroyPart(part: BasePart, player: Player?)
	local connected = ConstraintRegistry.GetPartConstraints(part)
	for _, rec in ipairs(connected) do
		ConstraintRegistry.DestroyConstraint(rec.id)
	end

	partConstraints[part] = nil

	if player then
		BudgetManager.RemoveProp(player, part)
	else
		-- fallback owner check
		local ownerId = part:GetAttribute("OwnerUserId")
		if ownerId then
			local p = Players:GetPlayerByUserId(ownerId)
			if p then BudgetManager.RemoveProp(p, part) end
		end
	end

	if part.Parent then
		part:Destroy()
	end
end

function ConstraintRegistry.GetAllRecords(): { [string]: ConstraintRecord }
	return records
end

return ConstraintRegistry
