local mapping = require("c3po.mapping")

local core = require("c3po").setup()

describe("Mappings", function()
  before_each(function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "" })
    core:pick()
  end)

  after_each(function()
    if core.ui.bufnr then
      core.ui:close()
    end
    core.prev_colors:reset()
    core:reset_mode()
  end)

  describe("alpha", function()
    it("shows, hides and toggles the slider", function()
      mapping.show_alpha(core)
      assert.is_false(core.color.alpha.is_hide)
      mapping.hide_alpha(core)
      assert.is_true(core.color.alpha.is_hide)
      mapping.toggle_alpha(core)
      assert.is_false(core.color.alpha.is_hide)
      mapping.toggle_alpha(core)
      assert.is_true(core.color.alpha.is_hide)
    end)

    it("steps the value when the point is on the slider", function()
      mapping.show_alpha(core)
      core.ui:set_point({ type = "alpha" })
      assert.equal("alpha", core.ui:point_at().type)
      mapping.decrease5(core)
      assert.equal(0.95, core.color.alpha:get())
      mapping.increase1(core)
      assert.equal(0.96, core.color.alpha:get())
    end)

    it("sets the value by percent", function()
      mapping.show_alpha(core)
      core.ui:set_point({ type = "alpha" })
      mapping.set50(core)
      assert.equal(0.5, core.color.alpha:get())
      mapping.set0(core)
      assert.equal(0, core.color.alpha:get())
    end)

    it("is left alone while the slider is hidden", function()
      mapping.show_alpha(core)
      core.ui:set_point({ type = "alpha" })
      mapping.set50(core)
      mapping.hide_alpha(core)
      mapping.decrease5(core)
      mapping.show_alpha(core)
      assert.equal(0.5, core.color.alpha:get())
    end)
  end)

  describe("previous colors", function()
    before_each(function()
      core.prev_colors:prepend(core.color:copy())
    end)

    it("shows, hides and toggles the view", function()
      mapping.show_prev_colors(core)
      assert.is_true(core.ui.show_prev_colors)
      mapping.hide_prev_colors(core)
      assert.is_false(core.ui.show_prev_colors)
      mapping.toggle_prev_colors(core)
      assert.is_true(core.ui.show_prev_colors)
    end)

    it("walks the list and stops at both ends", function()
      core.prev_colors:prepend(core.color:copy())
      core.prev_colors:prepend(core.color:copy())
      mapping.show_prev_colors(core)
      assert.equal(1, core.prev_colors:get_index())
      mapping.goto_next(core)
      assert.equal(2, core.prev_colors:get_index())
      mapping.goto_prev(core)
      assert.equal(1, core.prev_colors:get_index())
      mapping.goto_tail(core)
      assert.equal(3, core.prev_colors:get_index())
      mapping.goto_head(core)
      assert.equal(1, core.prev_colors:get_index())
    end)
  end)

  describe("mode", function()
    it("resets input and output to the first one", function()
      mapping.cycle_input_mode(core)
      mapping.cycle_output_mode(core)
      assert.equal(2, core.color._input_idx)
      assert.equal(2, core.color._output_idx)
      mapping.reset_mode(core)
      assert.equal(1, core.color._input_idx)
      assert.equal(1, core.color._output_idx)
    end)

    it("cycles through the deprecated aliases", function()
      local warned = {}
      local original = vim.notify_once
      vim.notify_once = function(msg)
        warned[#warned + 1] = msg
      end
      finally(function()
        vim.notify_once = original
      end)

      mapping.toggle_input_mode(core)
      mapping.toggle_output_mode(core)
      assert.equal(2, core.color._input_idx)
      assert.equal(2, core.color._output_idx)
      assert.equal(2, #warned)
      assert.is_truthy(warned[1]:match("toggle_input_mode is deprecated"))
      assert.is_truthy(warned[2]:match("toggle_output_mode is deprecated"))
    end)
  end)

  describe("click", function()
    ---@param pos table
    local function with_mousepos(pos, body)
      local original = vim.fn.getmousepos
      vim.fn.getmousepos = function()
        return pos
      end
      local ok, err = pcall(body)
      vim.fn.getmousepos = original
      assert(ok, err)
    end

    it("ignores a click outside the float", function()
      with_mousepos({ winid = core.ui.winid + 1000, line = 1, column = 1 }, function()
        mapping.click(core)
      end)
      assert.equal("#000000", core.color:hex())
    end)

    it("ignores a click above the first slider", function()
      with_mousepos({ winid = core.ui.winid, line = 0, column = 1 }, function()
        mapping.click(core)
      end)
      assert.equal("#000000", core.color:hex())
    end)

    it("ignores a click off the bar", function()
      with_mousepos({ winid = core.ui.winid, line = 2, column = 1 }, function()
        mapping.click(core)
      end)
      assert.equal("#000000", core.color:hex())
    end)

    it("sets the slider to the clicked cell", function()
      local bar_len = require("c3po.config").options.bar_len
      local bar_start = #core.color:input().bar_name[1] + 10
      local line = vim.api.nvim_buf_get_lines(core.ui.bufnr, 1, 2, true)[1]
      -- The bar characters may be multibyte, so walk the last cell's start by
      -- character count rather than assuming one byte per cell.
      local before_last = vim.fn.strcharpart(line:sub(bar_start + 1), 0, bar_len - 1)

      with_mousepos({ winid = core.ui.winid, line = 2, column = bar_start + #before_last + 1 }, function()
        mapping.click(core)
      end)
      assert.equal("#ff0000", core.color:hex())

      with_mousepos({ winid = core.ui.winid, line = 2, column = bar_start + 1 }, function()
        mapping.click(core)
      end)
      assert.equal("#000000", core.color:hex())
    end)

    it("selects a previous color by column", function()
      core.prev_colors:prepend(core.color:copy())
      mapping.show_prev_colors(core)
      local row = vim.api.nvim_buf_line_count(core.ui.bufnr)
      with_mousepos({ winid = core.ui.winid, line = row, column = 1 }, function()
        mapping.click(core)
      end)
      assert.equal("prev", core.ui:point_at().type)
    end)
  end)
end)
