#!/bin/bash

# --- Configuration ---
KUBE_VERSION="1.29" # Specify a stable Kubernetes version prefix (e.g., 1.28, 1.29)
# ---------------------

DOCKER_INSTALL=false
K8S_INSTALL=false

# Function to display script usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "A script to install Docker and/or Kubernetes components on Ubuntu."
    echo ""
    echo "Options:"
    echo "  --docker       Install Docker Engine, CLI, and Containerd."
    echo "  --k8s          Install Kubernetes tools (kubeadm, kubelet, kubectl)."
    echo "  -h, --help     Display this help message."
    echo ""
    echo "Example: $0 --docker --k8s"
    exit 1
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --docker)
            DOCKER_INSTALL=true
            ;;
        --k8s)
            K8S_INSTALL=true
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Error: Unknown option '$1'"
            usage
            ;;
    esac
    shift
done

# Check if any installation flag was provided
if ! $DOCKER_INSTALL && ! $K8S_INSTALL; then
    echo "Error: You must specify at least one installation flag (--docker or --k8s)."
    usage
fi

# --- Main Installation Logic ---

echo "Updating system packages..."
sudo apt update -y

# ---------------------------------------------
# 🐳 Docker Installation Function
# ---------------------------------------------
install_docker() {
    echo "--- Starting Docker Installation ---"
    
    # Install prerequisite packages
    sudo apt install -y ca-certificates curl gnupg

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Set up the stable repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update the package index again
    sudo apt update -y

    # Install Docker Engine, CLI, and Containerd
    echo "Installing docker-ce, docker-ce-cli, and containerd.io..."
    sudo apt install -y docker-ce docker-ce-cli containerd.io

    # Post-installation: Add user to the docker group (requires logout/login)
    echo "Adding user ${USER} to the docker group."
    sudo usermod -aG docker "$USER"

    echo "--- Docker Installation Complete (User must log out and back in to use 'docker' without 'sudo') ---"
    echo "Verification: sudo docker run hello-world"
}

# ---------------------------------------------
# ☸️ Kubernetes Installation Function
# ---------------------------------------------
install_kubernetes() {
    echo "--- Starting Kubernetes Installation ---"
    
    # Load required kernel modules (for Cgroups)
    echo "Loading required kernel modules..."
    sudo modprobe overlay
    sudo modprobe br_netfilter

    # Configure networking parameters for Kubernetes
    sudo tee /etc/sysctl.d/k8s.conf > /dev/null <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
    sudo sysctl --system

    # Install prerequisite packages
    sudo apt install -y apt-transport-https ca-certificates curl

    # Add Kubernetes official GPG key
    echo "Adding Kubernetes GPG key and repository..."
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBE_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    
    # Add Kubernetes repository
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$KUBE_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

    # Update package index and install K8s components
    sudo apt update -y
    
    echo "Installing kubeadm, kubelet, and kubectl..."
    sudo apt install -y kubelet kubeadm kubectl
    
    # Prevent automatic updates for K8s components
    sudo apt-mark hold kubelet kubeadm kubectl

    echo "--- Kubernetes Installation Complete ---"
    echo "Components installed: kubeadm, kubelet, kubectl"
    echo "Verification: kubectl version --client"
    echo "Note: You still need to initialize the cluster with 'sudo kubeadm init'."
}

# Execute installations based on flags
if $DOCKER_INSTALL; then
    install_docker
fi

if $K8S_INSTALL; then
    install_kubernetes
fi

echo "All requested installations finished."