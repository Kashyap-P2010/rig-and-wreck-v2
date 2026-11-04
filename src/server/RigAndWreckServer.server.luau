--!strict

-- server init

local ServerDispatcher = require(script.Parent.Network.ServerDispatcher)

local WorldBoundaryCleaner = require(script.Parent.Core.WorldBoundaryCleaner)

ServerDispatcher.Start()

WorldBoundaryCleaner.Start()

print("[Rig & Wreck] Server initialized successfully.")
