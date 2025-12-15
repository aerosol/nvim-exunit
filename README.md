# nvim-exunit

Opinionated ExUnit test runner for NeoVim

## Features

- Quick keymaps to run tests at cursor, module, project and jump to output
- Populates location list and automatically opens it on failure, unless the current buffer is on the list already
- Places signs on stacktrace items
- Displays statusline progress + notifications

## Default keymaps

<kbd>tt</kbd> - test under cursor

<kbd>tf</kbd> - test current module

<kbd>tF</kbd> - test current module with `--trace`

<kbd>ta</kbd> - test all

<kbd>tl</kbd> - repeat last test run

<kbd>gto</kbd> - go to test output tab

## Install

```lua
	{
		"aerosol/nvim-exunit",
		config = function()
			require("exunit").setup({
				own_keymaps = false,
				-- opens location list, if current buffer isn't under test
				-- available options: 
				--  "focus" - automatically switch to location list window
				--  "manual" - populates the list but doesn't invoke anything
				location_list_mode = "open_no_focus" 			
			})
		end,
	}
```

If you don't want default keymappings:

```lua
	{
		"aerosol/nvim-exunit",
		config = function()
			require("exunit").setup({own_keymaps = true})
      -- ...
		end,
	},

```

See: https://github.com/aerosol/nvim-exunit/blob/65c6da303cf290d9ba7e2c6e75181575ceb5b4bd/lua/exunit/init.lua#L17-L22

### Statusline integration

```lua
vim.o.statusline = "%{%v:lua.require'exunit'.statusline()%}"
```
