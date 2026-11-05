--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseTool = require(script.Parent.BaseTool)

local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)

local SelectionHighlighter = require(script.Parent.Parent.Previews.SelectionHighlighter)

local TargetDetector = require(script.Parent.Parent.Core.TargetDetector)

local UIComponents = { ShowToast = function(...) end }

type TargetData = TargetDetector.TargetData

local WeldTool = setmetatable({}, BaseTool)

WeldTool.__index = WeldTool


function WeldTool.new()
	local self = setmetatable(BaseTool.new("Weld"), WeldTool)
	self.FirstPart = nil :: BasePart?
	self.Att0 = nil :: Attachment?
	self.Att1 = nil :: Attachment?
	self.GhostTarget = nil :: BasePart?
	self.PreviewBeam = nil :: Beam?
	self.ToolActionRemote = RemoteDefinitions.GetEvent("ToolAction")

	return self
end


function WeldTool:ClearPreview()

	if self.PreviewBeam then self.PreviewBeam:Destroy(); self.PreviewBeam = nil end

	if self.Att0 then self.Att0:Destroy(); self.Att0 = nil end

	if self.Att1 then self.Att1:Destroy(); self.Att1 = nil end

	if self.GhostTarget then self.GhostTarget:Destroy(); self.GhostTarget = nil end
end

function WeldTool:Unequip()
	BaseTool.Unequip(self)
	self.FirstPart = nil
	self:ClearPreview()
	SelectionHighlighter.Clear()
end


function WeldTool:OnPointerMove(target: TargetData)

	if self.GhostTarget then
		self.GhostTarget.Position = target.Position
	end

	if target.IsProp and target.Instance then

		if target.Instance ~= self.FirstPart then

			SelectionHighlighter.HighlightHover(target.Instance)

		end

	else

		SelectionHighlighter.HighlightHover(nil)

	end

end


function WeldTool:OnActionTriggered()
	local target = TargetDetector.GetTarget()

	if not target.IsProp or not target.Instance then return end

	if not self.FirstPart then
		-- select first part
		self.FirstPart = target.Instance
		SelectionHighlighter.HighlightSelected(target.Instance, Color3.fromRGB(0, 180, 255))
		-- preview beam
		self:ClearPreview()
		local ghost = Instance.new("Part")
		ghost.Name = "RigWreck_WeldGhost"
		ghost.Size = Vector3.new(0.1, 0.1, 0.1)
		ghost.Transparency = 1
		ghost.CanCollide = false
		ghost.CanTouch = false
		ghost.CanQuery = false
		ghost.Anchored = true
		ghost.Position = target.Position
		ghost.Parent = workspace
		self.GhostTarget = ghost
		local att0 = Instance.new("Attachment")
		att0.Name = "WeldPreviewAtt0"
		att0.Position = target.Instance.CFrame:PointToObjectSpace(target.Position)
		att0.Parent = target.Instance
		self.Att0 = att0
		local att1 = Instance.new("Attachment")
		att1.Name = "WeldPreviewAtt1"
		att1.Position = Vector3.zero
		att1.Parent = ghost
		self.Att1 = att1
		local beam = Instance.new("Beam")
		beam.Name = "WeldPreviewBeam"
		beam.Attachment0 = att0
		beam.Attachment1 = att1
		beam.Color = ColorSequence.new(Color3.fromRGB(0, 180, 255))
		beam.Width0 = 0.12
		beam.Width1 = 0.12
		beam.FaceCamera = true
		beam.Transparency = NumberSequence.new(0.3)
		beam.Parent = target.Instance
		self.PreviewBeam = beam
	else
		-- select second part
		local secondPart = target.Instance

		if secondPart ~= self.FirstPart then
			self.ToolActionRemote:FireServer({
				Action = "Weld",
				PartA = self.FirstPart,
				PartB = secondPart,
			})
			UIComponents.ShowToast("Welded props together", Color3.fromRGB(0, 180, 255))
		end

		self.FirstPart = nil

		self:ClearPreview()

		SelectionHighlighter.Clear()

	end

end


function WeldTool:OnSecondaryTriggered()

	if self.FirstPart then
		self.FirstPart = nil
		self:ClearPreview()
		SelectionHighlighter.Clear()
	else
		-- right click unweld
		local target = TargetDetector.GetTarget()

		if target.IsProp and target.Instance then
			self.ToolActionRemote:FireServer({
				Action = "Unweld",
				Part = target.Instance,
			})
			UIComponents.ShowToast("Unwelded all joints from prop", Color3.fromRGB(240, 140, 40))
		end

	end

end


function WeldTool:UnweldHovered()
	local target = TargetDetector.GetTarget()

	if target.IsProp and target.Instance then
		self.ToolActionRemote:FireServer({
			Action = "Unweld",
			Part = target.Instance,
		})
		UIComponents.ShowToast("Unwelded joints from target", Color3.fromRGB(240, 140, 40))
	else
		UIComponents.ShowToast("Aim at a prop first to unweld", Color3.fromRGB(220, 80, 80))
	end

end

function WeldTool:UnweldAll()
	self.ToolActionRemote:FireServer({
		Action = "UnweldAll",
	})
	UIComponents.ShowToast("Broke all your welds", Color3.fromRGB(240, 80, 40))
end


return WeldTool
