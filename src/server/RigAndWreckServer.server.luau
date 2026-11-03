--!strict

local Workspace = game:GetService("Workspace")

local propsFolder = Workspace:FindFirstChild("RigAndWreckProps")

if not propsFolder then

    propsFolder = Instance.new("Folder")

    propsFolder.Name = "RigAndWreckProps"

    propsFolder.Parent = Workspace

end

print("[Rig & Wreck] Server initialized.")
