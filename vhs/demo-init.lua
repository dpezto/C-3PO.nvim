-- Minimal config for the vhs tapes in this directory.
-- Run vhs from the repo root: `vhs vhs/pick.tape` (or `make demo`).
vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.cmd.runtime("plugin/ccc.vim")

vim.opt.termguicolors = true
vim.opt.swapfile = false
vim.opt.number = false
vim.opt.laststatus = 0
vim.opt.ruler = false
vim.opt.showcmd = false
vim.opt.fillchars = { eob = " " }

require("ccc").setup({
  -- Rounded slider ends; the glyphs live in Fira Code (the tapes' font).
  bar_cap_start = "\u{ee03}",
  bar_char = "\u{ee04}",
  bar_cap_end = "\u{ee05}",
  bar_len = 32,
  highlighter = { auto_enable = true },
  outputs = { "hex", "css_rgb", "css_hsl", "latex_rgb", "latex_cmyk", "latex_html", "latex_gray" },
  pickers = { "hex", "css_rgb", "css_hsl", "latex" },
  convert = { "hex", "css_rgb", "css_hsl", "latex_rgb", "latex_cmyk", "latex_html" },
})
