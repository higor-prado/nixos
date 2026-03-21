# Aurelius — Próximos Passos

Plano de evolução do host `aurelius` (Oracle Cloud ARM, 4 vCPU Ampere A1, 24GB RAM, 200GB SSD).

> **Contexto de infra pessoal:**
>
> - **aurelius** — Oracle Cloud (Brasil), aarch64, 24GB RAM, 200GB SSD. RTT ~20ms via Tailscale. Sempre ligado, IP público, acesso via Tailscale + SSH.
> - **predator** — Desktop workstation x86_64, GPU NVIDIA, NixOS, hub de desenvolvimento.
> - **orange pi 5** — Local, 8GB RAM, 1TB SSD + 2TB HD externo. Hoje roda CachyOS + AdGuard DNS + cloud storage subutilizado. Em breve será migrado para NixOS.
> - **vpn-us** (futuro) — Google Cloud Always Free (e2-micro, EUA), instância mínima, serve apenas como Tailscale exit node para IP gringo. Plano detalhado em `vpn-exit-node-plan.md`.

## Orçamento de disco do aurelius

O SSD de 200GB é o recurso mais escasso. Planejamento de uso:

| Fatia               | Estimativa | Notas                                             |
| ------------------- | ---------- | ------------------------------------------------- |
| NixOS + nix store   | ~20 GB     | Com autoPrune semanal e `nh clean`                |
| Docker images + vol | ~15 GB     | Imagens leves, prune semanal                      |
| Binary cache (attic)| ~40 GB     | Quota hard, GC automático                         |
| Forgejo + dados     | ~5 GB      | SQLite, repos mirrors, sem LFS                    |
| Grafana + Prometheus| ~5 GB      | Retention 30d, scrape 60s                         |
| Restic repo (temp)  | ~15 GB     | Cache local transitório — repo principal no OPi5  |
| Dev remoto (home)   | ~15 GB     | devenv shells, projeto(s) ativo(s)                |
| Reserva livre       | ~85 GB     | Margem de segurança                               |

**Regra geral:** tudo que é armazenamento pesado (backups de longo prazo, media, datasets) vai pro Orange Pi 5 quando ele entrar no NixOS. O aurelius é compute + serviços leves.

---

## Fase 0 — Preparar o terreno

### 0.1 Habilitar Docker no aurelius

Adicionar `nixos.docker` ao host composition. Você já tem o módulo pronto com autoPrune semanal.

**No arquivo `modules/hosts/aurelius.nix`**, adicionar na lista de imports:

```nix
nixos.docker
```

E na seção `home-manager.users.${userName}.imports`:

```nix
homeManager.docker
```

Isso já traz os abbrs `dps`, `dpsa`, `di`, `dex` pro fish.

### 0.2 Abrir portas no firewall de forma modular

Hoje o módulo `security.nix` só abre a porta 22. Pra não ficar editando o módulo compartilhado, criar regras extras diretamente no `aurelius.nix`:

```nix
# Portas extras do aurelius (só Tailscale ou localhost em produção)
networking.firewall.allowedTCPPorts = [
  # 3000  — Forgejo (se quiser acesso direto, senão só via Tailscale)
  # 8080  — attic
  # 9090  — Prometheus
  # 3100  — Grafana
];
```

Na prática, com Tailscale, a interface `tailscale0` já bypassa o firewall (`openFirewall = true` no seu módulo). Então esses serviços ficam acessíveis via IP Tailscale sem abrir no IP público. Manter o firewall fechado no IP público é o correto.

### 0.3 Criar estrutura de diretórios no aurelius

Via SSH ou como activation script:

```bash
mkdir -p ~/services/{forgejo,grafana,prometheus,attic}
mkdir -p ~/backups
```

---

## Fase 1 — Ambiente de dev remoto headless (detalhe completo)

Este é o passo com maior impacto no dia a dia. A ideia: transformar o aurelius numa sessão de desenvolvimento persistente que sobrevive a desconexões, acessível de qualquer lugar via Tailscale.

### 1.1 Portar módulos de dev para o aurelius

**No `modules/hosts/aurelius.nix`**, adicionar aos imports do NixOS:

```nix
nixos.editor-neovim     # PAM limits pra LSP sockets
nixos.packages-toolchains  # gcc, nodejs, sqlite, cmake etc.
```

