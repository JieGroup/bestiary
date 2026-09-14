#!/usr/bin/env bash
# Run the MuJoCo passive viewer on a policy.
# macOS needs mjpython, not python. Linux uses plain python.
#
#   scripts/view.sh checkpoints/2026_09_14_120000_10000000.onnx
#   scripts/view.sh BEST_WALK_ONNX_2.onnx --standing

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <policy.onnx> [extra args passed to mujoco_infer.py]" >&2
  exit 1
fi

POLICY="$1"; shift

if [[ ! -f "$POLICY" ]]; then
  echo "no such policy: $POLICY" >&2
  exit 1
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  PYVIEW=mjpython
else
  PYVIEW=python
fi

cd "$(dirname "${BASH_SOURCE[0]}")/.."
exec uv run "$PYVIEW" playground/open_duck_mini_v2/mujoco_infer.py -o "$POLICY" "$@"
