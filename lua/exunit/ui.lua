local RUNNING_ICONS = { "🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘" }

local running_index = 1

local M = {}

function M.statusline(status)
	if status.running then
		running_index = running_index % #RUNNING_ICONS + 1
		return "[Runner " .. RUNNING_ICONS[running_index] .. "]"
	elseif status.exit_code ~= nil then
		if status.exit_code == 0 then
			return "[Runner ✅ ]"
		else
			return "[Runner ❌ exit:" .. status.exit_code .. "]"
		end
	else
		return ""
	end
end

function M.close_runner_buffer(name)
	local bnr = vim.fn.bufnr(name)
	if bnr > 0 then
		for _, tabnr in ipairs(vim.api.nvim_list_tabpages()) do
			local wins = vim.api.nvim_tabpage_list_wins(tabnr)
			for _, win in ipairs(wins) do
				if vim.api.nvim_win_get_buf(win) == bnr then
					vim.api.nvim_set_current_tabpage(tabnr)
					vim.api.nvim_set_current_win(win)
					vim.api.nvim_command("tabclose")
					break
				end
			end
		end
		vim.api.nvim_command("bdelete! " .. bnr)
	end
end

function M.open_runner_tab(name)
	vim.api.nvim_command("tabnew")
	vim.api.nvim_command("file! " .. name)
end

function M.go_back_to_previous_tab()
	vim.api.nvim_command("tabprev")
end

return M
