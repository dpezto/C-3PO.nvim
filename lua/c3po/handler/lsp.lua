local api = require("c3po.utils.api")

-- Picking the LSP color under the cursor. Buffer highlighting itself is left
-- to vim.lsp.document_color, which nvim 0.12+ enables by default.
local M = {}

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
  local row, col = api.get_cursor()
  local line = vim.api.nvim_get_current_line()
  for client_id, res in pairs(results) do
    local client = vim.lsp.get_client_by_id(client_id)
    local encoding = client and client.offset_encoding or "utf-16"
    for _, info in ipairs(res.result or {}) do
      local range, color = info.range, info.color
      -- lsp.Range is 0-based and the end position is exclusive. Its characters
      -- are counted in the server's encoding (UTF-16 by default), not in bytes.
      if range.start.line == row and range["end"].line == row then
        local start_col = vim.str_byteindex(line, encoding, range.start.character, false)
        local end_col = vim.str_byteindex(line, encoding, range["end"].character, false)
        if start_col <= col and col < end_col then
          return start_col + 1, end_col, { color.red, color.green, color.blue }, color.alpha
        end
      end
    end
  end
end

return M
