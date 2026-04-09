{
  lib,
  stdenv,
  autoreconfHook,
  pkg-config,
  texinfo,
  hidapi,
  libusb1,
  src,
}:

stdenv.mkDerivation {
  pname = "openocd-ht32";
  version = "unstable-2017-01-04";
  inherit src;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    texinfo
  ];

  buildInputs = [
    hidapi
    libusb1
  ];

  configureFlags = [
    "--enable-stlink"
    "--disable-werror"
  ];

  meta = with lib; {
    description = "OpenOCD fork with Holtek HT32F165x support";
    homepage = "https://github.com/ChaoticEnigma/openocd-ht32";
    license = licenses.gpl2Only;
    platforms = platforms.unix;
  };
}
