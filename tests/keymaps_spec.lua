local keymaps = require("exunit.keymaps")

describe("keymaps", function()
	before_each(function()
		package.loaded["exunit.keymaps"] = nil
		keymaps = require("exunit.keymaps")
	end)

	describe("setup_keymaps", function()
		it("should not set keymaps when own_keymaps is true", function()
			local keymap_called = false
			local original_keymap_set = vim.keymap.set
			vim.keymap.set = function()
				keymap_called = true
			end

			local commands = {
				test_all = function() end,
				test_current = function() end,
				test_current_trace = function() end,
				test_under_cursor = function() end,
				test_last = function() end,
			}

			keymaps.setup_keymaps(commands, { own_keymaps = true })

			vim.keymap.set = original_keymap_set
			assert.is_false(keymap_called)
		end)

		it("should set keymaps when own_keymaps is false", function()
			local keymap_count = 0
			local original_keymap_set = vim.keymap.set
			vim.keymap.set = function()
				keymap_count = keymap_count + 1
			end

			local commands = {
				test_all = function() end,
				test_all_no_limit = function() end,
				test_current = function() end,
				test_current_trace = function() end,
				test_under_cursor = function() end,
				test_last = function() end,
				goto_output = function() end,
			}

			keymaps.setup_keymaps(commands, { own_keymaps = false })

			vim.keymap.set = original_keymap_set
			assert.equals(7, keymap_count)
		end)
	end)
end)
