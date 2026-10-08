{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  stdenv,
}:
let
  binaries = {
    x86_64-linux = {
      architecture = "x86_64";
      sha256 = "96c692ec8a0d4142244cbd50a3e53299e0fccb8797e263d1e97142daa325a788";
    };
    aarch64-linux = {
      architecture = "aarch64";
      sha256 = "157a2df3f427ac89c28893fe6be4a730e38e982bf50471303fd4f9f1b5ea7bdf";
    };
  };
  binary = binaries.${stdenv.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "supermaven-agent";
  version = "2-8";
  src = fetchurl {
    url = "https://supermaven-public.s3.amazonaws.com/sm-agent/v2/8/linux-musl/${binary.architecture}/sm-agent";
    inherit (binary) sha256;
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
    platforms = builtins.attrNames binaries;
  };
}
