#!/bin/bash
#
# Enhanced compile script for Xiaomi_kernel_odin
# Copyright (C) 2023-2025 Ruoqing

# 文件路径
CURRENT_DIR=$(pwd)
KERNEL_DIR="${CURRENT_DIR}/xiaomi_kernel_odin"
CLANG_DIR="${KERNEL_DIR}/scripts/clang-r383902b1"
# GCC_DIR="${KERNEL_DIR}/scripts/aarch64-linux-android-4.9"
ANYKERNEL_DIR="${KERNEL_DIR}/scripts/AnyKernel3"
IMAGE_DIR="${KERNEL_DIR}/out/arch/arm64/boot/Image"
MODULES_DIR="${ANYKERNEL_DIR}/modules/vendor/lib/modules"

# 内核目录
cd "${KERNEL_DIR}"

# 配置文件
DEFCONFIG="odin_defconfig"

# 文件名称
if [ -d ".git" ]; then
GIT_COMMIT_HASH=$(git rev-parse --short=7 HEAD)
ZIP_NAME="MIX4-5.4.281-g${GIT_COMMIT_HASH}.zip"
else
CURRENT_TIME=$(date '+%Y-%m%d%H%M')
ZIP_NAME="MIX4-5.4.281-${CURRENT_TIME}.zip"
fi

# 字体颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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
#   export KBUILD_BUILD_TIMESTAMP="Sun Jan 26 20:13:14 CST 2025"
    export PATH="${CLANG_DIR}/bin:$PATH"
#   export PATH="${CLANG_DIR}/bin:${GCC_DIR}/bin:$PATH"
    args="-j$(nproc) O=out CC=clang ARCH=arm64 LD=ld.lld CLANG_TRIPLE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1"
#   args="-j$(nproc) O=out CC=clang ARCH=arm64 HOSTCC=gcc LD=ld.lld CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-android-"

}

# 编译内核
build() {
    make ${args} "${DEFCONFIG}"
    make ${args} menuconfig
    make ${args} savedefconfig
    cp out/defconfig arch/arm64/configs/"${DEFCONFIG}"
    START_TIME=$(date +%s)
    make ${args}
    if [ $? -ne 0 ]; then
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo -e "${RED}编译失败，请检查代码后重试...${NC}"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    clean
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
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo -e "${GREEN}总共用时： $((COST_TIME / 60))分$((COST_TIME % 60))秒${NC}"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo -e "${YELLOW}内核文件: ${CURRENT_DIR}/${ZIP_NAME}${NC}"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
}

# 清理环境
clean() {
    rm -rf "${ANYKERNEL_DIR}"/Image
    rm -rf "${KERNEL_DIR}"/out
}

# 主程序
main() {
    install
    email
    path
    build
    package
    clean
}

main
