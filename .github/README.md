# haku-wrt

OpenWrt / ImmortalWrt firmware for the **NSY-G68-Plus** (农商云 G68 AX3000) router, and nothing else.

haku-wrt started from the build tooling of [ophub/amlogic-s9xxx-openwrt](https://github.com/ophub/amlogic-s9xxx-openwrt). Files for other devices are still in the tree but are not built or supported here.

## Hardware

| Part | Detail |
|---|---|
| SoC | Rockchip RK3568, 4x Cortex-A55 |
| RAM | 4GB DDR4 |
| Switch | RTL8367S, 4 LAN + 1 WAN, gigabit (DSA), linked to the SoC over RGMII (gmac0) and SGMII (gmac1) |
| WiFi | MediaTek MT7916 (AX3000, 2.4G + 5G), open-source mt76 driver |
| Storage | 64GB eMMC, M.2 NVMe (bootable), USB 3.0 |
| Power | discrete regulators (no PMIC), PWM-controlled CPU voltage |

WiFi only works on boards where the MT7916 shows up as both `14c3:7906` and `14c3:790a` (`lspci`). Boards with only `14c3:790a` need the closed MTK driver, which haku-wrt doesn't ship (see [ophub#845](https://github.com/ophub/amlogic-s9xxx-openwrt/issues/845)).

## Features

- **WiFi 6 out of the box.** 2.4G `HE20` and 5G `HE80` (802.11ax) on the MT7916, using the board's own calibration data.
- **WAN on its own gigabit link.** The switch forwards the WAN port in hardware to gmac1 over SGMII, so WAN and LAN no longer share one link to the SoC. The WAN port is chosen in LuCI: whichever port sits in the `br-wanlink` bridge with `sgmii` is WAN.
- **Boots from NVMe.** Mainline U-Boot in the SPI flash boots NVMe first, then eMMC, then USB, so the system can live on an M.2 SSD and spare the eMMC. Holding the reset button at power-on boots a USB rescue stick.
- **Port LEDs you can configure.** Each port LED is a Linux LED device; pick link, activity or speed modes in `System → LED Configuration`, and the switch drives them in hardware.
- **Kernel made for this board.** A 6.18.y kernel from [kagaminehaku/linux-6.18.y](https://github.com/kagaminehaku/linux-6.18.y) with G68 fixes (PCIe link stability after U-Boot, RTL8367S LEDs and SGMII, an accurate device tree) and a config trimmed to what the board can use, while keeping USB Ethernet, 4G modems, USB storage, USB WiFi, webcams and the RK3568 video blocks available.
- **Safe defaults.** The LAN defaults to `192.168.2.1`, so it does not clash with ISP modems on `192.168.1.x`, and a fresh install keeps WiFi off with a random WPA2/WPA3 key instead of broadcasting an open network.
- **zapret and AdGuard Home included.** Both are under `Services` in LuCI. zapret (DPI bypass, from [remittor/zapret-openwrt](https://github.com/remittor/zapret-openwrt)) needs a strategy that suits your ISP. AdGuard Home starts with its setup wizard on port 3000, and DNS falls back to the default upstream if it stops.
- **Self-contained builds.** U-Boot, kernel and firmware are all built from this repository, with the board's u-boot, MT7916 firmware and platform files vendored (see [VENDORED.md](../make-openwrt/VENDORED.md)).
- **Own update channel.** `System → Amlogic Service → Online Download Update` downloads haku-wrt releases (tags starting with `haku-wrt_g68_`), and updates keep your config.

## Download

Prebuilt images are on the [Releases](https://github.com/kagaminehaku/haku-wrt/releases) page. The file name looks like `openwrt_..._rockchip_nsy-g68-plus_k6.18.x_<date>.img.gz`.

Default login: `192.168.2.1`, user `root`, password `password`. Change the password and set up WiFi (`Network → Wireless`) after the first login.

## Build

1. Run **Actions → Compile haku-wrt kernel**. It builds the latest 6.18.y from kagaminehaku/linux-6.18.y on an arm64 runner (about an hour) and uploads `6.18.x.tar.gz` to the `kernel_stable` release.
2. Run **Actions → Build haku-wrt for NSY-G68-Plus**, then pick the rootfs branch.
3. The image is published as a new `haku-wrt_g68_<branch>_<date>` release.

To change the kernel (DTS, drivers, config), edit kagaminehaku/linux-6.18.y or `compile-kernel/tools/config/config-6.18` and rerun step 1. `compile-kernel/tools/config/trim-g68.sh` regenerates the trimmed config.

The kernel can also be built on an x86_64 Linux or WSL2 machine with `compile-kernel/tools/script/wsl_compile_kernel.sh`, which cross-compiles it, builds uInitrd in an arm64 chroot and produces the same `6.18.x.tar.gz` for `kernel_stable` (about 25 minutes from scratch on a desktop CPU, a few minutes for small changes).

**Actions → Compile haku-wrt U-Boot** builds the SPI flash bootloader (`uboot_g68` release).

The other workflows inherited from ophub are disabled in the Actions settings.

## Flashing

Flash to eMMC with RKDevTool in MaskROM/Loader mode. The tools and step-by-step guide are collected by ophub here: [nsy-g68-plus flashing methods and tools](https://github.com/ophub/kernel/releases/download/tools/nsy-g68-plus_nsy-g16-plus_Flashing-methods-and-tools.tar.gz). Back up the original SPI/eMMC first.

## Credits

- [ophub](https://github.com/ophub) for amlogic-s9xxx-openwrt, kernel, u-boot, firmware and luci-app-amlogic
- [unifreq (flippy)](https://github.com/unifreq) for the kernel trees and openwrt_packit
- [zhoufuli/immortalwrt-rk356x](https://github.com/zhoufuli/immortalwrt-rk356x) for the original G68 DTS and u-boot configuration
- liubei1998, xiaomeng9597, maojun1998, nanosunny, faq110, robinZhao and everyone in [ophub#845](https://github.com/ophub/amlogic-s9xxx-openwrt/issues/845)
- [OpenWrt](https://openwrt.org) and [ImmortalWrt](https://immortalwrt.org)

## License

GPL-2.0, same as upstream. See [LICENSE](../LICENSE).
