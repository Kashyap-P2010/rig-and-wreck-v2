--!strict

local SoundService = game:GetService("SoundService")

local SoundAssets = {}

SoundAssets.IDs = {

	Spawn = "rbxassetid://137935424222814",

	Weld = "rbxassetid://6215849605",

	RopeSnap = "rbxassetid://106499637668939",

	ThrusterLoop = "rbxassetid://77246158727159",

	Delete = "rbxassetid://127768050243969",

	ErrorBeep = "rbxassetid://119249141473632",

	Click = "rbxassetid://6215849605", -- click sound

}


function SoundAssets.Play(name: string, position: Vector3?, parent: Instance?): Sound?
	local assetId = SoundAssets.IDs[name]

	if not assetId or assetId == "rbxassetid://0" then

		return nil
	end

	local sound = Instance.new("Sound")

	sound.Name = "RigWreck_" .. name

	sound.SoundId = assetId

	sound.Volume = 0.5

	sound.RollOffMaxDistance = 120

	sound.RollOffMinDistance = 10

	sound.PlaybackSpeed = 1 + (math.random(-12, 12) / 100)

	if parent then

		sound.Parent = parent

	elseif position then

		local anchor = Instance.new("Part")

		anchor.Name = "SoundAnchor"

		anchor.Size = Vector3.new(0.1, 0.1, 0.1)

		anchor.Transparency = 1

		anchor.CanCollide = false

		anchor.CanTouch = false

		anchor.CanQuery = false

		anchor.Anchored = true

		anchor.Position = position

		anchor.Parent = workspace

		sound.Parent = anchor

		sound.Ended:Connect(function()

			anchor:Destroy()

		end)

	else

		sound.Parent = SoundService

	end

	sound:Play()

	if not position then

		sound.Ended:Connect(function()

			sound:Destroy()

		end)

	end


	return sound

end


function SoundAssets.CreateLooping(name: string, parent: Instance): Sound?
	local assetId = SoundAssets.IDs[name]

	if not assetId or assetId == "rbxassetid://0" then

		return nil
	end

	local sound = Instance.new("Sound")

	sound.Name = "RigWreck_Loop_" .. name

	sound.SoundId = assetId

	sound.Volume = 0.55

	sound.Looped = true

	sound.RollOffMaxDistance = 150

	sound.RollOffMinDistance = 10

	sound.Parent = parent


	return sound

end


return SoundAssets
