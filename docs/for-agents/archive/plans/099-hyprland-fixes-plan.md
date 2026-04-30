# PLAN: Correções e Otimizações de Performance (Hyprland & Repo)

## Objetivo
Resolver problemas de performance, sincronia e arquitetura, garantindo que qualquer otimização possua provas matemáticas (benchmarks) do seu benefício, bem como testes que assegurem 100% de paridade na saída visual das barras e ícones.

---

## Escopo de Tarefas

### Fase 1: Benchmarks Iniciais (Baseline)
Antes de alterar qualquer arquivo, executaremos coletas de métricas para provar o estado atual:
1. **Benchmark do `active-window.sh`**: 
   - Capturar o custo de execução da função atual usando `hyperfine` ou medição nativa (`time`) ao simular X chamadas ao `hyprctl activewindow -j | jq`.
2. **Benchmark do `mako.sh`**: 
   - Medir o consumo de CPU da instância do Waybar e dos subprocessos instanciados a cada 1 segundo (usando `pidstat` ou contador de *syscalls* / *forks* durante 60 segundos).

### Fase 2: Testes de Paridade (Unitários)
1. **Fixture para `active-window.sh`**:
   - Extrair a função de *parser* atual e isolá-la.
   - Criar um mock com 10 janelas diferentes (ex: `Firefox`, `YouTube`, `Code`, casos com nomes vazios e lixo no sufixo).
   - O teste deve garantir que o novo código (baseado em IPC nativo do bash) cuspa **exatamente** as mesmas strings de ícone e label que o script velho produzia. A refatoração só será aplicada ao Waybar após este teste passar.

### Fase 3: Implementação das Otimizações
1. **Otimizar `active-window.sh` (Zero Subprocessos no Loop)**
   - **Ação**: Refatorar o `while` interno para fazer o *parse* da string nativa recebida do `nc -U` (`activewindowv2>>class,title`) via manipulação do bash (`IFS=,`).
   - **Resultado Esperado**: O mesmo *output* visual, mas reduzindo substancialmente o número de processos *forkados*.

2. **Otimizar `mako.sh` (Migração de Polling para Event-Driven)**
   - **Ação**: Remover o `restart-interval: 1` do `waybar/config`. O novo `mako.sh` utilizará `dbus-monitor` para segurar o *loop* passivamente na interface `org.freedesktop.Notifications`, invocando as checagens apenas quando uma notificação mudar de estado.

### Fase 4: Correções e Limpezas de Configuração
3. **Limpar MIME Apps Inválidos**
   - **Ação**: Em `desktop-viewers.nix`, remover chaves `.pdf`, `.jpg`, `.png`, mantendo apenas tipos MIME padrão (`application/pdf`, etc).

4. **Sincronizar Drift do Waypaper**
   - **Ação**: Atualizar `config/apps/waypaper/config.ini` no repo com o conteúdo de `~/.config/waypaper/config.ini` (incorporando `zen_mode = True`).

5. **Remover Lixo do Sistema Vivo**
   - **Ação**: Deletar `~/.config/waybar/dock`.

6. **Integrar Mako ao Systemd**
   - **Ação**: No `mako.nix`, injetar um *override* DBus (`SystemdService=mako.service`) para que o Mako suba atrelado à árvore do systemd, respeitando os *resets* da sessão.

### Fase 5: Validação Final e Relatório de Ganhos
- Executar os mesmos testes da Fase 1 usando os scripts otimizados.
- Gerar um quadro comparativo (Delta) provando a redução do tempo de execução (ms) e da quantidade de processos paralelos (forks/s) gerados pelo Waybar.
