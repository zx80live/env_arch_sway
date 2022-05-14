eim.cmd [[packadd packer.nvim]]


local function map(mode, lhs, rhs, opts)
    local options = { noremap = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

return require('packer').startup(function()
  -- [plugins]
  use 'wbthomason/packer.nvim'	
  use {'joshdick/onedark.vim', as = 'onedark'}

  use 'airblade/vim-gitgutter'
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true }
  }

  -- [main]
  vim.o.expandtab = true
  vim.o.tabstop = 2
  vim.o.softtabstop = 2
  vim.o.shiftwidth = 2
  vim.o.autoindent = true
  vim.o.wildmenu = true
  vim.o.mouse = a
  vim.o.ffs = unix,dos,mac -- symbol of the next line
  -- search
  vim.o.ignorecase = true
  vim.o.smartcase = true
  vim.o.hlsearch = true
  vim.o.incsearch = true
  -- clipboard
  --vim.o.clipboard = unnamedplus
  map("v", "<C-c>", '"*y')


  -- [appearance]
  vim.o.laststatus = 2
  vim.o.number = true
  vim.cmd [[syntax on]]
  vim.cmd [[colorscheme onedark]]

  require('lualine').setup()


end)


