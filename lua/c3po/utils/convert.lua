local utils = require("c3po.utils")
local hsluv = require("c3po.utils.hsluv")
local ok = require("c3po.utils.ok_colorspace")

local convert = {}

---@param RGB RGB
---@return RGB
local function rgb_clamp(RGB)
  return vim.tbl_map(function(x)
    return utils.clamp(x, 0, 1)
  end, RGB)
end

---@param RGB RGB
---@return integer R #0-255
---@return integer G #0-255
---@return integer B #0-255
function convert.rgb_format(RGB)
  RGB = vim.tbl_map(function(n)
    return utils.round(n * 255)
  end, RGB)
  return unpack(RGB)
end

---@param RGB RGB
---@return HSLuv
function convert.rgb2hsluv(RGB)
  return hsluv.rgb_to_hsluv(RGB)
end

---@param HSLuv HSLuv
---@return RGB
function convert.hsluv2rgb(HSLuv)
  local RGB = (hsluv.hsluv_to_rgb(HSLuv))
  return rgb_clamp(RGB)
end

---@param RGB RGB
---@return HSL
function convert.rgb2hsl(RGB)
  local R, G, B = unpack(RGB)
  local H, S, L

  local MAX = utils.max(R, G, B)
  local MIN = utils.min(R, G, B)

  L = (MAX + MIN) / 2

  if MAX == MIN then
    H = 0
    S = 0
  else
    if MAX == R then
      H = (G - B) / (MAX - MIN) * 60
    elseif MAX == G then
      H = (B - R) / (MAX - MIN) * 60 + 120
    else
      H = (R - G) / (MAX - MIN) * 60 + 240
    end
    H = H % 360

    if L < 0.5 then
      S = (MAX - MIN) / (MAX + MIN)
    else
      S = (MAX - MIN) / (2 - (MAX + MIN))
    end
  end

  return { H, S, L }
end

---@param HSL HSL
---@return RGB
function convert.hsl2rgb(HSL)
  local H, S, L = unpack(HSL)
  local RGB

  H = H % 360

  local L_ = L < 0.5 and L or 1 - L

  local MAX = (L + L_ * S)
  local MIN = (L - L_ * S)

  local function f(x)
    return x / 60 * (MAX - MIN) + MIN
  end

  if H < 60 then
    RGB = { MAX, f(H), MIN }
  elseif H < 120 then
    RGB = { f(120 - H), MAX, MIN }
  elseif H < 180 then
    RGB = { MIN, MAX, f(H - 120) }
  elseif H < 240 then
    RGB = { MIN, f(240 - H), MAX }
  elseif H < 300 then
    RGB = { f(H - 240), MIN, MAX }
  else
    RGB = { MAX, MIN, f(360 - H) }
  end

  return rgb_clamp(RGB)
end

---@param RGB RGB
---@return HSV
function convert.rgb2hsv(RGB)
  local R, G, B = unpack(RGB)
  local H, S, V

  local MAX = utils.max(R, G, B)
  local MIN = utils.min(R, G, B)

  V = MAX

  if MAX == MIN then
    H = 0
    S = 0
  else
    if MAX == R then
      H = (G - B) / (MAX - MIN) * 60
    elseif MAX == G then
      H = (B - R) / (MAX - MIN) * 60 + 120
    else
      H = (R - G) / (MAX - MIN) * 60 + 240
    end
    H = H % 360
    -- MAX ~= MIN here, so MAX (== V) is strictly positive.
    S = (MAX - MIN) / MAX
  end

  return { H, S, V }
end

