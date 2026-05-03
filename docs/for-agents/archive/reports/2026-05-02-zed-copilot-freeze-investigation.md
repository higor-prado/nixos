# Zed Copilot Freeze Investigation

**Date:** 2026-05-02  
**Status:** Resolved

## Problem

Zed editor UI freezing and becoming unresponsive during use.

## Root Cause

The Copilot Language Server (`@github/copilot-language-server`) performs periodic OAuth token refresh via `authFromGitHubSession` → `fetchTokenResult` to `api.github.com/copilot_internal/v2/token`. When this HTTP call times out (120s Undici timeout), the LSP's event loop blocks. Since Zed communicates with the LSP via stdio JSON-RPC, all Copilot features (completions, agent chat, telemetry) stall. The editor UI freezes waiting for LSP responses.

Three Copilot LSP instances (~800MB each) were running simultaneously (one per open worktree), multiplying the impact.

## Evidence

From `Zed.log.old`:

```
[auth] tokenRefresh: HttpTimeoutError
Request to <https://api.github.com/copilot_internal/v2/token>
timed out after 120000ms
```

Completions were succeeding (12× 200 OK, 300-1000ms) — only the auth layer was broken.

## Secondary Issues Found

### Fixed: package-version-server dynamic linking

The `package-version-server` binary downloaded by Zed is dynamically linked and couldn't run on NixOS. Enabled `programs.nix-ld` with basic libraries. Resolved.

### Not actionable (harmless):

- `fs_watcher` errors on `.devenv/state/venv/` Nix store symlinks
- `window not found` GPUI race conditions
- `Unable to deserialize editor` persistence state mismatches

## Resolution

1. Cleared Copilot auth cache (`~/.config/github-copilot`, Copilot LSP cache)
2. Re-authenticated with fresh token
3. Enabled `nix-ld` for `package-version-server` binary support

## Changes Applied

- `modules/features/dev/editors-zed.nix`: Added `nix-ld` NixOS module, added `zeditor` fish abbrev
- `modules/hosts/predator.nix`: Enabled `nixos.editors-zed`
