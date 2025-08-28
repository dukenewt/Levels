#!/usr/bin/env bash
set -euo pipefail

# Hermetic tools bootstrapper
# - Downloads pinned binaries into tools/bin/<os>-<arch>
# - Supports cross-targeting via TARGET_OS and TARGET_ARCH
# - Adds BusyBox for Linux to provide sh/ls/grep/find in minimal sandboxes

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
TMP_DIR="$ROOT_DIR/tools/.tmp"
mkdir -p "$TMP_DIR"

have() { command -v "$1" >/dev/null 2>&1; }

download() {
  # download <url> <out>
  local url="$1" out="$2"
  if have curl; then
    curl -L --fail --retry 3 --connect-timeout 10 -o "$out" "$url"
  elif have wget; then
    wget -O "$out" "$url"
  elif have python3; then
    python3 - "$url" "$out" <<'PY'
import sys, urllib.request
url, out = sys.argv[1], sys.argv[2]
with urllib.request.urlopen(url) as r, open(out, 'wb') as f:
    f.write(r.read())
PY
  elif have python; then
    python - "$url" "$out" <<'PY'
import sys
try:
    from urllib.request import urlopen
except ImportError:
    from urllib2 import urlopen  # type: ignore
url, out = sys.argv[1], sys.argv[2]
with urlopen(url) as r, open(out, 'wb') as f:
    f.write(r.read())
PY
  else
    echo "No downloader found (curl/wget/python). Please download manually as described in tools/README.md." >&2
    return 9
  fi
}

sha256() {
  # sha256 <file>
  local f="$1"
  if have sha256sum; then
    sha256sum "$f" | awk '{print $1}'
  elif have shasum; then
    shasum -a 256 "$f" | awk '{print $1}'
  elif have openssl; then
    openssl dgst -sha256 "$f" | awk '{print $2}'
  else
    echo ""
  fi
}

require_checksum() {
  local file="$1" expected="$2"
  if [ -z "$expected" ]; then return 0; fi
  local got
  got=$(sha256 "$file") || true
  if [ -n "$got" ] && [ "$got" != "$expected" ]; then
    echo "Checksum mismatch for $file" >&2
    echo " expected: $expected" >&2
    echo " got:      $got" >&2
    return 7
  fi
}

ensure_tar() {
  if have tar; then return 0; fi
  echo "tar not found. Please install tar to extract archives." >&2
  return 8
}

detect_platform() {
  local os arch
  case "${OSTYPE:-}" in
    darwin*) os=macos ;;
    linux*)  os=linux ;;
    *)       os="${OSTYPE:-unknown}" ;;
  esac
  if have uname; then
    case "$(uname -m)" in
      x86_64|amd64) arch=x86_64 ;;
      arm64|aarch64) arch=arm64 ;;
      *) arch="$(uname -m)" ;;
    esac
  else
    arch="unknown"
  fi
  echo "$os:$arch"
}

# Helper installers (use global BIN_DIR set in main)
install_from_tar() {
  local url="$1" sum="$2" bin="$3"
  local tmp="$TMP_DIR/$(basename "$url")"
  download "$url" "$tmp"
  require_checksum "$tmp" "$sum"
  ensure_tar
  local work="$TMP_DIR/unpack-$(date +%s)-$RANDOM"
  mkdir -p "$work"
  tar -xzf "$tmp" -C "$work"
  local found
  found=$(find "$work" -type f -name "$bin" -perm -u+x | head -n1 || true)
  if [ -z "$found" ]; then
    found=$(find "$work" -type f -name "$bin*" -perm -u+x | head -n1 || true)
  fi
  if [ -z "$found" ]; then
    echo "Could not locate $bin in archive $url" >&2
    return 6
  fi
  mkdir -p "$BIN_DIR"
  cp "$found" "$BIN_DIR/$bin"
  chmod 0755 "$BIN_DIR/$bin"
  echo "Installed $bin -> ${BIN_DIR#$ROOT_DIR/}/$bin"
}