E nos imports do home-manager:

```nix
homeManager.editor-neovim    # neovim + todos os LSPs
homeManager.dev-tools        # bat, eza, gh, jq, fd, sd, uv, nixfmt
homeManager.dev-devenv       # devenv + direnv + cachix + devc
homeManager.terminal-tmux    # tmux com config customizada
homeManager.tui-tools        # lazygit, lazydocker, yazi, zellij
homeManager.starship         # prompt
homeManager.monitoring-tools # htoprc
homeManager.packages-toolchains  # bun/npm paths no fish
```

### 1.2 Resultado: o aurelius.nix completo ficaria assim

```nix
# Aurelius host composition - server + dev remote.
{ inputs, config, ... }:
let
  system = "aarch64-linux";
  hostName = "aurelius";
  hardwareImports = [
    inputs.disko.nixosModules.disko
    ../../hardware/aurelius/default.nix
  ];
in
{
  configurations.nixos.aurelius.module =
    let
      inherit (config.flake.modules) homeManager nixos;
      userName = config.username;
    in
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        # --- core ---
        nixos.system-base
        nixos.home-manager-settings
        nixos.networking
        nixos.security
        nixos.keyboard
        nixos.nixpkgs-settings
        nixos.maintenance
        nixos.tailscale
        nixos.higorprado
        nixos.nix-settings
        nixos.fish
        nixos.ssh
        # --- novo: containers ---
        nixos.docker
        # --- novo: dev ---
        nixos.editor-neovim
        nixos.packages-toolchains
        nixos.packages-server-tools
        nixos.packages-system-tools
      ] ++ hardwareImports;

      nixpkgs.hostPlatform = system;
      networking.hostName = hostName;

      home-manager = {
        users.${userName} = {
          imports = [
            homeManager.higorprado
            homeManager.core-user-packages
            homeManager.fish
            homeManager.git-gh
            homeManager.ssh
            # --- novo: dev remoto ---
            homeManager.editor-neovim
            homeManager.dev-tools
            homeManager.dev-devenv
            homeManager.terminal-tmux
            homeManager.tui-tools
            homeManager.starship
            homeManager.monitoring-tools
            homeManager.packages-toolchains
            homeManager.docker
          ];

          programs.fish.shellAbbrs = {
            naui = "nh os info";
            nausi = "nh os info";
            naust = "nixos-version --json; systemctl --failed --no-pager --legend=0 || true";
            nauc = "nh clean all";
            nauct = "systemctl status nh-clean.timer --no-pager";
          };
        };
      };

      services.openssh.settings.KbdInteractiveAuthentication = false;
    };
}
```

### 1.3 Consideração: btop-cuda no ARM

O módulo `core-user-packages` instala `pkgs.btop-cuda`. Isso não vai funcionar no aarch64 (sem NVIDIA). Você tem duas opções:

**Opção A — condicional no módulo (recomendado):**

Editar `modules/features/shell/core-user-packages.nix`:

```nix
programs.btop = {
  enable = true;
  package = if pkgs.stdenv.hostPlatform.isx86_64
    then pkgs.btop-cuda
    else pkgs.btop;
};
```

**Opção B — override no aurelius:**

No bloco home-manager do aurelius, antes dos imports:

```nix
programs.btop.package = lib.mkForce pkgs.btop;
```

A opção A é mais limpa e segue o estilo do seu repo.

### 1.4 Workflow no dia a dia

Após o deploy, o fluxo de trabalho:

```bash
# Do predator (ou qualquer dispositivo na tailnet):
ssh aurelius

# No aurelius, iniciar/reconectar sessão tmux:
tmux new -s dev    # primeira vez
tmux a -t dev      # reconectar

# Dentro do tmux, navegar até um projeto:
z meu-projeto      # zoxide
devenv shell        # ambiente isolado com deps

# Editar com neovim (todos os LSPs disponíveis):
nvim .

# Em outro pane do tmux:
lazygit             # gerenciar commits
lazydocker          # monitorar containers
```

A sessão tmux persiste indefinidamente. Fechar o terminal, desligar o predator, mudar de rede — o estado fica intacto no aurelius.

### 1.5 Mosh como fallback para redes instáveis

