# Network mDNS and Mako D-Bus Cleanup

## Goal

Restore stable `predator.local` discovery and remove the Mako-specific D-Bus
activation warnings by making one component responsible for each protocol
contract: Avahi owns mDNS publication, and the Mako package exposes one
correctly named `org.freedesktop.Notifications` D-Bus service file with
`SystemdService=mako.service`.

## Scope

In scope:
- Stop systemd-resolved from publishing/responding on mDNS while keeping it as
  the DNS stub resolver.
- Keep Avahi enabled as the single mDNS publisher for `predator.local`.
- Replace the custom Home Manager `fr.emersion.mako.service` D-Bus file with a
  single canonical user D-Bus service file named
  `org.freedesktop.Notifications.service`, while removing Mako D-Bus service
  files from the package profile to avoid duplicate providers.
- Clean up low-risk session warnings introduced by invalid local configuration:
  Waybar's impossible height and Elephant's inherited nonexistent PATH entries.
- Validate live DNS/mDNS behavior and user D-Bus activation after switch/login.

Out of scope:
- Changing Tailscale MagicDNS policy or tailnet names.
- Changing router/DHCP DNS configuration.
- Cleaning unrelated D-Bus duplicate warnings from packages such as portals,
  gvfs, fcitx, blueman, obex, or ghostty unless they block validation.
- Disabling Avahi.

## Current State

### mDNS / hostname resolution

Repo facts:
- `modules/features/system/networking-resolved.nix` enables systemd-resolved and
  sets `services.resolved.settings.Resolve.MulticastDNS = true`.
- `modules/features/system/networking-avahi.nix` enables Avahi, `nssmdns4`, and
  address publishing.

Live facts observed on predator:
- `resolvectl status` shows both LAN links with `+mDNS` under systemd-resolved.
- Avahi logs at boot show:
  - `Detected another IPv4 mDNS stack running on this host`
  - `Detected another IPv6 mDNS stack running on this host`
  - repeated hostname conflicts ending in `Host name is predator-4.local`
- systemd-resolved logs show:
  - `Detected conflict on predator.local IN A <LAN address>`
  - `Hostname conflict, changing published hostname from 'predator' to 'predator2'`
- Current local lookup still resolves synthetic `predator` to `127.0.0.2`, but
  mDNS name ownership is unstable because two local responders publish the same
  host identity.

Conclusion:
- The intermittent `predator`/`predator.local` discovery problem is explained by
  two mDNS responders on the same host: Avahi and systemd-resolved. They detect
  each other's announcements as conflicts and rename the published host.

Impact decision: mDNS is still required for local LAN `.local` name resolution and
service discovery. This plan does **not** disable mDNS system-wide. It disables only
systemd-resolved's mDNS responder so Avahi remains the sole mDNS owner. Expected
preserved functionality: `predator.local` publication, Avahi/NSS `.local` lookups,
and Avahi service discovery. Expected behavior change: `resolvectl query
predator.local` may no longer be the authoritative test path because mDNS moves
out of systemd-resolved and remains with Avahi/NSS.

### Mako D-Bus activation

Repo facts:
- Commit `097550e fix(desktop): inject SystemdService binding for mako DBus activation`
  added `xdg.dataFile."dbus-1/services/fr.emersion.mako.service"` with
  `Name=org.freedesktop.Notifications` and `SystemdService=mako.service`.
- `services.mako.enable = true` also installs the upstream Mako package, whose
  package profile already contains `share/dbus-1/services/fr.emersion.mako.service`.

Live facts observed on predator:
- Two Mako D-Bus service files exist:
  - `/home/higorprado/.local/share/dbus-1/services/fr.emersion.mako.service`
  - `/etc/profiles/per-user/higorprado/share/dbus-1/services/fr.emersion.mako.service`
- Both are named `fr.emersion.mako.service` but declare
  `Name=org.freedesktop.Notifications`.
- dbus-broker logs:
  - service file is not named after `org.freedesktop.Notifications`
  - duplicate name `org.freedesktop.Notifications` ignored
- `busctl --user status org.freedesktop.Notifications` shows Mako is currently
  D-Bus activated as an ad-hoc `dbus-...org.freedesktop.Notifications...service`,
  not as `mako.service`, so the intended `SystemdService=mako.service` handoff is
  not reliably active in the live session.

Conclusion:
- We need to fix the service file at the package/profile boundary, not add a
  second user-level D-Bus file with the same wrong filename.

Design decision: a user-level `xdg.dataFile` with the canonical filename would
still leave the upstream package's misnamed `fr.emersion.mako.service` in the
profile, so dbus-broker would continue to see a duplicate/wrong-name provider.
The package/profile boundary is the invariant: the Mako package should expose one
service file for `org.freedesktop.Notifications`, with the matching filename and
the `SystemdService=mako.service` handoff. Therefore the package override is the
least leaky fix even though it is slightly more code than another user-level file.

## Desired End State

- `journalctl -b -u avahi-daemon.service` has no `another ... mDNS stack` warning
  and no hostname conflict loop.
- `journalctl -b -u systemd-resolved.service` has no `Hostname conflict` for
  `predator.local`.
- Avahi publishes `predator.local` without renaming to `predator-2.local`,
  `predator-3.local`, or `predator-4.local`.
- Mako D-Bus activation has exactly one authoritative service file for
  `org.freedesktop.Notifications` in the user profile.
- The authoritative file is named `org.freedesktop.Notifications.service` and
  contains `SystemdService=mako.service`.
- D-Bus activation starts/uses `mako.service` rather than an ad-hoc
  `dbus-...org.freedesktop.Notifications...service` unit.

## Phases

### Phase 0: Baseline

