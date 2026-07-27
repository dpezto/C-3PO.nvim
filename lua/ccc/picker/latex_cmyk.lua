local utils = require("ccc.utils")
local convert = require("ccc.utils.convert")
local parse = require("ccc.utils.parse")
local pattern = require("ccc.utils.pattern")

---@class ccc.ColorPicker.LaTeXCmyk: ccc.ColorPicker
---@field pattern string
local LatexCmykPicker = {}

function LatexCmykPicker:init()
  if self.pattern then
    return
  end
  self.pattern = pattern.create("{cmyk}{ [<per-num>|none] , [<per-num>|none] , [<per-num>|none] , [<per-num>|none] }")
end

---@param s string
---@param init? integer
---@return integer? start_col
---@return integer? end_col
---@return RGB? rgb
---@return Alpha? alpha
function LatexCmykPicker:parse_color(s, init)
  self:init()
  init = init or 1
  -- The shortest patten is 15 characters like `{cmyk}{0,0,0,0}`
  while init <= #s - 14 do
    local start_col, end_col, cap1, cap2, cap3, cap4 = pattern.find(s, self.pattern, init)
    if not (start_col and end_col and cap1 and cap2 and cap3 and cap4) then
      return
    end
    local C = parse.percent(cap1)
    local M = parse.percent(cap2)
    local Y = parse.percent(cap3)
    local K = parse.percent(cap4)
    if utils.valid_range({ C, M, Y, K }, 0, 1) then
      local RGB = convert.cmyk2rgb({ C, M, Y, K })
      return start_col, end_col, RGB
    end
    init = end_col + 1
  end
end

return LatexCmykPicker
