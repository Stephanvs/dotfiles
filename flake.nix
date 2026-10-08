{
  description = "Stephan's NixOS workstation and installation rehearsal";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tmux-powerkit = {
      url = "github:fabioluciano/tmux-powerkit";
      flake = false;
    };
    tmux-navigate = {
      url = "github:sunaku/tmux-navigate";
      flake = false;
    };
    nvim-darkmatter = {
      url = "github:stevedylandev/darkmatter-nvim/dccd1a7feb626eee0f3dde3d2c587b9f698eb940";
      flake = false;
    };
    nvim-triforce = {
      url = "github:gisketch/triforce.nvim/9cf67075d18dc189b58eecb9989a88b854dfbe09";
      flake = false;
    };
    nvim-namu = {
      url = "github:bassamsdata/namu.nvim/e7afbdf63a75ace6ccc6202d58a4f6f9ac09db92";
      flake = false;
    };
    nvim-dotnet-test = {
      url = "github:austincrft/dotnet-test.nvim/6f6e7c20de8fea596541a67f2175b5fb5b8172d5";
      flake = false;
    };
    nvim-razor = {
      url = "github:jlcrochet/vim-razor/305dd1db88c657c0c02effbee1a88048479bb0c4";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      nixos-hardware,
      ...
    }:
    let
      system = "x86_64-linux";
      shared = [
        home-manager.nixosModules.home-manager
        ./nix/workstation.nix
        {
          home-manager.extraSpecialArgs.tmuxSources = {
            powerkit = inputs.tmux-powerkit;
            navigate = inputs.tmux-navigate;
          };
          home-manager.extraSpecialArgs.neovimSources = {
            darkmatter = inputs.nvim-darkmatter;
            triforce = inputs.nvim-triforce;
            namu = inputs.nvim-namu;
            dotnet-test = inputs.nvim-dotnet-test;
            razor = inputs.nvim-razor;
          };
        }
      ];
    in
    {
      nixosConfigurations.rehearsal = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = shared ++ [
          "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
          ./nix/hosts/rehearsal.nix
        ];
      };

      nixosConfigurations.rehearsal-macos = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = shared ++ [
          "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
          ./nix/hosts/rehearsal.nix
          ./nix/hosts/macos-preview.nix
        ];
      };

      nixosModules.framework = {
        imports = shared ++ [
          nixos-hardware.nixosModules.framework-intel-core-ultra-series3
          ./nix/hosts/framework.nix
        ];
      };

      packages.${system} = {
        rehearsal = self.nixosConfigurations.rehearsal.config.system.build.vm;
        default = self.packages.${system}.rehearsal;
      };
      packages.aarch64-linux = {
        macos-preview = self.nixosConfigurations.rehearsal-macos.config.system.build.macosPreview;
        default = self.packages.aarch64-linux.macos-preview;
      };
      formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixfmt;
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;
    };
}
