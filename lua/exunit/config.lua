local M = {}

M.defaults = {
	own_keymaps = false,
}

function M.setup(opts)
	return vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
