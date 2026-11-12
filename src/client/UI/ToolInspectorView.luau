--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIComponents = require(script.Parent.UIComponents)

local ToolConfigs = require(ReplicatedStorage.RigAndWreck.Config.ToolConfigs)

local ToolInspectorView = {}

local panel: Frame? = nil

local contentHolder: Frame? = nil

function ToolInspectorView.Init(screenGui: ScreenGui)
	local p = UIComponents.CreatePanel("ToolInspector", UDim2.new(0, 244, 0, 340), UDim2.new(1, -256, 0.5, -170))
	p.Visible = false
	local title = UIComponents.CreateLabel("TOOL SETTINGS", UDim2.new(1, -20, 0, 20), UDim2.new(0, 10, 0, 6))
	title.Font = UIComponents.Theme.FontBold
	title.TextSize = 12
	title.Parent = p
	local holder = Instance.new("Frame")
	holder.Name = "Content"
	holder.Size = UDim2.new(1, -20, 1, -36)
	holder.Position = UDim2.new(0, 10, 0, 30)
	holder.BackgroundTransparency = 1
	holder.Parent = p
	p.Parent = screenGui
	panel = p
	contentHolder = holder
end

function ToolInspectorView.ShowForTool(toolName: string, toolInstance: any)

	if not panel or not contentHolder then return end
	contentHolder:ClearAllChildren()

	if toolName == "Motor" then
		panel.Visible = true
		local speedSlider = UIComponents.CreateSlider("Speed", 5, 60, toolInstance.MotorSpeed or 20, UDim2.new(1, 0, 0, 45), function(val)
			toolInstance:SetSpeed(val)
		end, function(val)

			return string.format("Speed: %d RPM", val)

		end)

		speedSlider.Position = UDim2.new(0, 0, 0, 0)

		speedSlider.Parent = contentHolder

		local defTorqueLvl = math.clamp(math.round((toolInstance.MotorTorque or 15000) / 3500), 1, 10)

		local torqueSlider = UIComponents.CreateSlider("Torque", 1, 10, defTorqueLvl, UDim2.new(1, 0, 0, 45), function(val)

			toolInstance:SetTorque(val * 3500)

		end, function(val)

			return string.format("Torque: %d / 10", val)

		end)

		torqueSlider.Position = UDim2.new(0, 0, 0, 50)

		torqueSlider.Parent = contentHolder

		local info = UIComponents.CreateLabel("Controls: W / S or VehicleSeat", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 102))

		info.TextSize = 11

		info.TextColor3 = UIComponents.Theme.TextSecondary

		info.Parent = contentHolder

	elseif toolName == "Thruster" then

		panel.Visible = true

		local defThrustLvl = math.clamp(math.round((toolInstance.ThrusterForce or 16000) / 4000), 1, 10)

		local forceSlider = UIComponents.CreateSlider("Thrust Power", 1, 10, defThrustLvl, UDim2.new(1, 0, 0, 45), function(val)

			toolInstance:SetForce(val * 4000)

		end, function(val)

			return string.format("Thrust Power: %d / 10", val)

		end)

		forceSlider.Position = UDim2.new(0, 0, 0, 0)

		forceSlider.Parent = contentHolder

		local info = UIComponents.CreateLabel("Drives forward with VehicleSeat or Space", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 52))

		info.TextSize = 11

		info.TextColor3 = UIComponents.Theme.TextSecondary

		info.Parent = contentHolder

	elseif toolName == "Rope" then

		panel.Visible = true

		local lengthSlider = UIComponents.CreateSlider("Length", 2, 50, toolInstance.RopeLength or 10, UDim2.new(1, 0, 0, 45), function(val)

			toolInstance:SetLength(val)

		end, function(val)

			return string.format("Rope Length: %d studs", val)

		end)

		lengthSlider.Position = UDim2.new(0, 0, 0, 0)

		lengthSlider.Parent = contentHolder

	elseif toolName == "Balloon" then

		panel.Visible = true

		local defLiftLvl = math.clamp(math.round((toolInstance.LiftForce or 3500) / 1000), 1, 10)

		local liftSlider = UIComponents.CreateSlider("Buoyancy", 1, 10, defLiftLvl, UDim2.new(1, 0, 0, 45), function(val)

			toolInstance:SetLiftForce(val * 1000)

		end, function(val)

			return string.format("Buoyancy: %d / 10", val)

		end)

		liftSlider.Position = UDim2.new(0, 0, 0, 0)

		liftSlider.Parent = contentHolder

		local colLbl = UIComponents.CreateLabel("Balloon Color:", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 52))

		colLbl.TextSize = 11

		colLbl.Parent = contentHolder

		local colors = ToolConfigs.Balloon.Colors

		for idx, color in ipairs(colors) do

			local swatch = Instance.new("TextButton")

			swatch.Name = "BalloonColor_" .. idx

			swatch.Size = UDim2.new(0, 28, 0, 24)

			swatch.Position = UDim2.new(0, (idx - 1) * 34, 0, 72)

			swatch.BackgroundColor3 = color

			swatch.BorderSizePixel = 0

			swatch.Text = ""

			local sc = Instance.new("UICorner")

			sc.CornerRadius = UDim.new(0, 4)

			sc.Parent = swatch

			swatch.Activated:Connect(function()

				toolInstance:SetColor(color)

			end)

			swatch.Parent = contentHolder

		end

		local info = UIComponents.CreateLabel("LMB: Attach Balloon • Pop with LMB", UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 106))

		info.TextSize = 11

		info.TextColor3 = UIComponents.Theme.TextSecondary

		info.Parent = contentHolder

	elseif toolName == "Magnet" then

		panel.Visible = true

		local polBtn: TextButton


		local function updatePolBtn()

			if polBtn then
				local isNorth = (toolInstance.Polarity == "North")
				polBtn.Text = if isNorth then "Pole: NORTH (Red)" else "Pole: SOUTH (Blue)"
				polBtn.BackgroundColor3 = if isNorth then ToolConfigs.Magnet.NorthColor else ToolConfigs.Magnet.SouthColor
			end

		end

		polBtn = UIComponents.CreateButton("", UDim2.new(1, 0, 0, 32), UDim2.new(0, 0, 0, 0), function()

			toolInstance:TogglePolarity()

			updatePolBtn()

		end)

		updatePolBtn()

		polBtn.Parent = contentHolder

		local defMagLvl = math.clamp(math.round((toolInstance.Strength or 35000) / 7000), 1, 10)

		local forceSlider = UIComponents.CreateSlider("Magnetic Power", 1, 10, defMagLvl, UDim2.new(1, 0, 0, 45), function(val)

			toolInstance:SetStrength(val * 7000)

		end, function(val)

			return string.format("Magnetic Power: %d / 10", val)

		end)

		forceSlider.Position = UDim2.new(0, 0, 0, 40)

		forceSlider.Parent = contentHolder

		local tip = UIComponents.CreateLabel("Opposites attract • Likes repel", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 92))

		tip.TextSize = 11

		tip.TextColor3 = UIComponents.Theme.TextSecondary

		tip.Parent = contentHolder

	elseif toolName == "Weld" then

		panel.Visible = true

		local unweldBtn = UIComponents.CreateButton("Unweld Target Prop [RMB]", UDim2.new(1, 0, 0, 32), UDim2.new(0, 0, 0, 0), function()

			toolInstance:UnweldHovered()

		end)

		unweldBtn.BackgroundColor3 = Color3.fromRGB(190, 80, 40)

		unweldBtn.Parent = contentHolder

		local unweldAllBtn = UIComponents.CreateButton("Break All My Welds", UDim2.new(1, 0, 0, 32), UDim2.new(0, 0, 0, 40), function()

			toolInstance:UnweldAll()

		end)

		unweldAllBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 40)

		unweldAllBtn.Parent = contentHolder

		local info = UIComponents.CreateLabel("LMB: Click 2 props to Weld\nRMB: Break all welds on target", UDim2.new(1, 0, 0, 32), UDim2.new(0, 0, 0, 82))

		info.TextSize = 11

		info.TextColor3 = UIComponents.Theme.TextSecondary

		info.TextWrapped = true

		info.Parent = contentHolder

	elseif toolName == "Transform" then

		panel.Visible = true

		local snapLbl = UIComponents.CreateLabel("Snap:", UDim2.new(0, 45, 0, 22), UDim2.new(0, 0, 0, 0))

		snapLbl.TextSize = 11

		snapLbl.Parent = contentHolder

		for idx, snapVal in ipairs({ 0.5, 1, 2, 4 }) do

			local btn = UIComponents.CreateButton(tostring(snapVal), UDim2.new(0, 34, 0, 22), UDim2.new(0, 46 + (idx - 1) * 38, 0, 0), function()

				toolInstance:SetSnap(snapVal)

			end)

			btn.TextSize = 10

			btn.Parent = contentHolder

		end

		local rotBtn = UIComponents.CreateButton("Rotate +45°", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 26), function()

			toolInstance:RotateSelected(45)

		end)

		rotBtn.Parent = contentHolder

		local growBtn = UIComponents.CreateButton("Size +", UDim2.new(0.48, 0, 0, 24), UDim2.new(0, 0, 0, 54), function()

			toolInstance:ResizeSelected(toolInstance.Snap or 1)

		end)

		growBtn.Parent = contentHolder

		local shrinkBtn = UIComponents.CreateButton("Size -", UDim2.new(0.48, 0, 0, 24), UDim2.new(0.52, 0, 0, 54), function()

			toolInstance:ResizeSelected(-(toolInstance.Snap or 1))

		end)

		shrinkBtn.Parent = contentHolder

		local dupBtn = UIComponents.CreateButton("Duplicate", UDim2.new(0.48, 0, 0, 24), UDim2.new(0, 0, 0, 82), function()

			toolInstance:DuplicateSelected()

		end)

		dupBtn.Parent = contentHolder

		local mirrorBtn = UIComponents.CreateButton("Mirror (X)", UDim2.new(0.48, 0, 0, 24), UDim2.new(0.52, 0, 0, 82), function()

			toolInstance:MirrorClone()

		end)

		mirrorBtn.Parent = contentHolder

		local weightLbl = UIComponents.CreateLabel("Weight Presets:", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 112))

		weightLbl.Font = UIComponents.Theme.FontBold

		weightLbl.TextSize = 11

		weightLbl.Parent = contentHolder

		local presets = ToolConfigs.WeightPresets

		for idx, preset in ipairs(presets) do

			local row = math.floor((idx - 1) / 2)

			local col = (idx - 1) % 2

			local label = string.format("%s (%.1fx)", preset.name, preset.density)

			local pBtn = UIComponents.CreateButton(label, UDim2.new(0.48, 0, 0, 22), UDim2.new(col * 0.52, 0, 0, 132 + row * 26), function()

				toolInstance:SetWeightPreset(preset)

			end)

			pBtn.TextSize = 10

			pBtn.Parent = contentHolder

		end

		local info = UIComponents.CreateLabel("Click preset then click prop to apply\nScroll: Scale • Ctrl+Click: Copy Size", UDim2.new(1, 0, 0, 32), UDim2.new(0, 0, 0, 192))

		info.TextSize = 10

		info.TextColor3 = UIComponents.Theme.TextSecondary

		info.TextWrapped = true

		info.Parent = contentHolder

	elseif toolName == "Paint" then

		panel.Visible = true

		local colLbl = UIComponents.CreateLabel("Colors:", UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 0))

		colLbl.TextSize = 11

		colLbl.Parent = contentHolder

		local palette = ToolConfigs.Paint.Palette

		for idx, color in ipairs(palette) do

			local row = math.floor((idx - 1) / 6)

			local col = (idx - 1) % 6

			local swatch = Instance.new("TextButton")

			swatch.Name = "Color_" .. idx

			swatch.Size = UDim2.new(0, 28, 0, 22)

			swatch.Position = UDim2.new(0, col * 34, 0, 20 + row * 26)

			swatch.BackgroundColor3 = color

			swatch.BorderSizePixel = 0

			swatch.Text = ""

			local sc = Instance.new("UICorner")

			sc.CornerRadius = UDim.new(0, 2)

			sc.Parent = swatch

			swatch.Activated:Connect(function()

				toolInstance:SetColor(color)

			end)

			swatch.Parent = contentHolder

		end

		local matLbl = UIComponents.CreateLabel("Materials:", UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 80))

		matLbl.TextSize = 11

		matLbl.Parent = contentHolder

		local mats = {

			{ name = "Plastic", mat = Enum.Material.SmoothPlastic },

			{ name = "Wood", mat = Enum.Material.WoodPlanks },

			{ name = "Metal", mat = Enum.Material.Metal },

			{ name = "Neon", mat = Enum.Material.Neon },

			{ name = "Concrete", mat = Enum.Material.Concrete },

			{ name = "Glass", mat = Enum.Material.Glass },

		}

		for idx, m in ipairs(mats) do

			local row = math.floor((idx - 1) / 2)

			local col = (idx - 1) % 2

			local mBtn = UIComponents.CreateButton(m.name, UDim2.new(0.48, 0, 0, 22), UDim2.new(col * 0.52, 0, 0, 100 + row * 26), function()

				toolInstance:SetMaterial(m.mat)

			end)

			mBtn.TextSize = 10

			mBtn.Parent = contentHolder

		end

	elseif toolName == "Grab" then

		panel.Visible = true

		local freezeBtn = UIComponents.CreateButton("Freeze / Unfreeze [F]", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0), function()

			toolInstance:ToggleFreeze()

		end)

		freezeBtn.BackgroundColor3 = Color3.fromRGB(40, 110, 180)

		freezeBtn.Parent = contentHolder

		local rotBtn = UIComponents.CreateButton("Rotate [R / T]", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 32), function()

			toolInstance:RotateHeld("Yaw")

		end)

		rotBtn.Parent = contentHolder

		local throwBtn = UIComponents.CreateButton("Throw [RMB]", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 64), function()

			toolInstance:Throw()

		end)

		throwBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)

		throwBtn.Parent = contentHolder

		local info = UIComponents.CreateLabel("Scroll: Dist • Alt: Cam Align\nShift: Multi-Prop Grab", UDim2.new(1, 0, 0, 34), UDim2.new(0, 0, 0, 96))

		info.TextSize = 10

		info.TextColor3 = UIComponents.Theme.TextSecondary

		info.TextWrapped = true

		info.Parent = contentHolder

	else

		panel.Visible = false

	end

end


function ToolInspectorView.Hide()

	if panel then panel.Visible = false end
end

return ToolInspectorView
