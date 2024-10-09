-- init.lua

vim.g.base46_cache = vim.fn.stdpath "data" .. "/nvchad/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
    config = function()
      require "options"
    end,
  },

  { import = "plugins" },

  {
    "NvChad/base46",
    branch = "v2.5",
    lazy = false,
    priority = 1000,
    config = function()
      local ok, base46 = pcall(require, "base46")
      if ok then
        if type(base46.load_theme) == "function" then
          base46.load_theme()
        else
          print("base46.load_theme is not a function. base46 version: " .. (base46.VERSION or "unknown"))
        end
      else
        print("Failed to load base46: " .. tostring(base46))
      end
    end,
  },

  {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    config = function()
      require('nvim-tree').setup {}
    end,
  },
}, lazy_config)

-- load theme
local ok, _ = pcall(dofile, vim.g.base46_cache .. "defaults")
if not ok then
  print("Failed to load defaults from base46_cache")
end

ok, _ = pcall(dofile, vim.g.base46_cache .. "statusline")
if not ok then
  print("Failed to load statusline from base46_cache")
end

require "nvchad.autocmds"

vim.schedule(function()
  require "mappings"
end)

vim.cmd [[
  augroup NvimTree
    autocmd!
    autocmd VimEnter * NvimTreeToggle
  augroup END
]]

