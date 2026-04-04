# Cyberpunk 2077 — foco, fullscreen e performance no DMS/niri

## Goal

Corrigir dois problemas na execução do Cyberpunk 2077 via Proton no predator:
(1) gap no topo da tela e (2) foco não entra na janela ao abrir. Como meta
secundária, habilitar env vars de performance para DLSS SR e NVIDIA Reflex.

## Scope

In scope:
- Correção do modo de janela no jogo (Borderless Windowed + resolução correta)
- Window-rule niri para foco em `config/desktops/dms-on-niri/custom.kdl`
- Env vars de performance em `modules/features/desktop/gaming.nix`
- Perfis GLVidHeapReuseRatio para XWayland em `hardware/predator/hardware/gpu-nvidia.nix`

Out of scope:
- DLSS Frame Generation (não implementado no Proton — veja nota abaixo)
- Migração para gamescope
- Configuração de HDR
- Redução do gap VKD3D-Proton vs Windows nativo (problema arquitetural sem fix disponível)

## Current State

- Todas as correções estão commitadas em `feat/gaming-fixes` (commit 5e7b907)
- Monitor: Samsung QN90D, HDMI-A-1, 3840×2160 @ 144Hz, escala 1.5 → lógico 2560×1440
- Jogo configurado: Borderless Windowed, 2560×1440 (corrigido pelo usuário)
- Window-rule com `open-focused true` ativa em custom.kdl
- `VKD3D_CONFIG=no_upload_hvv` sistema-wide (gaming.nix)
- `VKD3D_CONFIG=no_upload_hvv,nodxr` nas launch options do jogo (workaround de crash)
- Performance atual: ~50 FPS com DLSS Performance, RT desabilitado via nodxr, 7GB VRAM

## Desired End State

- Cyberpunk abre cobrindo o monitor inteiro sem gap (concluído)
- Foco entra na janela imediatamente ao abrir (concluído)
- DLSS Super Resolution funcionando via `PROTON_ENABLE_NVAPI` (concluído)
- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel` → ok
- `./scripts/run-validation-gates.sh` → ok

## Phases

### Phase 0: Baseline

Status: concluído.

Validation:
- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel.drvPath` → ok
- `./scripts/run-validation-gates.sh` → ok

### Phase 1: Correção do jogo (ação do usuário)

Status: concluído.

No menu de vídeo do jogo, usuário alterou:
- `Window Mode` → Windowed Borderless
- `Resolution` → 2560×1440

Rationale: em Fullscreen, CP2077 tenta trocar a resolução via XRandR (3200×1800).
XWayland não consegue honrar a troca; a janela fica maior que os 2560×1440 lógicos
disponíveis, criando o gap. Borderless cria janela do tamanho exato do display.

### Phase 2: Corrigir offset do display HDMI

Status: concluído (usuário editou `~/.config/niri/dms/outputs.kdl` diretamente).

O DMS gerava HDMI em `position x=1920 y=0` porque eDP-1, mesmo desligada, ocupava
o espaço lógico x=0. Correção manual no arquivo ao vivo; repo reflete o estado correto.

### Phase 3: Window-rule para o jogo

Status: concluído.

`config/desktops/dms-on-niri/custom.kdl` contém:
```kdl
window-rule {
    match title=r#"Cyberpunk 2077"#
    open-focused true
    geometry-corner-radius 0
    clip-to-geometry false
}
```

### Phase 4: Env vars de performance

Status: concluído.

`modules/features/desktop/gaming.nix` — bloco `extraEnv` do Steam:
- `PROTON_USE_NTSYNC = "1"` — ativa ntsync (módulo já carregado em gaming.nix:8)
- `PROTON_ENABLE_NVAPI = "1"` — expõe NVAPI; necessário para DLSS SR e Reflex
- `PROTON_ENABLE_NGX_UPDATER = "1"` — atualiza DLLs DLSS SR para versão mais recente
- `VKD3D_CONFIG = "no_upload_hvv"` — força upload heaps para RAM em vez de VRAM
  (com ReBAR ativo e 8GB, VKD3D usava VRAM para staging buffers, comendo budget de render)

Nota sobre DLSS Frame Generation: **não implementado no Proton** (issue ValveSoftware/Proton#6500).
Requer implementação direta da NVIDIA (como foi feito para DLSS SR). O env var
`PROTON_ENABLE_NGX_UPDATER` atualiza as DLLs de DLSS SR; FG permanece inoperante.

### Phase 5: GLVidHeapReuseRatio para XWayland

Status: concluído.

`hardware/predator/hardware/gpu-nvidia.nix` — perfis adicionados para xwayland-satellite
e Xwayland, limitando o free buffer pool (GLVidHeapReuseRatio=0). Impacto prático baixo
para esses processos (uso de VRAM ~2MB cada), mas alinha com perfil já aplicado ao niri.

## Riscos e Limitações Conhecidas

- **Gap VKD3D-Proton vs Windows**: ~10 FPS de diferença com RT desabilitado é um
  problema arquitetural conhecido (issue HansKristian-Work/vkd3d-proton#2249, fechado
  sem fix). NVIDIA tem otimização em desenvolvimento (anunciada ago/2025), sem data.

- **DXR/RT**: `nodxr` está nas launch options do jogo como workaround de crash.
  O driver 580.x tem um bug aberto com CP2077 + RT (issue #2756, open). Não há
  caminho limpo para reabilitar RT em 8GB NVIDIA sem risco de crash. Manter nodxr.

- **`force_static_cbv`**: único flag VKD3D documentado como "speed hack NVIDIA" — mas
  sem dados para Ada Lovelace e causa freeze em alguns jogos (Horizon Zero Dawn).
  Não adicionado; risco vs benefício indefinido.

- **DMS re-geração de outputs.kdl**: se o DMS detectar mudança de monitor, pode
  regenerar outputs.kdl e o offset do HDMI voltar. Monitorar após reconexão de displays.

## Definition of Done

- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel` → ok
- `./scripts/run-validation-gates.sh` → ok
- `./scripts/check-repo-public-safety.sh` → ok
- Cyberpunk abre sem gap, foco imediato, DLSS SR ativo (FG não disponível no Linux)
- Commits em `feat/gaming-fixes` antes do merge na main
