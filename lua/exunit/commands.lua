local runner = require("exunit.runner")

local RUNNER_ID = "mix test"

local M = {}

function M.test_all()
	runner.run({ id = RUNNER_ID, cmd = "mix test --max-failures=1 --warnings-as-errors" })
end

function M.test_current()
	local current_file = vim.fn.expand("%:.")
	runner.run({ id = RUNNER_ID, cmd = "mix test " .. current_file })
end

function M.test_current_trace()
	local current_file = vim.fn.expand("%:.")
	runner.run({ id = RUNNER_ID, cmd = "mix test " .. current_file .. " --trace" })
end

function M.test_under_cursor()
	local current_file = vim.fn.expand("%:.")
	local current_line = vim.fn.line(".")
	local file_line = string.format("%s:%d", current_file, current_line)
	runner.run({ id = RUNNER_ID, cmd = "mix test " .. file_line })
end

function M.test_last()
	runner.run_last(RUNNER_ID)
end

return M
