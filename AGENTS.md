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

## Empirical verification (mandatory)

**Reading code is analysis; running code is verification.** A change is not
verified by reading the diff, running `bash -n`, or confirming it "looks
correct." It is verified by observing the actual behavior of the real
thing in the real environment — built, served, deployed, signed, running.
If you haven't seen it work (or fail) for real, it isn't verified.

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

## Boundaries

- ✅ **Always**: `gpg --dry-run --import`/`--show-keys` verify any hand-edit
  before committing (see "Rule" above); bump `shani-pkgbuilds/shani-keyring/
  PKGBUILD`'s checksums in the same change if you touch any of the three
  files here.
- ⚠️ **Ask first**: rotating the signing key — no rotation path exists yet
  (see below); this needs the runbook in item 2 of the roadmap section
  written and reviewed before it's ever executed for real, not improvised
  mid-incident.
- 🚫 **Never**: treat "gpg/pacman-key parsed it" as sufficient without also
  confirming the fingerprint is exactly `7B927BFFD4A9EAAA8B666B77DE217F3DA8014792`
  — this is the trust root for every package on every shani machine; a
  wrong-but-parseable key is far worse than a syntax error.

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
- **CI status — corrected, was stale.** `.github/workflows/ci.yml` exists
  with a `verify-keyring` job (`gpg --dry-run --import shani.gpg` +
  fingerprint check) — this line previously said "No CI workflows", which
  was already wrong at the time it was written (verified via `git log`:
  the workflow predates that note). No pre-commit hooks.
