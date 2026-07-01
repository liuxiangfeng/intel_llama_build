#!/bin/bash
set -e

echo "========================================================================="
echo "STEP 1: Preparing Host Environment & Creating Dockerfile"
echo "========================================================================="

# 1. Update Host Packages
echo "[*] Updating host package repositories..."
sudo apt-get update && sudo apt-get upgrade -y

# 2. Install Essential Host Utilities
echo "[*] Installing prerequisite system utilities..."
sudo apt-get install -y ca-certificates curl gnupg lsb-release git

# 3. Install Docker Engine (if not already present)
if ! command -v docker &> /dev/null; then
    echo "[*] Docker not found. Installing Docker Engine..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
else
    echo "[*] Docker Engine is already installed."
fi

# 4. Configure Group Permissions for GPU Access
echo "[*] Configuring user groups for direct GPU mapping access..."
sudo usermod -aG docker $USER
if getent group render >/dev/null; then
    sudo usermod -aG render $USER
fi
if getent group video >/dev/null; then
    sudo usermod -aG video $USER
fi

# 5. Create Target Deployment Workspace
echo "[*] Building local directory structures for GGUF models..."
sudo mkdir -p /data/Llama.cpp/models/Qwen3.6-35B-MTP
sudo mkdir -p /data/Llama.cpp/models/Qwen3.6-27B-MTP
sudo chown -R $USER:$USER /data/Llama.cpp

# 6. Generate the Multi-Stage Dockerfile inline
echo "[*] Generating Dockerfile in the current directory..."
cat << 'EOF' > Dockerfile
# syntax=docker/dockerfile:1.7
############################################################
# Stage 1 — Compilation de Mesa (driver Vulkan Intel)
# pour récupérer VK_NV_cooperative_matrix2
############################################################
FROM ubuntu:26.04 AS mesa-builder
ENV DEBIAN_FRONTEND=noninteractive
ARG MESA_REF=main
RUN apt-get update && apt-get install -y --no-install-recommends \
git ca-certificates \
build-essential meson ninja-build pkg-config \
python-is-python3 python3-mako \
glslang-tools spirv-tools-dev spirv-headers \
libclc-21-dev libllvmspirvlib-21-dev llvm-dev clang libclang-dev \
libdrm-dev \
libwayland-dev libwayland-client0 wayland-protocols \
libxcb1-dev libxcb-randr0-dev libx11-xcb-dev libxcb-dri3-dev \
libxcb-present-dev libxcb-shm0-dev libxshmfence-dev libxrandr-dev \
&& rm -rf /var/lib/apt/lists/*
WORKDIR /opt/src
RUN git clone --depth=1 https://gitlab.freedesktop.org/mesa/mesa.git \
&& cd mesa && git checkout "${MESA_REF}"
WORKDIR /opt/src/mesa
RUN meson setup builddir/ \
-Dbuildtype=release \
-Dgallium-drivers=[] \
-Dvulkan-drivers=intel \
-Dopengl=false \
-Dglx=disabled \
-Degl=disabled \
-Dgbm=disabled \
-Dgles1=disabled \
-Dgles2=disabled \
&& meson compile -C builddir/

############################################################
# Stage 2 — Compilation de llama.cpp avec backend Vulkan
############################################################
FROM ubuntu:26.04 AS llama-builder
ENV DEBIAN_FRONTEND=noninteractive
ARG LLAMA_REF=master
RUN apt-get update && apt-get install -y --no-install-recommends \
git ca-certificates \
build-essential cmake \
libvulkan-dev glslc spirv-headers \
&& rm -rf /var/lib/apt/lists/*
WORKDIR /opt/src
RUN git clone --depth=1 https://github.com/ggml-org/llama.cpp \
&& cd llama.cpp && git checkout "${LLAMA_REF}"
WORKDIR /opt/src/llama.cpp
RUN cmake -B build -DGGML_VULKAN=1 -DCMAKE_BUILD_TYPE=Release \
&& cmake --build build --config Release -j"$(nproc)"

############################################################
# Stage 3 — Image finale (runtime uniquement)
############################################################
FROM ubuntu:26.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
ca-certificates \
libvulkan1 mesa-vulkan-drivers vulkan-tools \
libdrm2 \
libwayland-client0 \
libxcb1 libxcb-randr0 libxcb-dri3-0 libxcb-present0 libxcb-shm0 \
libxshmfence1 libxrandr2 \
libgomp1 \
&& rm -rf /var/lib/apt/lists/*

# Driver Vulkan Intel fraîchement compilé (Mesa devel)
COPY --from=mesa-builder \
/opt/src/mesa/builddir/src/intel/vulkan/libvulkan_intel.so \
/lib/x86_64-linux-gnu/libvulkan_intel.so

# Binaires + libs
RUN mkdir -p /app
COPY --from=llama-builder /opt/src/llama.cpp/build/bin/ /app/
ENV LD_LIBRARY_PATH=/app
WORKDIR /app

VOLUME ["/models"]
EXPOSE 8080
ENTRYPOINT ["/app/llama-server"]
CMD ["--host", "0.0.0.0", "--port", "8080"]
EOF

echo "------------------------------------------------------------------------"
echo " Host preparation and Dockerfile generation complete!"
echo " IMPORTANT: If Docker was just installed, please log out and log back in"
echo " (or run 'newgrp docker') to apply your GPU group privileges."
echo "------------------------------------------------------------------------"