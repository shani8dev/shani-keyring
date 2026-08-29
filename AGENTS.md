# Agent instructions — shani-keyring

This file applies to any AI coding assistant working in this repository
(Claude Code, opencode, Kilo Code, Cursor, Aider, or similar). Read this
before editing, and follow the verification steps before calling any change
done.

## What this repo is

Exactly three files — `shani.gpg` (public key), `shani-trusted`,
`shani-revoked` — packaged verbatim into
`/usr/share/pacman/keyrings/` by `shani-pkgbuilds/shani-keyring`'s
PKGBUILD. This is the pacman trust root for the entire `[shani]` repo:
every package Shanios installs is verified against the key(s) listed here.

## Rule: a change here is only correct if it actually imports and verifies

Don't hand-edit these files and assume the format is right — a keyring
that `gpg`/`pacman-key` can't parse is worse than no change at all (it can
make a clean install fail entirely). Verify:

```bash
gpg --dry-run --import shani.gpg          # must succeed, no errors
gpg --show-keys shani.gpg                 # confirm the fingerprint/UID match what you intended
```

If you change `shani-revoked`, confirm the fingerprint listed actually
matches a real key in `shani.gpg`'s history, and check whether anything
downstream (`shani-pkgbuilds/shani-keyring/PKGBUILD`,
`shani-pkgbuilds/check-skip-checksums.sh`) needs its own checksum bumped to
match — a drift between this repo's content and what `shani-pkgbuilds`
expects to package is a real, silent failure mode (nothing currently
checks the two stay in sync automatically).

## If you have Superpowers / oh-my-opencode / ultrawork / similar available

If your environment provides Claude Code's **Superpowers** plugin, OpenCode's
**oh-my-opencode**, an **ultrawork**-style parallel execution mode, or an
equivalent skill/subagent framework — use it to check the two downstream
`shani-pkgbuilds` files above for the same commit/checksum concurrently
with the import/verify commands here, rather than checking one thing at a
time.

## Audit-verified known issues (confirmed present)

- **Stray header line before the real armor header (Low, cosmetic — NOT install-breaking).** `shani.gpg:1-2` — line 1 is a bogus `-----shrinivas-----` line, with the real `-----BEGIN PGP PUBLIC KEY BLOCK-----` armor header right after it on line 2. This was first flagged as Critical/install-breaking; re-verified by actual execution (`gpg --import` on GnuPG 2.4.4, and real `pacman-key --add` inside the `shani-builder` Arch container) — both succeed with exit code 0 and correctly resolve fingerprint `7B927BFFD4A9EAAA8B666B77DE217F3DA8014792`, since OpenPGP armor parsers scan for the BEGIN marker and ignore leading garbage before it. Worth cleaning up for tidiness, but not a real defect — don't re-flag this as Critical without re-testing against real `gpg`/`pacman-key` first.
- **Fingerprint.** `7B927BFFD4A9EAAA8B666B77DE217F3DA8014792` — same key used everywhere in the project.
- **Single non-expiring key. No rotation path exists — documented, not
  fixed.** A deliberate, currently-accepted trade-off, not an oversight —
  see `SECURITY.md`'s "If this key is ever compromised" section for the
  concrete, `pacman-key`-source-verified incident-response runbook (what
  actually happens to `shani-revoked`, why revocation doesn't propagate
  to already-installed machines automatically, and why a full rotation is
  a much bigger effort than revocation alone).
- **CI status.** No CI workflows, no pre-commit hooks.

## Cross-repo impact — check before calling a fix complete

`shani-pkgbuilds/shani-keyring/PKGBUILD` packages this repo's exact
content, checksummed. Any change here (new key, rotated trust file) is
incomplete until that PKGBUILD's checksums are bumped to match — a drift
between the two breaks every clean install with a checksum-mismatch
error, and nothing currently checks this automatically.

## Where things are documented

`README.md` explains what each of the three files is for and how
`shani-pkgbuilds` consumes them.
