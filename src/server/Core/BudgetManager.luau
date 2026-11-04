--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SystemLimits = require(ReplicatedStorage.RigAndWreck.Config.SystemLimits)

local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)

local BudgetManager = {}

local playerProps: { [number]: { [BasePart]: boolean } } = {}

local playerConstraints: { [number]: { [string]: boolean } } = {}

local syncRemote: RemoteEvent? = nil

local function getSyncRemote(): RemoteEvent

	if not syncRemote then
		syncRemote = RemoteDefinitions.GetEvent("SyncBudget")
	end

	return syncRemote :: RemoteEvent

end

local function getPropCount(userId: number): number
	local set = playerProps[userId]

	if not set then return 0 end
	local c = 0

	for _ in pairs(set) do c += 1 end

	return c
end

local function getConstraintCount(userId: number): number
	local set = playerConstraints[userId]

	if not set then return 0 end
	local c = 0

	for _ in pairs(set) do c += 1 end

	return c
end

function BudgetManager.CanSpawnProp(player: Player): boolean

	return getPropCount(player.UserId) < SystemLimits.MaxPropsPerPlayer
end


function BudgetManager.CanCreateConstraint(player: Player): boolean

	return getConstraintCount(player.UserId) < SystemLimits.MaxConstraintsPerPlayer
end

function BudgetManager.AddProp(player: Player, part: BasePart)
	local uid = player.UserId

	if not playerProps[uid] then
		playerProps[uid] = {}
	end

	playerProps[uid][part] = true

	BudgetManager.Sync(player)

end


function BudgetManager.RemoveProp(player: Player, part: BasePart)
	local uid = player.UserId

	if playerProps[uid] and playerProps[uid][part] then
		playerProps[uid][part] = nil
		BudgetManager.Sync(player)
	end

end


function BudgetManager.AddConstraint(player: Player, id: string)
	local uid = player.UserId

	if not playerConstraints[uid] then
		playerConstraints[uid] = {}
	end

	playerConstraints[uid][id] = true

	BudgetManager.Sync(player)

end

function BudgetManager.RemoveConstraint(player: Player, id: string)
	local uid = player.UserId

	if playerConstraints[uid] and playerConstraints[uid][id] then
		playerConstraints[uid][id] = nil
		BudgetManager.Sync(player)
	end

end

function BudgetManager.GetBudget(player: Player)
	local uid = player.UserId

	return {
		CurrentProps = getPropCount(uid),
		MaxProps = SystemLimits.MaxPropsPerPlayer,
		CurrentConstraints = getConstraintCount(uid),
		MaxConstraints = SystemLimits.MaxConstraintsPerPlayer,
	}
end


function BudgetManager.Sync(player: Player)
	local remote = getSyncRemote()

	if remote then
		remote:FireClient(player, BudgetManager.GetBudget(player))
	end

end

function BudgetManager.GetPlayerProps(player: Player): { BasePart }
	local list = {}
	local set = playerProps[player.UserId]

	if set then

		for part in pairs(set) do

			if part and part.Parent then
				table.insert(list, part)
			end

		end

	end

	return list

end

function BudgetManager.CleanupPlayer(player: Player, destroyCallback: ((BasePart) -> ())?)
	local uid = player.UserId
	local set = playerProps[uid]

	if set then

		for part in pairs(set) do

			if destroyCallback then
				destroyCallback(part)
			elseif part and part.Parent then
				part:Destroy()
			end

		end

		playerProps[uid] = nil

	end

	playerConstraints[uid] = nil

end

return BudgetManager
