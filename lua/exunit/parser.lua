local M = {}

function M.parse_locations(output)
	if not output or output == "" then
		return {}
	end

	local locations = {}
	local seen = {}

	for line in output:gmatch("[^\r\n]+") do
		local path, line_num = line:match("^%s*([%w_/.%-]+%.exs?):(%d+)")

		if path and line_num then
			local key = path .. ":" .. line_num
			if not seen[key] then
				local full_path = vim.fn.getcwd() .. "/" .. path
				if vim.fn.filereadable(full_path) == 1 then
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

function M.populate_loclist(locations, config)
	if not locations or #locations == 0 then
		vim.fn.setloclist(0, {})
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

	if config and config.location_list_mode and config.location_list_mode ~= "manual" then
		local loclist_already_open = false
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			local buf = vim.api.nvim_win_get_buf(win)
			if vim.bo[buf].filetype == "qf" and vim.fn.getloclist(vim.fn.win_getid(win)) ~= {} then
				loclist_already_open = true
				break
			end
		end
		
		if not loclist_already_open then
			local current_bufname = vim.api.nvim_buf_get_name(0)
			local current_in_loclist = false
			
			for _, item in ipairs(items) do
				local item_path = vim.fn.getcwd() .. "/" .. item.filename
				if current_bufname == item_path then
					current_in_loclist = true
					break
				end
			end
			
			if not current_in_loclist then
				if config.location_list_mode == "focus" then
					vim.cmd("lopen")
				elseif config.location_list_mode == "open_no_focus" then
					vim.cmd("lopen")
					vim.cmd("wincmd p")
				end
			end
		end
	end
end

return M
