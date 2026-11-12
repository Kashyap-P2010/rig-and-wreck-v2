--!strict

local Workspace = game:GetService("Workspace")

local ZeroGravityManager = {}

local zeroGravActive = false

local managedProps: {

	[BasePart]: {

		force: VectorForce,

		attachment: Attachment,

		massConn: RBXScriptConnection?,

		ancConn: RBXScriptConnection?,

	}

} = {}

local propsFolderConn: RBXScriptConnection? = nil

local function getPropsFolder(): Folder?
	local f = Workspace:FindFirstChild("RigAndWreckProps")

	if not f then
		f = Instance.new("Folder")
		f.Name = "RigAndWreckProps"
		f.Parent = Workspace
	end

	return f :: Folder?

end


local function updatePartForce(part: BasePart)
	local data = managedProps[part]

	if not data or not data.force or not data.force.Parent then return end
	-- cancel gravity with upward force per part mass
	local upwardForce = part:GetMass() * Workspace.Gravity
	data.force.Force = Vector3.new(0, upwardForce, 0)
end

function ZeroGravityManager.Apply(part: BasePart, enabled: boolean)

	if not part or not part:IsA("BasePart") or not part.Parent then return end

	if enabled then
		local data = managedProps[part]

		if data and data.force and data.force.Parent then
			updatePartForce(part)
			return
		end

		local att = Instance.new("Attachment")

		att.Name = "RigWreck_ZeroGravAtt"

		att.Position = Vector3.zero

		att.Parent = part

		local vf = Instance.new("VectorForce")

		vf.Name = "RigWreck_ZeroGravForce"

		vf.Attachment0 = att

		vf.RelativeTo = Enum.ActuatorRelativeTo.World

		vf.ApplyAtCenterOfMass = true

		vf.Force = Vector3.new(0, part:GetMass() * Workspace.Gravity, 0)

		vf.Parent = part

		local massConn = part:GetPropertyChangedSignal("Mass"):Connect(function()

			updatePartForce(part)

		end)

		local ancConn = part:GetPropertyChangedSignal("Anchored"):Connect(function()

			if not part.Anchored and zeroGravActive then

				-- wake physics island

				part.AssemblyLinearVelocity = part.AssemblyLinearVelocity + Vector3.new(0, 0.05, 0)

			end

		end)

		managedProps[part] = {

			force = vf,

			attachment = att,

			massConn = massConn,

			ancConn = ancConn,

		}

		part.Destroying:Connect(function()

			ZeroGravityManager.Apply(part, false)

		end)

	else

		local data = managedProps[part]

		if data then

			if data.massConn then data.massConn:Disconnect() end

			if data.ancConn then data.ancConn:Disconnect() end

			if data.force and data.force.Parent then data.force:Destroy() end

			if data.attachment and data.attachment.Parent then data.attachment:Destroy() end

			managedProps[part] = nil

		end

		local oldF = part:FindFirstChild("RigWreck_ZeroGravForce")

		if oldF then oldF:Destroy() end

		local oldAtt = part:FindFirstChild("RigWreck_ZeroGravAtt")

		if oldAtt then oldAtt:Destroy() end

	end

end

function ZeroGravityManager.SetZeroGravity(enabled: boolean)
	zeroGravActive = enabled
	local propsFolder = getPropsFolder()

	if not propsFolder then return end

	if enabled then
		-- auto apply to new props in folder

		if not propsFolderConn then
			propsFolderConn = propsFolder.ChildAdded:Connect(function(child)

				if zeroGravActive and child:IsA("BasePart") then
					task.defer(function()

						if zeroGravActive and child.Parent == propsFolder and child:IsA("BasePart") then
							ZeroGravityManager.Apply(child, true)
						end

					end)

				end

			end)

		end

		-- apply to existing props

		for _, prop in ipairs(propsFolder:GetChildren()) do

			if prop:IsA("BasePart") then

				ZeroGravityManager.Apply(prop, true)

				-- float impulse

				if not prop.Anchored then

					local m = prop:GetMass()

					prop.AssemblyLinearVelocity = Vector3.new(

						prop.AssemblyLinearVelocity.X,

						math.max(prop.AssemblyLinearVelocity.Y, 1.8),

						prop.AssemblyLinearVelocity.Z

					)

					prop:ApplyAngularImpulse(Vector3.new(

						(math.random() - 0.5) * 0.04 * m,

						(math.random() - 0.5) * 0.04 * m,

						(math.random() - 0.5) * 0.04 * m

					))

				end

			end

		end

	else

		if propsFolderConn then

			propsFolderConn:Disconnect()

			propsFolderConn = nil

		end

		-- remove from props

		for prop in pairs(managedProps) do

			ZeroGravityManager.Apply(prop, false)

		end

		table.clear(managedProps)

		for _, prop in ipairs(propsFolder:GetChildren()) do

			if prop:IsA("BasePart") then

				ZeroGravityManager.Apply(prop, false)

			end

		end

	end

end


function ZeroGravityManager.IsZeroGravity(): boolean

	return zeroGravActive
end

return ZeroGravityManager
