{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  stdenv,
}:
stdenvNoCC.mkDerivation {
  pname = "supermaven-agent";
  version = "2-8";
  src = fetchurl {
    url = "https://supermaven-public.s3.amazonaws.com/sm-agent/v2/8/linux-musl/x86_64/sm-agent";
    sha256 = "96c692ec8a0d4142244cbd50a3e53299e0fccb8797e263d1e97142daa325a788";
  };
  dontUnpack = true;
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];
  installPhase = ''
    install -Dm755 "$src" "$out/bin/sm-agent"
  '';
  meta = {
    description = "Supermaven agent for the Neovim completion integration";
    homepage = "https://supermaven.com";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
