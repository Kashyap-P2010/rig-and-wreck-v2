--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)

local PropConfigs = require(ReplicatedStorage.RigAndWreck.Config.PropConfigs)

local OwnershipManager = require(script.Parent.Parent.Core.OwnershipManager)

local BudgetManager = require(script.Parent.Parent.Core.BudgetManager)

local ConstraintRegistry = require(script.Parent.ConstraintRegistry)

local SystemTypes = require(ReplicatedStorage.RigAndWreck.Types.SystemTypes)

type PropType = SystemTypes.PropType

local PropSpawner = {}

local propsFolder: Folder? = nil


local function getPropsFolder(): Folder

	if not propsFolder or not propsFolder.Parent then
		local f = workspace:FindFirstChild("RigAndWreckProps")

		if not f then
			f = Instance.new("Folder")
			f.Name = "RigAndWreckProps"
			f.Parent = workspace
		end

		propsFolder = f :: Folder

	end

	return propsFolder :: Folder

end

function PropSpawner.SpawnProp(player: Player, propType: string, cframe: CFrame, customSize: Vector3?, customColor: Color3?, customMaterial: Enum.Material?, creationId: string?): BasePart?

	if not BudgetManager.CanSpawnProp(player) then

		return nil
	end

	-- seat special case

	if propType == "VehicleSeat" or propType == "Seat" then

		local seat = Instance.new("VehicleSeat")

		seat.Name = "RigWreck_VehicleSeat"

		seat.Size = customSize or Vector3.new(2, 1, 2)

		seat.CFrame = cframe

		seat.Material = customMaterial or Enum.Material.SmoothPlastic

		seat.Color = customColor or Color3.fromRGB(50, 50, 60)

		seat.TopSurface = Enum.SurfaceType.Smooth

		seat.BottomSurface = Enum.SurfaceType.Smooth

		seat.CustomPhysicalProperties = PhysicalProperties.new(1.0, 0.5, 0.1)

		OwnershipManager.TagProp(seat, player, creationId)

		seat.Parent = getPropsFolder()

		BudgetManager.AddProp(player, seat)


		return seat

	end

	local config = PropConfigs.Get(propType :: any)

	if not config then return nil end

	local part: BasePart

	if config.partType == "Wedge" then

		part = Instance.new("WedgePart")

	else

		part = Instance.new("Part")

		if config.partType == "Ball" then

			part.Shape = Enum.PartType.Ball

		elseif config.partType == "Cylinder" then

			part.Shape = Enum.PartType.Cylinder

		else

			part.Shape = Enum.PartType.Block

		end

	end

	part.Name = "RigWreck_" .. config.name

	part.Size = customSize or config.defaultSize

	part.CFrame = cframe

	part.Material = customMaterial or config.material

	part.Color = customColor or config.color

	part.TopSurface = Enum.SurfaceType.Smooth

	part.BottomSurface = Enum.SurfaceType.Smooth

	part.CustomPhysicalProperties = PhysicalProperties.new(config.density, config.friction, config.elasticity)

	part:SetAttribute("PropType", config.name)

	-- tnt surface guis

	if config.name == "TNT" then

		for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }) do

			local sg = Instance.new("SurfaceGui")

			sg.Face = face

			sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud

			sg.PixelsPerStud = 40

			sg.AlwaysOnTop = false

			sg.Adornee = part

			sg.Parent = part

			local band = Instance.new("Frame")

			band.Size = UDim2.new(1, 0, 0.44, 0)

			band.Position = UDim2.new(0, 0, 0.28, 0)

			band.BackgroundColor3 = Color3.fromRGB(22, 22, 25)

			band.BorderSizePixel = 0

			band.Parent = sg

			local lbl = Instance.new("TextLabel")

			lbl.Size = UDim2.new(1, 0, 1, 0)

			lbl.BackgroundTransparency = 1

			lbl.Font = Enum.Font.GothamBlack

			lbl.Text = "TNT"

			lbl.TextColor3 = Color3.fromRGB(245, 245, 250)

			lbl.TextScaled = true

			lbl.Parent = band

		end

	end

	OwnershipManager.TagProp(part, player, creationId)

	part.Parent = getPropsFolder()

	BudgetManager.AddProp(player, part)

	-- collision sounds, sparks, breakable joints, and tnt explosion

	local lastImpact = 0

	local isTnt = (config.name == "TNT")

	part.Touched:Connect(function(other)

		if not other or not other:IsA("BasePart") then return end

		local now = os.clock()

		if now - lastImpact < 0.2 then return end

		local relVel = (part.AssemblyLinearVelocity - other.AssemblyLinearVelocity).Magnitude

		if relVel > 15 then

			lastImpact = now

			-- emit sparks

			-- explode tnt on hard hit

			if isTnt and relVel > 18 then

				local ExplosivesManager = require(script.Parent.ExplosivesManager)

				ExplosivesManager.Detonate(part, player)

				return

			end

			local playSoundRemote = RemoteDefinitions.GetEvent("PlaySoundEffect")

			if relVel > 45 then

				-- snap joints on hard hit

				ConstraintRegistry.TriggerBreakableImpact(part, relVel)

				playSoundRemote:FireAllClients("RopeSnap", part.Position)

			else

				playSoundRemote:FireAllClients("Weld", part.Position)

			end

		end

	end)


	return part

