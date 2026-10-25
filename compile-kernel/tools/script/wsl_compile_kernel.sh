#!/bin/bash
#==============================================================================
# Cross-compile the haku-wrt kernel on an x86_64 host (WSL2 / any Linux)
#
# Produces the same <version>.tar.gz as the "Compile haku-wrt kernel" workflow
# (boot-, dtb-rockchip- and modules-<kernel>.tar.gz plus sha256sums), which is
# what remake downloads from the kernel_stable release. The kernel is built
# with the aarch64 cross gcc; uInitrd is generated inside an arm64 Ubuntu
# chroot through qemu-user-static, because initramfs-tools packs the host's
# own binaries.
#
# Host packages (Ubuntu): build-essential gcc-aarch64-linux-gnu bc bison flex
#   libssl-dev libelf-dev ccache git u-boot-tools device-tree-compiler cpio
#   kmod rsync zstd qemu-user-static binfmt-support debootstrap
#
# Usage: sudo wsl_compile_kernel.sh [options]
#   -w <dir>   compile-kernel/tools directory (default: next to this script)
#   -s <dir>   kernel source (default /root/build/linux-6.18.y)
#   -l         build the source tree as it is (default: reset to origin/main)
#   -o <dir>   output directory (default /root/build/output)
#   -n <sign>  kernel signature (default -haku)
#   -d         dtbs only: build and print the G68 dtb, no packaging
#==============================================================================

set -eo pipefail

repo_url="https://github.com/kagaminehaku/linux-6.18.y.git"
src_dir="/root/build/linux-6.18.y"
out_dir="/root/build/output"
chroot_dir="/root/build/arm64-root"
custom_name="-haku"
use_local="no"
dtbs_only="no"

tools_dir="$(cd "$(dirname "${0}")/.." && pwd)"

while getopts "w:s:lo:n:d" opt; do
    case "${opt}" in
    w) tools_dir="${OPTARG}" ;;
    s) src_dir="${OPTARG}" ;;
    l) use_local="yes" ;;
    o) out_dir="${OPTARG}" ;;
    n) custom_name="${OPTARG}" ;;
    d) dtbs_only="yes" ;;
    *) exit 1 ;;
    esac
done
[[ "${custom_name:0:1}" == "-" ]] || custom_name="-${custom_name}"
config_file="${tools_dir}/config/config-6.18"
uboot_hook="${tools_dir}/initramfs/post-update.d/99-uboot"
[[ -s "${config_file}" && -s "${uboot_hook}" ]] || { echo "No config/uInitrd hook under ${tools_dir}"; exit 1; }
[[ "$(id -u)" -eq 0 ]] || { echo "Run as root (the uInitrd chroot needs it)."; exit 1; }

export CCACHE_DIR="/root/.ccache"
ccache -M 20G >/dev/null
make_args=(ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LOCALVERSION="${custom_name}"
    CC="ccache aarch64-linux-gnu-gcc")
jobs="$(nproc)"

# 1. Source
if [[ ! -d "${src_dir}/.git" ]]; then
    git clone --depth 1 -b main "${repo_url}" "${src_dir}"
elif [[ "${use_local}" == "no" ]]; then
    git -C "${src_dir}" fetch --depth 1 origin main
    git -C "${src_dir}" reset --hard origin/main
fi
cd "${src_dir}"
echo "Source: $(git log --oneline -1)"

# 2. Config, as the CI does: vendored config, empty CONFIG_LOCALVERSION
cp -f "${config_file}" .config
sed -i 's|CONFIG_LOCALVERSION=.*|CONFIG_LOCALVERSION=""|' .config
make "${make_args[@]}" olddefconfig >/dev/null

if [[ "${dtbs_only}" == "yes" ]]; then
    make "${make_args[@]}" rockchip/rk3568-nsy-g68-plus.dtb
    ls -l arch/arm64/boot/dts/rockchip/rk3568-nsy-g68-plus.dtb
    exit 0
fi

# 3. Kernel, modules, dtbs
start="$(date +%s)"
make -s "${make_args[@]}" Image modules dtbs -j"${jobs}"
echo "Compiled in $(($(date +%s) - start))s"

