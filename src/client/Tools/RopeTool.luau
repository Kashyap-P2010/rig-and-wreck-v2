--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseTool = require(script.Parent.BaseTool)

local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)

local SelectionHighlighter = require(script.Parent.Parent.Previews.SelectionHighlighter)

local TargetDetector = require(script.Parent.Parent.Core.TargetDetector)

type TargetData = TargetDetector.TargetData

local RopeTool = setmetatable({}, BaseTool)

RopeTool.__index = RopeTool

function RopeTool.new()
	local self = setmetatable(BaseTool.new("Rope"), RopeTool)
	self.FirstPart = nil :: BasePart?
	self.FirstLocalPos = nil :: Vector3?
	self.RopeLength = 12
	self.MinLength = 2
	self.MaxLength = 80
	self.GhostTarget = nil :: BasePart?
	self.Att0 = nil :: Attachment?
	self.Att1 = nil :: Attachment?
	self.PreviewBeam = nil :: Beam?
	self.Billboard = nil :: BillboardGui?
	self.LengthLabel = nil :: TextLabel?
	self.ToolActionRemote = RemoteDefinitions.GetEvent("ToolAction")

	return self
end

function RopeTool:UpdateGhostUI(currentDist: number?)

	if not self.LengthLabel then return end

	if currentDist then
		local taut = currentDist >= self.RopeLength
		local status = if taut then "[Taut / Stretched]" else "[Slack]"
		self.LengthLabel.Text = string.format("Rope: %d studs (Dist: %.1f) %s\n[Scroll: Adjust Length | RMB: Cancel]", self.RopeLength, currentDist, status)
		self.LengthLabel.TextColor3 = if taut then Color3.fromRGB(255, 170, 70) else Color3.fromRGB(240, 240, 240)
	else
		self.LengthLabel.Text = string.format("Rope Length: %d studs\n[Scroll: Adjust Length]", self.RopeLength)
		self.LengthLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	end

end

function RopeTool:ClearPreview()

	if self.PreviewBeam then self.PreviewBeam:Destroy(); self.PreviewBeam = nil end

	if self.Att0 then self.Att0:Destroy(); self.Att0 = nil end

	if self.Att1 then self.Att1:Destroy(); self.Att1 = nil end

	if self.Billboard then self.Billboard:Destroy(); self.Billboard = nil end
	self.LengthLabel = nil

	if self.GhostTarget then self.GhostTarget:Destroy(); self.GhostTarget = nil end
end

function RopeTool:SetLength(len: number)
	self.RopeLength = math.clamp(math.round(len), self.MinLength, self.MaxLength)

	if self.GhostTarget and self.FirstPart and self.FirstLocalPos then
		local worldA = self.FirstPart.CFrame:PointToWorldSpace(self.FirstLocalPos)
		local currentDist = (self.GhostTarget.Position - worldA).Magnitude
		self:UpdateGhostUI(currentDist)

		if self.PreviewBeam then
			local taut = currentDist >= self.RopeLength
			local c = if taut then Color3.fromRGB(255, 160, 60) else Color3.fromRGB(240, 220, 160)
			self.PreviewBeam.Color = ColorSequence.new(c)
		end

	end

end

function RopeTool:AdjustDistance(delta: number)
	local step = math.sign(delta) * (if math.abs(delta) >= 2 then 2 else 1)
	self:SetLength(self.RopeLength + step)
end


function RopeTool:Unequip()
	BaseTool.Unequip(self)
	self.FirstPart = nil
	self.FirstLocalPos = nil
	self:ClearPreview()
	SelectionHighlighter.Clear()
end


function RopeTool:OnPointerMove(target: TargetData)

	if self.GhostTarget and self.FirstPart and self.FirstLocalPos then
		self.GhostTarget.Position = target.Position
		local worldA = self.FirstPart.CFrame:PointToWorldSpace(self.FirstLocalPos)
		local currentDist = (target.Position - worldA).Magnitude
		self:UpdateGhostUI(currentDist)

		if self.PreviewBeam then
			local taut = currentDist >= self.RopeLength
			local c = if taut then Color3.fromRGB(255, 160, 60) else Color3.fromRGB(240, 220, 160)
			self.PreviewBeam.Color = ColorSequence.new(c)
		end

	end

	if target.IsProp and target.Instance then

		if target.Instance ~= self.FirstPart then

			SelectionHighlighter.HighlightHover(target.Instance)

		end

	else

		SelectionHighlighter.HighlightHover(nil)

	end

