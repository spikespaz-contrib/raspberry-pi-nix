{ lib, self, srcs }:

let
  packages = import ./packages.nix { inherit srcs; };

  attributes = {
    rpi-kernels = final: prev: {
      rpi-kernels = final.callPackage ./rpi-kernels.nix {
        inherit (srcs)
          rpi-linux-stable-src rpi-linux-6_6_67-src rpi-linux-6_12_11-src;
      };
    };
  };

  composites = {
    core = with self.overlays;
      lib.composeManyExtensions [
        # TODO: Is this necessary? What derivations use these functions?
        (final: prev: {
          # disable firmware compression so that brcm firmware can be found at
          # the path expected by raspberry pi firmware/device tree
          compressFirmwareXz = x: x;
          compressFirmwareZstd = x: x;
        })
        raspberrypi-wireless-firmware
        rpi-kernels
        uboot-rpi-arm64
      ];

    # This takes the place of the overlay for `packages/libcamera.nix`, includes dependencies.
    libcamera = with self.overlays;
      lib.composeManyExtensions [ # #
        packages.libcamera
        libcamera-apps
        libpisp
      ];
  };

in packages // attributes // composites
