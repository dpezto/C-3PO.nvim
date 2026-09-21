---xcolor color expressions: `myred!50!myblue`, `red!30`, `-green`,
---`rgb:red,1;blue,2`. Pure -- names come in as a table, so this is the seam the
---tests drive and the file has no buffer or filesystem access.
---
---The grammar follows xcolor.sty's own parser (\@xcolor@@ and \XC@split@iii..v):
---`A!p!B` is `p%` of A plus `(100-p)%` of B, chained left to right; a trailing
---percentage mixes with white; a leading `-` complements the *result* of the
---whole chain.
---
---ponytail: every mix happens in the stored RGB floats. xcolor mixes in the
---color's own model, so a cmyk-defined color mixes slightly differently there,
---and the extended form's core model is validated but not used as the mixing
---space. Tracking each name's defining model through scan_lines is what that
---would cost; the visible difference is a few units per channel.
local M = {}

-- The models xcolor accepts as the core model of an extended expression. The
-- charclass that finds an expression in the buffer is deliberately permissive,
-- so this is what keeps `http://x` out.
local CORE = { rgb = true, cmy = true, cmyk = true, hsb = true, gray = true }

---@param rgb RGB
---@return RGB
local function clamp(rgb)
  for i = 1, 3 do
    rgb[i] = math.min(math.max(rgb[i], 0), 1)
  end
  return rgb
end

---@param expr string
---@param names table<string, RGB>
---@return RGB?
local function standard(expr, names)
  -- An odd number of `-` complements. xcolor strips them from the first name
  -- but applies the complement once the whole chain has been evaluated.
  local dashes, rest = expr:match("^(%-*)(.*)$")
  local parts = vim.split(rest, "!", { plain = true })
  local rgb = names[parts[1]]
  if rgb == nil then
    return
  end

  local i = 2
  while i <= #parts do
    -- `A!!B` is the color-series postfix, not a mix: an empty percentage means
    -- 100, which keeps A whatever B is.
    local pct = parts[i] == "" and 100 or tonumber(parts[i])
    if pct == nil or pct < 0 or pct > 100 then
      return
    end
    -- `A!p` is `A!p!white`, taken from the name table so that a document
    -- redefining white mixes with its own. The partner goes back through
    -- evaluate() because it may carry a `-` prefix of its own.
    local other
    if parts[i + 1] == nil then
      other = names.white
    else
      other = M.evaluate(parts[i + 1], names)
    end
    if other == nil then
      return
    end
    local w = pct / 100
    rgb = { rgb[1] * w + other[1] * (1 - w), rgb[2] * w + other[2] * (1 - w), rgb[3] * w + other[3] * (1 - w) }
    i = i + 2
  end

  if #dashes % 2 == 1 then
    rgb = { 1 - rgb[1], 1 - rgb[2], 1 - rgb[3] }
  end
  return rgb
end

---`<model>[,<div>]:<expr>,<weight>;<expr>,<weight>;...`, a weighted sum
---divided by <div>, or by the sum of the weights when it is omitted.
---@param head string
---@param body string
---@param names table<string, RGB>
---@return RGB?
local function extended(head, body, names)
  local model, div = head:match("^([^,]*),?(.*)$")
  if not CORE[model] then
    return
  end

  local terms, sum = {}, 0
  for _, term in ipairs(vim.split(body, ";", { plain = true })) do
    -- xcolor's parser stops at an empty entry, so a trailing `;` is not an error.
    if term ~= "" then
      local sub, weight = term:match("^([^,]*),([^,]*)$")
      local w = weight and tonumber(weight)
      local rgb = sub and M.evaluate(sub, names)
      if not (rgb and w) then
        return
      end
      terms[#terms + 1] = { rgb, w }
      sum = sum + w
    end
  end
  if #terms == 0 then
    return
  end

  local total = div ~= "" and tonumber(div) or sum
  if total == nil or total == 0 then
    return
  end
  local out = { 0, 0, 0 }
  for _, term in ipairs(terms) do
    local rgb, w = term[1], term[2] / total
    out[1], out[2], out[3] = out[1] + rgb[1] * w, out[2] + rgb[2] * w, out[3] + rgb[3] * w
  end
  return out
end

---@param expr string
---@param names table<string, RGB> #Every name the expression may refer to
---@return RGB? #nil when a name is unknown or the expression is malformed
function M.evaluate(expr, names)
  local head, body = expr:match("^([^:]*):(.*)$")
  local rgb
  if head then
    rgb = extended(head, body, names)
  else
    rgb = standard(expr, names)
  end
  -- Weights may be negative, and a complemented mix can land just outside the
  -- cube through rounding; xcolor clamps to the model's range too.
  return rgb and clamp(rgb)
end

return M
