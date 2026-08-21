# shani-keyring

The pacman trust root for ShaniOS's custom package repository (`[shani]` at `repo.shani.dev`). This repo holds exactly three files, packaged as-is into `/usr/share/pacman/keyrings/` by [`shani-pkgbuilds/shani-keyring`](https://github.com/shani8dev/shani-pkgbuilds/tree/main/shani-keyring):

| File | Purpose |
|---|---|
| `shani.gpg` | The public signing key(s), in pacman-keyring format |
| `shani-trusted` | Which key(s) in `shani.gpg` are trusted, and at what trust level |
| `shani-revoked` | Revoked key fingerprints (currently empty — nothing has been revoked) |

The signing key fingerprint is `7B927BFFD4A9EAAA8B666B77DE217F3DA8014792` — the same key used everywhere else in the project (OS image signing in `shani-deploy`, the `[shani]` repo import in `shani-builder`'s Docker image).

## How this gets consumed

`shani-pkgbuilds/shani-keyring/PKGBUILD` fetches these three files directly from `raw.githubusercontent.com/shani8dev/shani-keyring/main/<file>` and pins their `sha256sums`. This is deliberate: a mutable branch with no checksum would mean the distro's own trust root has no integrity check on it at all.

## If you ever change a file in this repo

**You must also update `shani-pkgbuilds/shani-keyring/PKGBUILD`** — regenerate its `sha256sums` (`updpkgsums`) and bump `pkgver`/`pkgrel` — in the same change, or immediately after. There's no automation tying the two repos together; nothing here notifies that repo when these files change.

If you forget, the next `shani-keyring` package build simply fails with a checksum mismatch — safe (it won't silently trust unexpected content), but it will look like an unrelated build failure to whoever hits it next, so please just do the update together.

This applies to a genuine key rotation too: replacing `shani.gpg`'s key, or adding an entry to `shani-revoked`, needs the same follow-up in `shani-pkgbuilds`.
