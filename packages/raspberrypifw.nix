{ raspberrypifw, rpi-firmware-src }:

raspberrypifw.overrideAttrs (_: { src = rpi-firmware-src; })
