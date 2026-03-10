# Switch and Rollback

## Build and switch (predator)

```bash
nh os switch path:$HOME/nixos
```

## Build only (no switch)

```bash
nh os build path:$HOME/nixos
```

## Rollback

```bash
sudo nixos-rebuild switch --rollback
```

Or boot the previous generation from GRUB.

## Deploy aurelius

```bash
nh os switch path:$HOME/nixos#aurelius \
  --target-host aurelius --build-host aurelius \
  -e passwordless
```

See [workflow: deploy aurelius](106-deploy-aurelius.md).

## Check current generation

```bash
nixos-version --json
```
