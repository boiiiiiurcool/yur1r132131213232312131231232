-- misc1.lua  (the Misc tab: a small "Main | Extras" switcher at the bottom)
-- ASCII only, conservative syntax (no += and no continue).
--
-- Loaded by main.lua / Welcome.lua like hometab.lua. ui.lua calls  MiscModule.build(container, T, H, ctx).
--   Main   = three panels (Movement, Extras, Zhd extras), empty for now. Each has a title bar with a thin red line.
--   Extras = built by misc2.lua  (main.lua passes it as  Misc = { ExtrasModule = modules.Misc2 }  ).
--            misc2.lua just needs  build(container, T, H, ctx)  and may return { Unload = fn }.
--
-- Put items into a Main panel later with:
--     local body = ctx.Win.MiscPanels.Movement        -- "Movement", "Extras", "ZhdExtras"
-- Switch pages from code with:
--     ctx.Win.MiscShow("Main")  or  ctx.Win.MiscShow("Extras")

local Misc1 = {}

-- h = height of the panel as a share of the page (Movement tallest, Zhd extras shortest)
local PANELS = {
	{ id = "Movement",  title = "Movement",   h = 0.96, icon = "chevrons" },
	{ id = "Extras",    title = "Extras",     h = 0.78, icon = "plus" },
	{ id = "ZhdExtras", title = "Zhd extras", h = 0.60, icon = "diamond" },
}

