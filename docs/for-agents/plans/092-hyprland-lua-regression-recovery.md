# Hyprland Lua Regression Recovery

## Goal

Recover the `predator` Hyprland session from the broken first Lua migration, then redo the migration with measurable parity. The work must fix session startup/env ownership, restore logout behavior, and prove every keybind against the old Hyprlang source before Lua stays enabled.

## Scope

In scope:
- live emergency rollback path for the current broken `~/.config/hypr/hyprland.lua`
- repo-owned fix in `~/nixos` for Hyprland session startup under Lua
- exact bind parity table from old `binds.conf` to new Lua
- runtime validation for login time, environment propagation, rofi powermenu logout, and keybinds
- repo validation gates required by `AGENTS.md`

Out of scope:
- broad desktop redesign
- changing private override files
- replacing rofi with wlogout as part of this recovery

## Current State

Repo rules read:
- `AGENTS.md`
- `docs/for-agents/000-operating-rules.md`
- `001-repo-map.md`
- `002-architecture.md`
- `003-module-ownership.md`
- `004-private-safety.md`
- `005-validation-gates.md`
- `006-extensibility.md`
- `007-option-migrations.md`
- `999-lessons-learned.md`

Relevant repo files inspected:
- `flake.nix`
- `modules/hosts/predator.nix`
- `modules/features/desktop/hyprland.nix`
- `modules/desktops/hyprland-standalone.nix`
- `modules/features/desktop/session-applets.nix`
- `modules/features/desktop/rofi.nix`
- `modules/features/desktop/wlogout.nix`
- upstream Home Manager Hyprland module in `/nix/store/.../modules/services/window-managers/hyprland.nix`

Important repo facts:
- `modules/features/desktop/hyprland.nix` owns `homeManager.hyprland`.
- Home Manager's current Hyprland module still writes only `~/.config/hypr/hyprland.conf`; it has no native `hyprland.lua` output path in the inspected module.
- Hyprland upstream chooses `hyprland.lua` at startup if it exists, so the generated `hyprland.conf` session bootstrap is ignored once Lua exists.
- `homeManager.hyprland` now disables Home Manager's legacy Hyprland systemd integration and generates `~/.config/hypr/session-bootstrap.lua` as the repo-owned Lua session bridge.
- `modules/desktops/hyprland-standalone.nix` now provisions `~/.config/hypr/hyprland.lua` and the tracked `modules/*.lua` tree as mutable copy-once files from `config/desktops/hyprland-standalone/`.

Live facts observed after the bad migration:
- `hyprctl eval 'return 1'` returns `ok`, so Lua manager is active.
- `hyprctl configerrors` is empty; lack of config errors did not imply behavioral parity.
- `XDG_CURRENT_DESKTOP` was absent from the Hyprland process environment before the later un-reloaded local env edit.
- `rofi` powermenu logout script requires `XDG_CURRENT_DESKTOP=Hyprland` before it calls `hyprctl dispatch exit`.
- systemd user logs show display-bound services trying to start before Wayland was available during login:
  - `wl-paste: Failed to connect to a Wayland server`
  - `xdg-desktop-portal-hyprland: Couldn't connect to a wayland compositor`
  - `waybar.service: Failed`
  - `blueman-applet.service: Failed`
  - `hyprpolkitagent.service: Failed`

## Root Causes

1. Lua activation bypassed Home Manager's generated `hyprland.conf` bootstrap.
   - The old systemd/env startup existed only as `exec-once` in `hyprland.conf`.
   - Creating `hyprland.lua` made Hyprland ignore that file at startup.

2. The manual Lua startup copy ran session setup from the wrong ownership layer and without proving event ordering.
   - The session script belongs to the repo's Hyprland session owner, not ad-hoc live Lua.
   - It must run after Hyprland's compositor environment is real and after required env vars are set.

3. Session environment parity was not verified.
   - `XDG_CURRENT_DESKTOP`, `XDG_SESSION_DESKTOP`, and `XDG_SESSION_TYPE` must exist for children and user-manager/dbus activation.
   - The missing `XDG_CURRENT_DESKTOP` directly explains the rofi logout branch not running.

