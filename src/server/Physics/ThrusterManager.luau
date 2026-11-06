--!strict

local ConstraintRegistry = require(script.Parent.ConstraintRegistry)

local ThrusterManager = {}

function ThrusterManager.SetThrusterActive(id: string, active: boolean)
	local record = ConstraintRegistry.GetRecord(id)
	if not record or record.constraintType ~= "Thruster" then return end

	local vf = record.instance
	if vf and vf:IsA("VectorForce") then
		record.meta.active = active
		local targetForce = record.meta.targetForce or 14000
		if active then
			-- thrust direction
			vf.Force = Vector3.new(0, targetForce, 0)
		else
			vf.Force = Vector3.zero
		end
	end
end

function ThrusterManager.DriveAssemblyFromSeat(seat: VehicleSeat)
	local throttle = seat.ThrottleFloat
	local assemblyRoot = seat.AssemblyRootPart
	if not assemblyRoot then return end

	local shouldActivate = throttle > 0.1
	for _, part in ipairs(seat:GetConnectedParts(true)) do
		local connected = ConstraintRegistry.GetPartConstraints(part)
		for _, record in ipairs(connected) do
			if record.constraintType == "Thruster" and record.instance and record.instance.Parent then
				ThrusterManager.SetThrusterActive(record.id, shouldActivate)
			end
		end
	end
end

return ThrusterManager
