{
  description = "Reproducible Nix packaging for the illogical-impulse Quickshell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    googleSansFlex = {
      url = "github:end-4/google-sans-flex";
      flake = false;
    };

    quickshell = {
      url = "github:quickshell-mirror/quickshell/7511545ee20664e3b8b8d3322c0ffe7567c56f7a";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    roundedPolygon = {
      url = "github:end-4/rounded-polygon-qmljs/e31ec4cb4ebf6a46b267f5c42eabf6874916fa16";
      flake = false;
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    upstream = {
      url = "github:end-4/dots-hyprland";
      flake = false;
    };
  };

  outputs =
    {
      googleSansFlex,
      nixpkgs,
      quickshell,
      roundedPolygon,
      self,
      treefmt-nix,
      upstream,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      treefmtEval = treefmt-nix.lib.evalModule pkgs ./formatter.nix;
      shellFonts = pkgs.callPackage ./fonts.nix { inherit googleSansFlex; };
      shellPython = pkgs.callPackage ./python.nix { };
      shellSource = pkgs.callPackage ./shells/end4/source.nix {
        inherit roundedPolygon upstream;
      };
      shellTheme = pkgs.callPackage ./shells/end4/theme.nix { inherit upstream; };
      runnableShell = pkgs.callPackage ./shells/end4/package.nix {
        inherit
          shellFonts
          shellPython
          shellSource
          shellTheme
          ;
        quickshell = quickshell.packages.${system}.default;
      };
    in
    {
      packages.${system} = {
        default = runnableShell;
        fonts = shellFonts;
        python = shellPython;
        runtime = runnableShell;
        source = shellSource;
        theme = shellTheme;
      };

      checks.${system} = {
        formatting = treefmtEval.config.build.check self;
        extracted-shell = shellSource;
        packaged-fonts = shellFonts;
        packaged-python = shellPython;
        packaged-theme = shellTheme;
        runnable-shell = runnableShell;
      };

      formatter.${system} = treefmtEval.config.build.wrapper;
    };
}
