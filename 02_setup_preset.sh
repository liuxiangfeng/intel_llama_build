#!/bin/bash
set -e

TARGET_PRESET="/data/Llama.cpp/models/presets.ini"

echo "========================================================================="
echo "STEP 2: Deploying Model Presets Configuration"
echo "========================================================================="

echo "[*] Writing parameters to ${TARGET_PRESET}..."

cat << 'EOF' > "${TARGET_PRESET}"
[*]
n-gpu-layers = 999
flash-attn = off
jinja = 1
n-predict = -1
threads = 1
threads-batch = 1
batch-size = 2048
ubatch-size = 512
timeout = 10800

# # =============================================================================
# # QWEN 3.6 35B MoE (3B actifs) - THINKING - MTP
# # MoE sur SYCL/B70 : flash-attn on + KV cache q8_0
# # temp=1.0 + presence=1.5 : params officiels Qwen3.6-35B-A3B (model card HF)
# # =============================================================================
# [Qwen3.6-35B]
# model = /models/Qwen3.6-35B-MTP/Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf
# alias = qwen36-35b
# ctx-size = 100000
# parallel = 1
# flash-attn = on
# cache-type-k = q8_0
# cache-type-v = q8_0
# spec-type = draft-mtp
# spec-draft-n-max = 3
# temp = 1.0
# top-p = 0.95
# top-k = 20
# min-p = 0.0
# repeat-penalty = 1.0
# presence-penalty = 1.5
# reasoning = on

# =============================================================================
# QWEN 3.6 27B Dense - THINKING - MTP
# Dense sur B70 : flash-attn on + KV cache q8_0
# =============================================================================
[Qwen3.6-27B]
model = /models/Qwen3.6-27B-MTP/Qwen3.6-27B-Q5_K_M.gguf
alias = qwen36-27b
ctx-size = 100000
parallel = 1
flash-attn = on
cache-type-k = q8_0
cache-type-v = q8_0
spec-type = draft-mtp
spec-draft-n-max = 3
temp = 1.0
top-p = 0.95
top-k = 20
min-p = 0.0
repeat-penalty = 1.0
presence-penalty = 1.5
reasoning = on
EOF

echo "[*] Preset configuration verified and written."