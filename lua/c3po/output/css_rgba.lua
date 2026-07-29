local utils = require("c3po.utils")
local convert = require("c3po.utils.convert")

---@class c3po.ColorOutput
return {
  name = "CssRGBA",
  str = function(RGB, A)
    local R, G, B = convert.rgb_format(RGB)
    if A then
      -- three decimals: an alpha from a hex AA byte needs 1/255 resolution
      A = utils.fmt(A, 3)
      return ("rgba(%d, %d, %d, %s)"):format(R, G, B, A)
    else
      return ("rgba(%d, %d, %d, 1)"):format(R, G, B)
    end
  end,
}
