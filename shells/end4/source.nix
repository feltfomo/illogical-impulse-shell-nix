{
  lib,
  stdenvNoCC,
  patch,
  roundedPolygon,
  upstream,
}:
stdenvNoCC.mkDerivation {
  pname = "illogical-impulse-shell-source";
  version = "unstable";

  src = upstream;

  nativeBuildInputs = [ patch ];

  dontConfigure = true;
  dontBuild = true;
  # compatibility.patch carries qml fixes against upstream aed4d1ec
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    shell_source="$src/dots/.config/quickshell/ii"
    test -f "$shell_source/shell.qml"

    mkdir -p "$out/share/quickshell"
    cp -a "$shell_source" "$out/share/quickshell/ii"

    # the aed4d1ec archive omitted the e31ec4cb shapes gitlink contents
    chmod -R u+w "$out/share/quickshell/ii"
    shapes_target="$out/share/quickshell/ii/modules/common/widgets/shapes"
    rm -rf "$shapes_target"
    cp -a ${roundedPolygon} "$shapes_target"

    test -f "$shapes_target/ShapeCanvas.qml"
    test -f "$shapes_target/material-shapes.js"

    {
      sed '/^# /d' ${./compatibility.patch}
      printf '\n'
    } | patch -d "$out/share/quickshell/ii" -p1

    substituteInPlace "$out/share/quickshell/ii/modules/ii/wallpaperSelector/WallpaperDirectoryItem.qml" \
      --replace-fail 'fileModelData: root.fileModelData' \
      'fileModelData: root.fileModelData
                        iconColor: root.colText'

    install -m 0644 ${../common/DirectoryIcon.qml} \
      "$out/share/quickshell/ii/modules/common/widgets/DirectoryIcon.qml"

    runHook postInstall
  '';

  meta = {
    description = "Extracted illogical-impulse Quickshell source";
    homepage = "https://github.com/end-4/dots-hyprland";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
