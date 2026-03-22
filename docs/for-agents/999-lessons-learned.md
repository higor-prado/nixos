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
13. Dendritic repo philosophy: the context shape is the condition. Feature inclusion in a host is the condition. Do not reintroduce `custom.host.role` or any similar role selector into the runtime just to satisfy validation scripts.
14. In Nix modules, use `mkIf` instead of eager `optionalAttrs` for conditions that depend on `config`, otherwise fixed-point evaluation can recurse.
15. Keep one canonical validation runner and make CI/local wrappers delegate to it.
16. Docs drift checks should target a bounded living-docs set; scanning all historical docs creates false failures and discourages maintenance.
17. For server onboarding, keep tracked host defaults generic/public-safe and move account keys or sudo exceptions into untracked private overrides.
18. When a test fails or ownership/architecture placement is disputed, stop execution and understand the real cause before changing code. If the fix would affect ownership, structure, or expected architecture, get explicit human validation before applying it.
19. In feature migrations or reorganizations, name owner files after user-facing capabilities and avoid abstract buckets that hide ownership.
20. If no tracked host selects a leftover feature path, delete it instead of preserving dead code, dead flake inputs, or speculative architecture.
21. Canonical outputs now come from the repo-local dendritic runtime. The repo-wide tracked user lives under `username`, and concrete systems under `configurations.nixos.*.module`.
22. Home Manager modules should be published under `flake.modules.homeManager.*` and wired concretely by the host. HM-specific APIs such as `lib.hm.dag.entryAfter` and `config.xdg.configHome` are available inside those lower-level HM modules.
23. Canonical tracked user definition now lives in `modules/users/<user>.nix` as published `flake.modules.nixos.<user>` and `flake.modules.homeManager.<user>` modules plus the repo-wide `username` fact.
24. New files under `modules/` must be `git add`-ed before `nix eval` — the repo's auto-import path only sees git-tracked files.
25. Do not mirror feature inclusion into dedicated `custom.<feature>.enable` booleans just for validation. Prefer checking real configuration state or declared topology directly.
26. Generic helpers belong in root `lib/`, not in repo-specific private or feature subtrees.
27. Root `hosts/` was retired in favor of `hardware/` for machine-specific files; `modules/hosts/` is the top-level host owner and configuration layer.
28. `hardware/<host>/default.nix` owns only machine-specific hardware imports and defaults. Script-only classifications must not leak back into the runtime surface.
29. Desktop composition baseline duplication is intentional explicitness in this repo's composition model. Each composition owns its complete baseline for clarity.
30. Do not keep parallel host metadata files just to help scripts. Tooling must derive host facts from the real repo structure, not the other way around.
31. Speculative parameterization options should exist only when multiple real values are supported. A single-value enum option is architectural noise.
32. Do not build a repo-local `config.host.*`, `repo.context`, or HM `_module.args.host` bridge. Host-aware lower-level modules should use explicit top-level facts, direct flake inputs captured by the owner, or existing lower-level state.
33. For system-owned user services that only need per-user overrides, prefer Home Manager drop-ins via `xdg.configFile."systemd/user/<unit>.service.d/override.conf"` instead of redefining partial `systemd.user.services.<name>` units in HM.
34. `nixpkgs.config.allowUnfree` and other `nixpkgs.config` settings belong in a dedicated `core/nixpkgs-settings.nix` feature, not as a side-effect of a hardware file. Hardware files can be refactored or removed; policy settings must be independently traceable.
35. Feature file names should match at least one published lower-level module name they define. A mismatched filename creates confusion when cross-referencing host imports against the filesystem.
36. Split bundle features when hosts need different subsets. A feature that bundles fstrim + smartd requires a `mkForce` override on servers with no physical disks. Separate features let host inclusion be the condition, eliminating the only reason for `mkForce` in the codebase.
37. Upstream module imports that materially shape a concrete host session or system should stay explicit in the host composition. Do not hide major host composition edges behind framework-like helpers just to reduce import lines.
38. If a lower-level module is meant to be universal, publish it once under `flake.modules.*` and import it consistently from each concrete host module. Do not recreate implicit global include layers unless they buy real simplicity.
39. Server-specific policy (mutableUsers, no autologin, no documentation, SSH hardening) belongs in a dedicated published feature module, not inline in a host block. Host files should stay focused on concrete imports, operator wiring, and host-owned entitlements.
40. In the local runtime, host-aware Home Manager is just another lower-level HM module. It should use direct flake inputs captured by the owner, narrow facts such as `config.username`, or existing lower-level state; no mutual-routing battery is needed in the canonical path.
41. Keep historical migration material clearly secondary. Do not let old compatibility stories override the canonical dendritic runtime.
42. Use `~/git/dendritic` as the pattern reference. Historical framework-specific material is for migration/audit context only; canonical runtime decisions should be validated against the repo-local top-level modules first.
43. Host-operator shell commands that reference a concrete machine, repo checkout, or remote target belong in the concrete host module, not in the shared shell feature.
44. When replacing an old framework battery, restore its behavior explicitly in the new owner. Syntax migration alone is not parity if semantic effects like primary-user admin groups disappear.
45. Keep repo-wide user semantics narrow. Base account shape and truly cross-host admin semantics belong in `modules/users/<user>.nix`; host-specific groups like device or service access belong in the concrete host module.
46. Keep the active docs surface small. Completed plans/logs belong in `archive/`; living docs should describe the current repo, not retell the migration.
47. For service slices, keep service semantics in the service owner. URLs, bind policy, and service-specific firewall openings do not belong in the host file unless they are genuinely host-only facts rather than service behavior.
48. A service slice is not complete until the intended consumer path is proved from the real consumer host. Host-local `systemd` health and localhost `curl` only prove the host side.
49. When a service slice is recovered from a false-done state, treat “remove the bad version” as integrity repair only. Delivery happens only after the clean owner shape and the real consumer path are both proved.
50. When a feature is gated behind private binding, add at least one synthetic eval with a fake non-secret binding before claiming the owner shape is correct. Lazy `mkIf` paths can hide broken references until the real binding appears.

---
> ### ⚠ RULE 999 — AGENT OWNS THE WHOLE REPO
> **The agent is responsible for the whole repo, not only the changes it is currently making.**
> When a validation gate, test, or eval reveals a failure — even one that predates the current
> task — do **NOT** silently label it "pre-existing" and proceed.
> **Stop. Surface it to the human. Ask: "I found this failure — is it known? Fix it now or track it separately?"**
> Wait for explicit direction. Do not fix it unilaterally (out-of-scope), but do not pretend it is not there either.
---