kernel_name="$(make -s "${make_args[@]}" kernelrelease)"
kernel_version="$(make -s kernelversion)"
stage="${out_dir}/stage"
rm -rf "${stage}" "${out_dir:?}/${kernel_version}"
mkdir -p "${stage}"/{boot,modules,dtb} "${out_dir}/${kernel_version}"

make -s "${make_args[@]}" INSTALL_MOD_PATH="${stage}/modules" modules_install
find "${stage}/modules" -name '*.ko' -print0 | xargs -0 aarch64-linux-gnu-strip --strip-debug
rm -f "${stage}/modules/lib/modules/${kernel_name}"/{build,source}

cp -f System.map "${stage}/boot/System.map-${kernel_name}"
cp -f .config "${stage}/boot/config-${kernel_name}"
cp -f arch/arm64/boot/Image "${stage}/boot/vmlinuz-${kernel_name}"

# 4. uInitrd, inside an arm64 chroot so the initramfs gets arm64 binaries
if [[ ! -x "${chroot_dir}/usr/sbin/update-initramfs" ]]; then
    debootstrap --arch=arm64 --variant=minbase \
        --include=initramfs-tools,u-boot-tools,xz-utils,kmod,zstd \
        noble "${chroot_dir}" http://ports.ubuntu.com/ubuntu-ports
fi
install -D -m 0755 "${uboot_hook}" "${chroot_dir}/etc/initramfs/post-update.d/99-uboot"
sed -i 's|^COMPRESS=.*|COMPRESS=xz|' "${chroot_dir}/etc/initramfs-tools/initramfs.conf"
sed -i 's|^update_initramfs=.*|update_initramfs=yes|' "${chroot_dir}/etc/initramfs-tools/update-initramfs.conf"

rm -rf "${chroot_dir}/boot" "${chroot_dir}/usr/lib/modules"
mkdir -p "${chroot_dir}/boot" "${chroot_dir}/usr/lib/modules"
cp -f "${stage}/boot"/* "${chroot_dir}/boot/"
cp -a "${stage}/modules/lib/modules/${kernel_name}" "${chroot_dir}/usr/lib/modules/"

for fs in proc sys dev; do mount --bind "/${fs}" "${chroot_dir}/${fs}"; done
trap 'for fs in proc sys dev; do umount -l "${chroot_dir}/${fs}" 2>/dev/null || true; done' EXIT
chroot "${chroot_dir}" update-initramfs -c -k "${kernel_name}"
for fs in proc sys dev; do umount -l "${chroot_dir}/${fs}"; done
trap - EXIT

[[ -f "${chroot_dir}/boot/uInitrd-${kernel_name}" ]] || { echo "uInitrd was not generated"; exit 1; }
cp -f "${chroot_dir}/boot"/{initrd.img,uInitrd}-"${kernel_name}" "${stage}/boot/"

# 5. Archives, laid out like the CI output
(cd "${stage}/boot" && chmod +x * && tar -czf "${out_dir}/${kernel_version}/boot-${kernel_name}.tar.gz" *)

cp -f arch/arm64/boot/dts/rockchip/*.dtb "${stage}/dtb/"
if [[ -d arch/arm64/boot/dts/rockchip/overlay ]]; then
    mkdir -p "${stage}/dtb/overlay"
    cp -f arch/arm64/boot/dts/rockchip/overlay/*.dtbo "${stage}/dtb/overlay/" 2>/dev/null || true
fi
(cd "${stage}/dtb" && tar -czf "${out_dir}/${kernel_version}/dtb-rockchip-${kernel_name}.tar.gz" *)

(cd "${stage}/modules/lib/modules" && tar -czf "${out_dir}/${kernel_version}/modules-${kernel_name}.tar.gz" *)

cd "${out_dir}/${kernel_version}"
sha256sum *.tar.gz >sha256sums
cd "${out_dir}"
tar -czf "${kernel_version}.tar.gz" "${kernel_version}"
rm -rf "${stage}"

echo "Done in $(($(date +%s) - start))s: ${out_dir}/${kernel_version}.tar.gz (${kernel_name})"
echo "Upload: gh release upload kernel_stable ${kernel_version}.tar.gz --clobber"
