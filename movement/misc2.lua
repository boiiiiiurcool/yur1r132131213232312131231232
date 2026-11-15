-- misc2.lua  (the "Extras" page of the Misc tab - this is where the features go)
-- ASCII only, conservative syntax (no += and no continue).
--
-- misc1.lua builds this into the Extras side of its "Main | Extras" switcher:
--     Misc2.build(container, T, H, ctx)
--   T = theme, H = { new, corner, stroke, label }, ctx.Win = the Y1 window
--
-- The page is an empty scrolling list for now. Put your features into the Body:
--     local body = ctx.Win.MiscExtras
-- Rows parented to it stack top to bottom (8px gap, 12px padding).
-- Modules you can turn on / off should be registered with  ctx.Win:AddToggle({...})  so they show in the Keybinds panel.

local Misc2 = {}

function Misc2.build(container, T, H, ctx)
	local root = H.new("Frame", {
		Name = "MiscExtrasRoot",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = T.SIDEBAR_BG,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, container)
	H.corner(root, 6)
	H.stroke(root, T.BORDER, 1, 0)

	-- title bar with the thin red line, same look as the Main panels
	-- plus icon (same one the Extras panel on the Main side uses)
	local ico = H.new("Frame", {
		Position = UDim2.fromOffset(12, 9),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, root)
	local pw = H.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(12, 2),
		BackgroundColor3 = T.ACCENT,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, ico)
	H.corner(pw, 1)
	local ph = H.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(2, 12),
		BackgroundColor3 = T.ACCENT,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, ico)
	H.corner(ph, 1)
	H.label(root, "Extras", UDim2.fromOffset(36, 0), UDim2.new(1, -48, 0, 34),
		Enum.Font.GothamBold, 13, T.TEXT_COLOR).ZIndex = 3
	H.new("Frame", {
		Name = "HeadLine",
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = T.ACCENT,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, root)

	local body = H.new("ScrollingFrame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, 35),
		Size = UDim2.new(1, 0, 1, -35),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = T.BORDER,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 2,
	}, root)
	H.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	}, body)
	H.new("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
	}, body)

	-- shown until the first feature is added
	local hint = H.label(root, "Extras features will go here", UDim2.new(0, 0, 0.5, -8), UDim2.new(1, 0, 0, 16),
		Enum.Font.GothamMedium, 12, T.DIM_TEXT, Enum.TextXAlignment.Center)
	hint.ZIndex = 2
	body.ChildAdded:Connect(function(c)
		if c:IsA("GuiObject") and hint.Visible then
			hint.Visible = false
		end
	end)

	if type(ctx) == "table" and ctx.Win then
		ctx.Win.MiscExtras = body
	end

	return {
		Body = body,
		Unload = function()
			if root and root.Parent then
				root:Destroy()
			end
		end,
	}
end

return Misc2