4. Bind migration was not proven line-by-line before activation.
   - Several legacy dispatchers were translated to Lua helper dispatchers without runtime proof.
   - Additional runtime discovery during execution: under the Lua config manager, `hyprctl dispatch <legacy-dispatcher> <args>` is no longer valid syntax. `hyprctl dispatch exit`, `hyprctl dispatch workspace r+1`, and similar calls are parsed as Lua dispatch expressions and fail. Scripts and external commands must use Lua dispatch syntax, e.g. `hyprctl dispatch 'hl.dsp.focus({ workspace = "r+1" })'`, or binds must call the Lua API directly.
   - This directly explains why `SUPER+Down` failed: the helper script called legacy `hyprctl dispatch movefocus` and `hyprctl dispatch workspace`.

## Desired End State

- Login to Hyprland Lua does not produce early Wayland failures or visible delay beyond baseline.
- `systemctl --user show-environment` contains at least:
  - `WAYLAND_DISPLAY`
  - `HYPRLAND_INSTANCE_SIGNATURE`
  - `XDG_CURRENT_DESKTOP=Hyprland`
  - `XDG_SESSION_DESKTOP=Hyprland`
  - `XDG_SESSION_TYPE=wayland`
  - `NIX_XDG_DESKTOP_PORTAL_DIR`
- Processes launched by Hyprland inherit the same session env.
- Rofi powermenu logout executes `hyprctl dispatch exit` successfully.
- Every old bind is either:
  - exact semantic parity, or
  - explicitly documented as intentionally changed, with approval.
- Repo validation gates pass.
- Rollback is one command: disable `~/.config/hypr/hyprland.lua` and restart Hyprland to return to legacy `hyprland.conf`.

## Phases

### Phase 0: Stop digging; choose temporary recovery mode

Targets:
- live `~/.config/hypr/hyprland.lua`
- live `~/.config/hypr/modules/**`

Changes proposed:
- Option A, safest immediate recovery: rename `~/.config/hypr/hyprland.lua` to `hyprland.lua.disabled` and restart Hyprland. This restores Home Manager's generated `hyprland.conf` bootstrap and old Hyprlang config path.
- Option B, if Lua must remain active during investigation: remove session-start command from `modules/startup.lua`, keep only static config, and test. This is riskier than Option A.

Validation:
```bash
hyprctl eval 'return 1' 2>&1 | rg 'only supported with the lua config manager' # expected after rollback
hyprctl configerrors
systemctl --user show-environment | sort | rg 'WAYLAND_DISPLAY|XDG_CURRENT_DESKTOP|XDG_SESSION_TYPE|HYPRLAND_INSTANCE_SIGNATURE|NIX_XDG_DESKTOP_PORTAL_DIR'
```

Diff expectation:
- live-only rollback, no repo change.

Approval required before execution: yes.

### Phase 1: Baseline capture before fixes

Targets:
- live session
- `~/nixos`

Commands:
```bash
cd ~/nixos
git status --short
systemctl --user --failed --no-pager || true
systemctl --user list-units \
  'graphical-session.target' \
  'hyprland-session.target' \
  'waybar.service' \
  'network-manager-applet.service' \
  'blueman-applet.service' \
  'udiskie.service' \
  'cliphist*.service' \
  'wl-clip-persist.service' \
  'hyprpolkitagent.service' \
  'xdg-desktop-portal*.service' \
  --all --no-pager
systemctl --user show-environment | sort | rg 'WAYLAND_DISPLAY|DISPLAY|XDG_CURRENT_DESKTOP|XDG_SESSION_DESKTOP|XDG_SESSION_TYPE|HYPRLAND_INSTANCE_SIGNATURE|NIX_XDG_DESKTOP_PORTAL_DIR' || true
journalctl --user -b --no-pager | rg -i 'graphical-session|hyprland-session|waybar|nm-applet|blueman|udiskie|cliphist|wl-clip|hyprpolkit|xdg-desktop-portal|cannot open display|WAYLAND_DISPLAY|start-limit-hit|wl_display' || true
```

Validation:
- Baseline records current broken/pass state before any edits.
- No claim of fixed behavior without runtime evidence.

Diff expectation:
- none.

### Phase 2: Repo-owned Lua session bootstrap design

Targets:
- `modules/features/desktop/hyprland.nix`
- possibly `modules/desktops/hyprland-standalone.nix`
- new tracked payload under `config/desktops/hyprland-standalone/` if needed

