# Cerebelo: Migração extlinux FAT → ext4

## Contexto

O FAT de 200MB (`/boot`, nvme0n1p1) enche durante `nixos-rebuild boot` porque
`extlinux-conf-builder.sh` copia arquivos da geração atual **e** das N anteriores
antes de remover as obsoletas. Dois conjuntos de device-tree-overlays (87MB cada)
já ultrapassam o limite.

A solução oficial (`examples/upstream-opi` no repo `nixos-rk3588`) é mover o
extlinux para o root ext4. O mecanismo é simples: quando `/boot` aponta para FAT
e `/boot/firmware` para FAT, o NixOS escreve extlinux em `/boot/extlinux/` (FAT).
Quando `/boot/firmware` aponta para FAT e `/boot` é o root ext4 (sem mount point
separado), o NixOS escreve extlinux em `/boot/extlinux/` no ext4.

O U-Boot Armbian no SPI usa `distro_bootcmd` padrão, que escaneia partições em
ordem: FAT primeiro, ext4 depois. Se FAT não tiver extlinux, cai para ext4.

---

## Estado atual

- cerebelo está online (`rk@192.168.1.X`), rodando a vanilla image (hostname `orangepi5`)
- FAT 100% cheio com arquivos de tentativas anteriores:
  ```
  nzxpljfk85x8xl0xf0zld2adyh15ad7k-device-tree-overlays   87MB  completo ✓ cerebelo
  jvvkwxjdfjqf10d22q0vi3nmglsva7a6-initrd-k-initrd         11MB  completo ✓ cerebelo
  vf515si92mxc38fh6gb96vxzvj1l11l3-k-Image                 39MB  completo ✓ cerebelo
  mc2lj043yhf613hvzi0cilmvqi0vdwc0-initrd-k-initrd         10MB  vanilla, não necessário
  icvzz19129ppl40fa55kk7pqg7avwh2b-device-tree-overlays.tmp.1580  32MB  parcial, falhou
  RPi firmware files                                        ~21MB  ignorados pelo U-Boot OPi5
  ```
- Fases 1–4 do plano 072 commitadas no predator

---

## Fase 1 — Fazer cerebelo bootar a imagem NixOS (FAT, stepping stone)

cerebelo precisa estar rodando a nossa imagem NixOS antes de executar a migração
ext4. Esta fase é pré-requisito: não podemos mudar o ponto de montagem do `/boot`
de um sistema que ainda não bootou a nossa config.

### 1a. Verificar pré-condições

```bash
# Arquivos cerebelo presentes e completos
ssh rk@192.168.1.X '
  ls /boot/nixos/nzxpljfk85x8xl0xf0zld2adyh15ad7k-device-tree-overlays/rockchip/rk3588s-orangepi-5.dtb &&
  ls /boot/nixos/jvvkwxjdfjqf10d22q0vi3nmglsva7a6-initrd-k-initrd &&
  ls /boot/nixos/vf515si92mxc38fh6gb96vxzvj1l11l3-k-Image &&
  echo "todos presentes"
'

# Backup do extlinux.conf atual
ssh rk@192.168.1.X 'cp /boot/extlinux/extlinux.conf ~/boot-backup-extlinux.conf && cat ~/boot-backup-extlinux.conf'
```

### 1b. Mudança no predator: configurationLimit = 0

Arquivo: `modules/features/system/rk3588-orangepi5.nix`

```nix
boot.loader.generic-extlinux-compatible = {
  enable = lib.mkForce true;
  configurationLimit = 0;  # temporário: FAT de 200MB não comporta rollback
};
```

`configurationLimit = 0` faz o script passar `-g 0`, que copia apenas a geração
atual e remove tudo o mais. Ao contrário de `= 1` (que ainda copia kernel+initrd
da vanilla antes de remover), `= 0` não precisa de espaço para nada além do que
já está no FAT.

Validar:
```bash
nix eval .#nixosConfigurations.cerebelo.config.boot.loader.generic-extlinux-compatible.configurationLimit
# esperado: 0
./scripts/run-validation-gates.sh cerebelo
```

Commit: `fix(cerebelo): configurationLimit=0 stepping stone for ext4 migration`

### 1c. Sync para cerebelo

```bash
rsync -avz -e "sshpass -p 'rk3588' ssh -o StrictHostKeyChecking=no" \
  --exclude='.git' --exclude='scripts/' \
  . rk@192.168.1.X:~/nixos-config/
```

### 1d. Liberar espaço no FAT

Arquivos a remover (não são necessários para o boot do cerebelo):
- `.tmp.1580`: cópia parcial que falhou, 32MB
- `mc2lj...initrd`: initrd da vanilla, 10MB

