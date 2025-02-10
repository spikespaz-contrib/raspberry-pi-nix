{ lib, stdenv, pkg-config, meson, ninja, boost, nlohmann_json, libpisp-src }:

stdenv.mkDerivation {
  name = "libpisp";
  version = "1.0.7";
  src = libpisp-src;
  nativeBuildInputs = [ pkg-config meson ninja ];
  buildInputs = [ nlohmann_json boost ];
  # Meson is no longer able to pick up Boost automatically.
  # https://github.com/NixOS/nixpkgs/issues/86131
  BOOST_INCLUDEDIR = "${lib.getDev boost}/include";
  BOOST_LIBRARYDIR = "${lib.getLib boost}/lib";
}
