-- settingstab.lua  (Y1 Settings tab, lives in tabs/ next to hometab.lua)
-- ASCII only, conservative syntax (no += and no continue).
--
-- ui.lua calls  SettingsModule.build(container, T, H, ctx)  (main.lua loads it as modules.SettingsTab).
--   ctx.Win = the window, ctx.HideKey = the key that hides the window (main.lua passes it, only used for the text).
-- Two panels, same look as the Misc tab:
--   Interface : Watermark switch, Unload Script button (click twice to confirm)
--   About     : account name, hide key, how long the window has been running
-- Add more rows with  addRow(panelBody, ...)  helpers below.

local SettingsTab = {}

function SettingsTab.build(container, T, H, ctx)
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
	local new, corner, stroke, label = H.new, H.corner, H.stroke, H.label
	local FAST, SMOOTH = T.FAST, T.SMOOTH

	local GAP, HEAD = 14, 38
	local BODY_PAD_X, BODY_PAD_TOP, BODY_PAD_BOTTOM = 14, 16, 18
	local SECTION_GAP, HEADER_H = 18, 28
	local BOX_PAD, BOX_GAP, ROW_H = 10, 9, 28

	local win = nil
	local hideKey = "RightShift"
	if type(ctx) == "table" then
		win = ctx.Win
		if ctx.HideKey then
			hideKey = tostring(ctx.HideKey.Name or ctx.HideKey)
		end
	end

	local root = new("Frame", {
		Name = "SettingsRoot",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, container)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, GAP),
	}, root)

	-- a panel with a title bar and a scrolling body; returns the body
	local function makePanel(order, title, badgeText)
		local panel = new("Frame", {
			Name = title .. "Panel",
			LayoutOrder = order,
			Size = UDim2.new(1 / 3, -(GAP * 2) / 3, 1, -14),
			BackgroundColor3 = T.SIDEBAR_BG,
			BorderSizePixel = 0,
			ClipsDescendants = true,
		}, root)
		corner(panel, 6)
		stroke(panel, T.BORDER, 1, 0)
		label(panel, title, UDim2.fromOffset(14, 0), UDim2.new(1, -60, 0, HEAD),
			Enum.Font.GothamBold, 14, T.TEXT_COLOR).ZIndex = 3
		local badge = new("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0, HEAD / 2),
			Size = UDim2.fromOffset(26, 20),
			BackgroundColor3 = T.CLUSTER_BG,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, panel)
		corner(badge, 4)
		stroke(badge, T.BORDER, 1, 0)
		label(badge, badgeText, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1),
			Enum.Font.GothamMedium, 12, T.ICON, Enum.TextXAlignment.Center).ZIndex = 4
		new("Frame", {
			Position = UDim2.fromOffset(0, HEAD),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = T.ACCENT,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, panel)
		local body = new("ScrollingFrame", {
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
			ElasticBehavior = Enum.ElasticBehavior.Never,
			ZIndex = 2,
		}, panel)
		new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, SECTION_GAP),
		}, body)
		new("UIPadding", {
			PaddingLeft = UDim.new(0, BODY_PAD_X),
			PaddingRight = UDim.new(0, BODY_PAD_X),
			PaddingTop = UDim.new(0, BODY_PAD_TOP),
			PaddingBottom = UDim.new(0, BODY_PAD_BOTTOM),
		}, body)
		return body
	end

	-- one section: name (+ optional switch) on top, one inset box under it. Returns { box, head, n }
	local function makeSection(body, order, title)
		local S = { n = 0 }
		local sec = new("Frame", {
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, body)
		new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 12),
		}, sec)
		S.head = new("Frame", {
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, HEADER_H),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, sec)
		label(S.head, title, UDim2.fromOffset(2, 0), UDim2.new(1, -56, 1, 0), Enum.Font.GothamBold, 14, T.TEXT_COLOR)
		S.box = new("Frame", {
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = T.WELL,
			BorderSizePixel = 0,
		}, sec)
		corner(S.box, 6)
		stroke(S.box, T.BORDER, 1, 0)
		new("UIPadding", {
			PaddingLeft = UDim.new(0, BOX_PAD), PaddingRight = UDim.new(0, BOX_PAD),
			PaddingTop = UDim.new(0, BOX_PAD), PaddingBottom = UDim.new(0, BOX_PAD),
		}, S.box)
		new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, BOX_GAP),
		}, S.box)
		function S.order()
			S.n = S.n + 1
			return S.n
		end
		return S
	end

	local function makeSwitch(row, startOn, onChange)
		local on = startOn
		local track = new("TextButton", {
			AutoButtonColor = false, Text = "",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(38, 20),
			BackgroundColor3 = T.CLUSTER_BG,
			BorderSizePixel = 0,
		}, row)
		corner(track, 100)
		stroke(track, T.BORDER, 1, 0)
		local knob = new("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = T.DIM_TEXT,
			BorderSizePixel = 0,
		}, track)
		corner(knob, 100)
		local function paint(animate)
			local pos, tc, kc = UDim2.new(0, 3, 0.5, 0), T.CLUSTER_BG, T.DIM_TEXT
			if on then
				pos, tc, kc = UDim2.new(0, 21, 0.5, 0), T.JOIN_BG, T.BLACK
			end
			if animate then
				TweenService:Create(knob, SMOOTH, { Position = pos }):Play()
			else
				knob.Position = pos
			end
			TweenService:Create(knob, FAST, { BackgroundColor3 = kc }):Play()
			TweenService:Create(track, FAST, { BackgroundColor3 = tc }):Play()
		end
		paint(false)
		track.Activated:Connect(function()
			on = not on
			paint(true)
			onChange(on)
		end)
	end

	local function toggleRow(S, title, startOn, onChange)
		local row = new("Frame", {
			LayoutOrder = S.order(),
			Size = UDim2.new(1, 0, 0, ROW_H),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, S.box)
		label(row, title, UDim2.fromOffset(0, 0), UDim2.new(1, -50, 1, 0), Enum.Font.GothamMedium, 12, T.ICON)
		makeSwitch(row, startOn, onChange)
	end

	-- name on the left, a value on the right
	local function infoRow(S, title, value)
		local row = new("Frame", {
			LayoutOrder = S.order(),
			Size = UDim2.new(1, 0, 0, ROW_H),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, S.box)
		label(row, title, UDim2.fromOffset(0, 0), UDim2.new(0.5, 0, 1, 0), Enum.Font.GothamMedium, 12, T.ICON)
		return label(row, value, UDim2.new(0.5, 0, 0, 0), UDim2.new(0.5, 0, 1, 0),
			Enum.Font.GothamMedium, 12, T.ICON_HOVER, Enum.TextXAlignment.Right)
	end

	local function buttonRow(S, text, onClick)
		local b = new("TextButton", {
			LayoutOrder = S.order(),
			AutoButtonColor = false,
			Size = UDim2.new(1, 0, 0, ROW_H),
			BackgroundColor3 = T.CLUSTER_BG,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = T.ICON_HOVER,
			Text = text,
		}, S.box)
		corner(b, 5)
		stroke(b, T.BORDER, 1, 0)
		b.MouseEnter:Connect(function()
			TweenService:Create(b, FAST, { BackgroundColor3 = T.HOVER_GREY }):Play()
		end)
		b.MouseLeave:Connect(function()
			TweenService:Create(b, FAST, { BackgroundColor3 = T.CLUSTER_BG }):Play()
		end)
		b.Activated:Connect(function()
			onClick(b)
		end)
		return b
	end

	---------------------------------------------------------------------
	-- INTERFACE
	---------------------------------------------------------------------
	local interface = makePanel(1, "Interface", "2")

	local wmSec = makeSection(interface, 1, "Watermark")
	local function findWatermark()
		if win and win.Gui then
			return win.Gui:FindFirstChild("Watermark", true)
		end
		return nil
	end
	local wmStart = findWatermark() ~= nil
	toggleRow(wmSec, "Show Watermark", wmStart, function(on)
		local wm = findWatermark()
		if wm then
			wm.Visible = on
		end
	end)
	if not wmStart then
		-- no watermark in this window (Watermark = false in main.lua), so the switch has nothing to do
		local n = label(wmSec.box, "The watermark is switched off in main.lua.", UDim2.fromOffset(0, 0),
			UDim2.new(1, 0, 0, 0), Enum.Font.Gotham, 11, T.DIM_TEXT)
		n.LayoutOrder = wmSec.order()
		n.TextWrapped = true
		n.AutomaticSize = Enum.AutomaticSize.Y
	end

	new("Frame", {
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = T.ACCENT,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
	}, interface)

	local scriptSec = makeSection(interface, 3, "Script")
	local armed = false
	local unloadBtn = nil
	unloadBtn = buttonRow(scriptSec, "Unload Script", function(b)
		if not armed then
			armed = true
			b.Text = "Click again to unload"
			b.TextColor3 = T.WARN
			task.delay(3, function()
				if armed and b.Parent then
					armed = false
					b.Text = "Unload Script"
					b.TextColor3 = T.ICON_HOVER
				end
			end)
			return
		end
		if win and type(win.Unload) == "function" then
			win:Unload()
		end
	end)

	---------------------------------------------------------------------
	-- ABOUT
	---------------------------------------------------------------------
	local about = makePanel(2, "About", "3")
	local infoSec = makeSection(about, 1, "Session")

	local account = "Guest"
	local startedAt = os.time()
	local okG, g = pcall(function()
		return getgenv()
	end)
	if okG and type(g) == "table" and type(g.Y1_SESSION) == "table" then
		if type(g.Y1_SESSION.username) == "string" and g.Y1_SESSION.username ~= "" then
			account = g.Y1_SESSION.username
		end
		if type(g.Y1_SESSION.started) == "number" then
			startedAt = g.Y1_SESSION.started
		end
	end
	infoRow(infoSec, "Account", account)
	infoRow(infoSec, "Hide Key", hideKey)
	local timeLbl = infoRow(infoSec, "Running For", "0m")

	local running = true
	local conn = nil
	local acc = 0
	conn = RunService.Heartbeat:Connect(function(dt)
		acc = acc + dt
		if acc < 1 then
			return
		end
		acc = 0
		if not running or not timeLbl.Parent then
			return
		end
		local secs = math.max(0, os.time() - startedAt)
		local h = math.floor(secs / 3600)
		local m = math.floor((secs % 3600) / 60)
		if h > 0 then
			timeLbl.Text = string.format("%dh %dm", h, m)
		else
			timeLbl.Text = string.format("%dm %ds", m, secs % 60)
		end
	end)

	local function unload()
		running = false
		if conn then
			conn:Disconnect()
			conn = nil
		end
		pcall(function()
			root:Destroy()
		end)
	end

	return { Root = root, Unload = unload }
end

return SettingsTab
