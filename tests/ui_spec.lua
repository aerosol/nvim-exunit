local ui = require("exunit.ui")

describe("ui", function()
	before_each(function()
		package.loaded["exunit.ui"] = nil
		ui = require("exunit.ui")
	end)

	describe("statusline", function()
		it("should return empty string for default status", function()
			local status = {
				running = false,
				exit_code = nil,
			}
			local result = ui.statusline(status)
			assert.equals("", result)
		end)

		it("should return success icon when exit code is 0", function()
			local status = {
				running = false,
				exit_code = 0,
			}
			local result = ui.statusline(status)
			assert.equals("[ExUnit ✅ ]", result)
		end)

		it("should return error icon with exit code when failed", function()
			local status = {
				running = false,
				exit_code = 1,
			}
			local result = ui.statusline(status)
			assert.equals("[ExUnit ❌ exit:1]", result)
		end)

		it("should return running icon when job is running", function()
			local status = {
				running = true,
			}
			local result = ui.statusline(status)
			assert.is_true(result:match("%[ExUnit .+%]") ~= nil)
		end)
	end)
end)
