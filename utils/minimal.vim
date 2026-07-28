set termguicolors

let s:plug_dir = expand('/tmp/plugged/vim-plug')
if !filereadable(s:plug_dir .. '/autoload/plug.vim')
  execute printf('!curl -fLo %s/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim', s:plug_dir)
end

execute 'set runtimepath+=' . s:plug_dir
call plug#begin(s:plug_dir)
Plug 'dpezto/C-3PO.nvim'
Plug 'neovim/nvim-lspconfig'
call plug#end()
PlugInstall | quit

lua <<EOF
local c3po = require("c3po")
local mapping = c3po.mapping

c3po.setup({
    -- Minimal configurations required to reproduce the problem.
})

require("lspconfig").cssls.setup({})
EOF
