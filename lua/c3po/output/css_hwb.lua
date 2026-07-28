local utils = require("c3po.utils")
local convert = require("c3po.utils.convert")

---@class c3po.ColorOutput
return {
  name = "CssHWB",
  str = function(RGB, A)
    local H, W, B = unpack(convert.rgb2hwb(RGB))
    H = utils.round(H)
    W = utils.round(W * 100)
    B = utils.round(B * 100)
    if A then
      A = utils.round(A * 100)
      return ("hwb(%d %d%% %d%% / %d%%)"):format(H, W, B, A)
    else
      return ("hwb(%d %d%% %d%%)"):format(H, W, B)
    end
  end,
}
