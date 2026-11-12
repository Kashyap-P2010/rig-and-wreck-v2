--!strict

local UIComponents = require(script.Parent.UIComponents)

local HotbarView = {}

local TOOLS_LIST = {

	{ id = "Grab", label = "Grab", bind = "1" },

	{ id = "Weld", label = "Weld", bind = "2" },

	{ id = "Rope", label = "Rope", bind = "3" },

	{ id = "Balloon", label = "Balloon", bind = "4" },

	{ id = "Magnet", label = "Magnet", bind = "5" },

	{ id = "Hinge", label = "Hinge", bind = "6" },

	{ id = "Motor", label = "Motor", bind = "7" },

	{ id = "Thruster", label = "Thrust", bind = "8" },

	{ id = "Transform", label = "Move", bind = "9" },

	{ id = "Paint", label = "Paint", bind = "0" },

	{ id = "Delete", label = "Del", bind = "-" },

}

local toolButtons: { [number]: TextButton } = {}

local activeIndex: number? = 1


function HotbarView.Init(screenGui: ScreenGui, onSelectTool: (index: number) -> (), onToggleProps: () -> (), onUndo: () -> (), onRedo: () -> ())
	local bar = Instance.new("Frame")
	bar.Name = "Hotbar"
	bar.Size = UDim2.new(0, 780, 0, 48)
	bar.Position = UDim2.new(0.5, -390, 1, -58)
	bar.BackgroundColor3 = UIComponents.Theme.PanelBg
	bar.BorderSizePixel = 0
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 4)
	barCorner.Parent = bar
	local barStroke = Instance.new("UIStroke")
	barStroke.Color = UIComponents.Theme.Border
	barStroke.Thickness = 1
	barStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	barStroke.Parent = bar
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 3)
	layout.Parent = bar
	-- props button
	local propsBtn = UIComponents.CreateButton("[Q] Props", UDim2.new(0, 60, 0, 38), nil, function()
		onToggleProps()
	end)

	propsBtn.BackgroundColor3 = Color3.fromRGB(45, 95, 60)

	propsBtn.Parent = bar

	-- tool slots

	for idx, tool in ipairs(TOOLS_LIST) do

		local text = string.format("[%s] %s", tool.bind, tool.label)

		local btn = UIComponents.CreateButton(text, UDim2.new(0, 50, 0, 38), nil, function()

			onSelectTool(idx)

		end)

		btn.TextSize = 10

		btn.Parent = bar

		toolButtons[idx] = btn

	end

	-- undo button

	local undoBtn = UIComponents.CreateButton("[Z]", UDim2.new(0, 30, 0, 38), nil, function()

		onUndo()

	end)

	undoBtn.TextSize = 10

	undoBtn.Parent = bar

	-- redo button

	local redoBtn = UIComponents.CreateButton("[Y]", UDim2.new(0, 30, 0, 38), nil, function()

		onRedo()

	end)

	redoBtn.TextSize = 10

	redoBtn.Parent = bar

	-- controls hint

	local hint = Instance.new("TextLabel")

	hint.Name = "ControlsHint"

	hint.Size = UDim2.new(0, 780, 0, 16)

	hint.Position = UDim2.new(0.5, -390, 1, -78)

	hint.BackgroundTransparency = 1

	hint.Font = Enum.Font.GothamMedium

	hint.TextSize = 11

	hint.TextColor3 = Color3.fromRGB(190, 195, 205)

	hint.TextStrokeTransparency = 0.5

	hint.Text = "[LMB] Use  •  [RMB] Throw / Cancel / Polarity  •  [R / T] Rotate  •  [G] Slow-Mo  •  [Z / Y] Undo / Redo"

	hint.Parent = screenGui

	bar.Parent = screenGui

	HotbarView.SetActive(1)

end


function HotbarView.SetActive(idx: number?)
	activeIndex = idx

	for i, btn in pairs(toolButtons) do

		if i == idx then
			btn.BackgroundColor3 = UIComponents.Theme.SlotSelected
		else
			btn.BackgroundColor3 = UIComponents.Theme.SlotBg
		end

	end

end

function HotbarView.GetActiveIndex(): number?

	return activeIndex
end


function HotbarView.GetToolsList()

	return TOOLS_LIST
end

return HotbarView
