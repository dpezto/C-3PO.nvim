local utils = require("c3po.utils")

---@class c3po.ColorInput
local ColorInput = {}

---@param n number
---@return string
function ColorInput.format(n, _)
  n = utils.round(n)
  return ("%6d"):format(n)
end

---Hue in degrees for the first channel, percentages for the rest.
---Shared by HSL, HSV, HWB, OKHSL and OKHSV.
---@param n number
---@param i integer
---@return string
function ColorInput.format_deg_percent(n, i)
  if i > 1 then
    n = n * 100
  end
  return ("%6d"):format(utils.round(n))
end

---Every channel as a percentage with half-point resolution.
---Shared by CMYK and XYZ.
---@param n number
---@return string
function ColorInput.format_percent(n)
  return ("%5.1f%%"):format(math.floor(n * 200) / 2)
end

function ColorInput:new()
  return setmetatable({}, { __index = self })
end

---@param index integer
---@param new_value number
function ColorInput:callback(index, new_value)
  self.value[index] = new_value
end

---@param value number[]
function ColorInput:set(value)
  for i, v in ipairs(value) do
    value[i] = utils.clamp(v, self.min[i], self.max[i])
  end
  self.value = value
end

---@param RGB RGB
function ColorInput:set_rgb(RGB)
  self:set(self.from_rgb(RGB))
end

--- Returns a shallow copy
---@return number[] value
function ColorInput:get()
  return { unpack(self.value) }
end

---@return RGB
function ColorInput:get_rgb()
  return self.to_rgb(self:get())
end

return ColorInput