end


function PropSpawner.SpawnTemplate(player: Player, templateName: string, baseCF: CFrame): { BasePart }
	local parts = {}

	if templateName == "BasicCar" then
		-- main chassis
		local chassis = PropSpawner.SpawnProp(player, "Plank", baseCF + Vector3.new(0, 2.2, 0), Vector3.new(5.6, 0.8, 12), Color3.fromRGB(50, 55, 65), Enum.Material.Metal)

		if not chassis then return parts end
		table.insert(parts, chassis)
		-- vehicle seat
		local seat = PropSpawner.SpawnProp(player, "VehicleSeat", baseCF + Vector3.new(0, 3.4, 0), Vector3.new(2, 1, 2))

		if seat then
			table.insert(parts, seat)
			ConstraintRegistry.RegisterWeld(player, chassis, seat)
		end

		-- rear drive wheels

		local rearOffsets = {

			{ offset = Vector3.new(-3.4, 0, -3.8), name = "RearLeft" },

			{ offset = Vector3.new(3.4, 0, -3.8), name = "RearRight" },

		}

		for _, rInfo in ipairs(rearOffsets) do

			local wheel = PropSpawner.SpawnProp(player, "Cylinder", chassis.CFrame * CFrame.new(rInfo.offset), Vector3.new(1.2, 3.4, 3.4), Color3.fromRGB(30, 30, 35))

			if wheel then

				table.insert(parts, wheel)

				local att0 = Instance.new("Attachment")

				att0.Name = "RigWreck_MotorAtt0"

				att0.Position = rInfo.offset

				att0.Axis = Vector3.new(1, 0, 0)

				att0.Parent = chassis

				local att1 = Instance.new("Attachment")

				att1.Name = "RigWreck_MotorAtt1"

				att1.Position = Vector3.zero

				att1.Axis = Vector3.new(1, 0, 0)

				att1.Parent = wheel

				ConstraintRegistry.RegisterMotor(player, chassis, wheel, att0, att1, 32, 28000, "W", "S")

			end

		end

		-- front steering knuckles

		local frontOffsets = {

			{ kOffset = Vector3.new(-3.1, 0, 3.8), wOffset = Vector3.new(-3.8, 0, 3.8) },

			{ kOffset = Vector3.new(3.1, 0, 3.8), wOffset = Vector3.new(3.8, 0, 3.8) },

		}

		for _, fInfo in ipairs(frontOffsets) do

			local knuckle = PropSpawner.SpawnProp(player, "Crate", chassis.CFrame * CFrame.new(fInfo.kOffset), Vector3.new(0.6, 0.6, 0.6), Color3.fromRGB(70, 75, 85), Enum.Material.Metal)

			local wheel = PropSpawner.SpawnProp(player, "Cylinder", chassis.CFrame * CFrame.new(fInfo.wOffset), Vector3.new(1.2, 3.4, 3.4), Color3.fromRGB(30, 30, 35))

			if knuckle and wheel then

				table.insert(parts, knuckle)

				table.insert(parts, wheel)

				-- steering servo

				local attC = Instance.new("Attachment")

				attC.Name = "RigWreck_SteerAtt0"

				attC.Position = fInfo.kOffset

				attC.Axis = Vector3.new(0, 1, 0)

				attC.Parent = chassis

				local attK = Instance.new("Attachment")

				attK.Name = "RigWreck_SteerAtt1"

				attK.Position = Vector3.zero

				attK.Axis = Vector3.new(0, 1, 0)

				attK.Parent = knuckle

				ConstraintRegistry.RegisterHinge(player, chassis, knuckle, attC, attK, true, -35, 35, true)

				-- drive motor

				local attKWheel = Instance.new("Attachment")

				attKWheel.Name = "RigWreck_WheelAtt0"

				attKWheel.Position = Vector3.new(if fInfo.kOffset.X < 0 then -0.4 else 0.4, 0, 0)

				attKWheel.Axis = Vector3.new(1, 0, 0)

				attKWheel.Parent = knuckle

				local attW = Instance.new("Attachment")

				attW.Name = "RigWreck_WheelAtt1"

				attW.Position = Vector3.zero

				attW.Axis = Vector3.new(1, 0, 0)

				attW.Parent = wheel

				ConstraintRegistry.RegisterMotor(player, knuckle, wheel, attKWheel, attW, 32, 28000, "W", "S")

			end

		end

	elseif templateName == "Catapult" then

		-- base plank

		local basePlank = PropSpawner.SpawnProp(player, "Plank", baseCF + Vector3.new(0, 1, 0), Vector3.new(8, 0.8, 14), Color3.fromRGB(110, 80, 50), Enum.Material.WoodPlanks)

		if not basePlank then return parts end

		table.insert(parts, basePlank)

		-- uprights

		local upL = PropSpawner.SpawnProp(player, "Plank", basePlank.CFrame * CFrame.new(-3.4, 3.5, 0), Vector3.new(0.8, 7, 0.8), Color3.fromRGB(90, 65, 40), Enum.Material.WoodPlanks)

		local upR = PropSpawner.SpawnProp(player, "Plank", basePlank.CFrame * CFrame.new(3.4, 3.5, 0), Vector3.new(0.8, 7, 0.8), Color3.fromRGB(90, 65, 40), Enum.Material.WoodPlanks)

		if upL then table.insert(parts, upL); ConstraintRegistry.RegisterWeld(player, basePlank, upL) end

		if upR then table.insert(parts, upR); ConstraintRegistry.RegisterWeld(player, basePlank, upR) end

		-- arm with basket

		local arm = PropSpawner.SpawnProp(player, "Plank", basePlank.CFrame * CFrame.new(0, 6, -1), Vector3.new(1.2, 0.6, 13), Color3.fromRGB(130, 95, 60), Enum.Material.WoodPlanks)

		if arm and upL then

			table.insert(parts, arm)

			local att0 = Instance.new("Attachment")

			att0.Position = upL.CFrame:PointToObjectSpace((basePlank.CFrame * CFrame.new(-3.4, 6, 0)).Position)

			att0.Axis = Vector3.new(1, 0, 0)

			att0.Parent = upL

			local att1 = Instance.new("Attachment")

			att1.Position = arm.CFrame:PointToObjectSpace((basePlank.CFrame * CFrame.new(0, 6, 0)).Position)

			att1.Axis = Vector3.new(1, 0, 0)

			att1.Parent = arm

			ConstraintRegistry.RegisterHinge(player, upL, arm, att0, att1, true, -65, 45, false)

			-- basket crate

			local basket = PropSpawner.SpawnProp(player, "Crate", arm.CFrame * CFrame.new(0, 1.2, 5.5), Vector3.new(2.4, 1.6, 2.4), Color3.fromRGB(170, 120, 70), Enum.Material.Wood)

			if basket then

				table.insert(parts, basket)

				ConstraintRegistry.RegisterWeld(player, arm, basket)

				-- ammo ball

				local ammo = PropSpawner.SpawnProp(player, "Ball", arm.CFrame * CFrame.new(0, 2.4, 5.5), Vector3.new(2, 2, 2), Color3.fromRGB(220, 50, 50))

				if ammo then table.insert(parts, ammo) end

			end

		end

	elseif templateName == "Rocket" then

		-- fuselage

		local fuselage = PropSpawner.SpawnProp(player, "Cylinder", baseCF + Vector3.new(0, 8, 0), Vector3.new(14, 3.4, 3.4), Color3.fromRGB(230, 230, 235), Enum.Material.Metal)

		if not fuselage then return parts end

		table.insert(parts, fuselage)

		-- side seat

		local seat = PropSpawner.SpawnProp(player, "VehicleSeat", fuselage.CFrame * CFrame.new(0, 2, 2.2), Vector3.new(2, 1, 2))

		if seat then

			table.insert(parts, seat)

			ConstraintRegistry.RegisterWeld(player, fuselage, seat)

		end

		-- 4 fins

		local finAngles = { 0, 90, 180, 270 }

		for _, angle in ipairs(finAngles) do

			local finCF = fuselage.CFrame * CFrame.Angles(0, math.rad(angle), 0) * CFrame.new(0, -4.5, 2.4) * CFrame.Angles(0, math.rad(180), 0)

			local fin = PropSpawner.SpawnProp(player, "Wedge", finCF, Vector3.new(0.6, 3, 2.4), Color3.fromRGB(200, 45, 45), Enum.Material.Metal)

			if fin then

				table.insert(parts, fin)

				ConstraintRegistry.RegisterWeld(player, fuselage, fin)

			end

		end

		-- rocket thruster

		local tAtt = Instance.new("Attachment")

		tAtt.Name = "RigWreck_RocketAtt"

		tAtt.CFrame = CFrame.new(0, -7, 0) * CFrame.Angles(math.rad(-90), 0, 0)

		tAtt.Parent = fuselage

		ConstraintRegistry.RegisterThruster(player, fuselage, tAtt, 75000, "LeftShift")

	end

	return parts

end

return PropSpawner
