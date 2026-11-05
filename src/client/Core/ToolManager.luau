--!strict

local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)

local TargetDetector = require(script.Parent.TargetDetector)

local GhostRenderer = require(script.Parent.Parent.Previews.GhostRenderer)

local GrabTool = require(script.Parent.Parent.Tools.GrabTool)

local WeldTool = require(script.Parent.Parent.Tools.WeldTool)

local HingeTool = require(script.Parent.Parent.Tools.HingeTool)

local ToolManager = {}

local tools: { [number]: any } = {}

local activeToolIndex: number? = 1

local isSpawnMode = false

local currentSpawnSnap = 1

local spawnPropRemote = RemoteDefinitions.GetEvent("SpawnProp")

function ToolManager.Init()
	tools[1] = GrabTool.new()
	tools[2] = WeldTool.new()
	tools[6] = HingeTool.new()
	ToolManager.SelectTool(1)
	RunService.RenderStepped:Connect(function()
		local target = TargetDetector.GetTarget()

		if isSpawnMode then
			GhostRenderer.Update(target.Position, target.Normal, currentSpawnSnap)
		else
			local tool = activeToolIndex and tools[activeToolIndex]

			if tool and tool.IsEquipped then
				tool:OnPointerMove(target)

				if tool.Name == "Grab" and tool.HeldPart then
					ViewportCardView.SetReticleState("holding")
				elseif target.IsProp and target.Instance then
					ViewportCardView.SetReticleState("hover")
				else
					ViewportCardView.SetReticleState("idle")
				end

			end

		end

	end)

end

function ToolManager.SelectTool(index: number)

	if isSpawnMode then
		isSpawnMode = false
		GhostRenderer.SetVisible(false)
	end

	if activeToolIndex and tools[activeToolIndex] then

		tools[activeToolIndex]:Unequip()

	end

	activeToolIndex = index

	local newTool = tools[index]

	if newTool then

		newTool:Equip()

		HotbarView.SetActive(index)

		ToolInspectorView.ShowForTool(newTool.Name, newTool)

		ViewportCardView.SetTool(newTool.Name)

	end

end


function ToolManager.EnterSpawnMode(propType: string, snap: number)

	if activeToolIndex and tools[activeToolIndex] then
		tools[activeToolIndex]:Unequip()
	end

	activeToolIndex = nil

	HotbarView.SetActive(nil)

	ToolInspectorView.Hide()

	isSpawnMode = true

	currentSpawnSnap = snap

	GhostRenderer.SetPropType(propType)

	GhostRenderer.SetVisible(true)

end


function ToolManager.TriggerAction()

	if isSpawnMode then
		local cf = GhostRenderer.GetCFrame()
		local propType = GhostRenderer.GetPropType()
		spawnPropRemote:FireServer({
			PropType = propType,
			CFrame = cf,
		})
	else
		local tool = activeToolIndex and tools[activeToolIndex]

		if tool then
			tool:OnActionTriggered()
		end

	end

end


function ToolManager.TriggerSecondary()

	if isSpawnMode then
		-- cancel spawn mode
		isSpawnMode = false
		GhostRenderer.SetVisible(false)
		ToolManager.SelectTool(1)
	else
		local tool = activeToolIndex and tools[activeToolIndex]

		if tool then
			tool:OnSecondaryTriggered()
		end

	end

end


function ToolManager.TriggerRotate(axis: string?)

	if isSpawnMode then
		GhostRenderer.Rotate()
	else
		local tool = activeToolIndex and tools[activeToolIndex]

		if tool and tool.Name == "Grab" then
			tool:RotateHeld(axis)
		elseif tool and tool.Name == "Transform" then
			tool:RotateSelected(45)
		end

	end

end

function ToolManager.TriggerFreeze()
	local tool = activeToolIndex and tools[activeToolIndex]

	if tool and type(tool.ToggleFreeze) == "function" then
		tool:ToggleFreeze()
	end

end


function ToolManager.AdjustDistance(delta: number)
	local tool = activeToolIndex and tools[activeToolIndex]

	if tool and type(tool.AdjustDistance) == "function" then
		tool:AdjustDistance(delta)
	end

end

function ToolManager.GetActiveTool(): any

	return activeToolIndex and tools[activeToolIndex]
end


return ToolManager
