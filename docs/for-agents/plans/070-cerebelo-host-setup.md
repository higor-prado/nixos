# Cerebelo Host Setup — Orange Pi 5

## Goal

Incorporar o Orange Pi 5 (`cerebelo`) ao repositório seguindo os padrões dendríticos
das demais máquinas. O resultado final é um host aarch64-linux headless, gerenciado
pela flake, com hardware declarado, zram swap, HDD montado e usuário `higorprado`
com acesso SSH.

## Scope

In scope:
- `hardware/cerebelo/` — hardware-configuration, performance (zram + sysctls), boot
- `modules/hosts/cerebelo.nix` — composição de features básicas de servidor
- `private/hosts/cerebelo/default.nix.example` — shape para SSH key + sudo
- wiring de validação: adicionar cerebelo a `validation_host_topology.sh` e CI
- deploy: nixos-rebuild switch via SSH

Out of scope:
- GPU/NPU/display (Mali G610 — sem uso previsto no momento)
- impermanence (não usada em aurelius, não necessária agora)
- migração do usuário `rk` (será substituído naturalmente pelo rebuild)
- disko para o NVMe (disco já particionado corretamente — describe via fileSystems)
- serviços além do básico de servidor (ssh, fish, ferramentas)

## Current State

### Hardware

| Item | Detalhe |
|------|---------|
| SoC | Rockchip RK3588S (Orange Pi 5) |
| CPU | 4× Cortex-A55 @ 1.8 GHz + 4× Cortex-A76 @ 2.35 GHz |
| RAM | 8 GB |
| Boot/Root | NVMe 1 TB Kingston SNV3S — `nvme0n1p2` ext4, UUID `14e19a7b-0ae0-484d-9d54-43bd6fdc20c7` |
| Firmware | `nvme0n1p1` 200 MB vfat, label `BOOT`, mount `/boot/firmware` |
| HDD | 2 TB Seagate ST2000LM007 `/dev/sda`, `sda1` ext4, **não montado** — UUID desconhecido (requer sudo para blkid) |
| Swap | **nenhum** |
| GPU | Mali G610 — dois nós DRI (`card0`, `card1`) |
| NIC | `end1` — rk_gmac-dwmac (Gigabit) |
| Temp (idle) | ~43 °C |

### NixOS

- Versão: 26.05.20251221.a653104 (Yarara)
- Closure name: `orangepi5-sd-card` — build externo, sem `/etc/nixos/`
- Boot: extlinux (U-Boot), **não EFI** — diferente de aurelius
- User atual: `rk` (uid=1000, wheel)
- Sem home-manager, sem channels, sem nixos-hardware

### O que não existe ainda

- `hardware/cerebelo/`
- `modules/hosts/cerebelo.nix`
- `private/hosts/cerebelo/`
- cerebelo nas listas de validação

## Desired End State

- `nixosConfigurations.cerebelo` na flake avaliado sem erros
- `nixos-rebuild switch` executado com sucesso na máquina
- Usuário `higorprado` com shell fish, sudo, SSH key via private override
- `/data` montado com o HDD de 2 TB
- zram swap ativo (memoryPercent=100, zstd) — sem swap em disco
- Gates de validação passam localmente e no CI
- `.example` para private override presente e documentado

## Phases

### Phase 0: Bootstrap SSH

O acesso atual é por senha (`rk`/`rk3588`). Antes de qualquer rebuild:

Targets:
- `private/hosts/cerebelo/default.nix` (untracked) — SSH key + sudo

Changes:
- Criar `private/hosts/cerebelo/default.nix` com a chave SSH pública de predator
- Subir essa config via nixos-rebuild (pode ser feito por senha na primeira vez)

Validation:
- `ssh higorprado@192.168.1.X` sem senha (após rebuild)

### Phase 1: Hardware config

Targets:
- `hardware/cerebelo/default.nix`
- `hardware/cerebelo/hardware-configuration.nix`
- `hardware/cerebelo/performance.nix`

#### `hardware/cerebelo/default.nix`

