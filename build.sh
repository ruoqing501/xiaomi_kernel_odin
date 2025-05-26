#!/bin/bash
#
# Enhanced compile script for Xiaomi_kernel_odin
# This script is based on ubuntu 18.4.6
# Copyright (C) 2023-2025 Ruoqing

# 字体颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 脚本说明
echo -e "${YELLOW}==================================================${NC}"
echo -e "${YELLOW}                脚本说明              ${NC}"
echo -e "${YELLOW}                                      ${NC}"
echo -e "${YELLOW}             作者: 情若相惜 ღ             ${NC}"
echo -e "${YELLOW}             QQ群：290495721          ${NC}"
echo -e "${YELLOW}            ubuntu版本：18.4.6        ${NC}"
echo -e "${YELLOW}==================================================${NC}"

# 文件路径
CURRENT_DIR=$(pwd)
KERNEL_DIR="${CURRENT_DIR}/xiaomi_kernel_odin"
CLANG_DIR="${KERNEL_DIR}/scripts/tools/clang-r383902b1"
GCC64_DIR="${KERNEL_DIR}/scripts/tools/aarch64-linux-android-4.9"
GCC_DIR="${KERNEL_DIR}/scripts/tools/arm-linux-androideabi-4.9"
ANYKERNEL_DIR="${KERNEL_DIR}/scripts/tools/AnyKernel3"
IMAGE_DIR="${KERNEL_DIR}/out/arch/arm64/boot/Image"
MODULES_DIR="${ANYKERNEL_DIR}/modules/vendor/lib/modules"
ROOT_DIR="${KERNEL_DIR}/drivers"
KSU_DIR="${KERNEL_DIR}/scripts/tools/root/Kernelsu"
KSU_NEXT_DIR="${KERNEL_DIR}/scripts/tools/root/Kernelsu-next"
SUKISU_DIR="${KERNEL_DIR}/scripts/tools/root/SukiSU-Ultra"
MKSU_DIR="${KERNEL_DIR}/scripts/tools/root/MKSU"

# 内核目录
cd "${KERNEL_DIR}"

# 内核配置
DEFCONFIG="odin_defconfig"

# 文件名称
if [ -d ".git" ]; then
GIT_COMMIT_HASH=$(git rev-parse --short=7 HEAD)
ZIP_NAME="MIX4-5.4.289-g${GIT_COMMIT_HASH}.zip"
else
CURRENT_TIME=$(date '+%Y%m%d%H%M')
ZIP_NAME="MIX4-5.4.289-${CURRENT_TIME}.zip"
fi

# 安装依赖
install() {
    dependencies=(git ccache automake flex lzop bison gperf build-essential zip curl zlib1g-dev zlib1g-dev:i386 g++-multilib python-networkx libxml2-utils bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev squashfs-tools pngcrush schedtool dpkg-dev liblz4-tool make optipng maven libssl-dev pwgen libswitch-perl policycoreutils minicom libxml-sax-base-perl libxml-simple-perl bc libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev xsltproc unzip openjdk-17-jdk repo)
    missing=0
    for pkg in "${dependencies[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    missing=1
    fi
    done
    if [ "$missing" = '1' ]; then
    sudo apt-get update
    sudo apt-get install -y "${dependencies[@]}"
    fi
}

# 用户邮箱
email() {
    git config --global user.name "ruoqing501"
    git config --global user.email "liangxiaobo501@gmail.com"
}

# 环境变量
path() {
    export KBUILD_BUILD_USER="18201329"
    export KBUILD_BUILD_HOST="qq.com"
#   export KBUILD_BUILD_TIMESTAMP="Sat Apr 4 20:13:14 CST 2025"
    export PATH="${CLANG_DIR}/bin:${GCC64_DIR}/bin:${GCC_DIR}/bin:$PATH"
    args="-j$(nproc) O=out CC=clang ARCH=arm64 SUBARCH=arm64 LD=ld.lld AR=llvm-ar NM=llvm-nm STRIP=llvm-strip OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump READELF=llvm-readelf HOSTCC=clang HOSTCXX=clang++ HOSTAR=llvm-ar HOSTLD=ld.lld CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- LLVM=1 LLVM_IAS=1"
#   args="-j$(nproc) O=out CC=clang ARCH=arm64 HOSTCC=gcc LD=ld.lld CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-android-"

}

