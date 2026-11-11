--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseTool = require(script.Parent.BaseTool)

local ToolConfigs = require(ReplicatedStorage.RigAndWreck.Config.ToolConfigs)

local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)

local SelectionHighlighter = require(script.Parent.Parent.Previews.SelectionHighlighter)

local TargetDetector = require(script.Parent.Parent.Core.TargetDetector)

type TargetData = TargetDetector.TargetData

local PaintTool = setmetatable({}, BaseTool)

PaintTool.__index = PaintTool

function PaintTool.new()
	local self = setmetatable(BaseTool.new("Paint"), PaintTool)
	self.SelectedColor = ToolConfigs.Paint.Palette[4] -- default red
	self.SelectedMaterial = Enum.Material.SmoothPlastic
	self.ToolActionRemote = RemoteDefinitions.GetEvent("ToolAction")

	return self
end


function PaintTool:SetColor(color: Color3)
	self.SelectedColor = color
end


function PaintTool:SetMaterial(mat: Enum.Material)
	self.SelectedMaterial = mat
end


function PaintTool:Unequip()
	BaseTool.Unequip(self)
	SelectionHighlighter.Clear()
end

function PaintTool:OnPointerMove(target: TargetData)

	if target.IsProp and target.Instance then
		SelectionHighlighter.HighlightHover(target.Instance)
	else
		SelectionHighlighter.HighlightHover(nil)
	end

end

function PaintTool:OnActionTriggered()
	local target = TargetDetector.GetTarget()

	if not target.IsProp or not target.Instance then return end
	self.ToolActionRemote:FireServer({
		Action = "Paint",
		Part = target.Instance,
		Color = self.SelectedColor,
		Material = self.SelectedMaterial,
	})
end

return PaintTool
