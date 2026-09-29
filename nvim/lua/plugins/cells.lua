-- Quick cell insertion for jupytext percent files (days/*.py and friends).
-- Only maps in Python buffers, so nothing changes elsewhere.
--   <leader>ma  add a code cell
--   <leader>mt  add a text (markdown) cell
--   <leader>mv  add a jaxvis.draw block, cursor on the function name
local function insert(lines, cursor_offset)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, lines)
  vim.api.nvim_win_set_cursor(0, { row + (cursor_offset or #lines), 0 })
  vim.cmd("startinsert!")
end

local function map(lhs, lines, offset, desc)
  vim.keymap.set("n", lhs, function() insert(lines, offset) end,
    { buffer = true, desc = desc })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    map("<leader>ma", { "", "# %%", "" }, 3, "Cell: add code")
    map("<leader>mt", { "", "# %% [markdown]", "# ## ", "#", "# " }, 3,
      "Cell: add markdown")
    map("<leader>mv", {
      "", "# %% [markdown]", "# ## ", "#", "# _Notes._", "",
      "# %%", "@jaxvis.draw(field, palette=\"ultra\", size=680, tween=30, hold=8,",
      "             duration=55)", "def name(x):", "    return x", "",
    }, 3, "Cell: add markdown + jaxvis.draw")
  end,
})

return {}
