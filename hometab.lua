-- hometab.lua  (Y1 Home tab content, separate module)
-- ASCII only, conservative syntax (no += and no continue).
--
-- Builds the Home overview INTO a frame (the Home tab of ui.lua). It does not make its own window.
--
--   Good evening, <name>                                                         [Ready]
--   Welcome back to Y1. Here's your overview.
--
--   Account                      (icon)     Application                  (icon)
--   <name>                                  Beta 0.6
--   Lifetime membership                     Current build
--
--   Current session              (icon)
--   <game name>
--   Connected game - Session information
--
--   What's new                                                              [Beta 0.6]
--   Latest Y1 announcements and release information will appear here.
--
-- * the greeting follows the time on this device: morning 05:00-11:59, afternoon 12:00-16:59,
--   evening 17:00-20:59, night 21:00-04:59
-- * <name> is the yur1 account name from the login (getgenv().Y1_SESSION.username)
-- * membership: "Lifetime membership", or "Expires in 3d 4h" (live) for a timed key
--   (reads lifetime / key_expires_at from getgenv().Y1_SESSION)
-- * options (the Home table in main.lua is passed in as ctx):
--     Build = "Beta 0.6"                       text of the Application card and the What's new badge
--     WhatsNew = "..."                         text under What's new
--
--   build(container, T, H, ctx)  ->  { Unload = fn }

local HomeTab = {}

