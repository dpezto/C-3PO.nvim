local utils = require("c3po.utils")
local convert = require("c3po.utils.convert")

---@class c3po.ColorOutput
return {
  name = "CssOKLab",
  str = function(RGB, A)
    local L, a, b = unpack(convert.rgb2oklab(RGB))
    L = utils.round(L * 100)
    a = utils.round(a, 2)
    b = utils.round(b, 2)
    if A then
      return ("oklab(%d%% %.2f %.2f / %d%%)"):format(L, a, b, A * 100)
    else
      return ("oklab(%d%% %.2f %.2f)"):format(L, a, b)
    end
  end,
}
