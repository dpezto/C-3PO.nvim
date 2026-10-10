local convert = require("c3po.utils.convert")
local parse = require("c3po.utils.parse")
local pattern = require("c3po.utils.pattern")
local utils = require("c3po.utils")

return require("c3po.picker")({
  min_len = 10, -- lab(0 0 0)
  patterns = {
    pattern.create("lab( [<per-num>|none]  [<per-num>|none]  [<per-num>|none] %[/ [<alpha-value>|none]]? )"),
  },
  to_rgb = function(c1, c2, c3, c4)
    local L, a, b = parse.percent(c1, 100), parse.percent(c2, 125), parse.percent(c3, 125)
    -- L is clamped; a and b are unbounded, 125 is only what 100% stands for.
    if L and a and b then
      return convert.lab2rgb({ utils.clamp(L, 0, 100), a, b }), parse.alpha(c4)
    end
  end,
})
