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
13. Do not use `custom.host.role` as a conditional inside feature or hardware modules. `custom.host.role` is a contract signal for validation scripts; feature inclusion via `modules/hosts/<host>.nix` is the den condition.
14. In Nix modules, use `mkIf` instead of eager `optionalAttrs` for conditions that depend on `config`, otherwise fixed-point evaluation can recurse.
15. Keep one canonical validation runner and make CI/local wrappers delegate to it.
16. Runtime smoke checks should fail only on high-confidence regressions and treat noisy warnings as thresholded signals.
17. Docs drift checks should target a bounded living-docs set; scanning all historical docs creates false failures and discourages maintenance.
18. For server onboarding, keep tracked host defaults generic/public-safe and move account keys or sudo exceptions into untracked private overrides.
19. When ownership or architecture placement is disputed, stop execution, re-read AGENTS plus ownership contracts, and update the plan before writing more code.
20. In feature migrations or reorganizations, name owner files after user-facing capabilities and avoid abstract buckets that hide ownership.
21. If no tracked host selects a leftover feature path, delete it instead of preserving dead code and dead flake inputs.
22. `vic/den` has a native `.homeManager` aspect class. User registration via `den.hosts.<sys>.<host>.users.<user>.classes = [ "homeManager" ]` auto-routes each aspect's `.homeManager` to `home-manager.users.<userName>`. No `hasHomeManagerUsers` guard is needed.
23. In den-native `.homeManager` functions, HM-specific APIs such as `lib.hm.dag.entryAfter` and `config.xdg.configHome` are available directly.
24. Den philosophy: the context shape is the condition. Feature inclusion in a host is the condition. Do not use role-based conditionals inside feature aspects.
25. `den._.define-user`, `den._.primary-user`, and `den._.user-shell "<shell>"` should own canonical user definition, primary-user groups, and shell wiring in tracked user aspects.
26. New files under `modules/` must be `git add`-ed before `nix eval` — den's import-tree only sees git-tracked files.
27. Do not mirror feature inclusion into dedicated `custom.<feature>.enable` booleans just for validation. Prefer checking real configuration state or declared topology directly.
28. Generic helpers belong in root `lib/`, not in subtrees like `home/base/lib/`.
29. Root `hosts/` was retired in favor of `hardware/` for machine-specific files; `modules/hosts/` is the den composition layer.
30. Host ownership contract: `hardware/<host>/default.nix` owns `custom.host.role`, while `modules/hosts/<host>.nix` must declare at least one tracked host user under `den.hosts.<system>.<host>.users`. `custom.user.name` is only a narrowed compatibility bridge.
31. Desktop composition baseline duplication is intentional explicitness per den philosophy. Each composition owns its complete baseline for clarity.
32. `hardware/host-descriptors.nix` is script-only integration metadata. Do not mirror runtime host facts there unless a real script consumer needs them.
33. A feature never selected by any host is dead code. Delete it instead of preserving speculative architecture.
34. Speculative parameterization options should exist only when multiple real values are supported. A single-value enum option is architectural noise.
35. Do not build a repo-local `config.host.*` or HM `_module.args.host` bridge. Use den parametric includes and capture `{ host, ... }` directly where host-aware logic is needed.
36. For system-owned user services that only need per-user overrides, prefer Home Manager drop-ins via `xdg.configFile."systemd/user/<unit>.service.d/override.conf"` instead of redefining partial `systemd.user.services.<name>` units in HM.
