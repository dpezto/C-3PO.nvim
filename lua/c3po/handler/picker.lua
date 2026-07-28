local utils = require("c3po.utils")
local api = require("c3po.utils.api")
local hl = require("c3po.handler.highlight")

---@class c3po.PickerHandler
local PickerHandler = {}

---@return integer? start_col 1-index
---@return integer? end_col 1-index, included
---@return RGB? RGB
---@return Alpha? Alpha
---@return c3po.ColorInput? recognized_input
---@return c3po.ColorOutput? recognized_output
function PickerHandler.pick()
  local opts = require("c3po.config").options
  local line = vim.api.nvim_get_current_line()
  --- cursor_col is 0-indexed, but start_col and end_col is 1-indexed.
  local _, cursor_col = api.get_cursor()
  cursor_col = cursor_col + 1

  local init = 1
  while init <= #line do
    local start_col, end_col, RGB, A, input, output
    for _, picker in ipairs(opts.pickers) do
      -- Readonly pickers match text that names a color rather than spelling one
      -- out (xcolor's `\textcolor{R2D2}`). Picking would overwrite the name
      -- with a literal, so they only ever feed the highlighter.
      local s, e, rgb, a
      if not picker.readonly then
        s, e, rgb, a = picker:parse_color(line, init)
      end
      if s and e and rgb and (start_col == nil or s < start_col) then
        start_col, end_col, RGB, A, input, output = s, e, rgb, a, nil, nil

        local pattern = utils.oc(opts.recognize, "pattern", picker) or {}
        if opts.recognize.input then
          input = pattern[1]
        end
        if opts.recognize.output then
          output = pattern[2]
        end
      end
    end
    if start_col == nil then
      break
    end
    if start_col <= cursor_col and cursor_col <= end_col then
      return start_col, end_col, RGB, A, input, output
    end
    init = end_col + 1
  end
end

---@param bufnr integer
---@param start_line integer 0-based
---@param end_line integer 0-based
---@param pickers? c3po.ColorPicker[]
---@return c3po.hl_info[]
function PickerHandler.info_in_range(bufnr, start_line, end_line, pickers)
  if pickers == nil then
    local opts = require("c3po.config").options
    pickers = opts.pickers
  end

  local infos = {}
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)
  for i, line in ipairs(lines) do
    local row = start_line + i - 1
    local init = 1
    while true do
      ---@type integer?, integer?, RGB?, vim.api.keyset.highlight?
      local start_col, end_col, RGB, hl_def
      for _, picker in ipairs(pickers) do
        local s, e, rgb, _, h = picker:parse_color(line, init, bufnr)
        if s and (start_col == nil or s < start_col) then
          start_col, end_col, RGB, hl_def = s, e, rgb, h
        end
      end
      if (RGB or hl_def) and end_col then
        table.insert(infos, {
          range = { row, start_col - 1, row, end_col },
          hl_name = hl.ensure_hl_name(RGB, hl_def),
        })
        init = end_col + 1
      else
        break
      end
    end
  end
  return infos
end

return PickerHandler
