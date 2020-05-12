#!/bin/bash
#
#  Perparing the linux system for  operating
#  simulation VTD components
#
#   Usage: sudo ./setup_linux_refactor.sh
#
#
# === Break on the first Error ===
set -euo pipefail

if [ "${DEBUG}" ]; then
    set -o xtrace # Similar to -v, but expands commands, same as "set -x"
fi

# === Global vars we need for conan to run ===
export CONAN_USER_HOME=/opt/conan
export ORIG_PATH=$(cut -d '=' -f2 /etc/environment)

# === Cleanup actions ===
function finish() {
    sudo /usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync
    rm -rf "$TMP_DIR"
}
# === Enforce clean-up on any circumstances ===
trap finish EXIT

# === Installing Packages ===
install_system_packages() {
    sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${PACKAGES[@]}"
}

# === Adding NVIDIA APT repositories ===
install_nvidia_repos() {
    wget -O "${TMP_DIR}/${NVIDIA_PKG}" http://us.download.nvidia.com/tesla/415.25/${NVIDIA_PKG}
    sudo dpkg -i "${TMP_DIR}/${NVIDIA_PKG}"
    sudo apt-key add /var/nvidia-diag-driver-local-repo-415.25/7fa2af80.pub
}

# === Adding NVIDIA CUDA repositories ===
install_cuda_repos() {
    wget -O "${TMP_DIR}/${CUDA_PKG}" "${NVIDIA_REPO}/${CUDA_PKG}"
    sudo dpkg -i "${TMP_DIR}/${CUDA_PKG}"
    sudo apt-key adv --fetch-keys ${NVIDIA_REPO}/7fa2af80.pub
}

# === Installing Nvidia driver ===
install_nvidia_drivers() {
    sudo apt install -y nvidia-driver-415
    # Installing CUDA drivers. Must be resolved in a separate step because cuda-drivers cannot properly resolve the dependency to the display drivers.
    sudo apt install -y cuda-drivers
}

# === Configure xrdp environment ===
setup_xrdp() {
    sudo sed -e 's/^new_cursors=true/new_cursors=false/g' -i /etc/xrdp/xrdp.ini
    sudo systemctl enable xrdp
}

# === Installing Conan ===
setup_conan() {
    sudo pip3 install conan
    sudo mkdir "${CONAN_USER_HOME}"
    sudo chmod -R a+w "${CONAN_USER_HOME}"
    conan config install /tmp/conan_config # Packer creates /tmp/conan_config
    conan config set storage.path="${CONAN_USER_HOME}"
    conan user "${USER_DEVSTACK}" -r adapmt7c -p "${PASS_DEVSTACK}"

}

# === Installing VTD Procudure ===
install_vtd() {
    setup_conan
    conan install "${VERSION_TOOLCHAIN}" -g virtualenv -r adapmt7c
    sed \
        -e '/CONAN_OLD/d' \
        -e '/ADS2LICENSE=/d' \
        -e "s%\${PATH+:\$PATH}%${ORIG_PATH+:$ORIG_PATH}%" \
        -e "s%\${LD_LIBRARY_PATH+:\$LD_LIBRARY_PATH}%${LD_LIBARY_PATH+:$LD_LIBRARY_PATH}%" \
        -e 's/"//g' \
        -e '$CONAN_USER_HOME=/opt/conan' environment.sh.env | sudo tee /etc/environment
}

# === MAIN PROCEDURE ===
run_main() {
    declare -ra required_env_vars=(
        "${USER_DEVSTACK}"
        "${PASS_DEVSTACK}"
        "${VERSION_TOOLCHAIN}"
        "${LD_LIBRARY_PATH}"
        "${NVIDIA_PKG}"
        "${CUDA_PKG}"
        "${NVIDIA_REPO}"
    )
    for var in "${required_env_vars[@]}"; do
        if [ -z "${var}" ]; then
            var_name=(${!var@})
            "Empty required env var found: $var_name. ABORT"
            exit 1
        fi
    done

    local -r enable_nvidia="true"
    declare -ar PACKAGES=(
        wget curl
        # Install GUI
        kde-plasma-desktop xrdp
        # VTD dependencies
        xterm freeglut3 openssh-server nfs-common mesa-utils xfonts-75dpi libusb-0.1-4
        libqtgui4 libqt4-dev libgsm1 libpulse0 libcrystalhd3 libmpg123-0 libdvdread4
        libxvidcore4 libaa1 libfaad2 libxss1 libopencore-amrnb0 libopencore-amrwb0
        libspeex1 libjack-jackd2-0 libdv4 libdca0 libtheora0 libxvmc1 libbs2b0 libmp3lame0
        libmad0 liblircclient0 libsmbclient libsdl1.2debian libtwolame0 libenca0
        # Conan needs pip
        python3-pip
    )
    declare -r TMP_DIR=$(mktemp -d -t tmp.XXXXXXXXXX || exit 1)

    install_nvidia_repos
    install_cuda_repos
    install_system_packages
    if [ $enable_nvidia ]; then
        install_nvidia_drivers
    fi
    setup_xrdp
    install_vtd
}

#  Be able to run this one either as standalone or import as lib
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_main
fi
