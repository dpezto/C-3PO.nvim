local utils = require("c3po.utils")
local parse = require("c3po.utils.parse")
local pattern = require("c3po.utils.pattern")

---@class c3po.ColorPicker.CssRgb: c3po.ColorPicker
---@field pattern string[]
local CssRgbPicker = {}

function CssRgbPicker:init()
  if self.pattern then
    return
  end
  self.pattern = {
    pattern.create("rgba?( [<number>|none]  [<number>|none]  [<number>|none] %[/ [<alpha-value>|none]]? )"),
    pattern.create("rgba?( [<percentage>|none]  [<percentage>|none]  [<percentage>|none] %[/ [<alpha-value>|none]]? )"),
    pattern.create("rgba?( [<number>|none] , [<number>|none] , [<number>|none] %[, [<alpha-value>|none]]? )"),
    pattern.create(
      "rgba?( [<percentage>|none] , [<percentage>|none] , [<percentage>|none] %[, [<alpha-value>|none]]? )"
    ),
  }
end

---@param s string
---@param init? integer
---@return integer? start_col
---@return integer? end_col
---@return RGB? rgb
---@return Alpha? alpha
function CssRgbPicker:parse_color(s, init)
  self:init()
  init = init or 1
  -- The shortest patten is 10 characters like `rgb(0 0 0)`
  while init <= #s - 9 do
    local start_col, end_col, cap1, cap2, cap3, cap4 = pattern.find_first(s, self.pattern, init)
    if not (start_col and end_col and cap1 and cap2 and cap3) then
      return
    end
    local R = parse.percent(cap1, 255, true)
    local G = parse.percent(cap2, 255, true)
    local B = parse.percent(cap3, 255, true)
    if utils.valid_range({ R, G, B }, 0, 1) then
      local A = parse.alpha(cap4)
      return start_col, end_col, { R, G, B }, A
    end
    init = end_col + 1
  end
end

return CssRgbPicker