Changes proposed:
1. Keep `modules/features/desktop/hyprland.nix` as owner for session bootstrap.
2. Do not manually paste Nix store paths into live Lua.
3. Add a Lua-aware session bootstrap generated by Nix, because Home Manager's inspected module only emits Hyprlang `exec-once`.
4. The generated Lua bootstrap must:
   - set compositor process env with `hl.env("XDG_CURRENT_DESKTOP", "Hyprland", true)`, `hl.env("XDG_SESSION_DESKTOP", "Hyprland", true)`, `hl.env("XDG_SESSION_TYPE", "wayland", true)`;
   - register `hyprland.start` handler;
   - defer the session script with `hl.timer(..., { timeout = <small value>, type = "oneshot" })` so Hyprland's own executor start hook and env import can run first;
   - call the existing generated `hyprland-session-start` script once;
   - log with a distinct marker so journal validation can prove ordering.
5. The root `hyprland.lua` must require this generated session module before user modules.

Open point to prove before implementation:
- Whether `hl.timer` with a small delay is sufficient to avoid the event listener ordering race. This must be validated by journal order and environment state. If not, do not ship; use an alternate wrapper/session strategy.

Validation:
```bash
cd ~/nixos
nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.wayland.windowManager.hyprland.systemd.variables
nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path
nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel
```

Runtime validation after switch + fresh login:
```bash
systemctl --user show-environment | sort | rg 'WAYLAND_DISPLAY|DISPLAY|XDG_CURRENT_DESKTOP|XDG_SESSION_DESKTOP|XDG_SESSION_TYPE|HYPRLAND_INSTANCE_SIGNATURE|NIX_XDG_DESKTOP_PORTAL_DIR'
journalctl --user -b --no-pager | rg -i 'hyprland lua session bootstrap|hyprland-session|graphical-session|cannot open display|WAYLAND_DISPLAY|start-limit-hit|xdg-desktop-portal'
systemctl --user is-active hyprland-session.target graphical-session.target waybar.service network-manager-applet.service blueman-applet.service udiskie.service cliphist.service wl-clip-persist.service hyprpolkitagent.service
```

Diff expectation:
- only Hyprland session/bootstrap ownership files change.

Commit target:
- `fix(hyprland): add lua-aware session bootstrap`

### Phase 3: Bind parity rewrite, no semantic translation first

Execution correction:
- The initial recovery idea of wrapping legacy dispatchers with `hyprctl dispatch <name> <arg>` is invalid under the Lua manager.
- Binds must use native Lua API dispatchers directly.
- Helper scripts that call `hyprctl dispatch` must detect Lua manager and use Lua dispatch expressions.

Targets:
- live `~/.config/hypr/modules/binds.lua`
- future repo-owned Lua bind payload

Policy:
- First pass must preserve legacy dispatcher strings exactly.
- Do not replace `workspace r+1` with `hl.dsp.focus({ workspace = "r+1" })` until it is proven equivalent.
- Do not replace `movetoworkspace r+1` with `hl.dsp.window.move({ workspace = "r+1" })` until it is proven equivalent.
- For every bind, record old line, new line, and validation result.

Preferred implementation shape for recovery pass:
```lua
local function dispatch(dispatcher, arg)
  local cmd = "hyprctl dispatch " .. dispatcher .. (arg and (" " .. arg) or "")
  return hl.dsp.exec_cmd(cmd)
end
```

Then examples:
```lua
bind(mainMod .. " + down", exec("~/.config/hypr/scripts/focus-or-workspace.sh d"))
bind(mainMod .. " + 1", dispatch("workspace", "1"))
bind(mainMod .. " + CTRL + 1", dispatch("movetoworkspace", "1"))
bind(mainMod .. " + ALT + down", dispatch("movewindow", "d"))
```

Mouse move bind must be handled separately:
- old: `bindm = ALT, mouse:272, movewindow`
- do not mark it fixed until a real drag test proves the Lua replacement behaves the same.
- candidate remains `hl.dsp.window.drag()` on `ALT + mouse:272`, but status is unproven until tested.

Validation:
```bash
hyprctl binds -j > /tmp/hypr-binds-after.json
jq '.[] | {modmask,key,dispatcher,arg,locked,repeat,mouse,release}' /tmp/hypr-binds-after.json
```

