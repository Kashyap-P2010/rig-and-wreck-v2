--!strict

local HttpService = game:GetService("HttpService")

local OwnershipManager = {}

local freeForAllSettings: { [number]: boolean } = {}


function OwnershipManager.TagProp(part: BasePart, player: Player, creationId: string?): string
	local id = creationId or HttpService:GenerateGUID(false)
	part:SetAttribute("IsRigWreckProp", true)
	part:SetAttribute("OwnerUserId", player.UserId)
	part:SetAttribute("OwnerName", player.DisplayName or player.Name)
	part:SetAttribute("CreationId", id)
	part:SetAttribute("CreatedAt", os.time())

	return id
end


function OwnershipManager.IsProp(instance: Instance?): boolean

	if not instance or not instance:IsA("BasePart") then return false end

	return instance:GetAttribute("IsRigWreckProp") == true
end

function OwnershipManager.CanModify(player: Player, part: BasePart?): boolean

	if not OwnershipManager.IsProp(part) then return false end
	local ownerId = (part :: BasePart):GetAttribute("OwnerUserId")

	if not ownerId then return false end

	if ownerId == player.UserId then

		return true
	end

	-- check ffa setting

	if freeForAllSettings[ownerId] == true then

		return true

	end

	return false

end

function OwnershipManager.SetFreeForAll(player: Player, enabled: boolean)
	freeForAllSettings[player.UserId] = enabled
end

function OwnershipManager.IsFreeForAll(player: Player): boolean

	return freeForAllSettings[player.UserId] == true
end


function OwnershipManager.GetOwnerInfo(part: BasePart): { userId: number?, name: string? }

	return {
		userId = part:GetAttribute("OwnerUserId") :: number?,
		name = part:GetAttribute("OwnerName") :: string?,
	}
end


function OwnershipManager.CleanupPlayer(player: Player)
	freeForAllSettings[player.UserId] = nil
end


return OwnershipManager
