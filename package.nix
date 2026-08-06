{
  lib,
  stdenvNoCC,
  bash,
  bc,
  brightnessctl,
  cliphist,
  coreutils,
  curl,
  ddcutil,
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
  libnotify,
  libsecret,
  makeFontsConf,
  matugen,
  playerctl,
  procps,
  qt6,
  quickshell,
  shellFonts,
  shellSource,
  shellTheme,
  slurp,
  util-linux,
  wget,
  wl-clipboard,
  xdg-user-dirs,
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
    libnotify
    libsecret
    matugen
    playerctl
    procps
    slurp
    util-linux
    wget
    wl-clipboard
    xdg-user-dirs
  ];

  iconInputs = [
    hicolor-icon-theme
    kdePackages.breeze-icons
  ];

  fontConfig = makeFontsConf {
    fontDirectories = [ shellFonts ];
  };

  qmlInputs = [
    # nixpkgs e72e4f299401 exposed kirigami through a propagation wrapper
    # the qml payload stayed in kirigami.unwrapped
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

  # nixpkgs e72e4f299401 wrapQtAppsHook missed qml-only modules for this launcher
  qmlImportPath = lib.makeSearchPath "lib/qt-6/qml" qmlInputs;
in
stdenvNoCC.mkDerivation {
  pname = "illogical-impulse-shell";
  version = "unstable";

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ qt6.wrapQtAppsHook ];

  buildInputs = [
    quickshell
    gsettings-desktop-schemas
  ] ++ iconInputs ++ qmlInputs;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    cat > "$out/bin/illogical-impulse-shell" <<'EOF'
    #!${bash}/bin/bash
    set -euo pipefail

    config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
    config_root="$config_home/quickshell"
    config_path="$config_root/ii"
    translations_dir="$config_home/illogical-impulse/translations"
    state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"
    generated_dir="$state_home/quickshell/user/generated"
    wallpaper_state_dir="$generated_dir/wallpaper"
    colors_path="$generated_dir/colors.json"

    mkdir -p "$config_root" "$translations_dir" "$wallpaper_state_dir"

    # upstream aed4d1ec Translation.qml read the optional overlay before it existed
    if [[ ! -e "$translations_dir/en_US.json" ]]; then
      printf '%s\n' '{}' > "$translations_dir/en_US.json"
    fi

    # quickshell 7511545 generated qs imports only for named configurations
    if [[ -L "$config_path" ]]; then
      ln -sfn ${shellSource}/share/quickshell/ii "$config_path"
    elif [[ -e "$config_path" ]]; then
      printf 'error: %s already exists and is not a symlink\n' "$config_path" >&2
      exit 1
    else
      ln -s ${shellSource}/share/quickshell/ii "$config_path"
    fi

    # the host renderer owns every matugen output except colors.json
    if [[ ! -s "$colors_path" ]]; then
      bootstrap_home="$state_home/quickshell/matugen-bootstrap"
      mkdir -p "$bootstrap_home/matugen"
      cat > "$bootstrap_home/matugen/config.toml" <<EOF_THEME
    [config]
    version_check = false

    [templates.m3colors]
    input_path = '${shellTheme}/share/illogical-impulse-shell/matugen/colors.json'
    output_path = '$colors_path'
    EOF_THEME

      XDG_CONFIG_HOME="$bootstrap_home" ${lib.getExe matugen} \
        --source-color-index 0 \
        color hex '#6750A4' \
        --mode dark \
        --type scheme-tonal-spot \
        >/dev/null
    fi

    if [[ ! -e "$wallpaper_state_dir/category.txt" ]]; then
      printf '%s\n' 'unknown' > "$wallpaper_state_dir/category.txt"
    fi

    # upstream aed4d1ec first-run code launched the unrestricted wallpaper bootstrap
    if [[ ! -e "$state_home/quickshell/user/first_run.txt" ]]; then
      printf '%s\n' 'Initialized by the Nix launcher' > "$state_home/quickshell/user/first_run.txt"
    fi

    export PATH=${lib.makeBinPath runtimeInputs}:"$PATH"
    export FONTCONFIG_FILE=${fontConfig}
    export XDG_DATA_DIRS=${lib.makeSearchPath "share" iconInputs}:"''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    export QML2_IMPORT_PATH=${qmlImportPath}:"''${QML2_IMPORT_PATH:-}"
    export QML_IMPORT_PATH=${qmlImportPath}:"''${QML_IMPORT_PATH:-}"
    exec ${lib.getExe quickshell} -c ii "$@"
    EOF

    cat > "$out/bin/illogical-impulse-shell-ipc" <<'EOF_IPC'
    #!${bash}/bin/bash
    set -euo pipefail

    exec ${lib.getExe quickshell} -c ii ipc call "$@"
    EOF_IPC

    chmod +x \
      "$out/bin/illogical-impulse-shell" \
      "$out/bin/illogical-impulse-shell-ipc"

    runHook postInstall
  '';

  meta = {
    description = "Runnable packaging layer for the illogical-impulse Quickshell";
    homepage = "https://github.com/end-4/dots-hyprland";
    license = lib.licenses.gpl3Only;
    mainProgram = "illogical-impulse-shell";
    platforms = lib.platforms.linux;
  };
}