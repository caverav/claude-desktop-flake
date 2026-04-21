{
  lib,
  stdenvNoCC,
  fetchurl,
  undmg,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "claude-desktop";
  version = "1.3561.0";

  src = fetchurl {
    url = "https://downloads.claude.ai/releases/darwin/universal/${finalAttrs.version}/Claude-fbc74be3fdc714a2c46ef1fb84f71d4e4c062930.dmg";
    hash = "sha256-AsZTF4gBfddWM/XYnIRiA8nDxb67VYRIbLzuEdgeIY4=";
  };

  nativeBuildInputs = [ undmg ];

  sourceRoot = ".";

  dontFixup = true;

  unpackPhase = ''
    runHook preUnpack
    undmg "$src"
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications" "$out/bin"
    cp -R Claude.app "$out/Applications/Claude.app"
    ln -s "$out/Applications/Claude.app/Contents/MacOS/Claude" \
      "$out/bin/claude-desktop"

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Anthropic's official desktop client for Claude";
    homepage = "https://claude.ai/download";
    changelog = "https://claude.ai/download";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    mainProgram = "claude-desktop";
    maintainers = [ ];
  };
})
