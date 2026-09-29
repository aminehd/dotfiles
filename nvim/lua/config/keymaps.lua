-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- CP harness: run tests / step through PuDB on the current file
local cp = "/home/amineh/WorkSpace/ClawClaude/cp-prep/cp"

-- F5: save + run against all samples (✅/❌ + diff + timing) in a bottom split
vim.keymap.set("n", "<F5>", function()
  vim.cmd("write")
  local f = vim.fn.fnameescape(vim.fn.expand("%:p"))
  vim.cmd("botright 15split | terminal " .. cp .. " run " .. f)
  vim.b.cp_term = true
  vim.cmd("startinsert")
end, { desc = "CP: run samples" })

-- F6: save + open PuDB (visual debugger) full-screen in a terminal tab
vim.keymap.set("n", "<F6>", function()
  vim.cmd("write")
  local f = vim.fn.fnameescape(vim.fn.expand("%:p"))
  vim.cmd("tabnew | terminal " .. cp .. " run " .. f .. " --debug")
  vim.b.cp_term = true
  vim.cmd("startinsert")
end, { desc = "CP: PuDB debug" })

-- Ex-commands (reliable — no function-key issues). Type :Debug or :Run
vim.api.nvim_create_user_command("Debug", function()
  vim.cmd("write")
  local f = vim.fn.fnameescape(vim.fn.expand("%:p"))
  vim.cmd("botright vsplit | terminal " .. cp .. " run " .. f .. " --debug")
  vim.b.cp_term = true
  vim.cmd("startinsert")
end, { desc = "CP: PuDB debug (split)" })

vim.api.nvim_create_user_command("Run", function()
  vim.cmd("write")
  local f = vim.fn.fnameescape(vim.fn.expand("%:p"))
  vim.cmd("botright 15split | terminal " .. cp .. " run " .. f)
  vim.b.cp_term = true
  vim.cmd("startinsert")
end, { desc = "CP: run samples (split)" })

-- When a CP terminal finishes, close its window automatically
vim.api.nvim_create_autocmd("TermClose", {
  callback = function(args)
    if vim.b[args.buf].cp_term then
      vim.schedule(function()
        pcall(vim.api.nvim_buf_delete, args.buf, { force = true })
      end)
    end
  end,
})
