local utils = require("c3po.utils")
local convert = require("c3po.utils.convert")

---@class c3po.ColorOutput
return {
  name = "CssOKLCH",
  str = function(RGB, A)
    local L, C, H = unpack(convert.rgb2oklch(RGB))
    L = utils.round(L * 100)
    C = utils.round(C, 2)
    H = utils.round(H)
    if A then
      A = utils.round(A * 100)
      return ("oklch(%d%% %.2f %d / %d%%)"):format(L, C, H, A)
    else
      return ("oklch(%d%% %.2f %d)"):format(L, C, H)
    end
  end,
}
