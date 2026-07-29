local utils = require("c3po.utils")
local convert = require("c3po.utils.convert")

---@class c3po.ColorOutput
return {
  name = "CssHWB",
  str = function(RGB, A)
    local H, W, B = unpack(convert.rgb2hwb(RGB))
    H = utils.fmt(H, 2)
    W = utils.fmt(W * 100, 2)
    B = utils.fmt(B * 100, 2)
    if A then
      A = utils.fmt(A * 100, 2)
      return ("hwb(%s %s%% %s%% / %s%%)"):format(H, W, B, A)
    else
      return ("hwb(%s %s%% %s%%)"):format(H, W, B)
    end
  end,
}
