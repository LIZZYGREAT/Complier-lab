#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORT_DIR="$LAB_DIR/report"
LOG_DIR="$LAB_DIR/logs"
TMP_BASE="${TMPDIR:-/tmp}"
WORK_DIR="$(mktemp -d "$TMP_BASE/compiler-labs-latex.XXXXXX")"
OUT_DIR="$WORK_DIR/out"
mkdir -p "$OUT_DIR" "$LOG_DIR"

cleanup() {
    local result=$?
    trap - EXIT
    if [[ -f "$OUT_DIR/report.log" ]]; then
        cp "$OUT_DIR/report.log" "$LOG_DIR/10_latex_compile.log" || result=$?
    fi
    rm -rf "$WORK_DIR"
    exit "$result"
}
trap cleanup EXIT

TECTONIC_BIN="${TECTONIC_BIN:-}"
if [[ -n "$TECTONIC_BIN" ]]; then
    if [[ ! -x "$TECTONIC_BIN" ]]; then
        printf 'ERROR: TECTONIC_BIN is not executable: %s\n' "$TECTONIC_BIN" >&2
        exit 1
    fi
elif command -v tectonic >/dev/null 2>&1; then
    TECTONIC_BIN="$(command -v tectonic)"
else
    if [[ "$(uname -m)" != "x86_64" ]]; then
        printf 'ERROR: no tectonic binary found; automatic temporary download supports x86_64 only.\n' >&2
        exit 1
    fi
    command -v curl >/dev/null 2>&1 || { printf 'ERROR: curl is required to fetch Tectonic.\n' >&2; exit 1; }
    command -v sha256sum >/dev/null 2>&1 || { printf 'ERROR: sha256sum is required to verify Tectonic.\n' >&2; exit 1; }
    TECTONIC_VERSION='0.16.9'
    ARCHIVE="$WORK_DIR/tectonic.tar.gz"
    URL="https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%400.16.9/tectonic-0.16.9-x86_64-unknown-linux-musl.tar.gz"
    EXPECTED_SHA256='60b13a0826ae7ad9ce34b4a2df06bff2cfcfa6dda8a915477c0cbb84e1a4a902'
    printf 'No system Tectonic found; fetching isolated Tectonic %s into %s\n' "$TECTONIC_VERSION" "$WORK_DIR"
    curl --fail --location --show-error --max-time 180 "$URL" -o "$ARCHIVE"
    printf '%s  %s\n' "$EXPECTED_SHA256" "$ARCHIVE" | sha256sum --check --status || {
        printf 'ERROR: Tectonic archive checksum mismatch.\n' >&2
        exit 1
    }
    mkdir -p "$WORK_DIR/bin"
    tar -xzf "$ARCHIVE" -C "$WORK_DIR/bin" tectonic
    TECTONIC_BIN="$WORK_DIR/bin/tectonic"
fi

if [[ -n "${TECTONIC_CACHE_DIR:-}" ]]; then
    mkdir -p "$TECTONIC_CACHE_DIR"
else
    export TECTONIC_CACHE_DIR="$WORK_DIR/cache"
    mkdir -p "$TECTONIC_CACHE_DIR"
fi

printf 'Stage 10: compile report/report.tex to PDF with Tectonic\n'
"$TECTONIC_BIN" --version
"$TECTONIC_BIN" --untrusted --keep-logs --outdir "$OUT_DIR" "$REPORT_DIR/report.tex"
[[ -s "$OUT_DIR/report.pdf" ]] || { printf 'ERROR: LaTeX did not produce report.pdf.\n' >&2; exit 1; }
install -m 0644 "$OUT_DIR/report.pdf" "$REPORT_DIR/report.pdf.tmp"
mv "$REPORT_DIR/report.pdf.tmp" "$REPORT_DIR/report.pdf"

printf '\n[PDF artifact]\n'
file "$REPORT_DIR/report.pdf"
sha256sum "$REPORT_DIR/report.pdf"
printf 'LaTeX source: report/report.tex\n'
printf 'Tectonic cache: %s\n' "$TECTONIC_CACHE_DIR"
printf 'Build-owned temporary download, output, and default-cache files are removed on exit.\n'
printf '\nStage 10 report build: PASS\n'