Com ~20ms de RTT via Tailscale, SSH puro é perfeito no dia a dia. Mas em redes ruins (café, celular, Wi-Fi de hotel), Mosh brilha: ele faz predição local de keystroke (o caractere aparece instantaneamente e corrige depois) e sobrevive a trocas de IP/rede sem reconectar.

**No aurelius**, adicionar ao host config:

```nix
programs.mosh.enable = true;
# Abre UDP 60000-61000 automaticamente no firewall
```

**No predator**, Mosh já está disponível no nixpkgs. Se não estiver instalado:

```nix
environment.systemPackages = [ pkgs.mosh ];
```

Uso:

```bash
# Conexão via Mosh (usa SSH pra autenticar, depois troca pra UDP):
mosh aurelius -- tmux new -As dev

# Via Tailscale funciona normalmente:
mosh aurelius.your-tailnet.ts.net -- tmux new -As dev
```

**Quando usar qual:**
- **SSH** — conexão estável (predator em casa, rede fixa). Mais simples, suporta port forwarding.
- **Mosh** — rede instável, alta latência, ou quando você troca de rede frequentemente (laptop em movimento).

**Dica de SSH tuning:** versões recentes do OpenSSH (9.5+) adicionam delay artificial nos keystrokes por privacidade (`ObscureKeystrokeTiming`). Isso piora a experiência em editores TUI. No `~/.ssh/config.local` do predator, considere:

```
Host aurelius
  ObscureKeystrokeTiming no
```

### 1.6 Abbrs úteis para o predator

No `predator.nix`, dentro de `home-manager.users.${userName}`, considere adicionar:

```nix
programs.fish.shellAbbrs = {
  # ... abbrs existentes ...
  adev = "ssh -t aurelius 'tmux new -As dev'";
  amdev = "mosh aurelius -- tmux new -As dev";  # via mosh
};
```

Um único comando pra conectar e já cair dentro da sessão tmux.

### 1.7 Considerações de disco para dev remoto

Cada `devenv shell` cria derivações no nix store. Com o autoPrune semanal do Docker e o `nh clean` periódico, isso se mantém sob controle. Mas adicione ao aurelius:

```nix
nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 14d";
};
```

E mantenha poucos projetos ativos simultaneamente. Se precisar de datasets grandes, monte do Orange Pi via NFS/SSHFS pela Tailscale.

---

## Fase 2 — Restic backup centralizado

### 2.1 Estratégia de storage híbrido

O aurelius **não é o destino final** de backups — ele é o orquestrador. O Orange Pi 5 (1TB SSD + 2TB HD) será o destino de longo prazo. Enquanto o OPi5 não está no NixOS, usar o aurelius como destino temporário com quota limitada.

### 2.2 Servidor restic REST no aurelius (temporário)

Criar um novo módulo `modules/features/system/restic-server.nix`:

```nix
{ ... }:
{
  flake.modules.nixos.restic-server =
    { pkgs, ... }:
    {
      # Restic REST server — escuta só em localhost + tailscale
      systemd.services.restic-rest-server = {
        description = "Restic REST Server";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = ''
            ${pkgs.restic-rest-server}/bin/rest-server \
              --path /srv/restic-repo \
              --listen 0.0.0.0:8000 \
              --no-auth
          '';
          # no-auth é seguro porque só é acessível via Tailscale
          User = "restic";
          Group = "restic";
          StateDirectory = "restic";
          ReadWritePaths = [ "/srv/restic-repo" ];
        };
      };

      users.users.restic = {
        isSystemUser = true;
        group = "restic";
        home = "/srv/restic-repo";
        createHome = true;
      };
      users.groups.restic = { };
    };
}
```

### 2.3 Apontar o backup-service do predator para o aurelius

Evoluir o `backup-service.nix` existente ou criar um timer separado que executa:

```bash
restic -r rest:http://aurelius:8000/predator backup \
  ~/.ssh \
  ~/.gnupg \
  ~/nixos \
  ~/code \
  --exclude='.direnv' \
  --exclude='node_modules' \
  --exclude='.venv' \
  --exclude='result'
```

### 2.4 Prune automático no aurelius

Adicionar um timer que roda semanalmente:

```bash
restic -r /srv/restic-repo/predator forget \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 3 \
  --prune
```

