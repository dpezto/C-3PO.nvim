local convert = require("c3po.utils.convert")
local parse = require("c3po.utils.parse")
local pattern = require("c3po.utils.pattern")
local utils = require("c3po.utils")

return require("c3po.picker")({
  min_len = 12, -- oklch(0 0 0)
  patterns = {
    pattern.create("oklch( [<per-num>|none]  [<per-num>|none]  [<hue>|none] %[/ [<alpha-value>|none]]? )"),
  },
  to_rgb = function(c1, c2, c3, c4)
    local L, C, H = parse.percent(c1, 1), parse.percent(c2, 0.4), parse.hue(c3)
    if utils.valid_range(L, 0, 1) and utils.valid_range(C, 0, 0.4) and H then
      return convert.oklch2rgb({ L, C, H }), parse.alpha(c4)
    end
  end,
})
