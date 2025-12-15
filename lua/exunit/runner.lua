local ui = require("exunit.ui")

local M = {
	last = {},
	current_job = nil,
	last_status = nil,
}

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
	ui.close_runner_buffer(name)
	ui.open_runner_tab(name)

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

	ui.go_back_to_previous_tab()

	M.last[id] = args
end

return M
