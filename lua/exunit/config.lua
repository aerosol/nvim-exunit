local M = {}

M.defaults = {
	own_keymaps = false,
	location_list_mode = "open_no_focus",
}

function M.setup(opts)
	return vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
