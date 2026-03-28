# Cerebelo — Agent Handoff

## 1. O repositório

`/home/higorprado/nixos` é uma configuração NixOS gerenciada por flake, usando o
padrão dendrítico sem `den`. Estrutura relevante:

| Caminho | Papel |
|---------|-------|
| `flake.nix` | Entry point; usa `import-tree` para auto-descobrir `modules/` |
| `modules/hosts/*.nix` | Composição de features por host |
| `hardware/<host>/` | Hardware config, boot config, performance |
| `private/` | Overrides não rastreados (SSH keys, sudoers) — `.gitignore`'d |
| `docs/for-agents/plans/` | Planos de execução ativos |
| `docs/for-agents/current/` | Logs de progresso e análises em andamento |
| `scripts/run-validation-gates.sh` | Gates de validação locais |
| `.github/workflows/validate.yml` | CI |

**Regras absolutas do repositório:**
- Sem `mkIf` — padrão dendrítico (ler `docs/for-humans/architecture/`).
- Todo arquivo novo em `modules/` precisa de `git add` antes de ser avaliado
  (`import-tree` só vê arquivos rastreados pelo git).
- Sem `Co-Authored-By` nos commits.
- Validações devem rodar antes de declarar trabalho concluído.

**Documentação de referência para este trabalho:**
- Plano original: `docs/for-agents/plans/070-cerebelo-host-setup.md`
- Análise técnica do problema de boot: `docs/for-agents/current/070-cerebelo-boot-loader-analysis.md`

---

## 2. O que estamos tentando fazer

Incorporar o host `cerebelo` (Orange Pi 5, RK3588S, aarch64-linux) ao repositório,
tornando-o gerenciado pela flake com o mesmo padrão dos demais hosts (`predator`,
`aurelius`).

O resultado esperado:
- `nixosConfigurations.cerebelo` na flake, avaliado sem erros.
- Boot do NVMe com o config cerebelo (não a imagem genérica `orangepi5-sd-card`).
- Usuário `higorprado` acessível via SSH, com fish, sudo, home-manager.
- `/data` montado (HDD Seagate 2 TB, `sda1`).
- zram swap ativo.

O hardware está presente e funcional. O SD card com a imagem genérica NixOS para
Orange Pi 5 está disponível em `~/Downloads/orangepi5-sd-image.img.zst` no predator.

---

## 3. O que foi feito

### Trabalho concluído antes do problema de boot

- `hardware/cerebelo/default.nix` — criado (extlinux, DTB, import de private).
- `hardware/cerebelo/hardware-configuration.nix` — criado com UUID do NVMe, HDD, DTB.
- `hardware/cerebelo/performance.nix` — criado (zram, sysctls).
- `modules/hosts/cerebelo.nix` — criado (composição de features servidor).
- `private/hosts/cerebelo/default.nix` — criado (não rastreado; SSH key + sudo).
- `private/hosts/cerebelo/default.nix.example` — criado (rastreado).
- Wiring de validação: cerebelo adicionado a `scripts/lib/validation_host_topology.sh`,
  `scripts/run-validation-gates.sh` e `.github/workflows/validate.yml`.
- `flake.lock` atualizado.

### Tentativas de deploy e seus resultados

**Tentativa 1:** `nixos-rebuild switch` direto via SSH (`rk@cerebelo`).
- Resultado: rede caiu durante switch (dhcpcd → NetworkManager). Máquina inacessível.
- Causa: switch de serviços ao vivo; NM não obteve lease DHCP a tempo.

**Tentativa 2:** Re-flash do NVMe com a imagem + correção manual do extlinux.conf na FAT.
- O extlinux.conf na FAT do NVMe foi corrigido (FDTDIR → FDT explícito).
- Resultado: sem vídeo após reboot sem SD card.
- Causa identificada posteriormente: U-Boot lê FAT; nixos-rebuild escrevia em ext4.
  O extlinux.conf na FAT apontava para geração antiga; init não encontrava sistema.

**Tentativa 3:** Alteração de `fileSystems."/boot/firmware"` para `fileSystems."/boot"`
em `hardware-configuration.nix` + `nixos-rebuild switch` via SSH.
- Resultado: filesystem ext4 do NVMe corrompido. `/nix/var` apagado. `/etc/fstab`
  desapareceu. Máquina não boota do NVMe.
- Causa: o switch tentou desmontar a FAT de `/boot/firmware` e remontar em `/boot`
  num sistema ao vivo, corrompendo o ext4 durante a transição.

**Estado atual do NVMe:**
- `nvme0n1p1` (FAT): intacta, extlinux.conf original com FDT correto.
- `nvme0n1p2` (ext4): corrompida. `e2fsck` executado; filesystem reparado estruturalmente
  mas `/nix/var` e `/etc/fstab` ausentes. Não é bootável.

**Estado atual do cerebelo:**
- Bootar do SD card, IP variável (último: `192.168.1.X`, usuário `rk`, senha `rk3588`).
- NVMe montável mas não bootável.
- Imagem `~/orangepi5-sd-image.img.zst` presente no cerebelo (`/home/rk/`).
- Config `~/nixos-config/` copiada para o cerebelo (rsync do predator).

