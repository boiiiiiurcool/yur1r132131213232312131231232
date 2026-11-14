-- hometab.lua  (Y1 Home tab content, separate module)
-- ASCII only, conservative syntax (no += and no continue).
--
-- Builds the Home screen INTO a frame (the Home tab of ui.lua). It does not make its own window.
--
-- Shows, centred on the page:
--   * a greeting that follows the time on this device:
--       05:00 - 11:59  "Good morning, <name>"
--       12:00 - 17:59  "Good afternoon, <name>"
--       18:00 - 04:59  "Good night, <name>"
--     <name> is the yur1 account name from the login (main.lua puts it in getgenv().Y1_SESSION.username).
--   * under it, in tiny and barely visible text:  detected game, <game name>
--   * at the TOP of the page:  "Key expires in, 3d 4h" (counts down live; "Lifetime key" for a lifetime key).
--     It reads key_expires_at / lifetime from getgenv().Y1_SESSION (the login answer).
--
--   build(container, T, H, ctx)
--     container = the Body frame of the Home tab
--     T = theme table, H = helpers { new, corner, stroke, label }
--     ctx = a copy of opts.Home plus ctx.Win (the window), ctx.Theme and ctx.Helpers
--   It returns { Unload = fn }, which the window calls when it unloads.

local HomeTab = {}

function HomeTab.build(container, T, H, ctx)
	local MarketplaceService = game:GetService("MarketplaceService")
	local new = H.new

	local alive = true

	-- the account name from the login
	local function accountName()
		local ok, genv = pcall(getgenv)
		if ok and type(genv) == "table" and type(genv.Y1_SESSION) == "table" then
			local n = genv.Y1_SESSION.username
			if type(n) == "string" and n ~= "" then
				return n
			end
		end
		return nil
	end

	-- the greeting word for the current hour on this device
	local function greetingWord()
		local hour = tonumber(os.date("%H")) or 12
		if hour >= 5 and hour < 12 then
			return "Good morning"
		elseif hour >= 12 and hour < 18 then
			return "Good afternoon"
		end
		return "Good night"
	end

	-- the name goes into rich text, so these characters must be escaped
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

	-- the key expiry from the login: mode "lifetime", "timed" (target = the os.clock() moment it ends) or "none"
	local keyMode = "none"
	local keyTarget = 0
	do
		local ok, genv = pcall(getgenv)
		if ok and type(genv) == "table" and type(genv.Y1_SESSION) == "table" then
			local sess = genv.Y1_SESSION
			if sess.lifetime == true then
				keyMode = "lifetime"
			elseif type(sess.key_expires_at) == "string" then
				local left = secondsUntil(sess.key_expires_at)
				if left ~= nil then
					keyMode = "timed"
					keyTarget = os.clock() + left
				end
			end
		end
	end

	local root = new("Frame", {
		Name = "HomeRoot",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -40, 0, 74),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, container)

	local greeting = new("TextLabel", {
		Name = "Greeting",
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "",
		TextSize = 30,
		TextColor3 = T.TEXT_COLOR,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		RichText = true,
	}, root)

	-- tiny, barely visible
	local detected = new("TextLabel", {
		Name = "DetectedGame",
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = "",
		TextSize = 10,
		TextColor3 = T.DIM_TEXT,
		TextTransparency = 0.55,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, root)

	-- TOP of the page: "Key expires in, <time>" (the label for the time is dim, the time itself is white)
	local keyLine = new("TextLabel", {
		Name = "KeyExpires",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.new(1, -40, 0, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "",
		TextSize = 12,
		TextColor3 = T.DIM_TEXT,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		RichText = true,
		Visible = false,
	}, container)

	local lastKeyText = nil
	local function paintKey()
		local text = nil
		if keyMode == "lifetime" then
			text = "<font color=\"rgb(232,232,236)\">Lifetime key</font>"
		elseif keyMode == "timed" then
			local left = keyTarget - os.clock()
			if left <= 0 then
				text = "<font color=\"rgb(232,232,236)\">Key expired</font>"
			else
				text = "Key expires in, <font color=\"rgb(232,232,236)\">" .. formatLeft(left) .. "</font>"
			end
		end
		if text == nil then
			keyLine.Visible = false
			return
		end
		keyLine.Visible = true
		if text ~= lastKeyText then
			lastKeyText = text
			keyLine.Text = text
		end
	end
	paintKey()

	local lastText = nil
	local function paintGreeting()
		local word = greetingWord()
		local name = accountName()
		local text = word
		if name then
			-- the name is in the calm red accent colour
			text = word .. ", <font color=\"rgb(196,92,92)\">" .. escape(name) .. "</font>"
		end
		if text ~= lastText then
			lastText = text
			greeting.Text = text
		end
	end
	paintGreeting()

	local function setGame(name)
		detected.Text = "detected game, " .. tostring(name)
	end
	setGame(game.Name)

	-- the real game name comes from the marketplace (in the background)
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(game.PlaceId)
		end)
		if ok and type(info) == "table" and type(info.Name) == "string" and info.Name ~= "" then
			if alive and detected.Parent then
				setGame(info.Name)
			end
		end
	end)

	-- the greeting changes by itself when the time of day changes
	task.spawn(function()
		while alive do
			task.wait(30)
			if alive and greeting.Parent then
				paintGreeting()
			end
		end
	end)

	-- the key countdown ticks every second
	task.spawn(function()
		while alive do
			task.wait(1)
			if alive and keyLine.Parent then
				paintKey()
			end
		end
	end)

	return {
		Root = root,
		Unload = function()
			alive = false
			pcall(function()
				root:Destroy()
				keyLine:Destroy()
			end)
		end,
	}
end

return HomeTab