```nix
{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./performance.nix
  ] ++ lib.optional (builtins.pathExists ../../private/hosts/cerebelo/default.nix)
       ../../private/hosts/cerebelo/default.nix;

  # extlinux (U-Boot) — RK3588S não usa EFI
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.grub.enable = false;
}
```

#### `hardware/cerebelo/hardware-configuration.nix`

```nix
{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # NVMe root — por UUID (label NIXOS_SD é do build de imagem, UUID é confiável)
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/14e19a7b-0ae0-484d-9d54-43bd6fdc20c7";
    fsType = "ext4";
  };

  # Partição de firmware U-Boot
  fileSystems."/boot/firmware" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "nofail" "noauto" ];
  };

  # HDD de 2 TB — substituir UUID pelo valor real de blkid
  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/PLACEHOLDER-BLKID-SDA1";
    fsType = "ext4";
    options = [ "nofail" "noatime" "lazytime" ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
```

**Nota sobre HDD UUID:** antes do rebuild, obter UUID real com:
```bash
sudo blkid /dev/sda1
```
E substituir `PLACEHOLDER-BLKID-SDA1`.

#### `hardware/cerebelo/performance.nix`

Basear no modelo de aurelius com ajustes para SBC:

```nix
{ ... }:
{
  # zram: melhor opção para ARM sem swap em disco
  # — comprime páginas frias na RAM em vez de ir ao disco lento
  # — com RK3588S + 8 GB, memoryPercent=100 = até 8 GB de swap comprimido
  zramSwap.enable = true;
  zramSwap.memoryPercent = 100;
  zramSwap.algorithm = "zstd";

  boot.kernel.sysctl = {
    # Preferir manter dados em RAM; só despejar para zram quando necessário
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 30;

    # Rede — BBR + buffers para Gigabit
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "net.core.somaxconn" = 8192;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_max_syn_backlog" = 4096;
    "net.core.netdev_max_backlog" = 4096;
    "net.ipv4.tcp_tw_reuse" = 1;
    "net.ipv4.ip_local_port_range" = "1024 65535";

    "fs.file-max" = 2097152;
  };
}
```

Validation:
- `nix eval .#nixosConfigurations.cerebelo.config.zramSwap.enable` → `true`

Diff expectation:
- `hardware/cerebelo/` com 3 arquivos

Commit target:
- `feat(cerebelo): add hardware config — extlinux, ext4 NVMe, zram`

### Phase 2: Host module

Arquivo: `modules/hosts/cerebelo.nix`

Composição mínima de servidor (similar a aurelius, sem serviços específicos por ora):

```nix
{ inputs, config, ... }:
let
  system = "aarch64-linux";
  hostName = "cerebelo";
  hardwareImports = [
    ../../hardware/cerebelo/default.nix
  ];
in
{
  configurations.nixos.cerebelo.module =
    let
      inherit (config.flake.modules) homeManager nixos;
      userName = config.username;
    in
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        nixos.system-base
        nixos.home-manager-settings
        nixos.nixpkgs-settings
        nixos.nix-settings
        nixos.networking
        nixos.security
        nixos.keyboard
        nixos.maintenance
        nixos.fish
        nixos.ssh
        nixos.mosh
        nixos.higorprado
        nixos.editor-neovim
        nixos.packages-server-tools
        nixos.packages-system-tools
      ] ++ hardwareImports;

      nixpkgs.hostPlatform = system;
      networking.hostName = hostName;

      home-manager.users.${userName} = {
        imports = [
          homeManager.higorprado
          homeManager.core-user-packages
          homeManager.git-gh
          homeManager.ssh
          homeManager.fish
          homeManager.starship
          homeManager.terminal-tmux
          homeManager.tui-tools
          homeManager.dev-tools
          homeManager.editor-neovim
        ];
      };
    };
}
```

Validation:
- `nix eval .#nixosConfigurations.cerebelo.config.networking.hostName` → `"cerebelo"`
- `nix eval .#nixosConfigurations.cerebelo.config.system.stateVersion`

