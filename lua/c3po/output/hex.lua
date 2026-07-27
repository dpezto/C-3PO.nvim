local utils = require("c3po.utils")
local convert = require("c3po.utils.convert")

local pattern = {
  uppercase = {
    "#%02X%02X%02X%02X",
    "#%02X%02X%02X",
  },
  lowercase = {
    "#%02x%02x%02x%02x",
    "#%02x%02x%02x",
  },
}

---@class c3po.ColorOutput
local HexOutput = {
  name = "HEX",
  pattern = pattern.lowercase,
}

---@param opt { uppercase?: boolean }
function HexOutput.setup(opt)
  if opt.uppercase then
    HexOutput.pattern = pattern.uppercase
  else
    HexOutput.pattern = pattern.lowercase
  end
end

function HexOutput.str(RGB, A)
  local R, G, B = convert.rgb_format(RGB)
  if A then
    A = utils.round(A * 255)
    return HexOutput.pattern[1]:format(R, G, B, A)
  else
    return HexOutput.pattern[2]:format(R, G, B)
  end
end

return HexOutput