function HomeTab.build(container, T, H, ctx)
	ctx = ctx or {}
	local MarketplaceService = game:GetService("MarketplaceService")
	local new, corner, stroke = H.new, H.corner, H.stroke

	local alive = true
	local PAD = 16
	local buildText = tostring(ctx.Build or "Beta 0.6")
	local whatsNewText = tostring(ctx.WhatsNew or "Latest Y1 announcements and release information will appear here.")
	local DOT = "\u{00B7}"

	---------------------------------------------------------------------
	-- DATA
	---------------------------------------------------------------------
	local function getSession()
		local ok, genv = pcall(getgenv)
		if ok and type(genv) == "table" and type(genv.Y1_SESSION) == "table" then
			return genv.Y1_SESSION
		end
		return nil
	end

	local function accountName()
		local s = getSession()
		if s and type(s.username) == "string" and s.username ~= "" then
			return s.username
		end
		return nil
	end

	local function greetingWord()
		local hour = tonumber(os.date("%H")) or 12
		if hour >= 5 and hour < 12 then
			return "Good morning"
		elseif hour >= 12 and hour < 17 then
			return "Good afternoon"
		elseif hour >= 17 and hour < 21 then
			return "Good evening"
		end
		return "Good night"
	end

	local function escape(s)
		s = string.gsub(s, "&", "&amp;")
		s = string.gsub(s, "<", "&lt;")
		s = string.gsub(s, ">", "&gt;")
		return s
	end

	-- how many seconds until an ISO date like 2026-12-01T10:00:00Z (negative = already past), nil if unreadable
	local function secondsUntil(stamp)
		if type(stamp) ~= "string" then
			return nil
		end
		local y, mo, d, h, mi, sec = string.match(stamp, "(%d+)-(%d+)-(%d+)[T ](%d+):(%d+):(%d+)")
		if y == nil then
			return nil
		end
		local ok, res = pcall(function()
			local t = os.time({
				year = tonumber(y), month = tonumber(mo), day = tonumber(d),
				hour = tonumber(h), min = tonumber(mi), sec = tonumber(sec),
			})
			local off = os.time(os.date("*t")) - os.time(os.date("!*t"))
			return (t + off) - os.time()
		end)
		if ok and type(res) == "number" then
			return res
		end
		return nil
	end

	-- 273600 -> "3d 4h", 15120 -> "4h 12m", 725 -> "12m 5s"
	local function formatLeft(sec)
		sec = math.floor(sec)
		local d = math.floor(sec / 86400)
		local h = math.floor((sec % 86400) / 3600)
		local m = math.floor((sec % 3600) / 60)
		local r = sec % 60
		if d > 0 then
			return d .. "d " .. h .. "h"
		elseif h > 0 then
			return h .. "h " .. m .. "m"
		elseif m > 0 then
			return m .. "m " .. r .. "s"
		end
		return r .. "s"
	end

	-- membership from the login: "lifetime", "timed" (target = the os.clock() moment it ends) or "none"
	local memberMode = "none"
	local memberTarget = 0
	do
		local s = getSession()
		if s then
			if s.lifetime == true then
				memberMode = "lifetime"
			elseif type(s.key_expires_at) == "string" then
				local left = secondsUntil(s.key_expires_at)
				if left ~= nil then
					memberMode = "timed"
					memberTarget = os.clock() + left
				end
			end
		end
	end

	---------------------------------------------------------------------
	-- BUILDING BLOCKS
	---------------------------------------------------------------------
	local function text(parent, str, pos, size, font, textSize, color, align)
		return new("TextLabel", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = pos,
			Size = size,
			Font = font,
			Text = str,
			TextSize = textSize,
			TextColor3 = color,
			TextXAlignment = align or Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, parent)
	end

	-- small line icons (16 x 16, drawn with frames, in the icon colour)
	local function iconPerson(h)
		local head = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 1),
			Size = UDim2.fromOffset(6, 6),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, h)
		corner(head, 100)
		stroke(head, T.ICON, 1.5, 0)
		local clip = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, 0),
			Size = UDim2.fromOffset(13, 6),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
		}, h)
		local body = new("Frame", {
			Size = UDim2.fromOffset(13, 13),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, clip)
		corner(body, 100)
		stroke(body, T.ICON, 1.5, 0)
	end

	local function iconWindow(h)
		local box = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(13, 11),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, h)
		corner(box, 3)
		stroke(box, T.ICON, 1.5, 0)
		local bar = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0.5, -2.5),
			Size = UDim2.fromOffset(13, 1.5),
			BackgroundColor3 = T.ICON,
			BorderSizePixel = 0,
		}, h)
	end

	local function iconClock(h)
		local face = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(12, 12),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, h)
		corner(face, 100)
		stroke(face, T.ICON, 1.5, 0)
		local up = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(1.5, 4),
			BackgroundColor3 = T.ICON,
			BorderSizePixel = 0,
		}, h)
		local right = new("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(3.5, 1.5),
			BackgroundColor3 = T.ICON,
			BorderSizePixel = 0,
		}, h)
	end

	local root = new("Frame", {
		Name = "HomeRoot",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, container)

	-- one block: bold title with an icon on the right, a big value, a small caption.
	-- xs / xo / ws / wo place the column, y is the top. Returns the value and caption labels.
	local function section(xs, xo, ws, wo, y, title, iconFn)
		local f = new("Frame", {
			Name = title,
			Position = UDim2.new(xs, xo, 0, y),
			Size = UDim2.new(ws, wo, 0, 72),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, root)
		text(f, title, UDim2.fromOffset(0, 0), UDim2.new(1, -26, 0, 20), Enum.Font.GothamBold, 14, T.TEXT_COLOR)
		local ico = new("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 2),
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, f)
		iconFn(ico)
		local value = text(f, "", UDim2.fromOffset(0, 26), UDim2.new(1, 0, 0, 26), Enum.Font.GothamBold, 19, T.TEXT_COLOR)
		local cap = text(f, "", UDim2.fromOffset(0, 54), UDim2.new(1, 0, 0, 16), Enum.Font.GothamMedium, 12, T.ICON)
		return value, cap
	end

	---------------------------------------------------------------------
	-- HEADER: greeting, subtitle, Ready pill
	---------------------------------------------------------------------
	local greeting = new("TextLabel", {
		Name = "Greeting",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(PAD, 12),
		Size = UDim2.new(1, -(PAD * 2 + 64), 0, 28),
		Font = Enum.Font.GothamBold,
		Text = "",
		TextSize = 22,
		TextColor3 = T.TEXT_COLOR,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		RichText = true,
	}, root)

	text(root, "Welcome back to Y1. Here's your overview.", UDim2.fromOffset(PAD, 42), UDim2.new(1, -PAD * 2, 0, 16),
		Enum.Font.GothamMedium, 11, T.ICON)

	local pill = new("Frame", {
		Name = "ReadyPill",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -PAD, 0, 16),
		Size = UDim2.fromOffset(48, 20),
		BackgroundColor3 = Color3.fromRGB(22, 40, 30),
		BorderSizePixel = 0,
	}, root)
	corner(pill, 100)
	stroke(pill, Color3.fromRGB(44, 96, 66), 1, 0)
	text(pill, "Ready", UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), Enum.Font.GothamBold, 11, T.GOOD,
		Enum.TextXAlignment.Center)

	---------------------------------------------------------------------
	-- ROW 1: Account | Application
	---------------------------------------------------------------------
	local accValue, accCap = section(0, PAD, 0.5, -(PAD + 8), 84, "Account", iconPerson)
	local appValue, appCap = section(0.5, 8, 0.5, -(PAD + 8), 84, "Application", iconWindow)

	---------------------------------------------------------------------
	-- ROW 2: Current session
	---------------------------------------------------------------------
	local sesValue, sesCap = section(0, PAD, 1, -PAD * 2, 172, "Current session", iconClock)

	---------------------------------------------------------------------
	-- ROW 3: What's new
	---------------------------------------------------------------------
	local newsY = 262
	text(root, "What's new", UDim2.fromOffset(PAD, newsY), UDim2.new(1, -(PAD * 2 + 80), 0, 20), Enum.Font.GothamBold, 14,
		T.TEXT_COLOR)
	local badge = new("Frame", {
		Name = "BuildBadge",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -PAD, 0, newsY + 1),
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.POPUP_BG,
		BorderSizePixel = 0,
	}, root)
	corner(badge, 100)
	new("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9) }, badge)
	new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		Font = Enum.Font.GothamBold,
		Text = buildText,
		TextSize = 10,
		TextColor3 = T.TEXT_COLOR,
	}, badge)
	text(root, whatsNewText, UDim2.fromOffset(PAD, newsY + 28), UDim2.new(1, -PAD * 2, 0, 32), Enum.Font.GothamMedium, 12,
		T.ICON).TextWrapped = true

	---------------------------------------------------------------------
	-- FILL IN
	---------------------------------------------------------------------
	local lastGreeting = nil
	local function paintGreeting()
		local word = greetingWord()
		local name = accountName()
		local t = word
		if name then
			t = word .. ", <font color=\"rgb(196,92,92)\">" .. escape(name) .. "</font>"
		end
		if t ~= lastGreeting then
			lastGreeting = t
			greeting.Text = t
		end
	end

	local function paintMember()
		local t = "Member"
		if memberMode == "lifetime" then
			t = "Lifetime membership"
		elseif memberMode == "timed" then
			local left = memberTarget - os.clock()
			if left <= 0 then
				t = "Membership expired"
			else
				t = "Expires in " .. formatLeft(left)
			end
		end
		accCap.Text = t
	end

	paintGreeting()
	accValue.Text = accountName() or "Guest"
	paintMember()
	appValue.Text = buildText
	appCap.Text = "Current build"
	sesValue.Text = game.Name
	sesCap.Text = "Connected game " .. DOT .. " Session information"

	-- the real game name comes from the marketplace (in the background)
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(game.PlaceId)
		end)
		if ok and type(info) == "table" and type(info.Name) == "string" and info.Name ~= "" then
			if alive and sesValue.Parent then
				sesValue.Text = info.Name
			end
		end
	end)

	-- the greeting follows the time of day, the membership counts down
	task.spawn(function()
		local n = 0
		while alive do
			task.wait(1)
			if not alive or not root.Parent then
				return
			end
			n = n + 1
			if memberMode == "timed" then
				paintMember()
			end
			if n % 30 == 0 then
				paintGreeting()
			end
		end
	end)

	return {
		Root = root,
		Unload = function()
			alive = false
			pcall(function()
				root:Destroy()
			end)
		end,
	}
end

return HomeTab
