local ui = require("exunit.ui")
local config = require("exunit.config")

describe("ui", function()
	before_each(function()
		package.loaded["exunit.ui"] = nil
		package.loaded["exunit.runner"] = nil
		package.loaded["exunit.config"] = nil
		ui = require("exunit.ui")
		config = require("exunit.config")
	end)

	describe("statusline", function()
		it("should return empty string for default status", function()
			local status = {
				running = false,
				exit_code = nil,
			}
			local result = ui.statusline(status, config.defaults)
			assert.equals("", result)
		end)

		it("should return success icon when exit code is 0", function()
			local status = {
				running = false,
				exit_code = 0,
			}
			local result = ui.statusline(status, config.defaults)
			assert.equals("[ExUnit " .. config.defaults.success_icon .. " ]", result)
		end)

		it("should return error icon with exit code when failed", function()
			local status = {
				running = false,
				exit_code = 1,
			}
			local result = ui.statusline(status, config.defaults)
			assert.equals("[ExUnit " .. config.defaults.failure_icon .. " exit:1]", result)
		end)

		it("should return running icon when job is running", function()
			local status = {
				running = true,
			}
			local result = ui.statusline(status, config.defaults)
			assert.is_true(result:match("%[ExUnit .+%]") ~= nil)
		end)
	end)

	describe("switch_to_output_tab", function()
		it("should notify when no test has been run", function()
			local runner = require("exunit.runner")
			runner.last_status = nil
			runner.current_job = nil

			local notified = false
			local old_notify = vim.notify
			vim.notify = function(msg, level)
				if msg == "No test output available" then
					notified = true
				end
			end

			local result = ui.switch_to_output_tab()

			vim.notify = old_notify

			assert.is_false(result)
			assert.is_true(notified)
		end)

		it("should notify when output buffer does not exist", function()
			local runner = require("exunit.runner")
			runner.last_status = { id = "mix test" }

			local old_fn = vim.fn
			vim.fn = setmetatable({
				bufnr = function()
					return -1
				end,
			}, { __index = old_fn })

			local notified = false
			local old_notify = vim.notify
			vim.notify = function(msg, level)
				if msg == "Test output tab not found" then
					notified = true
				end
			end

			local result = ui.switch_to_output_tab()

			vim.notify = old_notify
			vim.fn = old_fn

			assert.is_false(result)
			assert.is_true(notified)
		end)

		it("should switch to output tab when it exists", function()
			local runner = require("exunit.runner")
			runner.last_status = { id = "mix test" }

			local old_fn = vim.fn
			local old_api = vim.api
			local switched_to_tab = false
			local switched_to_win = false

			vim.fn = setmetatable({
				bufnr = function()
					return 5
				end,
			}, { __index = old_fn })

			vim.api = setmetatable({
				nvim_list_tabpages = function()
					return { 1, 2 }
				end,
				nvim_tabpage_list_wins = function(tabnr)
					if tabnr == 2 then
						return { 10, 11 }
					end
					return { 1, 2 }
				end,
				nvim_win_get_buf = function(win)
					if win == 11 then
						return 5
					end
					return 1
				end,
				nvim_set_current_tabpage = function(tabnr)
					switched_to_tab = tabnr == 2
				end,
				nvim_set_current_win = function(win)
					switched_to_win = win == 11
				end,
			}, { __index = old_api })

			local result = ui.switch_to_output_tab()

			vim.fn = old_fn
			vim.api = old_api

			assert.is_true(result)
			assert.is_true(switched_to_tab)
			assert.is_true(switched_to_win)
		end)
	end)
end)
