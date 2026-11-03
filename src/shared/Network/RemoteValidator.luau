--!strict

local ToolConfigs = require(script.Parent.Parent.Config.ToolConfigs)

local PropConfigs = require(script.Parent.Parent.Config.PropConfigs)

local SystemLimits = require(script.Parent.Parent.Config.SystemLimits)

local RemoteValidator = {}

function RemoteValidator.ValidatePlayerCharacter(player: Player): (boolean, BasePart?)
	local character = player.Character

	if not character then return false, nil end
	local root = character:FindFirstChild("HumanoidRootPart")

	if not root or not root:IsA("BasePart") then return false, nil end

	return true, root
end

function RemoteValidator.ValidateDistance(player: Player, targetPos: Vector3, maxDistance: number?): boolean
	local ok, root = RemoteValidator.ValidatePlayerCharacter(player)

	if not ok or not root then return false end
	local dist = (root.Position - targetPos).Magnitude
	local limit = maxDistance or ToolConfigs.InteractionRange

	return dist <= limit
end

function RemoteValidator.ValidatePropType(propType: string): boolean

	return PropConfigs.Get(propType :: any) ~= nil
end


function RemoteValidator.ValidateVectorFinite(vec: Vector3): boolean

	local function isFinite(n: number): boolean

		return n == n and math.abs(n) ~= math.huge
	end

	return isFinite(vec.X) and isFinite(vec.Y) and isFinite(vec.Z)
end

function RemoteValidator.ValidateCFrame(cf: CFrame): boolean

	if not RemoteValidator.ValidateVectorFinite(cf.Position) then

		return false
	end

	-- clamp to world bounds

	local pos = cf.Position

	if math.abs(pos.X) > 2000 or math.abs(pos.Z) > 2000 or pos.Y < SystemLimits.WorldYBoundary or pos.Y > 2000 then


		return false

	end


	return true

end


function RemoteValidator.ValidateSize(size: Vector3, minSize: Vector3?, maxSize: Vector3?): boolean

	if not RemoteValidator.ValidateVectorFinite(size) then return false end
	local min = minSize or Vector3.new(SystemLimits.MinPropDimension, SystemLimits.MinPropDimension, SystemLimits.MinPropDimension)
	local max = maxSize or Vector3.new(SystemLimits.MaxPropDimension, SystemLimits.MaxPropDimension, SystemLimits.MaxPropDimension)

	return size.X >= min.X and size.X <= max.X
		and size.Y >= min.Y and size.Y <= max.Y
		and size.Z >= min.Z and size.Z <= max.Z
end

return RemoteValidator
