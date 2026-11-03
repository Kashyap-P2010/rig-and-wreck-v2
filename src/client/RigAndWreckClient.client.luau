--!strict

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)

local SoundAssets = require(ReplicatedStorage.RigAndWreck.Config.SoundAssets)

local ToolManager = require(script.Parent.Core.ToolManager)

local InputManager = require(script.Parent.Core.InputManager)

local playSoundRemote = RemoteDefinitions.GetEvent("PlaySoundEffect")

ToolManager.Init()

InputManager.Init()

playSoundRemote.OnClientEvent:Connect(function(soundName: string, position: Vector3?)

	SoundAssets.Play(soundName, position)

end)

print("[Rig & Wreck] Client initialized successfully.")
