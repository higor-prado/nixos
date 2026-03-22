# Aurelius Service Bootstrap

This runbook covers the parts of the Aurelius service surface that are not
fully expressible in tracked Nix alone.

## What Nix does own

- host composition for Aurelius
- Attic server, client, and publisher owners
- GitHub runner owner
- Prometheus, node-exporter, Forgejo, Grafana, Docker, and related service wiring
- Grafana secret key (auto-generated on first activation via activation script)

## What private host state still exists

These files are intentionally private and must exist on the target hosts.

On `aurelius`:
- `/etc/atticd/atticd.env`
- `/home/<user>/.config/github-runner/aurelius.token`

On `predator`:
- `/home/<user>/.config/attic/predator-publisher.token`

## What external control-plane state still exists

These are GitHub settings, not NixOS state:
- organization runner group exists
- runner group allows the intended repositories
- if the repositories are public, the runner group allows public repositories

## Bootstrap GitHub org runner

1. Put the private host binding in `private/hosts/aurelius/services.nix`:

```nix
{ ... }:
{
  custom.githubRunner = {
    url = "https://github.com/<org>";
    tokenFile = "/home/<user>/.config/github-runner/aurelius.token";
    runnerGroup = "Default";
  };
}
```

2. Create the token file on `aurelius` itself:

```bash
ssh aurelius 'install -d -m 700 /home/<user>/.config/github-runner'
ssh aurelius 'umask 077; cat > /home/<user>/.config/github-runner/aurelius.token'
```

3. Apply the host:

```bash
nh os test path:$HOME/nixos#aurelius \
  --target-host aurelius \
  --build-host aurelius \
  -e passwordless
```

4. Verify runtime:

```bash
ssh aurelius 'systemctl status github-runner-aurelius.service --no-pager -l'
ssh aurelius 'journalctl -u github-runner-aurelius.service --no-pager -n 120'
```

Expected:
- `Connected to GitHub`
- `Listening for Jobs`

## Workflow shape for org-wide runner usage

The proven working shape is:

```yaml
runs-on:
  group: Default
  labels:
    - self-hosted
    - aurelius
    - nixos
    - aarch64
```

Do not rely on label-only routing here; the proven org-wide path used explicit
runner group plus labels.

## Bootstrap Attic

1. Put the private host bindings in the gitignored overrides:
- `private/hosts/aurelius/services.nix`
- `private/hosts/predator/services.nix`

2. Create the Attic server env file on `aurelius`:

```bash
ssh aurelius 'sudo install -d -m 700 /etc/atticd'
ssh aurelius 'sudo sh -lc '\''umask 077; cat > /etc/atticd/atticd.env'\'''
```

3. Place the publisher token file on each publishing host:

```bash
install -d -m 700 /home/<user>/.config/attic
umask 077; cat > /home/<user>/.config/attic/predator-publisher.token
```

4. Apply the relevant host and verify:

```bash
ssh aurelius 'systemctl status atticd.service --no-pager -l'
ssh aurelius 'journalctl -u attic-post-build-hook.service --no-pager -n 30'
```

Note: Attic publishing now runs via `nix.settings.post-build-hook`, not a persistent
daemon. The hook fires after each build and pushes resulting paths to the cache.

## Bootstrap Grafana

Grafana requires no manual bootstrap. On first activation, the activation script
`grafana-secret-key` auto-generates `/var/lib/grafana/secret-key` with correct
ownership and permissions.

What persists across rebuilds: `/var/lib/grafana/` — do not delete this directory.
If it is lost, the script regenerates a new secret key on the next boot, which
invalidates all existing browser sessions.

Verify after deploy:

```bash
ssh aurelius 'systemctl status grafana.service --no-pager -l'
```

Grafana is accessible at `http://aurelius.your-tailnet.ts.net:3001` (Tailscale
network only, bound to all interfaces via firewall rule on tailscale0).

## Bootstrap Forgejo

Forgejo requires a one-time web UI setup on first boot.

1. Apply the host and verify the service is running:

```bash
ssh aurelius 'systemctl status forgejo.service --no-pager -l'
```

2. Open `http://aurelius.your-tailnet.ts.net:3000` in a browser.

3. Complete the initial setup wizard and create the admin account.

All Forgejo data (repositories, issues, users) lives in `/var/lib/forgejo/`. This
directory MUST be preserved before any host wipe.

## Bootstrap SSH keys

After a rebuild or wipe, restore the SSH private key(s) needed to authenticate
into aurelius and for git operations:

```bash
# restore authorized host key (matches key in private/hosts/aurelius/default.nix)
scp /path/to/backup/id_rsa aurelius:~/.ssh/
ssh aurelius 'chmod 600 ~/.ssh/id_rsa'
```

If the authorized key in `private/hosts/aurelius/default.nix` changes, update the
file before deploying — otherwise you will lose SSH access after activation.

## Enable Tailscale exit node

After the first deploy (or after a wipe), aurelius will NOT automatically advertise
itself as a Tailscale exit node. The kernel routing capability is enabled by Nix
(`useRoutingFeatures = "server"` via `nixos.tailscale-exit-node`), but advertising
requires a one-time command:

```bash
ssh aurelius 'sudo tailscale set --advertise-exit-node'
```

Then approve the exit node in the Tailscale Admin console:
- Go to the Machines tab
- Find aurelius
- Enable "Use as exit node"

This approval survives host reboots and rebuilds as long as the Tailscale node
identity is preserved (i.e., `/var/lib/tailscale/` is not wiped).

## Pre-wipe checklist

Before wiping or reprovisioning aurelius, back up the following:

| What | Where on aurelius | Why |
|---|---|---|
| Forgejo data | `/var/lib/forgejo/` | All repos, issues, users |
| Attic JWT secret | `/etc/atticd/atticd.env` | Required to re-register publisher tokens |
| GitHub runner token | `/home/<user>/.config/github-runner/aurelius.token` | Required to re-register runner |
| SSH private keys | `~/.ssh/` | Access and git operations |
| Tailscale state | `/var/lib/tailscale/` | Preserves node identity (optional) |

On predator (not on aurelius):

| What | Where on predator | Why |
|---|---|---|
| Attic publisher token | `/home/<user>/.config/attic/predator-publisher.token` | Required to push from predator |

## Recovery rule

If a host is rebuilt from scratch, the recovery order is:

1. restore gitignored private overrides
2. recreate private token/env files on the correct host
3. reapply the host with `nh os test` or `nh os switch`
4. run exit-node advertise command if needed
5. complete Forgejo web UI setup if `/var/lib/forgejo/` was not restored
6. verify the service journal, not only `nix eval`
