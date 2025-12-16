local runner = require("exunit.runner")

describe("runner", function()
	local ui_mock

	before_each(function()
		package.loaded["exunit.ui"] = nil
		package.loaded["exunit.runner"] = nil

		ui_mock = {
			close_runner_buffer = function() end,
			open_runner_tab = function() end,
			go_back_to_previous_tab = function() end,
			notify_running = function() end,
			notify_success = function() end,
			notify_failure = function() end,
			notify_warning = function() end,
			place_signs = function() end,
		}

		package.preload["exunit.ui"] = function()
			return ui_mock
		end

		runner = require("exunit.runner")
	end)

	after_each(function()
		package.preload["exunit.ui"] = nil
	end)

	describe("status", function()
		it("should return default status when no job has run", function()
			local status = runner.status()
			assert.is_false(status.running)
			assert.is_nil(status.exit_code)
			assert.is_nil(status.cmd)
			assert.is_nil(status.id)
			assert.is_nil(status.output)
			assert.are.same({}, status.locations)
		end)

		it("should clear previous failed status when new test starts", function()
			local old_api = vim.api
			local old_fn = vim.fn

			vim.api = setmetatable({
				nvim_command = function() end,
			}, { __index = old_api })

			vim.fn = setmetatable({
				jobstart = function()
					return 1
				end,
			}, { __index = old_fn })

			vim.notify = function() end

			runner.last_status = {
				code = 1,
				cmd = "mix test",
				id = "test",
				output = "test output",
				locations = {},
			}

			runner.run({ cmd = "mix test", id = "test" })

			vim.api = old_api
			vim.fn = old_fn

			local status = runner.status()
			assert.is_true(status.running)
			assert.is_nil(status.exit_code)
		end)

		it("should ignore on_exit callback from old job when new job is running", function()
			local old_api = vim.api
			local old_fn = vim.fn
			local on_exit_callbacks = {}

			vim.api = setmetatable({
				nvim_command = function() end,
				nvim_buf_is_valid = function()
					return false
				end,
			}, { __index = old_api })

			vim.fn = setmetatable({
				jobstart = function(cmd, opts)
					table.insert(on_exit_callbacks, opts.on_exit)
					return #on_exit_callbacks
				end,
				bufnr = function()
					return -1
				end,
			}, { __index = old_fn })

			vim.notify = function() end

			runner.run({ cmd = "mix test 1", id = "test1" })
			local old_job_exit = on_exit_callbacks[1]

			runner.run({ cmd = "mix test 2", id = "test2" })

			old_job_exit(1, 1, "exit")

			local status = runner.status()
			assert.is_true(status.running)
			assert.equals("mix test 2", status.cmd)
			assert.is_nil(runner.last_status)

			vim.api = old_api
			vim.fn = old_fn
		end)
	end)

	describe("run_last", function()
		it("should notify when no last command exists", function()
			local notified = false
			ui_mock.notify_warning = function(msg)
				notified = true
			end

			runner.run_last("nonexistent")

			assert.is_true(notified)
		end)
	end)

	describe("run", function()
		it("should rename buffer after jobstart", function()
			local commands_executed = {}
			local jobstart_index = nil
			local old_api = vim.api
			local old_fn = vim.fn

			vim.api = setmetatable({
				nvim_command = function(cmd)
					table.insert(commands_executed, { type = "command", value = cmd })
				end,
			}, { __index = old_api })

			vim.fn = setmetatable({
				jobstart = function(cmd, opts)
					jobstart_index = #commands_executed + 1
					table.insert(commands_executed, { type = "jobstart", value = cmd })
					return 1
				end,
			}, { __index = old_fn })

			vim.notify = function() end

			runner.run({ cmd = "mix test", id = "test", label = "Test" })

			vim.api = old_api
			vim.fn = old_fn

			local file_command_index = nil
			for i, entry in ipairs(commands_executed) do
				if entry.type == "command" and entry.value:match("^file! ") then
					file_command_index = i
					break
				end
			end

			assert.is_not_nil(file_command_index, "file! command should be called")
			assert.is_not_nil(jobstart_index, "jobstart should be called")
			assert.is_true(
				file_command_index > jobstart_index,
				"file! command should be called after jobstart"
			)
		end)

		it("should reuse existing tab by closing buffer with same name", function()
			local close_called = false
			local close_name = nil

			ui_mock.close_runner_buffer = function(name)
				close_called = true
				close_name = name
			end

			local old_api = vim.api
			local old_fn = vim.fn

			vim.api = setmetatable({
				nvim_command = function() end,
			}, { __index = old_api })

			vim.fn = setmetatable({
				jobstart = function()
					return 1
				end,
			}, { __index = old_fn })

			vim.notify = function() end

			runner.run({ cmd = "mix test", id = "test1" })

			vim.api = old_api
			vim.fn = old_fn

			assert.is_true(close_called)
			assert.equals("ExUnit:test1", close_name)
		end)

		it("should use consistent buffer name format", function()
			local file_commands = {}
			local old_api = vim.api
			local old_fn = vim.fn

			vim.api = setmetatable({
				nvim_command = function(cmd)
					if cmd:match("^file! ") then
						table.insert(file_commands, cmd)
					end
				end,
			}, { __index = old_api })

			vim.fn = setmetatable({
				jobstart = function()
					return 1
				end,
			}, { __index = old_fn })

			vim.notify = function() end

			runner.run({ cmd = "mix test", id = "my-test" })
			runner.run({ cmd = "mix test", id = "my-test" })

			vim.api = old_api
			vim.fn = old_fn

			assert.equals(2, #file_commands)
			assert.equals("file! ExUnit:my-test", file_commands[1])
			assert.equals("file! ExUnit:my-test", file_commands[2])
		end)
	end)
end)
