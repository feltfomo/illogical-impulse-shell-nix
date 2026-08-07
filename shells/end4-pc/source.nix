{
  bash,
  end4Pc,
  lib,
  patch,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "end4-pc-shell-source";
  version = "unstable";

  src = end4Pc;

  nativeBuildInputs = [ patch ];

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    test -f "$src/shell.qml"
    test -d "$src/modules"
    test -d "$src/services"
    test -d "$src/scripts"

    target="$out/share/quickshell/end4-pC"
    mkdir -p "$(dirname "$target")"
    cp -a "$src" "$target"
    chmod -R u+w "$target"

    find "$target/scripts" -type f \
      \( -name '*.sh' -o -name '*.py' \) \
      -exec chmod +x {} +

    test -f "$target/shell.qml"
    test -f "$target/modules/common/Directories.qml"
    test -f "$target/scripts/colors/switchwall.sh"

    {
      sed '/^# /d' ${./compatibility.patch}
      printf '\n'
    } | patch -d "$target" -p1

    substituteInPlace "$target/scripts/musicRecognition/recognize-music.sh" \
      --replace-fail '#!/bin/bash' '#!${bash}/bin/bash'

    substituteInPlace "$target/modules/ii/bar/BarContent.qml" \
      --replace-fail 'if (item && item.hasOwnProperty("mirrored"))' \
      'if (item && modelData === "visualizer")'

    substituteInPlace "$target/modules/ii/wallpaperSelector/WallpaperDirectoryItem.qml" \
      --replace-fail 'generateThumbnail: false' \
      'generateThumbnail: true' \
      --replace-fail 'fileModelData: root.fileModelData' \
      'fileModelData: root.fileModelData
                        iconColor: root.colText'

    install -m 0644 ${../common/DirectoryIcon.qml} \
      "$target/modules/common/widgets/DirectoryIcon.qml"

    runHook postInstall
  '';

  meta = {
    description = "Extracted end4-pC Quickshell source";
    homepage = "https://github.com/pctrade/end4-pC";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
