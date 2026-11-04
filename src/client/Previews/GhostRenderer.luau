--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PropConfigs = require(ReplicatedStorage.RigAndWreck.Config.PropConfigs)

local PhysicsUtility = require(ReplicatedStorage.RigAndWreck.Utilities.PhysicsUtility)

local GhostRenderer = {}

local ghostPart: BasePart? = nil

local currentPropType: string = "Plank"

local currentSize: Vector3 = Vector3.new(1, 8, 2)

local currentCFrame: CFrame = CFrame.identity

local rotationAngle: number = 0

local function ensureGhost(propType: string): BasePart

	if ghostPart and ghostPart.Parent and ghostPart:GetAttribute("PropType") == propType then

		return ghostPart
	end

	if ghostPart and ghostPart.Parent then

		ghostPart:Destroy()

	end

	local config = PropConfigs.Get(propType :: any)

	local part: BasePart

	if config and config.partType == "Wedge" then

		part = Instance.new("WedgePart")

	else

		part = Instance.new("Part")

		if config and config.partType == "Ball" then

			part.Shape = Enum.PartType.Ball

		elseif config and config.partType == "Cylinder" then

			part.Shape = Enum.PartType.Cylinder

		else

			part.Shape = Enum.PartType.Block

		end

	end

	part.Name = "RigAndWreckGhost"

	part.Size = config and config.defaultSize or Vector3.new(2, 2, 2)

	part.Transparency = 0.5

	part.Color = Color3.fromRGB(80, 180, 255)

	part.Material = Enum.Material.ForceField

	part.CanCollide = false

	part.CanTouch = false

	part.CanQuery = false

	part.CastShadow = false

	part.Anchored = true

	part:SetAttribute("PropType", propType)

	part.Parent = workspace

	ghostPart = part

	currentPropType = propType

	currentSize = part.Size


	return part

end


function GhostRenderer.SetPropType(propType: string)
	currentPropType = propType
	ensureGhost(propType)
end

function GhostRenderer.Rotate()
	rotationAngle = (rotationAngle + 45) % 360
end

function GhostRenderer.Update(hitPosition: Vector3, normal: Vector3, snap: number): CFrame
	local ghost = ensureGhost(currentPropType)
	local halfExtents = ghost.Size * 0.5
	local offsetDist = math.abs(normal:Dot(halfExtents))
	local basePos = hitPosition + normal * offsetDist

	if snap > 0 then
		basePos = PhysicsUtility.SnapVector(basePos, snap)
	end

	local rotCF = CFrame.fromAxisAngle(normal, math.rad(rotationAngle))

	local finalCF = CFrame.new(basePos) * rotCF

	ghost.CFrame = finalCF

	currentCFrame = finalCF

	return finalCF

end

function GhostRenderer.GetCFrame(): CFrame

	return currentCFrame
end


function GhostRenderer.GetPropType(): string

	return currentPropType
end

function GhostRenderer.SetVisible(visible: boolean)

	if ghostPart and ghostPart.Parent then
		ghostPart.Transparency = visible and 0.5 or 1
	end

end

function GhostRenderer.Destroy()

	if ghostPart and ghostPart.Parent then
		ghostPart:Destroy()
		ghostPart = nil
	end

end


return GhostRenderer
