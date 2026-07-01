#!/bin/bash
set -e

IMAGE_NAME="llama-cpp-vulkan-intel:latest"
MODELS_DIR="/data/Llama.cpp/models"

# Define the models exactly matching your folder structures
MODEL_35B="/models/Qwen3.6-35B-MTP/Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf"
# MODEL_27B="/models/Qwen3.6-27B-MTP/Qwen3.6-27B-Q5_K_M.gguf"
MODEL_27B="/models/Qwen3.6-27B-MTP/Qwen3.6-27B-Q4_K_M.gguf"

echo "========================================================================="
echo "STEP 5: Running llama-bench on Intel Arc B70 (Vulkan)"
echo "========================================================================="

# Helper function to run llama-bench inside a transient container
run_benchmark() {
    local model_path=$1
    local label=$2
    
    echo ""
    echo "------------------------------------------------------------------------"
    echo " Running Performance Benchmarks for: ${label}"
    echo "------------------------------------------------------------------------"
    
    # --rm deletes the container immediately after the benchmark finishes
    docker run --rm \
      --device /dev/dri/card1:/dev/dri/card1 \
      --device /dev/dri/renderD128:/dev/dri/renderD128 \
      --volume /data/Llama.cpp/models:/models:ro \
      --env=GGML_VULKAN_DEVICE=0 \
      --entrypoint /app/llama-bench \
      "${IMAGE_NAME}" \
      -m "${model_path}" \
      -n 128,512 \
      -b 512,2048 \
      -p 512,2048 \
      -ngl 999 \
      -fa 1
}

# -v "${MODELS_DIR}":/models:ro \
# Check if models exist on the host before wasting time initializing the container
if [ ! -f "${MODELS_DIR}/Qwen3.6-35B-MTP/Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf" ]; then
    echo "WARNING: Qwen 3.6 35B model file not found in ${MODELS_DIR}. Skipping..."
else
    run_benchmark "${MODEL_35B}" "Qwen 3.6 35B MoE"
fi

if [ ! -f "${MODELS_DIR}/Qwen3.6-27B-MTP/Qwen3.6-27B-Q4_K_M.gguf" ]; then
    echo "WARNING: Qwen 3.6 27B model file not found in ${MODELS_DIR}. Skipping..."
else
    run_benchmark "${MODEL_27B}" "Qwen 3.6 27B Dense"
fi

echo "========================================================================="
echo "Benchmarking Session Completed."
echo "========================================================================="