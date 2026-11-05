--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseTool = require(script.Parent.BaseTool)
local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)
local SelectionHighlighter = require(script.Parent.Parent.Previews.SelectionHighlighter)
local TargetDetector = require(script.Parent.Parent.Core.TargetDetector)

type TargetData = TargetDetector.TargetData

local WheelMotorTool = setmetatable({}, BaseTool)
WheelMotorTool.__index = WheelMotorTool

function WheelMotorTool.new()
	local self = setmetatable(BaseTool.new("Motor"), WheelMotorTool)
	self.FirstPart = nil :: BasePart?
	self.FirstPos = nil :: Vector3?
	self.FirstNormal = nil :: Vector3?
	self.MotorSpeed = 20
	self.MotorTorque = 15000
	self.Inverted = false
	self.ToolActionRemote = RemoteDefinitions.GetEvent("ToolAction")

	return self
end

function WheelMotorTool:SetSpeed(spd: number)
	self.MotorSpeed = spd
end

function WheelMotorTool:SetTorque(trq: number)
	self.MotorTorque = trq
end

function WheelMotorTool:Unequip()
	BaseTool.Unequip(self)
	self.FirstPart = nil
	self.FirstPos = nil
	self.FirstNormal = nil
	SelectionHighlighter.Clear()
end

function WheelMotorTool:OnPointerMove(target: TargetData)
	if target.IsProp and target.Instance then
		if target.Instance ~= self.FirstPart then
			SelectionHighlighter.HighlightHover(target.Instance)
		end
	else
		SelectionHighlighter.HighlightHover(nil)
	end
end

function WheelMotorTool:OnActionTriggered()
	local target = TargetDetector.GetTarget()
	if not target.IsProp or not target.Instance then return end

	if not self.FirstPart then
		self.FirstPart = target.Instance
		self.FirstPos = target.Position
		self.FirstNormal = target.Normal
		SelectionHighlighter.HighlightSelected(target.Instance, Color3.fromRGB(245, 120, 40))
	else
		local secondPart = target.Instance
		local secondPos = target.Position

		if secondPart ~= self.FirstPart and self.FirstPos and self.FirstNormal then
			local finalSpeed = if self.Inverted then -self.MotorSpeed else self.MotorSpeed
			self.ToolActionRemote:FireServer({
				Action = "Motor",
				PartA = self.FirstPart,
				PartB = secondPart,
				PosA = self.FirstPos,
				NormalA = self.FirstNormal,
				PosB = secondPos,
				Speed = finalSpeed,
				Torque = self.MotorTorque,
			})
		end

		self.FirstPart = nil
		self.FirstPos = nil
		self.FirstNormal = nil
		SelectionHighlighter.Clear()
	end
end

function WheelMotorTool:OnSecondaryTriggered()
	if self.FirstPart then
		self.FirstPart = nil
		self.FirstPos = nil
		self.FirstNormal = nil
		SelectionHighlighter.Clear()
	else
		-- toggle motor spin direction
		self.Inverted = not self.Inverted
	end
end

return WheelMotorTool
