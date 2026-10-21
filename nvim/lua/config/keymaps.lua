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

-- ── Debug extras: general pudb + snoop (work on ANY file, not just the CP harness) ──
local vpy = "/home/amineh/WorkSpace/ClawClaude/.venv/bin/python3"

-- <leader>dP : run the current file in PuDB (full-screen TUI debugger) in a split.
-- Use this for practice/ and design-style files that aren't wired to `cp`.
vim.keymap.set("n", "<leader>dP", function()
  vim.cmd("write")
  local f = vim.fn.fnameescape(vim.fn.expand("%:p"))
  vim.cmd("botright split | resize 20 | terminal " .. vpy .. " -m pudb " .. f)
  vim.cmd("startinsert")
end, { desc = "Debug: run file in PuDB (TUI)" })

-- <leader>dS : drop a @snoop tracer above the current line (auto-adds `import snoop`).
-- Put the cursor on a `def ...:` line, hit it, run the file — every line prints
-- with how each variable changed. Zero stepping, just read the execution.
vim.keymap.set("n", "<leader>dS", function()
  local buf = 0
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local indent = vim.api.nvim_get_current_line():match("^%s*") or ""
  -- decorator just above the current line
  vim.api.nvim_buf_set_lines(buf, row - 1, row - 1, false, { indent .. "@snoop" })
  -- ensure `import snoop` near the top (scan first 40 lines)
  local head = vim.api.nvim_buf_get_lines(buf, 0, 40, false)
  local has = false
  for _, l in ipairs(head) do
    if l:match("^%s*import%s+snoop") then
      has = true
      break
    end
  end
  if not has then
    vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "import snoop" })
  end
end, { desc = "Debug: insert @snoop tracer" })
