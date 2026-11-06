--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseTool = require(script.Parent.BaseTool)
local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)
local SelectionHighlighter = require(script.Parent.Parent.Previews.SelectionHighlighter)
local TargetDetector = require(script.Parent.Parent.Core.TargetDetector)
local GhostSilhouette = require(ReplicatedStorage.RigAndWreck.Utilities.GhostSilhouette)

type TargetData = TargetDetector.TargetData

local DeleteTool = setmetatable({}, BaseTool)
DeleteTool.__index = DeleteTool

function DeleteTool.new()
	local self = setmetatable(BaseTool.new("Delete"), DeleteTool)
	self.ToolActionRemote = RemoteDefinitions.GetEvent("ToolAction")

	return self
end

function DeleteTool:Unequip()
	BaseTool.Unequip(self)
	SelectionHighlighter.Clear()
end

function DeleteTool:OnPointerMove(target: TargetData)
	if target.IsProp and target.Instance then
		SelectionHighlighter.HighlightSelected(target.Instance, Color3.fromRGB(220, 50, 50))
	else
		SelectionHighlighter.Clear()
	end
end

function DeleteTool:OnActionTriggered()
	local target = TargetDetector.GetTarget()
	if not target.IsProp or not target.Instance then return end

	local part = target.Instance
	local cf = part.CFrame
	local sz = part.Size
	local shape = if part:IsA("Part") then part.Shape else nil

	-- red dissolution ghost
	GhostSilhouette.SpawnRedGhost(cf, sz, shape)
	SelectionHighlighter.Clear()

	self.ToolActionRemote:FireServer({
		Action = "Delete",
		Part = part,
	})
end

function DeleteTool:OnSecondaryTriggered()
	SelectionHighlighter.Clear()
end

return DeleteTool
