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
      upstream,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      shellFonts = pkgs.callPackage ./fonts.nix { inherit googleSansFlex; };
      shellSource = pkgs.callPackage ./source.nix {
        inherit roundedPolygon upstream;
      };
      shellTheme = pkgs.callPackage ./theme.nix { inherit upstream; };
      runnableShell = pkgs.callPackage ./package.nix {
        inherit shellFonts shellSource shellTheme;
        quickshell = quickshell.packages.${system}.default;
      };
    in
    {
      packages.${system} = {
        default = runnableShell;
        fonts = shellFonts;
        runtime = runnableShell;
        source = shellSource;
        theme = shellTheme;
      };

      checks.${system} = {
        extracted-shell = shellSource;
        packaged-fonts = shellFonts;
        packaged-theme = shellTheme;
        runnable-shell = runnableShell;
      };

      formatter.${system} = pkgs.nixfmt-rfc-style;
    };
}