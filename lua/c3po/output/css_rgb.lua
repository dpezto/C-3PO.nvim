local utils = require("c3po.utils")
local convert = require("c3po.utils.convert")

---@class c3po.ColorOutput
return {
  name = "CssRGB",
  str = function(RGB, A)
    local R, G, B = convert.rgb_format(RGB)
    if A then
      A = utils.fmt(A * 100, 2)
      return ("rgb(%d %d %d / %s%%)"):format(R, G, B, A)
    else
      return ("rgb(%d %d %d)"):format(R, G, B)
    end
  end,
}