```bash
ssh rk@192.168.1.X 'echo rk3588 | sudo -S bash -c "
  set -e
  # Backup do estado atual antes de qualquer remoção
  ls -lh /boot/nixos/ > ~/boot-nixos-before-cleanup.txt
  df -h /boot >> ~/boot-nixos-before-cleanup.txt

  rm -rf /boot/nixos/icvzz19129ppl40fa55kk7pqg7avwh2b-device-tree-overlays.tmp.1580
  rm -f  /boot/nixos/mc2lj043yhf613hvzi0cilmvqi0vdwc0-initrd-k-initrd

  df -h /boot
  ls -lh /boot/nixos/
"'
```

Esperado: ~42MB livres no FAT.

**Se `df` ainda mostrar 100%:** não prosseguir; diagnosticar o que ocupa espaço.

### 1e. nixos-rebuild boot

```bash
ssh rk@192.168.1.X 'echo rk3588 | sudo -S bash -c "
  cd /home/rk/nixos-config &&
  nixos-rebuild boot --flake .#cerebelo > /tmp/rebuild.log 2>&1
  echo exit:$?
"'
```

**Se exit != 0:** ler log antes de qualquer outra ação:
```bash
ssh rk@192.168.1.X 'tail -100 /tmp/rebuild.log'
ssh rk@192.168.1.X 'grep -i "error\|failed\|no space" /tmp/rebuild.log | tail -30'
```

### 1f. Verificar extlinux.conf antes do reboot

**Só prosseguir com reboot se TODAS as condições forem verdadeiras:**

```bash
ssh rk@192.168.1.X 'cat /boot/extlinux/extlinux.conf'
```

Verificar no conteúdo:
- `nixos-system-cerebelo-` presente no `init=` (não `orangepi5-sd-card`) ✓
- `k-Image` no `LINUX` ✓
- `root=UUID=14e19a7b-` no `APPEND` ✓
- `rk3588s-orangepi-5.dtb` no `FDT` ✓

```bash
ssh rk@192.168.1.X 'df -h /boot'
```

FAT não pode estar 100% cheio.

### 1g. Reboot

```bash
ssh rk@192.168.1.X 'echo rk3588 | sudo -S reboot'
```

Aguardar ~60s. IP pode mudar (DHCP):
```bash
for ip in $(seq 20 50); do
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 -o BatchMode=yes \
    higorprado@192.168.1.$ip 'echo found' 2>/dev/null && echo "IP: 192.168.1.$ip" && break
done
```

Validação pós-reboot:
```bash
ssh higorprado@<ip> '
  uname -r        # → 6.1.115
  hostname        # → cerebelo
  findmnt -n -o SOURCE /       # → /dev/nvme0n1p2
  findmnt -n -o SOURCE /boot   # → /dev/nvme0n1p1
'
```

**Fallback Fase 1:** Se nixos-rebuild falhar, nenhum reboot foi feito; cerebelo
continua acessível via SSH na vanilla image. Ler log, corrigir, repetir.
Se o reboot não devolver o sistema: sem acesso físico não há recuperação automática.
A mitigação é a Fase 1f — só fazer reboot com extlinux.conf verificado.

---

## Fase 2 — Migração: extlinux passa para root ext4

Executar a partir do cerebelo rodando nossa imagem NixOS (após Fase 1).

### 2a. Mudanças no predator

**`hardware/cerebelo/hardware-configuration.nix`**: trocar `/boot` (vfat) por
`/boot/firmware` (vfat). Sem mount separado para `/boot`, o NixOS escreve
extlinux em `/boot/extlinux/` no root ext4.

```nix
fileSystems."/boot/firmware" = {
  device = "/dev/disk/by-uuid/${storage.nvmeBootUuid}";
  fsType = "vfat";
  options = [ "umask=0077" ];
};
```

**`modules/features/system/rk3588-orangepi5.nix`**: remover `configurationLimit`
(revert do stepping stone da Fase 1). O default (20) funciona no ext4.

```nix
boot.loader.generic-extlinux-compatible = {
  enable = lib.mkForce true;
};
```

Validar e commitar:
```bash
nix eval .#nixosConfigurations.cerebelo.config.boot.loader.generic-extlinux-compatible.configurationLimit
# esperado: 20 (default)
./scripts/run-validation-gates.sh cerebelo
```

Commit: `feat(cerebelo): migrate extlinux to root ext4, FAT as /boot/firmware`

### 2b. Sync e nixos-rebuild boot no cerebelo

```bash
rsync -avz -e "ssh" \
  --exclude='.git' --exclude='scripts/' \
  . higorprado@<ip>:~/nixos-config/

ssh higorprado@<ip> 'sudo bash -c "
  cd /home/user/nixos-config &&
  nixos-rebuild boot --flake .#cerebelo > /tmp/rebuild-ext4.log 2>&1
  echo exit:$?
"'
```

