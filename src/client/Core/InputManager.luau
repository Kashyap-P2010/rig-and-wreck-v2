--!strict

local ContextActionService = game:GetService("ContextActionService")

local UserInputService = game:GetService("UserInputService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteDefinitions = require(ReplicatedStorage.RigAndWreck.Network.RemoteDefinitions)

local ToolManager = require(script.Parent.ToolManager)

local InputManager = {}

local undoActionRemote = RemoteDefinitions.GetEvent("UndoAction")

function InputManager.Init()
	-- primary action (lmb)
	ContextActionService:BindAction("RigWreck_PrimaryAction", function(actionName, inputState, inputObj)

		if inputState == Enum.UserInputState.Begin then
			ToolManager.TriggerAction()
		end

		return Enum.ContextActionResult.Pass

	end, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)

	-- secondary action (rmb)

	ContextActionService:BindAction("RigWreck_SecondaryAction", function(actionName, inputState, inputObj)

		if inputState == Enum.UserInputState.Begin then

			ToolManager.TriggerSecondary()

		end

		return Enum.ContextActionResult.Pass

	end, false, Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonL2)

	-- tool hotkeys 1-0

	local numberKeys = {

		Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three,

		Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six,

		Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine,

		Enum.KeyCode.Zero, Enum.KeyCode.Minus

	}

	for idx, key in ipairs(numberKeys) do

		ContextActionService:BindAction("RigWreck_Tool_" .. idx, function(actionName, inputState)

			if inputState == Enum.UserInputState.Begin then

				ToolManager.SelectTool(idx)

			end

			return Enum.ContextActionResult.Pass

		end, false, key)

	end

	-- toggle slow-mo (g)

	ContextActionService:BindAction("RigWreck_SlowMotion", function(actionName, inputState)

		if inputState == Enum.UserInputState.Begin then

			-- slow-mo UI added later

		end

		return Enum.ContextActionResult.Pass

	end, false, Enum.KeyCode.G)

	-- spawn menu (q)

	ContextActionService:BindAction("RigWreck_ToggleProps", function(actionName, inputState)

		if inputState == Enum.UserInputState.Begin then

			-- spawn menu added later

		end

		return Enum.ContextActionResult.Pass

	end, false, Enum.KeyCode.Q, Enum.KeyCode.ButtonY)

	-- freeze (f)

	ContextActionService:BindAction("RigWreck_Freeze", function(actionName, inputState)

		if inputState == Enum.UserInputState.Begin then

			ToolManager.TriggerFreeze()

		end

		return Enum.ContextActionResult.Pass

	end, false, Enum.KeyCode.F)

	-- rotate yaw (r)

	ContextActionService:BindAction("RigWreck_Rotate", function(actionName, inputState)

		if inputState == Enum.UserInputState.Begin then

			ToolManager.TriggerRotate("Yaw")

		end

		return Enum.ContextActionResult.Pass

	end, false, Enum.KeyCode.R, Enum.KeyCode.ButtonX)

	-- rotate pitch (t)

	ContextActionService:BindAction("RigWreck_RotatePitch", function(actionName, inputState)

		if inputState == Enum.UserInputState.Begin then

			ToolManager.TriggerRotate("Pitch")

		end

		return Enum.ContextActionResult.Pass

	end, false, Enum.KeyCode.T)

	-- undo (z)

	ContextActionService:BindAction("RigWreck_Undo", function(actionName, inputState)

		if inputState == Enum.UserInputState.Begin then

			undoActionRemote:FireServer({ Redo = false })

		end

		return Enum.ContextActionResult.Pass

	end, false, Enum.KeyCode.Z)

	-- redo (y)

	ContextActionService:BindAction("RigWreck_Redo", function(actionName, inputState)

		if inputState == Enum.UserInputState.Begin then

			undoActionRemote:FireServer({ Redo = true })

		end

		return Enum.ContextActionResult.Pass

	end, false, Enum.KeyCode.Y)

	-- scroll wheel dist

	UserInputService.PointerAction:Connect(function(wheel, pan, pinch, processed)

		if not processed and math.abs(wheel) > 0 then

			ToolManager.AdjustDistance(wheel * 2.5)

		end

	end)

end

return InputManager
