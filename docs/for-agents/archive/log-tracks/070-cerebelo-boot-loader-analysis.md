# Cerebelo Boot Loader Analysis

## Status

Blocked — NVMe ext4 corrompido. Requer re-flash e deploy correto.

## Related Plan

- [070-cerebelo-host-setup.md](/home/higorprado/nixos/docs/for-agents/plans/070-cerebelo-host-setup.md)

---

## 1. O que a documentação oficial diz

Fonte: nixos-rk3588 (gnull/nixos-rk3588).

Para instalar em SSD/NVMe:

1. Bootar pelo SD card com a imagem NixOS para Orange Pi 5.
2. Gravar a imagem completa no NVMe:
   ```bash
   zstdcat orangepi5-sd-image-*.img.zst | sudo dd bs=4M status=progress of=/dev/nvme0n1
   ```
3. Remover SD card, reiniciar. O sistema boota do NVMe.
4. Usar `nixos-rebuild` para atualizar o sistema.

A documentação não detalha como `nixos-rebuild` interage com a partição FAT de boot.

---

## 2. Layout de boot do Orange Pi 5 (RK3588S)

| Partição | Dispositivo | Filesystem | Conteúdo | Mount no SD image |
|----------|-------------|------------|----------|-------------------|
| p1 | nvme0n1p1 | vfat (200 MB, label BOOT) | extlinux.conf, kernel Image, initrd, DTBs | `/boot/firmware` (noauto) |
| p2 | nvme0n1p2 | ext4 (UUID 14e19a7b…) | root, nix store, `/boot/extlinux/extlinux.conf` | `/` |

**U-Boot lê:** nvme0n1p1 `/extlinux/extlinux.conf` (partição FAT).

**NixOS escreve:** `/boot/extlinux/extlinux.conf` — no filesystem montado em `/boot`.

No SD image padrão, `/boot` está no ext4 root (nvme0n1p2). Logo:

- `nixos-rebuild` escreve em ext4 `/boot/extlinux/extlinux.conf`.
- U-Boot lê da FAT `/extlinux/extlinux.conf`.
- **Os dois arquivos divergem após o primeiro rebuild.** U-Boot nunca vê a nova geração.

---

## 3. Erros cometidos e suas causas

### 3.1 — `hardware-configuration.nix`: montagem incorreta da FAT

A FAT foi declarada como `/boot/firmware` (noauto) seguindo o shape gerado pela imagem.
Isso é funcionalmente incorreto para deploys futuros: nixos-rebuild jamais escreve no
lugar que U-Boot lê.

**Correção necessária:** montar a FAT em `/boot` (sem noauto), para que
`boot.loader.generic-extlinux-compatible` escreva diretamente na FAT.

### 3.2 — Aplicação da correção via `nixos-rebuild switch`

Quando a correção do mount point foi aplicada via `switch` num sistema ao vivo:

1. O activation script escreveu o novo extlinux.conf em `/boot/extlinux/` (ext4, pois
   a FAT ainda estava em `/boot/firmware` no sistema corrente).
2. O systemd parou `boot-firmware.mount` e tentou ativar o novo mount em `/boot`.
3. Durante essa transição com desmontagem de partição vfat e remontagem em caminho
   diferente, a escrita no ext4 (que estava ocorrendo simultaneamente) corrompeu o
   filesystem.
4. Resultado: inode 767 (`/nix/store`) perdeu extents; `/nix/var` foi deletado do
   diretório; `/etc/fstab` desapareceu.

**Regra derivada:** nunca aplicar mudança de mount point via `switch` num sistema vivo.
A ferramenta correta é `nixos-install` sobre partição desmontada, ou `nixos-rebuild boot`
seguido de reboot (sem garantia de que o bootloader seja gravado no lugar correto neste
caso — ver §4).

### 3.3 — `nixos-rebuild boot` também não resolve o bootstrap

Mesmo com `nixos-rebuild boot` (que não troca serviços ao vivo), o bootloader installer
escreve em `/boot/extlinux/` do sistema corrente. Se o sistema corrente ainda tem
`/boot` no ext4, o arquivo escrito vai para o lugar errado. A FAT permanece com a
geração antiga.

A mudança de mount point só tem efeito no próximo boot. O primeiro boot após a mudança
ainda usa a FAT antiga.

---

## 4. Abordagem correta

A ferramenta indicada para instalar num disco que não está montado como root é
`nixos-install`. Ela aceita `--root /mnt` e escreve o bootloader no filesystem montado
em `/mnt/boot` — que pode ser a FAT do NVMe.

**Fluxo correto:**

```
[predator]            [cerebelo – SD card]          [NVMe]
                      boots from mmcblk1
                      mounts nvme0n1p2 → /mnt
                      mounts nvme0n1p1 → /mnt/boot   ← FAT aqui
nh / nixos-rebuild
build → copy to SD ──► nixos-install
                        escrita em /mnt/boot/extlinux/extlinux.conf ← FAT ✓
                        copia kernel/initrd/DTBs em /mnt/boot/nixos/ ← FAT ✓
                        copia nix store em /mnt/nix/store
                      umount /mnt/boot /mnt
                      SD removido, reboot
                                                     U-Boot lê FAT → cerebelo ✓
```

