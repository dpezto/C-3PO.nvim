local utils = require("ccc.utils")
local parse = require("ccc.utils.parse")
local pattern = require("ccc.utils.pattern")

---@class ccc.ColorPicker.LaTeXRgb: ccc.ColorPicker
---@field pattern string[]
local LatexRgbPicker = {}

function LatexRgbPicker:init()
  if self.pattern then
    return
  end
  self.pattern = {
    pattern.create("{RGB}{ [<number>] , [<number>] , [<number>] }"),
    pattern.create("{rgb}{ [<per-num>|none] , [<per-num>|none] , [<per-num>|none] }"),
  }
end

---@param s string
---@param init? integer
---@return integer? start_col
---@return integer? end_col
---@return RGB? rgb
---@return Alpha? alpha
function LatexRgbPicker:parse_color(s, init)
  self:init()
  init = init or 1
  -- The separators are optional whitespace, so the shortest patten is the
  -- 12 characters of `{RGB}{0,0,0}`, not the 14 of `{RGB}{0, 0, 0}`.
  while init <= #s - 11 do
    local start_col, end_col, cap1, cap2, cap3, cap4 = pattern.find_first(s, self.pattern, init)
    if not (start_col and end_col and cap1 and cap2 and cap3) then
      return
    end
    -- xcolor's two models differ only in scale: `RGB` is 0-255, `rgb` is 0-1.
    local ratio = s:sub(start_col + 1, start_col + 3) == "RGB" and 255 or 1
    local R = parse.percent(cap1, ratio, true)
    local G = parse.percent(cap2, ratio, true)
    local B = parse.percent(cap3, ratio, true)
    if utils.valid_range({ R, G, B }, 0, 1) then
      local A = parse.alpha(cap4)
      return start_col, end_col, { R, G, B }, A
    end
    init = end_col + 1
  end
end

return LatexRgbPicker
