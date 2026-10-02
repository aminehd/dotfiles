return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          layout = {
            layout = {
              -- narrower sidebar (default is 40); set both or min_width keeps it at 40
              width = 30,
              min_width = 30,
            },
          },
        },
      },
    },
  },
}
