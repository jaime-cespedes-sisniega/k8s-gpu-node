#!/usr/bin/env bash

# Install Docker
curl https://get.docker.com | sh \
  && sudo systemctl --now enable docker

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

# Remove Docker files to avoid possible conflicts with Kubespray
sudo rm /usr/share/keyrings/docker-archive-keyring.gpg \
  /etc/apt/sources.list.d/docker.list