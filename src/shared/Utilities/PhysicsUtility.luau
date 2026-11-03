--!strict

local PhysicsUtility = {}


function PhysicsUtility.ClampAssemblyVelocity(part: BasePart, maxLinear: number, maxAngular: number)
	local linVel = part.AssemblyLinearVelocity

	if linVel.Magnitude > maxLinear then
		part.AssemblyLinearVelocity = linVel.Unit * maxLinear
	end

	local angVel = part.AssemblyAngularVelocity

	if angVel.Magnitude > maxAngular then

		part.AssemblyAngularVelocity = angVel.Unit * maxAngular

	end

end


function PhysicsUtility.GetAssemblyMass(part: BasePart): number

	return part.AssemblyMass
end

function PhysicsUtility.SnapVector(vec: Vector3, snap: number): Vector3

	if snap <= 0 then return vec end
	local x = math.round(vec.X / snap) * snap
	local y = math.round(vec.Y / snap) * snap
	local z = math.round(vec.Z / snap) * snap

	return Vector3.new(x, y, z)
end

function PhysicsUtility.SnapAngle(rad: number, snapDegrees: number): number

	if snapDegrees <= 0 then return rad end
	local snapRad = math.rad(snapDegrees)

	return math.round(rad / snapRad) * snapRad
end

function PhysicsUtility.SerializeCFrame(cf: CFrame): { number }
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()

	return { x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 }
end

function PhysicsUtility.DeserializeCFrame(comp: { number }): CFrame

	if #comp < 12 then

		return CFrame.new(comp[1] or 0, comp[2] or 0, comp[3] or 0)
	end

	return CFrame.new(

		comp[1], comp[2], comp[3],

		comp[4], comp[5], comp[6],

		comp[7], comp[8], comp[9],

		comp[10], comp[11], comp[12]

	)

end


function PhysicsUtility.GetRelativeCFrame(rootCF: CFrame, targetCF: CFrame): CFrame

	return rootCF:ToObjectSpace(targetCF)
end

function PhysicsUtility.ApplyRelativeCFrame(rootCF: CFrame, relCF: CFrame): CFrame

	return rootCF * relCF
end


return PhysicsUtility
