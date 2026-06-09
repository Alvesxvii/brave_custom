# Brave Workspace Custom

Projeto de customizacao do Brave para Ubuntu GNOME com:

- dois launchers separados na dock
- um profile DEV preso ao Workspace 1
- um profile Trabalho preso ao Workspace 2
- icones distintos com badge visual
- wrappers locais para manter o comportamento persistente fora do pacote oficial do Brave
- favoritos da dock variando por workspace sem trocar o Ubuntu Dock

## Objetivo

O problema original era usar dois perfis do Brave dentro de um fluxo orientado por workspaces sem perder a experiencia visual padrao do Ubuntu Dock.

O resultado final separa:

- `Brave DEV` -> usa o perfil real `Default` e vai para o Workspace 1
- `Brave Trabalho` -> usa o perfil real `Profile 1` e vai para o Workspace 2
- `code.desktop` aparece como favorito no Workspace 1 e some no Workspace 2

## Arquitetura

O setup nao altera arquivos dentro de `/usr/share/applications` nem dentro do pacote do Brave. Tudo fica em espaco de usuario:

- launchers em `~/.local/share/applications`
- scripts em `~/.local/bin`
- icones em `~/.local/share/icons/hicolor/256x256/apps`
- wrappers do Brave em `~/.config/BraveSoftware/Brave-Workspace-*`

Isso ajuda bastante na persistencia entre atualizacoes do Brave.

## Como funciona

### 1. Wrappers de execucao

Arquivos:

- [bin/brave-personal](/home/alves/genesis/projects/apps/brave_custom/bin/brave-personal)
- [bin/brave-work](/home/alves/genesis/projects/apps/brave_custom/bin/brave-work)

Cada wrapper:

- chama `brave-browser-stable`
- usa `--user-data-dir` dedicado
- usa `--class` dedicado (`BravePersonal` e `BraveWork`)
- usa `wmctrl` para mover a janela criada para o workspace alvo

O motivo do `--class` customizado e fazer o GNOME conseguir:

- diferenciar os dois launchers na dock
- casar o `StartupWMClass` do `.desktop`
- permitir movimentacao por janela sem confundir os perfis

### 2. Wrappers de perfis com symlink

Os diretorios:

- `~/.config/BraveSoftware/Brave-Workspace-Personal`
- `~/.config/BraveSoftware/Brave-Workspace-Work`

nao sao clones completos do perfil principal. Em vez disso:

- `Brave-Workspace-Personal/Default` aponta por symlink para `Brave-Browser/Default`
- `Brave-Workspace-Work/Profile 1` aponta por symlink para `Brave-Browser/Profile 1`

Isso foi escolhido porque copiar perfil parecia funcionar no comeco, mas perdia consistencia com o tempo:

- favoritos
- historico
- sessao aberta
- identidade visual do perfil

Com symlink, qualquer mudanca no perfil real e imediatamente refletida no launcher customizado.

### 3. Launchers `.desktop`

Arquivos template:

- [desktop/brave-personal.desktop.template](/home/alves/genesis/projects/apps/brave_custom/desktop/brave-personal.desktop.template)
- [desktop/brave-work.desktop.template](/home/alves/genesis/projects/apps/brave_custom/desktop/brave-work.desktop.template)

Pontos importantes:

- `Exec=` aponta para `~/.local/bin/...`
- `Icon=` aponta para os icones customizados
- `StartupWMClass=` precisa bater exatamente com o `WM_CLASS` usado no wrapper

Sem esse casamento, o Ubuntu Dock tende a mostrar a janela como outro app e criar um segundo icone.

### 4. Icones customizados

Arquivos:

- [icons/brave-dev.png](/home/alves/genesis/projects/apps/brave_custom/icons/brave-dev.png)
- [icons/brave-work-badge.png](/home/alves/genesis/projects/apps/brave_custom/icons/brave-work-badge.png)

Os icones foram gerados a partir do icone oficial do Brave com um badge no canto para identificacao rapida na dock.

O script de geracao esta em:

- [scripts/generate-icons.sh](/home/alves/genesis/projects/apps/brave_custom/scripts/generate-icons.sh)

Ele usa `ImageMagick` (`convert`).

### 5. Favoritos diferentes por workspace

Arquivos:

- [bin/workspace-favorites-daemon](/home/alves/genesis/projects/apps/brave_custom/bin/workspace-favorites-daemon)
- [desktop/workspace-favorites-daemon.desktop.template](/home/alves/genesis/projects/apps/brave_custom/desktop/workspace-favorites-daemon.desktop.template)

