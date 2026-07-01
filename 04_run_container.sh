#!/bin/bash
set -e

CONTAINER_NAME="Llama.cpp-VULKAN-INTEL"
IMAGE_NAME="llama-cpp-vulkan-intel:latest"

echo "========================================================================="
echo "STEP 4: Launching Runtime Stack with Host Hardware Integration"
echo "========================================================================="

# Clean any existing container instance to enable clean redeployments
if [ "$(docker ps -aq -f name=^${CONTAINER_NAME}$)" ]; then
    echo "[*] Legacy instance discovered. Evicting container: ${CONTAINER_NAME}"
    docker rm -f "${CONTAINER_NAME}"
fi

echo "[*] Spawning production engine instance..."

docker run \
  --name=Llama.cpp-VULKAN-INTEL \
  --hostname=71d7ef3cc4f5 \
  --mac-address=7e:5a:cf:70:85:3b \
  --volume /data/Llama.cpp/models:/models:ro \
  --env=SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS=1 \
  --env=UR_L0_ENABLE_RELAXED_ALLOCATION_LIMITS=1 \
  --env=ZES_ENABLE_SYSMAN=1 \
  --env=GGML_SYCL_DISABLE_OPT=1 \
  --env=GGML_SYCL_FORCE_MMQ=1 \
  --env=ONEAPI_DEVICE_SELECTOR=level_zero:gpu \
  --env=GGML_VULKAN_DEVICE=0 \
  --cap-add=CAP_AUDIT_WRITE \
  --cap-add=CAP_CHOWN \
  --cap-add=CAP_DAC_OVERRIDE \
  --cap-add=CAP_FOWNER \
  --cap-add=CAP_FSETID \
  --cap-add=CAP_KILL \
  --cap-add=CAP_MKNOD \
  --cap-add=CAP_NET_BIND_SERVICE \
  --cap-add=CAP_NET_RAW \
  --cap-add=CAP_SETFCAP \
  --cap-add=CAP_SETGID \
  --cap-add=CAP_SETPCAP \
  --cap-add=CAP_SETUID \
  --cap-add=CAP_SYS_CHROOT \
  --cap-drop=CAP_AUDIT_CONTROL \
  --cap-drop=CAP_BLOCK_SUSPEND \
  --cap-drop=CAP_DAC_READ_SEARCH \
  --cap-drop=CAP_IPC_LOCK \
  --cap-drop=CAP_IPC_OWNER \
  --cap-drop=CAP_LEASE \
  --cap-drop=CAP_LINUX_IMMUTABLE \
  --cap-drop=CAP_MAC_ADMIN \
  --cap-drop=CAP_MAC_OVERRIDE \
  --cap-drop=CAP_NET_ADMIN \
  --cap-drop=CAP_NET_BROADCAST \
  --cap-drop=CAP_SYSLOG \
  --cap-drop=CAP_SYS_ADMIN \
  --cap-drop=CAP_SYS_BOOT \
  --cap-drop=CAP_SYS_MODULE \
  --cap-drop=CAP_SYS_NICE \
  --cap-drop=CAP_SYS_PACCT \
  --cap-drop=CAP_SYS_PTRACE \
  --cap-drop=CAP_SYS_RAWIO \
  --cap-drop=CAP_SYS_RESOURCE \
  --cap-drop=CAP_SYS_TIME \
  --cap-drop=CAP_SYS_TTY_CONFIG \
  --cap-drop=CAP_WAKE_ALARM \
  --network=bridge \
  --workdir=/app \
  -p 8080:8080 \
  --restart=always \
  --device /dev/dri/card1:/dev/dri/card1 \
  --device /dev/dri/renderD128:/dev/dri/renderD128 \
  --runtime=runc \
  --detach=true \
  "${IMAGE_NAME}" \
  --models-preset /models/presets.ini \
  --models-max 1 \
  --host 0.0.0.0 \
  --port 8080

echo "------------------------------------------------------------------------"
echo " Target successfully spun up!"
echo " Check execution logs via: docker logs -f ${CONTAINER_NAME}"
echo "------------------------------------------------------------------------"