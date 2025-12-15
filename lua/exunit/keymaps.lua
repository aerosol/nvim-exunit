local M = {}

function M.setup_keymaps(commands, opts)
	if opts.own_keymaps then
		return
	end

	local keymap = vim.keymap.set
	local test_mappings = {
		ta = commands.test_all,
		tA = commands.test_all_no_limit,
		tf = commands.test_current,
		tF = commands.test_current_trace,
		tt = commands.test_under_cursor,
		tl = commands.test_last,
		gto = commands.goto_output,
	}
	for lhs, fn in pairs(test_mappings) do
		keymap("n", lhs, fn, {})
	end
end

return M
