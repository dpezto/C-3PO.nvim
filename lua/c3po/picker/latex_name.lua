local expr = require("c3po.picker.latex_expr")
local hl = require("c3po.handler.highlight")
local latex = require("c3po.picker.latex")
local utils = require("c3po.utils")
local pattern = require("c3po.utils.pattern")

---xcolor colors used by name. `\definecolor{R2D2}{RGB}{0, 112, 192}` sits in
---the preamble, `\textcolor{R2D2}{...}` in a chapter file, so resolving a name
---means looking beyond the current buffer.
---@class c3po.ColorPicker.LatexName: c3po.ColorPicker
---@field patterns string[]
local LatexNamePicker = {}

-- The span is a name, not a color literal: overwriting it with `#0070c0` would
-- throw away the indirection the document is built on. `:C3 pick` skips it.
LatexNamePicker.readonly = true

local TEX_FT = { tex = true, latex = true, plaintex = true }

-- A color name is what xcolor lets you write between the braces. `!` is excluded
-- on purpose: it opens a color expression, and a definition names one color.
local NAME = [=[[0-9A-Za-z@_-]+]=]
-- Every character a color expression can be built from. Deliberately a
-- superset: latex_expr is the grammar, and an argument it cannot evaluate is
-- simply not highlighted.
local EXPR = [=[[-0-9A-Za-z@_.,:;!]+]=]
-- \definecolor's optional [type] argument, and \color's optional [model] one.
local OPT = [=[%(\[[^]]*\])?]=]

-- \C: names are case-sensitive, so 'ignorecase' must never merge R2D2 with
-- r2d2. \zs and \ze are what make the reported span the bare name, which is
-- also what keeps the definition's `{RGB}{...}` visible to the latex picker: the
-- handler resumes at the end of the name, not at the end of the command.
local DEFINITION = [=[\C\v\\%(define|provide)color]=] .. OPT .. [=[\{\zs]=] .. NAME .. [=[\ze\}]=]
-- Where a color argument ends. `$` is there so the swatch survives the moment
-- between typing the expression and typing its closing brace.
local ARG_END = [=[\ze%(\}|$)]=]
-- \colorlet as a definition, for scan_lines. `[^{]*` is the optional [type]
-- argument; the value is left to latex_expr, which is the only thing that knows
-- whether it resolves.
local COLORLET = "\\colorlet[^{]*{([0-9A-Za-z@_-]+)}{([^}]+)}"
-- A color argument opened and typed into, for arg_start(). Whatever stands
-- between the brace and the name being completed is the expression so far, so
-- an operand of a mix completes like a first argument does.
local COMMAND_ARG = "\\%a*color%a*{[-0-9A-Za-z@_.,:;!]*$"
local COLORLET_ARG = "\\colorlet{[0-9A-Za-z@_-]+}{[-0-9A-Za-z@_.,:;!]*$"
-- What may stand right before a match: a color command's opening brace,
-- \colorlet's second one, or \fcolorbox's second one, its background. The `}{`
-- pattern below cannot see the command it follows, so without this
-- `\textcolor{red}{blue}` would paint the word blue.
local ARG_PREFIX = {
  "\\%a*color%a*%[?[^%]{]*%]?{$",
  "\\colorlet%[?[^%]{]*%]?{[0-9A-Za-z@_-]+}{$",
  "\\fcolorbox%[?[^%]{]*%]?{[-0-9A-Za-z@_.,:;!]+}{$",
}

---@param before string #The line up to the match
---@return boolean
local function after_color_arg(before)
  for _, prefix in ipairs(ARG_PREFIX) do
    if before:match(prefix) then
      return true
    end
  end
  return false
end

