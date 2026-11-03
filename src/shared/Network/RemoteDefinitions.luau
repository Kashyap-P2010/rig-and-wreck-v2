--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteDefinitions = {}

local remotesFolder = ReplicatedStorage:WaitForChild("RigAndWreckRemotes")


function RemoteDefinitions.GetEvent(name: string): RemoteEvent
	local remote = remotesFolder:WaitForChild(name, 5)

	if not remote or not remote:IsA("RemoteEvent") then
		error("RemoteEvent not found in RigAndWreckRemotes: " .. tostring(name))
	end

	return remote

end

function RemoteDefinitions.GetFunction(name: string): RemoteFunction
	local remote = remotesFolder:WaitForChild(name, 5)

	if not remote or not remote:IsA("RemoteFunction") then
		error("RemoteFunction not found in RigAndWreckRemotes: " .. tostring(name))
	end


	return remote

end


return RemoteDefinitions
