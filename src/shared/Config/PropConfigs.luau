--!strict

local SystemTypes = require(script.Parent.Parent.Types.SystemTypes)

type PropConfig = SystemTypes.PropConfig

type PropType = SystemTypes.PropType

local PropConfigs = {}

local DEFINITIONS: { [PropType]: PropConfig } = {

	Plank = {

		name = "Plank",

		partType = "Block",

		defaultSize = Vector3.new(1, 8, 2),

		minSize = Vector3.new(0.5, 2, 0.5),

		maxSize = Vector3.new(4, 30, 8),

		material = Enum.Material.WoodPlanks,

		color = Color3.fromRGB(150, 105, 65),

		density = 0.6,

		friction = 0.7,

		elasticity = 0.1,

	},

	Ball = {

		name = "Ball",

		partType = "Ball",

		defaultSize = Vector3.new(3, 3, 3),

		minSize = Vector3.new(1, 1, 1),

		maxSize = Vector3.new(16, 16, 16),

		material = Enum.Material.SmoothPlastic,

		color = Color3.fromRGB(220, 60, 60),

		density = 1.0,

		friction = 0.4,

		elasticity = 0.8,

	},

	Crate = {

		name = "Crate",

		partType = "Block",

		defaultSize = Vector3.new(3, 3, 3),

		minSize = Vector3.new(1, 1, 1),

		maxSize = Vector3.new(16, 16, 16),

		material = Enum.Material.Wood,

		color = Color3.fromRGB(180, 130, 75),

		density = 0.7,

		friction = 0.6,

		elasticity = 0.2,

	},

	Cylinder = {

		name = "Cylinder",

		partType = "Cylinder",

		defaultSize = Vector3.new(4, 2, 2),

		minSize = Vector3.new(1, 1, 1),

		maxSize = Vector3.new(20, 10, 10),

		material = Enum.Material.Metal,

		color = Color3.fromRGB(140, 145, 150),

		density = 1.4,

		friction = 0.5,

		elasticity = 0.2,

	},

	Wedge = {

		name = "Wedge",

		partType = "Wedge",

		defaultSize = Vector3.new(3, 3, 3),

		minSize = Vector3.new(1, 1, 1),

		maxSize = Vector3.new(16, 16, 16),

		material = Enum.Material.Concrete,

		color = Color3.fromRGB(130, 130, 135),

		density = 1.8,

		friction = 0.8,

		elasticity = 0.1,

	},

	Cash = {

		name = "Cash",

		partType = "Block",

		defaultSize = Vector3.new(0.4, 2, 1),

		minSize = Vector3.new(0.2, 1, 0.5),

		maxSize = Vector3.new(2, 10, 5),

		material = Enum.Material.Foil,

		color = Color3.fromRGB(45, 140, 60),

		density = 0.4,

		friction = 0.6,

		elasticity = 0.1,

	},

	TNT = {

		name = "TNT",

		partType = "Block",

		defaultSize = Vector3.new(2.5, 2.5, 2.5),

		minSize = Vector3.new(1, 1, 1),

		maxSize = Vector3.new(10, 10, 10),

		material = Enum.Material.Concrete,

		color = Color3.fromRGB(225, 45, 40),

		density = 1.0,

		friction = 0.7,

		elasticity = 0.2,

	},

}

function PropConfigs.Get(propType: PropType): PropConfig?

	return DEFINITIONS[propType]
end


function PropConfigs.List(): { PropConfig }
	local list = {}

	for _, propType in ipairs({ "Plank", "Ball", "Crate", "Cylinder", "Wedge", "Cash", "TNT" }) do
		table.insert(list, DEFINITIONS[propType :: PropType])
	end

	return list

end

return PropConfigs
