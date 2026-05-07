# Code Quality Audit Report — 2026-05-06

## Scope

Análise completa de todos os arquivos `.nix` rastreados, scripts de validação e
docs. Não houve edições. Apenas leitura e execução dos gates de validação.

## Metodologia

1. Leitura dos docs operacionais (000–007, 999).
2. Leitura de todos os arquivos `.nix` rastreados (~122 arquivos).
3. Execução de `./scripts/run-validation-gates.sh structure` — **PASS**.
4. Execução de `nix eval path:$PWD#nixosConfigurations.{predator,aurelius,cerebelo}.config.system.stateVersion` — **todos PASS**.

---

## Sumário

| Severidade  | Contagem |
| ----------- | -------- |
| Crítico     | 0        |
| Alto        | 1        |
| Médio       | 1        |
| Baixo       | 1        |
| Informativo | 2        |

---

## Achados

### 1. [ALTO] Repo map desatualizado — 2 feature files não documentados

**Arquivo:** `docs/for-agents/001-repo-map.md`

Dois arquivos de feature existem em `modules/features/` mas não estão listados no
repo map. O `check-docs-drift.sh` só valida que referências em docs apontam para
caminhos existentes — não verifica completude (se todo arquivo está documentado).

| Arquivo                                | Onde deveria estar no repo map |
| -------------------------------------- | ------------------------------ |
| `dev/llm-paseo.nix`                    | Seção **Dev / Editors / LLM**  |
| `media/aiostreams-tailscale-serve.nix` | Seção **Media**                |

**Risco:** Agentes e humanos consultam o repo map como fonte autoritativa. Um
arquivo não documentado pode ser esquecido em refactors, removido acidentalmente,
ou duplicado.

**Ação sugerida:** Adicionar ambas as entradas no repo map.

---

### 2. [MÉDIO] Cerebelo usa `_module.args` — exceção documentada ao padrão dendritic

**Arquivo:** `modules/hosts/cerebelo.nix` (linhas 52-60)

```nix
_module.args.rk3588 = {
  inherit pkgsKernel;
  nixpkgs = upstreamNixpkgs;
};
_module.args.nixos-generators = null;
```

O padrão dendritic proíbe `specialArgs`/`extraSpecialArgs`. `_module.args` é
equivalente funcional. O código tem comentários explícitos marcando isso como
"narrow board-compatibility bridge for cerebelo only" e "should not be copied to
unrelated host/feature modules".

**Risco:** Baixo no momento — a exceção é auto-documentada e isolada. O risco
é que futuros mantenedores copiem o padrão sem entender que é uma exceção.

**Ação sugerida:** Nenhuma imediata. Monitorar se o upstream `nixos-rk3588`
eventualmente remove a dependência de `_module.args`, permitindo eliminar a
ponte.

---

### 3. [BAIXO] Repetição excessiva de provisioning copy-once em waybar.nix e walker.nix

**Arquivos:**

- `modules/features/desktop/waybar.nix` — 7 entradas `home.activation.provisionWaybar*` quase idênticas
- `modules/features/desktop/walker.nix` — 8 entradas `home.activation.provisionElephant*` quase idênticas

Cada entrada segue o mesmo padrão:

```nix
home.activation.provisionFoo = lib.hm.dag.entryAfter [ "writeBoundary" ] (
  mutableCopy.mkCopyOnce {
    source = ../../../config/apps/foo/file;
    target = "$HOME/.config/foo/file";
  }
);
```

**Nota:** A lição 25 diz: "Desktop composition duplication is intentional
explicitness." Isso pode se estender a feature modules também. A repetição é
consistente com a filosofia do repo.

**Ação sugerida:** Opcional — extrair para um helper `provisionCopyOnce` que
aceita `{source, target, mode?}` reduziria ~40 linhas sem perda de clareza.

---

### 4. [INFORMATIVO] `networking*.nix` usa glob pattern ambíguo no repo map

**Arquivo:** `docs/for-agents/001-repo-map.md`, seção System

A entrada `system/networking*.nix` é ambígua — não lista explicitamente quais
arquivos existem:

- `system/networking.nix`
- `system/networking-avahi.nix`
- `system/networking-resolved.nix`
- `system/networking-wireguard-client.nix`
- `system/networking-wireguard-server.nix`

**Ação sugerida:** Expandir o glob para a lista explícita no repo map.

---

### 5. [INFORMATIVO] `nix-cache-settings` é importado só em predator — correto mas frágil

**Arquivo:** `modules/features/core/nix-cache-settings.nix`

O módulo tem o comentário: "Import this only on hosts that benefit from these
desktop/dev upstream caches." Está importado apenas em `modules/hosts/predator.nix`,
não em aurelius/cerebelo. Isso está correto.

Porém, se um novo host desktop for adicionado, é fácil esquecer de importar este
módulo. O comentário no próprio módulo serve como lembrete, mas não há checagem
automatizada.

**Ação sugerida:** Se o número de hosts crescer, considerar adicionar uma regra
no `check-extension-contracts.sh` ou similar.

---

## Verificações de segurança

| Check                                                | Resultado |
| ---------------------------------------------------- | --------- |
| `openssh.authorizedKeys.keys` em arquivos rastreados | ✅ Nenhum |
| `environment.systemPackages` em `hardware/`          | ✅ Nenhum |
| Hardcoded usernames/paths em `modules/features/`     | ✅ Nenhum |
| Role conditionals (`mkIf custom.host.role`)          | ✅ Nenhum |
| Bare `{ host }:` lambdas                             | ✅ Nenhum |
| Flake inputs não utilizados                          | ✅ Nenhum |
| Feature publisher name mismatch                      | ✅ Nenhum |
| Private data leak em tracked files                   | ✅ Nenhum |
| Legacy desktop selector references                   | ✅ Nenhum |

---

## Qualidade geral

O código é de **alta qualidade**. Padrões observados:

- **Consistência:** Todo módulo publica via `flake.modules.{nixos,homeManager}.*`.
- **Narrow owners:** Cada feature tem escopo bem definido. Split NixOS/HM é
  aplicado corretamente (fish, ssh, docker, hyprland, editors-neovim, etc.).
- **Host composition explícita:** Três hosts com imports declarativos, sem
  geradores escondidos ou data-driven toggles.
- **Documentação interna:** Comentários explicam decisões não-óbvias (ex: TPM2
  stage-1 no root-reset.nix, Steam tray icon patch, WireGuard IPv6 toggle).
- **Private safety:** `.example` files para shapes, optional imports com
  `builtins.pathExists`, allowlist para falsos positivos.
- **Validation gates abrangentes:** 15+ checks estáticos + eval matrix.

**Nota:** 10/10 — não foram encontradas violações das regras operacionais.
