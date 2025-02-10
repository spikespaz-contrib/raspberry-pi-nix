{ openssl, libtiff, libglibutil, gst_all_1, python3, libpisp, libcamera
, libcamera-src }:

libcamera.overrideAttrs (old: {
  version = "0.3.1";
  src = libcamera-src;
  buildInputs = old.buildInputs ++ [
    libpisp
    openssl
    libtiff
    (python3.withPackages (ps: with ps; [ python3-gnutls pybind11 pyyaml ply ]))
    libglibutil
    gst_all_1.gst-plugins-base
  ];
  patches = [ ];
  postPatch = ''
    patchShebangs src/py/ utils/
  '';
  mesonFlags = [
    "--buildtype=release"
    "-Dpipelines=rpi/vc4,rpi/pisp"
    "-Dipas=rpi/vc4,rpi/pisp"
    "-Dv4l2=true"
    "-Dgstreamer=enabled"
    "-Dtest=false"
    "-Dlc-compliance=disabled"
    "-Dcam=disabled"
    "-Dqcam=disabled"
    "-Ddocumentation=enabled"
    "-Dpycamera=enabled"
  ];
})
