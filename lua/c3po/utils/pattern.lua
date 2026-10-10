local pattern = {}

---@param str string
---@return string regexp #Very no magic.
function pattern.create(str)
  str = str:gsub("  ", [[\s\+]])
  str = str:gsub(" ", [[\s\*]])
  str = str:gsub("%%%[", [[\%%(]])
  str = str:gsub("%[", [[\(]])
  str = str:gsub("|", [[\|]])
  str = str:gsub("%]", [[\)]])
  str = str:gsub("%?", [[\?]])
  str = str:gsub("<alpha%-value>", [[<number>%%\?]])
  str = str:gsub("<per%-num>", [[<number>%%\?]])
  str = str:gsub("<percentage>", [[<number>%%]])
  str = str:gsub("<hue>", [[<number>\%%(deg\|grad\|rad\|turn\)\?]])
  str = str:gsub("<number>", [=[\[+-]\?\%%(\d\+.\?\d\*\|.\d\+\)]=])
  return "\\V" .. str
end

-- Compiling a regexp is far more expensive than running it, and the set of
-- patterns is fixed after each picker's init().
---@type table<string, vim.regex>
local regex_cache = {}

---@param pat string
---@return vim.regex
local function regex(pat)
  local re = regex_cache[pat]
  if re == nil then
    re = vim.regex(pat)
    regex_cache[pat] = re
  end
  return re
end

---@param str string
---@return string?
local function empty2nil(str)
  if str == "" then
    return nil
  end
  return str
end

---@param str string
---@param pat string
---@param init number
---@return integer? start
---@return integer? end
---@return string? ... submatches
local function find(str, pat, init)
  -- matchlist() considers a string containing `\0` as a blob and cannot process them.
  if str:find("\0") then
    return
  end

  local sub = str:sub(init)
  -- The compiled regexp reports where the match actually starts, honouring \zs.
  -- Searching for the matched text with string.find() instead would return the
  -- first place that text happens to appear, which is a different position
  -- whenever the pattern rejected an earlier occurrence (`#fff` in `x#fff #fff`).
  -- It also rejects non-matching lines without paying for matchlist().
  local start0, end0 = regex(pat):match_str(sub)
  if start0 == nil then
    return
  end

  local result = vim.fn.matchlist(sub, pat)
  if #result == 10 then
    table.remove(result, 1)
    result = vim.tbl_map(empty2nil, result)
    return init + start0, init + end0 - 1, unpack(result)
  end
end

-- Where each pattern last found nothing. Highlighting walks a line left to
-- right, asking every pattern again from just past each color found, and a
-- pattern with no match left would rescan the rest of the line every time:
-- quadratic in the colors on the line.
---@type table<string, { str: string, init: integer }>
local missed = {}

---@param str string
---@param pat string
---@param init number
---@return integer? start
---@return integer? end
---@return string? ... submatches
function pattern.find(str, pat, init)
  local prev = missed[pat]
  if prev and prev.str == str and prev.init <= init then
    -- Every attempt that starts past init was already made, and failed, from
    -- prev.init. The one at init itself can still differ, since `^` holds
    -- there now (latex_name's `}{` pattern depends on that), so try just it.
    if init == prev.init or regex("^" .. pat):match_str(str:sub(init)) == nil then
      return
    end
  end
  local result = vim.F.pack_len(find(str, pat, init))
  if result.n == 0 then
    missed[pat] = { str = str, init = init }
  end
  return unpack(result, 1, result.n)
end

---Find the earliest match among several patterns.
---Returns the match with the smallest start column, not the first pattern that
---matches anywhere — those differ whenever a later pattern matches earlier text.
---@param str string
---@param pats string[]
---@param init number
---@return integer? start
---@return integer? end
---@return string? ... submatches
function pattern.find_first(str, pats, init)
  local best
  for _, pat in ipairs(pats) do
    -- On a match pattern.find() always returns start, end and 9 submatches, so
    -- the arity is fixed even though individual captures may be nil.
    local result = { pattern.find(str, pat, init) }
    if result[1] and (best == nil or result[1] < best[1]) then
      best = result
    end
  end
  if best then
    return unpack(best, 1, 11)
  end
end

return pattern