Manual runtime validation checklist:
- `SUPER+Down` changes workspace at bottom edge via `focus-or-workspace.sh d`.
- `SUPER+Up` changes workspace at top edge.
- `SUPER+1..4` select workspaces.
- `SUPER+CTRL+1..4` move windows to workspaces.
- `SUPER+ALT+Down/Up` move windows vertically.
- `SUPER+mouse wheel` changes workspace.
- `ALT+LMB drag` moves a window.
- rofi launcher opens.
- rofi powermenu logout exits Hyprland.

Diff expectation:
- bind file changes only.

Commit target:
- `fix(hyprland): restore lua bind parity`

### Phase 4: Full bind comparison table

| Old bind | Old action | Bad Lua migration | Required recovery action | Status before fix |
|---|---|---|---|---|
| `SUPER SPACE` | `exec pkill -x rofi || rofi -show drun ...` | same exec | keep exact | likely ok |
| `SUPER CTRL T` | `exec kitty` | same exec | keep exact | likely ok |
| `SUPER CTRL F` | `exec nautilus` | same exec | keep exact | likely ok |
| `SUPER CTRL B` | `exec firefox` | same exec | keep exact | likely ok |
| `SUPER CTRL Z` | `exec zeditor` | same exec | keep exact | likely ok |
| `SUPER CTRL C` | `exec code` | same exec | keep exact | likely ok |
| `SUPER CTRL V` | clipboard script | same exec | keep exact | likely ok |
| `SUPER CTRL O` | `exec obsidian` | same exec | keep exact | likely ok |
| `SUPER CTRL E` | `exec emacsclient -c -a ""` | same exec | keep exact | likely ok |
| `SUPER CTRL 7` | `exec zeditor` | same exec | keep exact | likely ok |
| `SUPER CTRL 8` | `exec teams-for-linux` | same exec | keep exact | likely ok |
| `SUPER CTRL 9` | `exec steam` | same exec | keep exact | likely ok |
| `SUPER CTRL 0` | `exec spotify` | same exec | keep exact | likely ok |
| `ALT F4` | `killactive` | `hl.dsp.window.close()` | acceptable only if verified; safer: dispatch `killactive` | unproven |
| `SUPER M` | `fullscreen 0` | Lua fullscreen helper | use dispatch `fullscreen 0` first | unproven |
| `SUPER KP_Multiply` | `fullscreen 0` | Lua fullscreen helper | use dispatch `fullscreen 0` first | unproven |
| `SUPER ALT slash` | `togglefloating` | Lua float helper | use dispatch `togglefloating` first | unproven |
| `SUPER ALT KP_Divide` | `togglefloating` | Lua float helper | use dispatch `togglefloating` first | unproven |
| `SUPER comma` | `hyprctl --batch ...` | same exec | keep exact | likely ok |
| `SUPER KP_Delete` | toggle col width script | same exec | keep exact | likely ok |
| `SUPER period` | toggle col width script | same exec | keep exact | likely ok |
| `SUPER KP_Insert` | toggle col width script | same exec | keep exact | likely ok |
| `SUPER CTRL Delete` | rofi powermenu | same exec but env and script dispatch syntax broken | fix env/session and change rofi logout to `hyprctl dispatch 'hl.dsp.exit()'` under Lua | broken by env + Lua dispatch syntax |
| `mouse_left` | `movefocus l` | Lua focus helper | use dispatch `movefocus l` first | unproven |
| `mouse_right` | `movefocus r` | Lua focus helper | use dispatch `movefocus r` first | unproven |
| `SUPER mouse_left` | `workspace r-1` | Lua workspace helper | use dispatch `workspace r-1` first | unproven |
| `SUPER mouse_right` | `workspace r+1` | Lua workspace helper | use dispatch `workspace r+1` first | unproven |
| `SUPER ALT mouse_left` | `layoutmsg swapcol l` | Lua layout helper | keep or dispatch `layoutmsg swapcol l` | unproven |
| `SUPER ALT mouse_right` | `layoutmsg swapcol r` | Lua layout helper | keep or dispatch `layoutmsg swapcol r` | unproven |
| `SUPER SHIFT mouse_left` | `layoutmsg colresize +0.1` | Lua layout helper | keep or dispatch exact | unproven |
| `SUPER SHIFT mouse_right` | `layoutmsg colresize -0.1` | Lua layout helper | keep or dispatch exact | unproven |
| `SUPER mouse_down` | `workspace r-1` | Lua workspace helper | use dispatch exact | unproven |
| `SUPER mouse_up` | `workspace r+1` | Lua workspace helper | use dispatch exact | unproven |
| `SUPER CTRL mouse_down` | `movetoworkspace r-1` | Lua window.move helper | use dispatch exact | unproven |
| `SUPER CTRL mouse_up` | `movetoworkspace r+1` | Lua window.move helper | use dispatch exact | unproven |
| knob no mod raise/lower | `movefocus r/l` | Lua focus helper | use dispatch exact | unproven |
| knob no mod mute | toggle col width script | same exec | keep exact | likely ok |
| `SUPER` knob raise/lower | `workspace r+1/r-1` | Lua workspace helper | use dispatch exact | unproven |
| `SUPER` knob mute | `exec dms ipc overview toggle` | same exec | keep exact | likely ok |
| `ALT` knob raise/lower | `movefocus r/l` | Lua focus helper | use dispatch exact | unproven |
| `SUPER CTRL` knob raise/lower | `movetoworkspace r+1/r-1` | Lua window.move helper | use dispatch exact | unproven |
| `SUPER CTRL ALT` knob raise/lower | `movewindow d/u` | Lua window.move helper | use dispatch exact | unproven |
| `SUPER ALT` knob raise/lower | `layoutmsg swapcol r/l` | Lua layout helper | dispatch exact first | unproven |
| `SUPER SHIFT` knob raise/lower/mute | `layoutmsg colresize ...` | Lua layout helper | dispatch exact first | unproven |
| audio `bindl` group | wpctl/playerctl/dms commands | exec with `locked=true` | add `repeating=true` where old `bindl` behavior needs repeats and test | incomplete |
| screenshots | grim commands | same exec | keep exact | likely ok |
| `SUPER left/right` | `movefocus l/r` | Lua focus helper | use dispatch exact | unproven |
| `SUPER down/up` | focus-or-workspace script | same exec, but script used legacy `hyprctl dispatch` | update script to use Lua dispatch syntax when Lua manager is active | broken by Lua dispatch syntax |
| `SUPER H/L` | `movefocus l/r` | Lua focus helper | use dispatch exact | unproven |
| `SUPER J/K` | focus-or-workspace script | same exec | trace script execution | unproven |
| `SUPER ALT left/right/H/L` | `layoutmsg swapcol` | Lua layout helper | dispatch exact first | unproven |
| `SUPER ALT down/up/J/K` | `movewindow d/u` | Lua window.move helper | use dispatch exact | unproven |
| `SUPER CTRL down/up/J/K` | `movetoworkspace r+1/r-1` | Lua window.move helper | use dispatch exact | unproven |
| `SUPER 1..4` | `workspace 1..4` | Lua workspace helper | use dispatch exact | unproven |
| `SUPER CTRL 1..4` | `movetoworkspace 1..4` | Lua window.move helper | use dispatch exact | unproven |
| column sizing group | `layoutmsg colresize/promote` | Lua layout helper | dispatch exact first | unproven |
| `bindm ALT mouse:272` | `movewindow` drag | `hl.dsp.window.drag()` with unused `{ mouse = true }` option | test actual drag; if not identical, keep legacy config or find supported Lua mouse binding form | high risk |

