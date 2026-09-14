#!/usr/bin/env bash
# rsync code up to the RunPod box, or checkpoints back down.
#
#   scripts/sync_runpod.sh push    # laptop -> pod  (code only)
#   scripts/sync_runpod.sh pull    # pod -> laptop  (checkpoints only)
#
# Configure once in ~/.zshrc:
#   export RUNPOD_HOST=root@213.x.x.x
#   export RUNPOD_PORT=22
#   export RUNPOD_DIR=/workspace/bestiary

set -euo pipefail

HOST="${RUNPOD_HOST:-}"
PORT="${RUNPOD_PORT:-22}"
REMOTE_DIR="${RUNPOD_DIR:-/workspace/bestiary}"
LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -z "$HOST" ]]; then
  echo "RUNPOD_HOST is not set. Example: export RUNPOD_HOST=root@213.1.2.3" >&2
  exit 1
fi

SSH="ssh -p ${PORT} -o ConnectTimeout=15 -o ServerAliveInterval=20"

case "${1:-}" in
  push)
    echo "-> pushing code to ${HOST}:${REMOTE_DIR}"
    $SSH "$HOST" "mkdir -p ${REMOTE_DIR}"
    rsync -avz --delete \
      -e "$SSH" \
      --exclude '.git/' \
      --exclude 'checkpoints/' \
      --exclude '.tmp/' \
      --exclude '__pycache__/' \
      --exclude '*.onnx' \
      --exclude '.venv/' \
      --exclude 'wandb/' \
      "${LOCAL_DIR}/" "${HOST}:${REMOTE_DIR}/"
    ;;
  pull)
    echo "<- pulling checkpoints from ${HOST}:${REMOTE_DIR}/checkpoints"
    mkdir -p "${LOCAL_DIR}/checkpoints"
    rsync -avz \
      -e "$SSH" \
      "${HOST}:${REMOTE_DIR}/checkpoints/" "${LOCAL_DIR}/checkpoints/"
    ;;
  *)
    echo "usage: $0 {push|pull}" >&2
    exit 1
    ;;
esac
