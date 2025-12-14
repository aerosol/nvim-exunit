# nvim-exunit

Opinionated ExUnit test runner for NeoVim


https://github.com/user-attachments/assets/e9c640d9-9971-4345-a2fa-9e4a10f99311


## Default keymaps

<kbd>tt</kbd> - test under cursor

<kbd>tf</kbd> - test current module

<kbd>tF</kbd> - test current module with `--trace`

<kbd>ta</kbd> - test all

<kbd>tl</kbd> - repeat last test run

## Install

```lua
	{
		"aerosol/nvim-exunit",
		config = function()
			require("exunit").setup({})
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
