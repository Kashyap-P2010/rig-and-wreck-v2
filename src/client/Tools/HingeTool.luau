--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseTool = require(script.Parent.BaseTool)
local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)
local SelectionHighlighter = require(script.Parent.Parent.Previews.SelectionHighlighter)
local TargetDetector = require(script.Parent.Parent.Core.TargetDetector)

type TargetData = TargetDetector.TargetData

local HingeTool = setmetatable({}, BaseTool)
HingeTool.__index = HingeTool

function HingeTool.new()
	local self = setmetatable(BaseTool.new("Hinge"), HingeTool)
	self.FirstPart = nil :: BasePart?
	self.FirstPos = nil :: Vector3?
	self.FirstNormal = nil :: Vector3?
	self.LimitsEnabled = false
	self.LowerAngle = -90
	self.UpperAngle = 90
	self.ToolActionRemote = RemoteDefinitions.GetEvent("ToolAction")

	return self
end

function HingeTool:Unequip()
	BaseTool.Unequip(self)
	self.FirstPart = nil
	self.FirstPos = nil
	self.FirstNormal = nil
	SelectionHighlighter.Clear()
end

function HingeTool:OnPointerMove(target: TargetData)
	if target.IsProp and target.Instance then
		if target.Instance ~= self.FirstPart then
			SelectionHighlighter.HighlightHover(target.Instance)
		end
	else
		SelectionHighlighter.HighlightHover(nil)
	end
end

function HingeTool:OnActionTriggered()
	local target = TargetDetector.GetTarget()
	if not target.IsProp or not target.Instance then return end

	if not self.FirstPart then
		self.FirstPart = target.Instance
		self.FirstPos = target.Position
		self.FirstNormal = target.Normal
		SelectionHighlighter.HighlightSelected(target.Instance, Color3.fromRGB(240, 180, 50))
	else
		local secondPart = target.Instance
		local secondPos = target.Position

		if secondPart ~= self.FirstPart and self.FirstPos and self.FirstNormal then
			self.ToolActionRemote:FireServer({
				Action = "Hinge",
				PartA = self.FirstPart,
				PartB = secondPart,
				PosA = self.FirstPos,
				NormalA = self.FirstNormal,
				PosB = secondPos,
				LimitsEnabled = self.LimitsEnabled,
				Lower = self.LowerAngle,
				Upper = self.UpperAngle,
			})
		end

		self.FirstPart = nil
		self.FirstPos = nil
		self.FirstNormal = nil
		SelectionHighlighter.Clear()
	end
end

function HingeTool:OnSecondaryTriggered()
	if self.FirstPart then
		self.FirstPart = nil
		self.FirstPos = nil
		self.FirstNormal = nil
		SelectionHighlighter.Clear()
	else
		-- toggle limit presets: free 360 vs 90 deg swing
		self.LimitsEnabled = not self.LimitsEnabled
	end
end

return HingeTool
