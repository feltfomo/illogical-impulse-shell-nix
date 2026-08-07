{
  description = "Reproducible Nix packaging for the illogical-impulse Quickshell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    end4Pc = {
      url = "github:pctrade/end4-pC";
      flake = false;
    };

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
      end4Pc,
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
      end4PcSource = pkgs.callPackage ./shells/end4-pc/source.nix { inherit end4Pc; };
      end4PcTheme = pkgs.callPackage ./shells/end4-pc/theme.nix { inherit upstream; };
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
      end4PcRuntime = pkgs.callPackage ./shells/end4-pc/package.nix {
        inherit
          end4PcSource
          end4PcTheme
          shellFonts
          shellPython
          ;
        quickshell = quickshell.packages.${system}.default;
      };
    in
    {
      packages.${system} = {
        default = runnableShell;
        end4-pc-runtime = end4PcRuntime;
        end4-pc-source = end4PcSource;
        end4-pc-theme = end4PcTheme;
        fonts = shellFonts;
        python = shellPython;
        runtime = runnableShell;
        source = shellSource;
        theme = shellTheme;
      };

      checks.${system} = {
        formatting = treefmtEval.config.build.check self;
        extracted-end4-pc = end4PcSource;
        extracted-shell = shellSource;
        packaged-end4-pc-theme = end4PcTheme;
        packaged-fonts = shellFonts;
        packaged-python = shellPython;
        packaged-theme = shellTheme;
        runnable-end4-pc = end4PcRuntime;
        runnable-shell = runnableShell;
      };

      formatter.${system} = treefmtEval.config.build.wrapper;
    };
}
