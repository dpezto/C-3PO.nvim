local parse = require("ccc.utils.parse")
local pattern = require("ccc.utils.pattern")

---@class ccc.ColorPicker.LaTeXHtml: ccc.ColorPicker
---@field pattern string
local LatexHtmlPicker = {
  -- xcolor's HTML model is always exactly six hex digits, so this needs a
  -- character class that pattern.create() does not provide.
  pattern = [=[\V{HTML}{\(\x\x\)\(\x\x\)\(\x\x\)}]=],
}

---@param s string
---@param init? integer
---@return integer? start_col
---@return integer? end_col
---@return RGB? rgb
---@return Alpha? alpha
function LatexHtmlPicker:parse_color(s, init)
  init = init or 1
  -- The shortest and only patten is 14 characters like `{HTML}{000000}`
  while init <= #s - 13 do
    local start_col, end_col, cap1, cap2, cap3 = pattern.find(s, self.pattern, init)
    if not (start_col and end_col and cap1 and cap2 and cap3) then
      return
    end
    local R = parse.hex(cap1)
    local G = parse.hex(cap2)
    local B = parse.hex(cap3)
    if R and G and B then
      return start_col, end_col, { R, G, B }
    end
    init = end_col + 1
  end
end

return LatexHtmlPicker
