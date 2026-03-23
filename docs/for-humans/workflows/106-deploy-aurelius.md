# Deploy Aurelius (Remote Server)

## One-shot deploy

From predator:

```bash
nh os switch path:$HOME/nixos#aurelius \
  --target-host aurelius --build-host aurelius \
  --out-link "$HOME/nixos/result-aurelius" \
  -e passwordless
```

Abbreviations (fish):
- `naus` — update lockfile + switch aurelius
- `naub` — update lockfile + build only
- `naut` — update lockfile + test (no activate)
- `adev` — open a persistent tmux dev session over SSH

## Check health

```bash
ssh aurelius 'nixos-version --json; systemctl --failed --no-pager --legend=0 || true'
# Or use the abbreviation:
naust
```

If the deploy touched Attic, verify the cache endpoint from `predator` too:

```bash
ssh aurelius 'systemctl status atticd.service --no-pager -l'
curl -fsSL http://aurelius.your-tailnet.ts.net:8080/aurelius/nix-cache-info
```

If a local build fails with `Nix daemon disconnected unexpectedly`, check Attic
first before chasing unrelated config:

```bash
curl -fsSL http://aurelius.your-tailnet.ts.net:8080/aurelius/nix-cache-info
ssh aurelius 'systemctl status atticd.service --no-pager -l'
```

## Remote dev session

```bash
adev
```

## Clean store

```bash
ssh aurelius 'sudo -n /run/current-system/sw/bin/nh clean all -e none'
# Or:
nauc
```
