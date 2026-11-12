--!strict

local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToolConfigs = require(ReplicatedStorage.RigAndWreck.Config.ToolConfigs)

local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)

local OwnershipManager = require(script.Parent.Parent.Core.OwnershipManager)

type MagnetRecord = {

	Part: BasePart,

	Polarity: string, -- north or south

	Strength: number,

	PhysicsAttachment: Attachment,

	BeamAttachment: Attachment,

	VisualModel: Instance?,

}

type ActiveForceRecord = {

	LineForce: LineForce,

	Beam: Beam?,

	PartA: BasePart,

	PartB: BasePart,

}

local MagnetManager = {}

local activeMagnets: { [BasePart]: MagnetRecord } = {}

local activeForces: { [string]: ActiveForceRecord } = {}

local heartbeatConn: RBXScriptConnection? = nil

-- weak part id mapping

local nextPartId = 0

local partIdMap = setmetatable({}, { __mode = "k" })

local function getPartId(part: BasePart): number
	local id = partIdMap[part]

	if not id then
		nextPartId += 1
		id = nextPartId
		partIdMap[part] = id
	end

	return id

end

local function getPairKey(partA: BasePart, partB: BasePart): string
	local idA = getPartId(partA)
	local idB = getPartId(partB)

	if idA < idB then

		return idA .. ":" .. idB
	else

		return idB .. ":" .. idA
	end

end

local function removeVisual(part: BasePart)
	local oldVis = part:FindFirstChild("RigWreck_MagnetVisual")

	if oldVis then
		oldVis:Destroy()
	end

end

