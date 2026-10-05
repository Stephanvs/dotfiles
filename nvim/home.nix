{
  lib,
  pkgs,
  neovimSources,
  ...
}:
let
  supermavenAgent = pkgs.callPackage ./supermaven-agent.nix { };
  treesitter = pkgs.vimPlugins.nvim-treesitter-legacy.withPlugins (
    grammars: with grammars; [
      bash
      c
      c_sharp
      cpp
      css
      html
      javascript
      json
      lua
      markdown
      markdown_inline
      nix
      python
      query
      regex
      rust
      toml
      tsx
      typescript
      vim
      vimdoc
      yaml
    ]
  );
  parserDirectory = pkgs.symlinkJoin {
    name = "dotfiles-neovim-parsers";
    paths = treesitter.dependencies;
  };
  plugins = with pkgs.vimPlugins; {
    "lazy.nvim" = lazy-nvim;
    "NvChad" = nvchad;
    "LuaSnip" = luasnip;
    "asyncrun.vim" = asyncrun-vim;
    "base46" = base46;
    "cellular-automaton.nvim" = cellular-automaton-nvim;
    "cmp-async-path" = cmp-async-path;
    "cmp-buffer" = cmp-buffer;
    "cmp-nvim-lsp" = cmp-nvim-lsp;
    "cmp-nvim-lua" = cmp-nvim-lua;
    "cmp_luasnip" = cmp_luasnip;
    "conform.nvim" = conform-nvim;
    "d2-vim" = d2-vim;
    "darkmatter-nvim" = neovimSources.darkmatter;
    "dotnet-test.nvim" = neovimSources.dotnet-test;
    "friendly-snippets" = friendly-snippets;
    "gitsigns.nvim" = gitsigns-nvim;
    "indent-blankline.nvim" = indent-blankline-nvim;
    "menu" = nvzone-menu;
    "mini.map" = mini-map;
    "minty" = nvzone-minty;
    "namu.nvim" = neovimSources.namu;
    "noice.nvim" = noice-nvim;
    "nui.nvim" = nui-nvim;
    "nvim-autopairs" = nvim-autopairs;
    "nvim-cmp" = nvim-cmp;
    "nvim-dap" = nvim-dap;
    "nvim-lspconfig" = nvim-lspconfig;
    "nvim-notify" = nvim-notify;
    "nvim-tree.lua" = nvim-tree-lua;
    "nvim-treesitter" = treesitter;
    "nvim-web-devicons" = nvim-web-devicons;
    "plenary.nvim" = plenary-nvim;
    "roslyn.nvim" = roslyn-nvim;
    "snacks.nvim" = snacks-nvim;
    "supermaven-nvim" = supermaven-nvim.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace lua/supermaven-nvim/binary/binary_handler.lua \
          --replace-fail 'local binary_path = binary_fetcher:fetch_binary()' \
          'local binary_path = "${supermavenAgent}/bin/sm-agent"'
      '';
    });
    "telescope.nvim" = telescope-nvim;
    "triforce.nvim" = neovimSources.triforce;
    "trouble.nvim" = trouble-nvim;
    "ui" = nvchad-ui;
    "vim-fugitive" = vim-fugitive;
    "vim-razor" = neovimSources.razor;
    "vim-tmux-navigator" = vim-tmux-navigator;
    "volt" = nvzone-volt;
    "which-key.nvim" = which-key-nvim;
  };
  pluginDirectory = pkgs.linkFarm "dotfiles-neovim-plugins" (
    lib.mapAttrsToList (name: path: { inherit name path; }) plugins
  );
in
{
  home.packages = with pkgs; [
    neovim
    lua-language-server
    vscode-langservers-extracted
    typescript-language-server
    csharp-ls
    roslyn-ls
    netcoredbg
    stylua
    d2
  ];
  xdg.configFile."nvim" = {
    source = ./nvchad;
    recursive = true;
  };
  xdg.configFile."nvim/lua/dotfiles/nix.lua".text =
    builtins.replaceStrings
      [ "@pluginDirectory@" "@parserDirectory@" ]
      [ (toString pluginDirectory) (toString parserDirectory) ]
      (builtins.readFile ./nixos.lua);
}
