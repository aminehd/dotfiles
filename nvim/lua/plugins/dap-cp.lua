-- nvim-dap: visual debugging inside nvim, wired for the CP harness.
-- Self-contained so it won't clash with the rest of your LazyVim config.
return {
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup()

      -- auto open the panels when a session starts, close when it ends
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

      local venv = "/home/amineh/WorkSpace/ClawClaude/.venv/bin/python3"
      local cp_root = "/home/amineh/WorkSpace/ClawClaude/cp-prep"

      dap.adapters.python = {
        type = "executable",
        command = venv,
        args = { "-m", "debugpy.adapter" },
      }

      dap.configurations.python = {
        {
          -- runs your file with the baked sample fed to stdin automatically
          type = "python",
          request = "launch",
          name = "CP: debug with sample",
          program = cp_root .. "/dap_run.py",
          args = { "${file}" },
          console = "integratedTerminal",
          justMyCode = false,
          cwd = cp_root,
          pythonPath = venv,
        },
        {
          -- plain run of the current file, stops on the first line
          type = "python",
          request = "launch",
          name = "Python: current file",
          program = "${file}",
          console = "integratedTerminal",
          justMyCode = false,
          stopOnEntry = true,
          pythonPath = venv,
        },
      }

      -- gutter signs
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticWarn", linehl = "Visual" })

      -- keymaps (leader = <space>; reliable, no function-key issues)
      local map = vim.keymap.set
      map("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: toggle breakpoint" })
      map("n", "<leader>dc", dap.continue, { desc = "Debug: start / continue" })
      map("n", "<leader>dn", dap.step_over, { desc = "Debug: step over (next line)" })
      map("n", "<leader>di", dap.step_into, { desc = "Debug: step into" })
      map("n", "<leader>do", dap.step_out, { desc = "Debug: step out" })
      map("n", "<leader>dq", dap.terminate, { desc = "Debug: quit / stop" })
      map("n", "<leader>du", dapui.toggle, { desc = "Debug: toggle panels" })
      map("n", "<leader>de", function() dapui.eval(nil, { enter = true }) end, { desc = "Debug: eval expr" })
    end,
  },
}