Diff expectation:
- `modules/hosts/cerebelo.nix` novo

Commit target:
- `feat(cerebelo): add host module — minimal server composition`

### Phase 3: Private override + exemplo

Targets:
- `private/hosts/cerebelo/default.nix` (untracked — criar manualmente)
- `private/hosts/cerebelo/default.nix.example` (tracked)

O exemplo deve seguir o shape de aurelius:

```nix
# Copy to ./default.nix (untracked) and fill with real values.
{ config, ... }:
let userName = "your-user"; in
{
  users.users.${userName}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAA... replace-with-real-key"
  ];

  security.sudo.extraRules = [{
    users = [ userName ];
    commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
  }];
}
```

Validation:
- `./scripts/check-repo-public-safety.sh` — PASS

Commit target:
- `feat(cerebelo): add private override example`

### Phase 4: Validation wiring

Targets:
- `scripts/lib/validation_host_topology.sh`
- `.github/workflows/validate.yml`

Changes:
- Adicionar `cerebelo` às listas `validation_host_stages`, `ci_validation_host_stages`, e o case `validation_stage_host`/`validation_stage_mode`
- O modo de cerebelo = `"eval"` (como aurelius — sem build completo no CI por ser aarch64 cross)
- Adicionar job `cerebelo-eval` no CI paralelo com `aurelius-eval`

Validation:
- `./scripts/run-validation-gates.sh structure` — PASS
- `./scripts/run-validation-gates.sh cerebelo` — PASS

Commit target:
- `feat(ci): add cerebelo to validation stages`

### Phase 5: Deploy

```bash
# Opção A: build local (x86_64 cross-compila para aarch64)
nixos-rebuild switch \
  --flake .#cerebelo \
  --target-host rk@192.168.1.X \
  --use-remote-sudo

# Opção B: build em aurelius (aarch64 nativo) e push para cerebelo
# (mais rápido, evita cross-compile)
```

Validation:
- `ssh higorprado@192.168.1.X nixos-version` → versão da flake
- `ssh higorprado@192.168.1.X swapon --show` → zram ativo
- `ssh higorprado@192.168.1.X df -h /data` → HDD montado

## Riscos

- **UUID do HDD desconhecido**: precisa de `sudo blkid` antes de Phase 1. O `nofail`
  em `fileSystems."/data"` evita falha de boot se o disco não estiver presente, mas
  o UUID placeholder causará erro de eval antes disso — substituir antes de commitar.

- **User `rk` vs `higorprado`**: o primeiro rebuild com `--use-remote-sudo` ainda
  usa `rk`. Após o rebuild, `higorprado` precisa estar em private override com chave
  SSH e sudo antes de poder descartar `rk`.

- **Cross-compile**: builds x86_64 → aarch64 são lentos. Aurelius pode ser usado
  como builder nativo com `--build-host aurelius --target-host cerebelo`.

- **extlinux**: `boot.loader.generic-extlinux-compatible.enable = true` reescreve
  `/boot/extlinux/extlinux.conf`. A primeira reescrita troca a entrada para a nova
  geração — se algo estiver errado, a entrada atual desaparece. Testar build antes.

- **Label NIXOS_SD**: a fstab atual usa label, mas o kernel cmdline usa UUID. Usar
  UUID na config NixOS é mais seguro e não depende de a label persistir.

## Definition of Done

- `nix eval .#nixosConfigurations.cerebelo.config.system.stateVersion` sem erros
- `nix eval .#nixosConfigurations.cerebelo.config.zramSwap.enable` → `true`
- `nix eval .#nixosConfigurations.cerebelo.config.networking.hostName` → `"cerebelo"`
- `./scripts/run-validation-gates.sh structure` — PASS
- `./scripts/run-validation-gates.sh cerebelo` — PASS
- `ssh higorprado@192.168.1.X nixos-version` — versão da flake atual
- `ssh higorprado@192.168.1.X swapon --show` — zram ativo
- `df -h /data` na máquina — HDD montado
