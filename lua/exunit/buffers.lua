local M = {}

function M.find_buffer_in_tabs(bufnr)
	for _, tabnr in ipairs(vim.api.nvim_list_tabpages()) do
		local wins = vim.api.nvim_tabpage_list_wins(tabnr)
		for _, win in ipairs(wins) do
			if vim.api.nvim_win_get_buf(win) == bufnr then
				return tabnr, win
			end
		end
	end
	return nil, nil
end

function M.close_buffer_and_tab(name)
	local bnr = vim.fn.bufnr(name)
	if bnr <= 0 then
		return
	end

	local tabnr, win = M.find_buffer_in_tabs(bnr)
	if tabnr and win then
		vim.api.nvim_set_current_tabpage(tabnr)
		vim.api.nvim_set_current_win(win)
		vim.api.nvim_command("tabclose")
	end
	vim.api.nvim_command("bdelete! " .. bnr)
end

function M.switch_to_buffer_tab(bufnr)
	local tabnr, win = M.find_buffer_in_tabs(bufnr)
	if tabnr and win then
		vim.api.nvim_set_current_tabpage(tabnr)
		vim.api.nvim_set_current_win(win)
		return true
	end
	return false
end

return M
