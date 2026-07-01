#!/bin/bash
set -e

IMAGE_NAME="llama-cpp-vulkan-intel:latest"
MESA_REF="main"
LLAMA_REF="master"

echo "========================================================================="
echo "STEP 3: Compiling Driver Stack & Engine Binaries via Docker"
echo "========================================================================="

if [ ! -f "Dockerfile" ]; then
    echo "ERROR: Dockerfile not found in current directory!"
    exit 1
fi

echo "[*] Building ${IMAGE_NAME}..."
echo "[*] Tracking Mesa Branch: ${MESA_REF}"
echo "[*] Tracking Llama.cpp Branch: ${LLAMA_REF}"

docker build \
  --build-arg MESA_REF="${MESA_REF}" \
  --build-arg LLAMA_REF="${LLAMA_REF}" \
  -t "${IMAGE_NAME}" .

echo "[*] Image assembly completed successfully."