install_busybox() {
  # Tries multiple BusyBox URLs; prefers static builds
  local arch_name
  case "$1" in
    x86_64) arch_name=x86_64 ;;
    arm64)  arch_name=aarch64 ;;
    *)      arch_name="$1" ;;
  esac
  local urls=(
    "https://busybox.net/downloads/binaries/1.36.1-defconfig-static/busybox-${arch_name}"
    "https://busybox.net/downloads/binaries/1.36.0-defconfig-static/busybox-${arch_name}"
    "https://busybox.net/downloads/binaries/1.36.1-defconfig-multiarch/busybox-${arch_name}"
  )
  local tmp
  for u in "${urls[@]}"; do
    tmp="$TMP_DIR/$(basename "$u")"
    echo "Attempting BusyBox from: $u"
    if download "$u" "$tmp" 2>/dev/null; then
      cp "$tmp" "$BIN_DIR/busybox"
      chmod 0755 "$BIN_DIR/busybox"
      echo "Installed busybox -> ${BIN_DIR#$ROOT_DIR/}/busybox"
      return 0
    fi
  done
  echo "Could not fetch BusyBox automatically. See tools/README.md for manual install options." >&2
  return 0
}

main() {
  local platform arch
  if [ -n "${TARGET_OS:-}" ] && [ -n "${TARGET_ARCH:-}" ]; then
    platform="$TARGET_OS"
    arch="$TARGET_ARCH"
    echo "Targeting (override): $platform $arch"
  else
    IFS=: read -r platform arch < <(detect_platform)
    echo "Detected platform: $platform $arch"
  fi

  # Pinned versions
  local RG_VER="14.1.1"
  local FD_VER="10.2.0"

  # Choose output directory per target, e.g. tools/bin/linux-arm64
  if [ -n "${OUT_DIR:-}" ]; then
    BIN_DIR="$OUT_DIR"
  else
    BIN_DIR="$ROOT_DIR/tools/bin/${platform}-${arch}"
  fi
  mkdir -p "$BIN_DIR"

  case "$platform:$arch" in
    macos:x86_64)
      install_from_tar \
        "https://github.com/BurntSushi/ripgrep/releases/download/$RG_VER/ripgrep-$RG_VER-x86_64-apple-darwin.tar.gz" \
        "" \
        rg
      install_from_tar \
        "https://github.com/sharkdp/fd/releases/download/v$FD_VER/fd-v$FD_VER-x86_64-apple-darwin.tar.gz" \
        "" \
        fd
      ;;
    macos:arm64)
      install_from_tar \
        "https://github.com/BurntSushi/ripgrep/releases/download/$RG_VER/ripgrep-$RG_VER-aarch64-apple-darwin.tar.gz" \
        "" \
        rg
      install_from_tar \
        "https://github.com/sharkdp/fd/releases/download/v$FD_VER/fd-v$FD_VER-aarch64-apple-darwin.tar.gz" \
        "" \
        fd
      ;;
    linux:x86_64)
      install_from_tar \
        "https://github.com/BurntSushi/ripgrep/releases/download/$RG_VER/ripgrep-$RG_VER-x86_64-unknown-linux-gnu.tar.gz" \
        "" \
        rg
      install_from_tar \
        "https://github.com/sharkdp/fd/releases/download/v$FD_VER/fd-v$FD_VER-x86_64-unknown-linux-gnu.tar.gz" \
        "" \
        fd
      install_busybox x86_64 || true
      ;;
    linux:arm64)
      install_from_tar \
        "https://github.com/BurntSushi/ripgrep/releases/download/$RG_VER/ripgrep-$RG_VER-aarch64-unknown-linux-gnu.tar.gz" \
        "" \
        rg
      install_from_tar \
        "https://github.com/sharkdp/fd/releases/download/v$FD_VER/fd-v$FD_VER-aarch64-unknown-linux-gnu.tar.gz" \
        "" \
        fd
      install_busybox arm64 || true
      ;;
    *)
      echo "Unsupported platform ($platform $arch). Please install tools manually; see tools/README.md." >&2
      exit 4
      ;;
  esac

  # Ensure wrapper scripts are executable
  chmod +x "$ROOT_DIR/tools/bootstrap.sh" 2>/dev/null || true
  [ -f "$ROOT_DIR/tools/run" ] && chmod +x "$ROOT_DIR/tools/run" 2>/dev/null || true
  [ -f "$ROOT_DIR/tools/run-linux" ] && chmod +x "$ROOT_DIR/tools/run-linux" 2>/dev/null || true

  echo "Done. Use ./tools/run (macOS) or ./tools/run-linux (Linux sandbox)."
}

main "$@"

