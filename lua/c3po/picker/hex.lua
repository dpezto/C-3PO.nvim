local parse = require("c3po.utils.parse")

-- #RRGGBB, #RRGGBBAA, #RGB and #RGBA
return require("c3po.picker")({
  min_len = 4,
  patterns = {
    [=[\v%(^|[^[:keyword:]])\zs#(\x\x)(\x\x)(\x\x)>]=],
    [=[\v%(^|[^[:keyword:]])\zs#(\x\x)(\x\x)(\x\x)(\x\x)>]=],
    [=[\v%(^|[^[:keyword:]])\zs#(\x)(\x)(\x)>]=],
    [=[\v%(^|[^[:keyword:]])\zs#(\x)(\x)(\x)(\x)>]=],
  },
  to_rgb = function(c1, c2, c3, c4)
    local r, g, b = parse.hex(c1), parse.hex(c2), parse.hex(c3)
    if r and g and b then
      return { r, g, b }, parse.hex(c4)
    end
  end,
})