- **Automated checksum-sync check with `shani-pkgbuilds` — DONE
  (2026-09-18).** `tests/check-checksums.sh` already existed (parses the
  PKGBUILD's `source=()`/`sha256sums=()` arrays and diffs against this
  repo's actual files) but was never wired into anything — a manual-only
  script, same "built but not connected" pattern found in shani-chronoa
  the same day. **Verified live**: ran it clean (all 3 match), then
  corrupted a local copy of `shani-trusted` and reran it — correctly
  caught the mismatch and exited 1, restored and reran clean again. Added
  a `verify-pkgbuild-checksum-sync` job to `ci.yml` that checks out both
  this repo and the sibling `shani8dev/shani-pkgbuilds` repo (GitHub
  Actions runners don't have sibling repos checked out by default, unlike
  this local dev environment) and runs the existing script —
  **verified the exact checkout layout locally** by replicating it under
  `/tmp` (two repos as true siblings, `working-directory: shani-keyring`,
  relative `../shani-pkgbuilds/...` path) before trusting the YAML.
  Master-roadmap item #6, closed.

## Cross-repo impact — check before calling a fix complete

`shani-pkgbuilds/shani-keyring/PKGBUILD` packages this repo's exact
content, checksummed. Any change here (new key, rotated trust file) is
incomplete until that PKGBUILD's checksums are bumped to match — a drift
between the two breaks every clean install with a checksum-mismatch
error, and nothing currently checks this automatically.

## Where things are documented

`README.md` explains what each of the three files is for and how
`shani-pkgbuilds` consumes them.

## Garuda Cross-Reference Findings (added 2026-09-17)

Based on a full scan of the garuda clones mapped against shani — **29 repos** (not 34; several user-listed names don't exist — see `../garuda-catalog.md` §Discrepancies). See `../garuda-mapping-analysis.md`, `../deep-analysis.md`, `../shani-catalog.md`, and `../garuda-catalog.md` for full details. No direct garuda equivalent — shani-keyring manages the pacman trust root for the entire shani ecosystem.

### 🔗 Cross-repo context

1. **Critical trust anchor** — This repo holds the pacman trust root (public key + trust/revoke files) that every shani install verifies packages against. Any change to this repo affects every package on every shani machine. Treat with the same weight as shani-deploy's boot-entry code.

2. **Cross-repo dependency** — `shani-builder/AGENTS.md` documents that `validpgpkeys` from PKGBUILDs are now imported into the build container's keyring before `makepkg` runs. Ensure this repo's keyring is updated whenever a new package with `validpgpkeys` is added to `shani-pkgbuilds`.

### 🔍 Re-Scan Findings (2026-09-17)

Re-scanned against `garuda-catalog.md` (29 repos, not 34) and `shani-catalog.md` (16 repos). **Confirmed mapping: no direct garuda equivalent.** The garuda-catalog discrepancy table lists `garuda-keyring` as NOT FOUND — the closest entry is `shani-keyring/` itself. Garuda's trust infrastructure is fragmented rather than a dedicated repo: Chaotic-AUR keys `0706B90D37D9B881` / `3056513887B78AEB` are baked directly into the `buildiso-docker` and `garuda-distrobox` Dockerfiles (`pacman-key --init`/`--lsign-key`), and `garuda-tools` ships `signiso`/`signpkgs`/`signfile` signing tools with a `gpgkey` config — but there is no standalone keyring/trust-root repo anywhere in the 29. This makes shani-keyring a **shani-specific security-critical component**: the single pacman trust root for the entire `[shani]` repo.

**New gaps from the garuda side:**
1. **No automated checksum-sync check** — `shani-pkgbuilds/shani-keyring/PKGBUILD` packages this repo's files verbatim, checksummed, and nothing verifies the two stay in sync (confirmed in `shani-catalog.md` §10 "Missing"). A drift silently breaks every clean install.
2. **No CI workflows, no pre-commit hooks** — confirmed in `shani-catalog.md` §10. Garuda's equivalent trust operations (key init/lsign in `buildiso-docker`, `garuda-distrobox`) are at least exercised by GitLab CI on every image build.
3. **No central config layer** — `garuda-tools` has `garuda-tools.conf` with system-wide (`/etc/`) and user (`~/.config/`) layers; shani-keyring is three static files with no config surface, so key selection/rotation parameters can't be tuned per-install.
4. **Single non-expiring key, no rotation path** — documented as deliberate in this repo's SECURITY.md, but the garuda side shows the alternative: two Chaotic-AUR keys with a documented `pacman-key --init`/`--lsign-key` bootstrap in Dockerfiles. Worth re-reading the trade-off against that precedent.

**Shani advantages:**
1. **One dedicated, auditable trust root** — exactly three files (`shani.gpg`, `shani-trusted`, `shani-revoked`) vs garuda's keys scattered across Dockerfiles and tool configs. The blast radius of a change is fully contained in this repo.
2. **Consistent single fingerprint** `7B927BFFD4A9EAAA8B666B77DE217F3DA8014792` used for package signing, UKI signing, and agent commands (per `shani-catalog.md` global patterns) — one key to reason about, vs garuda's two-key Chaotic-AUR setup.
3. **Documented incident-response runbook** — SECURITY.md's "If this key is ever compromised" section is `pacman-key`-source-verified; none of the 29 garuda repos has an AGENTS.md or equivalent security documentation at all.

**Qt GUI gap note:** not applicable — trust-root management is `pacman-key` CLI-only on both sides. (Garuda's 12 Qt GUI apps carry `pkexec` policies for privileged ops, but none of them manages the pacman trust root.)

### 📋 Implementation Roadmap (2026-09-17)

Implementation priorities are per `../IMPLEMENTATION-ROADMAP.md` (master roadmap for the whole shani ecosystem).

1. ~~**Automated checksum-sync check with `shani-pkgbuilds` (P0, few hours).**~~ **DONE (2026-09-18)** — see "Audit-verified known issues" above. Master-roadmap item #6, closed.

2. **Key rotation path planning (P0/P1, documented trade-off → real runbook).** The single non-expiring key has no rotation path — a deliberate, documented trade-off (see `SECURITY.md`'s incident-response runbook). Formalize an actual rotation procedure (new key generation, dual-key period, migration steps for `shani-trusted`/`shani-revoked` and every downstream `validpgpkeys` reference) even if it's never executed — the plan must exist before it's needed. Do NOT copy garuda's fragmented approach of baking keys into Dockerfiles; shani's single dedicated trust root is the superior model to preserve.

3. ~~**CI workflow (P1).** Verify key-file integrity on every commit...~~ **Already existed** when this was written (stale note, corrected 2026-09-18 — see "Audit-verified known issues" above): `ci.yml`'s `verify-keyring` job already does exactly this (`gpg --dry-run --import` + fingerprint check). Only the checksum-sync job (item 1) was actually missing.

4. **Conventional commits + minimal shared CI (P1).** Adopt the ecosystem-wide conventional-commit convention (master-roadmap item #9) and a minimal `renovate.json` (item #8) — this repo has no dependencies to update, so Renovate is near-no-op here, but the commit convention matters for changelog generation across the ecosystem.
