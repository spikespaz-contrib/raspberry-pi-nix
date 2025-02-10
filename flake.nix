{
  description = "raspberry-pi nixos configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11-small";
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
      overlays = import ./overlays { inherit lib self srcs; };

      nixosModules = {
        raspberry-pi = import ./rpi { inherit self pinned; };
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
        kernels = lib.foldlAttrs (acc: version: boardAttrs:
          acc // lib.foldlAttrs
          (acc: board: drv: acc // { "linux-${version}-${board}" = drv; }) { }
          boardAttrs) { } pinned.rpi-kernels;
        packages = {
          inherit (pinned)
            libcamera-apps libcamera libpisp raspberrypi-wireless-firmware
            raspberrypi-firmware uboot-rpi-arm64;
        };
        special = {
          example-sd-image =
            self.nixosConfigurations.rpi-example.config.system.build.sdImage;
          # Alias
          wireless-firmware = pinned.raspberrypi-wireless-firmware;
        };

      in kernels // packages // special;

      formatter =
        lib.genAttrs [ "aarch64-linux" "aarch64-darwin" "x86_64-linux" ]
        (system: nixpkgs.legacyPackages.${system}.nixfmt-classic);
    };
}
