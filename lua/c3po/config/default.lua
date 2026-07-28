local mapping = require("c3po.mapping")
local utils = require("c3po.utils")

---@type c3po.Options
return {
  default_color = "#000000",
  bar_char = "━",
  point_char = "█",
  bar_cap_start = "",
  bar_cap_end = "",
  point_color = "",
  empty_point_bg = true,
  point_color_on_dark = "#ffffff",
  point_color_on_light = "#000000",
  bar_len = 30,
  win_opts = {
    relative = "cursor",
    row = 1,
    col = 1,
    style = "minimal",
    border = "rounded",
  },
  auto_close = true,
  preserve = false,
  save_on_quit = false,
  max_prev_colors = 10,
  alpha_show = "auto",
  inputs = { "rgb", "hsl", "cmyk" },
  outputs = { "hex", "hex_short", "css_rgb", "css_hsl" },
  pickers = { "hex", "css_rgb", "css_hsl", "css_hwb", "css_lab", "css_lch", "css_oklab", "css_oklch" },
  ui = require("c3po.ui.float"),
  output_line = function(before_color, after_color, width)
    local b_hex = before_color:hex()
    local a_str = after_color:str()
    local line = b_hex .. " =>" .. (" "):rep(width - #b_hex - 3 - #a_str) .. a_str
    -- Range for highlight
    local b_start_col = 0
    local b_end_col = #b_hex
    local a_start_col = width - #a_str
    local a_end_col = width
    return line, b_start_col, b_end_col, a_start_col, a_end_col
  end,
  highlight_mode = "bg",
  virtual_symbol = " ● ",
  virtual_pos = "inline-left",
  lsp = true,
  latex_completion = false,
  highlighter = {
    auto_enable = false,
    max_byte = 100 * 1024, -- 100 KB
    filetypes = {},
    excludes = {},
    picker = true,
    update_insert = true,
  },
  -- A cycle: each format converts to the next, and the last back to the first.
  convert = { "hex", "css_rgb", "css_hsl" },
  recognize = {
    input = false,
    output = false,
    -- stylua: ignore
    pattern = {
        css_rgb   = { "rgb",   "css_rgb"   },
        css_name  = { "rgb",   "css_rgb"   },
        hex       = { "rgb",   "hex"       },
        hex_long  = { "rgb",   "hex"       },
        hex_short = { "rgb",   "hex_short" },
        css_hsl   = { "hsl",   "css_hsl"   },
        css_hwb   = { "hwb",   "css_hwb"   },
        css_lab   = { "lab",   "css_lab"   },
        css_lch   = { "lch",   "css_lch"   },
        css_oklab = { "oklab", "css_oklab" },
        css_oklch = { "oklch", "css_oklch" },
        -- The full "latex" picker matches every model, so it cannot name one
        -- output; recognition needs the single-model views, listed in
        -- 'pickers' ahead of it.
        latex_rgb       = { "rgb",  "latex_rgb"       },
        latex_rgb_float = { "rgb",  "latex_rgb_float" },
        latex_cmyk      = { "cmyk", "latex_cmyk"      },
        latex_html      = { "rgb",  "latex_html"      },
        latex_gray      = { "gray", "latex_gray"      },
        latex_gray15    = { "gray", "latex_gray15"    },
        latex_cmy       = { "cmyk", "latex_cmy"       },
        latex_hsb       = { "hsv",  "latex_hsb"       },
        latex_hsb360    = { "hsv",  "latex_hsb360"    },
        latex_hsb240    = { "hsv",  "latex_hsb240"    },
        latex_thsb      = { "hsv",  "latex_thsb"      },
        -- Wave has an input but no output: xcolor has no conversion into a
        -- wavelength, so a {wave} pick keeps the current output mode.
        latex_wave      = { "hsv" },
    },
  },
  mappings = {
    ["<CR>"] = mapping.complete,
    ["q"] = mapping.quit,
    ["l"] = mapping.increase1,
    ["d"] = mapping.increase5,
    [","] = mapping.increase10,
    ["h"] = mapping.decrease1,
    ["s"] = mapping.decrease5,
    ["m"] = mapping.decrease10,
    ["H"] = mapping.set0,
    ["M"] = mapping.set50,
    ["L"] = mapping.set100,
    ["0"] = mapping.set0,
    ["1"] = utils.bind(mapping._set_percent, 10),
    ["2"] = utils.bind(mapping._set_percent, 20),
    ["3"] = utils.bind(mapping._set_percent, 30),
    ["4"] = utils.bind(mapping._set_percent, 40),
    ["5"] = mapping.set50,
    ["6"] = utils.bind(mapping._set_percent, 60),
    ["7"] = utils.bind(mapping._set_percent, 70),
    ["8"] = utils.bind(mapping._set_percent, 80),
    ["9"] = utils.bind(mapping._set_percent, 90),
    -- The digit row stops at 90%; $ completes it, and is otherwise a no-op
    -- since the cursor is pinned to the labels.
    ["$"] = mapping.set100,
    ["r"] = mapping.reset_mode,
    ["a"] = mapping.toggle_alpha,
    ["g"] = mapping.toggle_prev_colors,
    ["b"] = mapping.goto_prev,
    ["w"] = mapping.goto_next,
    ["B"] = mapping.goto_head,
    ["W"] = mapping.goto_tail,
    ["i"] = mapping.cycle_input_mode,
    ["o"] = mapping.cycle_output_mode,
    ["<LeftMouse>"] = mapping.click,
    ["<ScrollWheelDown>"] = mapping.decrease1,
    ["<ScrollWheelUp>"] = mapping.increase1,
  },
  disable_default_mappings = false,
}
