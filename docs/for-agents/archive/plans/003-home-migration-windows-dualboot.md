# Home Migration and Windows Dual-Boot

## Goal

Move `/home` do disco de 2TB (WD Black SN850X) para o disco de sistema de 1TB
(Micron 3400), liberar o disco de 2TB inteiro para uma instalação limpa de
Windows, e configurar dual-boot por seleção de disco no BIOS.

## Scope

In scope:
- Adicionar subvolume `@home` no btrfs do cryptroot (nvme0n1)
- Migrar os dados de /home do disco de 2TB para o subvolume novo
- Remover `disk.home` do disko.nix e `crypthome` do encryption.nix
- Verificar que o NixOS sobe completo sem o disco de 2TB
- Instalar Windows no disco de 2TB
- Configurar boot por BIOS (seleção de SSD)

Out of scope:
- Adicionar entrada do Windows no GRUB (dual-boot via BIOS é suficiente)
- Alterar qualquer outro módulo NixOS além de disko.nix e encryption.nix
- Migrar dados do Windows ou qualquer configuração de jogos já existente

## Current State (após Phases 0–3)

Discos:
- `nvme0n1` — Micron 3400 1TB, sistema NixOS
  - `nvme0n1p1` 512M: ESP em `/boot` (vfat)
  - `nvme0n1p2` 953.4G: LUKS `cryptroot` → btrfs com subvolumes
    `@root`, `@nix`, `@log`, `@persist`, `@swap`, `@home`
- `nvme1n1` — WD Black SN850X 2TB, ainda presente (aguarda Windows)

Arquivos relevantes:
- `hardware/predator/disko.nix` — declara apenas `disk.system` com `@home`
- `hardware/predator/hardware/encryption.nix` — TPM2 apenas para `cryptroot`
- `/home` montado de `cryptroot` com `subvol=@home`

Boot: GRUB EFI com `efiInstallAsRemovable = true`; escreve em
`/EFI/BOOT/BOOTX64.EFI` no ESP do nvme0n1. Não depende de variáveis
EFI da firmware.

## Desired End State

- nvme0n1: NixOS completo — ESP + cryptroot btrfs com `@root`, `@nix`,
  `@log`, `@persist`, `@swap`, `@home`
- nvme1n1: Windows (particionado pelo instalador do Windows com ESP
  próprio e partição NTFS)
- NixOS sobe sem erro, /home montado do nvme0n1
- Windows sobe via seleção de dispositivo de boot no BIOS (F2 → Boot)
- Nenhum dado de /home perdido

## Phases

### Phase 0: Baseline — concluída

Validation:
- /home: 53G usados, 842G livres no nvme0n1 — espaço ok
- `nix eval` → ok
- `./scripts/run-validation-gates.sh` → ok

### Phase 1: Config NixOS — mover @home para o disco de sistema — concluída

Commit: `feat(predator): move @home to system disk, remove disk.home`

Targets:
- `hardware/predator/disko.nix`
- `hardware/predator/hardware/encryption.nix`

Changes:

**disko.nix** — adicionar subvolume `@home` dentro do btrfs de `cryptroot`,
remover o bloco `disk.home` inteiro:

```nix
# Em disk.system.content.partitions.luks.content.content.subvolumes,
# adicionar após @persist:
"@home" = {
  mountpoint = "/home";
  mountOptions = [ "compress=zstd:3" "noatime" ];
};

# Remover o bloco disk.home por completo.
```

**encryption.nix** — remover a linha do crypthome:

```nix
# Antes:
boot.initrd.luks.devices = {
  "cryptroot".crypttabExtraOpts = [ "tpm2-device=auto" ];
  "crypthome".crypttabExtraOpts = [ "tpm2-device=auto" ];
};

# Depois:
boot.initrd.luks.devices = {
  "cryptroot".crypttabExtraOpts = [ "tpm2-device=auto" ];
};
```

Validation:
- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `./scripts/run-validation-gates.sh`
- Confirmar que `fileSystems."/home"` na avaliação aponta para subvol `@home`
  em `/dev/mapper/cryptroot` e não mais em `/dev/mapper/crypthome`

Diff expectation:
- disko.nix: remoção do bloco `disk.home` (~30 linhas), adição de
  `"@home"` (~5 linhas) dentro do btrfs existente
- encryption.nix: remoção de uma linha (`"crypthome"...`)

Commit target:
- `feat(predator): move @home to system disk, remove disk.home`

### Phase 2: Migração dos dados — concluída

Executar com o sistema rodando normalmente. O cryptroot já está desbloqueado;
basta montar o pool btrfs em subvolid=5 para criar o subvolume novo e fazer
o rsync diretamente. Não trocar o config ainda.

Procedimento:
1. Montar o pool btrfs raiz (subvolid=5) do cryptroot:
   ```bash
   sudo mkdir -p /mnt/btrfsroot
   sudo mount -t btrfs -o subvolid=5 /dev/mapper/cryptroot /mnt/btrfsroot
   ```
2. Criar o subvolume `@home`:
   ```bash
   sudo btrfs subvolume create /mnt/btrfsroot/@home
   ```
