{
  projectRootFile = "flake.nix";

  settings.global.excludes = [
    ".claude/**"
    ".github/*TEMPLATE*/*"
    ".github/CODEOWNERS"
    "docs/*"
    "Justfile"
    "AGENT*.md"
    "CLAUDE.md"
    "*.txt"
    "*.svg"
    "ci.bash"
    "templates/fleet-demo/diagrams/*"
    "templates/fleet-demo/README.md"
    "templates/diagram-demo/diagrams/*"
    "templates/diagram-demo/README.md"
  ];

  programs.nixfmt.enable = true;
  programs.deadnix.enable = false;
  programs.nixf-diagnose.enable = false;
}
