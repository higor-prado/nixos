# Lessons Learned

## Rules
0. Write important lessons you learned in `999-lessons-learned.md`.
1. Keep lessons short and direct.
2. Never modify private override files unless explicitly asked.
3. Never force a concrete desktop composition on a host without explicit request.
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
21. Canonical outputs now come from the repo-local dendritic runtime. Host inventory lives under `repo.hosts.*`, tracked users under `repo.hosts.<host>.trackedUsers`, and concrete systems under `configurations.nixos.*.module`.
22. Home Manager modules should be published under `flake.modules.homeManager.*` and wired concretely by the host. HM-specific APIs such as `lib.hm.dag.entryAfter` and `config.xdg.configHome` are available inside those lower-level HM modules.
23. Canonical tracked user definition now lives in `modules/users/<user>.nix` as published `flake.modules.nixos.<user>` and `flake.modules.homeManager.<user>` modules plus `repo.users.<user>` inventory.
24. New files under `modules/` must be `git add`-ed before `nix eval` — the repo's auto-import path only sees git-tracked files.
25. Do not mirror feature inclusion into dedicated `custom.<feature>.enable` booleans just for validation. Prefer checking real configuration state or declared topology directly.
26. Generic helpers belong in root `lib/`, not in subtrees like `private/` or former `home/base/lib/`.
27. Root `hosts/` was retired in favor of `hardware/` for machine-specific files; `modules/hosts/` is the top-level host inventory and configuration layer.
28. Host ownership contract: `hardware/<host>/default.nix` owns `custom.host.role`, while `modules/hosts/<host>.nix` must declare at least one tracked host user under `repo.hosts.<host>.trackedUsers`. `custom.user.name` is only a narrowed compatibility bridge.
29. Desktop composition baseline duplication is intentional explicitness in this repo's composition model. Each composition owns its complete baseline for clarity.
30. `hardware/host-descriptors.nix` is script-only integration metadata. Do not mirror runtime host facts there unless a real script consumer needs them.
31. Speculative parameterization options should exist only when multiple real values are supported. A single-value enum option is architectural noise.
32. Do not build a repo-local `config.host.*` or HM `_module.args.host` bridge. Host-aware lower-level modules should read runtime facts from `config.repo.context.*`.
33. For system-owned user services that only need per-user overrides, prefer Home Manager drop-ins via `xdg.configFile."systemd/user/<unit>.service.d/override.conf"` instead of redefining partial `systemd.user.services.<name>` units in HM.
34. `nixpkgs.config.allowUnfree` and other `nixpkgs.config` settings belong in a dedicated `core/nixpkgs-settings.nix` feature, not as a side-effect of a hardware file. Hardware files can be refactored or removed; policy settings must be independently traceable.
35. Feature file names should match the aspect name they define. The aspect name is the public API used in host `includes` lists; a mismatched filename creates confusion when cross-referencing includes against the filesystem.
36. Split bundle features when hosts need different subsets. A feature that bundles fstrim + smartd requires a `mkForce` override on servers with no physical disks. Separate features let host inclusion be the condition, eliminating the only reason for `mkForce` in the codebase.
37. When a feature is parametric and captures `{ host, ... }`, declare `imports = [host.inputs.X.nixosModules.Y]` inside the parametric nixos block rather than in the host file. This makes the feature self-contained and keeps host composition limited to aspect names in `includes`.
38. If a lower-level module is meant to be universal, publish it once under `flake.modules.*` and import it consistently from each concrete host module. Do not recreate implicit global include layers unless they buy real simplicity.
39. Server-specific policy (mutableUsers, no autologin, no documentation, SSH hardening) belongs in a dedicated published feature module, not inline in a host block. Host files should stay focused on inventory plus concrete imports.
40. In the local runtime, host-aware Home Manager is just another lower-level HM module that reads `config.repo.context.host`; no mutual-routing battery is needed in the canonical path.
41. Keep historical migration material clearly secondary. Do not let old compatibility stories override the canonical dendritic runtime.
42. Use `~/git/dendritic` as the pattern reference. Historical framework-specific material is for migration/audit context only; canonical runtime decisions should be validated against the repo-local top-level modules first.

---
> ### ⚠ RULE 999 — AGENT OWNS THE WHOLE REPO
> **The agent is responsible for the whole repo, not only the changes it is currently making.**
> When a validation gate, test, or eval reveals a failure — even one that predates the current
> task — do **NOT** silently label it "pre-existing" and proceed.
> **Stop. Surface it to the human. Ask: "I found this failure — is it known? Fix it now or track it separately?"**
> Wait for explicit direction. Do not fix it unilaterally (out-of-scope), but do not pretend it is not there either.
---
