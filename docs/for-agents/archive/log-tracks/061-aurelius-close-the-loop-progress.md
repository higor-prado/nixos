# Aurelius Close the Loop Progress

## Status

Complete

## Related Plan

- [061-aurelius-close-the-loop.md](/home/higorprado/nixos/docs/for-agents/plans/061-aurelius-close-the-loop.md)

## Baseline

- Active branch: `aurelius-next-steps-plan`
- Working tree has uncommitted clean changes: `predator.nix`, `llm-agents.nix`,
  `flake.lock`, `aurelius.nix`
- Untracked files: `modules/features/system/grafana.nix`,
  `docs/for-agents/plans/060-aurelius-grafana-baseline.md`
- `attic-publisher.nix` on predator runs `attic watch-store` daemon (~500 MB idle)
- All other aurelius phases from original draft are complete per 050 progress log

## Slices

### Slice 1 — Phase 0: baseline commits

- Verified working-tree diffs: `predator.nix` (amdev IPv4 fix), `llm-agents.nix`
  (copilot-cli), `flake.lock` (four input updates) — all dendritic-compliant
- Committed each in a focused commit; held back `aurelius.nix` until grafana.nix
  was tracked
- Gates passed: `./scripts/run-validation-gates.sh structure`
- Evals passed: both `predator` and `aurelius` toplevel drvPaths returned

### Slice 2 — Phase 1: grafana

- `git add`-ed `grafana.nix`, `aurelius.nix`, `060-aurelius-grafana-baseline.md`
- Added `system.activationScripts.grafana-secret-key` to `grafana.nix`: generates
  `/var/lib/grafana/secret-key` on first activation if absent
- Committed in two commits: initial module + activation script fix
- Gates passed: `./scripts/run-validation-gates.sh structure`,
  `./scripts/check-docs-drift.sh`, `./scripts/check-repo-public-safety.sh`
- Deployed: `nh os test path:$PWD#aurelius --target-host aurelius --build-host aurelius -e passwordless`
- Runtime proof:
  - `grafana.service` is `active (running)` on aurelius
  - `curl http://127.0.0.1:3001/` → HTTP 200 (local)
  - `curl http://aurelius.your-tailnet.ts.net:3001/api/health` → HTTP 200 (from predator)
  - Prometheus datasource provisioned declaratively

### Slice 3 — Phase 2: attic-publisher fix

- Replaced `systemd.services.attic-watch-store` persistent daemon (~500 MB idle RSS)
  with `nix.settings.post-build-hook` in `attic-publisher.nix`
- Hook runs as root after each build, sets HOME/XDG_CONFIG_HOME to
  `/var/lib/attic-publisher`, logs in with token from tokenFile, pushes `$OUT_PATHS`
- No `StateDirectory` (hook does `mkdir -p` at runtime); no persistent process
- Deployed to predator: nix-daemon RSS dropped from ~500 MB to 35 MB
- Gates passed: `./scripts/run-validation-gates.sh structure`
- Commit: `fix(attic-publisher): replace watch-store daemon with post-build-hook`

### Slice 4 — Phase 3: service-owned timers

- Added `docker-health-check` service + 15-min timer to `docker.nix` (correct owner)
- Added `disk-usage-alert` service + daily timer to `maintenance.nix` (correct owner)
- Added `flake-update-check` service + weekly timer to `maintenance.nix` — WRONG:
  hardcoded `/etc/nixos/flake.lock` which does not exist; removed in correction pass
- Gates passed before and after correction
- Commits: `feat(docker): add health-check timer`, `feat(maintenance): add disk-usage and flake-update timers`

### Slice 5 — Phase 4: access model

- Added `AuthenticationMethods = "publickey"` to `ssh.nix` (correct owner: sshd policy)
- Applies to both predator and aurelius — both benefit from requiring pubkey
- Deployed to aurelius; sshd.service restarted cleanly
- Commit: `fix(ssh): require public-key authentication`

### Slice 6 — Phase 5: exit node

- Added `useRoutingFeatures = "server"` to shared `tailscale.nix` — WRONG: both
  predator and aurelius import this feature; only aurelius should be exit node
- Correction: removed from `tailscale.nix`, created dedicated `tailscale-exit-node.nix`
  publishing `nixos.tailscale-exit-node`; aurelius includes it, predator does not
- Follows pattern: feature inclusion IS the condition (no inline overrides in host file)
- Validated: aurelius evals to `"server"`, predator evals to `"none"`
- Deployed to aurelius; verified via systemd timers list
- Commit: `fix(tailscale): split exit-node routing into dedicated feature module`

### Slice 7 — Phase 6: reproducibility

- Bootstrap runbook `107-aurelius-service-bootstrap.md` updated:
  - Removed stale reference to `attic-watch-store.service`
  - Added Grafana section: auto-bootstrap via activation script, no manual steps
  - Added Forgejo section: first-boot web UI at port 3000, `/var/lib/forgejo/` must be preserved
  - Added SSH keys section: restore private keys post-rebuild
  - Added Tailscale exit-node section: `tailscale set --advertise-exit-node` + admin console approval
  - Added pre-wipe checklist: Forgejo data, Attic env, runner token, SSH keys, publisher token
- Docs-drift and public-safety checks passed
- Commit: `docs(aurelius): complete service bootstrap and recovery runbook`

### Slice 8 — Phase 7: documentation cleanup

- Progress log 061 filled and marked Complete
- Plans and logs archived (see archive commit)

## Final State

- `tailscale-exit-node.nix` publishes `nixos.tailscale-exit-node`; aurelius includes it; predator does not
- `tailscale.nix` restored to minimum: `enable = true; openFirewall = true`
- `maintenance.nix` has `fstrim` and `disk-usage-alert`; `flake-update-check` removed
- `ssh.nix` requires `publickey` authentication
- Bootstrap runbook covers full recovery surface for aurelius
- All gates pass: `./scripts/run-validation-gates.sh all`
