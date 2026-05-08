# Repository Audit Report — 2025-05-08

Deep audit of the NixOS repository against its documented philosophy,
architecture, and code standards.

## Executive Summary

The repository follows the **dendritic pattern on `flake-parts` + `import-tree`**
consistently and maturely. The architecture is well documented, all validation
gates pass, and the "explicit over implicit" philosophy is respected in the vast
majority of the codebase. A small number of inconsistencies were found — none
critical.

## Strengths (Philosophy Well Applied)

| Aspect                                                                            | Status                      |
| --------------------------------------------------------------------------------- | --------------------------- |
| No `specialArgs` / `extraSpecialArgs`                                             | ✅ Zero usage               |
| No `openssh.authorizedKeys` in tracked files                                      | ✅                          |
| No `environment.systemPackages` in `hardware/`                                    | ✅                          |
| No hardcoded usernames in features/hosts (only `config.username`)                 | ✅                          |
| `_module.args` isolated to cerebelo only (nixos-rk3588 bridge)                    | ✅ Documented and justified |
| Feature filenames match published module names                                    | ✅ Gate passes              |
| `_`-prefixed files do not publish `flake.modules`                                 | ✅                          |
| Options declared only in features, nixos.nix, and users/                          | ✅ Gate passes              |
| All host imports point to real published modules                                  | ✅ Zero dead references     |
| All `config/apps/` directories consumed by modules                                | ✅                          |
| No `mkIf` used for role/context checks                                            | ✅                          |
| No private data (IPs, emails, tokens) in tracked files                            | ✅ Gate passes              |
| All HM modules that need `inputs` capture it at top-level                         | ✅                          |
| All structure validation gates pass                                               | ✅                          |
| `home-manager-settings` imported by all hosts                                     | ✅                          |
| `home.packages` only in HM blocks                                                 | ✅                          |
| Private imports only via `builtins.pathExists` in hardware/default.nix and users/ | ✅                          |

## Issues Found

### 3.1 🔴 Doc Drift: `config/apps/mpd/` and `config/apps/rmpc/` documented as "copy-once" but are declarative

**Location:** `docs/for-agents/001-repo-map.md`

**Doc says:**

> `config/apps/mpd/` — tracked MPD config provisioned by copy-once
> `config/apps/rmpc/` — tracked rmpc config provisioned by copy-once

**Actual code** (`modules/features/desktop/music-client.nix`):

```nix
xdg.configFile."mpd/mpd.conf".source = builtins.path { ... };
xdg.configFile."rmpc/config.ron".source = builtins.path { ... };
```

These use `xdg.configFile.*.source` (declarative/symlink), **not** `mkCopyOnce`.
The AGENTS.md "Mutable copy-once configs" section also lists `mpd` and `rmpc`
as copy-once, but the code uses declarative provisioning.

**Severity:** Medium (misleading documentation; parity checks may produce false alarms)

### 3.2 🟡 `opencode.json` tracked but undocumented

**Location:** `/home/higorprado/nixos/opencode.json`

Opencode (LLM agent) configuration is tracked in git but:

- Not mentioned in `docs/for-agents/001-repo-map.md`
- Not mentioned in `README.md`
- Not in the top-level layout of the repo-map

This is a developer tool config — it may be personal and should either be
documented or gitignored.

**Severity:** Low

### 3.3 🟡 `templates/` directory undocumented in repo-map

**Location:** `/home/higorprado/nixos/templates/` with 4 `.tpl` files

The repo-map documents `modules/templates.nix` (flake template outputs for
devenv) but does not document the `templates/` directory (host skeleton
templates used by `scripts/new-host-skeleton.sh`).

**Severity:** Low (documentation gap)

### 3.4 🟡 Inconsistent Fish abbreviation pattern across hosts

| Host       | Pattern                                                                              |
| ---------- | ------------------------------------------------------------------------------------ |
| `predator` | `let operatorFishAbbrs = { ... };` → `programs.fish.shellAbbrs = operatorFishAbbrs;` |
| `aurelius` | Inline `programs.fish.shellAbbrs = { ... };`                                         |
| `cerebelo` | Inline `programs.fish.shellAbbrs = { ... };`                                         |

Additionally, `mkPredatorConfig` parameterizes `nixosDesktop` and `hmDesktop`
but is called with the same values already defined — the abstraction exists for
alternative compositions that are not currently used.

**Severity:** Low (style inconsistency)

### 3.5 🟡 Public DNS IPs hardcoded in AIOStreams module

**Location:** `modules/features/media/aiostreams.nix:26-27`

```nix
"--dns=1.1.1.1"
"--dns=8.8.8.8"
```

Not private IPs — accepted by the public-safety allowlist — but not
configurable.

**Severity:** Very low (cosmetic)

### 3.6 🟡 Aurelius missing `attic-client` HM module

Aurelius runs the Attic server but the user does not have `attic-client` as an
HM tool. The NixOS-level `attic-publisher` works via `lib.getExe' pkgs.attic-client`,
so the server functions correctly. The gap is only in interactive use.

**Severity:** Low (UX gap, may be intentional)

### 3.7 🟡 `backup-service` only imported on Predator

`homeManager.backup-service` is imported only by predator. Aurelius and cerebelo
have no backup of SSH keys/GPG. May be intentional (servers have different
backup strategies).

**Severity:** Very low

## Quantitative Summary

| Metric                      | Value                            |
| --------------------------- | -------------------------------- |
| Hosts                       | 3 (predator, aurelius, cerebelo) |
| Feature modules (published) | ~58                              |
| `_`-private modules         | 3                                |
| Split modules (nixos + HM)  | 11                               |
| NixOS-only modules          | 33                               |
| HM-only modules             | 33                               |
| Declared inputs             | 18                               |
| Validation gate scripts     | 16                               |
| Issues found                | 7 (0 critical, 1 medium, 6 low)  |

## Recommendations

1. Fix mpd/rmpc doc to say "declarative" instead of "copy-once" — or convert
   them to copy-once if runtime mutability is desired.
2. Decide on `opencode.json`: gitignore or document.
3. Document `templates/` in repo-map under the extensibility/onboarding section.
4. Simplify `mkPredatorConfig` or document the planned alternative compositions.
5. Consider adding `homeManager.attic-client` to aurelius for interactive use.
6. Evaluate whether mpd/rmpc should be copy-once (as doc implies) — declarative
   overwrites local changes on every HM activation.
