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

## Check health

```bash
ssh aurelius 'nixos-version --json; systemctl --failed --no-pager --legend=0 || true'
# Or use the abbreviation:
naust
```

## Clean store

```bash
ssh aurelius 'sudo -n /run/current-system/sw/bin/nh clean all -e none'
# Or:
nauc
```
