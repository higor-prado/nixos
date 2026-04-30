# Relatório de Auditoria: Migração Hyprland e Saúde do Repositório

## Resumo Executivo
Foi realizada uma investigação profunda em todo o repositório NixOS com foco na recente migração para o Hyprland, alinhamento com a documentação, performance, ferramentas e possíveis lixos/arquivos duplicados. O sistema vivo foi considerado a fonte da verdade.

De forma geral, a arquitetura *dendrítica* e as restrições do repositório estão sendo rigorosamente respeitadas. Contudo, foram encontrados *drifts* de configuração, scripts custosos de *polling* que afetam a performance, lixo de configurações inválidas e oportunidades para modernização das ferramentas utilizadas.

---

## 1. Drifts entre Sistema Vivo e Repositório

Como o sistema vivo é a referência, os seguintes *drifts* foram identificados e o repositório deve ser atualizado para refletir a realidade:

* **Waypaper (`config/apps/waypaper/config.ini`)**: 
  O arquivo no repositório está defasado em relação ao sistema vivo (`~/.config/waypaper/config.ini`). No sistema vivo, o `zen_mode` está habilitado (`True`), os caminhos como `stylesheet` estão absolutos e a ordem da configuração `wallpaperengine_folder` mudou. 
  **Solução**: Copiar o `config.ini` do sistema vivo de volta para o repositório.

* **Leftover Experimental (`~/.config/waybar/dock`)**:
  Existe um arquivo `dock` no diretório do Waybar no sistema vivo que não é gerenciado pelo repositório (aparentemente um teste de *taskbar* antigo com o `wlr/taskbar`). 
  **Solução**: Remover o arquivo solto do sistema vivo para manter a consistência declarativa, visto que não tem uso ativo.

---

## 2. Problemas de Performance e Gargalos (Waybar)

Os scripts customizados do Waybar estão gerando gargalos de CPU e quebras de performance desnecessárias:

* **Polling do Mako (`mako.sh`)**:
  O módulo `"custom/mako"` no Waybar está com `"restart-interval": 1`. Isso significa que a cada 1 segundo, o sistema recria um processo bash que roda `makoctl list`, `makoctl mode` e duas instâncias de `grep`. É um gasto severo de CPU/bateria para apenas checar o status de notificações.
  **Solução/Sugestão**: Substituir por um script orientado a eventos (utilizando `dbus-monitor`) ou, melhor ainda, substituir o `mako` pelo `SwayNotificationCenter (swaync)`, que possui um módulo nativo no Waybar (`custom/notification`) que consome os sinais do DBus sem nenhum *polling*.

* **Monitoramento da Janela Ativa (`active-window.sh`)**:
  O script escuta eventos via IPC (`nc -U`), mas reage instanciando `hyprctl` e `jq` a cada mudança de foco no sistema. Inicialmente, considerei recomendar a substituição pelo módulo nativo `hyprland/window` do Waybar. **No entanto, o módulo nativo não suporta a lógica condicional complexa (fallbacks de strings vazias para nomes padrão) exigida pela sua configuração.** O custo de instanciar subprocessos a cada evento de janela é, portanto, o preço pago para manter a exatidão dessa regra de UI customizada.
  **Sugestão de Otimização**: Refatorar o script para extrair a classe e o título diretamente do *payload* do socket `activewindowv2>>class,title` emitido pelo Hyprland, eliminando a necessidade de invocar `hyprctl` e `jq` no *loop* principal.

---

## 3. Lixo Residual e Duplicações

* **Mapeamentos MIME Inválidos (`desktop-viewers.nix`)**:
  Em `xdg.mimeApps.defaultApplications` e `associations`, extensões de arquivo (`.pdf`, `.jpg`, `.png`, etc.) estão sendo vinculadas. O `mimeapps.list` e a especificação XDG aceitam estritamente tipos MIME padrão (ex: `application/pdf`, `image/jpeg`). O uso de extensões é lixo de configuração e é ignorado silenciosamente pelo sistema.
  **Solução**: Remover as chaves de extensões (".pdf", ".jpg", etc.) do bloco `xdg.mimeApps`.

* **Navegadores Redundantes (`desktop-apps.nix`)**:
  Há uma declaração expressiva de 7 browsers diferentes (`Firefox`, `Chromium`, `Brave`, `Floorp`, `Vivaldi`, `Google Chrome`, `Zen Browser`). Ao mesmo tempo, 6 deles são explicitamente removidos das associações padrão na variável `nonFirefoxWebHandlers`.
  **Solução**: A menos que o usuário seja desenvolvedor *front-end* ativamente testando em todos, sugere-se a limpeza para manter apenas os navegadores de uso cotidiano (diminuindo o tamanho da *closure* do NixOS e o tempo de build).

---

## 4. Integração do Sistema e "Melhores Ferramentas"

* **Descompasso DBus vs Systemd no Mako**:
  O Mako está sendo ativado pelo *DBus* (como um serviço transiente subordinado ao dbus-broker: `dbus-:1.2-org.freedesktop.Notifications@5.service`), mas o serviço `mako.service` de fato aparece como inativo (`dead`) no systemd. Isso acontece porque o arquivo de serviço DBus do Mako não declara a chave `SystemdService=mako.service`.
  **Impacto**: O ciclo de vida do Mako fica fora do controle direto das *targets* do systemd (`graphical-session.target`). Comandos padrões de reinício ou logs do `mako.service` não refletirão o daemon real.
  **Solução**: Declarar um *override* ou migrar para o `swaync` (SwayNotificationCenter) que fornece uma integração mais resiliente e controle de painel no Wayland.

* **Gerenciamento de Sessão Wayland (UWSM)**:
  Em `hyprland.nix`, está configurado `withUWSM = false`, mantendo a ativação manual do `hyprland-session.target` através do `session-bootstrap.lua`.
  **Sugestão**: O **UWSM (Universal Wayland Session Manager)** tornou-se a ferramenta padrão recomendada pela comunidade do Hyprland para gerenciar *environment variables* e o ciclo de vida do DBus/Systemd, garantindo limpezas seguras (*clean teardowns*). A longo prazo, adotar o UWSM permitirá apagar boa parte dos scripts de sessão shell lua.

* **Conflito Potencial de Nice/Prioridade (Gamemode)**:
  Em `gaming.nix`, o `gamemode` seta `renice = 10` (que o gamemode traduz como uma prioridade de `-10`). Como o sistema já roda o `ananicy-cpp` em plano de fundo atuando pesadamente na repriorização automática das threads baseadas em regras de cgroups/nome, pode ocorrer concorrência para ditar o niceness dos jogos.
  **Sugestão**: Validar se o uso isolado do `ananicy-cpp` com as regras do CachyOS já não atende a demanda de prioridade.
