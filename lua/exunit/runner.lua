local ui = require("exunit.ui")
local parser = require("exunit.parser")
local status_builder = require("exunit.status")

local exunit

local M = {
	last = {},
	current_job = nil,
	last_status = nil,
}

function M.status()
	if M.current_job and M.current_job.running then
		return status_builder.create_running_status(M.current_job)
	elseif M.last_status then
		return status_builder.create_completed_status(M.last_status)
	else
		return status_builder.create_empty_status()
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

	M.last_status = nil
	M.current_job = {
		running = true,
		cmd = cmd,
		id = id,
	}

	local function on_exit(job_id, exit_code, event_type)
		if M.current_job and M.current_job.job_id == job_id then
			M.current_job.running = false

			local output = ""
			local bnr = vim.fn.bufnr(name)
			if bnr > 0 and vim.api.nvim_buf_is_valid(bnr) then
				local lines = vim.api.nvim_buf_get_lines(bnr, 0, -1, false)
				output = table.concat(lines, "\n")
			end

			local locations = parser.parse_locations(output)
			exunit = exunit or require("exunit")
			parser.populate_loclist(locations, exunit.config)
			ui.place_signs(locations, exunit.config)

			M.last_status = {
				code = exit_code,
				cmd = cmd,
				id = id,
				output = output,
				locations = locations,
			}
			if exit_code == 0 then
				ui.notify_success(label, exunit.config)
			else
				ui.notify_failure(label, exunit.config)
			end
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