Em vez de uma extensao GNOME carregada dentro do processo do Shell, o projeto usa um daemon simples em espaco de usuario. Essa escolha foi feita por estabilidade.

O daemon:

- detecta o workspace ativo com `wmctrl -d`
- le e grava `org.gnome.shell favorite-apps`
- salva um estado persistente em `~/.config/workspace-favorites/config.json`
- aprende alteracoes manuais feitas pelo usuario em cada workspace
- reaplica a lista correta ao trocar de workspace
- usa lock para impedir duas instancias simultaneas

Mapeamento atual:

- Workspace 1: lista padrao com `code.desktop`
- Workspace 2: mesma lista, mas sem `code.desktop`
- Demais workspaces: usam a lista padrao

Na pratica, isso significa:

- se voce remover um favorito no workspace atual, o daemon salva essa nova lista para aquele workspace
- se voce adicionar um favorito no workspace atual, o daemon salva tambem
- no proximo login, a configuracao volta exatamente como ficou por workspace

Essa abordagem preserva o Ubuntu Dock padrao e evita mexer no codigo da extensao oficial da dock.

## Mapeamento atual dos perfis

No ambiente atual, o Brave esta assim:

- `Default` = perfil `DEV`
- `Profile 1` = perfil `WORK`

Importante: o nome interno exibido pelo Brave pode nao bater com o nome do diretório. O que manda aqui e o mapeamento acima.

## Instalacao em outra maquina

### Pre-requisitos

- Ubuntu GNOME
- Brave instalado
- `wmctrl` instalado
- dois perfis existentes no Brave
- idealmente com o mesmo mapeamento:
  - `Default` para DEV
  - `Profile 1` para WORK

### Passos

1. Clonar este repositorio.
2. Rodar:

```bash
chmod +x install.sh verify.sh scripts/generate-icons.sh bin/brave-personal bin/brave-work bin/workspace-favorites-daemon
./install.sh
```

3. Fixar os atalhos na dock, se necessario:

- `~/.local/share/applications/brave-personal.desktop`
- `~/.local/share/applications/brave-work.desktop`

O instalador tambem cria:

- `~/.config/autostart/workspace-favorites-daemon.desktop`
- `~/.config/workspace-favorites/config.json` se ele ainda nao existir

### Variaveis uteis

O `install.sh` aceita overrides por variavel de ambiente:

```bash
BRAVE_MASTER_DIR="$HOME/.config/BraveSoftware/Brave-Browser" \
BRAVE_DEV_SOURCE_PROFILE="Default" \
BRAVE_WORK_SOURCE_PROFILE="Profile 1" \
./install.sh
```

Isso ajuda se o profile corporativo nao estiver em `Profile 1` na outra maquina.

## Verificacao

Rode:

```bash
./verify.sh
```

Ele mostra:

- `Exec`, `Icon` e `StartupWMClass` dos launchers
- destino dos symlinks dos perfis
- favoritos atuais da dock no GNOME
- configuracao persistida de favoritos por workspace

## Estado da dock

Snapshot do estado atual salvo em:

- [state/favorite-apps.gsettings.txt](/home/alves/genesis/projects/apps/brave_custom/state/favorite-apps.gsettings.txt)
- [state/workspace-favorites.config.sample.json](/home/alves/genesis/projects/apps/brave_custom/state/workspace-favorites.config.sample.json)

Esse arquivo serve como referencia historica. Nao e aplicado automaticamente pelo instalador porque a dock pode variar de maquina para maquina.

## Riscos e manutencao futura

O setup tende a sobreviver bem a updates normais do Brave porque fica em arquivos de usuario. Ainda assim, vale acompanhar estes pontos:

- se o Brave mudar o suporte a `--class`
- se o GNOME mudar a forma como casa `StartupWMClass`
- se o mapeamento de perfis deixar de ser `Default` e `Profile 1`
- se o Brave mudar como resolve `--user-data-dir` com symlinks

Em qualquer desses casos, este repositório ajuda porque concentra:

- os wrappers
- os launchers
- os icones
- o daemon de favoritos por workspace
- a logica de instalacao
- a documentacao tecnica da customizacao

## Observacoes praticas

- este projeto nao versiona os dados sensiveis do perfil, apenas a customizacao
- os perfis reais continuam em `~/.config/BraveSoftware/Brave-Browser`
- se quiser sincronizar nomes internos dos perfis no futuro, isso deve ser feito dentro do proprio Brave, nao neste projeto
