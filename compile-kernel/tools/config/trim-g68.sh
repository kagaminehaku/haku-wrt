#!/bin/bash
#==============================================================================
# Trim the vendored kernel config (inherited from ophub's all-boards config)
# down to what the NSY-G68-Plus can use, and write it back.
#
# Removed: every arm64 platform but Rockchip (their SoC drivers go with them),
# display/GPU (DRM, framebuffer), sound, TV/radio/SDR and camera sensors,
# touchscreens, joysticks, tablets, IIO sensors (only the SARADC behind the
# reset button is kept), staging, FPGA, 1-Wire, aux displays, USB gadget mode
# (the USB port is host only) and the Unisoc UWE5622 SDIO WiFi of
# Allwinner/Amlogic boards.
#
# Kept as modules on purpose, so devices plugged in later still work without
# a rebuild: all networking and netfilter, USB Ethernet/modem/serial/storage
# adapters, USB and PCIe WiFi, Bluetooth, HID, filesystems, crypto, and for
# NVR use USB webcams (UVC) plus the RK3568 video blocks (Hantro, RKVDEC, RGA).
#
# Usage: trim-g68.sh <kernel-source> [config]   (default: config-6.18 here)
#==============================================================================

set -eo pipefail

src="${1:?kernel source directory}"
config="$(realpath "${2:-$(dirname "${0}")/config-6.18}")"
make_args=(ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-)

cd "${src}"
cp -f "${config}" .config
cfg() { scripts/config --file .config "$@"; }

# Platforms
for p in $(grep -oP '^config \KARCH_\w+' arch/arm64/Kconfig.platforms); do
    [[ "${p}" == "ARCH_ROCKCHIP" ]] || cfg -d "${p}"
done

# Whole subsystems a router without screen or audio never uses
for s in DRM FB SOUND STAGING FPGA W1 AUXDISPLAY USB_GADGET \
    INPUT_TOUCHSCREEN INPUT_JOYSTICK INPUT_TABLET WLAN_UWE5622 SPARD_WLAN_SUPPORT; do
    cfg -d "${s}"
done

# Media: keep what an NVR box can use, i.e. USB webcams (UVC) and the
# RK3568's own video blocks (Hantro VPU/VEPU, RKVDEC, RGA); drop TV, radio,
# SDR, test drivers, camera sensors and every other board's media hardware
for s in MEDIA_ANALOG_TV_SUPPORT MEDIA_DIGITAL_TV_SUPPORT MEDIA_RADIO_SUPPORT \
    MEDIA_SDR_SUPPORT MEDIA_TEST_SUPPORT VIDEO_CAMERA_SENSOR; do
    cfg -d "${s}"
done
for s in $(grep -rhoP '^config \K\w+' drivers/media --include='Kconfig*' | sort -u); do
    case "${s}" in
    USB_VIDEO_CLASS | VIDEO_HANTRO | VIDEO_ROCKCHIP_VDEC | VIDEO_ROCKCHIP_RGA) ;;
    *) grep -q "^CONFIG_${s}=m" .config && cfg -d "${s}" ;;
    esac
done

# IIO: keep the core and the SARADC (reset button via adc-keys) only
for s in $(grep -rhoP '^config \K\w+' drivers/iio --include='Kconfig*' | sort -u); do
    case "${s}" in
    IIO | ROCKCHIP_SARADC) ;;
    *) grep -q "^CONFIG_${s}=m" .config && cfg -d "${s}" ;;
    esac
done

make "${make_args[@]}" olddefconfig >/dev/null
cp -f .config "${config}"
echo "Trimmed: ${config} ($(grep -c '=m$' "${config}") modules, $(grep -c '=y$' "${config}") built-in)"