### Phase 5: SUPER+Down specific proof

Targets:
- `~/.config/hypr/scripts/focus-or-workspace.sh`
- Lua bind registration

Facts already known:
- script is executable.
- `jq` and `hyprctl` are available in the user's PATH.
- `hyprctl binds -j` shows `SUPER+down` registered as a Lua bind.

Required proof:
1. Add temporary tracing only if approved:
```bash
printf '%s\n' "$(date) direction=$1 before=$BEFORE after=$AFTER" >> /tmp/focus-or-workspace.log
```
2. Press `SUPER+Down` once.
3. Inspect whether the script ran and what branch it took.
4. Remove tracing after proof.

Possible outcomes:
- script did not run: Lua exec/bind path is wrong.
- script ran but did not dispatch workspace: script logic failed under current window/layout state.
- script ran and dispatched workspace but workspace did not change: Hyprland dispatcher/layout interaction changed and needs exact legacy dispatch testing.

No fix is accepted without this proof.

### Phase 6: Move working Lua config into repo ownership

Targets:
- `config/desktops/hyprland-standalone/`
- `modules/desktops/hyprland-standalone.nix`

Changes proposed:
- Add repo-owned Lua payload only after live recovery passes.
- Do not make mutable drift the only source of truth.
- Provision Lua files through the existing copy-once model or an explicit generated/symlink split:
  - generated session bootstrap stays symlinked from Nix because it contains store paths;
  - user-tuned Lua modules may be copy-once if editability is still desired.

