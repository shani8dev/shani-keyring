#!/usr/bin/env bash
#
# check-checksums.sh — verify this repo's three keyring files match the
# sha256sums=() array in the sibling shani-pkgbuilds/shani-keyring/PKGBUILD.
#
# A drift between the two silently breaks every clean install with a
# checksum-mismatch error. This script catches that drift.
#
# Usage:
#   ./tests/check-checksums.sh [path/to/PKGBUILD]
#
# Exit codes:
#   0 — all checksums match
#   1 — one or more checksums mismatch (or PKGBUILD not found / unparseable)
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Default PKGBUILD location: sibling shani-pkgbuilds repo
PKGBUILD="${1:-${REPO_ROOT}/../shani-pkgbuilds/shani-keyring/PKGBUILD}"

if [[ ! -f "$PKGBUILD" ]]; then
    echo "ERROR: PKGBUILD not found at: $PKGBUILD" >&2
    echo "Usage: $0 [path/to/PKGBUILD]" >&2
    exit 1
fi

echo "Checking checksums against: $PKGBUILD"
echo

# --- Parse the source=() array to get filenames (basename of each URL) ---
# The PKGBUILD source array looks like:
#   source=('https://.../shani.gpg'
#           'https://.../shani-revoked'
#           'https://.../shani-trusted')
# We extract the basename of each URL entry.
mapfile -t SOURCE_URLS < <(
    awk '/^source=/{f=1} f{print} f&&/\)/{f=0}' "$PKGBUILD" \
        | grep -oE "'[^']+'" \
        | tr -d "'" \
        | while IFS= read -r url; do basename "$url"; done
)

# --- Parse the sha256sums=() array ---
mapfile -t EXPECTED_HASHES < <(
    awk '/^sha256sums=/{f=1} f{print} f&&/\)/{f=0}' "$PKGBUILD" \
        | grep -oE "'[0-9a-f]{64}'" \
        | tr -d "'"
)

# --- Validate we got matching counts ---
if [[ ${#SOURCE_URLS[@]} -eq 0 ]]; then
    echo "ERROR: could not parse source=() array from PKGBUILD" >&2
    exit 1
fi

if [[ ${#EXPECTED_HASHES[@]} -eq 0 ]]; then
    echo "ERROR: could not parse sha256sums=() array from PKGBUILD" >&2
    exit 1
fi

if [[ ${#SOURCE_URLS[@]} -ne ${#EXPECTED_HASHES[@]} ]]; then
    echo "ERROR: source array has ${#SOURCE_URLS[@]} entries but sha256sums has ${#EXPECTED_HASHES[@]}" >&2
    exit 1
fi

# --- Compare each file's actual sha256 against the expected value ---
MISMATCH=0
for i in "${!SOURCE_URLS[@]}"; do
    filename="${SOURCE_URLS[$i]}"
    expected="${EXPECTED_HASHES[$i]}"
    filepath="${REPO_ROOT}/${filename}"

    if [[ ! -f "$filepath" ]]; then
        echo "MISSING: $filename (file not found in repo)" >&2
        MISMATCH=1
        continue
    fi

    actual="$(sha256sum "$filepath" | awk '{print $1}')"

    if [[ "$actual" == "$expected" ]]; then
        echo "OK:      $filename  $actual"
    else
        echo "MISMATCH: $filename" >&2
        echo "  expected: $expected" >&2
        echo "  actual:   $actual" >&2
        MISMATCH=1
    fi
done

echo
if [[ $MISMATCH -eq 0 ]]; then
    echo "All ${#SOURCE_URLS[@]} checksums match."
    exit 0
else
    echo "FAIL: checksum mismatch detected — PKGBUILD is stale." >&2
    exit 1
fi