---

## 4. O que deu errado e por quê

### Problema central

O `boot.loader.generic-extlinux-compatible` do NixOS escreve o extlinux.conf em
`/boot/extlinux/extlinux.conf` — no filesystem montado em `/boot` no sistema corrente.

No SD image padrão do nixos-rk3588, `/boot` está no ext4 root (`nvme0n1p2`). A FAT
(`nvme0n1p1`) está em `/boot/firmware` com `noauto`. Logo:

- `nixos-rebuild` → escreve em ext4.
- U-Boot → lê da FAT.
- **Divergência imediata após o primeiro rebuild.**

Para que o bootloader vá para o lugar correto, a FAT precisa estar montada em `/boot`
no momento em que o bootloader installer roda.

### Por que `nixos-rebuild switch` com a correção do mount point falhou

Quando o mount point foi alterado de `/boot/firmware` para `/boot` e aplicado via
`switch` num sistema ao vivo:

1. O activation script rodou com `/boot` ainda no ext4 (sistema corrente não mudou).
2. O systemd parou `boot-firmware.mount` (desmontou FAT de `/boot/firmware`).
3. O systemd tentou ativar `boot.mount` (montar FAT em `/boot`).
4. Durante essa transição, operações de I/O simultâneas no ext4 corromperam o filesystem.

### Hipótese sobre o mecanismo exato de corrupção

A corrupção concentrou-se no inode 767 (`/nix/store` directory) e no entry `var` do
diretório `/nix`. Hipótese: o systemd, ao desmontar `/boot/firmware`, também causou
um flush ou barreira de I/O que interagiu com writes em andamento no ext4 — possivelmente
o próprio bootloader installer ainda escrevendo arquivos em `/boot/nixos/` no ext4 quando
a barreira ocorreu.

**Não confirmado.** É possível também que o sistema tenha sido reiniciado de forma abrupta
pelo usuário durante o switch, deixando o journal do ext4 incompleto.

---

## 5. O que o próximo agente deve investigar

### 5.1 — Confirmar se a abordagem `nixos-install` é a correta

A hipótese é que `nixos-install --root /mnt` com `nvme0n1p1` montada em `/mnt/boot`
escreve o extlinux.conf diretamente na FAT. Antes de executar, verificar:

1. Ler o código do `generic-extlinux-compatible` installer no nixpkgs para confirmar
   que ele escreve em `${config.boot.loader.generic-extlinux-compatible.configurationLimit}`
   relativo ao root passado ao installer, não a um path hardcoded.
   - Path relevante em nixpkgs: `nixos/modules/system/boot/loader/generic-extlinux-compatible/`

2. Confirmar que `nixos-install` passa o `--root` como prefixo para o bootloader
   installer (deve estar em `nixos/modules/installer/tools/nixos-install.sh`).

3. Testar empiricamente: após `nixos-install`, montar `nvme0n1p1` e verificar se
   `extlinux/extlinux.conf` foi atualizado com a geração cerebelo.

### 5.2 — Confirmar que a FAT tem espaço suficiente

Kernel cerebelo: ~62 MB. Initrd: ~11 MB. DTBs: ~1 MB. Total: ~74 MB.
FAT tem 200 MB. Verificar espaço livre após mount antes de instalar.

### 5.3 — Confirmar UUID do HDD (`/data`)

`hardware-configuration.nix` tem o UUID `e47efc1f-98d8-42ab-80e1-d0e29115e6e0` para
`/dev/sda1`. Verificar que esse UUID é correto antes de instalar:

```bash
sudo blkid /dev/sda1
```

Se diferente, corrigir `hardware/cerebelo/hardware-configuration.nix` antes de prosseguir.

### 5.4 — Confirmar que o cerebelo tem acesso à internet durante o build

O `nixos-install` buildará o sistema no próprio cerebelo (aarch64 nativo). Dependências
como `catppuccin/nix` precisam ser baixadas ou estar em cache. Verificar:

```bash
curl -s --max-time 5 https://github.com && echo OK
```

Se não houver cache suficiente, copiar o closure do predator via `nix copy` antes de
instalar.

---

## 6. Recomendação

Seguir as fatias descritas em `docs/for-agents/current/070-cerebelo-boot-loader-analysis.md`,
seção 6, na ordem exata:

1. Re-flash do NVMe com a imagem (dd).
2. Validar `hardware-configuration.nix` (mount `/boot`, DTB, UUIDs).
3. `nixos-install` com NVMe montado em `/mnt` e FAT em `/mnt/boot`.
4. Validar extlinux.conf na FAT antes de remover o SD card.
5. Boot sem SD card e validar acesso SSH como `higorprado`.

**Não usar `nixos-rebuild switch` para a instalação inicial.** Usar exclusivamente
`nixos-install`. Após o primeiro boot com o config cerebelo, `nixos-rebuild switch`
é seguro (troca NM → NM, não há mudança de mount point).

**Testar cada fatia antes de avançar.** A validação da Fatia 3 (extlinux.conf na FAT
com geração cerebelo) é o gate mais crítico — é a única forma de garantir que o boot
sem SD card vai funcionar antes de remover o SD.
