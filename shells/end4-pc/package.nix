{
  lib,
  stdenvNoCC,
  adwaita-icon-theme,
  bash,
  bc,
  brightnessctl,
  cliphist,
  coreutils,
  curl,
  ddcutil,
  end4PcSource,
  end4PcTheme,
  findutils,
  gawk,
  gnugrep,
  gnused,
  gsettings-desktop-schemas,
  grim,
  hicolor-icon-theme,
  hyprsunset,
  imagemagick,
  jq,
  kdePackages,
  libqalculate,
  libnotify,
  libsecret,
  makeFontsConf,
  matugen,
  playerctl,
  procps,
  pulseaudio,
  qt6,
  quickshell,
  shellFonts,
  shellPython,
  slurp,
  songrec,
  tesseract,
  util-linux,
  wget,
  wl-clipboard,
  xdg-utils,
  xdg-user-dirs,
  ydotool,
}:
let
  runtimeInputs = [
    bash
    bc
    brightnessctl
    cliphist
    coreutils
    curl
    ddcutil
    findutils
    gawk
    gnugrep
    gnused
    grim
    hyprsunset
    imagemagick
    jq
    libqalculate
    libnotify
    libsecret
    matugen
    playerctl
    procps
    pulseaudio
    shellPython
    slurp
    songrec
    tesseract
    util-linux
    wget
    wl-clipboard
    xdg-utils
    xdg-user-dirs
    ydotool
  ];

  iconInputs = [
    adwaita-icon-theme
    hicolor-icon-theme
    kdePackages.breeze-icons
  ];

  fontConfig = makeFontsConf {
    fontDirectories = [ shellFonts ];
  };

  qmlInputs = [
    kdePackages.kirigami
    kdePackages.kirigami.unwrapped
    kdePackages.qqc2-desktop-style
    kdePackages.kdialog
    kdePackages.qtlocation
    kdePackages.qtpositioning
    kdePackages.qtwayland
    kdePackages.syntax-highlighting
    qt6.qt5compat
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtimageformats
    qt6.qtmultimedia
    qt6.qtpositioning
    qt6.qtquicktimeline
    qt6.qtsensors
    qt6.qtsvg
    qt6.qttools
    qt6.qttranslations
    qt6.qtvirtualkeyboard
    qt6.qtwayland
  ];

  qmlImportPath = lib.makeSearchPath "lib/qt-6/qml" qmlInputs;
in
stdenvNoCC.mkDerivation {
  pname = "end4-pc-shell";
  version = "unstable";

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ qt6.wrapQtAppsHook ];

  buildInputs = [
    quickshell
    gsettings-desktop-schemas
  ]
  ++ iconInputs
  ++ qmlInputs;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    cat > "$out/bin/end4-pc-shell" <<'EOF'
    #!${bash}/bin/bash
    set -euo pipefail

    config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
    config_root="$config_home/quickshell"
    config_path="$config_root/end4-pC"
    translations_dir="$config_home/illogical-impulse/translations"
    state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"
    cache_home="''${XDG_CACHE_HOME:-$HOME/.cache}"
    generated_dir="$state_home/quickshell/user/generated"
    wallpaper_state_dir="$generated_dir/wallpaper"
    colors_path="$generated_dir/colors.json"

    export PATH="$(dirname "$0")":${lib.makeBinPath runtimeInputs}:"$PATH"

    mkdir -p \
      "$config_root" \
      "$translations_dir" \
      "$wallpaper_state_dir" \
      "$cache_home/thumbnails"/{normal,large,x-large,xx-large}

    if [[ ! -e "$translations_dir/en_US.json" ]]; then
      printf '%s\n' '{}' > "$translations_dir/en_US.json"
    fi

    if [[ -L "$config_path" ]]; then
      ln -sfn ${end4PcSource}/share/quickshell/end4-pC "$config_path"
    elif [[ -e "$config_path" ]]; then
      printf 'error: %s already exists and is not a symlink\n' "$config_path" >&2
      exit 1
    else
      ln -s ${end4PcSource}/share/quickshell/end4-pC "$config_path"
    fi

    if [[ ! -s "$colors_path" ]]; then
      end4-pc-shell-theme \
        --source-color-index 0 \
        color hex '#6750A4' \
        --mode dark \
        --type scheme-tonal-spot \
        >/dev/null
    fi

    if [[ ! -e "$wallpaper_state_dir/category.txt" ]]; then
      printf '%s\n' 'unknown' > "$wallpaper_state_dir/category.txt"
    fi

    if [[ ! -e "$state_home/quickshell/user/first_run.txt" ]]; then
      printf '%s\n' 'Initialized by the Nix launcher' > "$state_home/quickshell/user/first_run.txt"
    fi

    export ILLOGICAL_IMPULSE_VIRTUAL_ENV=${shellPython}
    export FONTCONFIG_FILE=${fontConfig}
    export XDG_DATA_DIRS=${lib.makeSearchPath "share" iconInputs}:"''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    export QML2_IMPORT_PATH=${qmlImportPath}:"''${QML2_IMPORT_PATH:-}"
    export QML_IMPORT_PATH=${qmlImportPath}:"''${QML_IMPORT_PATH:-}"
    exec ${lib.getExe quickshell} -c end4-pC "$@"
    EOF

    cat > "$out/bin/end4-pc-shell-theme" <<'EOF_THEME_COMMAND'
    #!${bash}/bin/bash
    set -euo pipefail

    state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"
    generated_dir="$state_home/quickshell/user/generated"
    colors_path="$generated_dir/colors.json"
    matugen_home="$state_home/quickshell/matugen-end4-pc-shell"

    mkdir -p "$generated_dir" "$matugen_home/matugen"
    cat > "$matugen_home/matugen/config.toml" <<EOF_MATUGEN
    [config]
    version_check = false

    [templates.m3colors]
    input_path = '${end4PcTheme}/share/end4-pc-shell/matugen/colors.json'
    output_path = '$colors_path'
    EOF_MATUGEN

    XDG_CONFIG_HOME="$matugen_home" ${lib.getExe matugen} "$@"

    config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
    user_templates_config="$config_home/end4-pc/matugen/config.toml"
    if [[ -s "$user_templates_config" ]]; then
      ${lib.getExe matugen} "$@" --config "$user_templates_config"
    fi
    EOF_THEME_COMMAND

    cat > "$out/bin/end4-pc-shell-ipc" <<'EOF_IPC'
    #!${bash}/bin/bash
    set -euo pipefail

    exec ${lib.getExe quickshell} -c end4-pC ipc call "$@"
    EOF_IPC

    chmod +x \
      "$out/bin/end4-pc-shell" \
      "$out/bin/end4-pc-shell-ipc" \
      "$out/bin/end4-pc-shell-theme"

    runHook postInstall
  '';

  meta = {
    description = "Runnable packaging layer for the end4-pC Quickshell";
    homepage = "https://github.com/pctrade/end4-pC";
    license = lib.licenses.gpl3Only;
    mainProgram = "end4-pc-shell";
    platforms = lib.platforms.linux;
  };
}
