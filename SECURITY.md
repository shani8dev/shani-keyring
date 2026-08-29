# Security Policy

## Trust Model

`shani-keyring` is the **pacman trust root** for the entire `[shani]` package
repository. It holds exactly three files, packaged verbatim into
`/usr/share/pacman/keyrings/`:

| File | Purpose |
|------|---------|
| `shani.gpg` | The public signing key(s), in pacman-keyring format |
| `shani-trusted` | Which key(s) in `shani.gpg` are trusted, and at what trust level |
| `shani-revoked` | Revoked key fingerprints (currently empty) |

Every package Shanios installs is verified against the key(s) listed here.
A keyring that `gpg`/`pacman-key` can't parse is worse than no change at all —
it can make a clean install fail entirely.

## Key Security Mechanisms

| Mechanism | Implementation |
|-----------|----------------|
| Key verification | `gpg --dry-run --import shani.gpg` must succeed after any change |
| Checksum pinning | `shani-pkgbuilds/shani-keyring/PKGBUILD` pins `sha256sums` on all 3 files |
| Single signing key | Fingerprint `7B927BFFD4A9EAAA8B666B77DE217F3DA8014792` |

## Known Limitations

- **Stray line before the real GPG header (cosmetic, not install-breaking).**
  `shani.gpg` has a bogus `-----shrinivas-----` line before the real
  `-----BEGIN PGP PUBLIC KEY BLOCK-----` armor header. Re-verified by
  actual execution (`gpg --import` on GnuPG 2.4.4, and a real
  `pacman-key --add` inside the `shani-builder` container): both succeed
  and correctly resolve the real fingerprint, since OpenPGP armor parsers
  scan forward for the `BEGIN` marker and ignore leading garbage before
  it. Worth cleaning up, but does not cause install failures — an earlier
  version of this document overstated this as a blocking defect.
- **Single non-expiring key. No rotation path exists.** This key has no
  expiration date set (`gpg --list-keys --with-colons` confirms an empty
  expiry field) and there is only ever one active signing key at a time —
  there is no second, standby key that could take over instantly if this
  one were ever compromised. This is a deliberate, currently-accepted
  trade-off, not an oversight: rotating to a genuinely new key is a real,
  coordinated, cross-repo undertaking (every already-published package in
  `shani-repo` would need re-signing, `shani-pkgbuilds/shani-keyring`'s
  checksums would need bumping, and every already-installed machine needs
  to actually receive and apply the new `shani-keyring` package before it
  trusts the replacement) — not something to do preemptively without a
  concrete reason. See "If this key is ever compromised" below for what
  actually happens today if it needs to be revoked.
- **Revocation doesn't propagate to already-installed systems
  automatically.** Verified by reading `pacman-key`'s own source
  (`/usr/sbin/pacman-key`): `shani-revoked` is only consulted, and a
  listed key only actually gets GPG-disabled in the local trust
  database, when `pacman-key --populate shani` runs — which happens via
  this keyring package's own install/upgrade hook. A machine that never
  upgrades the `shani-keyring` package (offline, decommissioned, pinned)
  keeps trusting a revoked key indefinitely. There is no live,
  network-checked revocation source (e.g. OCSP/CRL-style) — pacman's
  keyring model doesn't have one.
- **No automated drift check.** `shani-pkgbuilds/shani-keyring/PKGBUILD` checksums must be manually bumped when this repo's content changes. Nothing checks the two stay in sync automatically.

## If this key is ever compromised

This is the concrete incident-response runbook — what to actually do,
verified against `pacman-key`'s real source and this repo's real files,
not a generic template. All of this requires the real private key or its
existing revocation certificate; if neither is available, the key cannot
be revoked this way at all (see "No standby key" below).

1. **Generate (or use an existing) revocation certificate** for
   `7B927BFFD4A9EAAA8B666B77DE217F3DA8014792` and publish it to a
   keyserver, so the compromise is discoverable independently of this
   repo. `gpg --gen-revoke <fingerprint>` if one wasn't prepared in
   advance — this needs the private key, so it must happen before the
   key material itself is lost, not after.
2. **Add the fingerprint to `shani-revoked`** in this repo, one
   fingerprint per line, no trailing metadata — confirmed via the real
   `archlinux-revoked` reference file inside the `shani-builder`
   container, which uses this exact bare format (contrast with
   `shani-trusted`'s `FINGERPRINT:TRUST_LEVEL:` format — the two files
   are not the same shape).
3. **Bump `shani-pkgbuilds/shani-keyring/PKGBUILD`'s checksums** to match
   this repo's new content — a stale checksum there makes the *old*,
   not-yet-revoked keyring get packaged, silently undoing step 2 for
   anyone who installs from that stale package.
4. **Build, sign (with whatever key/process is used for the *next*
   package, not the compromised one), and publish** the new
   `shani-keyring` package to `shani-repo` through the normal
   `shani-builder` pipeline.
5. **Every already-installed machine only actually disables the
   compromised key once it upgrades to this new `shani-keyring` package**
   (its post-install hook re-runs `pacman-key --populate shani`, which is
   what reads `shani-revoked` and marks the key GPG-"disabled" in the
   local trust database — confirmed by reading `pacman-key`'s
   `populate()`/`key_is_revoked()` functions directly). There is no way
   to force this remotely; a machine that never updates never picks up
   the revocation. This is the single biggest practical limitation of
   this whole trust model — plan announcements/communication for a real
   compromise accordingly, don't assume publishing the revocation alone
   protects anyone.
6. **No standby key exists today** (see "Single non-expiring key" above)
   — a full rotation to a *new* signing key, not just revocation of the
   old one, additionally requires re-signing every package currently in
   `shani-repo` and updating every reference to the old fingerprint across
   `shani-keyring` (here), `shani-builder` (signing), and any consumer
   that hardcodes it. This is a much larger undertaking than steps 1-5 and
   should be planned as its own effort, not attempted mid-incident from
   scratch.

## Reporting a Vulnerability

If you discover a security vulnerability in any Shanios project, please report it
responsibly by opening a private security advisory on GitHub.

Please include:
- A description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will acknowledge receipt within 72 hours and provide a detailed response
within 7 days. Thank you for helping keep Shanios secure.
