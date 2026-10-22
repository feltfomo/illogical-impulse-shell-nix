{
  bash,
  cliphist,
  end4Pc,
  file,
  lib,
  patch,
  python3,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "end4-pc-shell-source";
  version = "unstable";

  src = end4Pc;

  nativeBuildInputs = [
    cliphist
    file
    patch
    python3
  ];

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

    patch -d "$target" -p1 < ${./clipboard.patch}
    install -m 0644 ${./copy-history.py} "$target/scripts/clipboard/copy-history.py"
    python3 ${./test-clipboard.py} "$target"

    substituteInPlace "$target/scripts/musicRecognition/recognize-music.sh" \
      --replace-fail '#!/bin/bash' '#!${bash}/bin/bash'

    substituteInPlace "$target/modules/ii/wallpaperSelector/WallpaperDirectoryItem.qml" \
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
