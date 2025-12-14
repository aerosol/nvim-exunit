local RUNNING_ICONS = { "🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘" } -- Moon phase animation
local RUNNER_ID = "mix test"

local running_index = 1

local M = {
	last = {},
	current_job = nil,
	last_status = nil,
}

function M.setup(opts)
	opts = opts or {}

	if not opts.own_keymaps then
		local keymap = vim.keymap.set
		local test_mappings = {
			ta = M.test_all,
			tf = M.test_current,
			tF = M.test_current_trace,
			tt = M.test_under_cursor,
			tl = M.test_last,
		}
		for lhs, fn in pairs(test_mappings) do
			keymap("n", lhs, fn, opts)
		end
	end
end

function M.test_all()
	M.run({ id = RUNNER_ID, cmd = "mix test --max-failures=1 --warnings-as-errors" })
end

function M.test_current()
	local current_file = vim.fn.expand("%:p")
	M.run({ id = RUNNER_ID, cmd = "mix test " .. current_file })
end

function M.test_current_trace()
	local current_file = vim.fn.expand("%:p")
	M.run({ id = RUNNER_ID, cmd = "mix test " .. current_file .. " --trace" })
end

function M.test_under_cursor()
	local current_file = vim.fn.expand("%:p")
	local current_line = vim.fn.line(".")
	local file_line = string.format("%s:%d", current_file, current_line)
	M.run({ id = RUNNER_ID, cmd = "mix test " .. file_line })
end

function M.test_last()
	M.run_last(RUNNER_ID)
end

function M.status()
	if M.current_job and M.current_job.running then
		return {
			running = true,
			exit_code = nil,
			cmd = M.current_job.cmd,
			id = M.current_job.id,
		}
	elseif M.last_status then
		return {
			running = false,
			exit_code = M.last_status.code,
			cmd = M.last_status.cmd,
			id = M.last_status.id,
		}
	else
		return {
			running = false,
			exit_code = nil,
			cmd = nil,
			id = nil,
		}
	end
end

function M.statusline()
	local status = M.status()
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

function M.run_last(id)
	if M.last[id] then
		M.run(M.last[id])
	else
		vim.notify("No last command for " .. id, vim.log.levels.WARN)
	end
end

function M.run(args)
	args = args or {}
	local cmd = args.cmd
	local id = args.id or cmd

	local name = "Runner:" .. id
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
	vim.api.nvim_command("tabnew")

	M.current_job = {
		running = true,
		cmd = cmd,
		id = id,
	}

	local function on_exit(job_id, exit_code, event_type)
		M.current_job.running = false
		M.last_status = {
			code = exit_code,
			cmd = cmd,
			id = id,
		}
		if exit_code == 0 then
			vim.notify("✅ " .. cmd, vim.log.levels.INFO)
		else
			vim.notify("❌ " .. cmd, vim.log.levels.ERROR)
		end
	end

	vim.notify(cmd, vim.log.levels.INFO)
	local job_id = vim.fn.jobstart(cmd, { term = true, on_exit = on_exit })
	M.current_job.job_id = job_id
	vim.api.nvim_command("file! " .. name)

	vim.api.nvim_command("tabprev")

	M.last[id] = args
end

return M
