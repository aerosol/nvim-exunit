local M = {}

function M.setup_keymaps(commands, opts)
	if opts.own_keymaps then
		return
	end

	local keymap = vim.keymap.set
	local test_mappings = {
		ta = commands.test_all,
		tf = commands.test_current,
		tF = commands.test_current_trace,
		tt = commands.test_under_cursor,
		tl = commands.test_last,
	}
	for lhs, fn in pairs(test_mappings) do
		keymap("n", lhs, fn, {})
	end
end

return M
