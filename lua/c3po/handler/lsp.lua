local api = require("c3po.utils.api")

-- Picking the LSP color under the cursor. Buffer highlighting itself is left
-- to vim.lsp.document_color, which nvim 0.12+ enables by default.
local M = {}

---@param range lsp.Range
---@param cursor { [1]: integer, [2]: integer } (0,0)-index
---@return boolean
local function is_within(range, cursor)
  -- lsp.Range is 0-based and the end position is exclusive.
  return range.start.line <= cursor[1]
    and range.start.character <= cursor[2]
    and range["end"].line >= cursor[1]
    and range["end"].character > cursor[2]
end

---@return integer? start_col 1-indexed
---@return integer? end_col 1-indexed, inclusive
---@return RGB?
---@return Alpha?
function M.pick()
  -- Asking for a method no attached server implements is a warning, not a
  -- silent miss, and every LaTeX buffer would raise it: no LaTeX language
  -- server declares a color provider.
  if #vim.lsp.get_clients({ bufnr = 0, method = "textDocument/documentColor" }) == 0 then
    return
  end
  local param = { textDocument = vim.lsp.util.make_text_document_params() }
  local results = vim.lsp.buf_request_sync(0, "textDocument/documentColor", param, 200) or {}
  local cursor = { api.get_cursor() }
  for _, res in pairs(results) do
    for _, info in ipairs(res.result or {}) do
      local range, color = info.range, info.color
      if is_within(range, cursor) then
        return range.start.character + 1, range["end"].character, { color.red, color.green, color.blue }, color.alpha
      end
    end
  end
end

return M
