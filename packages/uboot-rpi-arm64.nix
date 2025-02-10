{ buildUBoot, u-boot-src }:
buildUBoot {
  defconfig = "rpi_arm64_defconfig";
  extraMeta.platforms = [ "aarch64-linux" ];
  filesToInstall = [ "u-boot.bin" ];
  version = "2024.04";
  patches = [ ];
  makeFlags = [ ];
  src = u-boot-src;
  # In raspberry pi sbcs the firmware manipulates the device tree in
  # a variety of ways before handing it off to the linux kernel. [1]
  # Since we have installed u-boot in place of a linux kernel we may
  # pass the device tree passed by the firmware onto the kernel, or
  # we may provide the kernel with a device tree of our own. This
  # configuration uses the device tree provided by firmware so that
  # we don't have to be aware of all manipulation done by the
  # firmware and attempt to mimic it.
  #
  # 1. https://forums.raspberrypi.com/viewtopic.php?t=329799#p1974233
}
