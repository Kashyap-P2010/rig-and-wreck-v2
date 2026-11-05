--!strict

local SelectionHighlighter = {}

local hoverHighlight: Highlight? = nil

local selectHighlight: Highlight? = nil

local infoBillboard: BillboardGui? = nil

local infoLabel: TextLabel? = nil

local function getHover(): Highlight

	if not hoverHighlight or not hoverHighlight.Parent then
		local h = Instance.new("Highlight")
		h.Name = "RigWreck_HoverHighlight"
		h.FillTransparency = 0.85
		h.FillColor = Color3.fromRGB(220, 220, 230)
		h.OutlineTransparency = 0.2
		h.OutlineColor = Color3.fromRGB(240, 240, 255)
		h.Parent = workspace
		hoverHighlight = h
	end

	return hoverHighlight :: Highlight

end


local function getSelect(): Highlight

	if not selectHighlight or not selectHighlight.Parent then
		local h = Instance.new("Highlight")
		h.Name = "RigWreck_SelectHighlight"
		h.FillTransparency = 0.7
		h.FillColor = Color3.fromRGB(45, 140, 245)
		h.OutlineTransparency = 0
		h.OutlineColor = Color3.fromRGB(80, 180, 255)
		h.Parent = workspace
		selectHighlight = h
	end

	return selectHighlight :: Highlight

end

local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer

local function getInfoBillboard(): (BillboardGui, TextLabel)

	if not infoBillboard or not infoBillboard.Parent then
		local playerGui = localPlayer and localPlayer:FindFirstChildOfClass("PlayerGui")
		local targetParent = playerGui or workspace
		local existing = targetParent:FindFirstChild("RigWreck_DimHud")

		if existing and existing:IsA("BillboardGui") then
			existing:Destroy()
		end

		local bb = Instance.new("BillboardGui")

		bb.Name = "RigWreck_DimHud"

		bb.Size = UDim2.new(0, 160, 0, 36)

		bb.AlwaysOnTop = true

		bb.StudsOffset = Vector3.new(0, 1.5, 0)

		bb.ResetOnSpawn = false

		bb.Enabled = false

		bb.Parent = targetParent

		local frame = Instance.new("Frame")

		frame.Size = UDim2.new(1, 0, 1, 0)

		frame.BackgroundColor3 = Color3.fromRGB(15, 18, 22)

		frame.BackgroundTransparency = 0.25

		frame.BorderSizePixel = 0

		frame.Parent = bb

		local stroke = Instance.new("UIStroke")

		stroke.Color = Color3.fromRGB(80, 120, 180)

		stroke.Thickness = 1

		stroke.Parent = frame

		local corner = Instance.new("UICorner")

		corner.CornerRadius = UDim.new(0, 4)

		corner.Parent = frame

		local lbl = Instance.new("TextLabel")

		lbl.Size = UDim2.new(1, -8, 1, -6)

		lbl.Position = UDim2.new(0, 4, 0, 3)

		lbl.BackgroundTransparency = 1

		lbl.Font = Enum.Font.GothamMedium

		lbl.TextSize = 10

		lbl.TextColor3 = Color3.fromRGB(240, 240, 245)

		lbl.TextWrapped = true

		lbl.Parent = frame

		infoBillboard = bb

		infoLabel = lbl

	end

	return infoBillboard :: BillboardGui, infoLabel :: TextLabel

end

local function updateInfo(part: BasePart?)
	local bb, lbl = getInfoBillboard()

	if part and part.Parent then
		bb.Adornee = part
		bb.StudsOffset = Vector3.new(0, part.Size.Y * 0.5 + 1.2, 0)
		local frozenTag = if part.Anchored then " • [FROZEN]" else ""
		local magPol = part:GetAttribute("MagnetPolarity")
		local magTag = if magPol then string.format(" • [%s]", tostring(magPol)) else ""
		local weightPreset = part:GetAttribute("WeightPreset")
		local weightTag = if weightPreset then string.format(" • [%s]", tostring(weightPreset)) else ""
		lbl.Text = string.format("Size: %.1f × %.1f × %.1f\nMass: %.1f kg%s%s%s", part.Size.X, part.Size.Y, part.Size.Z, part.AssemblyMass, frozenTag, magTag, weightTag)
		bb.Enabled = true
	else
		bb.Enabled = false
		bb.Adornee = nil
	end

end


function SelectionHighlighter.HighlightHover(part: BasePart?)
	local h = getHover()

	if part and part.Parent then
		h.Adornee = part
		h.Enabled = true
		updateInfo(part)
	else
		h.Enabled = false
		h.Adornee = nil

		if not selectHighlight or not selectHighlight.Enabled then
			updateInfo(nil)
		end

	end

end

function SelectionHighlighter.HighlightSelected(part: BasePart?, color: Color3?)
	local h = getSelect()

	if part and part.Parent then

		if color then
			h.FillColor = color
			h.OutlineColor = color
		else
			h.FillColor = Color3.fromRGB(45, 140, 245)
			h.OutlineColor = Color3.fromRGB(80, 180, 255)
		end

		h.Adornee = part

		h.Enabled = true

		updateInfo(part)

	else

		h.Enabled = false

		h.Adornee = nil

		if not hoverHighlight or not hoverHighlight.Enabled then

			updateInfo(nil)

		end

	end

end


function SelectionHighlighter.UpdateInfo(part: BasePart?)
	updateInfo(part)
end


function SelectionHighlighter.Clear()

	if hoverHighlight then hoverHighlight.Enabled = false end

	if selectHighlight then selectHighlight.Enabled = false end

	if infoBillboard then infoBillboard.Enabled = false end
end

return SelectionHighlighter