Validation:
- Capture current mDNS conflict evidence:
  - `journalctl -b -u avahi-daemon.service --no-pager`
  - `journalctl -b -u systemd-resolved.service --no-pager`
  - `resolvectl status`
  - `getent hosts predator.local`
- Capture current D-Bus service files:
  - `/home/higorprado/.local/share/dbus-1/services/fr.emersion.mako.service`
  - `/etc/profiles/per-user/higorprado/share/dbus-1/services/fr.emersion.mako.service`
  - `systemctl --user cat mako.service`
  - `busctl --user status org.freedesktop.Notifications`

### Phase 1: Make Avahi the only mDNS publisher

Targets:
- `modules/features/system/networking-resolved.nix`

Changes:
- Change `services.resolved.settings.Resolve.MulticastDNS` from `true` to `false`
  (or the equivalent `"no"` if the rendered systemd setting requires string form).
- Keep `networking.networkmanager.dns = "systemd-resolved"` unchanged.
- Keep `services.avahi` unchanged as the mDNS publisher.

Validation:
- `nix eval` confirms `services.resolved.settings.Resolve.MulticastDNS` renders disabled.
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` succeeds.
- After switch/reboot or service restart by operator:
  - `resolvectl status` shows systemd-resolved no longer advertising mDNS on LAN links.
  - Avahi logs have no `Detected another ... mDNS stack` warning.
  - Avahi logs have no `Host name conflict` renaming loop.
  - `getent hosts predator.local` still resolves through Avahi/NSS.

Diff expectation:
```diff
-      services.resolved.settings.Resolve.MulticastDNS = true;
+      services.resolved.settings.Resolve.MulticastDNS = false;
```

Commit target:
- `fix(networking): keep avahi as sole mdns publisher`

### Phase 2: Fix Mako D-Bus activation at the package boundary

Targets:
- `modules/features/desktop/mako.nix`

Changes:
- Remove `xdg.dataFile."dbus-1/services/fr.emersion.mako.service"`.
- Define a local package value, for example `makoWithoutDbusActivation`, using
  `pkgs.mako.overrideAttrs`.
- In the package override, remove both possible Mako D-Bus service files from
  the package output:
  - `$out/share/dbus-1/services/fr.emersion.mako.service`
  - `$out/share/dbus-1/services/org.freedesktop.Notifications.service`
- Add exactly one user-level D-Bus activation file via
  `xdg.dataFile."dbus-1/services/org.freedesktop.Notifications.service"` with:
  ```ini
  [D-BUS Service]
  Name=org.freedesktop.Notifications
  Exec=@mako@/bin/mako
  SystemdService=mako.service
  ```
  where `@mako@` is the overridden package output path.
- Set `services.mako.package = makoWithoutDbusActivation`.

Validation:
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path` succeeds.
- The generated user data files contain
  `.local/share/dbus-1/services/org.freedesktop.Notifications.service`.
- The generated package profile does not contain either
  `share/dbus-1/services/fr.emersion.mako.service` or
  `share/dbus-1/services/org.freedesktop.Notifications.service`.
- After switch/login by operator:
  - `$HOME/.local/share/dbus-1/services/fr.emersion.mako.service` is absent.
  - `/etc/profiles/per-user/higorprado/share/dbus-1/services/org.freedesktop.Notifications.service` is absent.
  - dbus-broker no longer logs the Mako-specific wrong-name/duplicate warning.
  - `busctl --user status org.freedesktop.Notifications` reports `UserUnit=mako.service` after activation.

Diff expectation:
- Remove the old wrong-name D-Bus file declaration.
- Remove Mako D-Bus service files from the package used by Home Manager.
- Add one canonical user-level D-Bus file with `SystemdService=mako.service`.
- No Mako behavior/settings changes.

Commit target:
- `fix(desktop): install canonical mako dbus activation file`

### Phase 3: Gates and runtime validation

Validation:
- `bash scripts/run-validation-gates.sh`
- `bash scripts/check-repo-public-safety.sh`
- `journalctl --user -b -u dbus-broker.service --no-pager` reviewed for remaining
  Mako-specific warnings.
- `journalctl -b -u avahi-daemon.service --no-pager` reviewed for mDNS conflicts.
- `journalctl -b -u systemd-resolved.service --no-pager` reviewed for hostname
  conflict messages.

Diff expectation:
- Only targeted networking/session modules and this plan should change.

Commit target:
- No separate commit unless documentation/report updates are added.

## Risks

- Disabling mDNS in systemd-resolved means `resolvectl query predator.local` may
  no longer be the right validation path for mDNS. Use `getent hosts
  predator.local` and Avahi logs because Avahi/NSS owns mDNS after the change.
- Existing non-Mako D-Bus duplicate warnings may remain. They are package/profile
  duplication noise and are out of scope unless they correspond to a broken
  runtime service.
- Home Manager should remove the old `xdg.dataFile` symlink when the declaration
  disappears. If it does not, the stale file must be removed explicitly after
  operator approval because it is mutable user-home state outside the repo.

## Definition of Done

- [ ] systemd-resolved no longer publishes/responds to mDNS.
- [ ] Avahi starts without detecting another local mDNS stack.
- [ ] Avahi keeps the hostname as `predator.local` with no conflict rename.
- [ ] `predator.local` resolves via Avahi/NSS after switch/reboot.
- [ ] User D-Bus data exposes exactly one `org.freedesktop.Notifications.service`
      with `SystemdService=mako.service`.
- [ ] Mako package/profile exposes no notification D-Bus service file.
- [ ] dbus-broker no longer reports the Mako-specific wrong-name/duplicate warning.
- [ ] Mako D-Bus activation uses `mako.service`.
- [ ] Build, validation gates, and public safety pass.
