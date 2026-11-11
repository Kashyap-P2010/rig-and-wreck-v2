--!strict

local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseTool = require(script.Parent.BaseTool)

local ToolConfigs = require(ReplicatedStorage.RigAndWreck.Config.ToolConfigs)

local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)

local SelectionHighlighter = require(script.Parent.Parent.Previews.SelectionHighlighter)

local TargetDetector = require(script.Parent.Parent.Core.TargetDetector)

type TargetData = TargetDetector.TargetData

local BalloonTool = setmetatable({}, BaseTool)

BalloonTool.__index = BalloonTool


function BalloonTool.new()
	local self = setmetatable(BaseTool.new("Balloon"), BalloonTool)
	self.LiftForce = ToolConfigs.Balloon.DefaultLiftForce or 3500
	self.BalloonColor = ToolConfigs.Balloon.Colors[1] or Color3.fromRGB(240, 50, 50)
	self.GhostBalloon = nil :: BasePart?
	self.GhostLine = nil :: Beam?
	self.Att0 = nil :: Attachment?
	self.Att1 = nil :: Attachment?
	self.ToolActionRemote = RemoteDefinitions.GetEvent("ToolAction")

	return self
end

function BalloonTool:ClearGhost()

	if self.GhostBalloon then self.GhostBalloon:Destroy(); self.GhostBalloon = nil end

	if self.GhostLine then self.GhostLine:Destroy(); self.GhostLine = nil end

	if self.Att0 then self.Att0:Destroy(); self.Att0 = nil end

	if self.Att1 then self.Att1:Destroy(); self.Att1 = nil end
end


function BalloonTool:SetLiftForce(force: number)
	self.LiftForce = math.clamp(force, ToolConfigs.Balloon.MinLiftForce, ToolConfigs.Balloon.MaxLiftForce)
end


function BalloonTool:SetColor(color: Color3)
	self.BalloonColor = color

	if self.GhostBalloon then
		self.GhostBalloon.Color = color
	end

end

function BalloonTool:Unequip()
	BaseTool.Unequip(self)
	self:ClearGhost()
	SelectionHighlighter.Clear()
end

function BalloonTool:OnPointerMove(target: TargetData)

	if target.IsProp and target.Instance then
		SelectionHighlighter.HighlightHover(target.Instance)
		-- ghost preview

		if not self.GhostBalloon then
			local b = Instance.new("Part")
			b.Name = "RigWreck_GhostBalloon"
			b.Shape = Enum.PartType.Ball
			b.Size = Vector3.new(2.4, 3.0, 2.4)
			b.Transparency = 0.45
			b.Color = self.BalloonColor
			b.Material = Enum.Material.Neon
			b.CanCollide = false
			b.CanTouch = false
			b.CanQuery = false
			b.Anchored = true
			b.Parent = Workspace
			self.GhostBalloon = b
			local att0 = Instance.new("Attachment")
			att0.Position = Vector3.new(0, -1.3, 0)
			att0.Parent = b
			self.Att0 = att0
			local anchor = Instance.new("Part")
			anchor.Name = "RigWreck_GhostAnchor"
			anchor.Size = Vector3.new(0.1, 0.1, 0.1)
			anchor.Transparency = 1
			anchor.CanCollide = false
			anchor.CanTouch = false
			anchor.CanQuery = false
			anchor.Anchored = true
			anchor.Parent = Workspace
			local att1 = Instance.new("Attachment")
			att1.Parent = anchor
			self.Att1 = att1
			local beam = Instance.new("Beam")
			beam.Attachment0 = att0
			beam.Attachment1 = att1
			beam.Color = ColorSequence.new(Color3.fromRGB(240, 240, 240))
			beam.Width0 = 0.1
			beam.Width1 = 0.1
			beam.Transparency = NumberSequence.new(0.3)
			beam.Parent = b
			self.GhostLine = beam
		end

		if self.GhostBalloon and self.Att1 and self.Att1.Parent then

			local anchor = self.Att1.Parent :: BasePart

			anchor.Position = target.Position

			self.GhostBalloon.Position = target.Position + Vector3.new(0, 6.5, 0)

			self.GhostBalloon.Color = self.BalloonColor

		end

	else

		SelectionHighlighter.HighlightHover(nil)

		self:ClearGhost()

	end

end


function BalloonTool:OnActionTriggered()
	local target = TargetDetector.GetTarget()

	if not target.IsProp or not target.Instance then return end
	-- pop existing balloon

	if target.Instance:GetAttribute("IsBalloon") then
		self.ToolActionRemote:FireServer({
			Action = "PopBalloon",
			BalloonPart = target.Instance,
		})
		self:ClearGhost()
		return
	end

	-- attach balloon

	self.ToolActionRemote:FireServer({

		Action = "CreateBalloon",

		TargetPart = target.Instance,

		HitPosition = target.Position,

		LiftForce = self.LiftForce,

		Color = self.BalloonColor,

	})

end

function BalloonTool:OnSecondaryTriggered()
	-- cycle color
	local colors = ToolConfigs.Balloon.Colors
	local nextIdx = 1

	for idx, col in ipairs(colors) do

		if col == self.BalloonColor then
			nextIdx = (idx % #colors) + 1
			break
		end

	end

	self:SetColor(colors[nextIdx])

end

return BalloonTool
