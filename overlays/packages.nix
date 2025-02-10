{ srcs }: {
  # A recent known working version of rpicam-apps
  libcamera-apps = final: prev: {
    libcamera-apps = final.callPackage ../packages/libcamera-apps.nix {
      inherit (srcs) rpicam-apps-src;
    };
  };

  libcamera = final: prev: {
    libcamera = final.callPackage ../packages/libcamera.nix {
      inherit (prev) libcamera;
      inherit (srcs) libcamera-src;
    };
  };

  libpisp = final: prev: {
    libpisp = final.callPackage ../packages/libpisp.nix { # #
      inherit (srcs) libpisp-src;
    };
  };

  raspberrypi-wireless-firmware = final: prev: {
    raspberrypi-wireless-firmware =
      final.callPackage ../packages/raspberrypi-wireless-firmware.nix {
        bluez-firmware = srcs.rpi-bluez-firmware-src;
        firmware-nonfree = srcs.rpi-firmware-nonfree-src;
      };
  };

  raspberrypifw = final: prev: {
    raspberrypifw = final.callPackage ../packages/raspberrypifw.nix {
      inherit (srcs) rpi-firmware-src;
    };
  };

  uboot-rpi-arm64 = final: prev: {
    uboot-rpi-arm64 = final.callPackage ../packages/uboot-rpi-arm64.nix {
      inherit (srcs) u-boot-src;
    };
  };
}
