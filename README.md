
# 🛠️ Linux System Setup Script

This script, `install_tools.sh`, provides a convenient, single-file method for installing essential containerization and orchestration tools—**Docker** and **Kubernetes** components—on Ubuntu/Debian-based Linux systems.

---

## 🚀 Usage

The script uses command-line flags to determine which tools to install.

### 1. Make the Script Executable

Before running, ensure the script has execution permissions:

```bash
chmod +x install_tools.sh
```

### 2. Run the Script with Flags

You must specify at least one flag:

| Command | Description |
|---------|-------------|
| `./install_tools.sh --docker` | Installs Docker Engine, Docker CLI, and Containerd. |
| `./install_tools.sh --k8s` | Installs Kubernetes core tools: kubeadm, kubelet, and kubectl. |
| `./install_tools.sh --docker --k8s` | Installs both Docker and Kubernetes components. |
| `./install_tools.sh --help` | Displays the usage information. |

---

## ⚙️ Configuration

The Kubernetes installation uses a specific version prefix defined inside the script.

### Kubernetes Version

To adjust the Kubernetes version that will be installed, you can edit the variable at the top of the `install_tools.sh` file:

```bash
# --- Configuration ---
KUBE_VERSION="1.29" # <-- Edit this value (e.g., change to "1.28")
# ---------------------
```

**Note:** The script installs the stable version of Kubernetes available under that prefix.

---

## ✅ Post-Installation Steps

### 🐳 Docker

1. **Re-log or Reboot:** After Docker installation, you must log out and log back in (or reboot your machine) for the changes to the user group (docker group) to take effect. This allows you to run `docker` commands without `sudo`.

2. **Verify:**
   ```bash
   docker run hello-world
   ```

### ☸️ Kubernetes

1. **Verify:**
   ```bash
   kubectl version --client
   ```

2. **Initialize Cluster (Control Plane only):** To start a new Kubernetes cluster, run `kubeadm init`.
   ```bash
   sudo kubeadm init --pod-network-cidr=10.244.0.0/16 # Using Flannel CIDR as example
   ```

3. **Set up Kubeconfig:** After `kubeadm init`, execute the following commands (as shown in the kubeadm output) to allow your non-root user to manage the cluster:
   ```bash
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```


