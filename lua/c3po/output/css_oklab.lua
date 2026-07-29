local utils = require("c3po.utils")
local convert = require("c3po.utils.convert")

---@class c3po.ColorOutput
return {
  name = "CssOKLab",
  str = function(RGB, A)
    local L, a, b = unpack(convert.rgb2oklab(RGB))
    -- a and b live in roughly [-0.4, 0.4] and feed a cube plus the sRGB
    -- gamma, so near-black channels need five decimals to round-trip.
    L = utils.fmt(L * 100, 3)
    a = utils.fmt(a, 5)
    b = utils.fmt(b, 5)
    if A then
      A = utils.fmt(A * 100, 2)
      return ("oklab(%s%% %s %s / %s%%)"):format(L, a, b, A)
    else
      return ("oklab(%s%% %s %s)"):format(L, a, b)
    end
  end,
}
