local convert = require("c3po.utils.convert")
local parse = require("c3po.utils.parse")
local pattern = require("c3po.utils.pattern")
local utils = require("c3po.utils")

return require("c3po.picker")({
  min_len = 12, -- hwb(0 0% 0%)
  patterns = {
    pattern.create("hwb( [<hue>|none]  [<percentage>|none]  [<percentage>|none] %[/ [<alpha-value>|none]]? )"),
  },
  to_rgb = function(c1, c2, c3, c4)
    local H, W, B = parse.hue(c1), parse.percent(c2), parse.percent(c3)
    if H and utils.valid_range({ W, B }, 0, 1) then
      return convert.hwb2rgb({ H, W, B }), parse.alpha(c4)
    end
  end,
})