local function createVisual(part: BasePart, polarity: string): (Instance, Attachment)
	removeVisual(part)
	local isNorth = (polarity == "North")
	local color = if isNorth then ToolConfigs.Magnet.NorthColor else ToolConfigs.Magnet.SouthColor
	local visFolder = Instance.new("Folder")
	visFolder.Name = "RigWreck_MagnetVisual"
	-- glowing orb
	local orb = Instance.new("Part")
	orb.Name = "MagnetOrb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(1.3, 1.3, 1.3)
	orb.Color = color
	orb.Material = Enum.Material.Neon
	orb.CanCollide = false
	orb.CanTouch = false
	orb.CanQuery = false
	orb.Massless = true
	orb.CFrame = part.CFrame * CFrame.new(0, part.Size.Y * 0.5 + 0.35, 0)
	orb.Parent = visFolder
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part
	weld.Part1 = orb
	weld.Parent = orb
	-- beam attachment
	local beamAtt = Instance.new("Attachment")
	beamAtt.Name = "RigWreck_BeamAtt"
	beamAtt.Position = Vector3.zero
	beamAtt.Parent = orb
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 14
	light.Brightness = 3
	light.Parent = orb
	local bb = Instance.new("BillboardGui")
	bb.Name = "MagnetBB"
	bb.Size = UDim2.new(0, 115, 0, 26)
	bb.StudsOffset = Vector3.new(0, 1.6, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = orb
	bb.Parent = orb
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 1.4
	stroke.Parent = frame
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 11
	lbl.TextColor3 = color
	lbl.Text = if isNorth then "NORTH [N]" else "SOUTH [S]"
	lbl.Parent = frame
	visFolder.Parent = part

	return visFolder, beamAtt
end


function MagnetManager.SetMagnet(player: Player, part: BasePart, polarity: string, customStrength: number?): boolean

	if not part or not part.Parent or not part:IsA("BasePart") then return false end

	if not OwnershipManager.CanModify(player, part) then return false end

	if polarity ~= "North" and polarity ~= "South" then
		polarity = if polarity == "Repel" then "South" else "North"
	end

	local strength = customStrength or ToolConfigs.Magnet.DefaultForce or 35000

	if part.Anchored then

		part.Anchored = false

	end

	pcall(function()

		part:ApplyImpulse(Vector3.new(0, 0.5, 0))

	end)

	local physAtt = part:FindFirstChild("RigWreck_MagnetAtt") :: Attachment?

	if not physAtt then

		physAtt = Instance.new("Attachment")

		physAtt.Name = "RigWreck_MagnetAtt"

		physAtt.Position = Vector3.zero

		physAtt.Parent = part

	end

	local vis, beamAtt = createVisual(part, polarity)

	part:SetAttribute("MagnetPolarity", polarity)

	part:SetAttribute("MagnetStrength", strength)

	activeMagnets[part] = {

		Part = part,

		Polarity = polarity,

		Strength = strength,

		PhysicsAttachment = physAtt :: Attachment,

		BeamAttachment = beamAtt,

		VisualModel = vis,

	}

	part.Destroying:Connect(function()

		MagnetManager.RemoveMagnet(part)

	end)

	local playSound = RemoteDefinitions.GetEvent("PlaySoundEffect")

	playSound:FireClient(player, "Weld", part.Position)

	MagnetManager.EnsureLoop()


	return true

end


function MagnetManager.RemoveMagnet(part: BasePart)
	removeVisual(part)
	local physAtt = part:FindFirstChild("RigWreck_MagnetAtt")

	if physAtt then physAtt:Destroy() end
	part:SetAttribute("MagnetPolarity", nil)
	part:SetAttribute("MagnetStrength", nil)
	local toRemove: { string } = {}

	for pairKey, forceData in pairs(activeForces) do

		if forceData.PartA == part or forceData.PartB == part then

			if forceData.LineForce and forceData.LineForce.Parent then forceData.LineForce:Destroy() end

			if forceData.Beam and forceData.Beam.Parent then forceData.Beam:Destroy() end
			table.insert(toRemove, pairKey)
		end

	end

	for _, key in ipairs(toRemove) do

		activeForces[key] = nil

	end

	activeMagnets[part] = nil

end

function MagnetManager.EnsureLoop()

	if heartbeatConn then return end
	heartbeatConn = RunService.Heartbeat:Connect(function()
		local deadList: { BasePart } = {}
		local list: { MagnetRecord } = {}

		for part, record in pairs(activeMagnets) do

			if part.Parent and part:IsA("BasePart") and record.PhysicsAttachment and record.PhysicsAttachment.Parent == part and record.BeamAttachment and record.BeamAttachment.Parent then
				table.insert(list, record)
			else
				table.insert(deadList, part)
			end

		end

		for _, deadPart in ipairs(deadList) do

			MagnetManager.RemoveMagnet(deadPart)

		end

		local count = #list

		if count < 2 then

			for _, forceData in pairs(activeForces) do

				if forceData.LineForce and forceData.LineForce.Parent then forceData.LineForce:Destroy() end

				if forceData.Beam and forceData.Beam.Parent then forceData.Beam:Destroy() end

			end

			table.clear(activeForces)

			return

		end

		local maxDist = ToolConfigs.Magnet.MaxDistance or 45

		local activePairsInStep: { [string]: boolean } = {}

		for i = 1, count - 1 do

			local recA = list[i]

			local partA = recA.Part

			for j = i + 1, count do

				local recB = list[j]

				local partB = recB.Part

				if partA ~= partB and (not partA.Anchored or not partB.Anchored) then

					local offset = partB.Position - partA.Position

					local dist = offset.Magnitude

					if dist <= maxDist and dist > 0.5 then

						local pairKey = getPairKey(partA, partB)

						activePairsInStep[pairKey] = true

						-- opposites pull

						-- likes push

						local isAttract = (recA.Polarity ~= recB.Polarity)

						local baseForce = math.max(recA.Strength, recB.Strength)

						local distFactor = math.clamp(1 - (dist / maxDist), 0.3, 1.0)

						local forceMag = baseForce * (distFactor * distFactor)

						local signedForce = if isAttract then forceMag else -forceMag

						local beamColor = if isAttract then ToolConfigs.Magnet.AttractBeamColor else ToolConfigs.Magnet.RepelBeamColor

						local forceData = activeForces[pairKey]

						if not forceData or not forceData.LineForce or not forceData.LineForce.Parent then

							local lf = Instance.new("LineForce")

							lf.Name = "RigWreck_LineForce"

							lf.Attachment0 = recA.PhysicsAttachment

							lf.Attachment1 = recB.PhysicsAttachment

							lf.ApplyAtCenterOfMass = true

							lf.ReactionForceEnabled = true

							lf.InverseSquareLaw = false

							lf.Magnitude = signedForce

							lf.Parent = partA

							local beam = Instance.new("Beam")

							beam.Name = "RigWreck_MagnetBeam"

							beam.Attachment0 = recA.BeamAttachment

							beam.Attachment1 = recB.BeamAttachment

							beam.Color = ColorSequence.new(beamColor)

							beam.Width0 = 0.45

							beam.Width1 = 0.45

							beam.FaceCamera = true

							beam.LightEmission = 1

							beam.LightInfluence = 0

							beam.Transparency = NumberSequence.new(0.05)

							beam.Parent = partA

							activeForces[pairKey] = {

								LineForce = lf,

								Beam = beam,

								PartA = partA,

								PartB = partB,

							}

						else

							forceData.LineForce.Magnitude = signedForce

							if forceData.Beam and forceData.Beam.Parent then

								forceData.Beam.Color = ColorSequence.new(beamColor)

								forceData.Beam.Attachment0 = recA.BeamAttachment

								forceData.Beam.Attachment1 = recB.BeamAttachment

							end

						end

					end

				end

			end

		end

		local toClean: { string } = {}

		for pairKey, forceData in pairs(activeForces) do

			if not activePairsInStep[pairKey] then

				if forceData.LineForce and forceData.LineForce.Parent then forceData.LineForce:Destroy() end

				if forceData.Beam and forceData.Beam.Parent then forceData.Beam:Destroy() end

				table.insert(toClean, pairKey)

			end

		end

		for _, pairKey in ipairs(toClean) do

			activeForces[pairKey] = nil

		end

	end)

end


return MagnetManager
