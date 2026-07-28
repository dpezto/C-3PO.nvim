set termguicolors

let s:dir = expand('/tmp/c3po-repro/C-3PO.nvim')
if !isdirectory(s:dir)
  execute printf('!git clone --depth 1 https://github.com/dpezto/C-3PO.nvim %s', s:dir)
end
execute 'set runtimepath+=' . s:dir

lua <<EOF
local c3po = require("c3po")
local mapping = c3po.mapping

c3po.setup({
    -- Minimal configurations required to reproduce the problem.
})

-- Only needed when the problem involves LSP colors (requires
-- vscode-css-language-server on $PATH).
vim.lsp.config("cssls", {
  cmd = { "vscode-css-language-server", "--stdio" },
  filetypes = { "css", "scss", "less" },
})
vim.lsp.enable("cssls")
EOF
