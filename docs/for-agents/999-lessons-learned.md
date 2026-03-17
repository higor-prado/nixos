# Lessons Learned

## Rules
0. Write important lessons you learned in `999-lessons-learned.md`.
1. Keep lessons short and direct.
2. Never modify private override files unless explicitly asked.
3. Never switch a host through hidden desktop selector options or force a concrete desktop composition without explicit request.
4. Keep risky changes in small, reversible slices.
5. Validate runtime behavior, not only successful builds or evals.
6. Confirm rollback path before applying login, session, or display-manager changes.
7. Treat scope constraints literally, for example branch vs new repo.
8. If a change affects system access or login, prioritize recovery first, then feature work.
9. When adopting an upstream flake app, verify the flake package actually builds; HEAD can be temporarily broken.
10. Keep root `docs/for-agents/` for durable operating docs. Put active execution plans under `docs/for-agents/plans/`, active progress logs under `docs/for-agents/current/`, and archive completed execution docs under `docs/for-agents/archive/`.
11. For this repo/user, prioritize performance and compatibility over ideology/licensing preferences when choosing technical paths.
12. For local matrix/validation scripts, prefer `builtins.getFlake "path:$PWD"` over git URL refs when you need live working-tree behavior; git/index snapshots can hide unstaged fixes.
13. Den philosophy: the context shape is the condition. Feature inclusion in a host is the condition. Do not use `custom.host.role` as a conditional inside feature or hardware modules; `custom.host.role` is only a contract signal for validation scripts.
14. In Nix modules, use `mkIf` instead of eager `optionalAttrs` for conditions that depend on `config`, otherwise fixed-point evaluation can recurse.
15. Keep one canonical validation runner and make CI/local wrappers delegate to it.
16. Docs drift checks should target a bounded living-docs set; scanning all historical docs creates false failures and discourages maintenance.
17. For server onboarding, keep tracked host defaults generic/public-safe and move account keys or sudo exceptions into untracked private overrides.
18. When a test fails or ownership/architecture placement is disputed, stop execution and understand the real cause before changing code. If the fix would affect ownership, structure, or expected architecture, get explicit human validation before applying it.
19. In feature migrations or reorganizations, name owner files after user-facing capabilities and avoid abstract buckets that hide ownership.
20. If no tracked host selects a leftover feature path, delete it instead of preserving dead code, dead flake inputs, or speculative architecture.
21. `vic/den` has a native `.homeManager` aspect class. User registration via `den.hosts.<sys>.<host>.users.<user>.classes = [ "homeManager" ]` auto-routes each aspect's `.homeManager` to `home-manager.users.<userName>`. No `hasHomeManagerUsers` guard is needed.
22. In den-native `.homeManager` functions, HM-specific APIs such as `lib.hm.dag.entryAfter` and `config.xdg.configHome` are available directly.
23. `den._.define-user`, `den._.primary-user`, and `den._.user-shell "<shell>"` should own canonical user definition, primary-user groups, and shell wiring in tracked user aspects.
24. New files under `modules/` must be `git add`-ed before `nix eval` — den's import-tree only sees git-tracked files.
25. Do not mirror feature inclusion into dedicated `custom.<feature>.enable` booleans just for validation. Prefer checking real configuration state or declared topology directly.
26. Generic helpers belong in root `lib/`, not in subtrees like `private/` or former `home/base/lib/`.
27. Root `hosts/` was retired in favor of `hardware/` for machine-specific files; `modules/hosts/` is the den composition layer.
28. Host ownership contract: `hardware/<host>/default.nix` owns `custom.host.role`, while `modules/hosts/<host>.nix` must declare at least one tracked host user under `den.hosts.<system>.<host>.users`. `custom.user.name` is only a narrowed compatibility bridge.
29. Desktop composition baseline duplication is intentional explicitness per den philosophy. Each composition owns its complete baseline for clarity.
30. `hardware/host-descriptors.nix` is script-only integration metadata. Do not mirror runtime host facts there unless a real script consumer needs them.
31. Speculative parameterization options should exist only when multiple real values are supported. A single-value enum option is architectural noise.
32. Do not build a repo-local `config.host.*` or HM `_module.args.host` bridge. Use den parametric includes and capture `{ host, ... }` directly where host-aware logic is needed.
33. For system-owned user services that only need per-user overrides, prefer Home Manager drop-ins via `xdg.configFile."systemd/user/<unit>.service.d/override.conf"` instead of redefining partial `systemd.user.services.<name>` units in HM.
34. After den's March 13, 2026 bidirectional change, do not assume host aspects implicitly re-run with `{ host, user }` at the OS layer. Use `den._.bidirectional` only when that reentry is explicitly wanted, and otherwise keep HM/NixOS fragments on the narrowest correct context shape.
35. `nixpkgs.config.allowUnfree` and other `nixpkgs.config` settings belong in a dedicated `core/nixpkgs-settings.nix` feature, not as a side-effect of a hardware file. Hardware files can be refactored or removed; policy settings must be independently traceable.
36. Feature file names should match the aspect name they define. The aspect name is the public API used in host `includes` lists; a mismatched filename creates confusion when cross-referencing includes against the filesystem.
37. Split bundle features when hosts need different subsets. A feature that bundles fstrim + smartd requires a `mkForce` override on servers with no physical disks. Separate features (`modules/features/system/maintenance.nix` for fstrim, `modules/features/system/maintenance-smartd.nix` for smartd) let host inclusion be the condition, eliminating the only reason for `mkForce` in the codebase.
38. When a feature is parametric and captures `{ host, ... }`, declare `imports = [host.inputs.X.nixosModules.Y]` inside the parametric nixos block rather than in the host file. This makes the feature self-contained and keeps host composition limited to aspect names in `includes`.
39. Use `den.default.includes` (declared in `modules/features/core/den-defaults.nix`) for aspects that must be present on every host. Do not repeat them in individual host `includes` lists.
40. Server-specific policy (mutableUsers, no autologin, no documentation, SSH hardening) belongs in a `server-base` aspect, not inline in a host's `nixos` block. Host files should be pure composition lists.
41. Under `den._.bidirectional`, a host-aspect's `includes` functions fire with BOTH `{host}` and `{host,user}` contexts. Use `den.lib.perHost ({ host }:)` for nixos-only includes and `den.lib.take.atLeast ({ host, user }:)` for homeManager-only includes. Never bare `{ host, ... }:` in host-aspect includes — it fires in both contexts, duplicating NixOS options and packages. `den.lib.parametric` is required whenever an aspect has context-dependent `includes`; do not omit it.
42. A local den clone (e.g. `~/git/den`) may be behind the version pinned in flake.lock. Before auditing den APIs or searching den source, do `git -C ~/git/den pull` (or fetch the remote) to bring it up to date, OR use the pinned nix store source directly: `nix flake metadata . --json | jq -r '.locks.nodes.den.path'` gives the store path. Never assume the local clone matches what the flake actually uses.

---
> ### ⚠ RULE 999 — AGENT OWNS THE WHOLE REPO
> **The agent is responsible for the whole repo, not only the changes it is currently making.**
> When a validation gate, test, or eval reveals a failure — even one that predates the current
> task — do **NOT** silently label it "pre-existing" and proceed.
> **Stop. Surface it to the human. Ask: "I found this failure — is it known? Fix it now or track it separately?"**
> Wait for explicit direction. Do not fix it unilaterally (out-of-scope), but do not pretend it is not there either.
---
