local parse = require("c3po.utils.parse")
local pattern = require("c3po.utils.pattern")
local utils = require("c3po.utils")

return require("c3po.picker")({
  min_len = 10, -- rgb(0 0 0)
  patterns = {
    pattern.create("rgba?( [<number>|none]  [<number>|none]  [<number>|none] %[/ [<alpha-value>|none]]? )"),
    pattern.create("rgba?( [<percentage>|none]  [<percentage>|none]  [<percentage>|none] %[/ [<alpha-value>|none]]? )"),
    pattern.create("rgba?( [<number>|none] , [<number>|none] , [<number>|none] %[, [<alpha-value>|none]]? )"),
    pattern.create(
      "rgba?( [<percentage>|none] , [<percentage>|none] , [<percentage>|none] %[, [<alpha-value>|none]]? )"
    ),
  },
  to_rgb = function(c1, c2, c3, c4)
    local R = parse.percent(c1, 255, true)
    local G = parse.percent(c2, 255, true)
    local B = parse.percent(c3, 255, true)
    if utils.valid_range({ R, G, B }, 0, 1) then
      return { R, G, B }, parse.alpha(c4)
    end
  end,
})
