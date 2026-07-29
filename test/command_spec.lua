local utils = dofile("test/helper.lua")
local command = require("c3po.command")
local feed = utils.feed

vim.cmd("runtime plugin/c3po.lua")
local core = require("c3po").setup()

local function clear_buffer()
  utils.set_lines(0, -1, {})
  assert.same({ "" }, utils.get_lines(0, -1))
end

---Messages captured by the most recent capture_notify call.
---@type { msg: string, level: integer? }[]
local notified = {}

---Run body with vim.notify collecting into `notified` instead of printing.
---@param body fun()
local function capture_notify(body)
  notified = {}
  local original = vim.notify
  vim.notify = function(msg, level)
    notified[#notified + 1] = { msg = msg, level = level }
  end
  local ok, err = pcall(body)
  vim.notify = original
  assert(ok, err)
end

describe("Commands", function()
  before_each(function()
    clear_buffer()
  end)

  after_each(function()
    if utils.num_win() == 2 then
      vim.cmd("quit")
    end
    core.prev_colors:reset()
    core:reset_mode()
  end)

  it("g:c3po_color", function()
    vim.cmd("C3 pick")
    assert.equal("#000000", vim.g.c3po_color)
    feed("<CR>")
    assert.equal("", vim.g.c3po_color)
  end)

  describe("C3 pick", function()
    it("Insert new color", function()
      vim.cmd("C3 pick")
      assert.equal(2, utils.num_win(), "UI is not opened")
      feed("<CR>")
      -- Initial color is #000000
      assert.equal("#000000", utils.get_line())
      assert.equal(1, utils.num_win(), "UI is not closed")
    end)

    it("Pick color", function()
      utils.set_lines(0, -1, { "#ffffff" })
      vim.cmd("C3 pick")
      assert.equal("#ffffff", vim.g.c3po_color)
      feed("<CR>")
    end)

    it("Recognizes the picked format when enabled", function()
      local opts = require("c3po.config").options
      local saved_in, saved_out = opts.recognize.input, opts.recognize.output
      opts.recognize.input, opts.recognize.output = true, true
      finally(function()
        opts.recognize.input, opts.recognize.output = saved_in, saved_out
      end)
      utils.set_lines(0, -1, { "hsl(180 50% 50%)" })
      vim.cmd("C3 pick")
      feed("<CR>")
      -- Input and output followed the picked format, so the color is written
      -- back as hsl rather than the default hex.
      assert.equal("hsl(180 50% 50%)", utils.get_line())
    end)
  end)

  describe("C3 yank", function()
    it("Yanks in the first output format by default", function()
      utils.set_lines(0, -1, { "#ff0000" })
      vim.fn.setreg('"', "")
      vim.cmd("C3 yank")
      assert.equal("#ff0000", vim.fn.getreg('"'))
      -- The buffer is untouched.
      assert.equal("#ff0000", utils.get_line())
    end)

    it("Yanks in a named output format", function()
      utils.set_lines(0, -1, { "#ff0000" })
      vim.cmd("C3 yank css_rgb")
      assert.equal("rgb(255 0 0)", vim.fn.getreg('"'))
    end)
  end)

  describe("C3 pick (edit)", function()
    it("Replace color", function()
      utils.set_lines(0, -1, { "#ffffff" })
      vim.cmd("C3 pick")
      -- Default mode; RGB (input), hex (output)
      -- Set all values to 0
      feed("0j0j0<CR>")
      assert.equal("#000000", utils.get_line())
    end)

    describe("action", function()
      it("complete", function()
        vim.cmd("C3 pick")
        feed("<CR>")
        -- Initial color is #000000
        assert.equal("#000000", utils.get_line())
      end)

      it("quit", function()
        vim.cmd("C3 pick")
        feed("q")
        assert.equal("", utils.get_line())
      end)

      it("cycle input mode", function()
        vim.cmd("C3 pick")
        -- Default mode; RGB (input), hex (output)
        -- Toggle to HSL
        feed("i")
        -- Set to hsl(180 50% 50%)
        feed("MjMjM<CR>")
        assert.equal("#40bfbf", utils.get_line())
      end)

      it("cycle output mode", function()
        vim.cmd("C3 pick")
        -- Default mode; RGB (input), hex (output)
        -- Toggle to hex_short
        feed("o<CR>")
        assert.equal("#000", utils.get_line())
      end)

      it("toggle_alpha", function()
        vim.cmd("C3 pick")
        -- Default mode; RGB (input), hex (output)
        assert.equal(5, vim.fn.line("$"))
        feed("a")
        assert.equal(6, vim.fn.line("$"))
        feed("<CR>")
        assert.equal("#000000ff", utils.get_line())
      end)

      it("toggle prev colors", function()
        vim.cmd("C3 pick")
        feed("L<CR>")
        assert.equal("#ff0000", utils.get_line())
        clear_buffer()
        vim.cmd("C3 pick")
        -- Set default color
        assert.equal("#000000", vim.g.c3po_color)
        -- Select most recently used color
        feed("g<CR><CR>")
        assert.equal("#ff0000", utils.get_line())
      end)

      it("goto next", function()
        vim.cmd("C3 pick")
        feed("L<CR>")
        assert.equal("#ff0000", utils.get_line())
        vim.cmd("C3 pick")
        feed("jL<CR>")
        assert.equal("#ffff00", utils.get_line())
        vim.cmd("C3 pick")
        feed("gw<CR><CR>")
        assert.equal("#ff0000", utils.get_line())
      end)

      it("goto prev", function()
        vim.cmd("C3 pick")
        feed("L<CR>")
        assert.equal("#ff0000", utils.get_line())
        vim.cmd("C3 pick")
        feed("jL<CR>")
        assert.equal("#ffff00", utils.get_line())
        clear_buffer()
        vim.cmd("C3 pick")
        feed("gwb<CR><CR>")
        assert.equal("#ffff00", utils.get_line())
      end)

      it("goto tail", function()
        vim.cmd("C3 pick")
        feed("L<CR>")
        assert.equal("#ff0000", utils.get_line())
        vim.cmd("C3 pick")
        feed("jL<CR>")
        assert.equal("#ffff00", utils.get_line())
        vim.cmd("C3 pick")
        feed("jjL<CR>")
        assert.equal("#ffffff", utils.get_line())
        clear_buffer()
        vim.cmd("C3 pick")
        feed("gW<CR><CR>")
        assert.equal("#ff0000", utils.get_line())
      end)

      it("goto head", function()
        vim.cmd("C3 pick")
        feed("L<CR>")
        assert.equal("#ff0000", utils.get_line())
        vim.cmd("C3 pick")
        feed("jL<CR>")
        assert.equal("#ffff00", utils.get_line())
        vim.cmd("C3 pick")
        feed("jjL<CR>")
        assert.equal("#ffffff", utils.get_line())
        clear_buffer()
        vim.cmd("C3 pick")
        feed("gWB<CR><CR>")
        assert.equal("#ffffff", utils.get_line())
      end)

      describe("increase", function()
        -- Default mapping: l / d / , (1 / 5 / 10)

        it("step by 1", function()
          vim.cmd("C3 pick")
          assert.equal("#000000", vim.g.c3po_color)
          feed("l<CR>")
          assert.equal("#010000", utils.get_line())
        end)

        it("step by 5", function()
          vim.cmd("C3 pick")
          assert.equal("#000000", vim.g.c3po_color)
          feed("d<CR>")
          assert.equal("#050000", utils.get_line())
        end)

        it("step by 10", function()
          vim.cmd("C3 pick")
          assert.equal("#000000", vim.g.c3po_color)
          feed(",<CR>")
          assert.equal("#0a0000", utils.get_line())
        end)
      end)

      describe("decrease", function()
        -- Default mapping: h / s / m (1 / 5 / 10)

        it("step by 1", function()
          vim.cmd("C3 pick")
          feed("ll")
          assert.equal("#020000", vim.g.c3po_color)
          feed("h<CR>")
          assert.equal("#010000", utils.get_line())
        end)

        it("step by 5", function()
          vim.cmd("C3 pick")
          feed("dd")
          assert.equal("#0a0000", vim.g.c3po_color)
          feed("s<CR>")
          assert.equal("#050000", utils.get_line())
        end)

        it("step by 10", function()
          vim.cmd("C3 pick")
          feed(",,")
          assert.equal("#140000", vim.g.c3po_color)
          feed("m<CR>")
          assert.equal("#0a0000", utils.get_line())
        end)
      end)

      describe("set to", function()
        -- Default mapping: H / M / L (0 / 50 / 100), 1 - 9 (10% - 90%)

        it("0 %", function()
          vim.cmd("C3 pick")
          feed("ll")
          assert.equal("#020000", vim.g.c3po_color)
          feed("H<CR>")
          assert.equal("#000000", utils.get_line())
        end)

        it("50 %", function()
          vim.cmd("C3 pick")
          feed("M<CR>")
          assert.equal("#800000", utils.get_line())
        end)

        it("100 %", function()
          vim.cmd("C3 pick")
          feed("L<CR>")
          assert.equal("#ff0000", utils.get_line())
        end)

        it("0 % - 90 % (mapped to numbers)", function()
          vim.cmd("C3 pick")
          feed("0")
          assert.equal("#000000", vim.g.c3po_color)
          feed("1")
          assert.equal("#1a0000", vim.g.c3po_color)
          feed("2")
          assert.equal("#330000", vim.g.c3po_color)
          feed("3")
          assert.equal("#4d0000", vim.g.c3po_color)
          feed("4")
          assert.equal("#660000", vim.g.c3po_color)
          feed("5")
          assert.equal("#800000", vim.g.c3po_color)
          feed("6")
          assert.equal("#990000", vim.g.c3po_color)
          feed("7")
          assert.equal("#b30000", vim.g.c3po_color)
          feed("8")
          assert.equal("#cc0000", vim.g.c3po_color)
          feed("9")
          assert.equal("#e60000", vim.g.c3po_color)
          feed("q")
        end)
      end)
    end)
  end)

  describe("<Plug>(c3po-insert)", function()
    -- One feed() per test: the sequence passes through insert mode, so it must
    -- stay in a single typeahead run.

    it("the middle of a line", function()
      utils.set_lines(0, -1, { "foobar" })
      feed("llli<Plug>(c3po-insert)MjMjM<CR>")
      assert.equal("foo#808080bar", utils.get_line())
    end)

    it("the beginning of a line", function()
      utils.set_lines(0, -1, { "foo" })
      feed("I<Plug>(c3po-insert)MjMjM<CR>")
      assert.equal("#808080foo", utils.get_line())
    end)

    it("the end of a line", function()
      utils.set_lines(0, -1, { "foo" })
      feed("A<Plug>(c3po-insert)MjMjM<CR>")
      assert.equal("foo#808080", utils.get_line())
    end)
  end)

  it("C3 convert", function()
    utils.set_lines(0, -1, { "#808080" })
    -- hex -> css_rgb -> css_hsl
    vim.cmd("C3 convert")
    assert.equal("rgb(128 128 128)", utils.get_line())
    vim.cmd("C3 convert")
    -- 0x80 is 50.196%; two decimals so the cycle returns the exact hex
    assert.equal("hsl(0 0% 50.2%)", utils.get_line())
    vim.cmd("C3 convert")
    assert.equal("#808080", utils.get_line())
  end)

  describe("<Plug>(c3po-select-color)", function()
    it("visual mode", function()
      utils.set_lines(0, -1, { "#00ff00" })
      feed("llv<Plug>(c3po-select-color)y")
      assert.equal("#00ff00", vim.fn.getreg())
    end)

    it("operator pending mode", function()
      utils.set_lines(0, -1, { "#ff00ff" })
      feed("lly<Plug>(c3po-select-color)")
      assert.equal("#ff00ff", vim.fn.getreg())
    end)
  end)

  describe("completion", function()
    it("offers the subcommands", function()
      assert.same({ "convert", "highlighter", "pick", "yank" }, command.complete("", "C3 ", 3))
      assert.same({ "pick" }, command.complete("p", "C3 p", 4))
    end)

    it("offers the output formats to yank", function()
      local got = command.complete("hex", "C3 yank hex", 11)
      assert.same({ "hex", "hex_short" }, got)
    end)

    it("offers the actions to highlighter, and nothing after them", function()
      assert.same({ "enable" }, command.complete("e", "C3 highlighter e", 16))
      assert.same({}, command.complete("", "C3 highlighter enable ", 22))
    end)

    it("offers nothing for a subcommand that takes no argument", function()
      assert.same({}, command.complete("", "C3 pick ", 8))
    end)

    it("offers nothing for an unknown subcommand", function()
      assert.same({}, command.complete("", "C3 nope ", 8))
    end)
  end)

  describe("argument checking", function()
    it("rejects an unknown subcommand", function()
      capture_notify(function()
        vim.cmd("C3 nope")
      end)
      assert.equal("[c3po] unknown subcommand: nope", notified[1].msg)
      assert.equal(vim.log.levels.ERROR, notified[1].level)
    end)

    it("rejects too many arguments", function()
      capture_notify(function()
        vim.cmd("C3 pick extra")
      end)
      assert.equal("[c3po] pick: expected 0 arguments, got 1", notified[1].msg)
    end)

    it("rejects a missing argument", function()
      capture_notify(function()
        vim.cmd("C3 highlighter")
      end)
      assert.equal("[c3po] highlighter: expected + arguments, got 0", notified[1].msg)
    end)

    it("accepts any number of arguments for nargs *", function()
      command.register("test_star", {
        nargs = "*",
        desc = "test only",
        func = function() end,
      })
      finally(function()
        command.commands.test_star = nil
      end)
      capture_notify(function()
        vim.cmd("C3 test_star a b c")
      end)
      assert.same({}, notified)
    end)
  end)

  describe("C3 yank (errors)", function()
    it("rejects an unknown output format", function()
      capture_notify(function()
        vim.cmd("C3 yank nope")
      end)
      assert.equal('[c3po] yank: no such output: "nope"', notified[1].msg)
    end)

    it("warns when there is no color under the cursor", function()
      utils.set_lines(0, -1, { "no color here" })
      capture_notify(function()
        vim.cmd("C3 yank")
      end)
      assert.equal("[c3po] yank: no color under the cursor", notified[1].msg)
      assert.equal(vim.log.levels.WARN, notified[1].level)
    end)
  end)

  describe("C3 highlighter", function()
    local highlighter = require("c3po.highlighter")

    after_each(function()
      highlighter:disable(0)
    end)

    it("enables and disables the current buffer", function()
      vim.cmd("C3 highlighter enable")
      assert.is_true(highlighter.attached_buffer[vim.api.nvim_get_current_buf()])
      vim.cmd("C3 highlighter disable")
      assert.is_nil(highlighter.attached_buffer[vim.api.nvim_get_current_buf()])
    end)

    it("takes an explicit bufnr", function()
      local bufnr = vim.api.nvim_create_buf(true, false)
      finally(function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end)
      vim.cmd("C3 highlighter toggle " .. bufnr)
      assert.is_true(highlighter.attached_buffer[bufnr])
      vim.cmd("C3 highlighter toggle " .. bufnr)
      assert.is_nil(highlighter.attached_buffer[bufnr])
    end)

    it("rejects an unknown action", function()
      capture_notify(function()
        vim.cmd("C3 highlighter nope")
      end)
      assert.equal('[c3po] highlighter: expected enable/disable/toggle, got "nope"', notified[1].msg)
    end)
  end)

  describe("C3 (menu)", function()
    local selected

    ---@param choose fun(choices: string[]): string?
    local function with_ui_select(choose, body)
      local original = vim.ui.select
      vim.ui.select = function(choices, opts, on_choice)
        selected = { choices = choices, format_item = opts.format_item }
        on_choice(choose(choices))
      end
      local ok, err = pcall(body)
      vim.ui.select = original
      assert(ok, err)
    end

    before_each(function()
      selected = nil
    end)

    it("lists every subcommand with its description", function()
      with_ui_select(function()
        return nil
      end, function()
        vim.cmd("C3")
      end)
      assert.same({ "convert", "highlighter", "pick", "yank" }, selected.choices)
      assert.equal("pick         Detect and replace the color under the cursor", selected.format_item("pick"))
    end)

    it("runs a subcommand that needs no argument", function()
      utils.set_lines(0, -1, { "#808080" })
      with_ui_select(function()
        return "convert"
      end, function()
        vim.cmd("C3")
      end)
      assert.equal("rgb(128 128 128)", utils.get_line())
    end)

    it("only prefills the command line for a subcommand that needs arguments", function()
      local feedkeys = {}
      local original = vim.api.nvim_feedkeys
      vim.api.nvim_feedkeys = function(keys)
        feedkeys[#feedkeys + 1] = keys
      end
      finally(function()
        vim.api.nvim_feedkeys = original
      end)
      with_ui_select(function()
        return "highlighter"
      end, function()
        vim.cmd("C3")
      end)
      assert.same({ ":C3 highlighter " }, feedkeys)
    end)
  end)
end)
