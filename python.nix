{
  python3,
  runCommand,
}:
let
  pythonEnvironment = python3.withPackages (
    pythonPackages: with pythonPackages; [
      build
      click
      google-auth
      kde-material-you-colors
      libsass
      loguru
      material-color-utilities
      materialyoucolor
      numpy
      opencv4
      pillow
      psutil
      pycairo
      pygobject3
      pywayland
      requests
      setproctitle
      setuptools-scm
      tqdm
      wheel
    ]
  );
in
runCommand "illogical-impulse-shell-python" { } ''
  mkdir -p "$out/bin"

  for executable in ${pythonEnvironment}/bin/*; do
    ln -s "$executable" "$out/bin/$(basename "$executable")"
  done

  cat > "$out/bin/activate" <<EOF
  _illogical_impulse_old_path="\$PATH"
  export PATH="${pythonEnvironment}/bin:\$PATH"

  deactivate() {
    export PATH="\$_illogical_impulse_old_path"
    unset _illogical_impulse_old_path
    unset -f deactivate
  }
  EOF
''
