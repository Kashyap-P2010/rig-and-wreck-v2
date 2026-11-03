--!strict

local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PropConfigs = require(ReplicatedStorage.RigAndWreck.Config.PropConfigs)

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
    local config = PropConfigs.Get(propType :: any)

    if not config then return nil end
    local part = Instance.new("Part")
    part.Name = "RigWreck_" .. propType
    part.Size = customSize or config.defaultSize
    part.CFrame = cframe
    part.Color = customColor or config.defaultColor
    part.Material = customMaterial or config.defaultMaterial
    part.Parent = getPropsFolder()

    return part
end


return PropSpawner
