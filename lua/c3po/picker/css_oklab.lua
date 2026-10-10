local convert = require("c3po.utils.convert")
local parse = require("c3po.utils.parse")
local pattern = require("c3po.utils.pattern")
local utils = require("c3po.utils")

return require("c3po.picker")({
  min_len = 12, -- oklab(0 0 0)
  patterns = {
    pattern.create("oklab( [<per-num>|none]  [<per-num>|none]  [<per-num>|none] %[/ [<alpha-value>|none]]? )"),
  },
  to_rgb = function(c1, c2, c3, c4)
    local L, a, b = parse.percent(c1), parse.percent(c2, 0.4), parse.percent(c3, 0.4)
    -- L is clamped; a and b are unbounded, 0.4 is only what 100% stands for.
    if L and a and b then
      return convert.oklab2rgb({ utils.clamp(L, 0, 1), a, b }), parse.alpha(c4)
    end
  end,
})
