#!/bin/sh
set -eu
echo '=== Adding APT repositories ==='
wget -O "/tmp/${NVIDIA_PKG}" http://us.download.nvidia.com/tesla/415.25/${NVIDIA_PKG}
dpkg -i "/tmp/${NVIDIA_PKG}"
apt-key add /var/nvidia-diag-driver-local-repo-415.25/7fa2af80.pub
rm -f "/tmp/${NVIDIA_PKG}"

wget -O "/tmp/${CUDA_PKG}" "${NVIDIA_REPO}/${CUDA_PKG}"
dpkg -i "/tmp/${CUDA_PKG}"
apt-key adv --fetch-keys ${NVIDIA_REPO}/7fa2af80.pub
rm -f "/tmp/${CUDA_PKG}"
sudo apt update
sudo apt upgrade -y
echo '=== Installing Nvidia driver ==='
sudo apt install -y nvidia-driver-415
echo '=== Installing CUDA drivers ==='
sudo apt install -y cuda-drivers
echo '=== Installing GUI ==='
sudo apt install -y kubuntu-desktop xrdp
sed -e 's/^new_cursors=true/new_cursors=false/g' -i /etc/xrdp/xrdp.ini
sudo systemctl enable xrdp
echo '=== Installing VTD dependencies ==='
sudo apt install -y xterm freeglut3 openssh-server nfs-common mesa-utils xfonts-75dpi libusb-0.1-4
sudo apt install -y libqtgui4 libqt4-dev libgsm1 libpulse0 libcrystalhd3 libmpg123-0 libdvdread4 libxvidcore4 libaa1 libfaad2 libxss1 libopencore-amrnb0 libopencore-amrwb0 libspeex1 libjack-jackd2-0 libdv4 libdca0 libtheora0 libxvmc1 libbs2b0 libmp3lame0 libmad0 liblircclient0 libsmbclient libsdl1.2debian libtwolame0 libenca0
echo '=== Installing Azure CLI ==='
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
echo '=== Installing Conan ==='
sudo apt install -y python3-pip
sudo pip3 install conan

sudo mkdir /opt/conan
sudo chmod a+w /opt/conan

export CONAN_USER_HOME=/opt/conan
sudo -E conan config install /tmp/conan_config
sudo -E conan config set storage.path=/opt/conan
sudo -E conan user "${USER_DEVSTACK}" -r adapmt7c -p "${PASS_DEVSTACK}"
echo '=== Generating environment ==='
sudo -E conan install "MT7cToolchain/${VERSION_TOOLCHAIN}@adapmt7c/testing" -g virtualenv -r adapmt7c
export ORIG_PATH=$(cut -d '=' -f2 /etc/environment)
sudo sed -e '/CONAN_OLD/d' -e '/ADS2LICENSE=/d' -e "s%\${PATH+:\$PATH}%${ORIG_PATH+:$ORIG_PATH}%" -e "s%\${LD_LIBRARY_PATH+:\$LD_LIBRARY_PATH}%${LD_LIBARY_PATH+:$LD_LIBRARY_PATH}%" -e 's/"//g' environment.sh.env > /etc/environment
sudo echo 'CONAN_USER_HOME=/opt/conan' >> /etc/environment
cat /etc/environment
rm -rf /tmp/conan_config
/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync
