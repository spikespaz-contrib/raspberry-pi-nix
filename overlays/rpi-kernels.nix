{ lib, fetchpatch, buildLinux, rpi-linux-stable-src, rpi-linux-6_6_67-src
, rpi-linux-6_12_11-src }:

let
  versions = {
    v6_6_51.src = rpi-linux-stable-src;
    v6_6_67.src = rpi-linux-6_6_67-src;
    v6_12_11 = {
      src = rpi-linux-6_12_11-src;
      patches = [{
        name = "remove-readme-target.patch";
        patch = fetchpatch {
          url =
            "https://github.com/raspberrypi/linux/commit/3c0fd51d184f1748b83d28e1113265425c19bcb5.patch";
          hash = "sha256-v7uZOmPCUp2i7NGVgjqnQYe6dEBD+aATuP/oRs9jfuk=";
        };
      }];
    };
  };
  boards = [ "bcm2711" "bcm2712" ];

  mkRaspberryPiKernel = { version, board }:
    buildRaspberryPiKernel {
      inherit (versions.${version}) src;
      inherit lib buildLinux board;
      version = lib.replaceStrings [ "v" "_" ] [ "" "." ] version;
      kernelPatches = versions.${version}.patches or [ ];
    };

  buildRaspberryPiKernel =
    { lib, buildLinux, version, src, board, kernelPatches ? [ ] }:
    (buildLinux {
      pname = "linux-rpi";
      inherit version src;
      modDirVersion = version;
      defconfig = "${board}_defconfig";
      structuredExtraConfig = with lib.kernel; {
        # The perl script to generate kernel options sets unspecified
        # parameters to `m` if possible [1]. This results in the
        # unspecified config option KUNIT [2] getting set to `m` which
        # causes DRM_VC4_KUNIT_TEST [3] to get set to `y`.
        #
        # This vc4 unit test fails on boot due to a null pointer
        # exception with the existing config. I'm not sure why, but in
        # any case, the DRM_VC4_KUNIT_TEST config option itself states
        # that it is only useful for kernel developers working on the
        # vc4 driver. So, I feel no need to deviate from the standard
        # rpi kernel and attempt to successfully enable this test and
        # other unit tests because the nixos perl script has this
        # sloppy "default to m" behavior. So, I set KUNIT to `n`.
        #
        # [1] https://github.com/NixOS/nixpkgs/blob/85bcb95aa83be667e562e781e9d186c57a07d757/pkgs/os-specific/linux/kernel/generate-config.pl#L1-L10
        # [2] https://github.com/raspberrypi/linux/blob/1.20230405/lib/kunit/Kconfig#L5-L14
        # [3] https://github.com/raspberrypi/linux/blob/bb63dc31e48948bc2649357758c7a152210109c4/drivers/gpu/drm/vc4/Kconfig#L38-L52
        KUNIT = no;
      };
      features.efiBootStub = false;
      inherit kernelPatches;
    }).overrideAttrs (super: {
      postConfigure = super.postConfigure or "" + ''
        # The v7 defconfig has this set to '-v7' which screws up our modDirVersion.
        sed -i $buildRoot/.config -e 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=""/'
        sed -i $buildRoot/include/config/auto.conf -e 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=""/'
      '';
    });

in lib.genAttrs (lib.attrNames versions) (version:
  lib.genAttrs boards (board: mkRaspberryPiKernel { inherit version board; }))
