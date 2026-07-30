<div align="center">

<img src="./assets/icon.png" width="220" alt="C-3PO.nvim icon">

# C-3PO.nvim

A protocol droid for color: pick, convert, yank and highlight colors in any
dialect a buffer speaks.

[![CI](https://github.com/dpezto/C-3PO.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/dpezto/C-3PO.nvim/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/dpezto/C-3PO.nvim/branch/main/graph/badge.svg)](https://codecov.io/gh/dpezto/C-3PO.nvim)
[![Release](https://img.shields.io/github/v/release/dpezto/C-3PO.nvim)](https://github.com/dpezto/C-3PO.nvim/releases/latest)
[![Neovim](https://img.shields.io/badge/Neovim-0.12%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

<img src="./assets/pick.gif" alt="Picking a color with sliders and cycling input and output formats" width="700">

</div>

> _"I am C-3PO, human-cyborg relations. I am fluent in over six million forms
> of communication."_

C-3PO reads whatever format the buffer uses (hex, `rgb()`, `oklch()`, xcolor's
`{cmyk}`, named colors) and writes it back in whichever one is asked for. It
covers CSS Color Module Level 4 and every LaTeX xcolor model in both
directions, resolves xcolor colors used by name against every `\definecolor`
in the project, and completes those names.

It started as a fork of [uga-rosa/ccc.nvim](https://github.com/uga-rosa/ccc.nvim)
(**C**reate **C**olor **C**ode) and remains indebted to it; the **C-3** is
inherited, the **PO** followed naturally. See [Migrating from ccc.nvim](#migrating-from-cccnvim).

The full reference lives in [`doc/c3po.txt`](./doc/c3po.txt) (`:h c3po`).

## Features

- No dependencies. One `:C3` command with subcommands, completion and a menu.
- Sliders in 14 color spaces (RGB, HSL, CMYK, OKLCH, HSLuv, ...), switched
  without leaving the picker; 22 output formats; 26 detection presets plus
  3 constructor-built pickers.
- Reads and writes CSS Color Level 4 and every LaTeX xcolor model, `{wave}`
  included.
- Picks up where it found the color: with `recognize` enabled, a `{cmyk}` spec
  reopens on CMYK sliders and is written back as `{cmyk}`.
- Project-wide xcolor named colors: `\textcolor{R2D2}` carries the color its
  `\definecolor` gives it, wherever in the project that definition lives, and
  the names complete through blink.cmp or `'omnifunc'`.
- Buffer highlighting of every configured format, with `bg`, `fg` or virtual
  text styles.
- Yank a color in any format without touching the buffer.
- Restore previously used colors from inside the picker.
- Asks the language server first (`textDocument/documentColor`) when picking
  or yanking.
- Programmable input, output and picker modules.

### Highlight and convert

The highlighter paints every configured format in place, xcolor
specifications included. `:C3 convert` then cycles the color under the cursor
through the `convert` list without opening the UI. Colors reported by
language servers are highlighted natively by Neovim's
`vim.lsp.document_color`; c3po reads them in `:C3 pick` and `:C3 yank`.

![Highlighting colors in place and converting between formats](./assets/highlight_convert.gif)

### Yank in any format

`:C3 yank [output]` grabs the color under the cursor in any output format and
leaves the buffer untouched.

![Yanking the color under the cursor in several formats](./assets/yank.gif)

### Restore previously used colors

Inside the picker, `g` opens the history row and `<CR>` applies the selected
color (`w`/`b` walk the row).

![Reopening the picker and restoring a previously used color](./assets/prev-colors.gif)

### Complete the project's colors

Every `\definecolor` in the project, offered by name, each entry wearing the
color it stands for.

![Completing project-defined xcolor names with colored icons](./assets/autocompletion.gif)

## Requirements

- Neovim 0.12 or newer.
- `'termguicolors'` enabled.
- No runtime dependencies.

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "dpezto/C-3PO.nvim",
  cmd = "C3",
  opts = {
    highlighter = { auto_enable = true },
  },
}
```

Any plugin manager works. Nothing is set up until `require("c3po").setup()`
runs, so pass `opts`/`config` or call `setup()` explicitly.

<details>
<summary>blink.cmp source for xcolor color names</summary>

Register `c3po.blink` as a [blink.cmp](https://github.com/saghen/blink.cmp)
provider. The source is enabled on the `tex`, `latex` and `plaintex`
filetypes, triggers on `{`, and needs no `latex_completion`:

```lua
-- blink.cmp opts
sources = {
  per_filetype = { tex = { inherit_defaults = true, "c3po" } },
  providers = { c3po = { name = "Color", module = "c3po.blink" } },
}
```

Entries arrive as ordinary LSP items of kind `Color`, so they pick up the
usual `Color` icon, and while the highlighter is enabled each icon is drawn
in the color the name stands for. The module never requires blink.cmp, so it
costs nothing when unused.

Without a completion engine, set `latex_completion = true` instead. It wraps
`'omnifunc'` on tex buffers for `<C-x><C-o>` and hands every non-color
completion back to whatever function was there before, so vimtex keeps
completing `\cite` and `\ref`.

</details>

## Configuration

A short example with the options most setups touch:

```lua
require("c3po").setup({
  -- Color spaces the sliders can work in. `i` cycles them.
  inputs = { "rgb", "hsl", "cmyk" },
  -- Formats a color can be written as. `o` cycles them; the first is the
  -- default and the fallback for `:C3 yank`.
  outputs = { "hex", "hex_short", "css_rgb", "css_hsl" },
  -- Formats recognized under the cursor by `:C3 pick`, `:C3 yank` and the
  -- highlighter.
  pickers = { "hex", "css_rgb", "css_hsl", "css_hwb",
              "css_lab", "css_lch", "css_oklab", "css_oklch" },
  -- Open the picker on the format that was found and write it back the same
  -- way, instead of always falling back to the first input/output.
  recognize = { input = true, output = true },
  highlighter = { auto_enable = true },
})
```

<details>
<summary>All defaults (verbatim from <code>lua/c3po/config/default.lua</code>)</summary>

```lua
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
```

Every option is documented under `:h c3po-options`.

</details>

### LaTeX (xcolor)

The `"latex"` picker alone reads and highlights every xcolor model: `{RGB}`,
`{rgb}`, `{HTML}`, `{cmyk}`, `{cmy}`, `{hsb}`, `{Hsb}`, `{HSB}`, `{tHsb}`,
`{gray}`, `{Gray}`, `{wave}`. Outputs are per model, so only the ones a
document uses need enabling. `"latex_name"` resolves colors used by name
against every `\definecolor` and `\providecolor` in the project.

```lua
require("c3po").setup({
  inputs  = { "rgb", "hsl", "cmyk", "hsv", "gray" },
  outputs = { "hex", "latex_rgb", "latex_cmyk", "latex_html" },
  pickers = {
    "hex", "css_rgb",
    -- Single-model views. They carry the recognition, so they come first.
    "latex_rgb_float", "latex_rgb", "latex_cmyk", "latex_html",
    "latex_gray15", "latex_gray",
    "latex", "latex_name",
  },
  recognize = { input = true, output = true },
})
```

Notes and limitations:

- There is no `{wave}` output. xcolor has no conversion into a wavelength, so
  a `{wave}` spec is read and highlighted but written back in another format.
- The name span is highlight-only. `:C3 pick` deliberately skips it, because
  overwriting `R2D2` with `#0070c0` would throw away the indirection the
  document is built on. Edit the definition itself, and use `:C3 yank` to
  read a named color.
- The project scan finds the root through `.latexmkrc`, `latexmkrc`,
  `Tectonic.toml`, `.texlabroot`, `texlabroot` or `.git`, reads at most 200
  `*.tex`/`*.sty` files, and does not follow `\input`/`\include`. The `named`
  model, `\definecolorset`, `\definecolorseries` and definitions split across
  lines are not resolved. See `:h c3po-option-pickers-latex_name` for the
  full list.

### Recognition and picker order

Ties between pickers are broken by list order, and some patterns overlap, so
two orderings matter: `latex_rgb_float` before `latex_rgb` (the latter
matches both `{rgb}` and `{RGB}`) and `latex_gray15` before `latex_gray` (the
latter matches both `{gray}` and `{Gray}`). Keep `"latex"` last as the
catch-all for models with no dedicated view; it matches everything and
therefore cannot name a single output for `recognize`.

`recognize.pattern` maps each picker to the input and output it should
select; the defaults cover every preset, so it only needs touching for
custom modules.

### Highlighter

`highlighter.auto_enable = true` attaches to every normal buffer that gets a
filetype (never terminals or scratch buffers), skipping buffers larger than
`max_byte`. `filetypes` is an allow-list for automatic attachment;
`excludes` is honored when `filetypes` is empty. Manual `:C3 highlighter
enable` ignores both. `highlight_mode` selects `"bg"`, `"fg"` or
`"virtual"` (with `virtual_symbol` and `virtual_pos`), and `update_insert`
repaints while typing.

## Commands

Everything hangs off one command. Bare `:C3` opens a `vim.ui.select` menu of
the subcommands, and both subcommands and arguments complete with `<Tab>`.

- `:C3` opens a menu listing the subcommands.
- `:C3 pick` opens sliders for the color under the cursor and replaces it on
  `<CR>`; with no color detected, the color is inserted at the cursor.
- `:C3 convert` converts the color under the cursor to the next format in
  the `convert` cycle, no UI.
- `:C3 yank [output]` yanks the color under the cursor into `v:register`,
  formatted with `output` (any output preset name); when omitted, the first
  entry of `outputs` is used.
- `:C3 highlighter enable [bufnr]` highlights colors in the buffer (the
  current buffer when omitted); `disable` and `toggle` do what they say.

## Mappings

Two `<Plug>` mappings are provided; nothing is bound outside the picker
window by default.

- `<Plug>(c3po-insert)`, insert mode: open the picker and insert the color,
  skipping detection.
- `<Plug>(c3po-select-color)`, visual and operator-pending modes: select the
  color under the cursor as a text object.

```lua
vim.keymap.set("i", "<C-c>", "<Plug>(c3po-insert)")
```

<details>
<summary>Default mappings inside the picker</summary>

- Finish: `<CR>` writes the color and closes (on the history row it applies
  the selected color); `q` quits without writing.
- Modes: `i` cycles the input color space, `o` the output format, `r` resets
  both and hides the alpha slider and the history row.
- Toggles: `a` shows or hides the alpha (transparency) slider, `g` the
  previous colors row.
- History row: `w`/`b` next and previous color, `W`/`B` last and first.
- Value changes: `l` +1, `d` +5, `,` +10; `h` -1, `s` -5, `m` -10 (in the
  slider's own delta).
- Absolute values: `H`/`M`/`L` set 0%/50%/100%; `0` through `9` set 0%
  through 90%; `$` sets 100%, since the digit row stops at 90%.
- Mouse: `<LeftMouse>` sets the slider under the mouse to the clicked
  position; `<ScrollWheelUp>`/`<ScrollWheelDown>` change the value by 1.

Override any of these through the `mappings` option, disable everything with
`disable_default_mappings = true`, or disable a single one by mapping it to
`require("c3po").mapping.none`. The available actions are documented under
`:h c3po-action`.

</details>

## Variables, autocmds and highlights

- `g:c3po_color` holds the color being edited, as hex; it is the empty
  string while the UI is closed.
- The `C3ColorChanged` autocmd fires after `g:c3po_color` changes.
- The `C3FloatNormal` and `C3FloatBorder` highlight groups style the picker
  window and its border; they link to `NormalFloat` and `FloatBorder` by
  default.

## Programmable modules

Inputs, outputs and pickers are plain Lua modules, and every entry in the
`inputs`/`outputs`/`pickers` options is either a preset name or a module.
The presets: 14 input color spaces (RGB, HSL, HWB, Lab, LCH, OKLab, OKLCH,
CMYK, HSLuv, OKHSL, HSV, OKHSV, XYZ, Gray), 22 output formats (hex, the CSS
functions, float, and one per xcolor model) and 26 picker presets, plus 3
pickers built by constructor: `custom_entries`, `trailing_whitespace` and
`ansi_escape`. The full lists live under `:h c3po-option-inputs`,
`:h c3po-option-outputs` and `:h c3po-option-pickers`.

`custom_entries` maps arbitrary words to colors, for both highlighting and
picking:

```lua
local c3po = require("c3po")
c3po.setup({
  pickers = {
    c3po.picker.custom_entries({
      red = "#ff0000",
      green = "#00ff00",
    }),
  },
})
```

A custom picker implements one method,
`parse_color(self, s, init?, bufnr?)`, returning 1-indexed inclusive columns
and RGB as floats in `[0, 1]`, with optional alpha. The hex outputs can also
be switched to uppercase with `c3po.output.hex.setup({ uppercase = true })`.

## Migrating from ccc.nvim

Everything is renamed, and the old names are gone rather than kept as
deprecated shims, so configs referring to them need updating. That includes
lazy.nvim `cmd` lists, which otherwise create stubs that load the plugin and
then fail. C-3PO also requires Neovim 0.12+ and removes the
`highlighter.lsp` option (Neovim highlights LSP colors natively, see
`:h vim.lsp.document_color`).

The renames:

- `:CccPick` is `:C3 pick`, `:CccConvert` is `:C3 convert`, and
  `:CccHighlighterEnable`/`Disable`/`Toggle` are
  `:C3 highlighter enable`/`disable`/`toggle`.
- `require("ccc")` is `require("c3po")`.
- `<Plug>(ccc-insert)` and `<Plug>(ccc-select-color)` are
  `<Plug>(c3po-insert)` and `<Plug>(c3po-select-color)`.
- The `Ccc*` highlight groups are `C3*`: `CccFloatNormal` is
  `C3FloatNormal`, `CccFloatBorder` is `C3FloatBorder`.
- The `CccColorChanged` autocmd is `C3ColorChanged`.
- `g:ccc_color` is `g:c3po_color`.
- `doc/ccc.txt` is `doc/c3po.txt` (`:h c3po`).

## Credits

- [uga-rosa/ccc.nvim](https://github.com/uga-rosa/ccc.nvim), the plugin this
  is a fork of and owes its core to.
- The GIFs are recorded with [vhs](https://github.com/charmbracelet/vhs) from
  the tapes in [`vhs/`](./vhs) (`make demo`). The tapes load the recording
  machine's own Neovim config, so re-recorded demos will not look identical.

## License

[MIT](LICENSE)
