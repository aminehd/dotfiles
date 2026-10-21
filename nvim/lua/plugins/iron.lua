-- iron.nvim: a live Python REPL inside nvim. Send a line or a visual selection
-- to a running IPython and watch it evaluate — great for poking at a data
-- structure interactively instead of print-debugging. Uses the ClawClaude venv
-- (so snoop/pudb/numpy etc. are all there). Keymaps live under <leader>r (REPL).
return {
  "Vigemus/iron.nvim",
  keys = {
    { "<leader>r", mode = { "n", "v" }, desc = "REPL" },
    { "<leader>rr", desc = "REPL: toggle" },
    { "<leader>rl", desc = "REPL: send line" },
    { "<leader>rf", desc = "REPL: send file" },
    { "<leader>rc", desc = "REPL: interrupt" },
    { "<leader>rq", desc = "REPL: exit" },
  },
  config = function()
    local iron = require("iron.core")
    local view = require("iron.view")
    local venv = "/home/amineh/WorkSpace/ClawClaude/.venv/bin"

    iron.setup({
      config = {
        scratch_repl = true,
        repl_definition = {
          python = {
            -- IPython from the venv: nice inline eval, no autoindent mangling
            command = { venv .. "/ipython", "--no-autoindent" },
            format = require("iron.fts.common").bracketed_paste_python,
          },
        },
        -- open the REPL in a right-hand vertical split, 40% wide
        repl_open_cmd = view.split.vertical.botright(0.4),
      },
      keymaps = {
        toggle_repl = "<leader>rr",
        send_line = "<leader>rl",
        visual_send = "<leader>r", -- select lines in visual mode, <leader>r sends them
        send_file = "<leader>rf",
        send_until_cursor = "<leader>ru",
        interrupt = "<leader>rc",
        exit = "<leader>rq",
        clear = "<leader>rx",
      },
      highlight = { italic = true },
      ignore_blank_lines = true,
    })
  end,
}
