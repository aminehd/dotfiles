return {
  {
    "echasnovski/mini.surround",
    version = false,
    event = "VeryLazy",
    opts = {
      -- `gs` prefix, not bare `s` — mini.surround's default would clobber
      -- vim's `s` (substitute char), which is worth keeping.
      mappings = {
        add = "gsa",
        delete = "gsd",
        replace = "gsr",
        find = "gsf",
        find_left = "gsF",
        highlight = "gsh",
        update_n_lines = "gsn",
      },
      -- gsaiwH -> {{ word }}  (Helm/Go templates), gsdH removes it
      custom_surroundings = {
        H = {
          input = { "{{%s*().-()%s*}}" },
          output = { left = "{{ ", right = " }}" },
        },
      },
    },
  },
}
