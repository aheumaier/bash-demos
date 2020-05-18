#!/usr/bin/env bats
load 'libs/bats-support/load'
load 'libs/bats-assert/load'
load 'test_helper'

profile_script="./setup_linux_refactor.sh"

setup() {
    DOCKER_SUT_ID=$(docker run -itd ubuntu:18.04)
}

function teardown() {
    docker stop $DOCKER_SUT_ID && docker rm $DOCKER_SUT_ID
}

@test "test CONAN_USER_HOME is set" {
    source ${profile_script}
    run echo $CONAN_USER_HOME
    assert_output "/opt/conan"
}

@test "test ORIG_PATH is set" {
    source ${profile_script}
    run echo $ORIG_PATH
    assert_output "\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games\""
}
@test "test install_system_packages() should install provided packes" {
    skip
    source ${profile_script}
    function sudo() { docker_mock "${*}";  }
    export -f sudo 
    declare -ar PACKAGES=( wget curl gnupg2 xrdp libusb-0.1-4 libxvidcore4 libaa1 libfaad2 libxss1 libopencore-amrnb0 libopencore-amrwb0 )
    run install_system_packages
    assert_success

}
@test "test install_nvidia_repos() should install nvidia_repos" {
    NVIDIA_PKG="nvidia-diag-driver-local-repo-ubuntu1804-415.25_1.0-1_amd64.deb"
    NVIDIA_REPO="http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64"
    TMP_DIR="/tmp"
    source ${profile_script}
    function sudo() { docker_mock "${*}";  }
    export -f sudo 
    function wget() { docker_mock "wget" "${*}";  }
    export -f wget
    declare -ar PACKAGES=( wget curl gnupg2 )
    run install_system_packages 
    run install_nvidia_repos
    assert_success

}
@test "test install_cuda_repos() should install cuda_repos" {
    CUDA_PKG="cuda-repo-ubuntu1804_10.0.130-1_amd64.deb"
    NVIDIA_REPO="http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64"
    TMP_DIR="/tmp"
    source ${profile_script}
    function sudo() { docker_mock "${*}";  }
    export -f sudo 
    function wget() { docker_mock "wget" "${*}";  }
    export -f wget
    declare -ar PACKAGES=( wget curl gnupg2 )
    run install_system_packages 
    run install_cuda_repos
    assert_success

}
@test "test run_main should fail on missin env var" {
    NVIDIA_PKG="nvidia-diag-driver-local-repo-ubuntu1804-415.25_1.0-1_amd64.deb"
    NVIDIA_REPO="http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64"
    CUDA_PKG="cuda-repo-ubuntu1804_10.0.130-1_amd64.deb"
    USER_DEVSTACK=$(openssl rand -base64 12)
    unset PASS_DEVSTACK
    source ${profile_script}
    run run_main
    assert_failure 
    assert_output "Empty required env var found: var. ABORT"
}
@test "test run_main should be successfull" {
    source ${profile_script}
    NVIDIA_PKG="nvidia-diag-driver-local-repo-ubuntu1804-415.25_1.0-1_amd64.deb"
    NVIDIA_REPO="http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64"
    CUDA_PKG="cuda-repo-ubuntu1804_10.0.130-1_amd64.deb"
    USER_DEVSTACK=$(openssl rand -base64 12)
    PASS_DEVSTACK=$(openssl rand -base64 12)
    VERSION_TOOLCHAIN=$(openssl rand -base64 12)
    LD_LIBRARY_PATH="/usr/local/lib"
    function install_nvidia_repos() { echo "This would install_nvidia_repos ${*}"; }
    export -f install_nvidia_repos
    function install_cuda_repos() { echo "This would install_cuda_repos ${*}"; }
    export -f install_cuda_repos
    function install_system_packages() { echo "This would install_system_packages ${*}"; }
    export -f install_system_packages
    function install_nvidia_drivers() { echo "This would install_nvidia_drivers ${*}"; }
    export -f install_nvidia_drivers
    function setup_xrdp() { echo "This would setup_xrdp ${*}"; }
    export -f setup_xrdp
    function install_vtd() { echo "This would install_vtd ${*}"; }
    export -f install_vtd
    run run_main
    assert_success
}
