#!/usr/bin/env bash
# instalacao-ubuntu-mint.sh
# Ubuntu / Linux Mint - instala aplicativos, Flatpak, Snap quando disponivel,
# extensoes GNOME e faz reparo + limpeza.
#
# IMPORTANTE:
# - NAO instala gdm3.
# - Solicita a senha sudo apenas uma vez.
# - Recomendado executar em uma sessao grafica GNOME.
# - Alguns pacotes variam conforme a versao/distribuicao; o script ignora
#   individualmente os que nao estiverem disponiveis.

set -Eeuo pipefail
IFS=$'\n\t'

export DEBIAN_FRONTEND=noninteractive
SUDO="sudo"

log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\n\033[1;33mAVISO: %s\033[0m\n' "$*" >&2; }
die()  { printf '\n\033[1;31mERRO: %s\033[0m\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] && die "Nao execute como root. Execute com seu usuario normal para que o script solicite sudo uma unica vez."

command -v sudo >/dev/null 2>&1 || die "sudo nao esta instalado."

# Uma unica solicitacao de senha. A partir daqui o sudo usa o ticket em cache.
log "Solicitando autorizacao administrativa (uma unica vez)"
sudo -v

# Mantem o ticket sudo valido durante a execucao sem solicitar nova senha.
while true; do
    sudo -n -v >/dev/null 2>&1 || exit
    sleep 50
done &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

source /etc/os-release
DISTRO="${ID:-}"
VERSION_ID="${VERSION_ID:-unknown}"

case "$DISTRO" in
    ubuntu|linuxmint) ;;
    *)
        warn "Sistema detectado: ${PRETTY_NAME:-desconhecido}. O script foi projetado para Ubuntu/Linux Mint."
        ;;
esac

log "Sistema: ${PRETTY_NAME:-$DISTRO $VERSION_ID}"

# Nunca permitir que gdm3 seja instalado por dependencias deste script.
APT_NO_GDM="gdm3"
apt_update() {
    log "Atualizando indices do APT"
    sudo apt-get update
}

apt_install() {
    local p
    for p in "$@"; do
        if apt-cache show "$p" >/dev/null 2>&1; then
            log "Instalando APT: $p"
            sudo apt-get install -y --no-install-recommends "$p" || warn "Falha ao instalar $p; continuando."
        else
            warn "Pacote APT nao encontrado: $p"
        fi
    done
}

flatpak_install() {
    local app="$1"
    command -v flatpak >/dev/null 2>&1 || return 0
    if flatpak remote-info flathub "$app" >/dev/null 2>&1; then
        log "Instalando Flatpak: $app"
        flatpak install -y --noninteractive flathub "$app" || warn "Falha no Flatpak $app; continuando."
    else
        warn "Flatpak nao encontrado no Flathub: $app"
    fi
}

snap_install() {
    local app="$1"
    command -v snap >/dev/null 2>&1 || return 0
    if snap info "$app" >/dev/null 2>&1; then
        log "Instalando Snap: $app"
        sudo snap install "$app" || warn "Falha no Snap $app; continuando."
    else
        warn "Snap nao encontrado: $app"
    fi
}

# ---------------------------------------------------------------------------
# 1. Atualizacao completa sem instalar GDM3
# ---------------------------------------------------------------------------
apt_update
log "Atualizacao completa do sistema"
sudo apt-get -y dist-upgrade

# Se gdm3 estiver presente como candidato por alguma alteracao externa, nao
# instalamos/removemos automaticamente o gerenciador grafico existente.
sudo apt-mark manual gdm3 >/dev/null 2>&1 || true

# ---------------------------------------------------------------------------
# 2. Dependencias basicas, APT, Snap e Flatpak
# ---------------------------------------------------------------------------
apt_install \
    ca-certificates curl wget gnupg lsb-release software-properties-common \
    apt-transport-https flatpak gnome-software-plugin-flatpak \
    software-properties-common

# Flathub
if command -v flatpak >/dev/null 2>&1; then
    log "Configurando Flathub"
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
fi

# Snapd: Ubuntu normalmente possui; no Linux Mint pode estar bloqueado por
# nosnap.pref. O script habilita somente se for necessario.
if ! command -v snap >/dev/null 2>&1; then
    log "Habilitando suporte a Snap"
    if [[ "$DISTRO" == "linuxmint" ]]; then
        if [[ -f /etc/apt/preferences.d/nosnap.pref ]]; then
            sudo rm -f /etc/apt/preferences.d/nosnap.pref
            apt_update
        fi
    fi
    apt_install snapd
    sudo systemctl enable --now snapd.socket 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 3. Repositorios oficiais de terceiros: Brave, Google Chrome e RustDesk
# ---------------------------------------------------------------------------
log "Configurando repositorios oficiais"

# Brave
if ! command -v brave-browser >/dev/null 2>&1; then
    sudo install -d -m 0755 /etc/apt/keyrings
    curl -fsS https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
        | sudo tee /etc/apt/keyrings/brave-browser-archive-keyring.gpg >/dev/null || warn "Chave Brave nao baixada."
    echo "deb [signed-by=/etc/apt/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" \
        | sudo tee /etc/apt/sources.list.d/brave-browser-release.list >/dev/null
fi

# Google Chrome
if ! command -v google-chrome >/dev/null 2>&1; then
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
        | gpg --dearmor \
        | sudo tee /etc/apt/keyrings/google-chrome.gpg >/dev/null || warn "Chave Google nao baixada."
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
        | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
fi

# RustDesk - pacote .deb oficial, se arquitetura for suportada.
RUSTDESK_TMP=""
if [[ "$(dpkg --print-architecture)" == "amd64" ]] && ! command -v rustdesk >/dev/null 2>&1; then
    RUSTDESK_TMP="$(mktemp -d)"
    trap 'rm -rf "$RUSTDESK_TMP" 2>/dev/null || true; kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
    RUSTDESK_URL="https://github.com/rustdesk/rustdesk/releases/latest/download/rustdesk-1.4.0-x86_64.deb"
    # Se o nome acima mudar, a instalacao sera simplesmente ignorada.
    curl -fL "$RUSTDESK_URL" -o "$RUSTDESK_TMP/rustdesk.deb" || true
    if [[ -s "$RUSTDESK_TMP/rustdesk.deb" ]]; then
        sudo apt-get install -y "$RUSTDESK_TMP/rustdesk.deb" || warn "Falha no RustDesk."
    else
        warn "Nao foi possivel baixar o RustDesk automaticamente; instale a versao oficial para sua arquitetura."
    fi
fi

apt_update

# ---------------------------------------------------------------------------
# 4. Aplicativos APT
# ---------------------------------------------------------------------------
apt_install \
    steam-installer \
    clapper \
    gdebi \
    gufw \
    vlc \
    gnome-tweaks \
    kdenlive \
    gimp \
    inkscape \
    synaptic \
    bleachbit \
    copyq \
    gnome-software \
    dconf-editor \
    gnome-shell-extension-manager \
    gnome-menus

# Nomes alternativos / pacotes que podem variar
apt_install \
    brave-browser \
    google-chrome-stable \
    audacity \
    telegram-desktop \
    discord

# Bitwarden: prefere Flatpak se o pacote APT nao existir.
# Video Downloader e outros itens serao tratados no Flatpak abaixo.

# ---------------------------------------------------------------------------
# 5. Flatpaks
# ---------------------------------------------------------------------------
flatpak_install com.github.wwmm.clapper
flatpak_install org.videolan.VLC
flatpak_install com.spotify.Client
flatpak_install org.kde.kdenlive
flatpak_install org.gimp.GIMP
flatpak_install org.inkscape.Inkscape
flatpak_install com.discordapp.Discord
flatpak_install org.telegram.desktop
flatpak_install com.bitwarden.desktop
flatpak_install com.github.vinegarhq.Sober
flatpak_install org.gnome.Boxes
flatpak_install org.gnome.Software
flatpak_install com.github.unrud.VideoDownloader
flatpak_install de.haeckerfelix.Shortwave
flatpak_install org.audacityteam.Audacity
flatpak_install org.gnome.Extensions
flatpak_install org.gnome.Menu
flatpak_install ca.desrt.dconf-editor
flatpak_install io.gitlab.theevilskeleton.Upscaler
flatpak_install com.github.finefindus.eyedropper

# Aplicativos conhecidos por IDs alternativos. Se nao existirem, o script segue.
flatpak_install com.rustdesk.RustDesk
flatpak_install com.bitwarden.desktop

# ---------------------------------------------------------------------------
# 6. Google Chrome/Brave via repositorio e Steam via APT
# ---------------------------------------------------------------------------
apt_install brave-browser google-chrome-stable steam-installer

# Spotify pode ser instalado por Flatpak; Telegram/Discord tambem possuem
# Flatpak. Evitamos Snap duplicado quando o Flatpak estiver disponivel.

# ---------------------------------------------------------------------------
# 7. Extensoes GNOME Shell
# ---------------------------------------------------------------------------
# Instala gnome-extension-manager quando disponivel e tenta instalar extensoes
# do repositório Ubuntu. Extensoes que nao tiverem pacote sao informadas.
EXT_PKGS=(
    gnome-shell-extension-manager
    gnome-shell-extension-caffeine
    gnome-shell-extension-dash-to-dock
    gnome-shell-extension-appindicator
    gnome-shell-extension-desktop-icons-ng
    gnome-shell-extension-ubuntu-dock
    gnome-shell-extension-ubuntu-tiling-assistant
)

apt_install "${EXT_PKGS[@]}"

# "User Themes" existe em muitas versoes como pacote.
apt_install gnome-shell-extension-user-theme

# Outras extensoes (Blur my Shell, Open Bar, Rounded Corners, Tiling Shell,
# Vitals, Wallpaper Slideshow) dependem da versao do GNOME e sao mais seguras
# via site do GNOME Extensions / Extension Manager. O script nao baixa ZIPs
# arbitrarios sem verificar a compatibilidade da versao do GNOME.

if command -v gnome-extensions >/dev/null 2>&1; then
    log "Extensoes GNOME disponiveis no sistema"
    gnome-extensions list 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 8. Reparacao de pacotes quebrados
# ---------------------------------------------------------------------------
log "Reparando dependencias e pacotes quebrados"
sudo dpkg --configure -a || true
sudo apt-get -f install -y || true
sudo apt-get install --reinstall -y ca-certificates apt || true
sudo dpkg --configure -a || true

# ---------------------------------------------------------------------------
# 9. Limpeza de pacotes obsoletos e repositorios inutilizados
# ---------------------------------------------------------------------------
log "Removendo pacotes desnecessarios/obsoletos"
sudo apt-get autoremove --purge -y || true
sudo apt-get autoclean -y || true
sudo apt-get clean || true

# Remove arquivos de listas APT e recria os indices.
log "Limpando cache/listas do APT e recriando indices"
sudo rm -rf /var/lib/apt/lists/*
apt_update

# Limpa pacotes Flatpak sem uso.
if command -v flatpak >/dev/null 2>&1; then
    log "Limpando runtimes Flatpak sem uso"
    flatpak uninstall --unused -y || true
    flatpak repair --user || true
fi

# Limpeza de snaps antigos desativados.
if command -v snap >/dev/null 2>&1; then
    log "Removendo revisoes Snap desativadas"
    while read -r snapname rev; do
        [[ -n "${snapname:-}" && -n "${rev:-}" ]] || continue
        sudo snap remove "$snapname" --revision="$rev" || true
    done < <(snap list --all 2>/dev/null | awk '/disabled/{print $1, $3}')
fi

# ---------------------------------------------------------------------------
# 10. Limpeza de temporarios do usuario e navegadores
# ---------------------------------------------------------------------------
log "Limpando temporarios do usuario"
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}"/* 2>/dev/null || true
rm -rf "$HOME/.local/share/Trash/files/"* "$HOME/.local/share/Trash/info/"* 2>/dev/null || true
sudo journalctl --vacuum-time=14d || true

log "Limpando caches dos navegadores (sem apagar perfis, senhas ou favoritos)"
# Chrome/Chromium/Brave: somente caches comuns; nao apagar o perfil inteiro.
for d in \
    "$HOME/.cache/google-chrome" \
    "$HOME/.cache/chromium" \
    "$HOME/.cache/BraveSoftware/Brave-Browser"
do
    if [[ -d "$d" ]]; then
        find "$d" -mindepth 1 -maxdepth 1 \
            \( -name "Cache" -o -name "Code Cache" -o -name "GPUCache" \) \
            -exec rm -rf {} + 2>/dev/null || true
    fi
done

# Firefox: somente caches.
for d in "$HOME/.cache/mozilla/firefox"; do
    [[ -d "$d" ]] && find "$d" -mindepth 1 -maxdepth 2 -type d \
        \( -name "cache2" -o -name "startupCache" \) \
        -exec rm -rf {} + 2>/dev/null || true
done

# ---------------------------------------------------------------------------
# 11. Remover arquivos de repositorios APT obviamente temporarios/duplicados
# ---------------------------------------------------------------------------
log "Verificando fontes APT duplicadas/temporarias"
sudo find /etc/apt/sources.list.d -maxdepth 1 -type f \
    \( -name "*.save" -o -name "*.distUpgrade" -o -name "*.ucf-old" -o -name "*.disabled" \) \
    -delete 2>/dev/null || true

# Nao removemos repositorios de terceiros ativos automaticamente: isso poderia
# quebrar Brave/Chrome/RustDesk ou software do usuario. Apenas arquivos
# temporarios/backup sao removidos.

# ---------------------------------------------------------------------------
# 12. Verificacao final
# ---------------------------------------------------------------------------
log "Verificacao final"
sudo dpkg --audit || true
apt-cache policy gdm3 2>/dev/null | sed -n '1,8p' || true

echo
echo "============================================================"
echo " INSTALACAO / MANUTENCAO CONCLUIDA"
echo "============================================================"
echo "Distribuicao : ${PRETTY_NAME:-$DISTRO}"
echo "Arquitetura  : $(dpkg --print-architecture)"
echo
echo "GDM3: NAO foi instalado por este script."
echo "Sudo: a senha foi solicitada somente no inicio."
echo "Foi executada limpeza do APT, Flatpak, temporarios e caches."
echo "Caches dos navegadores foram limpos sem apagar senhas/favoritos."
echo
echo "IMPORTANTE: algumas extensoes GNOME dependem da versao do GNOME."
echo "Use o Gerenciador de Extensoes para instalar/atualizar as extensoes"
echo "que nao estejam disponiveis como pacote da sua distribuicao."
echo
echo "Reinicie o sistema para aplicar todas as atualizacoes:"
echo "    sudo reboot"
echo "============================================================"
