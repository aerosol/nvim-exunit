local parser = require("exunit.parser")

describe("parser", function()
	before_each(function()
		package.loaded["exunit.parser"] = nil
		parser = require("exunit.parser")
	end)

	describe("parse_locations", function()
		it("should return empty table for nil output", function()
			local result = parser.parse_locations(nil)
			assert.are.same({}, result)
		end)

		it("should return empty table for empty output", function()
			local result = parser.parse_locations("")
			assert.are.same({}, result)
		end)

		it("should extract file path and line number from test failure", function()
			local output = [[
1) test greets the world (FooTest)
test/foo_test.exs:5
Assertion with == failed
]]
			local old_fn = vim.fn
			vim.fn = setmetatable({
				getcwd = function()
					return "/tmp"
				end,
				filereadable = function(path)
					if path:match("test/foo_test%.exs$") then
						return 1
					end
					return 0
				end,
			}, { __index = old_fn })

			local result = parser.parse_locations(output)
			vim.fn = old_fn

			assert.equals(1, #result)
			assert.equals("test/foo_test.exs", result[1].file)
			assert.equals(5, result[1].line)
		end)

		it("should extract multiple locations from stacktrace", function()
			local output = [[
1) test greets the world (FooTest)
test/foo_test.exs:5
Assertion with == failed
stacktrace:
test/foo_test.exs:6: (test)
lib/foo.ex:11: Foo (module)
]]
			local old_fn = vim.fn
			vim.fn = setmetatable({
				getcwd = function()
					return "/tmp"
				end,
				filereadable = function()
					return 1
				end,
			}, { __index = old_fn })

			local result = parser.parse_locations(output)
			vim.fn = old_fn

			assert.is_true(#result >= 2)
		end)

		it("should deduplicate same file and line", function()
			local output = [[
test/foo_test.exs:5
test/foo_test.exs:5
test/foo_test.exs:5
]]
			local old_fn = vim.fn
			vim.fn = setmetatable({
				getcwd = function()
					return "/tmp"
				end,
				filereadable = function()
					return 1
				end,
			}, { __index = old_fn })

			local result = parser.parse_locations(output)
			vim.fn = old_fn

			assert.equals(1, #result)
		end)

		it("should handle .ex and .exs files", function()
			local output = [[
lib/foo.ex:11: Foo (module)
test/foo_test.exs:5: (test)
]]
			local old_fn = vim.fn
			vim.fn = setmetatable({
				getcwd = function()
					return "/tmp"
				end,
				filereadable = function()
					return 1
				end,
			}, { __index = old_fn })

			local result = parser.parse_locations(output)
			vim.fn = old_fn

			assert.is_true(#result >= 1)
		end)

		it("should handle paths with subdirectories", function()
			local output = [[
lib/plausible_web/controllers/stats_controller.ex:1004: PlausibleWeb.Api.StatsController.exit_pages/2
test/plausible_web/controllers/stats_controller_test.exs:626
]]
			local old_fn = vim.fn
			vim.fn = setmetatable({
				getcwd = function()
					return "/tmp"
				end,
				filereadable = function()
					return 1
				end,
			}, { __index = old_fn })

			local result = parser.parse_locations(output)
			vim.fn = old_fn

			assert.is_true(#result >= 1)
		end)

		it("should handle indented stacktrace lines", function()
			local output = [[
     stacktrace:
     test/foo_test.exs:6: (test)
]]
			local old_fn = vim.fn
			vim.fn = setmetatable({
				getcwd = function()
					return "/tmp"
				end,
				filereadable = function()
					return 1
				end,
			}, { __index = old_fn })

			local result = parser.parse_locations(output)
			vim.fn = old_fn

			assert.is_true(#result >= 1)
		end)

		it("should handle stacktrace lines with project prefix", function()
			local output = [[
  1) test fails (DemoTest)
     test/demo_test.exs:9
     ** (RuntimeError) Stop
     code: Demo.raise()
     stacktrace:
       (demo 0.1.0) lib/demo.ex:20: anonymous fn/1 in Demo.raise/0
       (elixir 1.16.0) lib/enum.ex:4368: Enum.map_range/4
       (elixir 1.16.0) lib/enum.ex:4368: Enum.map/2
       test/demo_test.exs:10: (test)
]]
			local old_fn = vim.fn
			vim.fn = setmetatable({
				getcwd = function()
					return "/tmp"
				end,
				filereadable = function(path)
					if path:match("demo") then
						return 1
					end
					return 0
				end,
			}, { __index = old_fn })

			local result = parser.parse_locations(output)
			vim.fn = old_fn

			local has_demo_ex = false
			for _, loc in ipairs(result) do
				if loc.file == "lib/demo.ex" and loc.line == 20 then
					has_demo_ex = true
					break
				end
			end

			assert.is_true(has_demo_ex)
		end)

		it("should only include files that exist", function()
			local output = [[
test/existing.exs:5
test/nonexistent.exs:10
]]
			local old_fn = vim.fn
			vim.fn = setmetatable({
				getcwd = function()
					return "/tmp"
				end,
				filereadable = function(path)
					if path:match("existing%.exs$") then
						return 1
					end
					return 0
				end,
			}, { __index = old_fn })

			local result = parser.parse_locations(output)
			vim.fn = old_fn

			assert.equals(1, #result)
			assert.equals("test/existing.exs", result[1].file)
		end)
	end)

	describe("populate_loclist", function()
		it("should clear location list when locations is nil", function()
			local old_fn = vim.fn
			local setloclist_called = false
			vim.fn = setmetatable({
				setloclist = function(nr, items)
					setloclist_called = true
					assert.equals(0, nr)
					assert.are.same({}, items)
				end,
			}, { __index = old_fn })

			parser.populate_loclist(nil)
			vim.fn = old_fn

			assert.is_true(setloclist_called)
		end)

		it("should clear location list when locations is empty", function()
			local old_fn = vim.fn
			local setloclist_called = false
			vim.fn = setmetatable({
				setloclist = function(nr, items)
					setloclist_called = true
					assert.equals(0, nr)
					assert.are.same({}, items)
				end,
			}, { __index = old_fn })

			parser.populate_loclist({})
			vim.fn = old_fn

			assert.is_true(setloclist_called)
		end)

		it("should populate location list with single location", function()
			local old_fn = vim.fn
			local items_captured = nil
			vim.fn = setmetatable({
				setloclist = function(nr, items, action, opts)
					if action == "r" then
						items_captured = items
					end
				end,
			}, { __index = old_fn })

			local locations = {
				{ file = "test/foo_test.exs", line = 5 },
			}
			parser.populate_loclist(locations)
			vim.fn = old_fn

			assert.is_not_nil(items_captured)
			assert.equals(1, #items_captured)
			assert.equals("test/foo_test.exs", items_captured[1].filename)
			assert.equals(5, items_captured[1].lnum)
			assert.equals(1, items_captured[1].col)
		end)

		it("should populate location list with multiple locations", function()
			local old_fn = vim.fn
			local items_captured = nil
			vim.fn = setmetatable({
				setloclist = function(nr, items, action, opts)
					if action == "r" then
						items_captured = items
					end
				end,
			}, { __index = old_fn })

			local locations = {
				{ file = "test/foo_test.exs", line = 5 },
				{ file = "lib/foo.ex", line = 11 },
			}
			parser.populate_loclist(locations)
			vim.fn = old_fn

			assert.is_not_nil(items_captured)
			assert.equals(2, #items_captured)
		end)

		it("should set location list title", function()
			local old_fn = vim.fn
			local title_captured = nil
			vim.fn = setmetatable({
				setloclist = function(nr, items, action, opts)
					if opts and opts.title then
						title_captured = opts.title
					end
				end,
			}, { __index = old_fn })

			local locations = {
				{ file = "test/foo_test.exs", line = 5 },
			}
			parser.populate_loclist(locations)
			vim.fn = old_fn

			assert.equals("ExUnit Test Failures", title_captured)
		end)

		it("should open and focus location list when location_list_mode is 'focus'", function()
			local old_fn = vim.fn
			local old_cmd = vim.cmd
			local old_api = vim.api
			local lopen_called = false

			vim.fn = setmetatable({
				setloclist = function() end,
				getcwd = function()
					return "/tmp"
				end,
			}, { __index = old_fn })

			vim.api = setmetatable({
				nvim_buf_get_name = function()
					return "/tmp/other.ex"
				end,
			}, { __index = old_api })

			vim.cmd = function(cmd)
				if cmd == "lopen" then
					lopen_called = true
				end
			end

			local locations = {
				{ file = "test/foo_test.exs", line = 5 },
			}
			local config = { location_list_mode = "focus" }
			parser.populate_loclist(locations, config)

			vim.fn = old_fn
			vim.cmd = old_cmd
			vim.api = old_api

			assert.is_true(lopen_called)
		end)

		it("should open location list without focus when location_list_mode is 'open_no_focus'", function()
			local old_fn = vim.fn
			local old_cmd = vim.cmd
			local old_api = vim.api
			local commands_called = {}

			vim.fn = setmetatable({
				setloclist = function() end,
				getcwd = function()
					return "/tmp"
				end,
			}, { __index = old_fn })

			vim.api = setmetatable({
				nvim_buf_get_name = function()
					return "/tmp/other.ex"
				end,
			}, { __index = old_api })

			vim.cmd = function(cmd)
				table.insert(commands_called, cmd)
			end

			local locations = {
				{ file = "test/foo_test.exs", line = 5 },
			}
			local config = { location_list_mode = "open_no_focus" }
			parser.populate_loclist(locations, config)

			vim.fn = old_fn
			vim.cmd = old_cmd
			vim.api = old_api

			assert.equals(2, #commands_called)
			assert.equals("lopen", commands_called[1])
			assert.equals("wincmd p", commands_called[2])
		end)

		it("should not open location list when location_list_mode is 'manual'", function()
			local old_fn = vim.fn
			local old_cmd = vim.cmd
			local old_api = vim.api
			local lopen_called = false

			vim.fn = setmetatable({
				setloclist = function() end,
				getcwd = function()
					return "/tmp"
				end,
			}, { __index = old_fn })

			vim.api = setmetatable({
				nvim_buf_get_name = function()
					return "/tmp/other.ex"
				end,
			}, { __index = old_api })

			vim.cmd = function(cmd)
				if cmd == "lopen" then
					lopen_called = true
				end
			end

			local locations = {
				{ file = "test/foo_test.exs", line = 5 },
			}
			local config = { location_list_mode = "manual" }
			parser.populate_loclist(locations, config)

			vim.fn = old_fn
			vim.cmd = old_cmd
			vim.api = old_api

			assert.is_false(lopen_called)
		end)

		it("should not open location list when current buffer is in the list", function()
			local old_fn = vim.fn
			local old_cmd = vim.cmd
			local old_api = vim.api
			local lopen_called = false

			vim.fn = setmetatable({
				setloclist = function() end,
				getcwd = function()
					return "/tmp"
				end,
			}, { __index = old_fn })

			vim.api = setmetatable({
				nvim_buf_get_name = function()
					return "/tmp/test/foo_test.exs"
				end,
			}, { __index = old_api })

			vim.cmd = function(cmd)
				if cmd == "lopen" then
					lopen_called = true
				end
			end

			local locations = {
				{ file = "test/foo_test.exs", line = 5 },
			}
			local config = { location_list_mode = "focus" }
			parser.populate_loclist(locations, config)

			vim.fn = old_fn
			vim.cmd = old_cmd
			vim.api = old_api

			assert.is_false(lopen_called)
		end)

		it("should close location list when no failures and mode is 'focus'", function()
			local old_fn = vim.fn
			local old_cmd = vim.cmd
			local lclose_called = false

			vim.fn = setmetatable({
				setloclist = function() end,
			}, { __index = old_fn })

			vim.cmd = function(cmd)
				if cmd == "lclose" then
					lclose_called = true
				end
			end

			local config = { location_list_mode = "focus" }
			parser.populate_loclist({}, config)

			vim.fn = old_fn
			vim.cmd = old_cmd

			assert.is_true(lclose_called)
		end)

		it("should close location list when no failures and mode is 'open_no_focus'", function()
			local old_fn = vim.fn
			local old_cmd = vim.cmd
			local lclose_called = false

			vim.fn = setmetatable({
				setloclist = function() end,
			}, { __index = old_fn })

			vim.cmd = function(cmd)
				if cmd == "lclose" then
					lclose_called = true
				end
			end

			local config = { location_list_mode = "open_no_focus" }
			parser.populate_loclist({}, config)

			vim.fn = old_fn
			vim.cmd = old_cmd

			assert.is_true(lclose_called)
		end)

		it("should not close location list when no failures and mode is 'manual'", function()
			local old_fn = vim.fn
			local old_cmd = vim.cmd
			local lclose_called = false

			vim.fn = setmetatable({
				setloclist = function() end,
			}, { __index = old_fn })

			vim.cmd = function(cmd)
				if cmd == "lclose" then
					lclose_called = true
				end
			end

			local config = { location_list_mode = "manual" }
			parser.populate_loclist({}, config)

			vim.fn = old_fn
			vim.cmd = old_cmd

			assert.is_false(lclose_called)
		end)
	end)

	describe("clear_signs", function()
		it("should unplace all previously placed signs", function()
			local ui = require("exunit.ui")
			local old_fn = vim.fn
			local unplaced_signs = {}

			vim.fn = setmetatable({
				sign_unplace = function(group, opts)
					table.insert(unplaced_signs, { group = group, id = opts.id })
				end,
			}, { __index = old_fn })

			table.insert(ui.placed_signs, 1)
			table.insert(ui.placed_signs, 2)
			table.insert(ui.placed_signs, 3)
			ui.clear_signs()

			vim.fn = old_fn

			assert.equals(3, #unplaced_signs)
			assert.equals("ExUnit", unplaced_signs[1].group)
			assert.equals(1, unplaced_signs[1].id)
		end)

		it("should clear placed_signs list", function()
			local ui = require("exunit.ui")
			table.insert(ui.placed_signs, 1)
			table.insert(ui.placed_signs, 2)
			table.insert(ui.placed_signs, 3)

			local old_fn = vim.fn
			vim.fn = setmetatable({
				sign_unplace = function() end,
			}, { __index = old_fn })

			ui.clear_signs()
			vim.fn = old_fn
		end)
	end)

	describe("place_signs", function()
		it("should define ExUnitError sign", function()
			local ui = require("exunit.ui")
			local config = require("exunit.config")
			local old_fn = vim.fn
			local sign_defined = false
			local sign_name = nil

			vim.fn = setmetatable({
				sign_define = function(name, opts)
					sign_defined = true
					sign_name = name
				end,
				getcwd = function()
					return "/tmp"
				end,
				bufnr = function()
					return -1
				end,
				bufadd = function()
					return 1
				end,
				sign_place = function()
					return 1
				end,
				sign_unplace = function() end,
			}, { __index = old_fn })

			ui.place_signs({ { file = "test/foo.exs", line = 5 } }, config.defaults)
			vim.fn = old_fn

			assert.is_true(sign_defined)
			assert.equals("ExUnitError", sign_name)
		end)

		it("should place signs for all locations", function()
			local ui = require("exunit.ui")
			local config = require("exunit.config")
			local old_fn = vim.fn
			local placed_signs = {}

			vim.fn = setmetatable({
				sign_define = function() end,
				getcwd = function()
					return "/tmp"
				end,
				bufnr = function()
					return 1
				end,
				bufadd = function()
					return 1
				end,
				sign_place = function(id, group, name, bufnr, opts)
					table.insert(placed_signs, {
						group = group,
						name = name,
						bufnr = bufnr,
						lnum = opts.lnum,
					})
					return #placed_signs
				end,
				sign_unplace = function() end,
			}, { __index = old_fn })

			local locations = {
				{ file = "test/foo.exs", line = 5 },
				{ file = "test/foo.exs", line = 10 },
				{ file = "lib/bar.ex", line = 15 },
			}
			ui.place_signs(locations, config.defaults)
			vim.fn = old_fn

			assert.equals(3, #placed_signs)
			assert.equals("ExUnit", placed_signs[1].group)
			assert.equals("ExUnitError", placed_signs[1].name)
			assert.equals(5, placed_signs[1].lnum)
			assert.equals(10, placed_signs[2].lnum)
			assert.equals(15, placed_signs[3].lnum)
		end)

		it("should clear previous signs before placing new ones", function()
			local ui = require("exunit.ui")
			local config = require("exunit.config")
			local old_fn = vim.fn
			local clear_called = false

			vim.fn = setmetatable({
				sign_define = function() end,
				sign_unplace = function()
					clear_called = true
				end,
				getcwd = function()
					return "/tmp"
				end,
				bufnr = function()
					return 1
				end,
				bufadd = function()
					return 1
				end,
				sign_place = function()
					return 1
				end,
			}, { __index = old_fn })

			ui.place_signs({ { file = "test/foo.exs", line = 5 } }, config.defaults)
			vim.fn = old_fn

			assert.is_true(clear_called)
		end)

		it("should handle empty locations", function()
			local ui = require("exunit.ui")
			local config = require("exunit.config")
			local old_fn = vim.fn
			local sign_placed = false

			vim.fn = setmetatable({
				sign_define = function() end,
				sign_place = function()
					sign_placed = true
					return 1
				end,
				sign_unplace = function() end,
			}, { __index = old_fn })

			ui.place_signs({}, config.defaults)
			vim.fn = old_fn

			assert.is_false(sign_placed)
		end)

		it("should track placed sign IDs", function()
			local ui = require("exunit.ui")
			local config = require("exunit.config")
			local old_fn = vim.fn

			vim.fn = setmetatable({
				sign_define = function() end,
				getcwd = function()
					return "/tmp"
				end,
				bufnr = function()
					return 1
				end,
				bufadd = function()
					return 1
				end,
				sign_place = function(id, group, name, bufnr, opts)
					return #ui.placed_signs + 1
				end,
				sign_unplace = function() end,
			}, { __index = old_fn })

			for i = #ui.placed_signs, 1, -1 do
				ui.placed_signs[i] = nil
			end
			ui.place_signs({
				{ file = "test/foo.exs", line = 5 },
				{ file = "test/bar.exs", line = 10 },
			}, config.defaults)
			vim.fn = old_fn

			assert.equals(2, #ui.placed_signs)
			assert.equals(1, ui.placed_signs[1])
			assert.equals(2, ui.placed_signs[2])
		end)
	end)
end)
