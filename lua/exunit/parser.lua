local paths = require("exunit.paths")

local M = {}

function M.parse_locations(output)
	if not output or output == "" then
		return {}
	end

	local locations = {}
	local seen = {}

	for line in output:gmatch("[^\r\n]+") do
		local path, line_num = line:match("([%w_/.%-]+%.exs?):(%d+)")

		if path and line_num and paths.is_elixir_test_file(path) then
			local key = path .. ":" .. line_num
			if not seen[key] then
				local full_path = paths.get_full_path(path)
				if paths.is_file_readable(full_path) then
					table.insert(locations, {
						file = path,
						line = tonumber(line_num),
					})
					seen[key] = true
				end
			end
		end
	end

	return locations
end

local function is_loclist_open()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		local ok, ft = pcall(function() return vim.bo[buf].filetype end)
		if ok and ft == "qf" then
			local ok_loclist, loclist = pcall(vim.fn.getloclist, vim.fn.win_getid(win))
			if ok_loclist and loclist ~= {} then
				return true
			end
		end
	end
	return false
end

local function should_open_loclist(config, items)
	if config.location_list_mode == "manual" then
		return false
	end

	if is_loclist_open() then
		return false
	end

	local current_bufname = vim.api.nvim_buf_get_name(0)
	for _, item in ipairs(items) do
		local item_path = paths.get_full_path(item.filename)
		if current_bufname == item_path then
			return false
		end
	end

	return true
end

local function open_loclist(config)
	if config.location_list_mode == "focus" then
		vim.cmd("lopen")
	elseif config.location_list_mode == "open_no_focus" then
		vim.cmd("lopen")
		vim.cmd("wincmd p")
	end
end

function M.populate_loclist(locations, config)
	config = config or require("exunit.config").defaults

	if not locations or #locations == 0 then
		vim.fn.setloclist(0, {})
		if config.location_list_mode ~= "manual" then
			vim.cmd("lclose")
		end
		return
	end

	local items = {}
	for _, loc in ipairs(locations) do
		table.insert(items, {
			filename = loc.file,
			lnum = loc.line,
			col = 1,
			text = string.format("%s:%d", loc.file, loc.line),
		})
	end

	vim.fn.setloclist(0, items, "r")
	vim.fn.setloclist(0, {}, "a", { title = "ExUnit Test Failures" })

	if should_open_loclist(config, items) then
		open_loclist(config)
	end
end

return M
