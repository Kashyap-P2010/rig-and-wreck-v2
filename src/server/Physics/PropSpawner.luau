--!strict

local Workspace = game:GetService("Workspace")

local PropSpawner = {}

local propsFolder: Folder? = nil

local function getPropsFolder(): Folder

    if not propsFolder or not propsFolder.Parent then
        local f = Workspace:FindFirstChild("RigAndWreckProps")

        if not f then
            f = Instance.new("Folder")
            f.Name = "RigAndWreckProps"
            f.Parent = Workspace
        end

        propsFolder = f :: Folder

    end

    return propsFolder :: Folder

end

function PropSpawner.SpawnProp(player: Player, propType: string, cframe: CFrame, customSize: Vector3?, customColor: Color3?, customMaterial: Enum.Material?): BasePart?
    local part = Instance.new("Part")
    part.Name = "RigWreck_" .. propType
    part.Size = customSize or Vector3.new(4, 2, 4)
    part.CFrame = cframe
    part.Color = customColor or Color3.fromRGB(180, 180, 190)
    part.Material = customMaterial or Enum.Material.Plastic
    part.Parent = getPropsFolder()

    return part
end

return PropSpawner
