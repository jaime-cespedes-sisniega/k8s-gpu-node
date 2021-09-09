#!/usr/bin/env bash

# IMPORTANT: Replace with the versions of the nodes in the cluster (sudo docker version)
DOCKER_VERSION=5:20.10.8~3-0~ubuntu-focal
CONTAINERD_VERSION=1.4.6-1

# Set up packages
sudo apt-get update \
  && sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up stable Docker´s repository
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker and containerd specific versions
sudo apt-get update \
  && sudo apt-get install -y \
  docker-ce=$DOCKER_VERSION \
  docker-ce-cli=$DOCKER_VERSION \
  containerd.io=$CONTAINERD_VERSION

# Setting up NVIDIA Docker
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
   && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - \
   && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Install nvidia-docker2
sudo apt-get update \
   && sudo apt-get install -y nvidia-docker2

# Restart Docker daemon
sudo systemctl restart docker

# Set default-runtime to be nvidia
sudo bash -c 'cat << EOF > /etc/docker/daemon.json
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF'

# Remove Docker files to avoid conflicts with Kubespray
sudo rm /usr/share/keyrings/docker-archive-keyring.gpg \
  /etc/apt/sources.list.d/docker.list