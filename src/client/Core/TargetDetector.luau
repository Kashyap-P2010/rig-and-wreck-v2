--!strict

local Players = game:GetService("Players")

local UserInputService = game:GetService("UserInputService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToolConfigs = require(ReplicatedStorage.RigAndWreck.Config.ToolConfigs)

local localPlayer = Players.LocalPlayer

local camera = workspace.CurrentCamera

local TargetDetector = {}

export type TargetData = {

	Instance: BasePart?,

	Position: Vector3,

	Normal: Vector3,

	CFrame: CFrame,

	IsProp: boolean,

	OwnerUserId: number?,

	OwnerName: string?,

}

local ignoreList: { Instance } = {}


function TargetDetector.SetIgnoreList(list: { Instance })
	ignoreList = list
end


function TargetDetector.GetTarget(customRayPos: Vector2?): TargetData
	local cam = workspace.CurrentCamera
	local mousePos = customRayPos or UserInputService:GetMouseLocation()
	local ray = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filter: { Instance } = { localPlayer.Character }

	for _, inst in ipairs(ignoreList) do
		table.insert(filter, inst)
	end

	local ghost = workspace:FindFirstChild("RigAndWreckGhost")

	if ghost then table.insert(filter, ghost) end

	params.FilterDescendantsInstances = filter

	local range = ToolConfigs.InteractionRange

	local result = workspace:Raycast(ray.Origin, ray.Direction * range, params)

	if result then

		local hitPart = result.Instance

		local isProp = false

		local ownerId: number? = nil

		local ownerName: string? = nil

		if hitPart and hitPart:IsA("BasePart") then

			isProp = hitPart:GetAttribute("IsRigWreckProp") == true

			ownerId = hitPart:GetAttribute("OwnerUserId") :: number?

			ownerName = hitPart:GetAttribute("OwnerName") :: string?

		end

		return {

			Instance = hitPart,

			Position = result.Position,

			Normal = result.Normal,

			CFrame = CFrame.lookAt(result.Position, result.Position + result.Normal),

			IsProp = isProp,

			OwnerUserId = ownerId,

			OwnerName = ownerName,

		}

	else

		local fallbackPos = ray.Origin + ray.Direction * 20

		return {

			Instance = nil,

			Position = fallbackPos,

			Normal = Vector3.new(0, 1, 0),

			CFrame = CFrame.new(fallbackPos),

			IsProp = false,

			OwnerUserId = nil,

			OwnerName = nil,

		}

	end

end


return TargetDetector
