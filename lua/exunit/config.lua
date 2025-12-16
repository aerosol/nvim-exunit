local M = {}

M.defaults = {
	own_keymaps = false,
	location_list_mode = "open_no_focus",
	running_icons = { "🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘" },
	failure_icon = "❌",
	success_icon = "✅",
}

function M.setup(opts)
	return vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
