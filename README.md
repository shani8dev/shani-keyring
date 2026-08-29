# shani-keyring

The pacman trust root for Shanios's custom package repository (`[shani]` at `repo.shani.dev`). This repo holds exactly three files, packaged as-is into `/usr/share/pacman/keyrings/` by [`shani-pkgbuilds/shani-keyring`](https://github.com/shani8dev/shani-pkgbuilds/tree/main/shani-keyring):

| File | Purpose |
|---|---|
| `shani.gpg` | The public signing key(s), in pacman-keyring format |
| `shani-trusted` | Which key(s) in `shani.gpg` are trusted, and at what trust level |
| `shani-revoked` | Revoked key fingerprints (currently empty — nothing has been revoked) |

This repo carries no independent version; the package version is set in `shani-pkgbuilds/shani-keyring/PKGBUILD`.

The signing key fingerprint is `7B927BFFD4A9EAAA8B666B77DE217F3DA8014792` — the same key used everywhere else in the project (OS image signing in `shani-deploy`, the `[shani]` repo import in `shani-builder`'s Docker image).

## How this gets consumed

`shani-pkgbuilds/shani-keyring/PKGBUILD` fetches these three files directly from `raw.githubusercontent.com/shani8dev/shani-keyring/main/<file>` and pins their `sha256sums`. This is deliberate: a mutable branch with no checksum would mean the distro's own trust root has no integrity check on it at all.

## If you ever change a file in this repo

**You must also update `shani-pkgbuilds/shani-keyring/PKGBUILD`** — regenerate its `sha256sums` (`updpkgsums`) and bump `pkgver`/`pkgrel` — in the same change, or immediately after. There's no automation tying the two repos together; nothing here notifies that repo when these files change.

If you forget, the next `shani-keyring` package build simply fails with a checksum mismatch — safe (it won't silently trust unexpected content), but it will look like an unrelated build failure to whoever hits it next, so please just do the update together.

This applies to a genuine key rotation too: replacing `shani.gpg`'s key, or adding an entry to `shani-revoked`, needs the same follow-up in `shani-pkgbuilds`.

## Key Rotation Procedure

If the signing key is compromised or needs rotation, follow this procedure:

### 1. Generate the new key

```bash
export GNUPGHOME=$(mktemp -d)
chmod 700 "$GNUPGHOME"

gpg --batch --gen-key <<EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: Shanios Signing Key
Name-Email: security@shani.dev
Expire-Date: 2y
%no-protection
%commit
EOF
```

### 2. Export the new public key

```bash
gpg --armor --export Shanios > shani.gpg
```

### 3. Update the trust file

```bash
FINGERPRINT=$(gpg --with-colons --show-keys shani.gpg | grep fpr | head -1 | cut -d: -f10)
echo "${FINGERPRINT}:4:" > shani-trusted
```

### 4. Add the old key to the revocation file

```bash
echo "<old-fingerprint>" >> shani-revoked
```

### 5. Verify the new keyring

```bash
gpg --dry-run --import shani.gpg
```

### 6. Publish the update

Commit the updated `shani.gpg`, `shani-trusted`, and `shani-revoked` files. The `shani-pkgbuilds/shani-keyring/PKGBUILD` checksums will need to be updated to match.

### 7. Communicate the change

Notify all users that the trust root has changed. Users must reinstall the keyring:

```bash
sudo pacman -S shani-keyring
sudo pacman-key --populate shani
```

### Trust Level Explanation

`shani-trusted` uses trust level `4` (ultimate trust). This means the key is trusted without requiring the normal Web of Trust validation. This is appropriate because:
- The key is distributed via a trusted channel (the OS install media)
- The keyring is itself signed and verified by pacman
- There is no external Web of Trust for a distro-specific key

### Revocation File Format

`shani-revoked` uses the standard pacman-key revocation format — one fingerprint per line. When a key is revoked, add its full fingerprint to this file. Pacman will refuse to verify packages signed with revoked keys.
