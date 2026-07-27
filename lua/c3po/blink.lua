local latex_name = require("c3po.picker.latex_name")

---A blink.cmp source for the project's xcolor color names. Register it with
---`providers = { c3po = { name = "Color", module = "c3po.blink" } }`.
---
---The items are ordinary LSP completion items of kind Color, so they get the
---same icon and highlight as the color names a language server offers, instead
---of arriving as untyped text the way 'omnifunc' items do.
---@class c3po.BlinkSource
local Source = {}

-- lsp.CompletionItemKind.Color. Hardcoded rather than required from blink: this
-- module must not pull the plugin in, and the protocol number is fixed.
local COLOR = 16

local TEX_FT = { tex = true, latex = true, plaintex = true }

function Source.new()
  return setmetatable({}, { __index = Source })
end

---@return boolean
function Source:enabled()
  return TEX_FT[vim.bo.filetype] == true
end

---@return string[]
function Source:get_trigger_characters()
  return { "{" }
end

---@param ctx table #blink.cmp.Context
---@param callback fun(response?: table)
function Source:get_completions(ctx, callback)
  local start = latex_name.arg_start(ctx.line, ctx.cursor[2])
  if start == nil then
    callback()
    return
  end

  local range = {
    ["start"] = { line = ctx.cursor[1] - 1, character = start },
    ["end"] = { line = ctx.cursor[1] - 1, character = ctx.cursor[2] },
  }

  local items = {}
  for name, rgb in pairs(latex_name.names(ctx.bufnr)) do
    table.insert(items, {
      label = name,
      kind = COLOR,
      -- blink's default draw already honours a per-item kind_hl, so the icon
      -- is drawn in the color the name stands for. Nothing to configure.
      kind_hl = latex_name.swatch_hl(ctx.bufnr, rgb),
      labelDetails = { description = latex_name.hex(rgb) },
      textEdit = { range = range, newText = name },
    })
  end

  callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = items })
end

return Source
