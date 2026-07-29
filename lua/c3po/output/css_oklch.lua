local utils = require("c3po.utils")
local convert = require("c3po.utils.convert")

---@class c3po.ColorOutput
return {
  name = "CssOKLCH",
  str = function(RGB, A)
    local L, C, H = unpack(convert.rgb2oklch(RGB))
    -- C lives in roughly [0, 0.4] and feeds a cube plus the sRGB gamma,
    -- so near-black channels need five decimals to round-trip.
    L = utils.fmt(L * 100, 3)
    C = utils.fmt(C, 5)
    H = utils.fmt(H, 3)
    if A then
      A = utils.fmt(A * 100, 2)
      return ("oklch(%s%% %s %s / %s%%)"):format(L, C, H, A)
    else
      return ("oklch(%s%% %s %s)"):format(L, C, H)
    end
  end,
}
