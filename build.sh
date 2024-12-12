#!/bin/bash
#
# Enhanced compile script for Xiaomi_kernel_odin
# Copyright (C) 2023-2024 Ruoqing

# 计时器
START_TIME=$(date +%s)

# 文件路径
CURRENT_DIR=$(pwd)
KERNEL_DIR="${CURRENT_DIR}/xiaomi_kernel_odin"
CLANG_DIR="${KERNEL_DIR}/scripts/clang-r383902b1"
ARM64_GCC_DIR="${KERNEL_DIR}/scripts/aarch64-linux-android-4.9"
ARM_GCC_DIR="${KERNEL_DIR}/scripts/arm-linux-androideabi-4.9"
ANYKERNEL_DIR="${KERNEL_DIR}/scripts/AnyKernel3"
IMAGE_DIR="${KERNEL_DIR}/out/arch/arm64/boot/Image"
MODULES_DIR="${ANYKERNEL_DIR}/modules/vendor/lib/modules"

# 内核目录
cd "${KERNEL_DIR}"

# 配置文件
DEFCONFIG="odin_defconfig"

# 文件名称
GIT_COMMIT_HASH=$(git rev-parse --short=12 HEAD)
ZIP_NAME="MIX4-5.4.278-g${GIT_COMMIT_HASH}.zip"

# 字体颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 安装依赖
dependencies() {
    dependencies="git git-lfs ccache automake flex lzop bison gperf build-essential zip curl zlib1g-dev zlib1g-dev:i386 g++-multilib python-networkx libxml2-utils bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev squashfs-tools pngcrush schedtool dpkg-dev liblz4-tool make optipng maven libssl-dev pwgen libswitch-perl policycoreutils minicom libxml-sax-base-perl libxml-simple-perl bc libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev xsltproc unzip openjdk-8-jdk repo"
    missing=0
    for pkg in "${dependencies[@]}"; do
    if ! dpkg -s $pkg >/dev/null 2>&1; then
    missing=1
    fi
    done
    if [ "$missing" = '1' ]; then
    sudo apt-get update
    sudo apt-get install -y "${dependencies[@]}"
    if [ $? -ne 0 ]; then
    exit 1
    fi
    fi
}

# 用户邮箱
configure() {
    git config --global user.name "ruoqing501"
    git config --global user.email "liangxiaobo501@gmail.com"
}

# 环境变量
environment() {
    export KBUILD_BUILD_USER="18201329"
    export KBUILD_BUILD_HOST="qq.com"
    export PATH="${CLANG_DIR}/bin:${ARM64_GCC_DIR}/bin:${ARM_GCC_DIR}/bin:$PATH"
    args="-j$(nproc) O=out CC=clang ARCH=arm64 LD=ld.lld CLANG_TRIPLE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1"
}

# 编译内核
compile() {
    make ${args} "${DEFCONFIG}"
    make ${args} menuconfig
    make ${args} savedefconfig
    cp out/defconfig arch/arm64/configs/odin_defconfig
    make ${args}
    if [ ! -f "${IMAGE_DIR}" ]; then
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo -e "${RED}编译失败...${NC}"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    exit 1
    fi
}

# 打包内核
package() {
    cd "${ANYKERNEL_DIR}"
    cp "${IMAGE_DIR}" "${ANYKERNEL_DIR}/Image"
    if grep -q '=m' "${KERNEL_DIR}/out/.config"; then
    make ${args} INSTALL_MOD_PATH=modules INSTALL_MOD_STRIP=1 modules_install
    cp $(find "${KERNEL_DIR}/out/modules/lib/modules/5.4*" -name '*.ko') "${MODULES_DIR}"
    cp "${KERNEL_DIR}/out/modules/lib/modules/5.4"/modules.{alias,dep,softdep} "${MODULES_DIR}"
    cp "${KERNEL_DIR}/out/modules/lib/modules/5.4"/modules.order "${MODULES_DIR}/modules.load"
    sed -i 's/ $kernel\/[^: ]*\/$  $[^: ]*\.ko$ /\/vendor\/lib\/modules\/\2/g' "${MODULES_DIR}/modules.dep"
    sed -i 's/.*\///g' "${MODULES_DIR}/modules.load"
    sed -i 's/do.modules=0/do.modules=1/g' anykernel.sh
    fi
    zip -r9 "${ZIP_NAME}" *
    mv "${ZIP_NAME}" "${CURRENT_DIR}"
    END_TIME=$(date +%s)
    COST_TIME=$((END_TIME - START_TIME))
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo -e "${GREEN}编译完成...${NC}"
    echo -e "${GREEN}总共用时： $((COST_TIME / 60))分 $((COST_TIME % 60))秒。${NC}"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo -e "${YELLOW}内核文件: ${CURRENT_DIR}/${ZIP_NAME}${NC}"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
}

# 清理环境
clean() {
    rm -rf "${MODULES_DIR}"/*
    rm -rf "${ANYKERNEL_DIR}"/Image
    rm -rf "${KERNEL_DIR}"/out
}

# 主程序
main() {
    dependencies
    configure
    environment
    compile
    package
    clean
}

main
