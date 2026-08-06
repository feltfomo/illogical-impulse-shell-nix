{
  lib,
  stdenvNoCC,
  roundedPolygon,
  upstream,
}:
stdenvNoCC.mkDerivation {
  pname = "illogical-impulse-shell-source";
  version = "unstable";

  src = upstream;

  dontConfigure = true;
  dontBuild = true;
  # Preserve the upstream shell and assemble its pinned shapes submodule.
  # Runtime packaging patches interpreters deliberately in a separate layer.
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    shell_source="$src/dots/.config/quickshell/ii"
    test -f "$shell_source/shell.qml"

    mkdir -p "$out/share/quickshell"
    cp -a "$shell_source" "$out/share/quickshell/ii"

    # GitHub archive inputs leave gitlinks empty. Populate the exact submodule
    # revision recorded by the pinned dots-hyprland commit.
    chmod -R u+w "$out/share/quickshell/ii"
    shapes_target="$out/share/quickshell/ii/modules/common/widgets/shapes"
    rm -rf "$shapes_target"
    cp -a ${roundedPolygon} "$shapes_target"

    test -f "$shapes_target/ShapeCanvas.qml"
    test -f "$shapes_target/material-shapes.js"

    runHook postInstall
  '';

  meta = {
    description = "Extracted illogical-impulse Quickshell source";
    homepage = "https://github.com/end-4/dots-hyprland";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}