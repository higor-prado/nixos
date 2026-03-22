# Aurelius Close the Loop

## Goal

Close the aurelius roadmap against every phase in the original draft
(~/Downloads/aurelius-next-steps.md) except the backup phase (Phase 2).
Classify each phase as done, done-with-issues, or pending, then fix every
incorrectness and implement every remaining phase to the repo quality bar:
owner shape correct, runtime proof from both ends, docs reflecting reality.

## Scope

In scope:
- Phase 0 of draft (Docker + firewall): verify done, commit pending working tree
- Phase 1 of draft (remote dev + Mosh): verify done, commit pending working tree
- Phase 3 of draft (Attic binary cache): fix RAM issue on predator publisher
- Phase 4 of draft (Forgejo): verify done
- Phase 5 of draft (Prometheus + Grafana): Prometheus verified; Grafana needs
  git-tracking, deploy, and runtime proof
- Phase 6 of draft (GitHub Actions runner): verify done
- Phase 7 of draft (automation/timers): implement service-owned timers in correct
  owners, not a broad bucket module
- Phase 8 of draft (container playground): verify inherent; Docker already on
- Phase 9 of draft (Caddy / Tailscale Serve): evaluate and implement if needed
- Phase 10 of draft (Tailscale exit nodes): implement aurelius as BR exit node
- Reproducibility: verify private/ overrides cover authorized keys and SSH config;
  audit ad-hoc state; complete bootstrap runbook for all services

Out of scope:
- Phase 2 of draft (Restic backup): explicitly deferred; Orange Pi 5 not yet
  on NixOS
- vpn-us / GCP provisioning: separate project with its own plan

## Current State

Phases complete and proved:

| Phase (draft) | Owners | Status |
|---|---|---|
| Phase 0 — Docker | `docker.nix`, `aurelius.nix` | complete |
| Phase 1 — Remote dev + Mosh | `mosh.nix`, `aurelius.nix`, `predator.nix` | complete |
| Phase 4 — Forgejo | `forgejo.nix`, `aurelius.nix` | complete |
| Phase 6 — GitHub runner | `github-runner.nix`, `aurelius.nix` | complete |
| Phase 5 (partial) — Prometheus | `prometheus.nix`, `aurelius.nix` | complete |
| Phase 3 — Attic server + local publisher | `attic-server.nix`, `attic-local-publisher.nix`, `aurelius.nix` | complete |
| Phase 3 — Attic publisher/client (predator) | `attic-publisher.nix`, `attic-client.nix`, `predator.nix` | done with issue |

Issues:

- `attic-publisher.nix` runs `attic watch-store` as a persistent daemon on
  predator, consuming ~500 MB RAM idle. Expected model is publish-on-build only.
  Fix: replace with `nix.settings.post-build-hook`.
- `modules/features/system/grafana.nix` is written but untracked. `aurelius.nix`
  already composes `nixos.grafana` in the working tree but import-tree cannot
  discover the untracked file. No deploy, no runtime proof yet.
- Working tree has uncommitted clean changes:
  - `predator.nix` — fixes `amdev` for Tailscale IPv4
  - `llm-agents.nix` — adds copilot-cli
  - `flake.lock` — four input updates
  - `aurelius.nix` — must not be committed before grafana.nix is tracked

Pending phases not started:

- Phase 5 (partial) — Grafana
- Phase 7 — Service-owned timers
- Phase 8 — Playground: inherent via Docker, no tracked work needed
- Phase 9 — Access model: Tailscale Serve vs direct ports
- Phase 10 — Exit node

Bootstrap runbook (`107-aurelius-service-bootstrap.md`) gaps:
- Missing Grafana secret-key creation step
- Missing Forgejo first-boot admin account step
- Missing SSH key bootstrap steps
- Missing pre-wipe checklist

Reproducibility gaps:
- `private/hosts/aurelius/default.nix` may not have `authorizedKeys.keys`
  filled or `users.mutableUsers = lib.mkForce false` set
- Authorized keys added ad-hoc on the host will not survive a wipe

## Desired End State

- Every phase of the original draft (except backup) is either done with runtime
  proof, or explicitly deferred with a stated reason
- `attic-publisher` on predator uses `nix.settings.post-build-hook`; no daemon
- Grafana deployed on aurelius, reachable from predator via Tailscale
- Service-owned timers active for Docker health, disk usage, and flake updates
- Access model decision documented (Tailscale Serve or direct ports)
- aurelius configured as Tailscale exit node and proved from predator
- `private/hosts/aurelius/default.nix` declares authorized keys and
  `mutableUsers = false`
- Bootstrap runbook complete for all services
- All completed plans archived
- All validation gates pass

## Phases

### Phase 0: Baseline

