{
  lib,
  stdenvNoCC,
  upstream,
}:
stdenvNoCC.mkDerivation {
  pname = "end4-pc-shell-theme";
  version = "unstable";

  src = upstream;

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    template="$src/dots/.config/matugen/templates/colors.json"
    test -f "$template"

    target="$out/share/end4-pc-shell/matugen"
    mkdir -p "$target"
    cp "$template" "$target/colors.json"

    runHook postInstall
  '';

  meta = {
    description = "Shell-only Matugen template for end4-pC";
    homepage = "https://github.com/pctrade/end4-pC";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
