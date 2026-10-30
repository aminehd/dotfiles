-- PlantUML: draws .puml files and ```plantuml blocks in markdown with the local
-- `plantuml` (setup-plantuml.sh installs it). Nothing goes to a plantuml server.
--
--   save a .puml   writes <name>.png next to it
--   <leader>Pv     show the diagram under the cursor as an image (a tmux window, any key closes it)
--   <leader>Pt     show it as text in a split (sequence diagrams only)
--
-- The image shows through iTerm2's inline images (imgcat), so inside tmux it needs
-- allow-passthrough on (tmux 3.3+, set in tmux.conf).

vim.filetype.add({ extension = { puml = "plantuml", pu = "plantuml", uml = "plantuml", plantuml = "plantuml" } })

local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "PlantUML" })
end

-- Source of the diagram under the cursor: the whole buffer for a .puml file,
-- the ```plantuml block around the cursor in markdown.
function M.source()
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if vim.bo[buf].filetype ~= "markdown" then
    return table.concat(lines, "\n")
  end
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local start
  for i = row, 1, -1 do
    if lines[i]:match("^%s*```%s*plantuml") then
      start = i
      break
    elseif i < row and lines[i]:match("^%s*```") then
      break
    end
  end
  if not start then
    return nil
  end
  for i = start + 1, #lines do
    if lines[i]:match("^%s*```") then
      return table.concat(lines, "\n", start + 1, i - 1)
    end
  end
end

-- Renders `src` with the given format ("png" or "utxt") into `out`, then calls on_done().
function M.render(src, fmt, out, on_done)
  if vim.fn.executable("plantuml") == 0 then
    return notify("plantuml not found; run setup-plantuml.sh from the dotfiles", vim.log.levels.ERROR)
  end
  local cmd = { "plantuml", "-pipe", "-t" .. fmt }
  -- smetana is the built-in layout engine, so class diagrams work without graphviz
  if vim.fn.executable("dot") == 0 then
    table.insert(cmd, "-Playout=smetana")
  end
  vim.system(cmd, { stdin = src }, function(res)
    vim.schedule(function()
      if res.code ~= 0 or #res.stdout == 0 then
        return notify("render failed:\n" .. (res.stderr or ""), vim.log.levels.ERROR)
      end
      local f = assert(io.open(out, "wb"))
      f:write(res.stdout)
      f:close()
      if on_done then
        on_done(out)
      end
    end)
  end)
end

function M.show_image(png)
  if vim.env.TMUX and vim.fn.executable("imgcat") == 1 then
    vim.fn.system({ "tmux", "new-window", "-n", "diagram", "imgcat " .. vim.fn.shellescape(png) .. "; read -rsn1" })
  else
    vim.ui.open(png)
  end
end

function M.view()
  local src = M.source()
  if not src then
    return notify("cursor is not in a ```plantuml block", vim.log.levels.WARN)
  end
  M.render(src, "png", vim.fn.tempname() .. ".png", M.show_image)
end

function M.text()
  local src = M.source()
  if not src then
    return notify("cursor is not in a ```plantuml block", vim.log.levels.WARN)
  end
  M.render(src, "utxt", vim.fn.tempname() .. ".txt", function(out)
    vim.cmd("vsplit " .. vim.fn.fnameescape(out))
    vim.bo.bufhidden = "wipe"
  end)
end

return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = { spec = { { "<leader>P", group = "plantuml" } } },
  },
  {
    -- syntax highlighting for .puml / .pu / .uml / .plantuml; loads in markdown too for the keys
    "aklt/plantuml-syntax",
    ft = { "plantuml", "markdown" },
    keys = {
      { "<leader>Pv", function() M.view() end, ft = { "plantuml", "markdown" }, desc = "PlantUML: view image" },
      { "<leader>Pt", function() M.text() end, ft = { "plantuml", "markdown" }, desc = "PlantUML: view as text" },
    },
    config = function()
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("plantuml_render", { clear = true }),
        pattern = { "*.puml", "*.pu", "*.uml", "*.plantuml" },
        callback = function(ev)
          local png = vim.fn.fnamemodify(ev.file, ":p:r") .. ".png"
          M.render(table.concat(vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false), "\n"), "png", png, function()
            notify("wrote " .. vim.fn.fnamemodify(png, ":~:."))
          end)
        end,
      })
    end,
  },
}
