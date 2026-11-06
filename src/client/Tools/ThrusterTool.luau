--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseTool = require(script.Parent.BaseTool)
local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)
local SelectionHighlighter = require(script.Parent.Parent.Previews.SelectionHighlighter)
local TargetDetector = require(script.Parent.Parent.Core.TargetDetector)

type TargetData = TargetDetector.TargetData

local ThrusterTool = setmetatable({}, BaseTool)
ThrusterTool.__index = ThrusterTool

function ThrusterTool.new()
	local self = setmetatable(BaseTool.new("Thruster"), ThrusterTool)
	self.ThrusterForce = 16000
	self.ToolActionRemote = RemoteDefinitions.GetEvent("ToolAction")

	return self
end

function ThrusterTool:SetForce(force: number)
	self.ThrusterForce = force
end

function ThrusterTool:Unequip()
	BaseTool.Unequip(self)
	SelectionHighlighter.Clear()
end

function ThrusterTool:OnPointerMove(target: TargetData)
	if target.IsProp and target.Instance then
		SelectionHighlighter.HighlightHover(target.Instance)
	else
		SelectionHighlighter.HighlightHover(nil)
	end
end

function ThrusterTool:OnActionTriggered()
	local target = TargetDetector.GetTarget()
	if not target.IsProp or not target.Instance then return end

	self.ToolActionRemote:FireServer({
		Action = "Thruster",
		PartA = target.Instance,
		PosA = target.Position,
		NormalA = target.Normal,
		Force = self.ThrusterForce,
	})
end

function ThrusterTool:OnSecondaryTriggered()
	-- cycle thrust force presets: 8000 -> 16000 -> 32000
	if self.ThrusterForce < 16000 then
		self.ThrusterForce = 16000
	elseif self.ThrusterForce < 32000 then
		self.ThrusterForce = 32000
	else
		self.ThrusterForce = 8000
	end
end

return ThrusterTool
