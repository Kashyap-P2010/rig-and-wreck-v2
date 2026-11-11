--!strict

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)

local RemoteValidator = require(ReplicatedStorage.RigAndWreck.Network.RemoteValidator)

local SoundAssets = require(ReplicatedStorage.RigAndWreck.Config.SoundAssets)

local ToolConfigs = require(ReplicatedStorage.RigAndWreck.Config.ToolConfigs)

local OwnershipManager = require(script.Parent.Parent.Core.OwnershipManager)

local BudgetManager = require(script.Parent.Parent.Core.BudgetManager)

local ConstraintRegistry = require(script.Parent.Parent.Physics.ConstraintRegistry)

local PropSpawner = require(script.Parent.Parent.Physics.PropSpawner)

local MotorManager = require(script.Parent.Parent.Physics.MotorManager)

local ThrusterManager = require(script.Parent.Parent.Physics.ThrusterManager)

local BalloonManager = require(script.Parent.Parent.Physics.BalloonManager)

local ExplosivesManager = require(script.Parent.Parent.Physics.ExplosivesManager)

local ServerDispatcher = {}

function ServerDispatcher.Start()
	local spawnPropEvent = RemoteDefinitions.GetEvent("SpawnProp")
	local toolActionEvent = RemoteDefinitions.GetEvent("ToolAction")
	local undoActionEvent = RemoteDefinitions.GetEvent("UndoAction")
	local updateSettingsEvent = RemoteDefinitions.GetEvent("UpdateSettings")
	local playSoundEvent = RemoteDefinitions.GetEvent("PlaySoundEffect")
	local saveBuildFunc = RemoteDefinitions.GetFunction("SaveBuild")
	local loadBuildFunc = RemoteDefinitions.GetFunction("LoadBuild")
	-- spawn prop
	spawnPropEvent.OnServerEvent:Connect(function(player: Player, data: any)

		if type(data) ~= "table" then return end

		if not AntiAbuseGuard.CheckRateLimit(player) then return end
		local cf = data.CFrame

		if typeof(cf) ~= "CFrame" or not RemoteValidator.ValidateCFrame(cf) then return end

		if not RemoteValidator.ValidateDistance(player, cf.Position) then return end

		if data.Template and type(data.Template) == "string" then
			local parts = PropSpawner.SpawnTemplate(player, data.Template, cf)

			if #parts > 0 then
				playSoundEvent:FireClient(player, "Spawn", cf.Position)
			else
				playSoundEvent:FireClient(player, "ErrorBeep")
			end

			return

		end

		local propType = data.PropType

		if type(propType) ~= "string" then return end

		if not RemoteValidator.ValidatePropType(propType) and propType ~= "VehicleSeat" then return end

		local part = PropSpawner.SpawnProp(player, propType, cf, data.CustomSize, data.CustomColor, data.CustomMaterial)

		if part then

			playSoundEvent:FireClient(player, "Spawn", cf.Position)

		else

			playSoundEvent:FireClient(player, "ErrorBeep")

		end

	end)

	-- tool actions

	toolActionEvent.OnServerEvent:Connect(function(player: Player, data: any)

		if type(data) ~= "table" then return end

		if not AntiAbuseGuard.CheckRateLimit(player) then return end

		local action = data.Action

		if type(action) ~= "string" then return end

		-- grab

		if action == "GrabStart" then

			local part = data.Part

			if not OwnershipManager.CanModify(player, part) then return end

			if not RemoteValidator.ValidateDistance(player, part.Position) then return end

			if part.Anchored then

				part.Anchored = false

			end

			-- give net ownership to client

			pcall(function()

				part:SetNetworkOwner(player)

			end)

		elseif action == "GrabEnd" or action == "Throw" then

			local part = data.Part

			if part and part:IsA("BasePart") then

				AntiAbuseGuard.SanitizePartPhysics(part)

				pcall(function()

					part:SetNetworkOwner(nil)

				end)

			end

		elseif action == "Freeze" then

			local part = data.Part

			local freezeState = data.Anchored == true

			if part and part:IsA("BasePart") and OwnershipManager.CanModify(player, part) then

				part.Anchored = freezeState

				if freezeState then

					part.AssemblyLinearVelocity = Vector3.zero

					part.AssemblyAngularVelocity = Vector3.zero

				end

			end

		-- weld & unweld

		elseif action == "Weld" then

			local partA = data.PartA

			local partB = data.PartB

			if not OwnershipManager.CanModify(player, partA) or not OwnershipManager.CanModify(player, partB) then return end

			if not RemoteValidator.ValidateDistance(player, partA.Position) or not RemoteValidator.ValidateDistance(player, partB.Position) then return end

			if not BudgetManager.CanCreateConstraint(player) then

				playSoundEvent:FireClient(player, "ErrorBeep")

				return

			end

			local rec = ConstraintRegistry.RegisterWeld(player, partA, partB)

			playSoundEvent:FireClient(player, "Weld", partA.Position)

		elseif action == "Unweld" then

			local part = data.Part

			if part and part:IsA("BasePart") and OwnershipManager.CanModify(player, part) then

				if not RemoteValidator.ValidateDistance(player, part.Position) then return end

				local count = 0

				local connected = ConstraintRegistry.GetPartConstraints(part)

				for _, rec in ipairs(connected) do

					if rec.constraintType == "WeldConstraint" then

						ConstraintRegistry.DestroyConstraint(rec.id)

						count += 1

					end

				end

				for _, child in ipairs(part:GetChildren()) do

					if child:IsA("WeldConstraint") or child:IsA("Weld") or child:IsA("ManualWeld") then

						child:Destroy()

						count += 1

					end

				end

				-- break other joints to this part

				for _, desc in ipairs(workspace:GetDescendants()) do

					if desc:IsA("WeldConstraint") and (desc.Part0 == part or desc.Part1 == part) then

						desc:Destroy()

						count += 1

					end

				end

				if count > 0 then

					playSoundEvent:FireClient(player, "Delete", part.Position)

				else

					playSoundEvent:FireClient(player, "ErrorBeep")

				end

			end

		elseif action == "UnweldAll" then

			local props = BudgetManager.GetPlayerProps(player)

			local count = 0

			for _, part in ipairs(props) do

				local connected = ConstraintRegistry.GetPartConstraints(part)

				for _, rec in ipairs(connected) do

					if rec.constraintType == "WeldConstraint" then

						ConstraintRegistry.DestroyConstraint(rec.id)

						count += 1

					end

				end

				for _, child in ipairs(part:GetChildren()) do

					if child:IsA("WeldConstraint") or child:IsA("Weld") or child:IsA("ManualWeld") then

						child:Destroy()

						count += 1

					end

				end

			end

			if count > 0 then

				playSoundEvent:FireClient(player, "Delete")

			end

		-- rope

		elseif action == "Rope" then

			local partA = data.PartA

			local partB = data.PartB

			local posA = data.PosA

			local posB = data.PosB

			local length = data.Length or 10

			if not OwnershipManager.CanModify(player, partA) or not OwnershipManager.CanModify(player, partB) then return end

			if not RemoteValidator.ValidateDistance(player, partA.Position) or not RemoteValidator.ValidateDistance(player, partB.Position) then return end

			if not BudgetManager.CanCreateConstraint(player) then

				playSoundEvent:FireClient(player, "ErrorBeep")

				return

			end

			local att0 = Instance.new("Attachment")

			att0.Name = "RigWreck_RopeAtt"

			att0.Position = partA.CFrame:PointToObjectSpace(posA)

			att0.Parent = partA

			local att1 = Instance.new("Attachment")

			att1.Name = "RigWreck_RopeAtt"

			att1.Position = partB.CFrame:PointToObjectSpace(posB)

			att1.Parent = partB

			local rec = ConstraintRegistry.RegisterRope(player, partA, partB, att0, att1, length)

			playSoundEvent:FireClient(player, "Weld", posA)

		-- hinge

		elseif action == "Hinge" then

			local partA = data.PartA

			local partB = data.PartB

			local posA = data.PosA

			local normA = data.NormalA

			local posB = data.PosB

			if not OwnershipManager.CanModify(player, partA) or not OwnershipManager.CanModify(player, partB) then return end

			if not RemoteValidator.ValidateDistance(player, partA.Position) or not RemoteValidator.ValidateDistance(player, partB.Position) then return end

			if not BudgetManager.CanCreateConstraint(player) then

				playSoundEvent:FireClient(player, "ErrorBeep")

				return

			end

			local att0 = Instance.new("Attachment")

			att0.Name = "RigWreck_HingeAtt"

			att0.Position = partA.CFrame:PointToObjectSpace(posA)

			att0.Axis = partA.CFrame:VectorToObjectSpace(normA or Vector3.new(0, 1, 0))

			att0.Parent = partA

			local att1 = Instance.new("Attachment")

			att1.Name = "RigWreck_HingeAtt"

			att1.Position = partB.CFrame:PointToObjectSpace(posB)

			att1.Axis = partB.CFrame:VectorToObjectSpace(normA or Vector3.new(0, 1, 0))

			att1.Parent = partB

			local rec = ConstraintRegistry.RegisterHinge(player, partA, partB, att0, att1, data.LimitsEnabled or false, data.Lower or -90, data.Upper or 90)

			playSoundEvent:FireClient(player, "Weld", posA)

		-- wheel motor

		elseif action == "Motor" then

			local partA = data.PartA

			local partB = data.PartB

			local posA = data.PosA

			local normA = data.NormalA

			local posB = data.PosB

			if not OwnershipManager.CanModify(player, partA) or not OwnershipManager.CanModify(player, partB) then return end

			if not RemoteValidator.ValidateDistance(player, partA.Position) or not RemoteValidator.ValidateDistance(player, partB.Position) then return end

			if not BudgetManager.CanCreateConstraint(player) then

				playSoundEvent:FireClient(player, "ErrorBeep")

				return

			end

			local att0 = Instance.new("Attachment")

			att0.Name = "RigWreck_MotorAtt"

			att0.Position = partA.CFrame:PointToObjectSpace(posA)

			att0.Axis = partA.CFrame:VectorToObjectSpace(normA or Vector3.new(1, 0, 0))

			att0.Parent = partA

			local att1 = Instance.new("Attachment")

			att1.Name = "RigWreck_MotorAtt"

			att1.Position = partB.CFrame:PointToObjectSpace(posB)

			att1.Axis = partB.CFrame:VectorToObjectSpace(normA or Vector3.new(1, 0, 0))

			att1.Parent = partB

			local speed = data.Speed or 16

			local torque = data.Torque or 12000

			local rec = ConstraintRegistry.RegisterMotor(player, partA, partB, att0, att1, speed, torque, "W", "S")

			playSoundEvent:FireClient(player, "Weld", posA)

		-- thruster

		elseif action == "Thruster" then

			local partA = data.PartA

			local posA = data.PosA

			local normA = data.NormalA

			if not OwnershipManager.CanModify(player, partA) then return end

			if not RemoteValidator.ValidateDistance(player, partA.Position) then return end

			if not BudgetManager.CanCreateConstraint(player) then

				playSoundEvent:FireClient(player, "ErrorBeep")

				return

			end

			local att0 = Instance.new("Attachment")

			att0.Name = "RigWreck_ThrusterAtt"

			local n = normA or Vector3.new(0, 1, 0)

			att0.CFrame = partA.CFrame:ToObjectSpace(CFrame.lookAt(posA, posA + n) * CFrame.Angles(math.rad(-90), 0, 0))

			att0.Parent = partA

			local force = data.Force or 14000

			local rec = ConstraintRegistry.RegisterThruster(player, partA, att0, force, "Space")

			playSoundEvent:FireClient(player, "Weld", posA)

		-- drive input dispatch

		elseif action == "SetMotorDirection" then

			local id = data.Id

			local dir = data.Direction or 0

			MotorManager.SetMotorDirection(id, dir)

		elseif action == "SetThrusterActive" then

			local id = data.Id

			local active = data.Active == true

			ThrusterManager.SetThrusterActive(id, active)

		-- transform prop

		elseif action == "Transform" then

			local part = data.Part

			local newCF = data.NewCFrame

			local newSize = data.NewSize

			if not OwnershipManager.CanModify(player, part) then return end

			if not RemoteValidator.ValidateCFrame(newCF) then return end

			if newSize and not RemoteValidator.ValidateSize(newSize) then return end

			if not RemoteValidator.ValidateDistance(player, part.Position) then return end

			local oldCF = part.CFrame

			local oldSize = part.Size

			part.CFrame = newCF

			if newSize then

				part.Size = newSize

			end

		-- paint & material

		elseif action == "Paint" then

			local part = data.Part

			local col = data.Color

			local mat = data.Material

			if not OwnershipManager.CanModify(player, part) then return end

			if not RemoteValidator.ValidateDistance(player, part.Position) then return end

			local oldColor = part.Color

			local oldMaterial = part.Material

			if typeof(col) == "Color3" then part.Color = col end

			if typeof(mat) == "EnumItem" and mat.EnumType == Enum.Material then part.Material = mat end

		elseif action == "Delete" then

			local part = data.Part

			if not OwnershipManager.CanModify(player, part) then return end

			if not RemoteValidator.ValidateDistance(player, part.Position) then return end

			local pos = part.Position

			local propType = part:GetAttribute("PropType") or "Plank"

			local cf = part.CFrame

			local sz = part.Size

			local clr = part.Color

			local mat = part.Material

			local cid = part:GetAttribute("CreationId")

			ConstraintRegistry.DestroyPart(part, player)

			playSoundEvent:FireClient(player, "Delete", pos)

		-- clear all props

		elseif action == "ClearAllProps" then

			local props = BudgetManager.GetPlayerProps(player)

			for _, p in ipairs(props) do

				ConstraintRegistry.DestroyPart(p, player)

			end

			playSoundEvent:FireClient(player, "Delete")

		-- balloon

		elseif action == "CreateBalloon" then

			local targetPart = data.TargetPart

			local hitPos = data.HitPosition

			if targetPart and hitPos and typeof(hitPos) == "Vector3" then

				BalloonManager.CreateBalloon(player, targetPart, hitPos, data.LiftForce, data.Color)

			end

		elseif action == "PopBalloon" then

			local balloonPart = data.BalloonPart

			if balloonPart and balloonPart:IsA("BasePart") then

				BalloonManager.PopBalloon(balloonPart, player)

			end

		-- magnet

		elseif action == "SetMagnet" then

			local part = data.Part

			local polarity = data.Polarity or "North"

			local strength = data.Strength

			if part and part:IsA("BasePart") then

			end

		elseif action == "RemoveMagnet" then

			local part = data.Part

			if part and part:IsA("BasePart") and OwnershipManager.CanModify(player, part) then

			end

		-- weight presets

		elseif action == "SetDensityPreset" then

			local part = data.Part

			local density = data.Density

			local friction = data.Friction or 0.5

			local elasticity = data.Elasticity or 0.2

			local presetName = data.PresetName or "Custom"

			if part and part:IsA("BasePart") and OwnershipManager.CanModify(player, part) and type(density) == "number" then

				local clampedDensity = math.clamp(density, 0.01, 100)

				part.CustomPhysicalProperties = PhysicalProperties.new(clampedDensity, friction, elasticity)

				part:SetAttribute("WeightPreset", presetName)

				part:SetAttribute("Density", clampedDensity)

				pcall(function()

					part:ApplyImpulse(Vector3.new(0, 0.2, 0))

				end)

				playSoundEvent:FireClient(player, "Weld", part.Position)

			end

		-- tnt manual click

		elseif action == "DetonateTNT" then

			local part = data.Part

			if part and part:IsA("BasePart") and part:GetAttribute("PropType") == "TNT" then

				ExplosivesManager.Detonate(part, player)

			end

		end

	end)

	-- undo / redo

	undoActionEvent.OnServerEvent:Connect(function(player: Player, data: any)

		if type(data) ~= "table" then return end

		if not AntiAbuseGuard.CheckRateLimit(player) then return end

		local isRedo = data.Redo == true

		local success = false

		if isRedo then

		else

		end

		if not success then

			playSoundEvent:FireClient(player, "ErrorBeep")

		end

	end)

	-- settings

	updateSettingsEvent.OnServerEvent:Connect(function(player: Player, data: any)

		if type(data) ~= "table" then return end

		if data.Setting == "FreeForAll" and type(data.Value) == "boolean" then

			OwnershipManager.SetFreeForAll(player, data.Value)

			updateSettingsEvent:FireAllClients({ Setting = "FreeForAll", Value = data.Value })

		elseif data.Setting == "ZeroGravity" and type(data.Value) == "boolean" then

			updateSettingsEvent:FireAllClients({ Setting = "ZeroGravity", Value = data.Value })

		elseif data.Setting == "SlowMotion" and type(data.Value) == "boolean" then

		end

	end)

	-- save / load

	saveBuildFunc.OnServerInvoke = function(player: Player, data: any)

		if type(data) ~= "table" then return { Success = false, Message = "Invalid payload" } end

		if not AntiAbuseGuard.CheckRateLimit(player) then return { Success = false, Message = "Rate limit reached" } end

		local slot = data.Slot or 1

		local name = data.Name or ("Build " .. slot)

	end

	loadBuildFunc.OnServerInvoke = function(player: Player, data: any)

		if type(data) ~= "table" then return { Success = false, Message = "Invalid payload" } end

		if not AntiAbuseGuard.CheckRateLimit(player) then return { Success = false, Message = "Rate limit reached" } end

		if data.Action == "Export" then

			local slot = data.Slot or 1

		elseif data.Action == "Import" then

			local code = data.Code

			if type(code) ~= "string" or #code == 0 then

				return { Success = false, Message = "Invalid build code" }

			end

			local cf = data.SpawnCFrame

			if typeof(cf) ~= "CFrame" then

				local _, root = RemoteValidator.ValidatePlayerCharacter(player)

				if root then

					cf = root.CFrame + root.CFrame.LookVector * 12 + Vector3.new(0, 3, 0)

				else

					cf = CFrame.new(0, 5, 0)

				end

			end

		end

		local slot = data.Slot or 1

		local cf = data.SpawnCFrame

		if typeof(cf) ~= "CFrame" then

			local _, root = RemoteValidator.ValidatePlayerCharacter(player)

			if root then

				cf = root.CFrame + root.CFrame.LookVector * 12 + Vector3.new(0, 3, 0)

			else

				cf = CFrame.new(0, 5, 0)

			end

		end

	end

	-- vehicle seat throttle hooks


	local function hookVehicleSeat(seat: VehicleSeat)

		local function updateDrive()
			MotorManager.DriveAssemblyFromSeat(seat)
			ThrusterManager.DriveAssemblyFromSeat(seat)
		end

		seat:GetPropertyChangedSignal("ThrottleFloat"):Connect(updateDrive)
		seat:GetPropertyChangedSignal("SteerFloat"):Connect(updateDrive)
	end

	for _, desc in ipairs(workspace:GetDescendants()) do

		if desc:IsA("VehicleSeat") then

			hookVehicleSeat(desc)

		end

	end

	workspace.DescendantAdded:Connect(function(descendant: Instance)

		if descendant:IsA("VehicleSeat") then

			hookVehicleSeat(descendant)

		end

	end)

	-- player join / leave

	Players.PlayerRemoving:Connect(function(player: Player)

		BudgetManager.CleanupPlayer(player, function(part)

			ConstraintRegistry.DestroyPart(part, player)

		end)

		OwnershipManager.CleanupPlayer(player)

		AntiAbuseGuard.CleanupPlayer(player)

	end)

	Players.PlayerAdded:Connect(function(player: Player)

		BudgetManager.Sync(player)

	end)

end


return ServerDispatcher
