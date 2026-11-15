-- misc1.lua  (the Misc tab content: three empty panels - Movement, Extras, Zhd extras)
-- ASCII only, conservative syntax (no += and no continue).
--
-- Loaded by main.lua / Welcome.lua like hometab.lua. ui.lua calls  MiscModule.build(container, T, H, ctx).
-- Each panel has a title bar with a thin red line under it and an empty scrolling body.
-- Put items into a panel later with:
--     local panels = ctx.Win.MiscPanels          -- or the table returned by build()
--     local body = panels.Movement                -- "Movement", "Extras", "ZhdExtras"
-- The body already has a vertical list layout (6px gap, 10px padding), so just parent your rows to it.

local Misc1 = {}

-- h = height of the panel as a share of the page (Movement tallest, Zhd extras shortest)
local PANELS = {
	{ id = "Movement",  title = "Movement",   h = 0.96 },
	{ id = "Extras",    title = "Extras",     h = 0.78 },
	{ id = "ZhdExtras", title = "Zhd extras", h = 0.60 },
}

function Misc1.build(container, T, H, ctx)
	local GAP = 8
	local HEAD = 34

	local root = H.new("Frame", {
		Name = "MiscRoot",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, container)

	H.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, GAP),
	}, root)

	local bodies = {}
	local count = #PANELS

	for i = 1, count do
		local def = PANELS[i]

		local panel = H.new("Frame", {
			Name = def.id .. "Panel",
			LayoutOrder = i,
			Size = UDim2.new(1 / count, -(GAP * (count - 1)) / count, def.h, 0),
			BackgroundColor3 = T.SIDEBAR_BG,
			BorderSizePixel = 0,
			ClipsDescendants = true,
		}, root)
		H.corner(panel, 6)
		H.stroke(panel, T.BORDER, 1, 0)

		-- title bar
		H.label(panel, def.title, UDim2.fromOffset(12, 0), UDim2.new(1, -24, 0, HEAD),
			Enum.Font.GothamBold, 13, T.TEXT_COLOR).ZIndex = 3

		-- thin red line under the title
		H.new("Frame", {
			Name = "HeadLine",
			Position = UDim2.fromOffset(0, HEAD),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = T.ACCENT,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, panel)

		-- empty body (scrolls if lots of items are added later)
		local body = H.new("ScrollingFrame", {
			Name = "Body",
			Position = UDim2.fromOffset(0, HEAD + 1),
			Size = UDim2.new(1, 0, 1, -(HEAD + 1)),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = T.BORDER,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ZIndex = 2,
		}, panel)
		H.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}, body)
		H.new("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
		}, body)

		bodies[def.id] = body
	end

	-- let other code reach the panels
	if ctx and ctx.Win then
		ctx.Win.MiscPanels = bodies
	end

	return {
		Panels = bodies,
		Unload = function()
			if root and root.Parent then
				root:Destroy()
			end
		end,
	}
end

return Misc1