Isso mantém o uso de disco previsível (~15GB max com os excludes acima).

### 2.5 Migração futura para o Orange Pi

Quando o OPi5 estiver no NixOS, o mesmo módulo `restic-server` será movido pra lá com path no SSD de 1TB, e o aurelius passa a ser apenas mais um cliente de backup.

---

## Fase 3 — Binary cache Nix com Attic

### 3.1 Por que Attic e não nix-serve/harmonia

Attic suporta garbage collection com quota, namespaces (um cache pra cada host), e deduplicação. Isso é crítico com 200GB de SSD. Harmonia é mais simples mas não tem GC automático.

### 3.2 Setup

Instalar attic via Docker (a versão NixOS nativa existe mas a imagem Docker é mais simples de isolar em disco):

```yaml
# ~/services/attic/docker-compose.yml
services:
  attic:
    image: ghcr.io/zhaofengli/attic:latest
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:8080"
    volumes:
      - ./data:/data
      - ./config.toml:/etc/attic/server.toml:ro
    environment:
      ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64: "<gerar com: openssl rand -base64 32>"
```

```toml
# ~/services/attic/config.toml
[storage]
type = "local"
path = "/data/storage"

[database]
url = "sqlite:///data/server.db?mode=rwc"

# Quota hard de 40GB
[garbage-collection]
default-retention-period = "30 days"

[chunking]
nar-size-threshold = 65536
min-size = 16384
avg-size = 65536
max-size = 262144
```

### 3.3 Integrar com o predator

No predator, após configurar o attic CLI:

```bash
attic login aurelius https://aurelius:8080 <token>
attic cache create aurelius:main
attic use aurelius:main
```

Depois, adicionar ao `nix.settings` do predator:

```nix
nix.settings.extra-substituters = [ "https://aurelius:8080/main" ];
nix.settings.extra-trusted-public-keys = [ "<chave pública do attic>" ];
```

### 3.4 Push automático após builds

No predator, após um `nh os switch` bem-sucedido:

```bash
attic push aurelius:main /nix/store/<derivação>
# ou push do result link:
attic push aurelius:main result/
```

Isso pode virar um post-build hook ou um alias fish.

---

## Fase 4 — Forgejo (Git privado)

### 4.1 Setup via Docker Compose

```yaml
# ~/services/forgejo/docker-compose.yml
services:
  forgejo:
    image: codeberg.org/forgejo/forgejo:10-rootless
    restart: unless-stopped
    ports:
      - "127.0.0.1:3000:3000"
      - "127.0.0.1:2222:22"
    volumes:
      - ./data:/var/lib/gitea
    environment:
      - FORGEJO__server__ROOT_URL=http://aurelius:3000
      - FORGEJO__database__DB_TYPE=sqlite3
      - FORGEJO__service__DISABLE_REGISTRATION=true
      - FORGEJO__repository__DEFAULT_PRIVATE=private
      - FORGEJO__server__LFS_START_SERVER=false  # economizar disco
```

### 4.2 O que hospedar lá

- **Mirror do repo NixOS** — push automático via webhook ou cron, ter uma cópia que não depende do GitHub.
- **Repos privados** com configurações sensíveis, scripts pessoais, notas técnicas.
- **Repos de experimentos** que não merecem estar no GitHub.

### 4.3 Mirror automático do GitHub

No Forgejo, criar um mirror repository apontando pro GitHub. Ou via cron simples:

```bash
#!/usr/bin/env bash
cd /home/higorprado/mirrors/nixos.git
git fetch origin --prune
git push forgejo --mirror
```

---

## Fase 5 — Observabilidade (Prometheus + Grafana)

### 5.1 Stack mínimo

```yaml
# ~/services/monitoring/docker-compose.yml
services:
  prometheus:
    image: prom/prometheus:latest
    restart: unless-stopped
    ports:
      - "127.0.0.1:9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.retention.time=30d'
      - '--storage.tsdb.retention.size=3GB'

  grafana:
    image: grafana/grafana-oss:latest
    restart: unless-stopped
    ports:
      - "127.0.0.1:3100:3000"
    volumes:
      - grafana-data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=<trocar>
      - GF_AUTH_ANONYMOUS_ENABLED=false

volumes:
  prometheus-data:
  grafana-data:
```

