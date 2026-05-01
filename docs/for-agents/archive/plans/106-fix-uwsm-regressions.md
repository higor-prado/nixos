# Fix UWSM Regressions — start-hyprland + App Launching + NVIDIA VRAM

## Goal

Fix the Hyprland `start-hyprland` warning, verify UWSM app-launching compatibility
with Hyprland binds, and confirm NVIDIA VRAM profiles survive the migration.

## Analysis Results

### 1. Hyprland warning fix (trivial)

**Current:** `--cmd "uwsm start -F -- Hyprland"`  
**Fix:** `--cmd "uwsm start -F -- start-hyprland"`

`start-hyprland` is a compiled binary from the Hyprland package that:
- Checks Nix environment (`nixEnvironmentOk()`, `shouldUseNixGL()`)
- Sets up env vars specific to Nix/Hyprland
- Then execs the actual Hyprland binary

UWSM wraps around it: `uwsm start` sets up systemd session units, then
launches `start-hyprland`, which in turn launches Hyprland. Both layers
work together — UWSM owns the session lifecycle, start-hyprland owns
the Nix environment setup.

### 2. Hyprland binds — no changes needed

All binds use `hl.dsp.exec_cmd("program")`:
```
kitty, firefox, nautilus, zeditor, code, obsidian, emacsclient,
teams-for-linux, steam, spotify, walker
```

When Hyprland runs under UWSM, child processes inherit the cgroup from
`wayland-wm@Hyprland.service` → already in the UWSM session tree.
`uwsm app` wrapping is an optional enhancement for sub-slice placement
(`app-graphical.slice` vs `background-graphical.slice`) — not required
for basic session management.

Walker/Elephant are systemd user services — already properly managed by
UWSM's `graphical-session.target` via `PartOf` + `WantedBy`.

### 3. NVIDIA VRAM profiles — unaffected

The profiles match by `procname` (executable basename):
```
.Hyprland-wrapped, .walker-wrapped, .zed-editor-wrapped,
firefox, code, Xwayland
```

UWSM does not rename or wrap process names. The actual binaries are the
same. Confirmed on live system:
- `.Hyprland-wrapped` still running under uwsm ✅
- `firefox`, `code`, `Xwayland` unchanged ✅

## Scope

In scope:
- Fix greetd command: `Hyprland` → `start-hyprland`

Out of scope:
- Changing any Hyprland bind
- Adding `uwsm app` wrapping (optional enhancement, not a regression)
- Modifying NVIDIA profiles

## Phases

### Phase 1: Fix greetd command

**File:** `modules/features/desktop/greetd.nix`

Change:
```diff
-            command = "${tuigreet} --time --remember --remember-session --asterisks --cmd \"uwsm start -F -- Hyprland\"";
+            command = "${tuigreet} --time --remember --remember-session --asterisks --cmd \"uwsm start -F -- start-hyprland\"";
```

Validation:
- `nix eval path:$PWD#nixosConfigurations.predator.config.services.greetd.settings.default_session.command`
- Must contain `start-hyprland`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`

### Phase 2: Validate no Hyprland warning after switch

Post-switch, check journal:
```bash
journalctl -b --no-pager | grep "start-hyprland\|WARNING.*launched without"
```
No warning should appear.

### Phase 3: Verify NVIDIA VRAM profile matches

Post-switch, confirm process names match:
```bash
ps aux | grep -E "Hyprland|walker|zed|firefox|code|Xwayland" | grep -v grep
```
All process names should match their NVIDIA profile patterns.

## Risks

- **start-hyprland binary**: Already confirmed present at
  `/run/current-system/sw/bin/start-hyprland` (comes with `programs.hyprland.package`).
  UWSM will find it on PATH since `--cmd` runs in the user session environment.

## Definition of Done

- [ ] greetd command uses `start-hyprland` instead of bare `Hyprland`
- [ ] Predator evals
- [ ] Validation gates pass
- [ ] Zero Hyprland warnings about missing start-hyprland after next switch
- [ ] NVIDIA VRAM profile matches confirmed on live system
