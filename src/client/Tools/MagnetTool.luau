--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseTool = require(script.Parent.BaseTool)

local ToolConfigs = require(ReplicatedStorage.RigAndWreck.Config.ToolConfigs)

local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)

local SelectionHighlighter = require(script.Parent.Parent.Previews.SelectionHighlighter)

local TargetDetector = require(script.Parent.Parent.Core.TargetDetector)

local UIComponents = require(script.Parent.Parent.UI.UIComponents)

type TargetData = TargetDetector.TargetData

local MagnetTool = setmetatable({}, BaseTool)

MagnetTool.__index = MagnetTool


function MagnetTool.new()
	local self = setmetatable(BaseTool.new("Magnet"), MagnetTool)
	self.Polarity = "North" -- north (red) or south (blue)
	self.Strength = ToolConfigs.Magnet.DefaultForce or 35000
	self.ToolActionRemote = RemoteDefinitions.GetEvent("ToolAction")

	return self
end

function MagnetTool:SetPolarity(pol: string)

	if pol == "North" or pol == "South" then
		self.Polarity = pol
	end

end

function MagnetTool:TogglePolarity()
	self.Polarity = if self.Polarity == "North" then "South" else "North"
end

function MagnetTool:SetStrength(s: number)
	self.Strength = math.clamp(s, 5000, 80000)
end

function MagnetTool:Unequip()
	BaseTool.Unequip(self)
	SelectionHighlighter.Clear()
end


function MagnetTool:OnPointerMove(target: TargetData)

	if target.IsProp and target.Instance then
		local highlightColor = if self.Polarity == "North"
			then ToolConfigs.Magnet.NorthColor
			else ToolConfigs.Magnet.SouthColor
		SelectionHighlighter.HighlightHover(target.Instance, highlightColor)
	else
		SelectionHighlighter.HighlightHover(nil)
	end

end

function MagnetTool:OnActionTriggered()
	local target = TargetDetector.GetTarget()

	if not target.IsProp or not target.Instance then
		UIComponents.ShowToast("Aim at a prop (press [Q] to spawn one)!", Color3.fromRGB(240, 180, 50))
		return
	end

	local targetPart = target.Instance

	local existingPolarity = targetPart:GetAttribute("MagnetPolarity")

	local toastColor = if self.Polarity == "North" then ToolConfigs.Magnet.NorthColor else ToolConfigs.Magnet.SouthColor

	if existingPolarity == self.Polarity then

		self.ToolActionRemote:FireServer({

			Action = "RemoveMagnet",

			Part = targetPart,

		})

		UIComponents.ShowToast("Magnet detached.", Color3.fromRGB(180, 180, 190))

	else

		-- count nearby magnets

		local otherNearby = 0

		local maxDist = ToolConfigs.Magnet.MaxDistance or 45

		for _, inst in ipairs(workspace:GetDescendants()) do

			if inst:IsA("BasePart") and inst ~= targetPart and inst:GetAttribute("MagnetPolarity") ~= nil then

				local d = (inst.Position - targetPart.Position).Magnitude

				if d <= maxDist then

					otherNearby += 1

				end

			end

		end

		self.ToolActionRemote:FireServer({

			Action = "SetMagnet",

			Part = targetPart,

			Polarity = self.Polarity,

			Strength = self.Strength,

		})

		if otherNearby == 0 then

			local opposite = if self.Polarity == "North" then "South" else "North"

			UIComponents.ShowToast(string.format("%s Pole attached! Click a 2nd prop with %s to attract.", self.Polarity, opposite), toastColor)

		else

			UIComponents.ShowToast(string.format("%s Pole placed! Magnetic interaction active.", self.Polarity), toastColor)

		end

	end

end

function MagnetTool:OnSecondaryTriggered()
	self:TogglePolarity()
	local toastColor = if self.Polarity == "North" then ToolConfigs.Magnet.NorthColor else ToolConfigs.Magnet.SouthColor
	UIComponents.ShowToast(string.format("Selected: %s Pole", string.upper(self.Polarity)), toastColor)
	local target = TargetDetector.GetTarget()

	if target.IsProp and target.Instance then
		SelectionHighlighter.HighlightHover(target.Instance, toastColor)
	end

end

return MagnetTool
