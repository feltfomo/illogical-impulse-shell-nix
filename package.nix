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
    # The public Kirigami package is an empty propagation wrapper. Include its
    # real QML payload and desktop style explicitly in the launcher closure.
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

  # The Qt wrapper hook does not discover every QML-only module from a shell
  # launcher, so expose their import roots explicitly as well.
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
    state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"

    mkdir -p "$config_root" "$state_home/quickshell/user"

    # Quickshell's synthetic `qs.*` module namespace is generated for named
    # configurations. Keep the immutable source in the store and expose it as
    # the upstream `ii` configuration rather than launching shell.qml by path.
    if [[ -L "$config_path" ]]; then
      ln -sfn ${shellSource}/share/quickshell/ii "$config_path"
    elif [[ -e "$config_path" ]]; then
      printf 'error: %s already exists and is not a symlink\n' "$config_path" >&2
      exit 1
    else
      ln -s ${shellSource}/share/quickshell/ii "$config_path"
    fi

    # Keep the first packaging launch from starting upstream's wallpaper/theme
    # bootstrap before those external resources have been packaged.
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
    chmod +x "$out/bin/illogical-impulse-shell"

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