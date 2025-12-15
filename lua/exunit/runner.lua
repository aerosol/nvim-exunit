local ui = require("exunit.ui")
local parser = require("exunit.parser")

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
			output = nil,
			locations = {},
		}
	elseif M.last_status then
		return {
			running = false,
			exit_code = M.last_status.code,
			cmd = M.last_status.cmd,
			id = M.last_status.id,
			output = M.last_status.output,
			locations = M.last_status.locations or {},
		}
	else
		return {
			running = false,
			exit_code = nil,
			cmd = nil,
			id = nil,
			output = nil,
			locations = {},
		}
	end
end

function M.run_last(id)
	if M.last[id] then
		M.run(M.last[id])
	else
		ui.notify_warning("No last command for " .. id)
	end
end

function M.run(args)
	args = args or {}
	local cmd = args.cmd
	local id = args.id or cmd
	local label = args.label or cmd

	local name = "ExUnit:" .. id
	ui.close_runner_buffer(name)
	ui.open_runner_tab()

	M.current_job = {
		running = true,
		cmd = cmd,
		id = id,
	}

	local function on_exit(job_id, exit_code, event_type)
		M.current_job.running = false

		local output = ""
		local bnr = vim.fn.bufnr(name)
		if bnr > 0 and vim.api.nvim_buf_is_valid(bnr) then
			local lines = vim.api.nvim_buf_get_lines(bnr, 0, -1, false)
			output = table.concat(lines, "\n")
		end

		local locations = parser.parse_locations(output)
		local exunit = require("exunit")
		parser.populate_loclist(locations, exunit.config)
		ui.place_signs(locations)

		M.last_status = {
			code = exit_code,
			cmd = cmd,
			id = id,
			output = output,
			locations = locations,
		}
		if exit_code == 0 then
			ui.notify_success(label)
		else
			ui.notify_failure(label)
		end
	end

	ui.notify_running(label)
	local job_id = vim.fn.jobstart(cmd, { term = true, on_exit = on_exit })
	M.current_job.job_id = job_id

	vim.api.nvim_command("file! " .. name)

	ui.go_back_to_previous_tab()

	M.last[id] = args
end

return M
