-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.number = true
vim.opt.relativenumber = true

-- Root = the folder nvim was opened in, not the git repo of the current file.
-- Without this, <leader><space> only searches the repo of the open buffer.
vim.g.root_spec = { "cwd" }
