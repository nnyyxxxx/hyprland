return {
  "andweeb/presence.nvim",
  lazy = false,
  config = function()
    require("presence").setup({
      main_image = "file",
      neovim_image_text = "Neovim",
    })
  end
} 