Changes:
- Verify working tree diffs are dendritic-compliant
- Commit `predator.nix`, `llm-agents.nix`, `flake.lock` in focused commits
- Do not commit `aurelius.nix` until grafana.nix is tracked

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`

Diff expectation:
- predator.nix: amdev uses `--family=inet --bind-server`
- llm-agents.nix: adds copilot-cli
- flake.lock: bumped hashes for four inputs

Commit targets:
- `fix(predator): use explicit IPv4 bind for mosh amdev abbreviation`
- `feat(llm-agents): add copilot-cli`
- `chore(flake): update inputs`

### Phase 1: Grafana

Targets:
- `modules/features/system/grafana.nix`
- `modules/hosts/aurelius.nix`
- `docs/for-agents/plans/060-aurelius-grafana-baseline.md`
- `docs/for-humans/workflows/107-aurelius-service-bootstrap.md`
- `docs/for-agents/current/050-aurelius-next-steps-dendritic-plan-progress.md`

Changes:
- `git add` grafana.nix and 060 plan
- `git add` aurelius.nix (now safe because grafana.nix is tracked)
- Verify grafana.nix owns all service semantics (firewall, bind, root_url,
  datasource); aurelius.nix only composes
- Bootstrap on aurelius before deploy:
  ```bash
  sudo install -m 600 -o grafana -g grafana \
    <(openssl rand -base64 32) \
    /var/lib/grafana/secret-key
  ```
- Add that bootstrap step to the runbook
- Deploy and prove runtime

Validation:
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-docs-drift.sh`
- `./scripts/check-repo-public-safety.sh`
- `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
- `nh os test path:$PWD#aurelius --target-host aurelius --build-host aurelius -e passwordless`
- On aurelius: `systemctl status grafana.service --no-pager -l`
- On aurelius: `curl -I http://127.0.0.1:3001/`
- From predator: `curl -I http://aurelius.your-tailnet.ts.net:3001/`

Diff expectation:
- aurelius.nix: composes nixos.grafana
- grafana.nix: all service semantics owned here

Commit target:
- `feat(monitoring): add aurelius grafana baseline`

### Phase 2: Fix attic-publisher

Targets:
- `modules/features/system/attic-publisher.nix`

Changes:
- Remove `systemd.services.attic-watch-store` entirely
- Add `nix.settings.post-build-hook` with a script that reads the token,
  logs in to the remote Attic, and pushes `$OUT_PATHS`
- Script must not block builds on Attic unavailability
- Keep all options and mkIf pattern unchanged
- Keep `StateDirectory = "attic-publisher"` for attic client HOME

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.nix.settings.post-build-hook`
  returns a store path
- `nh os test path:$PWD#predator`
- Verify `attic-watch-store.service` is gone on predator
- Trigger a real build; verify paths arrive in Attic on aurelius
- Confirm nix-daemon RSS is no longer inflated

Diff expectation:
- attic-publisher.nix: daemon removed, post-build-hook added

Commit target:
- `fix(attic): replace watch-store daemon with post-build-hook on predator`

### Phase 3: Service-owned timers

The original draft proposed three timers. Each must live in the narrowest
owner that genuinely owns the concern — not in a broad bucket module.

Targets:
- `modules/features/system/docker.nix` — Docker health-check (15 min)
- Appropriate existing owner for disk usage alert (daily) and flake update
  checker (weekly) — read owners before deciding

Changes:
- Add systemd service + timer pair to each owner
- If no narrower home exists for a timer, surface the question before committing

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
- Deploy to aurelius
- `systemctl list-timers --no-pager` on aurelius confirms each timer active
- Trigger each oneshot manually and verify journal output

Commit targets:
- `feat(docker): add health-check timer`
- `feat(maintenance): add disk usage alert and flake update checker`

### Phase 4: Access model

The original draft proposed Caddy. Tailscale Serve is the NixOS-native alternative.
Direct port access via Tailscale is already working.

Targets:
- Evaluate whether Tailscale Serve or Caddy adds value over the current model
- `modules/features/system/tailscale.nix` if Serve is chosen

Changes:
- If direct-port model is sufficient: document explicitly and defer
- If Tailscale Serve adds value (HTTPS, unified URLs): implement narrowly

Validation:
- From predator: verify all service URLs reachable as documented
- If Serve: verify HTTPS and Tailscale cert

Commit target:
- `feat(tailscale): add Tailscale Serve for aurelius services` or
- `docs(aurelius): document direct-port access model`

### Phase 5: Tailscale exit node

Targets:
- `modules/features/system/tailscale.nix`
- `modules/hosts/aurelius.nix`
- `docs/for-humans/workflows/107-aurelius-service-bootstrap.md`

Changes:
- Add `useRoutingFeatures = "server"` to the tailscale owner
- aurelius.nix composes the updated owner
- Operator steps (not tracked in Nix): advertise and approve in Tailscale Admin
- Document both operator steps in 107

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.services.tailscale.useRoutingFeatures`
  returns `"server"`
- `nh os test path:$PWD#aurelius --target-host aurelius --build-host aurelius -e passwordless`
- On aurelius: `sudo tailscale set --advertise-exit-node`
- From predator: `sudo tailscale set --exit-node=aurelius`
- `curl https://ipinfo.io` from predator shows Brazilian IP
- Restore: `sudo tailscale set --exit-node=`