**hardware-configuration.nix correto para este board:**

```nix
fileSystems."/boot" = {
  device = "/dev/disk/by-label/BOOT";
  fsType = "vfat";
  options = [ "umask=0077" ];
};
```

Sem `noauto`. Com FAT em `/boot`, todos os `nixos-rebuild` futuros (switch, boot)
escrevem no lugar correto.

---

## 5. Estado atual do NVMe (pós-fsck)

| Item | Estado |
|------|--------|
| nvme0n1p1 (FAT) | Intacta. extlinux.conf original (orangepi5-sd-card). Kernel/DTBs presentes. |
| nvme0n1p2 (ext4) | Reparado por e2fsck mas inutilizável: `/etc/fstab` ausente, `/nix/var` ausente. |
| Init orangepi5-sd-card | Presente no nix store (`gqahwas8…`). |
| Sistema cerebelo | Não bootável. |

**Ação necessária:** re-flash do NVMe com a imagem (`dd`), depois `nixos-install`.

---

## 6. Plano de recuperação — fatias simples e testáveis

### Fatia 1 — Re-flash do NVMe

**Pré-condição:** cerebelo bootar do SD card, IP acessível.

**Ação:**
```bash
# No cerebelo (via SSH, rk@IP):
zstdcat ~/orangepi5-sd-image.img.zst | sudo dd bs=4M status=progress of=/dev/nvme0n1
sync
```

**Validação:**
```bash
# No cerebelo:
sudo mount /dev/nvme0n1p1 /tmp/fat
cat /tmp/fat/extlinux/extlinux.conf   # deve conter FDT e kernel original
sudo umount /tmp/fat
```

**Critério de aceite:** extlinux.conf na FAT do NVMe idêntico ao da imagem original.

**Regressão possível:** nenhuma — NVMe estava corrompido; re-flash só melhora.

---

### Fatia 2 — Verificar hardware-configuration.nix

**Pré-condição:** Fatia 1 concluída.

**Ação:** confirmar que `hardware/cerebelo/hardware-configuration.nix` declara:
- `fileSystems."/boot"` com `device = "/dev/disk/by-label/BOOT"`, `fsType = "vfat"`,
  sem `noauto`.
- `hardware.deviceTree.name = "rockchip/rk3588s-orangepi-5.dtb"`.
- `fileSystems."/"` com UUID correto.
- `fileSystems."/data"` com UUID correto do HDD.

**Validação:**
```bash
nix eval path:$PWD#nixosConfigurations.cerebelo.config.fileSystems."/boot".device
# → "/dev/disk/by-label/BOOT"
nix eval path:$PWD#nixosConfigurations.cerebelo.config.hardware.deviceTree.name
# → "rockchip/rk3588s-orangepi-5.dtb"
```

**Critério de aceite:** eval sem erros, valores corretos.

---

### Fatia 3 — nixos-install com FAT em /mnt/boot

**Pré-condição:** Fatia 2 concluída. Cerebelo bootar do SD card.

**Ação (no cerebelo via SSH):**
```bash
sudo mkdir -p /mnt
sudo mount /dev/nvme0n1p2 /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/nvme0n1p1 /mnt/boot

# Verificar antes de instalar:
ls /mnt/boot/extlinux/extlinux.conf   # deve existir (imagem recém-flashada)

# Instalar (build ocorre no próprio cerebelo — aarch64 nativo):
sudo nixos-install --no-root-passwd --flake ~/nixos-config#cerebelo --root /mnt
```

**Validação pós-install (ainda com SD card):**
```bash
cat /mnt/boot/extlinux/extlinux.conf
# deve referenciar kernel cerebelo (wwcqp5h6…) e FDT rk3588s-orangepi-5.dtb

ls /mnt/boot/nixos/
# deve conter kernel Image, initrd e DTBs da geração cerebelo
```

**Critério de aceite:** extlinux.conf na FAT aponta para geração cerebelo com FDT correto.

**Regressão possível:** nenhuma enquanto SD card estiver inserido — NVMe não é o boot ativo.

---

### Fatia 4 — Boot do NVMe sem SD card

**Pré-condição:** Fatia 3 validada.

**Ação:** remover SD card, religar.

**Validação:**
```bash
ssh higorprado@<IP-cerebelo> nixos-version
# deve retornar versão da flake atual (não orangepi5-sd-card)
ssh higorprado@<IP-cerebelo> swapon --show
# deve mostrar zram
```

**Critério de aceite:** sistema cerebelo online, acessível via SSH como `higorprado`.

---

## 7. Riscos residuais

| Risco | Mitigação |
|-------|-----------|
| nixos-install baixa dependências (catppuccin etc.) — requer internet no cerebelo | Confirmar `curl -s https://github.com` antes de iniciar |
| FAT tem 200 MB — kernel cerebelo (62 MB) + initrd (11 MB) + DTBs ≈ 75 MB; cabe | Confirmar `df -h /mnt/boot` após mount |
| UUID do `/data` (HDD Seagate) pode mudar | Confirmar com `sudo blkid /dev/sda1` antes da Fatia 3 |
| Mesma label BOOT no SD e NVMe — mount por label pode pegar SD se inserido | Usar `/dev/nvme0n1p1` explícito nos mounts da Fatia 3, não `by-label` |
