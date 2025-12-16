local M = {}

function M.create_running_status(job)
	return {
		running = true,
		exit_code = nil,
		cmd = job.cmd,
		id = job.id,
		output = nil,
		locations = {},
	}
end

function M.create_completed_status(last_status)
	return {
		running = false,
		exit_code = last_status.code,
		cmd = last_status.cmd,
		id = last_status.id,
		output = last_status.output,
		locations = last_status.locations or {},
	}
end

function M.create_empty_status()
	return {
		running = false,
		exit_code = nil,
		cmd = nil,
		id = nil,
		output = nil,
		locations = {},
	}
end

return M
