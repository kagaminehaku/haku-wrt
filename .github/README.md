# haku-wrt

OpenWrt / ImmortalWrt firmware for the **NSY-G68-Plus** (农商云 G68 AX3000) router, and nothing else.

haku-wrt is built on [ophub/amlogic-s9xxx-openwrt](https://github.com/ophub/amlogic-s9xxx-openwrt) and keeps its full git history, so upstream fixes can still be merged. Files for other devices are left in place untouched but are not built or supported here.

## Hardware

| Part | Detail |
|---|---|
| SoC | Rockchip RK3568, 4x Cortex-A55 |
| RAM | 4GB DDR4 |
| Switch | RTL8367S, 4 LAN + 1 WAN, gigabit (DSA) |
| WiFi | MediaTek MT7916 (AX3000, 2.4G + 5G), open-source mt76 driver |
| Storage | eMMC, M.2 NVMe, USB 3.0 |

WiFi only works on boards where the MT7916 shows up as both `14c3:7906` and `14c3:790a` (`lspci`). Boards with only `14c3:790a` need the closed MTK driver, which haku-wrt doesn't ship (see [ophub#845](https://github.com/ophub/amlogic-s9xxx-openwrt/issues/845)).

## How it differs from ophub

- **WiFi 6 works.** ophub's packaging rewrites `iw` to a nonexistent `ipconfig` in `mac80211.sh`, which breaks HE (802.11ax) mode. haku-wrt applies that only on Amlogic, and the G68 defaults to 2.4G `HE20` / 5G `HE80`. The fix was also sent upstream in [ophub#965](https://github.com/ophub/amlogic-s9xxx-openwrt/pull/965).
- **Pinned kernel.** Kernels come from this repository's [`kernel_stable`](https://github.com/kagaminehaku/haku-wrt/releases/tag/kernel_stable) release instead of ophub/kernel, which keeps only the latest few builds. A kernel changes only when a tested one is uploaded here.
- **Own dependency sources.** u-boot, firmware, platform files and luci-app-amlogic scripts are fetched from forks under [kagaminehaku](https://github.com/kagaminehaku), synced on demand.
- **Own update channel.** `System → Amlogic Service → Online Download Update` downloads haku-wrt releases (tags starting with `haku-wrt_g68_`), not stock ophub images.

## Download

Prebuilt images are on the [Releases](https://github.com/kagaminehaku/haku-wrt/releases) page. The file name looks like `openwrt_..._rockchip_nsy-g68-plus_k6.18.x_<date>.img.gz`.

Default login: `192.168.1.1`, user `root`, password `password`.

## Build

1. Upload a tested kernel (for example `6.18.58.tar.gz` from [ophub/kernel](https://github.com/ophub/kernel/releases/tag/kernel_stable)) to the `kernel_stable` release of this repository.
2. Open **Actions → Build haku-wrt for NSY-G68-Plus → Run workflow**, then pick the rootfs branch.
3. The image is published as a new `haku-wrt_g68_<branch>_<date>` release.

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
