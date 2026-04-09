{
  lib,
  python3Packages,
  src,
}:

python3Packages.buildPythonApplication {
  pname = "pok3rtool";
  version = "2.0";
  format = "pyproject";
  inherit src;

  nativeBuildInputs = [
    python3Packages.setuptools
    python3Packages.wheel
  ];

  propagatedBuildInputs = [
    python3Packages.hid-parser
    python3Packages.pyusb
    python3Packages.rich
    python3Packages.tqdm
    python3Packages.typer
  ];

  meta = with lib; {
    description = "CLI tool for flashing Vortex and related keyboards";
    homepage = "https://github.com/pok3r-custom/pok3rtool";
    license = licenses.gpl3Plus;
    platforms = platforms.unix;
  };
}
