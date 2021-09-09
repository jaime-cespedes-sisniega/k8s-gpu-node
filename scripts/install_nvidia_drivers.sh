#!/usr/bin/env bash

# Install NVIDIA Drivers (install recommended drivers by ubuntu-drivers, usually the latest)
sudo apt install ubuntu-drivers-common -y \
  && sudo ubuntu-drivers install

sudo reboot