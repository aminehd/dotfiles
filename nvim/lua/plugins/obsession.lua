-- Auto-record open tabs/splits to Session.vim so tmux-resurrect restores them.
-- Only auto-starts when nvim opens a WORKSPACE (a dir or no file arg) — not for
-- quick single-file edits. Restores cleanly: nvim -S <session> re-attaches obsession.
return {
  "tpope/vim-obsession",
  lazy = false,
  config = function()
    vim.api.nvim_create_autocmd("VimEnter", {
      nested = true,
      callback = function()
        if vim.v.this_session ~= "" then return end        -- already tracking / restored
        local a0 = vim.fn.argv(0)
        local workspace = (vim.fn.argc() == 0)
          or (type(a0) == "string" and a0 ~= "" and vim.fn.isdirectory(a0) == 1)
        if workspace then pcall(vim.cmd, "Obsession") end   -- begin recording Session.vim
      end,
    })
  end,
}
