# Migrate Hyprland to UWSM (Universal Wayland Session Manager)

## Goal

Replace the custom `hyprland-session-start` script and manual session
bootstrap with UWSM, the upstream Wayland session manager that has native
Hyprland integration. UWSM 0.26.4 is already in nixpkgs and nixpkgs'
`programs.hyprland` module has a `withUWSM` toggle.

## Why UWSM?

Currently we maintain:
- Custom `session-bootstrap.lua` (sets env vars, triggers session-start)
- Custom `hyprland-session-start` script (~55 lines of service lifecycle)
- Custom `hyprland-session.target` definition
- Services manually bound to our custom target (`walker.nix`)

UWSM provides all of this out of the box:
- Proper systemd session hierarchy (`graphical-session.target`,
  `wayland-session@.target`)
- Environment setup/cleanup via systemd activation environment
- Bi-directional binding between login session and graphical session
- XDG autostart
- Compositor-aware env files (`uwsm/env-hyprland/*`)
- Graceful shutdown cascade

Nixpkgs already has first-class support:
```nix
programs.hyprland.withUWSM = true;  # enables programs.uwsm.enable
```

## Current State (what we own vs what UWSM would own)

| Concern | Current owner | UWSM replacement |
|---|---|---|
| Session bootstrap | `hyprland-session-start` script | `uwsm start -F -- Hyprland` |
| Env vars on startup | `session-bootstrap.lua` (`hl.env(...)`) | UWSM env preparation unit |
| D-Bus env update | `dbus-update-activation-environment` in script | UWSM handles via dbus-broker |
| Service reset-failed | Manual list of 13 services | UWSM manages service lifecycle |
| Session target | Custom `hyprland-session.target` | `wayland-session@Hyprland.target` (UWSM) |
| Service binding | `PartOf=hyprland-session.target` (walker) | Bind to `graphical-session.target` |
| Greetd command | `--cmd start-hyprland` | `--cmd "uwsm start -F -- Hyprland"` |

## Files that change

### 1. NixOS: Enable UWSM in hyprland module

**File:** `modules/features/desktop/hyprland.nix` (NixOS block)

Change:
```diff
-        withUWSM = false;
+        withUWSM = true;
```

Also add UWSM compositor config:
```nix
programs.uwsm.waylandCompositors.hyprland = {
  prettyName = "Hyprland";
  comment = "Hyprland compositor managed by UWSM";
  binPath = "/run/current-system/sw/bin/Hyprland";
};
```

Note: `binPath` uses the system-wide Hyprland binary from
`/run/current-system/sw/bin/Hyprland`, which is available because
`programs.hyprland.enable = true` adds it to `environment.systemPackages`.

### 2. NixOS: Update greetd command

**File:** `modules/features/desktop/greetd.nix`

Change:
```diff
-            command = "${tuigreet} --time --remember --remember-session --asterisks --cmd start-hyprland";
+            command = "${tuigreet} --time --remember --remember-session --asterisks --cmd \"uwsm start -F -- Hyprland\"";
```

`uwsm start -F -- Hyprland` launches Hyprland via UWSM's session management.
The `-F` flag means "foreground" (required for greetd).

### 3. HM: Remove custom session bootstrap

**File:** `modules/features/desktop/hyprland.nix` (HM block)

Remove:
- The entire `sessionStart` let-binding (~45 lines)
- The `systemd.user.targets.hyprland-session` definition
- The `xdg.configFile."hypr/session-bootstrap.lua"` block

The HM block should keep only:
```nix
wayland.windowManager.hyprland = {
  enable = true;
  package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  systemd.enable = false;  # UWSM manages systemd integration
};
```

### 4. HM: Update walker services

**File:** `modules/features/desktop/walker.nix`

Change service bindings from `hyprland-session.target` to
`graphical-session.target`:

```diff
-            PartOf = [ "hyprland-session.target" ];
-            After = [ "hyprland-session.target" ];
+            PartOf = [ "graphical-session.target" ];
+            After = [ "graphical-session.target" ];
```

Same change for both elephant and walker services (4 occurrences).

### 5. Config: Remove session-bootstrap require

**File:** `config/desktops/hyprland-standalone/hyprland.lua`

Remove the line:
```diff
-require("session-bootstrap")
```

UWSM handles the session setup that this module performed (env vars,
service lifecycle). The hyprland.lua entry point no longer needs it.

### 6. Config: Clean up startup.lua comment

**File:** `config/desktops/hyprland-standalone/modules/startup.lua`

