--!strict

local ConstraintRegistry = require(script.Parent.ConstraintRegistry)

local MotorManager = {}

function MotorManager.SetMotorDirection(id: string, direction: number)
	local record = ConstraintRegistry.GetRecord(id)
	if not record or record.constraintType ~= "Motor" then return end

	local hinge = record.instance
	if hinge and hinge:IsA("HingeConstraint") then
		record.meta.activeDirection = direction
		local targetSpeed = record.meta.targetSpeed or 16
		hinge.AngularVelocity = targetSpeed * direction
	end
end

function MotorManager.DriveAssemblyFromSeat(seat: VehicleSeat)
	local throttle = seat.ThrottleFloat
	local steer = seat.SteerFloat
	local assemblyRoot = seat.AssemblyRootPart
	if not assemblyRoot then return end

	-- query constraints on connected parts of the vehicle assembly
	for _, part in ipairs(seat:GetConnectedParts(true)) do
		local connected = ConstraintRegistry.GetPartConstraints(part)
		for _, record in ipairs(connected) do
			if record.instance and record.instance.Parent then
				if record.constraintType == "Motor" then
					local hinge = record.instance :: HingeConstraint
					local targetSpeed = record.meta.targetSpeed or 16
					hinge.AngularVelocity = targetSpeed * throttle
				elseif record.constraintType == "HingeConstraint" and record.meta and record.meta.isServo then
					local hinge = record.instance :: HingeConstraint
					hinge.TargetAngle = steer * 30
				end
			end
		end
	end
end

return MotorManager