### 5.2 Node exporter no NixOS (declarativo, sem container)

No aurelius (e futuramente no predator e OPi5):

```nix
services.prometheus.exporters.node = {
  enable = true;
  listenAddress = "0.0.0.0";
  port = 9100;
  enabledCollectors = [
    "cpu" "diskstats" "filesystem" "loadavg"
    "meminfo" "netdev" "netstat" "systemd" "zfs"
  ];
};
```

### 5.3 Prometheus config

```yaml
# ~/services/monitoring/prometheus.yml
global:
  scrape_interval: 60s

scrape_configs:
  - job_name: 'aurelius'
    static_configs:
      - targets: ['host.docker.internal:9100']
        labels:
          host: aurelius

  # Adicionar quando estiver na tailnet:
  # - job_name: 'predator'
  #   static_configs:
  #     - targets: ['predator:9100']
  #       labels:
  #         host: predator
```

### 5.4 Dashboards sugeridos

Importar o dashboard **Node Exporter Full** (ID: 1860) no Grafana — dá uma visão completa de cada host. Com o tempo, criar dashboards customizados para métricas que você acompanha nos seus benchmarks de `experiments/perf-tuning/`.

---

## Fase 6 — GitHub Actions self-hosted runner

### 6.1 Setup

```yaml
# ~/services/gh-runner/docker-compose.yml
services:
  runner:
    image: myoung34/github-runner:latest
    restart: unless-stopped
    environment:
      - REPO_URL=https://github.com/higorprado/nixos
      - RUNNER_TOKEN=<token do GitHub>
      - RUNNER_NAME=aurelius-arm64
      - RUNNER_LABELS=self-hosted,linux,arm64,nixos
      - RUNNER_WORKDIR=/work
    volumes:
      - ./work:/work
      - /var/run/docker.sock:/var/run/docker.sock  # se precisar docker-in-docker
```

**Alternativa mais limpa (declarativa):** instalar o runner via NixOS module direto, sem Docker:

```nix
services.github-runners.aurelius = {
  enable = true;
  url = "https://github.com/higorprado/nixos";
  tokenFile = "/run/secrets/gh-runner-token";
  extraLabels = [ "arm64" "nixos" ];
  replace = true;
};
```

### 6.2 O que rodar lá

Adaptar seu `.github/workflows/validate.yml` pra ter um job no runner self-hosted:

```yaml
jobs:
  validation:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/run-validation-gates.sh all
```

Vantagens: zero consumo de minutos GitHub, acesso ao nix store local (builds rápidos), e roda seus scripts de validação nativamente.

---

## Fase 7 — Automação e cronjobs

### 7.1 Módulo de automação do aurelius

Criar `modules/features/system/aurelius-automation.nix` (ou direto no host config):

```nix
# Exemplos de timers úteis

# Health check: verificar se todos os containers estão up
systemd.services.docker-health-check = {
  description = "Check all Docker containers are healthy";
  serviceConfig.Type = "oneshot";
  script = ''
    unhealthy=$(docker ps --filter "health=unhealthy" --format "{{.Names}}")
    if [ -n "$unhealthy" ]; then
      echo "UNHEALTHY: $unhealthy" | systemd-cat -t docker-health -p warning
    fi
  '';
};
systemd.timers.docker-health-check = {
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "*:0/15";  # a cada 15 min
    Persistent = true;
  };
};

# Limpeza de disco: reportar uso e alertar se > 80%
systemd.services.disk-usage-alert = {
  description = "Alert on high disk usage";
  serviceConfig.Type = "oneshot";
  script = ''
    usage=$(df / --output=pcent | tail -1 | tr -d ' %')
    if [ "$usage" -gt 80 ]; then
      echo "DISK ALERT: root at ${usage}%" | systemd-cat -t disk-alert -p crit
    fi
  '';
};
systemd.timers.disk-usage-alert = {
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "daily";
    Persistent = true;
  };
};
```

### 7.2 Flake update automático

Timer que verifica se há updates nos inputs do flake e notifica (sem aplicar automaticamente):

```bash
#!/usr/bin/env bash
cd ~/nixos
nix flake update 2>&1 | tee /tmp/flake-update.log
if git diff --quiet flake.lock; then
  echo "No updates available"
else
  echo "Updates available — review with: git -C ~/nixos diff flake.lock"
  git checkout flake.lock  # não persistir, só informar
fi
```

