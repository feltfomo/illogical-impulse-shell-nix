{
  lib,
  stdenvNoCC,
  google-fonts,
  googleSansFlex,
  material-symbols,
  nerd-fonts,
  noto-fonts,
  noto-fonts-color-emoji,
}:
let
  supplementalGoogleFonts = google-fonts.override {
    fonts = [
      "Readex Pro"
      "Space Grotesk"
    ];
  };

  fontSources = [
    googleSansFlex
    supplementalGoogleFonts
    material-symbols
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];
in
stdenvNoCC.mkDerivation {
  pname = "illogical-impulse-shell-fonts";
  version = "unstable";

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    target="$out/share/fonts/illogical-impulse"
    mkdir -p "$target"

    for source in ${lib.escapeShellArgs (map toString fontSources)}; do
      while IFS= read -r -d $'\0' font; do
        install -Dm644 "$font" "$target/$(basename "$font")"
      done < <(
        find "$source" -type f \
          \( -iname '*.otf' -o -iname '*.ttf' -o -iname '*.ttc' -o -iname '*.woff2' \) \
          -print0
      )
    done

    test -n "$(find "$target" -type f -print -quit)"

    runHook postInstall
  '';

  meta = {
    description = "Private font closure for the illogical-impulse shell";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}