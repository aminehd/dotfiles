-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- CP harness: run tests / step through PuDB on the current file
local cp = vim.g.cp_root .. "/cp"

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
local vpy = vim.g.py_venv .. "/bin/python3"

-- <leader>dP : run the current file in PuDB (full-screen TUI debugger) in a split.
-- Use this for practice/ and design-style files that aren't wired to `cp`.
vim.keymap.set("n", "<leader>dP", function()
  vim.cmd("write")
  -- kill any pudb panel from a previous run so this is always a fresh start
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.b[b] and vim.b[b].pudb_term then
      pcall(vim.api.nvim_buf_delete, b, { force = true })
    end
  end
  local f = vim.fn.fnameescape(vim.fn.expand("%:p"))
  -- full-screen tab: pudb needs the room or its focus/keys misbehave
  vim.cmd("tabnew | terminal " .. vpy .. " -m pudb " .. f)
  vim.b.pudb_term = true -- tag it so the next <leader>dP can close it
  vim.cmd("startinsert")
end, { desc = "Debug: run file in PuDB (fresh, fullscreen)" })

-- <F7> : save + run the current file with the venv python in a bottom panel.
-- General-purpose (works on practice/ + any file) and has snoop/pudb/etc available.
-- The panel stays open so you can read the snoop trace; :q closes it.
vim.keymap.set("n", "<F7>", function()
  vim.cmd("write")
  local f = vim.fn.fnameescape(vim.fn.expand("%:p"))
  vim.cmd("botright 18split | terminal " .. vpy .. " " .. f)
  vim.cmd("stopinsert") -- land in normal mode so k/j scroll the output
end, { desc = "Run file (venv) in panel" })

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
