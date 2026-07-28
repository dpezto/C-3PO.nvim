-- Minimal config for the vhs tapes in this directory.
-- Run vhs from the repo root: `vhs vhs/pick.tape` (or `make demo`).
vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.cmd.runtime("plugin/c3po.vim")

vim.opt.termguicolors = true
vim.opt.swapfile = false
vim.opt.number = false
vim.opt.laststatus = 0
vim.opt.ruler = false
vim.opt.showcmd = false
vim.opt.fillchars = { eob = " " }

require("c3po").setup({
  -- Rounded slider ends; the glyphs need the tapes' font, a Nerd Font.
  bar_cap_start = "\u{ee03}",
  bar_char = "\u{ee04}",
  bar_cap_end = "\u{ee05}",
  bar_len = 32,
  highlighter = { auto_enable = true },
  inputs = { "rgb", "hsl", "cmyk", "gray" },
  outputs = { "hex", "css_rgb", "css_hsl", "latex_rgb", "latex_cmyk", "latex_html", "latex_gray" },
  -- stylua: ignore
  pickers = {
    "hex", "css_rgb", "css_hsl",
    "latex_rgb_float", "latex_rgb", "latex_cmyk", "latex_html", "latex_gray15", "latex_gray",
    "latex", "latex_name",
  },
  -- A pick reopens in the format it found, and writes it back the same way.
  recognize = { input = true, output = true },
  convert = { "hex", "css_rgb", "css_hsl", "latex_rgb", "latex_cmyk", "latex_html" },
})
