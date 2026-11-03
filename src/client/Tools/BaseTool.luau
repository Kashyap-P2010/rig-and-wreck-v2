--!strict

local TargetDetector = require(script.Parent.Parent.Core.TargetDetector)

type TargetData = TargetDetector.TargetData

local BaseTool = {}
BaseTool.__index = BaseTool

function BaseTool.new(name: string)
	local self = setmetatable({
		Name = name,
		IsEquipped = false,
	}, BaseTool)

	return self
end

function BaseTool:Equip()
	self.IsEquipped = true
end

function BaseTool:Unequip()
	self.IsEquipped = false
end

function BaseTool:OnPointerMove(target: TargetData)
	-- no-op default for passive tools
end

function BaseTool:OnActionTriggered()
	-- primary tool click handler
end

function BaseTool:OnSecondaryTriggered()
	-- secondary tool click / reset
end

function BaseTool:Destroy()
	self:Unequip()
end

return BaseTool
