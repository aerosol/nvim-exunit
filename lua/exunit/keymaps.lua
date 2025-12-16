local M = {}

function M.setup_keymaps(commands, opts)
	if opts.own_keymaps then
		return
	end

	local test_mappings = {
		{ "n", "ta", commands.test_all, "ExUnit: Test all" },
		{ "n", "tA", commands.test_all_no_limit, "ExUnit: Test all (no limit)" },
		{ "n", "tf", commands.test_current, "ExUnit: Test current file" },
		{ "n", "tF", commands.test_current_trace, "ExUnit: Test current file with trace" },
		{ "n", "tt", commands.test_under_cursor, "ExUnit: Test under cursor" },
		{ "n", "tl", commands.test_last, "ExUnit: Test last" },
		{ "n", "gto", commands.goto_output, "ExUnit: Go to output" },
	}

	for _, mapping in ipairs(test_mappings) do
		vim.keymap.set(mapping[1], mapping[2], mapping[3], { desc = mapping[4] })
	end
end

return M
