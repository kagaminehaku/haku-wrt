# Vendored files

haku-wrt builds only for NSY-G68-Plus and no longer downloads build dependencies.
These files were copied once from ophub's repositories and are now maintained here.

| Files in this repo | Source | Commit |
|---|---|---|
| `make-openwrt/u-boot/rockchip/nsy-g68-plus/` | [ophub/u-boot](https://github.com/ophub/u-boot) `u-boot/rockchip/nsy-g68-plus/` | `b08178c` |
| `make-openwrt/openwrt-files/common-files/lib/firmware/mediatek/` (MT7916 only) | [ophub/firmware](https://github.com/ophub/firmware) `firmware/mediatek/` | `f26c85f` |
| `make-openwrt/openwrt-files/platform-files/rockchip/bootfs/` (without `dtb/`) | [ophub/amlogic-s9xxx-armbian](https://github.com/ophub/amlogic-s9xxx-armbian) `build-armbian/armbian-files/platform-files/rockchip/` | `c3230bf` |
| `make-openwrt/openwrt-files/different-files/nsy-g68-plus/bootfs/`, `rootfs/etc/modules-load.d/bridge.conf`, `rootfs/etc/sysctl.d/99-custom.conf` | same, `different-files/nsy-g68-plus/` | `c3230bf` |
| `make-openwrt/openwrt-files/common-files/usr/sbin/balethirq.pl`, `etc/balance_irq` | same, `common-files/` | `c3230bf` |
| `make-openwrt/openwrt-files/common-files/usr/sbin/{openwrt-backup,openwrt-ddbr,openwrt-install-amlogic,openwrt-kernel,openwrt-update-*,fixcpufreq.pl}`, `usr/share/amlogic/` | [ophub/luci-app-amlogic](https://github.com/ophub/luci-app-amlogic) `luci-app-amlogic/root/usr/` | `e98bf87` |

Kernel build (`.github/workflows/compile-haku-kernel.yml`):

| Files in this repo | Source | Commit |
|---|---|---|
| `compile-kernel/tools/script/armbian_compile_kernel.sh`, `armbian-compile-kernel-depends` | [ophub/amlogic-s9xxx-armbian](https://github.com/ophub/amlogic-s9xxx-armbian) `compile-kernel/tools/script/` | `c3230bf` |
| `compile-kernel/tools/initramfs/post-update.d/99-uboot` | same, `build-armbian/armbian-files/common-files/etc/initramfs/post-update.d/` | `c3230bf` |
| `compile-kernel/tools/config/config-6.18` | [ophub/kernel](https://github.com/ophub/kernel) `kernel-config/release/stable/` | `ec2112a` |

The compile script was changed to build with the system gcc on the arm64 runner and to use only the vendored config. Kernel sources come from [kagaminehaku/linux-6.18.y](https://github.com/kagaminehaku/linux-6.18.y), a fork of ophub/linux-6.18.y.

Still downloaded at build time:

- Kernel: Releases of this repository, tag `kernel_stable` (`6.18.x.tar.gz`), published by `compile-haku-kernel`.
- Rootfs: OpenWrt / ImmortalWrt ImageBuilder from their official download servers.
- luci-app-amlogic package: Releases of ophub/luci-app-amlogic (`config/imagebuilder/imagebuilder.sh`).

`remake` checks that the vendored directories exist (`check_depends`) and stops if one is missing.
