--!strict

local ToolConfigs = {}

ToolConfigs.InteractionRange = 85

ToolConfigs.Grab = {

	DefaultHoldDistance = 12,

	MinHoldDistance = 3,

	MaxHoldDistance = 45,

	AlignMaxForce = 45000,

	AlignResponsiveness = 32,

	AlignMaxVelocity = 60,

	ThrowImpulseMultiplier = 40,

	MaxThrowImpulse = 110,

	MaxAllowedVelocity = 120,

}

ToolConfigs.Weld = {

	HighlightColorA = Color3.fromRGB(50, 160, 255),

	HighlightColorB = Color3.fromRGB(80, 220, 100),

	BreakForceThreshold = 85000,

}

ToolConfigs.Rope = {

	DefaultLength = 10,

	MinLength = 1,

	MaxLength = 80,

	Thickness = 0.16,

	Color = Color3.fromRGB(235, 235, 240),

}

ToolConfigs.Hinge = {

	DefaultLimitsEnabled = false,

	DefaultLowerAngle = -90,

	DefaultUpperAngle = 90,

	Restitution = 0.1,

}

ToolConfigs.Motor = {

	DefaultSpeed = 16,

	MinSpeed = -80,

	MaxSpeed = 80,

	DefaultTorque = 12000,

	MaxTorque = 100000,

	DefaultKeyForward = Enum.KeyCode.W,

	DefaultKeyReverse = Enum.KeyCode.S,

}

ToolConfigs.Thruster = {

	DefaultForce = 14000,

	MinForce = 1000,

	MaxForce = 80000,

	DefaultKey = Enum.KeyCode.LeftShift,

}

ToolConfigs.Transform = {

	SnapIncrements = { 0.5, 1, 2, 4 },

	RotateIncrements = { 15, 45, 90 },

	DefaultSnap = 1,

	DefaultRotateSnap = 45,

}

ToolConfigs.Paint = {

	Palette = {

		Color3.fromRGB(240, 240, 240),

		Color3.fromRGB(160, 160, 165),

		Color3.fromRGB(50, 50, 55),

		Color3.fromRGB(235, 65, 65),

		Color3.fromRGB(245, 140, 40),

		Color3.fromRGB(250, 215, 50),

		Color3.fromRGB(60, 195, 80),

		Color3.fromRGB(45, 160, 245),

		Color3.fromRGB(150, 75, 230),

		Color3.fromRGB(235, 90, 170),

		Color3.fromRGB(150, 95, 55),

		Color3.fromRGB(90, 60, 35),

	},

	Materials = {

		Enum.Material.SmoothPlastic,

		Enum.Material.Wood,

		Enum.Material.WoodPlanks,

		Enum.Material.Metal,

		Enum.Material.CorrodedMetal,

		Enum.Material.Concrete,

		Enum.Material.Neon,

		Enum.Material.Glass,

		Enum.Material.Grass,

		Enum.Material.Foil,

	},

}

ToolConfigs.Balloon = {

	DefaultLiftForce = 3500,

	MinLiftForce = 1000,

	MaxLiftForce = 12000,

	RopeLength = 5,

	Colors = {

		Color3.fromRGB(240, 50, 50),

		Color3.fromRGB(250, 180, 30),

		Color3.fromRGB(60, 200, 60),

		Color3.fromRGB(40, 160, 250),

		Color3.fromRGB(180, 50, 230),

		Color3.fromRGB(240, 70, 170),

	},

}

ToolConfigs.Magnet = {

	DefaultForce = 35000,

	MaxDistance = 45,

	NorthColor = Color3.fromRGB(240, 50, 50), -- north pole red

	SouthColor = Color3.fromRGB(45, 140, 255), -- south pole blue

	AttractBeamColor = Color3.fromRGB(175, 75, 255), -- attract beam violet

	RepelBeamColor = Color3.fromRGB(255, 110, 40), -- repel beam orange

}

ToolConfigs.WeightPresets = {

	{ name = "Feather", density = 0.05, friction = 0.5, elasticity = 0.5 },

	{ name = "Wood", density = 0.7, friction = 0.6, elasticity = 0.2 },

	{ name = "Steel", density = 2.5, friction = 0.5, elasticity = 0.1 },

	{ name = "Anvil", density = 10.0, friction = 1.0, elasticity = 0.05 },

}

ToolConfigs.SlowMotion = {

	TimeScale = 0.3,

}

return ToolConfigs
