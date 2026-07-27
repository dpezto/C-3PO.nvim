local function loader(root)
  return function(self, key)
    local modname = table.concat({ "c3po", root, key }, ".")
    local ok, module = pcall(require, modname)
    if not ok then
      vim.notify("Unknown module: " .. modname)
      return
    end
    rawset(self, key, module)
    return module
  end
end

---@param user_opts? c3po.Options.P
local function setup(user_opts)
  if vim.fn.has("nvim-0.12") == 0 then
    vim.notify("[c3po] requires Neovim 0.12+", vim.log.levels.ERROR)
    return
  end
  user_opts = user_opts or {}
  require("c3po.config").setup(user_opts)
  local opts = require("c3po.config").options

  local core = require("c3po.core").new()
  require("c3po.command").create(core)
  vim.keymap.set("i", "<Plug>(c3po-insert)", function()
    core:insert()
  end)

  vim.keymap.set("o", "<Plug>(c3po-select-color)", function()
    require("c3po.select").select("v")
  end)
  vim.keymap.set("x", "<Plug>(c3po-select-color)", function()
    require("c3po.select").select("o")
  end)

  local highlighter = require("c3po.highlighter")
  highlighter:init()

  if opts.highlighter.auto_enable then
    ---@param bufnr integer
    ---@param file string
    local function auto_enable(bufnr, file)
      -- Only normal buffers: terminals, prompts and plugin scratch buffers
      -- must never be attached, whatever filetype they carry.
      if vim.bo[bufnr].buftype ~= "" then
        return
      end
      local ok, stat = pcall(vim.uv.fs_stat, file)
      if ok and stat and stat.size > opts.highlighter.max_byte then
        return
      end
      highlighter:enable(bufnr)
    end
    -- FileType rather than BufEnter: it fires once the filetype is actually
    -- set, so excludes work on buffers that get their filetype late (lazy's
    -- UI), and buffers that never get one (terminals) are never attached.
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("c3po-highlighter-auto-enable", {}),
      callback = function(ev)
        auto_enable(ev.buf, ev.file)
      end,
    })
    -- Buffers loaded before setup() (e.g. under a lazy-loading plugin manager)
    -- have had their FileType event already.
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype ~= "" then
        auto_enable(bufnr, vim.api.nvim_buf_get_name(bufnr))
      end
    end
  end

  return core
end

return {
  input = setmetatable({}, {
    __index = loader("input"),
  }),
  output = setmetatable({}, {
    __index = loader("output"),
  }),
  picker = setmetatable({}, {
    __index = loader("picker"),
  }),
  setup = setup,
  mapping = require("c3po.mapping"),
}
