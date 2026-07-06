return {
  -- Set Catppuccin flavour to "mocha" (matches Ghostty's catppuccin-mocha theme)
  {
    "catppuccin/nvim",
    opts = {
      flavour = "mocha",
    },
  },

  -- Override the LazyVim default colorscheme (tokyonight) to catppuccin
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
