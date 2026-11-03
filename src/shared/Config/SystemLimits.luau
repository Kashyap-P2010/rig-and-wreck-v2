--!strict

local SystemLimits = {}

SystemLimits.MaxPropsPerPlayer = 50

SystemLimits.MaxConstraintsPerPlayer = 100

SystemLimits.MaxUndoDepth = 30

SystemLimits.RateLimitActionsPerSecond = 20

SystemLimits.RateLimitBurstCapacity = 35

SystemLimits.MaxPropDimension = 35

SystemLimits.MinPropDimension = 0.2

SystemLimits.MaxAssemblyVelocity = 140

SystemLimits.MaxAssemblyAngularVelocity = 35

SystemLimits.MaxSaveSlots = 3

SystemLimits.WorldYBoundary = -100 -- cleanup threshold below world


return SystemLimits
