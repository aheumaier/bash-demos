#!/bin/bash

DOCKER_SUT_ID="b9b29a0328d5"

docker_mock() {
  local command=$1
  local parameters="${@:2}"
  echo "Calling docker_mock with ${command} ${parameters}"
  docker exec -it $DOCKER_SUT_ID bash -c "${command} ${parameters}"
  return $?
}

function test() {
  function apt-get() {
    echo "Calling apt-get mock with ${@}"
    docker_mock "apt-get" "${@}"
  }
  export -f apt-get
  declare -ar PACKAGES=(
    wget curl xrdp
    # VTD dependencies
    xterm freeglut3 openssh-server nfs-common mesa-utils xfonts-75dpi libusb-0.1-4
    libqtgui4 libqt4-dev libgsm1 libpulse0 libcrystalhd3 libmpg123-0 libdvdread4
    libxvidcore4 libaa1 libfaad2 libxss1 libopencore-amrnb0 libopencore-amrwb0
    libspeex1 libjack-jackd2-0 libdv4 libdca0 libtheora0 libxvmc1 libbs2b0 libmp3lame0
    libmad0 liblircclient0 libsmbclient libsdl1.2debian libtwolame0 libenca0
    # Conan needs pip
    python3-pip
  )

  function sudo() { docker_mock ${*}; }
  export -f sudo

  sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${PACKAGES[@]}"

}
test