# ROOT方式
root() {
    echo "请选择启用哪种 ROOT 方式："
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo "1. Kernelsu-next+susfs"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo "2. Kernelsu+susfs"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo "3. Sukisu-Ultra+susfs"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo "4. Mksu+susfs"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo -n "请输入选项（1/2/3/4）："
    read choice
    rm -rf "${ROOT_DIR}/kernelsu"
    rm -rf "${CURRENT_DIR}/ksuversion"
    KPM=0
    case $choice in
        1)
            cp -r "${KSU_NEXT_DIR}/kernelsu" "${ROOT_DIR}/kernelsu"
            name="Kernelsu-next+susfs"
            ;;
        2)
            cp -r "${KSU_DIR}/kernelsu" "${ROOT_DIR}/kernelsu"
            cp -r "${KSU_DIR}/ksuversion" "${KERNEL_DIR}/ksuversion"
            name="Kernelsu+susfs"
            ;;
        3)
            cp -r "${SUKISU_DIR}/kernelsu" "${ROOT_DIR}/kernelsu"
            name="Sukisu-Ultra+susfs"
            KPM=1
            ;;
        4)
            cp -r "${MKSU_DIR}/kernelsu" "${ROOT_DIR}/kernelsu"
            name="Mksu+susfs"
            ;;
        *)
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo -e "${RED}无效的选项，退出脚本...${NC}"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    exit 1
            ;;
    esac
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo -e "${GREEN}启用选项：$name ${NC}"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
}
    
# 编译内核
build() {
    make ${args} $DEFCONFIG
    make ${args} menuconfig
    make ${args} savedefconfig
    cp out/defconfig arch/arm64/configs/$DEFCONFIG
#   cp out/.config arch/arm64/configs/$DEFCONFIG
    START_TIME=$(date +%s)
    if ! make ${args} 2>&1 | tee "${CURRENT_DIR}/kernel.log"; then
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo -e "${RED}编译失败，请检查代码后重试...${NC}"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    exit 1
    fi
}

# 打包内核
package() {
    if grep -q '=m' "${KERNEL_DIR}/out/.config"; then
    make ${args} INSTALL_MOD_PATH=modules INSTALL_MOD_STRIP=1 modules_install
    cd "${ANYKERNEL_DIR}"
    cp $(find "${KERNEL_DIR}/out/modules/lib/modules/5.4*" -name '*.ko') "${MODULES_DIR}"
    cp "${KERNEL_DIR}/out/modules/lib/modules/5.4"/modules.{alias,dep,softdep} "${MODULES_DIR}"
    cp "${KERNEL_DIR}/out/modules/lib/modules/5.4"/modules.order "${MODULES_DIR}/modules.load"
    sed -i 's/ $kernel\/[^: ]*\/$  $[^: ]*\.ko$ /\/vendor\/lib\/modules\/\2/g' "${MODULES_DIR}/modules.dep"
    sed -i 's/.*\///g' "${MODULES_DIR}/modules.load"
    sed -i 's/do.modules=0/do.modules=1/g' anykernel.sh
    cd "${KERNEL_DIR}"
    fi
    cd "${ANYKERNEL_DIR}"
    cp "${IMAGE_DIR}" "${ANYKERNEL_DIR}/Image"
    if [ "$KPM" = '1' ]; then
    cp "${SUKISU_DIR}/patch_linux" "${ANYKERNEL_DIR}/patch_linux"
    ./patch_linux
    mv -f oImage Image
    rm -rf "${ANYKERNEL_DIR}"/patch_linux
    fi
    zip -r9 "${ZIP_NAME}" *
    mv "${ZIP_NAME}" "${CURRENT_DIR}"
    END_TIME=$(date +%s)
    COST_TIME=$((END_TIME - START_TIME))
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo -e "${GREEN}编译完成...${NC}"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo -e "${GREEN}总共用时： $((COST_TIME / 60))分$((COST_TIME % 60))秒${NC}"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo -e "${YELLOW}内核文件: ${CURRENT_DIR}/${ZIP_NAME}${NC}"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
}

# 清理环境
clean() {
    rm -rf "${ANYKERNEL_DIR}"/Image
    rm -rf "${MODULES_DIR}"/*
    rm -rf "${KERNEL_DIR}"/ksuversion
#   rm -rf "${KERNEL_DIR}"/out
}

# 主程序
main() {
    install
    email
    path
    root
    build
    package
    clean
}

main