Validation:
```bash
cd ~/nixos
./scripts/run-validation-gates.sh structure
nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath
nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path
nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel
```

Runtime validation after switch:
- fresh login
- environment checks
- powermenu logout
- manual bind checklist

Commit target:
- `feat(hyprland): provision lua config with parity checks`

## Risks

- Hyprland Lua support is still new; upstream API/event ordering may change.
- Home Manager currently emits Hyprlang config for systemd activation; Lua bypasses it by design.
- `hl.timer`-based session bridge must be treated as a hypothesis until runtime logs prove ordering.
- Mouse drag bind may not have exact Lua parity through the current API; if not, either keep legacy until upstream exposes a supported equivalent or document the limitation before enabling Lua.
- Display-bound services can be D-Bus activated outside the intended target graph; validation must include portal state, not just Hyprland config errors.

## Execution Log

Implemented in this recovery pass:
- live `~/.config/hypr/session-bootstrap.lua` created;
- live `~/.config/hypr/hyprland.lua` now requires `session-bootstrap` before user modules;
- live `~/.config/hypr/modules/startup.lua` no longer starts the Nix session bootstrap directly;
- live `~/.config/hypr/modules/binds.lua` rewritten back to native Lua API dispatchers instead of invalid `hyprctl dispatch <legacy>` wrappers;
- live `~/.config/hypr/scripts/focus-or-workspace.sh` updated to use Lua `hyprctl dispatch 'hl.dsp.focus(...)'` syntax when Lua manager is active;
- live `~/.config/hypr/scripts/toggle-col-width.sh` updated to use Lua `hyprctl dispatch 'hl.dsp.layout(...)'` syntax when Lua manager is active;
- live `~/.config/rofi/powermenu/type-2/powermenu.sh` updated so Hyprland Lua sessions call `hyprctl dispatch 'hl.dsp.exit()'` instead of legacy `hyprctl dispatch exit`.
- repo `modules/features/desktop/hyprland.nix` now generates `~/.config/hypr/session-bootstrap.lua` and exports/imports `XDG_SESSION_DESKTOP` and `DESKTOP_SESSION` in addition to the existing session variables;
- repo `modules/desktops/hyprland-standalone.nix` now provisions the root `hyprland.lua` entrypoint and tracked Lua module tree under `config/desktops/hyprland-standalone/`.

Validation run in this pass:
```bash
nix shell nixpkgs#lua -c luac -p hyprland.lua session-bootstrap.lua modules/*.lua
bash -n scripts/focus-or-workspace.sh scripts/toggle-col-width.sh
hyprctl reload
hyprctl configerrors
~/.config/hypr/scripts/focus-or-workspace.sh d # workspace 1 -> 2
~/.config/hypr/scripts/focus-or-workspace.sh u # workspace 2 -> 1
~/.config/hypr/scripts/toggle-col-width.sh # exit 0
systemctl --user show-environment | rg 'XDG_CURRENT_DESKTOP|XDG_SESSION_DESKTOP|XDG_SESSION_TYPE|DESKTOP_SESSION|WAYLAND_DISPLAY|HYPRLAND_INSTANCE_SIGNATURE|NIX_XDG'
nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.wayland.windowManager.hyprland.systemd.variables
nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path
nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel
./scripts/run-validation-gates.sh structure
```

Not yet validated because it requires intentional session exit/re-login:
- actual rofi powermenu logout click;
- next fresh login timing/journal free of early Wayland failures;
- `ALT+mouse:272` drag parity.

## Definition of Done

- Broken live Lua can be rolled back or replaced without losing the old Hyprlang config.
- `~/nixos` owns the session bootstrap needed when Lua bypasses `hyprland.conf`.
- Login does not show early Wayland failures in user journal.
- Rofi powermenu logout works.
- `SUPER+Down` and `SUPER+Up` behavior is proven with runtime evidence.
- Bind parity table is resolved: no `unproven` or `broken` statuses remain for accepted binds.
- Required Nix validation gates pass.
- Any unrelated pre-existing `~/nixos` worktree changes are either left untouched or explicitly handled in a separate approved task.
