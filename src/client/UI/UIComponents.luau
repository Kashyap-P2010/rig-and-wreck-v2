--!strict

local UIComponents = {}

local THEME = {

	Bg = Color3.fromRGB(28, 28, 32),

	PanelBg = Color3.fromRGB(34, 34, 38),

	SlotBg = Color3.fromRGB(42, 42, 48),

	SlotHover = Color3.fromRGB(52, 52, 60),

	SlotSelected = Color3.fromRGB(45, 90, 160),

	Border = Color3.fromRGB(58, 58, 66),

	TextPrimary = Color3.fromRGB(235, 235, 240),

	TextSecondary = Color3.fromRGB(160, 160, 170),

	Accent = Color3.fromRGB(50, 130, 230),

	Error = Color3.fromRGB(215, 60, 60),

	Font = Enum.Font.GothamMedium,

	FontBold = Enum.Font.GothamBold,

	FontRegular = Enum.Font.GothamMedium,

}

UIComponents.Theme = THEME

function UIComponents.CreatePanel(name: string, size: UDim2, pos: UDim2): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = pos
	frame.BackgroundColor3 = THEME.PanelBg
	frame.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.Border
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 3)
	corner.Parent = frame

	return frame
end


function UIComponents.CreateButton(text: string, size: UDim2, pos: UDim2?, onClick: () -> ()): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = "Btn_" .. text
	btn.Size = size

	if pos then btn.Position = pos end
	btn.BackgroundColor3 = THEME.SlotBg
	btn.BorderSizePixel = 0
	btn.Font = THEME.FontBold
	btn.Text = text
	btn.TextColor3 = THEME.TextPrimary
	btn.TextSize = 13
	btn.AutoButtonColor = false
	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.Border
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = btn
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 3)
	corner.Parent = btn
	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = THEME.SlotHover
	end)

	btn.MouseLeave:Connect(function()

		btn.BackgroundColor3 = THEME.SlotBg

	end)

	btn.MouseButton1Down:Connect(function()

		btn.BackgroundColor3 = THEME.SlotSelected

	end)

	btn.MouseButton1Up:Connect(function()

		btn.BackgroundColor3 = THEME.SlotHover

	end)

	btn.Activated:Connect(function()

		onClick()

	end)

	return btn

end

function UIComponents.CreateLabel(text: string, size: UDim2, pos: UDim2?, align: Enum.TextXAlignment?): TextLabel
	local lbl = Instance.new("TextLabel")
	lbl.Name = "Label"
	lbl.Size = size

	if pos then lbl.Position = pos end
	lbl.BackgroundTransparency = 1
	lbl.Font = THEME.Font
	lbl.Text = text
	lbl.TextColor3 = THEME.TextPrimary
	lbl.TextSize = 13
	lbl.TextXAlignment = align or Enum.TextXAlignment.Left

	return lbl
end

function UIComponents.CreateSlider(name: string, min: number, max: number, defaultVal: number, size: UDim2, onValChanged: (number) -> (), formatter: ((number) -> string)?): Frame
	local container = Instance.new("Frame")
	container.Name = "Slider_" .. name
	container.Size = size
	container.BackgroundTransparency = 1
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 16)
	title.BackgroundTransparency = 1
	title.Font = THEME.Font
	title.Text = if formatter then formatter(defaultVal) else string.format("%s: %d", name, defaultVal)
	title.TextColor3 = THEME.TextSecondary
	title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = container
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = UDim2.new(1, 0, 0, 6)
	track.Position = UDim2.new(0, 0, 0, 20)
	track.BackgroundColor3 = THEME.SlotBg
	track.BorderSizePixel = 0
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 2)
	trackCorner.Parent = track
	track.Parent = container
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	local initAlpha = math.clamp((defaultVal - min) / (max - min), 0, 1)
	fill.Size = UDim2.new(initAlpha, 0, 1, 0)
	fill.BackgroundColor3 = THEME.Accent
	fill.BorderSizePixel = 0
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 2)
	fillCorner.Parent = fill
	fill.Parent = track
	local dragging = false

	local function updateFromX(x: number)
		local absPos = track.AbsolutePosition.X
		local absSize = track.AbsoluteSize.X
		local alpha = math.clamp((x - absPos) / absSize, 0, 1)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		local val = math.round(min + (max - min) * alpha)
		title.Text = if formatter then formatter(val) else string.format("%s: %d", name, val)
		onValChanged(val)
	end

	track.InputBegan:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromX(input.Position.X)
		end

	end)

	game:GetService("UserInputService").InputEnded:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then

			dragging = false

		end

	end)

	game:GetService("UserInputService").InputChanged:Connect(function(input)

		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then

			updateFromX(input.Position.X)

		end

	end)


	return container

end

local activeToast: Frame? = nil


function UIComponents.ShowToast(text: string, color: Color3?)
	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")
	local lp = Players.LocalPlayer

	if not lp then return end
	local playerGui = lp:FindFirstChildOfClass("PlayerGui")

	if not playerGui then return end
	local screenGui = playerGui:FindFirstChild("RigAndWreckGui") or playerGui:FindFirstChildOfClass("ScreenGui")

	if not screenGui then return end

	if activeToast and activeToast.Parent then
		activeToast:Destroy()
		activeToast = nil
	end

	local toast = Instance.new("Frame")

	toast.Name = "RigWreck_Toast"

	toast.Size = UDim2.new(0, 380, 0, 36)

	toast.Position = UDim2.new(0.5, 0, 0, 138)

	toast.AnchorPoint = Vector2.new(0.5, 0)

	toast.BackgroundColor3 = Color3.fromRGB(20, 22, 28)

	toast.BackgroundTransparency = 0.1

	toast.BorderSizePixel = 0

	toast.ZIndex = 50

	local corner = Instance.new("UICorner")

	corner.CornerRadius = UDim.new(0, 5)

	corner.Parent = toast

	local stroke = Instance.new("UIStroke")

	stroke.Color = color or THEME.Accent

	stroke.Thickness = 1.2

	stroke.Parent = toast

	local lbl = Instance.new("TextLabel")

	lbl.Size = UDim2.new(1, -16, 1, 0)

	lbl.Position = UDim2.new(0, 8, 0, 0)

	lbl.BackgroundTransparency = 1

	lbl.Font = THEME.FontBold

	lbl.TextSize = 12

	lbl.TextColor3 = color or THEME.TextPrimary

	lbl.Text = text

	lbl.TextWrapped = true

	lbl.ZIndex = 51

	lbl.Parent = toast

	toast.Parent = screenGui

	activeToast = toast

	task.delay(3.5, function()

		if activeToast == toast then

			local fade = TweenService:Create(toast, TweenInfo.new(0.4), { BackgroundTransparency = 1 })

			TweenService:Create(lbl, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()

			TweenService:Create(stroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()

			fade:Play()

			fade.Completed:Connect(function()

				if activeToast == toast then

					toast:Destroy()

					activeToast = nil

				end

			end)

		end

	end)

end


return UIComponents
