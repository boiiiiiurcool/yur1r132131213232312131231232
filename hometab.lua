-- hometab.lua  (Y1 Home tab content, separate module)
-- ASCII only, conservative syntax (no += and no continue).
--
-- Builds the Home screen INTO a frame (the Home tab of ui.lua). It does not make its own window.
-- It is empty for now: while nothing is built into the page, the window shows its
-- "Nothing here yet" message by itself. Add your content inside build().
--
--   build(container, T, H, ctx)
--     container = the Body frame of the Home tab
--     T = theme table (T.BG, T.WELL, T.BORDER, T.TEXT_COLOR, T.DIM_TEXT, T.CALM_RED, T.GOOD, T.BAD ...)
--     H = helpers { new, corner, stroke, label }
--     ctx = a copy of opts.Home plus ctx.Win (the window), ctx.Theme and ctx.Helpers
--   It may return { Unload = function() end }, which is called when the window unloads.

local HomeTab = {}

function HomeTab.build(container, T, H, ctx)
	-- nothing here yet

	return {
		Unload = function()
		end,
	}
end

return HomeTab
