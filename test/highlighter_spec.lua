local highlighter = require("c3po.highlighter")
local config = require("c3po.config")
local hl = require("c3po.handler.highlight")

require("c3po").setup()

---@param lines string[]
---@param filetype? string
---@return integer bufnr
local function scratch(lines, filetype)
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  if filetype then
    vim.api.nvim_set_option_value("filetype", filetype, { buf = bufnr })
  end
  return bufnr
end

---@param bufnr integer
---@return vim.api.keyset.get_extmark_item[]
local function marks(bufnr)
  return vim.api.nvim_buf_get_extmarks(bufnr, highlighter.picker_ns_id, 0, -1, { details = true })
end

---Run body with config options temporarily overridden.
---@param overrides table
---@param body fun()
local function with_options(overrides, body)
  local saved = {}
  for key, value in pairs(overrides) do
    saved[key] = config.options[key]
    config.options[key] = value
  end
  local ok, err = pcall(body)
  for key, value in pairs(saved) do
    config.options[key] = value
  end
  assert(ok, err)
end

describe("Highlighter", function()
  local bufnr

  after_each(function()
    if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
      highlighter:disable(bufnr)
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
    bufnr = nil
  end)

  it("marks every color in the buffer on enable", function()
    bufnr = scratch({ "#ff0000", "no color here", "rgb(0 255 0)" })
    highlighter:enable(bufnr)
    assert.is_true(highlighter.attached_buffer[bufnr])
    local got = marks(bufnr)
    assert.equal(2, #got)
    assert.equal(0, got[1][2])
    assert.equal(2, got[2][2])
  end)

  it("enabling twice does not duplicate the marks", function()
    bufnr = scratch({ "#ff0000" })
    highlighter:enable(bufnr)
    highlighter:enable(bufnr)
    assert.equal(1, #marks(bufnr))
  end)

  it("clears the marks on disable", function()
    bufnr = scratch({ "#ff0000" })
    highlighter:enable(bufnr)
    highlighter:disable(bufnr)
    assert.is_nil(highlighter.attached_buffer[bufnr])
    assert.equal(0, #marks(bufnr))
  end)

  it("toggles both ways", function()
    bufnr = scratch({ "#ff0000" })
    highlighter:toggle(bufnr)
    assert.equal(1, #marks(bufnr))
    highlighter:toggle(bufnr)
    assert.equal(0, #marks(bufnr))
  end)

  it("defaults to the current buffer", function()
    bufnr = scratch({ "#ff0000" })
    vim.api.nvim_set_current_buf(bufnr)
    highlighter:enable()
    assert.is_true(highlighter.attached_buffer[bufnr])
    highlighter:disable()
    assert.is_nil(highlighter.attached_buffer[bufnr])
  end)

  it("detaches a buffer that is no longer valid", function()
    bufnr = scratch({ "#ff0000" })
    highlighter:enable(bufnr)
    local gone = bufnr
    vim.api.nvim_buf_delete(bufnr, { force = true })
    bufnr = nil
    highlighter:update(gone, 0, -1)
    assert.is_nil(highlighter.attached_buffer[gone])
  end)

  it("re-highlights an edited line", function()
    bufnr = scratch({ "#ff0000" })
    highlighter:enable(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "#ff0000 #00ff00" })
    vim.wait(500, function()
      return #marks(bufnr) == 2
    end)
    assert.equal(2, #marks(bufnr))
  end)

  it("skips the picker when it is turned off", function()
    bufnr = scratch({ "#ff0000" })
    with_options({ highlighter = vim.tbl_extend("force", config.options.highlighter, { picker = false }) }, function()
      highlighter:enable(bufnr)
      assert.equal(0, #marks(bufnr))
    end)
  end)

  describe("filetype filter", function()
    local function with_auto_enable(overrides, body)
      with_options({ highlighter = vim.tbl_extend("force", config.options.highlighter, overrides) }, body)
    end

    it("never attaches to the picker UI", function()
      bufnr = scratch({ "#ff0000" }, "c3po-ui")
      highlighter:enable(bufnr)
      assert.is_nil(highlighter.attached_buffer[bufnr])
    end)

    it("attaches only the listed filetypes", function()
      bufnr = scratch({ "#ff0000" }, "markdown")
      with_auto_enable({ auto_enable = true, filetypes = { "lua" } }, function()
        highlighter:enable(bufnr)
        assert.is_nil(highlighter.attached_buffer[bufnr])
      end)
      with_auto_enable({ auto_enable = true, filetypes = { "markdown" } }, function()
        highlighter:enable(bufnr)
        assert.is_true(highlighter.attached_buffer[bufnr])
      end)
    end)

    it("skips an excluded filetype", function()
      bufnr = scratch({ "#ff0000" }, "markdown")
      with_auto_enable({ auto_enable = true, excludes = { "markdown" } }, function()
        highlighter:enable(bufnr)
        assert.is_nil(highlighter.attached_buffer[bufnr])
      end)
    end)
  end)

  describe("virtual highlight mode", function()
    local function with_virtual(virtual_pos, body)
      with_options({ highlight_mode = "virtual", virtual_pos = virtual_pos }, body)
    end

    it("puts the symbol before the color", function()
      bufnr = scratch({ "  #ff0000" })
      with_virtual("inline-left", function()
        highlighter:enable(bufnr)
        local got = marks(bufnr)
        assert.equal(1, #got)
        assert.equal(2, got[1][3])
        assert.equal(" ● ", got[1][4].virt_text[1][1])
        assert.equal("inline", got[1][4].virt_text_pos)
      end)
    end)

    it("puts the symbol after the color", function()
      bufnr = scratch({ "  #ff0000" })
      with_virtual("inline-right", function()
        highlighter:enable(bufnr)
        local got = marks(bufnr)
        assert.equal(1, #got)
        assert.equal(9, got[1][3])
      end)
    end)

    it("puts the symbol at the end of the line", function()
      bufnr = scratch({ "  #ff0000" })
      with_virtual("eol", function()
        highlighter:enable(bufnr)
        local got = marks(bufnr)
        assert.equal(1, #got)
        assert.equal("eol", got[1][4].virt_text_pos)
      end)
    end)
  end)

  describe("ColorScheme", function()
    it("repaints the visible buffers and detaches the hidden ones", function()
      bufnr = scratch({ "#ff0000" })
      local hidden = scratch({ "#00ff00" })
      highlighter:enable(bufnr)
      highlighter:enable(hidden)
      vim.api.nvim_set_current_buf(bufnr)

      hl.hl_name_cache.stale = true
      vim.api.nvim_exec_autocmds("ColorScheme", {})

      assert.is_nil(hl.hl_name_cache.stale)
      assert.is_true(highlighter.attached_buffer[bufnr])
      assert.equal(1, #marks(bufnr))
      assert.is_nil(highlighter.attached_buffer[hidden])
      vim.api.nvim_buf_delete(hidden, { force = true })
    end)
  end)
end)
