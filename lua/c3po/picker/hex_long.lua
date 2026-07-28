local HexPicker = require("c3po.picker.hex")

---@class c3po.ColorPicker.HexLong: c3po.ColorPicker.Hex
local HexLongPicker = setmetatable({}, { __index = HexPicker })

-- #RRGGBB
-- #RRGGBBAA
HexLongPicker.pattern = {
  [=[\v%(^|[^[:keyword:]])\zs#(\x\x)(\x\x)(\x\x)>]=],
  [=[\v%(^|[^[:keyword:]])\zs#(\x\x)(\x\x)(\x\x)(\x\x)>]=],
}

return HexLongPicker
