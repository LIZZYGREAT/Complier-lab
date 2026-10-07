#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LAB_DIR="$ROOT_DIR/lab"

cd "$LAB_DIR"
printf 'Stage 10: build the final PDF report from report/report.md\n'
python3 scripts/10_render_report.py
printf '\n[PDF artifact]\n'
file report/report.pdf
sha256sum report/report.pdf
printf '\nStage 10 report build: PASS\n'