---

## Fase 8 — Playground de experimentos

### 8.1 Containers efêmeros

Com Docker habilitado, o aurelius serve como sandbox:

```bash
# Testar uma versão de NixOS diferente:
docker run -it --rm nixos/nix

# Testar um stack completo antes de declarar:
docker compose -f ~/experiments/alguma-coisa/compose.yml up

# Distrobox (já disponível via módulo podman) pra ambientes não-Nix:
distrobox create --name ubuntu-test --image ubuntu:24.04
distrobox enter ubuntu-test
```

### 8.2 VMs leves com microvm (futuro)

Se precisar de isolamento real (testar kernels, impermanence, disko), o NixOS tem o projeto `microvm.nix` que roda VMs mínimas via cloud-hypervisor/QEMU. Consideração futura quando a necessidade surgir.

---

## Fase 9 — Caddy como reverse proxy unificado

### 9.1 Por que Caddy

Todos os serviços (Forgejo, Grafana, Attic, restic REST) escutam em portas localhost diferentes. Um Caddy na frente unifica tudo com subdomínios e HTTPS automático. Como o acesso é via Tailscale, o Caddy pode usar os IPs Tailscale diretamente.

### 9.2 Setup declarativo

```nix
services.caddy = {
  enable = true;
  virtualHosts = {
    "git.aurelius.tail".extraConfig = ''
      reverse_proxy localhost:3000
    '';
    "cache.aurelius.tail".extraConfig = ''
      reverse_proxy localhost:8080
    '';
    "grafana.aurelius.tail".extraConfig = ''
      reverse_proxy localhost:3100
    '';
    "backup.aurelius.tail".extraConfig = ''
      reverse_proxy localhost:8000
    '';
  };
};
```

Alternativa: usar **Tailscale Serve/Funnel** (`tailscale serve`) que faz o mesmo sem precisar de Caddy, e fica integrado com os certificados do MagicDNS.

---

## Fase 10 — VPN pessoal com Tailscale exit nodes

### 10.1 Conceito

Você já tem Tailscale em tudo. O recurso **exit node** transforma qualquer máquina da tailnet num gateway de saída — todo o tráfego do dispositivo cliente sai pelo IP público daquela máquina. Isso substitui uma VPN tradicional (WireGuard manual, OpenVPN) com zero configuração extra.

A ideia: aurelius vira exit node com IP brasileiro (útil quando estiver no exterior), e um nó grátis em outro país te dá IP gringo (útil pra acessar conteúdo restrito, testar geolocalização, etc.).

### 10.2 Aurelius como exit node (IP brasileiro)

Adicionar ao host config do aurelius:

```nix
services.tailscale = {
  enable = true;
  openFirewall = true;
  useRoutingFeatures = "server";  # habilita exit node + subnet routing
};
```

Após o deploy, ativar como exit node:

```bash
# No aurelius:
sudo tailscale set --advertise-exit-node
```

