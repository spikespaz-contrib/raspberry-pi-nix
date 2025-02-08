{
  description = "raspberry-pi nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    u-boot-src = {
      flake = false;
      url = "https://ftp.denx.de/pub/u-boot/u-boot-2024.07.tar.bz2";
    };
    rpi-linux-stable-src = {
      flake = false;
      url = "github:raspberrypi/linux/stable_20241008";
    };
    rpi-linux-6_6_67-src = {
      flake = false;
      url = "github:raspberrypi/linux/rpi-6.6.y";
    };
    rpi-linux-6_12_11-src = {
      flake = false;
      url = "github:raspberrypi/linux/rpi-6.12.y";
    };
    rpi-firmware-src = {
      flake = false;
      url = "github:raspberrypi/firmware/1.20241008";
    };
    rpi-firmware-nonfree-src = {
      flake = false;
      url = "github:RPi-Distro/firmware-nonfree/bookworm";
    };
    rpi-bluez-firmware-src = {
      flake = false;
      url = "github:RPi-Distro/bluez-firmware/bookworm";
    };
    rpicam-apps-src = {
      flake = false;
      url = "github:raspberrypi/rpicam-apps/v1.5.2";
    };
    libcamera-src = {
      flake = false;
      url =
        "github:raspberrypi/libcamera/69a894c4adad524d3063dd027f5c4774485cf9db"; # v0.3.1+rpt20240906
    };
    libpisp-src = {
      flake = false;
      url = "github:raspberrypi/libpisp/v1.0.7";
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;

      srcs = builtins.removeAttrs inputs [ "self" "nixpkgs" ];

      pinned = import nixpkgs {
        system = "aarch64-linux";
        overlays = with self.overlays; [ core libcamera ];
      };
    in {
      overlays = {
        core = import ./overlays srcs;
        libcamera = import ./overlays/libcamera.nix srcs;
      };

      nixosModules = {
        raspberry-pi = import ./rpi {
          inherit pinned;
          core-overlay = self.overlays.core;
          libcamera-overlay = self.overlays.libcamera;
        };
        sd-image = import ./sd-image;
      };

      nixosConfigurations = {
        rpi-example = lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            self.nixosModules.raspberry-pi
            self.nixosModules.sd-image
            ./example
          ];
        };
      };

      checks.aarch64-linux = self.packages.aarch64-linux;

      packages.aarch64-linux = let
        kernels = lib.foldlAttrs f { } pinned.rpi-kernels;
        f = acc: kernel-version: board-attr-set:
          lib.foldlAttrs (acc: board-version: drv:
            acc // {
              "linux-${kernel-version}-${board-version}" = drv;
            }) acc board-attr-set;
      in {
        example-sd-image =
          self.nixosConfigurations.rpi-example.config.system.build.sdImage;
        firmware = pinned.raspberrypifw;
        libcamera = pinned.libcamera;
        wireless-firmware = pinned.raspberrypiWirelessFirmware;
        uboot-rpi-arm64 = pinned.uboot-rpi-arm64;
      } // kernels;

      formatter =
        lib.genAttrs [ "aarch64-linux" "aarch64-darwin" "x86_64-linux" ]
        (system: nixpkgs.legacyPackages.${system}.nixfmt-classic);
    };
}
