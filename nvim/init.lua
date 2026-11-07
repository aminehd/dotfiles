-- Machine paths come from the environment (~/.zshrc.local), so none live in this repo.
-- PY_VENV: python venv for the REPL and debuggers. CP_ROOT: folder of the CP practice harness.
vim.g.py_venv = os.getenv("PY_VENV") or vim.fn.expand("~/.venv")
vim.g.cp_root = os.getenv("CP_ROOT") or ""
if vim.fn.executable(vim.g.py_venv .. "/bin/python3") == 1 then
  vim.g.python3_host_prog = vim.g.py_venv .. "/bin/python3"
end

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
