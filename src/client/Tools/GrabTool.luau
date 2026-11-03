--!strict

local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UserInputService = game:GetService("UserInputService")

local TweenService = game:GetService("TweenService")

local BaseTool = require(script.Parent.BaseTool)

local ToolConfigs = require(ReplicatedStorage.RigAndWreck.Config.ToolConfigs)

local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)

local SelectionHighlighter = { Clear = function() end, HighlightHover = function(...) end, HighlightSelected = function(...) end, UpdateInfo = function(...) end }

local TargetDetector = require(script.Parent.Parent.Core.TargetDetector)

type TargetData = TargetDetector.TargetData

local GrabTool = setmetatable({}, BaseTool)

GrabTool.__index = GrabTool

function GrabTool.new()
	local self = setmetatable(BaseTool.new("Grab"), GrabTool)
	self.HeldPart = nil :: BasePart?
	self.HoldDistance = 12
	self.TargetHoldDistance = 12
	self.AlignPos = nil :: AlignPosition?
	self.AlignOrient = nil :: AlignOrientation?
	self.PartAtt = nil :: Attachment?
	self.RenderConn = nil :: RBXScriptConnection?
	self.BaseCameraRotation = CFrame.identity
	self.YawOffset = 0
	self.PitchOffset = 0
	self.ToolActionRemote = RemoteDefinitions.GetEvent("ToolAction")

	return self
end


function GrabTool:Equip()
	BaseTool.Equip(self)
end


function GrabTool:Unequip()
	BaseTool.Unequip(self)
	self:Release()
	SelectionHighlighter.Clear()
end


function GrabTool:OnPointerMove(target: TargetData)

	if not self.HeldPart then

		if target.IsProp and target.Instance then
			SelectionHighlighter.HighlightHover(target.Instance)
		else
			SelectionHighlighter.HighlightHover(nil)
		end

	end

end


function GrabTool:AdjustDistance(delta: number)

	if self.HeldPart then
		self.TargetHoldDistance = math.clamp(self.TargetHoldDistance + delta, ToolConfigs.Grab.MinHoldDistance, ToolConfigs.Grab.MaxHoldDistance)
	end

end


function GrabTool:RotateHeld(axis: string?)

	if self.HeldPart then

		if axis == "Pitch" then
			self.PitchOffset = (self.PitchOffset + 45) % 360
		else
			self.YawOffset = (self.YawOffset + 45) % 360
		end

	end

end


function GrabTool:ToggleFreeze()

	if self.HeldPart then
		local part = self.HeldPart
		self:Release()
		part.Anchored = true
		part.AssemblyLinearVelocity = Vector3.zero
		part.AssemblyAngularVelocity = Vector3.zero
		self.ToolActionRemote:FireServer({
			Action = "Freeze",
			Part = part,
			Anchored = true,
		})
		SelectionHighlighter.HighlightSelected(part, Color3.fromRGB(80, 200, 255))
		SelectionHighlighter.UpdateInfo(part)
		-- ice flash
		task.spawn(function()
			local origColor = part.Color
			part.Color = Color3.fromRGB(160, 225, 255)
			task.wait(0.2)

			if part and part.Parent then
				part.Color = origColor
			end

		end)

	else

		local target = TargetDetector.GetTarget()

		if target.IsProp and target.Instance then

			local part = target.Instance

			local willAnchor = not part.Anchored

			part.Anchored = willAnchor

			if willAnchor then

				part.AssemblyLinearVelocity = Vector3.zero

				part.AssemblyAngularVelocity = Vector3.zero

			end

			self.ToolActionRemote:FireServer({

				Action = "Freeze",

				Part = part,

				Anchored = willAnchor,

			})

			SelectionHighlighter.HighlightSelected(part, if willAnchor then Color3.fromRGB(80, 200, 255) else Color3.fromRGB(245, 180, 45))

			SelectionHighlighter.UpdateInfo(part)

		end

	end

end

