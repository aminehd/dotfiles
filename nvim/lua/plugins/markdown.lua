-- Draws markdown in the buffer: headings, lists, checkboxes, tables, code blocks.
-- <leader>um switches between the drawn view and the raw text.
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {},
    keys = {
      { "<leader>um", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle markdown rendering" },
    },
  },
}