Commit target:
- `feat(tailscale): enable aurelius exit-node routing`

### Phase 6: Reproducibility

The goal is that after a wipe + rebuild of aurelius, the operator can reach a
fully working system by restoring gitignored private/ overrides and following
the bootstrap runbook. Nothing that can be expressed in Nix should be ad-hoc.

Targets:
- `private/hosts/aurelius/default.nix` (gitignored, not tracked)
- `private/hosts/aurelius/default.nix.example` (tracked example)
- `docs/for-humans/workflows/107-aurelius-service-bootstrap.md`

Changes:

SSH access (NixOS-level, in gitignored private host override):
- Verify `private/hosts/aurelius/default.nix` exists on predator
- Verify it declares `users.mutableUsers = lib.mkForce false`
- Verify it declares `users.users.${userName}.openssh.authorizedKeys.keys`
  with the real authorized public keys
- Verify the private override is actually imported in the aurelius composition
- If missing: fill it in, rebuild, verify SSH still works from predator

SSH identity config (HM-level, in gitignored private user override):
- Verify aurelius instance of `private/users/higorprado/ssh.nix` declares
  matchBlocks for git hosts (GitHub, Forgejo) pointing to the correct key paths
- If missing: fill in; actual private key files remain a bootstrap step

Ad-hoc audit on running aurelius:
- SSH in and check for any running state not covered by Nix
- Check `/etc/` for manually managed files outside Nix control
- If `mutableUsers = false` is active: `~/.ssh/authorized_keys` must not be
  a standalone ad-hoc file (NixOS manages it via the declared keys)

Bootstrap runbook additions to `107-aurelius-service-bootstrap.md`:
- Grafana secret-key: `sudo install -m 600 -o grafana -g grafana <(openssl rand -base64 32) /var/lib/grafana/secret-key`
- Forgejo: first-boot admin account; note that `/var/lib/forgejo/` holds all
  data and must be backed up before a wipe
- SSH keys: which private key files to restore to `~/.ssh/` on aurelius
- Tailscale exit-node activation steps
- Pre-wipe checklist: what to back up and post-rebuild recovery order

Validation:
- Rebuild aurelius after fixing private override; verify SSH works from predator
- `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.users.mutableUsers`
  returns `false`
- `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.users.users.higorprado.openssh.authorizedKeys.keys`
  returns the expected key list (not empty)
- `./scripts/check-docs-drift.sh`
- `./scripts/check-repo-public-safety.sh`

Commit targets:
- `docs(aurelius): complete service bootstrap and recovery runbook`
- Update tracked example if it needs clarification

### Phase 7: Documentation cleanup

Targets:
- `docs/for-agents/current/050-aurelius-next-steps-dendritic-plan-progress.md`
- `docs/for-agents/current/058-aurelius-reproducibility-hardening-progress.md`
- `docs/for-agents/plans/050-aurelius-next-steps-dendritic-plan.md`
- `docs/for-agents/plans/058-aurelius-reproducibility-hardening.md`
- `docs/for-agents/plans/059-runner-recovery-after-bad-rotation.md`
- `docs/for-agents/plans/060-aurelius-grafana-baseline.md`

Changes:
- Update 050 progress with final honest proof matrix
- Move 050, 058, 059, 060 plans and their progress logs to archive/
- Verify `docs/for-agents/current/` and `docs/for-agents/plans/` contain only
  genuinely active work

Validation:
- `./scripts/check-docs-drift.sh`

Commit target:
- `docs(aurelius): archive completed plans and close roadmap`

## Risks

- `nix.settings.post-build-hook` runs as root. A buggy script silently skips
  pushes. Prove by actually triggering a build and confirming paths arrive.
- Timers: if the right owner is ambiguous, surface the question before committing
  rather than defaulting to the host file.
- Access model (Phase 4): changing from direct ports to Tailscale Serve affects
  all service URLs. Make the decision explicitly.
- Exit node: `useRoutingFeatures = "server"` enables IP forwarding; verify this
  does not break existing Tailscale connectivity.

## Definition of Done

- Every phase of the original draft (except backup) classified and resolved
- Working tree clean
- Grafana healthy on aurelius and reachable from predator with runtime proof
- `attic-watch-store.service` gone from predator; post-build-hook pushes correctly
- Service-owned timers active on aurelius
- aurelius proved as Tailscale exit node from predator
- Private host override enforces `mutableUsers = false` and authorized keys
- Bootstrap runbook complete for all services
- All completed plans archived
- `./scripts/run-validation-gates.sh all` passes
- `./scripts/check-docs-drift.sh` passes
- `./scripts/check-repo-public-safety.sh` passes
