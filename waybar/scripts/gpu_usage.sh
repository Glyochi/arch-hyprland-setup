#!/usr/bin/env bash

set -euo pipefail

DGPU_CARD="card1"
IGPU_CARD="card0"

read_metric() {
  local path="$1"
  if [[ -r "$path" ]]; then
    tr -d '[:space:]' < "$path"
  else
    printf "N/A"
  fi
}

is_int() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

to_mib() {
  local bytes="$1"
  if is_int "$bytes"; then
    printf "%d" $((bytes / 1024 / 1024))
  else
    printf "N/A"
  fi
}

d_busy_raw="$(read_metric "/sys/class/drm/${DGPU_CARD}/device/gpu_busy_percent")"
i_busy_raw="$(read_metric "/sys/class/drm/${IGPU_CARD}/device/gpu_busy_percent")"

d_busy_text="N/A"
i_busy_text="N/A"

if is_int "$d_busy_raw"; then
  d_busy_text="${d_busy_raw}%"
fi

if is_int "$i_busy_raw"; then
  i_busy_text="${i_busy_raw}%"
fi

d_vram_used_raw="$(read_metric "/sys/class/drm/${DGPU_CARD}/device/mem_info_vram_used")"
d_vram_total_raw="$(read_metric "/sys/class/drm/${DGPU_CARD}/device/mem_info_vram_total")"

d_vram_line="VRAM: N/A"
if is_int "$d_vram_used_raw" && is_int "$d_vram_total_raw" && [[ "$d_vram_total_raw" -gt 0 ]]; then
  d_vram_used_mib="$(to_mib "$d_vram_used_raw")"
  d_vram_total_mib="$(to_mib "$d_vram_total_raw")"
  d_vram_pct=$((d_vram_used_raw * 100 / d_vram_total_raw))
  d_vram_line="VRAM: ${d_vram_used_mib} / ${d_vram_total_mib} MiB (${d_vram_pct}%)"
fi

tooltip=$(printf "dGPU (%s): %s\niGPU (%s): %s\n%s" "$DGPU_CARD" "$d_busy_text" "$IGPU_CARD" "$i_busy_text" "$d_vram_line")
text="${d_busy_text}"

python3 - "$text" "$tooltip" <<'PY'
import json
import sys

text = sys.argv[1]
tooltip = sys.argv[2]
print(json.dumps({"text": text, "tooltip": tooltip}))
PY
