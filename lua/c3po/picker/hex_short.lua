local HexPicker = require("c3po.picker.hex")

---@class c3po.ColorPicker.HexShort: c3po.ColorPicker.Hex
local HexShortPicker = setmetatable({}, { __index = HexPicker })

-- #RGB
-- #RGBA
HexShortPicker.pattern = {
  [=[\v%(^|[^[:keyword:]])\zs#(\x)(\x)(\x)>]=],
  [=[\v%(^|[^[:keyword:]])\zs#(\x)(\x)(\x)(\x)>]=],
}

return HexShortPicker
