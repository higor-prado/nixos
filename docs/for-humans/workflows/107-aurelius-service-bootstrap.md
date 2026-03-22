# Aurelius Service Bootstrap

This runbook covers the parts of the Aurelius service surface that are not
fully expressible in tracked Nix alone.

## What Nix does own

- host composition for Aurelius
- Attic server, client, and publisher owners
- GitHub runner owner
- Prometheus, node-exporter, Forgejo, Docker, and related service wiring

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
ssh aurelius 'systemctl status attic-watch-store.service --no-pager -l'
systemctl status attic-watch-store.service --no-pager -l
```

## Recovery rule

If a host is rebuilt from scratch, the recovery order is:

1. restore gitignored private overrides
2. recreate private token/env files on the correct host
3. reapply the host with `nh os test` or `nh os switch`
4. verify the service journal, not only `nix eval`
