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
