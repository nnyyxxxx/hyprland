return {
  "andweeb/presence.nvim",
  lazy = false,
  config = function()
    require("presence").setup({
      main_image = "neovim",
      neovim_image_text = "Neovim",
    })
  end
} 