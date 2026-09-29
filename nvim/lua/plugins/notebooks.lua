return {
  {
    "3rd/image.nvim",
    build = false,
    opts = {
      backend = "kitty",        -- iTerm2 supports kitty protocol
      integrations = {},
      max_width = 100,
      max_height = 30,
      hijack_file_patterns = {},
    },
  },
  {
    "GCBallesteros/NotebookNavigator.nvim",
    dependencies = { "benlubas/molten-nvim", "echasnovski/mini.comment" },
    keys = {
      { "<leader>mc", function() require("notebook-navigator").run_cell() end,     desc = "Run cell" },
      { "<leader>mn", function() require("notebook-navigator").run_and_move() end, desc = "Run cell + move to next" },
      { "]h",         function() require("notebook-navigator").move_cell("d") end, desc = "Next cell" },
      { "[h",         function() require("notebook-navigator").move_cell("u") end, desc = "Prev cell" },
    },
    config = function()
      require("notebook-navigator").setup({ activate_hydra_keys = nil })
    end,
  },
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    build = ":UpdateRemotePlugins",
    dependencies = { "3rd/image.nvim" },
    init = function()
      vim.g.python3_host_prog    = "/home/amineh/WorkSpace/ClawClaude/.venv/bin/python3"
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_output_win_max_height = 30
      vim.g.molten_auto_open_output = true
      vim.g.molten_wrap_output  = true
      vim.g.molten_virt_text_output = true
    end,
    keys = {
      -- Pins the kernel and refuses to start a second one. Bare :MoltenInit
      -- prompts for a kernel, and running it twice gives you frontier-lab_1
      -- plus a "which kernel?" prompt on every single evaluate.
      {
        "<leader>mi",
        function()
          local ok, running = pcall(vim.fn.MoltenRunningKernels, true)
          if ok and running and #running > 0 then
            vim.notify("molten: already on " .. table.concat(running, ", "))
            return
          end
          vim.cmd("MoltenInit frontier-lab")
        end,
        desc = "Molten: init kernel (frontier-lab)",
      },
      { "<leader>ml", "<cmd>MoltenEvaluateLine<cr>",          desc = "Molten: run line" },
      { "<leader>md", "<cmd>MoltenDelete<cr>",                desc = "Molten: delete cell" },
      { "<leader>ms", "<cmd>noautocmd MoltenEnterOutput<cr>", desc = "Molten: show output" },
    },
  },
}