**Se exit != 0:** ler log, não prosseguir.

### 2c. Verificar que extlinux foi escrito no ext4

```bash
ssh higorprado@<ip> 'cat /boot/extlinux/extlinux.conf'
```

Este `/boot/extlinux/extlinux.conf` agora está no root ext4 (nvme0n1p2), não
no FAT. Verificar:
- `nixos-system-cerebelo-` no `init=` ✓
- `k-Image` no `LINUX` ✓
- `root=UUID=14e19a7b-` no `APPEND` ✓
- `rk3588s-orangepi-5.dtb` no `FDT` ✓

Verificar também que o FAT ainda tem o extlinux antigo (da Fase 1):
```bash
ssh higorprado@<ip> 'cat /boot/firmware/extlinux/extlinux.conf'
# Deve mostrar extlinux.conf da Fase 1 (apontando para cerebelo, via FAT)
```

### 2d. Reboot (seguro — FAT extlinux ainda presente)

Neste reboot, o U-Boot encontra o FAT extlinux (da Fase 1) e boota o cerebelo.
O sistema que boota já usa `/boot/firmware` para o FAT e tem o extlinux no ext4
para a próxima fase.

```bash
ssh higorprado@<ip> 'sudo reboot'
```

Validar após boot (mesmas checagens da Fase 1g).

**Fallback Fase 2:** O FAT ainda tem o extlinux da Fase 1. Qualquer falha na
Fase 2 deixa o sistema bootável via FAT extlinux. Corrigir no predator, repetir.

---

## Fase 3 — Remover extlinux do FAT (risco controlado)

Esta fase é o ponto sem retorno sem acesso físico. Executar apenas se:
- Fase 2 concluída e cerebelo online com a nossa imagem
- `/boot/extlinux/extlinux.conf` (ext4) verificado e correto
- `/boot/firmware/extlinux/extlinux.conf` (FAT) ainda presente como fallback

### 3a. Verificações antes da remoção

```bash
ssh higorprado@<ip> '
  echo "=== ext4 extlinux ===" &&
  cat /boot/extlinux/extlinux.conf &&
  echo "=== FAT extlinux ===" &&
  cat /boot/firmware/extlinux/extlinux.conf &&
  echo "=== findmnt ===" &&
  findmnt -n -o SOURCE /boot/firmware  # → /dev/nvme0n1p1 (FAT)
'
```

### 3b. Backup do extlinux FAT

```bash
ssh higorprado@<ip> 'cp -r /boot/firmware/extlinux ~/boot-firmware-extlinux-backup'
```

### 3c. Remover extlinux do FAT

```bash
ssh higorprado@<ip> 'sudo bash -c "
  rm -rf /boot/firmware/extlinux
  ls /boot/firmware/  # não deve mais conter extlinux/
"'
```

### 3d. Reboot — teste do U-Boot ext4

```bash
ssh higorprado@<ip> 'sudo reboot'
```

U-Boot escaneia FAT: não encontra extlinux → escaneia ext4 → encontra
`/boot/extlinux/extlinux.conf` → boota cerebelo.

Aguardar ~60s, escanear subnet:
```bash
for ip in $(seq 20 50); do
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 -o BatchMode=yes \
    higorprado@192.168.1.$ip 'echo found' 2>/dev/null && echo "IP: 192.168.1.$ip" && break
done
```

Validação final:
```bash
ssh higorprado@<ip> '
  uname -r        # → 6.1.115
  hostname        # → cerebelo
  findmnt -n -o SOURCE /              # → /dev/nvme0n1p2
  findmnt -n -o SOURCE /boot/firmware # → /dev/nvme0n1p1
  cat /boot/extlinux/extlinux.conf    # ext4, deve ter nixos-system-cerebelo-
'
```

**Fallback Fase 3:** Se o sistema não voltar após remover o FAT extlinux,
o U-Boot Armbian não escaneou ext4. Sem acesso físico, não há recuperação.

Mitigação: a Fase 3 só acontece depois que cerebelo está online com a nossa
imagem (Fase 1) e o ext4 extlinux foi escrito e verificado (Fase 2). O risco é
apenas o comportamento do U-Boot Armbian no SPI. Se o usuário tiver acesso serial
(ttyS2, 1500000 baud) ou HDMI+teclado disponíveis, a Fase 3 se torna segura.

---

## Definition of Done

- Fase 1: `hostname` = `cerebelo`, `uname -r` = `6.1.115`, boot via FAT extlinux ✓
- Fase 2: `/boot/extlinux/extlinux.conf` (ext4) contém `nixos-system-cerebelo-` ✓
- Fase 3: `findmnt /boot/firmware` = nvme0n1p1 (FAT), boot via ext4 extlinux ✓,
  FAT sem `/extlinux/` ✓, `configurationLimit` no default (20 gerações) ✓
