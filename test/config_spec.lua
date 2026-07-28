local config = require("c3po.config")
local mapping = require("c3po.mapping")
local utils = require("c3po.utils")

require("c3po").setup()

---Run body over a throwaway copy of the options, collecting vim.notify.
---@param opts table #passed to config.setup
---@param body fun(notified: string[])
local function with_setup(opts, body)
  local saved = config.options
  local notified = {}
  local original = vim.notify
  vim.notify = function(msg)
    notified[#notified + 1] = msg
  end

  config.options = {}
  local ok, err = pcall(function()
    config.setup(opts)
    body(notified)
  end)

  vim.notify = original
  config.options = saved
  assert(ok, err)
end

describe("Config", function()
  it("resolves module names", function()
    with_setup({ outputs = { "css_rgb", require("c3po.output.hex") } }, function(notified)
      assert.same({}, notified)
      assert.same({ require("c3po.output.css_rgb"), require("c3po.output.hex") }, config.options.outputs)
    end)
  end)

  it("drops a name that resolves to nothing", function()
    with_setup({ pickers = { "hex", "nope" } }, function(notified)
      assert.same({ '[c3po] pickers: no such picker: "nope"' }, notified)
      assert.equal(1, #config.options.pickers)
    end)
  end)

  it("takes convert as explicit picker/output pairs", function()
    with_setup({ convert = { { "css_rgb", "hex" }, { "hex", "css_hsl" } } }, function(notified)
      assert.same({}, notified)
      assert.equal(2, #config.options.convert)
      assert.equal(require("c3po.picker.css_rgb"), config.options.convert[1][1])
      assert.equal(require("c3po.output.hex"), config.options.convert[1][2])
    end)
  end)

  it("drops a convert pair that does not resolve", function()
    with_setup({ convert = { { "nope", "hex" } } }, function(notified)
      assert.same({ '[c3po] convert: no such picker: "nope"' }, notified)
      assert.same({}, config.options.convert)
    end)
  end)

  it("takes convert as a cycle of names", function()
    with_setup({ convert = { "hex", "css_rgb" } }, function()
      assert.equal(2, #config.options.convert)
      -- Each format converts to the next, and the last back to the first.
      assert.equal(require("c3po.output.css_rgb"), config.options.convert[1][2])
      assert.equal(require("c3po.output.hex"), config.options.convert[2][2])
    end)
  end)

  it("resolves the recognize patterns", function()
    with_setup({ recognize = { pattern = { hex = { "hsl", "css_hsl" } } } }, function()
      -- The pattern is keyed by the picker module itself, not by its name.
      local pair = config.options.recognize.pattern[require("c3po.picker.hex")]
      assert.equal(require("c3po.input.hsl"), pair[1])
      assert.equal(require("c3po.output.css_hsl"), pair[2])
      -- A default the user did not touch keeps its own pair.
      local untouched = config.options.recognize.pattern[require("c3po.picker.css_hwb")]
      assert.equal(require("c3po.input.hwb"), untouched[1])
    end)
  end)

  it("drops every default mapping on request", function()
    with_setup({ disable_default_mappings = true, mappings = { q = mapping.quit } }, function()
      assert.same({ "q" }, vim.tbl_keys(config.options.mappings))
    end)
  end)

  it("unmaps a default key set to mapping.none", function()
    with_setup({ mappings = { q = mapping.none } }, function()
      assert.is_nil(config.options.mappings.q)
      -- The other defaults survive.
      assert.is_not_nil(config.options.mappings.l)
    end)
  end)
end)

describe("Utils", function()
  it("clamps, including NaN", function()
    assert.equal(1, utils.clamp(0, 1, 3))
    assert.equal(3, utils.clamp(9, 1, 3))
    assert.equal(2, utils.clamp(2, 1, 3))
    assert.equal(1, utils.clamp(0 / 0, 1, 3))
  end)

  it("builds a highlight for each mode", function()
    assert.same({ fg = "#ff0000" }, utils.create_highlight("#ff0000", "virtual"))
    assert.same({ fg = "#ff0000", bg = "#ffffff" }, utils.create_highlight("#ff0000", "fg"))
    assert.same({ fg = "#ff0000", bg = "#ffffff" }, utils.create_highlight("#ff0000", "foreground"))
    assert.same({ fg = "#ffffff", bg = "#ff0000" }, utils.create_highlight("#ff0000", "bg"))
    -- A bright color takes the dark contrast.
    assert.same({ fg = "#000000", bg = "#ffff00" }, utils.create_highlight("#ffff00", "bg"))
  end)

  it("validates a number or a list of numbers", function()
    assert.is_true(utils.valid_range(0.5, 0, 1))
    assert.is_false(utils.valid_range(2, 0, 1))
    assert.is_true(utils.valid_range({ 0, 0.5, 1 }, 0, 1))
    assert.is_false(utils.valid_range({ 0, 2 }, 0, 1))
    assert.is_false(utils.valid_range(nil, 0, 1))
    assert.is_false(utils.valid_range("0.5", 0, 1))
  end)

  it("walks an optional chain", function()
    local root = { a = { b = { c = 1 } } }
    assert.equal(1, utils.oc(root, "a", "b", "c"))
    assert.is_nil(utils.oc(root, "a", "x", "c"))
  end)

  it("feeds keys, with and without termcodes", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "" })
    utils.feedkey("i")
    -- Plain keys are typed as they are; the rest go through termcodes.
    utils.feedkey("ab", true)
    utils.feedkey("<Esc>")
    vim.api.nvim_feedkeys("", "x", false)
    assert.equal("ab", vim.api.nvim_get_current_line())
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "" })
  end)
end)
