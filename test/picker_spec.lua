local utils = require("c3po.utils.test")
local hex = require("c3po.picker.hex")
local css_rgb = require("c3po.picker.css_rgb")
local css_hsl = require("c3po.picker.css_hsl")
local css_hwb = require("c3po.picker.css_hwb")
local css_lab = require("c3po.picker.css_lab")
local css_lch = require("c3po.picker.css_lch")
local css_oklab = require("c3po.picker.css_oklab")
local css_oklch = require("c3po.picker.css_oklch")
local css_name = require("c3po.picker.css_name")
local custom_entries = require("c3po.picker.custom_entries")
local trailing_whitespace = require("c3po.picker.trailing_whitespace")
local ansi_escape = require("c3po.picker.ansi_escape")
local latex = require("c3po.picker.latex")

---@param a number[]
---@return number[]
local function div255(a)
  return vim.tbl_map(function(x)
    return x / 255
  end, a)
end

---@param module c3po.ColorPicker
---@param str string
---@param expect_rgb integer[]? #range in [0-255]. If nil, expect parsing fail.
---@param expect_alpha Alpha?
local function test_rgb(module, str, expect_rgb, expect_alpha)
  local start, end_, rgb, alpha = module:parse_color(str)
  if expect_rgb == nil then
    assert.is_nil(start)
    assert.is_nil(end_)
    assert.is_nil(rgb)
    assert.is_nil(alpha)
  else
    assert(start and end_ and rgb, "Can't parse color")
    assert.equals(2, start)
    assert.equals(#str - 1, end_)
    expect_rgb = div255(expect_rgb)
    local msg = ("expected {%s}, but passed in {%s}"):format(table.concat(expect_rgb, ", "), table.concat(rgb, ", "))
    ---@cast rgb RGB
    for i = 1, 3 do
      assert.is_true(utils.near(expect_rgb[i], rgb[i], 1 / 255), msg)
    end
    assert.equals(expect_alpha, alpha)
  end
end

describe("Color detection test", function()
  it("none", function()
    test_rgb(css_rgb, " rgb(255 none 255) ", { 255, 0, 255 }, nil)
  end)

  describe("hex", function()
    it("6 digits", function()
      test_rgb(hex, " #ffff00 ", { 255, 255, 0 }, nil)
    end)
    it("8 digits (with alpha)", function()
      test_rgb(hex, " #ffff0000 ", { 255, 255, 0 }, 0)
    end)
    it("3 digits", function()
      test_rgb(hex, " #ff0 ", { 255, 255, 0 }, nil)
    end)
    it("4 digits (with alpha)", function()
      test_rgb(hex, " #ff00 ", { 255, 255, 0 }, 0)
    end)
    it("word boundary", function()
      test_rgb(hex, " dein#add ", nil, nil)
    end)
  end)

  describe("The RGB functions: rgb() and rgba()", function()
    it("Modern, rgb()", function()
      test_rgb(css_rgb, " rgb(255 0 255) ", { 255, 0, 255 }, nil)
      test_rgb(css_rgb, " rgb(255 0 255 / 0.8) ", { 255, 0, 255 }, 0.8)
      test_rgb(css_rgb, " rgb(100% 0% 100%) ", { 255, 0, 255 }, nil)
      test_rgb(css_rgb, " rgb(100% 0% 100% / 80%) ", { 255, 0, 255 }, 0.8)
    end)
    it("Modern, rgba()", function()
      test_rgb(css_rgb, " rgba(255 0 255) ", { 255, 0, 255 }, nil)
      test_rgb(css_rgb, " rgba(255 0 255 / 0.8) ", { 255, 0, 255 }, 0.8)
      test_rgb(css_rgb, " rgba(100% 0% 100%) ", { 255, 0, 255 }, nil)
      test_rgb(css_rgb, " rgba(100% 0% 100% / 80%) ", { 255, 0, 255 }, 0.8)
    end)
    it("Legacy, rgb()", function()
      test_rgb(css_rgb, " rgb(255, 0, 255) ", { 255, 0, 255 }, nil)
      test_rgb(css_rgb, " rgb(255, 0, 255, 0.8) ", { 255, 0, 255 }, 0.8)
      test_rgb(css_rgb, " rgb(100%, 0%, 100%) ", { 255, 0, 255 }, nil)
      test_rgb(css_rgb, " rgb(100%, 0%, 100%, 80%) ", { 255, 0, 255 }, 0.8)
    end)
    it("Legacy, rgba()", function()
      test_rgb(css_rgb, " rgba(255, 0, 255) ", { 255, 0, 255 }, nil)
      test_rgb(css_rgb, " rgba(255, 0, 255, 0.8) ", { 255, 0, 255 }, 0.8)
      test_rgb(css_rgb, " rgba(100%, 0%, 100%) ", { 255, 0, 255 }, nil)
      test_rgb(css_rgb, " rgba(100%, 0%, 100%, 80%) ", { 255, 0, 255 }, 0.8)
    end)
  end)

  describe("HSL Colors: hsl() and hsla() functions", function()
    it("Modern, hsl()", function()
      test_rgb(css_hsl, " hsl(180 50% 50%) ", { 63, 191, 191 }, nil)
      test_rgb(css_hsl, " hsl(180deg 50% 50% / 80%) ", { 63, 191, 191 }, 0.8)
      test_rgb(css_hsl, " hsl(200grad 50% 50% / 0.8) ", { 63, 191, 191 }, 0.8)
      test_rgb(css_hsl, " hsl(3.14rad 50% 50%) ", { 63, 191, 191 }, nil)
      test_rgb(css_hsl, " hsl(0.5turn 50% 50%) ", { 63, 191, 191 }, nil)
    end)
    it("Modern, hsla()", function()
      test_rgb(css_hsl, " hsla(180 50% 50%) ", { 63, 191, 191 }, nil)
      test_rgb(css_hsl, " hsla(180deg 50% 50% / 80%) ", { 63, 191, 191 }, 0.8)
      test_rgb(css_hsl, " hsla(200grad 50% 50% / 0.8) ", { 63, 191, 191 }, 0.8)
      test_rgb(css_hsl, " hsla(3.14rad 50% 50%) ", { 63, 191, 191 }, nil)
      test_rgb(css_hsl, " hsla(0.5turn 50% 50%) ", { 63, 191, 191 }, nil)
    end)
    it("Legacy, hsl()", function()
      test_rgb(css_hsl, " hsl(180, 50%, 50%) ", { 63, 191, 191 }, nil)
      test_rgb(css_hsl, " hsl(180deg, 50%, 50%, 80%) ", { 63, 191, 191 }, 0.8)
      test_rgb(css_hsl, " hsl(200grad, 50%, 50%, 0.8) ", { 63, 191, 191 }, 0.8)
      test_rgb(css_hsl, " hsl(3.14rad, 50%, 50%) ", { 63, 191, 191 }, nil)
      test_rgb(css_hsl, " hsl(0.5turn, 50%, 50%) ", { 63, 191, 191 }, nil)
    end)
    it("Legacy, hsla()", function()
      test_rgb(css_hsl, " hsla(180, 50%, 50%) ", { 63, 191, 191 }, nil)
      test_rgb(css_hsl, " hsla(180deg, 50%, 50%, 80%) ", { 63, 191, 191 }, 0.8)
      test_rgb(css_hsl, " hsla(200grad, 50%, 50%, 0.8) ", { 63, 191, 191 }, 0.8)
      test_rgb(css_hsl, " hsla(3.14rad, 50%, 50%) ", { 63, 191, 191 }, nil)
      test_rgb(css_hsl, " hsla(0.5turn, 50%, 50%) ", { 63, 191, 191 }, nil)
    end)
  end)

  describe("HWB Colors: hwb() function", function()
    it("hwb() without alpha", function()
      test_rgb(css_hwb, " hwb(180 30% 30%) ", { 77, 179, 179 }, nil)
      test_rgb(css_hwb, " hwb(180deg 30% 30%) ", { 77, 179, 179 }, nil)
      test_rgb(css_hwb, " hwb(200grad 30% 30%) ", { 77, 179, 179 }, nil)
      test_rgb(css_hwb, " hwb(3.14rad 30% 30%) ", { 77, 179, 179 }, nil)
      test_rgb(css_hwb, " hwb(0.5turn 30% 30%) ", { 77, 179, 179 }, nil)
    end)
    it("hwb() with alpha", function()
      test_rgb(css_hwb, " hwb(180 30% 30% / 0.8) ", { 77, 179, 179 }, 0.8)
      test_rgb(css_hwb, " hwb(180deg 30% 30% / 0.8) ", { 77, 179, 179 }, 0.8)
      test_rgb(css_hwb, " hwb(200grad 30% 30% / 0.8) ", { 77, 179, 179 }, 0.8)
      test_rgb(css_hwb, " hwb(3.14rad 30% 30% / 80%) ", { 77, 179, 179 }, 0.8)
      test_rgb(css_hwb, " hwb(0.5turn 30% 30% / 80%) ", { 77, 179, 179 }, 0.8)
    end)
  end)

  describe("Lab Color: lab() function", function()
    it("lab() without alpha", function()
      test_rgb(css_lab, " lab(60% 40% -20%) ", { 209, 109, 190 }, nil)
      test_rgb(css_lab, " lab(60 50 -25) ", { 209, 109, 190 }, nil)
    end)
    it("lab() with alpha", function()
      test_rgb(css_lab, " lab(60% 40% -20% / 80%) ", { 209, 109, 190 }, 0.8)
      test_rgb(css_lab, " lab(60 50 -25 / 0.8) ", { 209, 109, 190 }, 0.8)
    end)
  end)

  describe("LCH Color: lch() function", function()
    it("lch() without alpha", function()
      test_rgb(css_lch, " lch(60% 20% 270) ", { 108, 147, 197 }, nil)
      test_rgb(css_lch, " lch(60 30 270deg) ", { 108, 147, 197 }, nil)
      test_rgb(css_lch, " lch(60 30 300grad) ", { 108, 147, 197 }, nil)
      test_rgb(css_lch, " lch(60 30 4.71rad) ", { 108, 147, 197 }, nil)
      test_rgb(css_lch, " lch(60 30 0.75turn) ", { 108, 147, 197 }, nil)
    end)
    it("lch() with alpha", function()
      test_rgb(css_lch, " lch(60% 20% 270 / 80%) ", { 108, 147, 197 }, 0.8)
      test_rgb(css_lch, " lch(60 30 270deg / 0.8) ", { 108, 147, 197 }, 0.8)
      test_rgb(css_lch, " lch(60 30 300grad / 0.8) ", { 108, 147, 197 }, 0.8)
      test_rgb(css_lch, " lch(60 30 4.71rad / 0.8) ", { 108, 147, 197 }, 0.8)
      test_rgb(css_lch, " lch(60 30 0.75turn / 0.8) ", { 108, 147, 197 }, 0.8)
    end)
  end)

  describe("OKLab Color: oklab() function", function()
    it("oklab() without alpha", function()
      test_rgb(css_oklab, " oklab(50% 40% -40%) ", { 145, 29, 184 }, nil)
      test_rgb(css_oklab, " oklab(0.5 0.16 -0.16) ", { 145, 29, 184 }, nil)
    end)
    it("oklab() with alpha", function()
      test_rgb(css_oklab, " oklab(50% 40% -40% / 80%) ", { 145, 29, 184 }, 0.8)
      test_rgb(css_oklab, " oklab(0.5 0.16 -0.16 / 0.8) ", { 145, 29, 184 }, 0.8)
    end)
  end)

  describe("OKLCH Color: oklch() function", function()
    it("lch() without alpha", function()
      test_rgb(css_oklch, " oklch(60% 20% 270) ", { 109, 126, 177 }, nil)
      test_rgb(css_oklch, " oklch(0.6 0.08 270deg) ", { 109, 126, 177 }, nil)
      test_rgb(css_oklch, " oklch(0.6 0.08 300grad) ", { 109, 126, 177 }, nil)
      test_rgb(css_oklch, " oklch(0.6 0.08 4.71rad) ", { 109, 126, 177 }, nil)
      test_rgb(css_oklch, " oklch(0.6 0.08 0.75turn) ", { 109, 126, 177 }, nil)
    end)
    it("lch() with alpha", function()
      test_rgb(css_oklch, " oklch(60% 20% 270 / 80%) ", { 109, 126, 177 }, 0.8)
      test_rgb(css_oklch, " oklch(0.6 0.08 270deg / 0.8) ", { 109, 126, 177 }, 0.8)
      test_rgb(css_oklch, " oklch(0.6 0.08 300grad / 0.8) ", { 109, 126, 177 }, 0.8)
      test_rgb(css_oklch, " oklch(0.6 0.08 4.71rad / 0.8) ", { 109, 126, 177 }, 0.8)
      test_rgb(css_oklch, " oklch(0.6 0.08 0.75turn / 0.8) ", { 109, 126, 177 }, 0.8)
    end)
  end)

  it("Named Colors", function()
    test_rgb(css_name, " yellow ", { 255, 255, 0 }, nil)
    test_rgb(css_name, " yellowgreen ", { 154, 205, 50 }, nil)
  end)

  it("Custom Entries", function()
    test_rgb(custom_entries({ red = "#ff0000" }), " red ", { 255, 0, 0 }, nil)
    test_rgb(custom_entries({ [ [[foo\bar]] ] = "#ff0000" }), [[ foo\bar ]], { 255, 0, 0 }, nil)

    local orig = vim.opt.iskeyword:get()
    vim.opt.iskeyword = { "@", "48-57", "_", "128-167", "224-235" } -- default for Lua
    test_rgb(custom_entries({ red = "#ff0000", ["red-green"] = "#ffff00" }), " red-green ", { 255, 255, 0 }, nil)
    vim.opt.iskeyword = orig
  end)

  describe("Trailing Whitespace", function()
    after_each(function()
      vim.bo.filetype = ""
    end)

    ---@param ft string
    ---@param opts TrailingWhitespaceConfig
    ---@param str string
    ---@param expected? string
    ---@param length integer
    local function test(ft, opts, str, expected, length)
      vim.bo.filetype = ft
      local start, end_, _, _, hl_def = trailing_whitespace(opts):parse_color(str)
      assert.equals(length, end_ - start + 1)
      assert.same({ bg = expected }, hl_def)
    end

    ---@param ft string
    ---@param opts TrailingWhitespaceConfig
    ---@param str string
    local function test_fail(ft, opts, str)
      vim.bo.filetype = ft
      local start = trailing_whitespace(opts):parse_color(str)
      assert.is_nil(start)
    end

    local default_color = "#db7093"

    it("enable for all filetypes (default)", function()
      test("markdown", {}, "c3po  ", default_color, 2)
      test("text", {}, "c3po   ", default_color, 3)
    end)

    it("enable in only markdown", function()
      local opts = { enable = { "markdown" } }
      test("markdown", opts, "c3po  ", default_color, 2)
      test_fail("text", opts, "c3po  ")
    end)

    it("enable in except markdown", function()
      local opts = { disable = { "markdown" } }
      test_fail("markdown", opts, "c3po  ")
      test("text", opts, "c3po  ", default_color, 2)
      test("lua", opts, "c3po  ", default_color, 2)
    end)

    it("Set default color", function()
      test("markdown", { default_color = "#ff0000" }, "c3po  ", "#ff0000", 2)
    end)

    it("Set palette to specify color per filetype", function()
      local opts = {
        palette = {
          markdown = "#ff0000",
        },
        default_color = "#00ff00",
      }
      test("markdown", opts, "c3po  ", "#ff0000", 2)
      test("text", opts, "c3po  ", "#00ff00", 2)
    end)
  end)

  describe("ANSI Escape", function()
    ---@param module c3po.ColorPicker
    ---@param str string
    ---@param expect_hl_def highlightDefinition
    local function test_hl_def(module, str, expect_hl_def)
      local start, end_, _, _, hl_def = module:parse_color(str)
      assert(start and end_ and hl_def, "Can't parse color")
      assert.equals(2, start)
      assert.equals(#str - 1, end_)
      assert.same(expect_hl_def, hl_def)
    end

    it("bold", function()
      test_hl_def(
        ansi_escape({ red = "#ff0000", blue = "#0000ff" }, { meaning1 = "bold" }),
        " \\u001b[31;44;1m ",
        { fg = "#ff0000", bg = "#0000ff", bold = true }
      )
    end)
    it("bright", function()
      test_hl_def(
        ansi_escape({ bright_red = "#ff0000", bright_blue = "#0000ff" }, { meaning1 = "bright" }),
        " \\u001b[31;44;1m ",
        { fg = "#ff0000", bg = "#0000ff" }
      )
    end)
    it("attributes", function()
      test_hl_def(
        ansi_escape({ foreground = "#ffffff", background = "#000000" }, { meaning1 = "bold" }),
        " \\u001b[1;3;4;7;9m ",
        {
          fg = "#ffffff",
          bg = "#000000",
          bold = true,
          italic = true,
          underline = true,
          reverse = true,
          strikethrough = true,
        }
      )
    end)
    it([[In a string (\ may become \\)]], function()
      test_hl_def(
        ansi_escape({ red = "#ff0000", blue = "#0000ff" }),
        [["\\u001b[31;44m"]],
        { fg = "#ff0000", bg = "#0000ff" }
      )
    end)
  end)
  -- Every other case in this file pads the color with a leading and trailing
  -- space, which hid the boundary and ordering bugs below.
  describe("boundaries and ordering", function()
    it("matches a color that fills the whole line", function()
      local start, end_ = css_rgb:parse_color("rgb(0 0 0)")
      assert.equals(1, start)
      assert.equals(10, end_)
      start, end_ = latex:parse_color("{RGB}{0, 0, 0}")
      assert.equals(1, start)
      assert.equals(14, end_)
    end)

    it("reports the column the pattern matched, not the first lookalike", function()
      -- `x#fff` is rejected (preceded by a keyword char); the match is the second one.
      local s = "x#fff #fff"
      local start, end_ = hex:parse_color(s)
      assert.equals(7, start)
      assert.equals(10, end_)
      assert.equals("#fff", s:sub(start, end_))
    end)

    it("returns the earliest match when several patterns match", function()
      -- The comma form comes later in the pattern list but earlier in the line.
      local s = "rgba(1, 2, 3) then rgb(4 5 6)"
      local start, end_ = css_rgb:parse_color(s)
      assert.equals(1, start)
      assert.equals(13, end_)
      assert.equals("rgba(1, 2, 3)", s:sub(start, end_))
    end)

    it("clamps out-of-range alpha instead of passing it through", function()
      local _, _, _, alpha = css_rgb:parse_color(" rgba(0, 0, 0, 5) ")
      assert.equals(1, alpha)
      _, _, _, alpha = css_rgb:parse_color(" rgba(0, 0, 0, -1) ")
      assert.equals(0, alpha)
    end)
  end)
  describe("LaTeX (xcolor)", function()
    it("RGB and rgb models", function()
      test_rgb(latex, " {RGB}{255, 0, 255} ", { 255, 0, 255 }, nil)
      test_rgb(latex, " {rgb}{1, 0, 1} ", { 255, 0, 255 }, nil)
      -- The separators are optional, so this is the true minimum length.
      test_rgb(latex, " {RGB}{0,0,0} ", { 0, 0, 0 }, nil)
    end)

    it("cmyk model", function()
      test_rgb(latex, " {cmyk}{0, 1, 1, 0} ", { 255, 0, 0 }, nil)
      test_rgb(latex, " {cmyk}{0,1,1,0} ", { 255, 0, 0 }, nil)
      test_rgb(latex, " {cmyk}{0.000, 0.000, 0.000, 1.000} ", { 0, 0, 0 }, nil)
      -- cmyk needs four components; three of them is no model at all.
      test_rgb(latex, " {cmyk}{0, 1, 1} ", nil, nil)
      test_rgb(latex, " {cmyk}{0, 1, 1, 2} ", nil, nil)
    end)

    it("cmy model", function()
      test_rgb(latex, " {cmy}{0, 1, 1} ", { 255, 0, 0 }, nil)
      test_rgb(latex, " {cmy}{1, 1, 1} ", { 0, 0, 0 }, nil)
    end)

    it("HTML model", function()
      test_rgb(latex, " {HTML}{FF00FF} ", { 255, 0, 255 }, nil)
      test_rgb(latex, " {HTML}{ff00ff} ", { 255, 0, 255 }, nil)
      test_rgb(latex, " {HTML}{123456} ", { 18, 52, 86 }, nil)
      test_rgb(latex, " {HTML}{FF00F} ", nil, nil)
    end)

    it("hsb and HSB models", function()
      test_rgb(latex, " {hsb}{0, 1, 1} ", { 255, 0, 0 }, nil)
      -- 40/240 of a turn is 60 degrees: yellow.
      test_rgb(latex, " {HSB}{40, 240, 240} ", { 255, 255, 0 }, nil)
    end)

    it("Hsb and tHsb models", function()
      test_rgb(latex, " {Hsb}{120, 1, 1} ", { 0, 255, 0 }, nil)
      test_rgb(latex, " {Hsb}{240, 0.5, 1} ", { 128, 128, 255 }, nil)
      test_rgb(latex, " {Hsb}{400, 1, 1} ", nil, nil)
      -- Tuned hue 180 maps to Hsb hue 120: green.
      test_rgb(latex, " {tHsb}{180, 1, 1} ", { 0, 255, 0 }, nil)
      -- Tuned hue 60 maps to Hsb hue 30: orange.
      test_rgb(latex, " {tHsb}{60, 1, 1} ", { 255, 128, 0 }, nil)
      test_rgb(latex, " {tHsb}{360, 1, 1} ", { 255, 0, 0 }, nil)
    end)

    it("wave model", function()
      test_rgb(latex, " {wave}{580} ", { 255, 255, 0 }, nil)
      test_rgb(latex, " {wave}{650} ", { 255, 0, 0 }, nil)
      test_rgb(latex, " {wave}{445.5} ", { 0, 28, 255 }, nil)
      -- The vision limits fade to black instead of failing to parse.
      test_rgb(latex, " {wave}{380} ", { 77, 0, 77 }, nil)
      test_rgb(latex, " {wave}{900} ", { 0, 0, 0 }, nil)
    end)

    it("gray and Gray models", function()
      test_rgb(latex, " {gray}{0.5} ", { 128, 128, 128 }, nil)
      test_rgb(latex, " {gray}{1} ", { 255, 255, 255 }, nil)
      -- Gray is an integer scale of [0, 15].
      test_rgb(latex, " {Gray}{8} ", { 136, 136, 136 }, nil)
      test_rgb(latex, " {Gray}{15} ", { 255, 255, 255 }, nil)
    end)

    it("finds the model inside a full \\definecolor", function()
      local s = [[\definecolor{brand}{HTML}{123456}]]
      local start, end_ = latex:parse_color(s)
      assert.equals("{HTML}{123456}", s:sub(start, end_))
    end)

    it("restricted views match only their own model", function()
      local latex_cmyk = require("c3po.picker.latex_cmyk")
      test_rgb(latex_cmyk, " {cmyk}{0, 1, 1, 0} ", { 255, 0, 0 }, nil)
      test_rgb(latex_cmyk, " {RGB}{255, 0, 0} ", nil, nil)
      -- The full picker is untouched by the restriction.
      test_rgb(latex, " {RGB}{255, 0, 0} ", { 255, 0, 0 }, nil)
      -- The float view leaves the integer model alone, so listing it ahead of
      -- "latex_rgb" is what tells the two apart during recognition.
      local latex_rgb_float = require("c3po.picker.latex_rgb_float")
      test_rgb(latex_rgb_float, " {rgb}{1, 0, 0} ", { 255, 0, 0 }, nil)
      test_rgb(latex_rgb_float, " {RGB}{255, 0, 0} ", nil, nil)
      local latex_gray = require("c3po.picker.latex_gray")
      test_rgb(latex_gray, " {gray}{0.5} ", { 128, 128, 128 }, nil)
      test_rgb(latex_gray, " {Gray}{8} ", { 136, 136, 136 }, nil)
      test_rgb(latex_gray, " {rgb}{1, 0, 0} ", nil, nil)
    end)

    it("recognizes the picked format when enabled", function()
      local config = require("c3po.config")
      local latex_cmyk = require("c3po.picker.latex_cmyk")
      local saved_pickers, saved_recognize = config.options.pickers, config.options.recognize
      config.options.pickers = { latex_cmyk }
      config.options.recognize = {
        input = true,
        output = true,
        pattern = { [latex_cmyk] = { "cmyk", "latex_cmyk" } },
      }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { [[\definecolor{x}{cmyk}{0, 1, 1, 0}]] })
      vim.api.nvim_win_set_cursor(0, { 1, 20 })
      local _, _, _, _, input, output = require("c3po.handler.picker").pick()
      assert.equals("cmyk", input)
      assert.equals("latex_cmyk", output)
      config.options.pickers, config.options.recognize = saved_pickers, saved_recognize
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
    end)
  end)
  describe("LaTeX named colors", function()
    local latex_name = require("c3po.picker.latex_name")
    local DROID = { 0, 112 / 255, 192 / 255 }
    local real_names, saved_ft

    before_each(function()
      -- The name table is the seam: stubbing it keeps every case below off the
      -- filesystem and independent of the project this test happens to run in.
      real_names = latex_name.names
      latex_name.names = function()
        return { R2D2 = DROID }
      end
      saved_ft = vim.bo.filetype
      vim.bo.filetype = "tex"
    end)

    after_each(function()
      latex_name.names = real_names
      vim.bo.filetype = saved_ft
    end)

    ---@param s string
    ---@return string? #The matched text, nil when nothing matched
    local function span(s)
      local start, end_ = latex_name:parse_color(s)
      if start and end_ then
        return s:sub(start, end_)
      end
    end

    it("scans every model \\definecolor accepts", function()
      local names = latex_name.scan_lines({
        [[\definecolor{R2D2}{RGB}{0, 112, 192}]],
        [[\definecolor[ps]{oro}{HTML}{FFD700}]],
        [[\providecolor{medio}{gray}{0.5}]],
      })
      assert.is_true(utils.near(112 / 255, names.R2D2[2], 1 / 255))
      assert.is_true(utils.near(215 / 255, names.oro[2], 1 / 255))
      assert.same({ 0.5, 0.5, 0.5 }, names.medio)
    end)

    it("refuses the named model without stealing a later specification", function()
      local names = latex_name.scan_lines({
        [[\definecolor{a}{named}{Blue} \definecolor{b}{RGB}{255, 0, 0}]],
      })
      assert.is_nil(names.a)
      assert.same({ 1, 0, 0 }, names.b)
    end)

    it("pairs several definitions on one line", function()
      local names = latex_name.scan_lines({
        [[\definecolor{a}{gray}{0} \definecolor{b}{gray}{1}]],
      })
      assert.same({ 0, 0, 0 }, names.a)
      assert.same({ 1, 1, 1 }, names.b)
    end)

    it("spans the bare name at the definition site", function()
      assert.equals("R2D2", span([[\definecolor{R2D2}{RGB}{0, 112, 192}]]))
    end)

    it("matches the commands that take a color name", function()
      assert.equals("R2D2", span([[\textcolor{R2D2}{x}]]))
      assert.equals("R2D2", span([[{\color{R2D2} x}]]))
      assert.equals("R2D2", span([[\colorbox{R2D2}{x}]]))
      assert.equals("R2D2", span([[\cellcolor{R2D2}]]))
      -- \colorlet defines its first argument and reads its second; only the
      -- second one has a value this picker can resolve.
      assert.equals("R2D2", span([[\colorlet{astromech}{R2D2}]]))
    end)

    it("stops a mixing expression at the base name", function()
      assert.equals("R2D2", span([[\textcolor{R2D2!50!white}{x}]]))
    end)

    it("keeps scanning the line past an unknown name", function()
      local s = [[\textcolor{nope}{a} \textcolor{R2D2}{b}]]
      local start, end_ = latex_name:parse_color(s)
      assert.equals("R2D2", s:sub(start, end_))
    end)

    it("leaves bracketed specifications to the latex picker", function()
      assert.is_nil(span([[\textcolor[RGB]{0, 112, 192}{x}]]))
    end)

    it("is inert outside tex buffers", function()
      vim.bo.filetype = "lua"
      assert.is_nil(span([[\textcolor{R2D2}{x}]]))
    end)

    it("highlights the name and the specification separately", function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.bo[bufnr].filetype = "tex"
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { [[\definecolor{R2D2}{RGB}{0, 112, 192}]] })
      local infos = require("c3po.handler.picker").info_in_range(bufnr, 0, -1, { latex_name, latex })
      assert.equals(2, #infos)
      assert.same({ 0, 13, 0, 17 }, infos[1].range)
      assert.same({ 0, 18, 0, 36 }, infos[2].range)
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("sees an edited definition without waiting for a write", function()
      -- The real names(), not the stub the other cases install.
      latex_name.names = real_names
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.bo[bufnr].filetype = "tex"
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { [[\definecolor{holo}{RGB}{255, 0, 0}]] })
      assert.same({ 1, 0, 0 }, latex_name.names(bufnr).holo)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { [[\definecolor{holo}{RGB}{0, 0, 255}]] })
      assert.same({ 0, 0, 1 }, latex_name.names(bufnr).holo)
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("finds the completion prefix only inside a color argument", function()
      assert.equals(11, latex_name.arg_start([[\textcolor{az]], 13))
      assert.equals(7, latex_name.arg_start([[\color{]], 7))
      assert.equals(21, latex_name.arg_start([[\colorlet{astromech}{R2]], 22))
      assert.is_nil(latex_name.arg_start([[\cite{kn]], 8))
      assert.is_nil(latex_name.arg_start([[plain text]], 10))
    end)

    it("offers the names to blink.cmp as Color items", function()
      local source = require("c3po.blink").new()
      local ctx = { line = [[\textcolor{az]], cursor = { 1, 13 }, bufnr = 0 }
      local response
      source:get_completions(ctx, function(r)
        response = r
      end)
      local item = vim.tbl_filter(function(i)
        return i.label == "R2D2"
      end, response.items)[1]
      -- 16 is lsp.CompletionItemKind.Color.
      assert.equals(16, item.kind)
      assert.equals("#0070c0", item.labelDetails.description)
      assert.same({ line = 0, character = 11 }, item.textEdit.range["start"])
      -- The swatch follows the highlighter: no highlighting, no tinted icon.
      assert.is_nil(item.kind_hl)
      require("c3po.highlighter").attached_buffer[0] = true
      source:get_completions(ctx, function(r)
        response = r
      end)
      item = vim.tbl_filter(function(i)
        return i.label == "R2D2"
      end, response.items)[1]
      assert.equals("C3Highlighterfg0070c0", item.kind_hl)
      require("c3po.highlighter").attached_buffer[0] = nil

      -- Outside a color argument the source stays out of the way.
      source:get_completions({ line = [[\cite{kn]], cursor = { 1, 8 }, bufnr = 0 }, function(r)
        response = r
      end)
      assert.is_nil(response)
    end)

    it("never feeds :C3 pick, so the name is not overwritten", function()
      local config = require("c3po.config")
      local saved = config.options.pickers
      config.options.pickers = { latex_name }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { [[\textcolor{R2D2}{x}]] })
      vim.api.nvim_win_set_cursor(0, { 1, 13 })
      assert.is_nil(require("c3po.handler.picker").pick())
      config.options.pickers = saved
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
    end)
  end)
end)