---@param HSV HSV
---@return RGB
function convert.hsv2rgb(HSV)
  local H, S, V = unpack(HSV)
  local RGB

  H = H % 360

  local MAX = V
  local MIN = MAX - S * MAX

  local function f(x)
    return x / 60 * (MAX - MIN) + MIN
  end

  if H < 60 then
    RGB = { MAX, f(H), MIN }
  elseif H < 120 then
    RGB = { f(120 - H), MAX, MIN }
  elseif H < 180 then
    RGB = { MIN, MAX, f(H - 120) }
  elseif H < 240 then
    RGB = { MIN, f(240 - H), MAX }
  elseif H < 300 then
    RGB = { f(H - 240), MIN, MAX }
  else
    RGB = { MAX, MIN, f(360 - H) }
  end

  return rgb_clamp(RGB)
end

-- xcolor's default \rangetHsb tuning, with the implicit (0,0) and (360,360)
-- endpoints. tHsb hue on the x axis, Hsb hue on the y axis; both strictly
-- increasing, so the map is invertible by swapping the axes.
local THSB_POINTS = { { 0, 0 }, { 60, 30 }, { 120, 60 }, { 180, 120 }, { 210, 180 }, { 240, 240 }, { 360, 360 } }

---@param hue number #Degrees
---@param x integer #1 to read the x axis as input, 2 for the inverse
---@return number #Degrees
local function thsb_polyline(hue, x)
  local y = 3 - x
  for i = 2, #THSB_POINTS do
    local p, q = THSB_POINTS[i - 1], THSB_POINTS[i]
    if hue <= q[x] then
      return p[y] + (q[y] - p[y]) / (q[x] - p[x]) * (hue - p[x])
    end
  end
  return hue
end

---xcolor's tuned hue (tHsb model) to a plain Hsb hue, both in degrees.
---@param hue number
---@return number
function convert.thsb2hsb_hue(hue)
  return thsb_polyline(hue, 1)
end

---@param hue number
---@return number
function convert.hsb2thsb_hue(hue)
  return thsb_polyline(hue, 2)
end

---xcolor's wave model: a wavelength in nanometers to HSV, per the xcolor
---manual's wave-to-hsb conversion (Bruton's algorithm, gamma = 1). Saturation
---is always full; brightness fades to black outside roughly [363, 814] nm.
---@param lambda number
---@return HSV
function convert.wave2hsv(lambda)
  local function clamp01(x)
    return math.min(1, math.max(0, x))
  end
  local hue
  if lambda < 440 then
    hue = 4 + clamp01((lambda - 440) / (380 - 440))
  elseif lambda < 490 then
    hue = 4 - clamp01((lambda - 440) / (490 - 440))
  elseif lambda < 510 then
    hue = 2 + clamp01((lambda - 510) / (490 - 510))
  elseif lambda < 580 then
    hue = 2 - clamp01((lambda - 510) / (580 - 510))
  elseif lambda < 645 then
    hue = clamp01((lambda - 645) / (580 - 645))
  else
    hue = 0
  end
  local brightness
  if lambda < 420 then
    brightness = clamp01(0.3 + 0.7 * (lambda - 380) / (420 - 380))
  elseif lambda <= 700 then
    brightness = 1
  else
    brightness = clamp01(0.3 + 0.7 * (lambda - 780) / (700 - 780))
  end
  -- The manual's hue is a fraction of a turn; rgb2hsv/hsv2rgb speak degrees.
  return { hue * 60, 1, brightness }
end

---@param RGB RGB
---@return CMYK
function convert.rgb2cmyk(RGB)
  local R, G, B = unpack(RGB)
  local K = 1 - utils.max(R, G, B)
  if K == 1 then
    return { 0, 0, 0, 1 }
  end
  return {
    (1 - R - K) / (1 - K),
    (1 - G - K) / (1 - K),
    (1 - B - K) / (1 - K),
    K,
  }
end

---@param CMYK CMYK
---@return RGB
function convert.cmyk2rgb(CMYK)
  local C, M, Y, K = unpack(CMYK)
  if K == 1 then
    return { 0, 0, 0 }
  end
  local RGB = {
    (1 - C) * (1 - K),
    (1 - M) * (1 - K),
    (1 - Y) * (1 - K),
  }
  return rgb_clamp(RGB)