---@return string[]
local function build_patterns()
  return {
    DEFINITION,
    -- Every command that takes a color expression as its first braced argument.
    -- No optional-argument group here: `\color[RGB]{0,112,192}` is a
    -- specification, not a name, and belongs to the latex picker.
    [=[\C\v\\%(text|page|f|cell|row|column)?color%(box)?\*?\{\zs]=] .. EXPR .. ARG_END,
    -- \colorlet{new}{old}: `new` is the name it defines, resolvable once `old`
    -- is.
    [=[\C\v\\colorlet]=] .. OPT .. [=[\{\zs]=] .. NAME .. [=[\ze\}]=],
    -- `old`, the expression `new` is defined as, or \fcolorbox's background.
    -- Neither can be found from its command: the caller resumes the scan just
    -- past the first argument, so by the time this is looked for, the command
    -- name is behind the search start. What is left to key on is the second
    -- group following the first one immediately; ARG_PREFIX then checks which
    -- command that first group belonged to.
    [=[\C\v^\}\{\zs]=] .. EXPR .. ARG_END,
  }
end

-- xcolor's base names, always available without a package option. Kept under the
-- project's own definitions so that `\definecolor{red}{...}` wins.
---@type table<string, RGB>
local BUILTIN = {
  black = { 0, 0, 0 },
  blue = { 0, 0, 1 },
  brown = { 0.75, 0.5, 0.25 },
  cyan = { 0, 1, 1 },
  darkgray = { 0.25, 0.25, 0.25 },
  gray = { 0.5, 0.5, 0.5 },
  green = { 0, 1, 0 },
  lightgray = { 0.75, 0.75, 0.75 },
  lime = { 0.75, 1, 0 },
  magenta = { 1, 0, 1 },
  olive = { 0.5, 0.5, 0 },
  orange = { 1, 0.5, 0 },
  pink = { 1, 0.75, 0.75 },
  purple = { 0.75, 0, 0.25 },
  red = { 1, 0, 0 },
  teal = { 0, 0.5, 0.5 },
  violet = { 0.5, 0, 0.5 },
  white = { 1, 1, 1 },
  yellow = { 1, 1, 0 },
}

---The part of a line TeX reads: everything before the first unescaped `%`.
---@param line string
---@return string
local function strip_comment(line)
  local i = 1
  while true do
    i = line:find("[\\%%]", i)
    if i == nil then
      return line
    elseif line:sub(i, i) == "%" then
      return line:sub(1, i - 1)
    end
    -- A backslash escapes the next character, `\%` and `\\` alike.
    i = i + 2
  end
end

---Collect every `\definecolor` / `\providecolor` these lines resolve, and every
---`\colorlet` they declare. Pure: no filesystem, no buffer, so it is the seam
---the tests drive.
---@param lines string[]
---@return table<string, RGB> #Definitions, resolved
---@return table<string, string> #\colorlet targets, still unevaluated: the
---expression may name a color defined later, or in another file
function LatexNamePicker.scan_lines(lines)
  local names, lets = {}, {}
  for _, line in ipairs(lines) do
    line = strip_comment(line)
    for name, value in line:gmatch(COLORLET) do
      lets[name] = value
    end
    local init = 1
    while init <= #line do
      local start_col, end_col = pattern.find(line, DEFINITION, init)
      if start_col == nil or end_col == nil then
        break
      end
      -- The value follows the closing brace of the name.
      local gap = line:match("^}(%s*)", end_col + 1)
      if gap then
        local spec_init = end_col + 2 + #gap
        local spec_col, _, rgb = latex:parse_color(line, spec_init)
        -- Anchored: a model this plugin does not resolve ({named}) must not
        -- borrow the specification of a later definition on the same line.
        local name = line:sub(start_col, end_col)
        -- \providecolor leaves a color that already exists alone.
        local provide = line:sub(1, start_col - 1):match("\\providecolor%[?[^%]{]*%]?{$")
        if rgb and spec_col == spec_init and not (provide and (names[name] or BUILTIN[name])) then
          names[name] = rgb
        end
      end
      init = end_col + 1
    end
  end
  return names, lets
end

---Resolve `\colorlet` targets against the names already known, repeating while
---anything new comes out: a \colorlet may precede the definition it reads, and
---may read another \colorlet.
---ponytail: quadratic in the number of \colorlet's, which is a handful per
---document. A cycle simply stays unresolved.
---@param names table<string, RGB> #Modified in place
---@param lets table<string, string>
local function resolve(names, lets)
  local pending = vim.tbl_extend("force", {}, lets)
  local progress = true
  while progress do
    progress = false
    for name, value in pairs(pending) do
      local rgb = expr.evaluate(value, names)
      if rgb then
        names[name], pending[name] = rgb, nil
        progress = true
      end
    end
  end
end

---@alias c3po.LatexNameFile { path: string, names: table<string, RGB>, lets: table<string, string> }
---@type table<string, c3po.LatexNameFile[]> #Keyed by project root
local project = {}
---@type table<integer, { names: table<string, RGB>, lets: table<string, string> }> #Keyed by bufnr: the project but the buffer's own file
local bases = {}
---@type table<integer, table<string, RGB>> #Keyed by bufnr, only while modified
local live = {}
---@type table<integer, integer> #The changedtick each live entry was built from
local live_tick = {}
---@type table<integer, string>
local roots = {}

-- texlab's own root markers, plus .git for everyone who has none of them.
local MARKERS = { ".latexmkrc", "latexmkrc", "Tectonic.toml", ".texlabroot", "texlabroot", ".git" }

---The main document this buffer belongs to, when vimtex or a `% !TEX root`
---magic comment names one. A chapter in its own directory finds its preamble
---through it even without a root marker.
---@param bufnr integer
---@param name string #The buffer's file
---@return string?
local function main_of(bufnr, name)
  local vimtex = vim.b[bufnr].vimtex
  if type(vimtex) == "table" and type(vimtex.tex) == "string" and vimtex.tex ~= "" then
    return vimtex.tex
  end
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 5, false)) do
    local main = line:match("^%%%s*!%s*[Tt][Ee][Xx]%s+root%s*=%s*(.-)%s*$")
    if main and main ~= "" then
      return vim.fs.normalize(main:sub(1, 1) == "/" and main or vim.fs.joinpath(vim.fs.dirname(name), main))
    end
  end
