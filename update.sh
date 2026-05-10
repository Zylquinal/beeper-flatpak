#!/usr/bin/env bash
# update.sh — Updates the Beeper Flatpak manifest with the latest stable
#              AppImage URLs, SHA256 hashes, and file sizes.
#
# Usage:
#   ./update.sh
#
# Requirements: curl, sha256sum, python3 (for yaml patching via sed)

set -euo pipefail

MANIFEST="com.automattic.beeper.yml"
API_BASE="https://api.beeper.com/desktop/download/linux"
METAINFO="com.automattic.beeper.metainfo.xml"

echo "==> Resolving latest Beeper stable URLs..."

X64_URL=$(curl -sI "${API_BASE}/x64/stable/com.automattic.beeper.desktop" \
  | grep -i '^location:' | tr -d '\r' | awk '{print $2}')
ARM64_URL=$(curl -sI "${API_BASE}/arm64/stable/com.automattic.beeper.desktop" \
  | grep -i '^location:' | tr -d '\r' | awk '{print $2}')

echo "  x86_64 : ${X64_URL}"
echo "  aarch64: ${ARM64_URL}"

# Extract version from filename, e.g. Beeper-4.2.808-x86_64.AppImage -> 4.2.808
VERSION=$(basename "${X64_URL}" | sed -E 's/Beeper-([0-9.]+)-.*/\1/')
echo "  version: ${VERSION}"

echo ""
echo "==> Downloading and hashing AppImages (this may take a few minutes)..."

X64_SHA256=$(curl -sL "${X64_URL}" | sha256sum | awk '{print $1}')
X64_SIZE=$(curl -sI "${X64_URL}" | grep -i '^content-length:' | tr -d '\r' | awk '{print $2}')

ARM64_SHA256=$(curl -sL "${ARM64_URL}" | sha256sum | awk '{print $1}')
ARM64_SIZE=$(curl -sI "${ARM64_URL}" | grep -i '^content-length:' | tr -d '\r' | awk '{print $2}')

echo "  x86_64  sha256=${X64_SHA256}  size=${X64_SIZE}"
echo "  aarch64 sha256=${ARM64_SHA256}  size=${ARM64_SIZE}"

echo ""
echo "==> Patching ${MANIFEST}..."

# Patch x86_64 block
sed -i \
  -e "/only-arches: \[x86_64\]/{n; s|url: .*|url: ${X64_URL}|; n; s|sha256: .*|sha256: ${X64_SHA256}|; n; s|size: .*|size: ${X64_SIZE}|}" \
  "${MANIFEST}"

# Patch aarch64 block
sed -i \
  -e "/only-arches: \[aarch64\]/{n; s|url: .*|url: ${ARM64_URL}|; n; s|sha256: .*|sha256: ${ARM64_SHA256}|; n; s|size: .*|size: ${ARM64_SIZE}|}" \
  "${MANIFEST}"

echo "==> Patching ${METAINFO} release section..."

DATE_TODAY=$(date +%Y-%m-%d)
sed -i \
  -e "s|<release version=\"[^\"]*\" date=\"[^\"]*\">|<release version=\"${VERSION}\" date=\"${DATE_TODAY}\">|" \
  -e "/<release version/,/<\/release>/{s|Beeper stable release [^<]*|Beeper stable release ${VERSION}.|}" \
  "${METAINFO}"

echo ""
echo "✓ Done! Review changes with: git diff"
echo ""
echo "Remember to commit with:"
echo "  git add ${MANIFEST} ${METAINFO}"
echo "  git commit -m 'Update to Beeper ${VERSION}'"