3. Montar o novo subvolume:
   ```bash
   sudo mkdir -p /mnt/newhome
   sudo mount -t btrfs -o subvol=@home /dev/mapper/cryptroot /mnt/newhome
   ```
4. Copiar /home preservando todos os atributos:
   ```bash
   sudo rsync -aHAXx --info=progress2 /home/ /mnt/newhome/
   ```
5. Verificar que todos os arquivos foram copiados:
   ```bash
   diff <(sudo find /home -printf '%P\n' | sort) \
        <(sudo find /mnt/newhome -printf '%P\n' | sort)
   ```
6. Desmontar os temporários:
   ```bash
   sudo umount /mnt/newhome /mnt/btrfsroot
   sudo rmdir /mnt/newhome /mnt/btrfsroot
   ```

Validation:
- `diff` sem saída (sem diferenças)
- Nenhum erro de rsync
- Espaço ocupado em `/mnt/newhome` compatível com `du -sh /home`

### Phase 3: Switch para nova config — concluída

- `mount | grep home` → `cryptroot` com `subvol=@home`
- `systemctl --failed` → 0 unidades
- `crypthome` não ativo

### Phase 4: Verificar independência do disco de 2TB

Desabilitar nvme1n1 no BIOS (Acer Predator: F2 → Main → NVMe Config ou
Boot → desabilitar a entrada do disco) e bootar NixOS.

Validation:
- NixOS sobe completamente sem erros
- /home acessível
- `systemctl --failed` limpo
- Rede, áudio, GPU funcionando

Reabilitar nvme1n1 no BIOS depois da verificação.

### Phase 5: Instalação do Windows

**Antes de iniciar o instalador do Windows:**
- Desabilitar nvme0n1 (sistema NixOS) no BIOS para evitar que o
  instalador do Windows detecte o ESP do NixOS e sobrescreva
  `/EFI/BOOT/BOOTX64.EFI`
- Conectar pendrive com ISO do Windows

Procedimento:
1. BIOS → desabilitar nvme0n1
2. Bootar pelo instalador do Windows
3. Selecionar nvme1n1 como disco de instalação
4. Windows criará automaticamente: partição de recuperação, ESP (~100MB),
   partição reservada do sistema (~16MB) e partição NTFS principal
5. Concluir instalação do Windows normalmente
6. Após Windows instalado e funcionando: BIOS → reabilitar nvme0n1

Validation:
- Windows boota normalmente com nvme0n1 desabilitado
- Após reabilitar nvme0n1: NixOS ainda boota pelo BIOS → seleção de
  dispositivo (F12 ou equivalente no Predator)

### Phase 6: Configuração de dual-boot via BIOS

O Acer Predator permite selecionar o dispositivo de boot na tela de POST:
- **F12**: boot menu temporário (selecionar SSD na hora)
- **F2 → Boot**: definir ordem permanente (NixOS SSD como padrão,
  Windows SSD como segunda opção)

Como GRUB usa `efiInstallAsRemovable`, o NixOS escreve em
`/EFI/BOOT/BOOTX64.EFI` no seu próprio ESP (nvme0n1p1). O Windows
escreve em seu próprio ESP (em nvme1n1). Não há conflito.

Configurar no BIOS:
1. Prioridade 1: `nvme0n1` (NixOS) — boot padrão
2. Para Windows: F12 no POST e selecionar o SSD de 2TB

Nenhuma alteração no config NixOS é necessária para esta fase.

## Risks

- **Espaço insuficiente no nvme0n1**: Se /home tiver mais dados do que
  o espaço livre no disco de sistema, a migração é impossível sem
  limpeza prévia. Verificar na Phase 0.
- **Arquivos abertos durante rsync**: O rsync copia /home com o sistema
  rodando. Arquivos que mudam durante a cópia chegam ao destino em estado
  inconsistente. Para dados críticos que mudam ativamente (ex: DBs), fechar
  os processos que os usam antes do rsync ou fazer um segundo rsync rápido
  logo antes do reboot (`--checksum` para pegar só o que mudou).
- **Windows sobrescrevendo ESP do NixOS**: Mitigado desabilitando nvme0n1
  no BIOS durante a instalação do Windows.
- **BIOS reordenando entradas EFI após instalar Windows**: Como NixOS
  usa `efiInstallAsRemovable` (não registra variáveis EFI), não há risco
  de Windows remover a entrada do NixOS. Apenas verificar ordem de boot.
- **Dados em /home não migrados**: Verificar diff de arquivos após rsync
  (Phase 2 step 6) antes de continuar.

## Definition of Done

- `mount | grep home` mostra `cryptroot` com `subvol=@home`
- `disko.devices.disk` contém apenas `disk.system` (sem `disk.home`)
- `boot.initrd.luks.devices` contém apenas `cryptroot`
- NixOS boota completo sem o disco de 2TB presente
- Windows instalado e operacional no disco de 2TB
- Seleção de OS funcional via BIOS boot menu
- Nenhuma perda de dados em /home
- Validation gates passando
