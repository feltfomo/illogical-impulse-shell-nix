{
  lib,
  stdenvNoCC,
  upstream,
}:
stdenvNoCC.mkDerivation {
  pname = "illogical-impulse-shell-theme";
  version = "unstable";

  src = upstream;

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    template="$src/dots/.config/matugen/templates/colors.json"
    test -f "$template"

    target="$out/share/illogical-impulse-shell/matugen"
    mkdir -p "$target"
    cp "$template" "$target/colors.json"

    runHook postInstall
  '';

  meta = {
    description = "Shell-only Matugen template for illogical-impulse";
    homepage = "https://github.com/end-4/dots-hyprland";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}