local utils = require("c3po.utils")
local convert = require("c3po.utils.convert")
local parse = require("c3po.utils.parse")
local pattern = require("c3po.utils.pattern")

---One picker for every xcolor color specification, `{model}{values}`, with or
---without a surrounding \definecolor. Each model is its own pattern, so the
---model name decides both the value count and the value scale.
---@class c3po.ColorPicker.Latex: c3po.ColorPicker
---@field models { name: string, pattern: string, to_rgb: fun(caps: string[]): RGB? }[]
local LatexPicker = {}

---@param cap? string
---@param ratio? number
---@return number?
local function per(cap, ratio)
  if cap == nil then
    return
  end
  return parse.percent(cap, ratio or 1, true)
end

---@param model string
---@param n integer #Number of values
---@param token string #pattern.create() token for one value
---@return string
local function spec(model, n, token)
  local values = {}
  for i = 1, n do
    values[i] = token
  end
  -- \C: the case of the model name picks the value scale ({rgb} is [0,1],
  -- {RGB} is [0,255]), so 'ignorecase' must never blur them together.
  return [[\C]] .. pattern.create(("{%s}{ %s }"):format(model, table.concat(values, " , ")))
end

local NUM = "[<number>]"
local PER = "[<per-num>|none]"

function LatexPicker:init()
  if self.models then
    return
  end
  self.models = {
    {
      name = "RGB",
      pattern = spec("RGB", 3, NUM),
      to_rgb = function(c)
        return { per(c[1], 255), per(c[2], 255), per(c[3], 255) }
      end,
    },
    {
      name = "rgb",
      pattern = spec("rgb", 3, PER),
      to_rgb = function(c)
        return { per(c[1]), per(c[2]), per(c[3]) }
      end,
    },
    {
      -- xcolor's HTML model is always exactly six hex digits, which needs a
      -- character class that pattern.create() does not provide.
      name = "HTML",
      pattern = [=[\C\V{HTML}{\(\x\x\)\(\x\x\)\(\x\x\)}]=],
      to_rgb = function(c)
        return { parse.hex(c[1]), parse.hex(c[2]), parse.hex(c[3]) }
      end,
    },
    {
      name = "cmyk",
      pattern = spec("cmyk", 4, PER),
      to_rgb = function(c)
        local C, M, Y, K = per(c[1]), per(c[2]), per(c[3]), per(c[4])
        if not (C and M and Y and K) or not utils.valid_range({ C, M, Y, K }, 0, 1) then
          return
        end
        return convert.cmyk2rgb({ C, M, Y, K })
      end,
    },
    {
      name = "cmy",
      pattern = spec("cmy", 3, PER),
      to_rgb = function(c)
        local C, M, Y = per(c[1]), per(c[2]), per(c[3])
        if not (C and M and Y) or not utils.valid_range({ C, M, Y }, 0, 1) then
          return
        end
        return { 1 - C, 1 - M, 1 - Y }
      end,
    },
    {
      name = "hsb",
      pattern = spec("hsb", 3, PER),
      to_rgb = function(c)
        local H, S, B = per(c[1]), per(c[2]), per(c[3])
        if not (H and S and B) or not utils.valid_range({ H, S, B }, 0, 1) then
          return
        end
        return convert.hsv2rgb({ H * 360, S, B })
      end,
    },
    {
      -- HSB scales all three components to [0, 240], the hue included.
      name = "HSB",
      pattern = spec("HSB", 3, NUM),
      to_rgb = function(c)
        local H, S, B = per(c[1], 240), per(c[2], 240), per(c[3], 240)
        if not (H and S and B) or not utils.valid_range({ H, S, B }, 0, 1) then
          return
        end
        return convert.hsv2rgb({ H * 360, S, B })
      end,
    },
    {
      name = "gray",
      pattern = spec("gray", 1, PER),
      to_rgb = function(c)
        local G = per(c[1])
        return { G, G, G }
      end,
    },
    {
      -- Gray is an integer scale of [0, 15].
      name = "Gray",
      pattern = spec("Gray", 1, NUM),
      to_rgb = function(c)
        local G = per(c[1], 15)
        return { G, G, G }
      end,
    },
  }
end

---A view of this picker restricted to some models. Convert cycles pair one
---picker with one output, so cycling within latex formats needs pickers that
---only match their own model.
---@param names string[]
---@return c3po.ColorPicker.Latex
function LatexPicker.only(names)
  LatexPicker:init()
  local models = {}
  for _, model in ipairs(LatexPicker.models) do
    if vim.tbl_contains(names, model.name) then
      models[#models + 1] = model
    end
  end
  return setmetatable({ models = models }, { __index = LatexPicker })
end

---@param s string
---@param init? integer
---@return integer? start_col
---@return integer? end_col
---@return RGB? rgb
---@return Alpha? alpha #Always nil; xcolor specifications carry no alpha.
function LatexPicker:parse_color(s, init)
  self:init()
  init = init or 1
  while init <= #s do
    -- The earliest match across all models, like pattern.find_first(), except
    -- that converting the values needs to know which model matched.
    ---@type table?, { pattern: string, to_rgb: fun(caps: string[]): RGB? }?
    local best, best_model
    for _, model in ipairs(self.models) do
      local result = { pattern.find(s, model.pattern, init) }
      if result[1] and (best == nil or result[1] < best[1]) then
        best, best_model = result, model
      end
    end
    if best == nil or best_model == nil then
      return
    end
    local RGB = best_model.to_rgb({ unpack(best, 3, 6) })
    if RGB and RGB[1] and RGB[2] and RGB[3] and utils.valid_range(RGB, 0, 1) then
      return best[1], best[2], RGB
    end
    init = best[2] + 1
  end
end

return LatexPicker
