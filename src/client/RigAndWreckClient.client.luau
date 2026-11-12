--!strict

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

local playerGui = localPlayer:WaitForChild("PlayerGui")

local screenGui = playerGui:WaitForChild("RigAndWreckGui") :: ScreenGui

local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)

local SoundAssets = require(ReplicatedStorage.RigAndWreck.Config.SoundAssets)

-- client systems

local ToolManager = require(script.Parent.Core.ToolManager)

local InputManager = require(script.Parent.Core.InputManager)

local HotbarView = require(script.Parent.UI.HotbarView)

local ToolInspectorView = require(script.Parent.UI.ToolInspectorView)

-- remotes

local undoActionRemote = RemoteDefinitions.GetEvent("UndoAction")

local updateSettingsRemote = RemoteDefinitions.GetEvent("UpdateSettings")

local playSoundRemote = RemoteDefinitions.GetEvent("PlaySoundEffect")

local saveBuildFunc = RemoteDefinitions.GetFunction("SaveBuild")

local loadBuildFunc = RemoteDefinitions.GetFunction("LoadBuild")

-- init ui

ToolInspectorView.Init(screenGui)

HotbarView.Init(

	screenGui,

	function(toolIndex)
		ToolManager.SelectTool(toolIndex)
	end,

	function()
	end,

	function()
		undoActionRemote:FireServer({ Redo = false })
	end,

	function()
		undoActionRemote:FireServer({ Redo = true })
	end

)

ToolManager.Init()

InputManager.Init()

-- sfx listener

playSoundRemote.OnClientEvent:Connect(function(soundName: string, position: Vector3?)

	SoundAssets.Play(soundName, position)

end)

-- collision sparks and sound

local CollisionFX = require(ReplicatedStorage.RigAndWreck.Utilities.CollisionFX)

local function hookPropCollision(prop: Instance)

	if not prop:IsA("BasePart") then return end
	local lastHit = 0
	prop.Touched:Connect(function(other)

		if not other or not other:IsA("BasePart") then return end
		local now = os.clock()

		if now - lastHit < 0.18 then return end
		local relVel = (prop.AssemblyLinearVelocity - other.AssemblyLinearVelocity).Magnitude

		if relVel > 15 then
			lastHit = now
			local contactPos = (prop.Position + other.Position) * 0.5
			local normal = (prop.Position - other.Position).Unit
			CollisionFX.EmitSparks(contactPos, normal, math.clamp(math.floor(relVel * 0.55), 14, 30))
			CollisionFX.PlayImpactSound(contactPos, relVel)
		end

	end)

end

local propsFolder = workspace:FindFirstChild("RigAndWreckProps")

if propsFolder then

	for _, child in ipairs(propsFolder:GetChildren()) do

		hookPropCollision(child)

	end

	propsFolder.ChildAdded:Connect(hookPropCollision)

else

	workspace.ChildAdded:Connect(function(child)

		if child.Name == "RigAndWreckProps" then

			for _, p in ipairs(child:GetChildren()) do

				hookPropCollision(p)

			end

			child.ChildAdded:Connect(hookPropCollision)

		end

	end)

end

print("[Rig & Wreck] Client initialized successfully.")