end

---@param bufnr integer
---@return string #Empty when the buffer has no file to anchor on
local function root_of(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return ""
  end
  local main = main_of(bufnr, name)
  -- Never fall back to $HOME: the scan below would walk the whole home directory.
  return vim.fs.root(main or bufnr, MARKERS) or vim.fs.dirname(main or name) or ""
end

local MAX_FILES = 200
local MAX_ENTRIES = 10000

---Directories no document lives in: .git, editor and tool state, dependencies.
---@param dir string #Relative to the root
---@return boolean
local function walk_into(dir)
  local base = dir:match("[^/]*$")
  return base:sub(1, 1) ~= "." and base ~= "node_modules"
end

---@param root string
---@return c3po.LatexNameFile[]
local function scan_project(root)
  local scanned = {}
  if root == "" then
    return scanned
  end
  -- ponytail: every *.tex/*.sty under the project root, capped at MAX_FILES
  -- files and MAX_ENTRIES directory entries, since the walk runs inside the
  -- first repaint and a .git root may be a large repository.
  -- Following \input/\include properly needs TEXINPUTS, extension inference,
  -- \subimport bases and root-document detection -- texlab keeps a whole
  -- Workspace type for it. The glob is a superset for the price of some
  -- unrelated names, and a stray name is a stray swatch, not a wrong color.
  local entries = 0
  for rel, kind in vim.fs.dir(root, { depth = math.huge, skip = walk_into }) do
    entries = entries + 1
    if entries > MAX_ENTRIES or #scanned >= MAX_FILES then
      break
    end
    if kind == "file" and (rel:match("%.tex$") or rel:match("%.sty$")) then
      local path = vim.fs.normalize(vim.fs.joinpath(root, rel))
      local ok, lines = pcall(vim.fn.readfile, path)
      if ok then
        local found, let = LatexNamePicker.scan_lines(lines)
        table.insert(scanned, { path = path, names = found, lets = let })
      end
    end
  end
  return scanned
end

---Every color name visible from this buffer: builtins, then the project's
---definitions, then the unsaved ones in the buffer itself.
---@param bufnr integer
---@return table<string, RGB>
function LatexNamePicker.names(bufnr)
  -- Completion may be the only caller, and it needs the cache invalidated too.
  LatexNamePicker:init()
  local root = roots[bufnr]
  if root == nil then
    root = root_of(bufnr)
    roots[bufnr] = root
  end

  local base = bases[bufnr]
  if base == nil then
    local files = project[root]
    if files == nil then
      files = scan_project(root)
      project[root] = files
    end
    -- The buffer's own file is left out: the buffer is scanned below, and a
    -- definition deleted from it must not live on through the copy on disk.
    local own = vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))
    local names, lets = {}, {}
    for _, file in ipairs(files) do
      if file.path ~= own then
        names = vim.tbl_extend("force", names, file.names)
        lets = vim.tbl_extend("force", lets, file.lets)
      end
    end
    -- The \colorlet's stay unevaluated: they may read a name only this buffer
    -- defines.
    base = { names = vim.tbl_extend("force", BUILTIN, names), lets = lets }
    bases[bufnr] = base
  end

  -- The buffer is scanned whether or not it is modified: it may be a scratch
  -- buffer, or sit outside the project root, or fall past the file cap, and in
  -- every one of those cases the project scan has not seen it. The tick guard
  -- makes the unmodified case a one-off.
  -- ponytail: one full-buffer rescan per change, not per repaint -- the
  -- changedtick guard collapses the several parse_color calls one keystroke makes
  -- into a single scan. A few thousand lines is a few milliseconds; if that ever
  -- bites, narrow the rescan to the range on_lines already hands the highlighter.
  local tick = vim.api.nvim_buf_get_changedtick(bufnr)
  if live_tick[bufnr] ~= tick then
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local names, lets = LatexNamePicker.scan_lines(lines)
    local merged = vim.tbl_extend("force", base.names, names)
    -- Every \colorlet is evaluated once all definitions are in, the buffer's
    -- included, so a project \colorlet may read a name only the buffer defines.
    -- It never redefines one the buffer defines itself, though: some other
    -- file writing `\colorlet{myred}{red!70!black}` must not decide what
    -- `myred` is in a buffer that says otherwise.
    local all_lets = {}
    for name, value in pairs(base.lets) do
      if names[name] == nil and lets[name] == nil then
        all_lets[name] = value
      end
    end
    resolve(merged, vim.tbl_extend("force", all_lets, lets))
    -- A definition changed, so every use of that name is the wrong color now --
    -- including the ones this repaint will not reach, since on_lines only covers
    -- the edited range. Scheduled because we are inside that very repaint. The
    -- first build needs none: nothing has been painted from it yet.
    if live[bufnr] and not vim.deep_equal(live[bufnr], merged) then
      vim.schedule(function()
        require("c3po.highlighter"):update(bufnr, 0, -1)
      end)
    end
    live[bufnr], live_tick[bufnr] = merged, tick
  end
  return live[bufnr]
end

function LatexNamePicker:init()
  if self.patterns then
    return
  end
  self.patterns = build_patterns()

  -- Within a buffer the changedtick guard in names() keeps everything current.
  -- A write is the one event that changes what *other* buffers can see, since
  -- the project scan reads files rather than buffers.
  local group = vim.api.nvim_create_augroup("c3po-latex-name", {})
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = { "*.tex", "*.sty" },
    callback = function(ev)
      local path = vim.fs.normalize(vim.api.nvim_buf_get_name(ev.buf))
      -- The buffer is what was just written, so it stands in for the file.
      local found, let = LatexNamePicker.scan_lines(vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false))
      local highlighter = require("c3po.highlighter")
      for root, files in pairs(project) do
        if root ~= "" and vim.startswith(path, root .. "/") then
          local entry = vim.iter(files):find(function(file)
            return file.path == path
          end)
          if entry then
            entry.names, entry.lets = found, let
          else
            table.insert(files, { path = path, names = found, lets = let })
          end
          for bufnr, buf_root in pairs(roots) do
            if buf_root == root then
              bases[bufnr], live_tick[bufnr] = nil, nil
              -- names() repaints when the result differs from what was
              -- painted. Hidden buffers wait until they are shown.
              if #vim.fn.win_findbuf(bufnr) > 0 then
                LatexNamePicker.names(bufnr)
              elseif highlighter.attached_buffer[bufnr] then
                highlighter.stale[bufnr] = true
              end
            end
          end
        end
      end
    end,
  })
  -- Deleting whole lines hands on_lines an empty range, so no parse_color runs
  -- and a deleted definition would keep painting its uses.
  vim.api.nvim_create_autocmd("TextChanged", {
    group = group,
    callback = function(ev)
      if TEX_FT[vim.bo[ev.buf].filetype] and require("c3po.highlighter").attached_buffer[ev.buf] then
        LatexNamePicker.names(ev.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(ev)
      bases[ev.buf], live[ev.buf], live_tick[ev.buf], roots[ev.buf] = nil, nil, nil, nil
    end,
  })
end

---@param s string
---@param init? integer
---@param bufnr? integer
---@return integer? start_col 1-indexed
---@return integer? end_col 1-indexed, inclusive
---@return RGB?
function LatexNamePicker:parse_color(s, init, bufnr)
  self:init()
  bufnr = utils.ensure_bufnr(bufnr)
  if not TEX_FT[vim.bo[bufnr].filetype] then
    return
  end
  local names = self.names(bufnr)
  init = init or 1
  while init <= #s do
    local start_col, end_col = pattern.find_first(s, self.patterns, init)
    if start_col == nil or end_col == nil then
      return
    end
    local rgb = after_color_arg(s:sub(1, start_col - 1)) and expr.evaluate(s:sub(start_col, end_col), names)
    if rgb then
      return start_col, end_col, rgb
    end
    -- An unknown name is not a reason to abandon the rest of the line.
    init = end_col + 1
  end
end

--{{{ Completion
-- Which side answered the current completion round, per buffer. The protocol
-- calls the function twice and derives `base` from the first call's column, so
-- the second call must not decide again.
---@type table<integer, boolean>
local delegating = {}
---@type table<integer, string>
local previous = {}

---@param bufnr integer
---@param findstart 0|1
---@param base string
---@return integer|table[]
local function delegate(bufnr, findstart, base)
  local prev = previous[bufnr]
  -- ponytail: vim.fn[...] calls a Vimscript function name, which covers the
  -- realistic conflict (vimtex#complete#omnifunc). A `v:lua.` valued omnifunc
  -- is left alone rather than guessed at.
  if prev and prev ~= "" and not prev:match("^v:lua%.") then
    local ok, result = pcall(vim.fn[prev], findstart, base)
    if ok then
      return result
    end
  end
  -- -2 cancels silently and leaves the buffer untouched.
  return findstart == 1 and -2 or {}
end

---The byte offset where the color name under the cursor starts, or nil when the
---cursor is not inside a color command's braced argument. Shared by every
---completion front end, so they all agree on where a name begins.
---@param line string
---@param col integer #0-based byte offset of the cursor
---@return integer? #0-based
function LatexNamePicker.arg_start(line, col)
  local before = line:sub(1, col)
  local start = before:find("[0-9A-Za-z@_-]*$")
  if start == nil then
    return
  end
  local prefix = before:sub(1, start - 1)
  if prefix:match(COMMAND_ARG) or prefix:match(COLORLET_ARG) then
    return start - 1
  end
end

---@param rgb RGB
---@return string
function LatexNamePicker.hex(rgb)
  return ("#%02x%02x%02x"):format(utils.round(rgb[1] * 255), utils.round(rgb[2] * 255), utils.round(rgb[3] * 255))
end

---A highlight group drawing the color itself, for a completion entry to wear.
---Foreground rather than background: the entry gets a tinted glyph, not a block
---that fights the menu's own selection highlight.
---@param bufnr integer
---@param rgb RGB
---@return string? #nil while the highlighter is not attached to this buffer
function LatexNamePicker.swatch_hl(bufnr, rgb)
  if not require("c3po.highlighter").attached_buffer[bufnr] then
    return
  end
  return hl.ensure_hl_name(nil, { fg = LatexNamePicker.hex(rgb) })
end

---@param bufnr integer
---@return integer?
local function color_arg_start(bufnr)
  if not TEX_FT[vim.bo[bufnr].filetype] then
    return
  end
  return LatexNamePicker.arg_start(vim.api.nvim_get_current_line(), vim.api.nvim_win_get_cursor(0)[2])
end

---Standard 'omnifunc'/'completefunc' protocol. Outside a color argument it hands
---the round to whatever function it replaced, so vimtex keeps its own completion.
---@param findstart 0|1
---@param base string
---@return integer|table[]
function LatexNamePicker.omnifunc(findstart, base)
  local bufnr = vim.api.nvim_get_current_buf()
  if findstart == 1 then
    local start = color_arg_start(bufnr)
    delegating[bufnr] = start == nil
    if start then
      return start
    end
  end
  if delegating[bufnr] then
    return delegate(bufnr, findstart, base)
  end

  local items = {}
  for name, rgb in pairs(LatexNamePicker.names(bufnr)) do
    if vim.startswith(name:lower(), base:lower()) then
      table.insert(items, {
        word = name,
        kind = "Color",
        menu = LatexNamePicker.hex(rgb),
        kind_hlgroup = LatexNamePicker.swatch_hl(bufnr, rgb),
      })
    end
  end
  table.sort(items, function(a, b)
    return a.word < b.word
  end)
  return items
end

---@param bufnr integer
local function install(bufnr)
  -- Deferred because vimtex sets 'omnifunc' from its own ftplugin, on the very
  -- event that gets us here: scheduling is what guarantees we capture it
  -- instead of racing it up the runtimepath.
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    local current = vim.bo[bufnr].omnifunc
    if current:match("latex_name") then
      return
    end
    previous[bufnr] = current
    vim.bo[bufnr].omnifunc = "v:lua.require'c3po.picker.latex_name'.omnifunc"
  end)
end

---Install the completion function on tex buffers, keeping whatever was there.
function LatexNamePicker.setup_completion()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("c3po-latex-completion", {}),
    pattern = { "tex", "latex", "plaintex" },
    callback = function(ev)
      install(ev.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = "c3po-latex-completion",
    callback = function(ev)
      delegating[ev.buf], previous[ev.buf] = nil, nil
    end,
  })
  -- Under a lazy-loading plugin manager setup() itself often runs *from* the
  -- FileType event of the buffer that triggered the load, and an autocmd
  -- created during an event never fires for that same event.
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and TEX_FT[vim.bo[bufnr].filetype] then
      install(bufnr)
    end
  end
end
-- }}}

return LatexNamePicker