end


function RopeTool:OnActionTriggered()
	local target = TargetDetector.GetTarget()

	if not target.IsProp or not target.Instance then return end

	if not self.FirstPart then
		-- first click: attach start
		self.FirstPart = target.Instance
		self.FirstLocalPos = target.Instance.CFrame:PointToObjectSpace(target.Position)
		SelectionHighlighter.HighlightSelected(target.Instance, Color3.fromRGB(255, 200, 60))
		self:ClearPreview()
		-- ghost target at mouse
		local ghost = Instance.new("Part")
		ghost.Name = "RigWreck_RopeGhost"
		ghost.Size = Vector3.new(0.2, 0.2, 0.2)
		ghost.Transparency = 1
		ghost.CanCollide = false
		ghost.CanTouch = false
		ghost.CanQuery = false
		ghost.Anchored = true
		ghost.Position = target.Position
		ghost.Parent = workspace
		self.GhostTarget = ghost
		local att0 = Instance.new("Attachment")
		att0.Name = "RopePreviewAtt0"
		att0.Position = self.FirstLocalPos
		att0.Parent = target.Instance
		self.Att0 = att0
		local att1 = Instance.new("Attachment")
		att1.Name = "RopePreviewAtt1"
		att1.Position = Vector3.zero
		att1.Parent = ghost
		self.Att1 = att1
		local beam = Instance.new("Beam")
		beam.Name = "RopePreviewBeam"
		beam.Attachment0 = att0
		beam.Attachment1 = att1
		beam.Color = ColorSequence.new(Color3.fromRGB(240, 220, 160))
		beam.Width0 = 0.16
		beam.Width1 = 0.16
		beam.FaceCamera = true
		beam.Transparency = NumberSequence.new(0.25)
		beam.Parent = target.Instance
		self.PreviewBeam = beam
		-- distance label
		local bb = Instance.new("BillboardGui")
		bb.Name = "RopePreviewBillboard"
		bb.Size = UDim2.new(0, 240, 0, 44)
		bb.StudsOffset = Vector3.new(0, 1.8, 0)
		bb.AlwaysOnTop = true
		bb.Adornee = ghost
		bb.Parent = ghost
		self.Billboard = bb
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
		frame.BackgroundTransparency = 0.2
		frame.BorderSizePixel = 0
		frame.Parent = bb
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 200, 60)
		stroke.Thickness = 1.2
		stroke.Parent = frame
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = frame
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -12, 1, -8)
		label.Position = UDim2.new(0, 6, 0, 4)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextSize = 11
		label.TextColor3 = Color3.fromRGB(240, 240, 240)
		label.TextWrapped = true
		label.Parent = frame
		self.LengthLabel = label
		self:UpdateGhostUI(0)
	else
		-- second click: attach end
		local secondPart = target.Instance

		if secondPart ~= self.FirstPart and self.FirstPart and self.FirstPart.Parent and self.FirstLocalPos then
			local worldPosA = self.FirstPart.CFrame:PointToWorldSpace(self.FirstLocalPos)
			local worldPosB = target.Position
			local dist = (worldPosA - worldPosB).Magnitude
			local finalLen = math.max(dist, self.RopeLength)
			self.ToolActionRemote:FireServer({
				Action = "Rope",
				PartA = self.FirstPart,
				PartB = secondPart,
				PosA = worldPosA,
				PosB = worldPosB,
				Length = finalLen,
			})
		end

		self.FirstPart = nil

		self.FirstLocalPos = nil

		self:ClearPreview()

		SelectionHighlighter.Clear()

	end

end


function RopeTool:OnSecondaryTriggered()
	self.FirstPart = nil
	self.FirstLocalPos = nil
	self:ClearPreview()
	SelectionHighlighter.Clear()
end

return RopeTool