end

---@param RGB RGB
---@return linearRGB
function convert.rgb2linear(RGB)
  return vim.tbl_map(function(x)
    if x <= 0.04045 then
      return x / 12.92
    end
    return ((x + 0.055) / 1.055) ^ 2.4
  end, RGB)
end

---@param Linear linearRGB
---@return RGB
function convert.linear2rgb(Linear)
  local RGB = vim.tbl_map(function(x)
    if x <= 0.0031308 then
      return 12.92 * x
    else
      return 1.055 * x ^ (1 / 2.4) - 0.055
    end
  end, Linear)
  return rgb_clamp(RGB)
end

---@alias matrix number[][]
---@alias vector number[]

---@param a vector
---@param b vector
---@return number
local function dot(a, b)
  assert(#a == #b)
  local result = 0
  for i = 1, #a do
    result = result + a[i] * b[i]
  end
  return result
end

---@param m matrix
---@param v vector
---@return vector
local function product(m, v)
  local row = #m
  local result = {}
  for i = 1, row do
    result[i] = dot(m[i], v)
  end
  return result
end

local linear2xyz = {
  { 0.41239079926595, 0.35758433938387, 0.18048078840183 },
  { 0.21263900587151, 0.71516867876775, 0.072192315360733 },
  { 0.019330818715591, 0.11919477979462, 0.95053215224966 },
}
local xyz2linear = {
  { 3.240969941904521, -1.537383177570093, -0.498610760293 },
  { -0.96924363628087, 1.87596750150772, 0.041555057407175 },
  { 0.055630079696993, -0.20397695888897, 1.056971514242878 },
}

---@param Linear linearRGB
---@return XYZ
function convert.linear2xyz(Linear)
  return product(linear2xyz, Linear)
end

---@param XYZ XYZ
---@return linearRGB
function convert.xyz2linear(XYZ)
  return product(xyz2linear, XYZ)
end

---@param RGB RGB
---@return XYZ
function convert.rgb2xyz(RGB)
  local Linear = convert.rgb2linear(RGB)
  return convert.linear2xyz(Linear)
end

---@param XYZ XYZ
---@return RGB
function convert.xyz2rgb(XYZ)
  local Linear = convert.xyz2linear(XYZ)
  local RGB = convert.linear2rgb(Linear)
  return rgb_clamp(RGB)
end

---@param XYZ XYZ
---@return Lab
function convert.xyz2lab(XYZ)
  local X, Y, Z = unpack(XYZ)
  local Xn, Yn, Zn = 0.9505, 1, 1.089
  local function f(t)
    if t > (6 / 29) ^ 3 then
      return 116 * t ^ (1 / 3) - 16
    end
    return (29 / 3) ^ 3 * t
  end
  local fy = f(Y / Yn)
  return {
    fy,
    (500 / 116) * (f(X / Xn) - fy),
    (200 / 116) * (fy - f(Z / Zn)),
  }
end

---@param Lab Lab
---@return XYZ
function convert.lab2xyz(Lab)
  local L, a, b = unpack(Lab)
  local Xn, Yn, Zn = 0.9505, 1, 1.089
  local fy = (L + 16) / 116
  local fx = fy + (a / 500)
  local fz = fy - (b / 200)
  local function t(f)
    if f > 6 / 29 then
      return f ^ 3
    end
    return (116 * f - 16) * (3 / 29) ^ 3
  end
  return {
    t(fx) * Xn,
    t(fy) * Yn,
    t(fz) * Zn,
  }
end

---@param RGB RGB
---@return Lab
function convert.rgb2lab(RGB)
  local Linear = convert.rgb2linear(RGB)
  local XYZ = convert.linear2xyz(Linear)
  return convert.xyz2lab(XYZ)
end

---@param Lab Lab
---@return RGB
function convert.lab2rgb(Lab)
  local XYZ = convert.lab2xyz(Lab)
  local Linear = convert.xyz2linear(XYZ)
  local RGB = convert.linear2rgb(Linear)
  return rgb_clamp(RGB)
end

---@param RGB RGB
---@return OKLab
function convert.rgb2oklab(RGB)
  return ok.srgb_to_oklab(RGB)
end

---@param OKLab OKLab
---@return RGB
function convert.oklab2rgb(OKLab)
  local RGB = ok.oklab_to_srgb(OKLab)
  return rgb_clamp(RGB)
end

---@param RGB RGB
---@return OKHSV
function convert.rgb2okhsv(RGB)
  local OKHSV = ok.srgb_to_okhsv(RGB)
  OKHSV[1] = OKHSV[1] * 360
  return OKHSV
end

---@param OKHSV OKHSV
---@return RGB
function convert.okhsv2rgb(OKHSV)
  local h, s, v = unpack(OKHSV)
  h = h / 360
  local RGB = ok.okhsv_to_srgb({ h, s, v })
  return rgb_clamp(RGB)
end

---@param RGB RGB
---@return OKHSL
function convert.rgb2okhsl(RGB)
  local OKHSL = ok.srgb_to_okhsl(RGB)
  OKHSL[1] = OKHSL[1] * 360
  return OKHSL
end

---@param OKHSL OKHSL
---@return RGB
function convert.okhsl2rgb(OKHSL)
  local h, s, l = unpack(OKHSL)
  h = h / 360
  local RGB = ok.okhsl_to_srgb({ h, s, l })
  return rgb_clamp(RGB)
end

---@param RGB RGB
---@return HWB
function convert.rgb2hwb(RGB)
  local HSL = convert.rgb2hsl(RGB)
  local W = utils.min(unpack(RGB))
  local B = 1 - utils.max(unpack(RGB))
  return { HSL[1], W, B }
end

---@param HWB HWB
---@return RGB
function convert.hwb2rgb(HWB)
  local H, W, B = unpack(HWB)
  if W + B >= 1 then
    local gray = W / (W + B)
    return rgb_clamp({ gray, gray, gray })
  end
  local RGB = convert.hsl2rgb({ H, 1, 0.5 })
  for i = 1, 3 do
    RGB[i] = RGB[i] * (1 - W - B) + W
  end
  return rgb_clamp(RGB)
end

---@param Lab Lab
---@return LCH
function convert.lab2lch(Lab)
  local L, a, b = unpack(Lab)
  local H = math.atan2(b, a)
  local C = math.sqrt(a ^ 2 + b ^ 2)
  H = H / (2 * math.pi) * 360 -- [rad] -> [deg]
  H = H % 360
  return { L, C, H }
end

---@param LCH LCH
---@return Lab
function convert.lch2lab(LCH)
  local L, C, H = unpack(LCH)
  H = H / 360 * (2 * math.pi) -- [deg] -> [rad]
  local a = C * math.cos(H)
  local b = C * math.sin(H)
  return { L, a, b }
end

---@param RGB RGB
---@return LCH
function convert.rgb2lch(RGB)
  local Lab = convert.rgb2lab(RGB)
  return convert.lab2lch(Lab)
end

---@param LCH LCH
---@return RGB
function convert.lch2rgb(LCH)
  local Lab = convert.lch2lab(LCH)
  local RGB = convert.lab2rgb(Lab)
  return rgb_clamp(RGB)
end

---@param RGB RGB
---@return OKLCH
function convert.rgb2oklch(RGB)
  local Lab = convert.rgb2oklab(RGB)
  return convert.lab2lch(Lab)
end

---@param OKLCH OKLCH
---@return RGB
function convert.oklch2rgb(OKLCH)
  local Lab = convert.lch2lab(OKLCH)
  local RGB = convert.oklab2rgb(Lab)
  return rgb_clamp(RGB)
end

return convert
