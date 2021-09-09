# Nvidia GPU node on a Kubernetes cluster

This repository aims to configure and add an Nvidia GPU node to an existing Kubernetes cluster using [Kubespray](https://github.com/kubernetes-sigs/kubespray).

In order to facilitate the installation of the necessary drivers and configurations, two scripts are provided.
* [`install_nvidia_drivers.sh`](https://github.com/jaime-cespedes-sisniega/k8s-gpu-node/blob/main/scripts/install_nvidia_drivers.sh) which uses [Option 1 (recommended)](#option-1-(recommended)).
* [`install_nvidia_docker.sh`](https://github.com/jaime-cespedes-sisniega/k8s-gpu-node/blob/main/scripts/install_nvidia_docker.sh) which [Install Nvidia Docker](#install-nvidia-docker).
> **_NOTE:_**  Make the scrips executable with the command `chmod +x <script-name>.sh`.


The following steps have being tested on `Ubuntu LTS - 20.4` and using an `Nvidia Tesla V100-PCIE-32GB`.

## Install Nvidia Drivers

### Option 1 (recommended)

The most straightforward way of install the latest Nvidia drivers it´s by using `ubuntu-drivers-common`.

```bash
$ sudo apt install ubuntu-drivers-common -y \
  && sudo ubuntu-drivers install
```
### Option 2 (specific version)

If you want to install a specific version, you can use the following command by specifying the version.

```bash
$ sudo apt install nvidia-driver-<VERSION> -y
```

Regardless of the installation method, a reboot is required.

```bash
$ sudo reboot
```

## Install Nvidia Docker

> **_WARNING:_**  Docker and containerd.io versions must match with the existing versions of Kubernetes nodes. The configuration of those versions is out of the scope of this repository. For more information: [Upgrading in Kubespray](https://github.com/kubernetes-sigs/kubespray/blob/master/docs/upgrades.md).

Install Docker-CE. More information on [Docker installation methods](https://docs.docker.com/engine/install/ubuntu/#installation-methods).
```bash
$ curl https://get.docker.com | sh \
  && sudo systemctl --now enable docker
```

Add the package repositories according to the distribution.
```bash
$ distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
   && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - \
   && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
```

Install `nvidia-docker2`.
```bash
$ sudo apt-get update \
   && sudo apt-get install -y nvidia-docker2
```

Restart Docker daemon.
```bash
$ sudo systemctl restart docker
```

Nvidia runtime must be enabled as the default runtime by editing `/etc/docker/daemon.json`.
```json
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
```

Remove Docker files to avoid conflicts with Kubespray.
```bash
$ sudo rm /usr/share/keyrings/docker-archive-keyring.gpg \
  /etc/apt/sources.list.d/docker.list
```

## Adding Nvidia GPU node
> **_NOTE:_**  It is assumed that an existing Kubernetes cluster was created with Kubespray. For more information: [Quick Start in Kubespray](https://github.com/kubernetes-sigs/kubespray#quick-start).

In order to add the node using Kubespray, `inventory/<cluster-name>/hosts.yaml` must be edited with the configuration of the node. More information can be found in [Adding/replacing a node](https://github.com/kubernetes-sigs/kubespray/blob/master/docs/nodes.md#addingreplacing-a-node).

Scale the cluster with the new configuration.
```bash
$ ansible-playbook -i inventory/<cluster-name>/hosts.yaml --user <user> --become --become-user=root scale.yml
```

Once the node has been successfully added to the cluster, GPU support can be enable by deploying the `nvidia-device-plugin`.
```bash
$ kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.9.0/nvidia-device-plugin.yml
```

Finally, pods that need to make use of GPUs will be scheduled on nodes with resources of type `nvidia.com/gpu`. 
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cuda-vector-add
spec:
  restartPolicy: OnFailure
  containers:
    - name: cuda-vector-add
      # https://github.com/kubernetes/kubernetes/blob/v1.7.11/test/images/nvidia-cuda/Dockerfile
      image: "k8s.gcr.io/cuda-vector-add:v0.1"
      resources:
        limits:
          nvidia.com/gpu: 1 # requesting 1 GPU
```

### Labeling node (optional)

Node can be labeled to schedule desired pods. More information: [Assign Pods to Nodes](https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes/).
```bash
$ kubectl label nodes <node-with-gpu> accelerator=<nvidia-gpu-type>
```

## Removing Nvidia GPU node
> **_WARNING:_**  Using Kubespray does not completely remove the GPU node. It marks the node as unschedulable, but does not remove it.

The easiest way to remove a node is to drain it first and then delete it.

```bash
$ kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

```bash
$ kubectl delete node <node-name>
```

From the GPU node, kudeadm must be reset.
```bash
$ sudo kubeadm reset
```

Remove node configuration from `inventory/<cluster-name>/hosts.yaml`.

## Additional resources

* https://github.com/NVIDIA/k8s-device-plugin#preparing-your-gpu-nodes

* https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/#deploying-nvidia-gpu-device-plugin

* https://docs.nvidia.com/datacenter/cloud-native/kubernetes/install-k8s.html

* https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#docker