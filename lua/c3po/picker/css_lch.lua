local convert = require("c3po.utils.convert")
local parse = require("c3po.utils.parse")
local pattern = require("c3po.utils.pattern")
local utils = require("c3po.utils")

return require("c3po.picker")({
  min_len = 10, -- lch(0 0 0)
  patterns = {
    pattern.create("lch( [<per-num>|none]  [<per-num>|none]  [<hue>|none] %[/ [<alpha-value>|none]]? )"),
  },
  to_rgb = function(c1, c2, c3, c4)
    local L, C, H = parse.percent(c1, 100), parse.percent(c2, 150), parse.hue(c3)
    if utils.valid_range(L, 0, 100) and utils.valid_range(C, 0, 150) and H then
      return convert.lch2rgb({ L, C, H }), parse.alpha(c4)
    end
  end,
})
