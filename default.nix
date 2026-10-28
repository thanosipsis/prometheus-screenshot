{
  lib,
  stdenvNoCC,
  makeWrapper,
  quickshell,
  grim,
  imagemagick,
  wl-clipboard,
  python3,
  hyprland,
  libnotify,
}:
stdenvNoCC.mkDerivation {
  pname = "prometheus-screenshot";
  version = "0.1.0";

  src = lib.cleanSource ./.;

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/prometheus-screenshot
    cp -r icons shaders src theme shell.qml launch.py capture.py $out/share/prometheus-screenshot/

    mkdir -p $out/bin
    makeWrapper ${python3}/bin/python3 $out/bin/prometheus-screenshot \
      --add-flags "$out/share/prometheus-screenshot/launch.py" \
      --prefix PATH : ${
        lib.makeBinPath [
          quickshell
          python3
          hyprland
          libnotify
          grim
          imagemagick
          wl-clipboard
        ]
      }

    runHook postInstall
  '';

  meta = {
    description = "A Prometheus-themed screenshot utility for Hyprland built with Quickshell";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "prometheus-screenshot";
  };
}