function Misc1.build(container, T, H, ctx)
	local TweenService = game:GetService("TweenService")

	local GAP = 14        -- space between the three panels
	local HEAD = 34
	local SW_W = 220      -- switcher width
	local SW_H = 28       -- switcher height
	local SW_GAP = 3      -- space between the pages and the switcher (smaller = closer to the panels)

	local root = H.new("Frame", {
		Name = "MiscRoot",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, container)

	-- the area above the switcher; both pages live in here
	local view = H.new("Frame", {
		Name = "View",
		Size = UDim2.new(1, 0, 1, -(SW_H + SW_GAP)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, root)

	local function makePage(name, shown)
		local gt = 1
		if shown then
			gt = 0
		end
		return H.new("CanvasGroup", {
			Name = name,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			GroupTransparency = gt,
			Visible = shown,
		}, view)
	end

	local mainPage = makePage("MainPage", true)
	local extrasPage = makePage("ExtrasPage", false)

	---------------------------------------------------------------------
	-- MAIN PAGE: the three panels
	---------------------------------------------------------------------
	H.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, GAP),
	}, mainPage)

	-- small calm-red icon drawn with frames (16x16), sits left of a panel title
	local function headerIcon(parent, kind)
		local holder = H.new("Frame", {
			Name = "Icon",
			Position = UDim2.fromOffset(12, 9),
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, parent)

		local function bit(w, h, x, y, rot)
			local f = H.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, x, 0.5, y),
				Size = UDim2.fromOffset(w, h),
				Rotation = rot or 0,
				BackgroundColor3 = T.ACCENT,
				BorderSizePixel = 0,
				ZIndex = 4,
			}, holder)
			H.corner(f, 1)
			return f
		end

		if kind == "chevrons" then
			-- two ">" one after the other (movement)
			for k = 0, 1 do
				local x = -3 + k * 5
				bit(7, 2, x, -2.5, 45)
				bit(7, 2, x, 2.5, -45)
			end
		elseif kind == "plus" then
			bit(12, 2, 0, 0)
			bit(2, 12, 0, 0)
		else
			-- diamond outline with a dot in the middle
			local d = H.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(9, 9),
				Rotation = 45,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 4,
			}, holder)
			H.corner(d, 2)
			H.stroke(d, T.ACCENT, 2, 0)
			bit(3, 3, 0, 0)
		end
		return holder
	end

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
		}, mainPage)
		H.corner(panel, 6)
		H.stroke(panel, T.BORDER, 1, 0)

		-- title bar
		headerIcon(panel, def.icon)
		H.label(panel, def.title, UDim2.fromOffset(36, 0), UDim2.new(1, -48, 0, HEAD),
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

	---------------------------------------------------------------------
	-- EXTRAS PAGE: built by misc2.lua
	---------------------------------------------------------------------
	local extrasHandle = nil
	local extrasHolder = H.new("Frame", {
		Name = "ExtrasBody",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, extrasPage)

	local extrasMod = nil
	if type(ctx) == "table" then
		extrasMod = ctx.ExtrasModule
	end

	if type(extrasMod) == "table" and type(extrasMod.build) == "function" then
		local ok, res = pcall(extrasMod.build, extrasHolder, T, H, ctx)
		if ok then
			if type(res) == "table" then
				extrasHandle = res
			end
		else
			warn("[Y1] misc2.lua failed: " .. tostring(res))
			local msg = tostring(res)
			if #msg > 200 then
				msg = string.sub(msg, 1, 197) .. "..."
			end
			local t1 = H.label(extrasHolder, "Extras failed to build", UDim2.new(0, 0, 0.5, -24), UDim2.new(1, 0, 0, 22),
				Enum.Font.GothamBold, 16, T.TEXT_COLOR, Enum.TextXAlignment.Center)
			local t2 = H.label(extrasHolder, msg, UDim2.new(0, 20, 0.5, 2), UDim2.new(1, -40, 0, 50),
				Enum.Font.GothamMedium, 12, T.WARN, Enum.TextXAlignment.Center)
			t2.TextWrapped = true
			t2.TextTruncate = Enum.TextTruncate.None
			t2.TextYAlignment = Enum.TextYAlignment.Top
			t1.ZIndex = 2
		end
	else
		H.label(extrasHolder, "misc2.lua is not loaded", UDim2.new(0, 0, 0.5, -10), UDim2.new(1, 0, 0, 20),
			Enum.Font.GothamMedium, 12, T.DIM_TEXT, Enum.TextXAlignment.Center)
	end

	---------------------------------------------------------------------
	-- SWITCHER: tiny "Main | Extras" pill at the bottom middle
	---------------------------------------------------------------------
	local switcher = H.new("Frame", {
		Name = "Switcher",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.fromOffset(SW_W, SW_H),
		BackgroundColor3 = T.SIDEBAR_BG,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, root)
	H.corner(switcher, 5)
	H.stroke(switcher, T.BORDER, 1, 0)

	-- flat grey block under the active option, with the same small red bar the bottom tab bar uses
	local indicator = H.new("Frame", {
		Name = "Indicator",
		Position = UDim2.new(0, 3, 0, 3),
		Size = UDim2.new(0.5, -6, 1, -6),
		BackgroundColor3 = T.HOVER_GREY,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		ZIndex = 6,
	}, switcher)
	H.corner(indicator, 3)
	local bar = H.new("Frame", {
		Name = "RedBar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.fromOffset(20, 2),
		BackgroundColor3 = T.ACCENT,
		BorderSizePixel = 0,
		ZIndex = 7,
	}, indicator)
	H.corner(bar, 1)

	local current = "Main"
	local token = 0
	local btns = {}

	local function paintButtons()
		for name, b in pairs(btns) do
			local c = T.DIM_TEXT
			if name == current then
				c = T.TEXT_COLOR
			end
			TweenService:Create(b, T.FAST, { TextColor3 = c }):Play()
		end
	end

	local function show(name)
		if name == current then
			return
		end
		if name ~= "Main" and name ~= "Extras" then
			return
		end
		current = name
		token = token + 1
		local tk = token

		local nxt = mainPage
		local prv = extrasPage
		local pos = UDim2.new(0, 3, 0, 3)
		if name == "Extras" then
			nxt = extrasPage
			prv = mainPage
			pos = UDim2.new(0.5, 3, 0, 3)
		end

		TweenService:Create(indicator, T.SMOOTH, { Position = pos }):Play()
		paintButtons()

		TweenService:Create(prv, T.FAST, { GroupTransparency = 1 }):Play()
		task.delay(0.14, function()
			if tk == token then
				prv.Visible = false
			end
		end)
		nxt.Position = UDim2.fromOffset(0, 8)
		nxt.GroupTransparency = 1
		nxt.Visible = true
		TweenService:Create(nxt, T.SMOOTH, { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 }):Play()
	end

	local function makeButton(name, x)
		local b = H.new("TextButton", {
			Name = name .. "Btn",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(x, 0, 0, 0),
			Size = UDim2.new(0.5, 0, 1, 0),
			Font = Enum.Font.GothamMedium,
			Text = name,
			TextSize = 12,
			TextColor3 = T.DIM_TEXT,
			ZIndex = 8,
		}, switcher)
		b.MouseEnter:Connect(function()
			if name ~= current then
				TweenService:Create(b, T.FAST, { TextColor3 = T.ICON_HOVER }):Play()
			end
		end)
		b.MouseLeave:Connect(function()
			paintButtons()
		end)
		b.Activated:Connect(function()
			show(name)
		end)
		btns[name] = b
	end
	makeButton("Main", 0)
	makeButton("Extras", 0.5)
	paintButtons()

	-- let other code reach the panels / switch pages
	if type(ctx) == "table" and ctx.Win then
		ctx.Win.MiscPanels = bodies
		ctx.Win.MiscShow = function(name)
			show(name)
		end
	end

	return {
		Panels = bodies,
		Show = show,
		Unload = function()
			if extrasHandle and type(extrasHandle.Unload) == "function" then
				pcall(extrasHandle.Unload)
			end
			if root and root.Parent then
				root:Destroy()
			end
		end,
	}
end

return Misc1
