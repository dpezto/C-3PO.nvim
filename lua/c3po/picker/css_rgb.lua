local parse = require("c3po.utils.parse")
local pattern = require("c3po.utils.pattern")
local utils = require("c3po.utils")

return require("c3po.picker")({
  min_len = 10, -- rgb(0 0 0)
  patterns = {
    -- The modern syntax lets each channel be a number or a percentage.
    pattern.create("rgba?( [<per-num>|none]  [<per-num>|none]  [<per-num>|none] %[/ [<alpha-value>|none]]? )"),
    pattern.create("rgba?( [<number>|none] , [<number>|none] , [<number>|none] %[, [<alpha-value>|none]]? )"),
    pattern.create(
      "rgba?( [<percentage>|none] , [<percentage>|none] , [<percentage>|none] %[, [<alpha-value>|none]]? )"
    ),
  },
  to_rgb = function(c1, c2, c3, c4)
    local R = parse.percent(c1, 255, true)
    local G = parse.percent(c2, 255, true)
    local B = parse.percent(c3, 255, true)
    -- CSS clamps an out-of-range channel rather than rejecting the color.
    if R and G and B then
      return { utils.clamp(R, 0, 1), utils.clamp(G, 0, 1), utils.clamp(B, 0, 1) }, parse.alpha(c4)
    end
  end,
})
