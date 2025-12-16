local running_index = 1

local M = {}

function M.statusline(status, config)
	config = config or require("exunit.config").defaults
	local running_icons = config.running_icons
	local failure_icon = config.failure_icon
	local success_icon = config.success_icon
	if status.running then
		running_index = running_index % #running_icons + 1
		return "[ExUnit " .. running_icons[running_index] .. "]"
	elseif status.exit_code ~= nil then
		if status.exit_code == 0 then
			return "[ExUnit " .. success_icon .. " ]"
		else
			return "[ExUnit " .. failure_icon .. " exit:" .. status.exit_code .. "]"
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

function M.open_runner_tab()
	vim.api.nvim_command("tabnew")
end

function M.go_back_to_previous_tab()
	vim.api.nvim_command("tabprev")
end

function M.notify_running(label)
	vim.notify(label, vim.log.levels.INFO)
end

function M.notify_success(label, config)
	config = config or require("exunit.config").defaults
	vim.notify(config.success_icon .. " " .. label, vim.log.levels.INFO)
end

function M.notify_failure(label, config)
	config = config or require("exunit.config").defaults
	vim.notify(config.failure_icon .. " " .. label, vim.log.levels.ERROR)
end

function M.notify_warning(message)
	vim.notify(message, vim.log.levels.WARN)
end

function M.switch_to_output_tab()
	local status = require("exunit.runner").status()
	if not status.id then
		M.notify_warning("No test output available")
		return false
	end

	local name = "ExUnit:" .. status.id
	local bnr = vim.fn.bufnr(name)

	if bnr <= 0 then
		M.notify_warning("Test output tab not found")
		return false
	end

	for _, tabnr in ipairs(vim.api.nvim_list_tabpages()) do
		local wins = vim.api.nvim_tabpage_list_wins(tabnr)
		for _, win in ipairs(wins) do
			if vim.api.nvim_win_get_buf(win) == bnr then
				vim.api.nvim_set_current_tabpage(tabnr)
				vim.api.nvim_set_current_win(win)
				return true
			end
		end
	end

	M.notify_warning("Test output tab not found")
	return false
end

local sign_group = "ExUnit"
local placed_signs = {}
local pending_signs = {}

M.placed_signs = placed_signs

local sign_augroup = vim.api.nvim_create_augroup("ExUnitSigns", { clear = true })

vim.api.nvim_create_autocmd("BufReadPost", {
	group = sign_augroup,
	callback = function(args)
		local bufnr = args.buf
		local pending = pending_signs[bufnr]
		if pending then
			for _, loc in ipairs(pending) do
				local sign_id = vim.fn.sign_place(0, sign_group, "ExUnitError", bufnr, {
					lnum = loc.line,
					priority = 10,
				})
				if sign_id > 0 then
					table.insert(placed_signs, sign_id)
				end
			end
			pending_signs[bufnr] = nil
		end
	end,
})

function M.clear_signs()
	for _, sign_id in ipairs(placed_signs) do
		vim.fn.sign_unplace(sign_group, { id = sign_id })
	end
	for i = #placed_signs, 1, -1 do
		placed_signs[i] = nil
	end
	pending_signs = {}
end

function M.place_signs(locations, config)
	config = config or require("exunit.config").defaults
	M.clear_signs()

	if not locations or #locations == 0 then
		return
	end

	vim.fn.sign_define("ExUnitError", {
		text = config.failure_icon,
		texthl = "DiagnosticError",
		numhl = "DiagnosticError",
	})

	for _, loc in ipairs(locations) do
		local full_path = vim.fn.getcwd() .. "/" .. loc.file
		local bufnr = vim.fn.bufnr(full_path)

		if bufnr == -1 then
			bufnr = vim.fn.bufadd(full_path)
		end

		if bufnr > 0 then
			if vim.api.nvim_buf_is_loaded(bufnr) then
				local sign_id = vim.fn.sign_place(0, sign_group, "ExUnitError", bufnr, {
					lnum = loc.line,
					priority = 10,
				})
				if sign_id > 0 then
					table.insert(placed_signs, sign_id)
				end
			else
				if not pending_signs[bufnr] then
					pending_signs[bufnr] = {}
				end
				table.insert(pending_signs[bufnr], loc)
			end
		end
	end
end

return M
