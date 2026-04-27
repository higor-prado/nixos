# Lessons Learned

## Rules
0. Write important lessons you learned in `999-lessons-learned.md`.
1. Keep lessons short and direct.
2. Never modify private override files unless explicitly asked.
3. Never force a concrete desktop composition on a host without explicit request.
4. Keep risky changes in small, reversible slices.
5. Validate runtime behavior, not only successful builds or evals.
6. Confirm rollback path before applying login, session, display-manager, or access changes.
7. Treat scope constraints literally, for example branch vs new repo.
8. If a change affects system access or login, prioritize recovery first, then feature work.
9. When adopting an upstream flake app, verify the package actually builds; HEAD can be broken.
10. Keep root `docs/for-agents/` for durable operating docs, active work in `plans/` and `current/`, and completed work in `archive/`.
11. Docs drift checks should target bounded living docs, not historical archives.
12. For this repo/user, prioritize performance and compatibility over ideology/licensing preferences when choosing technical paths.
13. For local validation that must see the live working tree, prefer `builtins.getFlake "path:$PWD"` over git refs.
14. Dendritic rule: context shape is the condition. Feature inclusion in a host is the condition. Do not add role selectors, synthetic `enable` booleans, host bridges, or parallel metadata just to help validation or scripts.
15. Use `mkIf` for conditions that depend on `config`; do not use eager `optionalAttrs` there.
16. Keep one canonical validation runner and make wrappers delegate to it.
17. Keep tracked host defaults generic/public-safe; private keys, tokens, and sudo exceptions belong in untracked private overrides.
18. When a failure touches ownership, structure, or architecture, stop and understand the real cause before editing; get explicit human validation before changing those boundaries.
19. Name owners after user-facing capabilities, match feature filenames to published module names, and delete dead feature paths instead of preserving unused code.
20. Canonical tracked runtime facts live in the repo-local dendritic surface: concrete systems under `configurations.nixos.*.module`, repo-wide user facts under `username`, and tracked user ownership under `modules/users/<user>.nix`.
21. Home Manager modules should be published under `flake.modules.homeManager.*` and wired concretely by the host. Host-aware HM code should use direct flake inputs, narrow top-level facts, or existing lower-level state; do not build repo-local routing batteries.
22. New files under `modules/` must be `git add`-ed before `nix eval`; the auto-import path only sees tracked files.
23. Generic helpers belong in root `lib/`, not in private or feature subtrees.
24. `hardware/<host>/default.nix` owns only machine-specific hardware imports and defaults; `modules/hosts/` owns host composition and operator wiring.
25. Desktop composition duplication is intentional explicitness. Keep complete compositions visible.
26. Parameterize only when multiple real values exist. Single-value enums and speculative knobs are architectural noise.
27. For system-owned user services that only need per-user overrides, prefer Home Manager drop-ins instead of partial HM unit redefinitions.
28. `nixpkgs.config` policy belongs in dedicated policy features like `core/nixpkgs-settings.nix`, not in hardware files or incidental owners.
29. Split bundle features when hosts need different subsets; avoid `mkForce`-driven bundles when host inclusion can be the condition.
30. Universal lower-level modules should be published once under `flake.modules.*` and imported consistently. Major upstream imports that materially shape a host should stay explicit in the host composition.
31. Server-specific policy belongs in dedicated published features, not inline in host blocks. Host files should stay focused on concrete imports, operator commands, and host-owned entitlements.
32. Historical migration material is secondary. Use `~/git/dendritic` as the pattern reference for canonical runtime decisions.
33. Host-operator shell commands that reference a concrete machine, repo checkout, or remote target belong in the concrete host module, not in shared shell features.
34. When replacing an old framework battery, restore behavior explicitly; syntax migration alone is not parity.
35. Keep repo-wide user semantics narrow. Base account shape and cross-host admin semantics belong in `modules/users/<user>.nix`; host-specific groups belong in the concrete host module.
36. Service semantics belong in the service owner.
37. A service slice is not complete until the real consumer path is proved from the intended consumer host.
38. When recovering a false-done service slice, treat removal of the bad version as integrity repair only. Delivery happens only after clean owner shape and real consumer proof.
39. When a feature depends on private binding, add at least one synthetic eval with fake non-secret values before claiming the owner shape is correct.
40. When a regression appears after touching a subsystem, isolate that subsystem first. Prove or eliminate it before broadening the search.
41. Do not add background automation, corrective behavior, or continuous checks as “resilience” unless the failure mode, expected benefit, and operational cost are all evidenced.
42. When a hardware bootstrap path has an official upstream board stack, freeze that upstream contract first; do not keep iterating on generic boot guesses after the first mismatch.
43. Package ownership should follow the real owner: machine/runtime packages go to NixOS, user-interactive packages go to Home Manager, and mixed capabilities should be split instead of using `environment.systemPackages` as a catch-all.

44. Waybar tray `icons` mapping matches by the SNI **`Id`** property (e.g. `nm-applet`, `udiskie`), NOT by the changing `IconName` property (e.g. `nm-signal-75`). Use `busctl --user get-property ... org.kde.StatusNotifierItem Id` to discover the correct key. Confirmed via `strace` on waybar: the mapping lookup happens on Id, while IconName-based keys are silently ignored.
45. When debugging icon/theme resolution, `strace -e trace=openat -f` on the actual process reveals exactly which files GTK opens and in what order. This is more reliable than guessing icon names or checking theme indexes manually.
46. Symbolic SVGs in GTK icon themes use `fill:currentColor` and are tinted by the widget's CSS `color` property. Non-symbolic (colored) SVGs in `panel/` directories are NOT affected by CSS color. Always map to `-symbolic` variants for CSS tinting.
47. Do not assume a feature works because a user says it does. Verify the mechanism independently. In the tray icon case, the bluetooth mapping appeared to work but was actually matching by `Id` (`blueman`), not by `IconName` (`blueman-active`). Understanding the actual mechanism was required to replicate success on other items.
48. When a StatusNotifierItem advertises an app-local `IconThemePath`, Waybar may bypass the GTK icon theme entirely and open the app-shipped asset from that path. In that case, theme-side SVG alias patching is dead code; keep the remediation with the app owner, and prove it with `strace -e trace=openat` before changing theme or tray mappings.

---
> ### ⚠ RULE 999 — AGENT OWNS THE WHOLE REPO
> **The agent is responsible for the whole repo, not only the changes it is currently making.**
> When a validation gate, test, or eval reveals a failure — even one that predates the current
> task — do **NOT** silently label it "pre-existing" and proceed.
> **Stop. Surface it to the human. Ask: "I found this failure — is it known? Fix it now or track it separately?"**
> Wait for explicit direction. Do not fix it unilaterally (out-of-scope), but do not pretend it is not there either.
---