function GrabTool:Grab(part: BasePart)
	-- multi-prop grab
	local isShiftDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)

	if isShiftDown and part.AssemblyRootPart and part.AssemblyRootPart:IsA("BasePart") then
		part = part.AssemblyRootPart
	end

	-- unfreeze on grab

	if part.Anchored then

		part.Anchored = false

		self.ToolActionRemote:FireServer({

			Action = "Freeze",

			Part = part,

			Anchored = false,

		})

	end

	self.HeldPart = part

	local cam = workspace.CurrentCamera

	local mousePos = UserInputService:GetMouseLocation()

	local ray = cam:ViewportPointToRay(mousePos.X, mousePos.Y)

	local dist = (part.Position - ray.Origin):Dot(ray.Direction)

	self.HoldDistance = math.clamp(dist, ToolConfigs.Grab.MinHoldDistance, ToolConfigs.Grab.MaxHoldDistance)

	self.TargetHoldDistance = self.HoldDistance

	self.YawOffset = 0

	self.PitchOffset = 0

	self.BaseCameraRotation = cam.CFrame.Rotation:Inverse() * part.CFrame.Rotation

	part.AssemblyLinearVelocity = Vector3.zero

	part.AssemblyAngularVelocity = Vector3.zero

	self.ToolActionRemote:FireServer({

		Action = "GrabStart",

		Part = part,

	})

	SelectionHighlighter.HighlightSelected(part, Color3.fromRGB(45, 140, 245))

	local partAtt = Instance.new("Attachment")

	partAtt.Name = "RigWreck_GrabPartAtt"

	partAtt.Position = Vector3.zero

	partAtt.Parent = part

	self.PartAtt = partAtt

	local alignPos = Instance.new("AlignPosition")

	alignPos.Name = "RigWreck_AlignPos"

	alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment

	alignPos.Attachment0 = partAtt

	alignPos.Position = part.Position

	alignPos.MaxForce = 350000

	alignPos.Responsiveness = 45

	alignPos.MaxVelocity = 160

	alignPos.Parent = part

	self.AlignPos = alignPos

	local alignOrient = Instance.new("AlignOrientation")

	alignOrient.Name = "RigWreck_AlignOrient"

	alignOrient.Mode = Enum.OrientationAlignmentMode.OneAttachment

	alignOrient.Attachment0 = partAtt

	alignOrient.CFrame = part.CFrame.Rotation

	alignOrient.MaxTorque = 10000000

	alignOrient.Responsiveness = 40

	alignOrient.MaxAngularVelocity = 60

	alignOrient.Parent = part

	self.AlignOrient = alignOrient

	self.RenderConn = RunService.RenderStepped:Connect(function(dt: number)

		if not self.HeldPart or not self.HeldPart.Parent or not self.AlignPos or not self.AlignOrient then

			self:Release()

			return

		end

		-- smooth distance

		self.HoldDistance = self.HoldDistance + (self.TargetHoldDistance - self.HoldDistance) * math.clamp(dt * 16, 0, 1)

		local c = workspace.CurrentCamera

		local mPos = UserInputService:GetMouseLocation()

		local mRay = c:ViewportPointToRay(mPos.X, mPos.Y)

		local targetPos = mRay.Origin + mRay.Direction * self.HoldDistance

		self.AlignPos.Position = targetPos

		-- camera align snap

		local isAltDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)

		local rotCF: CFrame

		if isAltDown then

			rotCF = c.CFrame.Rotation

		else

			rotCF = c.CFrame.Rotation * self.BaseCameraRotation * CFrame.Angles(math.rad(self.PitchOffset), math.rad(self.YawOffset), 0)

		end

		self.AlignOrient.CFrame = rotCF

	end)

end

function GrabTool:Release()

	if self.RenderConn then
		self.RenderConn:Disconnect()
		self.RenderConn = nil
	end

	local part = self.HeldPart

	if self.AlignPos then self.AlignPos:Destroy(); self.AlignPos = nil end

	if self.AlignOrient then self.AlignOrient:Destroy(); self.AlignOrient = nil end

	if self.PartAtt then self.PartAtt:Destroy(); self.PartAtt = nil end

	self.HeldPart = nil

	SelectionHighlighter.HighlightSelected(nil)

	if part and part.Parent then

		self.ToolActionRemote:FireServer({

			Action = "GrabEnd",

			Part = part,

		})

	end

end


function GrabTool:Throw()
	local part = self.HeldPart

	if not part or not part.Parent then return end
	local cam = workspace.CurrentCamera
	local impulse = cam.CFrame.LookVector * (ToolConfigs.Grab.ThrowImpulseMultiplier * 1.5)
	self:Release()
	pcall(function()
		part:ApplyLinearImpulse(impulse * part.AssemblyMass)
	end)

	self.ToolActionRemote:FireServer({

		Action = "Throw",

		Part = part,

	})

end

function GrabTool:OnActionTriggered()

	if self.HeldPart then
		self:Release()
	else
		local target = TargetDetector.GetTarget()

		if target.IsProp and target.Instance then
			self:Grab(target.Instance)
		end

	end

end


function GrabTool:OnSecondaryTriggered()

	if self.HeldPart then
		self:Throw()
	end

end


return GrabTool