No painel admin do Tailscale (https://login.tailscale.com/admin/machines), aprovar o aurelius como exit node.

**Usar do predator ou celular:**

```bash
# Rotear todo tráfego pelo aurelius:
sudo tailscale set --exit-node=aurelius

# Desativar:
sudo tailscale set --exit-node=
```

No celular (app Tailscale), basta selecionar o exit node no menu — um toque.

### 10.3 Nó grátis em outro país (IP gringo)

O aurelius está no Brasil e não faz sentido movê-lo — a latência de 20ms é ouro pro dev remoto. Pra ter um IP estrangeiro, a solução é o **Google Cloud Always Free**: 1 VM e2-micro (2 vCPU, 1GB RAM) em regiões dos EUA, grátis pra sempre.

**O plano completo e detalhado está em `vpn-exit-node-plan.md`**, mas em resumo:

1. Criar conta GCP + projeto dedicado
2. Subir uma e2-micro em `us-central1` com Debian mínimo (~10GB disco)
3. Instalar Tailscale + configurar como exit node
4. Configurar IP forwarding + iptables NAT
5. Aprovar no painel Tailscale

Total: ~20 minutos, zero custo mensal permanente.

> **Nota:** Oracle não permite criar segunda conta, e o Fly.io matou o free tier em 2024 (agora é pay-as-you-go). GCP é a única opção genuinamente grátis pra IP gringo.

### 10.4 Uso no dia a dia

Com dois exit nodes configurados, você tem:

```bash
# Sair com IP brasileiro (de qualquer lugar do mundo):
sudo tailscale set --exit-node=aurelius

# Sair com IP americano (de qualquer lugar):
sudo tailscale set --exit-node=vpn-us

# Sem VPN (tráfego direto):
sudo tailscale set --exit-node=
```

No celular, o app Tailscale mostra todos os exit nodes disponíveis — basta tocar pra trocar. Funciona como qualquer VPN comercial, mas sem assinatura e sem confiar em terceiros.

### 10.5 Abbrs úteis

No predator (e eventualmente no aurelius), dentro de `home-manager.users.${userName}`:

```nix
programs.fish.shellAbbrs = {
  # ... existentes ...
  vpnbr = "sudo tailscale set --exit-node=aurelius";
  vpnus = "sudo tailscale set --exit-node=vpn-us";
  vpnoff = "sudo tailscale set --exit-node=";
};
```

### 10.6 Considerações de segurança

- O firewall do GCP bloqueia tudo por padrão. Abrir apenas a porta UDP 41641 (Tailscale) — o plano detalhado cobre isso.
- A instância `vpn-us` é descartável — se comprometer, destrói e recria em 10 minutos.
- Nunca coloque dados ou serviços na instância gringa. Ela existe só como gateway.

---

## Ordem de execução recomendada

| Passo | O quê                         | Dependência | Esforço | Impacto |
| ----- | ----------------------------- | ----------- | ------- | ------- |
| 0     | Docker + firewall no aurelius | nenhuma     | 15 min  | base    |
| 1     | Dev remoto headless + Mosh    | Fase 0      | 1 hora  | alto    |
| 2     | Restic backup                 | Fase 0      | 30 min  | alto    |
| 3     | Attic binary cache            | Fase 0      | 1 hora  | médio   |
| 4     | Forgejo                       | Fase 0      | 30 min  | médio   |
| 5     | Prometheus + Grafana          | Fase 0      | 45 min  | médio   |
| 6     | GitHub runner                 | Fase 0,4    | 30 min  | médio   |
| 7     | Automação / timers            | Fase 0      | 30 min  | baixo   |
| 8     | Playground                    | Fase 0      | 0 min   | inerente|
| 9     | Caddy / Tailscale Serve       | Fase 4,5    | 20 min  | QoL     |
| 10    | VPN exit nodes (BR + gringo)  | nenhuma     | 30 min  | alto    |

> **Nota:** a Fase 10 não depende de nenhuma outra e pode ser feita a qualquer momento — inclusive antes da Fase 0. Configurar o aurelius como exit node é uma mudança de uma linha no Tailscale config. Criar o `vpn-us` no GCP é um projeto paralelo independente (ver `vpn-exit-node-plan.md`).

---

## Sobre o Orange Pi 5 — visão de futuro

Quando migrar o OPi5 para NixOS, ele assume o papel de **storage node** da rede:

- **Restic repo principal** (1TB SSD) — o aurelius redireciona backups pra lá.
- **AdGuard Home** migrado para NixOS (declarativo, reprodutível).
- **Nextcloud ou Syncthing hub** no SSD de 1TB — substituir o "treco de cloud" atual.
- **Media / arquivo frio** no HD de 2TB — backups antigos, datasets, ISOs.
- **Nix binary cache secundário** — replicar do aurelius pra ter redundância.

A composição ficaria: aurelius = compute + serviços, OPi5 = storage + DNS + sync. Os dois na Tailnet, gerenciados pelo mesmo flake no predator.

O host composition do OPi5 no flake seria um terceiro entry em `modules/hosts/`, seguindo a mesma arquitetura modular. Conversa pra próxima sessão.

---

## Checklist pré-deploy

Antes de aplicar cada fase, rodar do predator:

```bash
# Validação do flake
nix flake check path:$HOME/nixos

# Build sem aplicar
naub   # (alias que faz build remoto no aurelius)

# Se OK, aplicar
naus   # (alias que faz switch remoto)

# Verificar status
naust  # (nixos-version + systemctl --failed)
```