Update comment:
```diff
- -- Startup commands. Session/bootstrap is handled by session-bootstrap.lua.
+ -- Startup commands. Session/bootstrap is handled by UWSM.
```

### 7. Docs: Update repo map

**File:** `docs/for-agents/001-repo-map.md`

Update hyprland.nix description to mention UWSM.

### 8. Docs: Update architecture/ownership docs if needed

Check `docs/for-agents/003-module-ownership.md` for references to
the old session management.

## What stays the same

- greetd display manager (still manages TTY and authentication)
- tuigreet greeter (still the terminal login prompt)
- Hyprland compositor (same package, same config)
- portal configs in `desktop-hyprland-standalone.nix`
- All other desktop modules (waybar, walker, mako, etc.)
- Session applets (hyprpolkitagent, nm-applet, udiskie)
- The Lua config tree (except removing one require)

## Validation gates

### Pre-migration baseline

1. Capture current session target state:
```bash
nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.systemd.user.targets 2>/dev/null | jq 'keys'
```

2. Capture current walker service bindings:
```bash
nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.systemd.user.services.elephant.Unit.PartOf
nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.systemd.user.services.walker.Unit.PartOf
```

3. Verify current greetd command:
```bash
nix eval --raw path:$PWD#nixosConfigurations.predator.config.services.greetd.settings.default_session.command
```

### Post-migration validation

1. All three hosts eval:
```bash
nix eval path:$PWD#nixosConfigurations.{predator,aurelius,cerebelo}.config.system.build.toplevel.drvPath
```

2. UWSM is enabled:
```bash
nix eval path:$PWD#nixosConfigurations.predator.config.programs.uwsm.enable
# must be: true
```

3. UWSM compositor configured:
```bash
nix eval --json path:$PWD#nixosConfigurations.predator.config.programs.uwsm.waylandCompositors
# must contain hyprland entry
```

4. Greetd command uses uwsm:
```bash
nix eval --raw path:$PWD#nixosConfigurations.predator.config.services.greetd.settings.default_session.command
# must contain "uwsm start"
```

5. Walker services bind to graphical-session.target (not hyprland-session.target):
```bash
nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.systemd.user.services.elephant.Unit.PartOf
# must be ["graphical-session.target"]
```

6. No references to hyprland-session.target remain in active code:
```bash
grep -r "hyprland-session.target" modules/ config/ --include="*.nix" --include="*.lua"
# must be empty (except possibly in archive docs)
```

7. Full validation gates:
```bash
./scripts/run-validation-gates.sh structure
```

8. Smoke test (runtime):
- Reboot into new generation
- Verify greetd shows tuigreet prompt
- Login → Hyprland starts via UWSM
- waybar, walker, mako, applets all start correctly
- Logout → session terminates cleanly

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| UWSM dbus-broker requirement | nixpkgs module auto-sets `services.dbus.implementation = "broker"`. We already use dbus — switching to broker is low risk and UWSM-recommended. |
| Service ordering change | Services currently bound to `hyprland-session.target` will now bind to `graphical-session.target`. These are already `After=hyprland-session.target`, which binds to `graphical-session.target` — the ordering chain is preserved. |
| Env vars not propagated | UWSM's env preparation unit sources `uwsm/env-hyprland/*` files. Current env setup was done via `hl.env()` in Lua. UWSM handles `XDG_CURRENT_DESKTOP`, `WAYLAND_DISPLAY`, etc. automatically. Additional vars can be placed in `~/.config/uwsm/env-hyprland/`. |
| session-bootstrap.lua removal | This only contained env vars already handled by UWSM + the session-start trigger. Hyprland no longer needs to exec the script on startup — UWSM orchestrates the session. |
| Rollback path | `nh os switch --rollback` reverts the NixOS generation. No persistent state changes. |

## Definition of Done

- [ ] `withUWSM = true` in hyprland.nix NixOS block
- [ ] `programs.uwsm.waylandCompositors.hyprland` configured
- [ ] greetd command uses `uwsm start -F -- Hyprland`
- [ ] `hyprland-session-start` script removed from HM block
- [ ] `hyprland-session.target` removed from HM block
- [ ] `session-bootstrap.lua` provisioning removed
- [ ] `require("session-bootstrap")` removed from hyprland.lua
- [ ] walker services bind to `graphical-session.target`
- [ ] Zero references to `hyprland-session.target` in active code
- [ ] All validation gates pass
- [ ] Three hosts eval successfully
- [ ] Runtime smoke: login → Hyprland starts → services up → logout clean
