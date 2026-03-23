#!/bin/bash
# ============================================================
#  Fath Spot - Spotify Mod para Linux
#  Patcher para Spotify Desktop que remove ads e podcasts.
# ============================================================

set -euo pipefail

FATHSPOT_VERSION="1.1.0"

# ============================================================
#  CORES
# ============================================================
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
DARKCYAN='\033[0;36m'
DARKGRAY='\033[1;30m'
WHITE='\033[1;37m'
NC='\033[0m'

# ============================================================
#  BANNER
# ============================================================
show_banner() {
    clear
    echo ""
    echo -e "  ${GREEN}==========================================${NC}"
    echo -e "  ${GREEN}||${NC}                                      ${GREEN}||${NC}"
    echo -e "  ${GREEN}||${NC}${YELLOW}        F A T H   S P O T${NC}          ${GREEN}||${NC}"
    echo -e "  ${GREEN}||${NC}${CYAN}      Spotify Mod for Linux${NC}         ${GREEN}||${NC}"
    echo -e "  ${GREEN}||${NC}${DARKGRAY}             v${FATHSPOT_VERSION}${NC}                  ${GREEN}||${NC}"
    echo -e "  ${GREEN}||${NC}                                      ${GREEN}||${NC}"
    echo -e "  ${GREEN}==========================================${NC}"
    echo -e "  ${YELLOW}~ Fenix renascendo no Spotify ~${NC}"
    echo ""
}

# ============================================================
#  FUNCOES UTILITARIAS
# ============================================================
fath_log() {
    local message="$1"
    local type="${2:-INFO}"
    local color prefix

    case "$type" in
        INFO)    color="$CYAN";   prefix="[*]" ;;
        SUCCESS) color="$GREEN";  prefix="[+]" ;;
        WARN)    color="$YELLOW"; prefix="[!]" ;;
        ERROR)   color="$RED";    prefix="[-]" ;;
        *)       color="$WHITE";  prefix="[>]" ;;
    esac

    echo -e "  ${color}${prefix}${NC} ${message}"
}

fath_pause() {
    echo ""
    read -n 1 -s -r -p "  Pressione qualquer tecla para continuar..."
    echo ""
}

show_menu() {
    echo ""
    echo -e "  ${DARKCYAN}+--------------------------------------+${NC}"
    echo -e "  ${DARKCYAN}|${NC}${WHITE}       SELECIONE UMA OPCAO${NC}           ${DARKCYAN}|${NC}"
    echo -e "  ${DARKCYAN}+--------------------------------------+${NC}"
    echo -e "  ${DARKCYAN}|${NC}                                      ${DARKCYAN}|${NC}"
    echo -e "  ${DARKCYAN}|${NC}  ${GREEN}[1]${NC} Remover Ads (Anuncios)          ${DARKCYAN}|${NC}"
    echo -e "  ${DARKCYAN}|${NC}                                      ${DARKCYAN}|${NC}"
    echo -e "  ${DARKCYAN}|${NC}  ${GREEN}[2]${NC} Remover Podcasts               ${DARKCYAN}|${NC}"
    echo -e "  ${DARKCYAN}|${NC}                                      ${DARKCYAN}|${NC}"
    echo -e "  ${DARKCYAN}|${NC}  ${YELLOW}[3]${NC} Remover Ads + Podcasts          ${DARKCYAN}|${NC}"
    echo -e "  ${DARKCYAN}|${NC}                                      ${DARKCYAN}|${NC}"
    echo -e "  ${DARKCYAN}|${NC}  ${CYAN}[4]${NC} Restaurar Spotify Original      ${DARKCYAN}|${NC}"
    echo -e "  ${DARKCYAN}|${NC}                                      ${DARKCYAN}|${NC}"
    echo -e "  ${DARKCYAN}|${NC}  ${MAGENTA}[5]${NC} Baixar Musica (MP3)             ${DARKCYAN}|${NC}"
    echo -e "  ${DARKCYAN}|${NC}                                      ${DARKCYAN}|${NC}"
    echo -e "  ${DARKCYAN}|${NC}  ${MAGENTA}[6]${NC} Baixar Letra da Musica          ${DARKCYAN}|${NC}"
    echo -e "  ${DARKCYAN}|${NC}                                      ${DARKCYAN}|${NC}"
    echo -e "  ${DARKCYAN}|${NC}  ${RED}[0]${NC} Sair                            ${DARKCYAN}|${NC}"
    echo -e "  ${DARKCYAN}|${NC}                                      ${DARKCYAN}|${NC}"
    echo -e "  ${DARKCYAN}+--------------------------------------+${NC}"
    echo ""
}

# ============================================================
#  DETECCAO DO SPOTIFY
# ============================================================
SPOTIFY_PATH=""

find_spotify() {
    local paths=(
        "$HOME/.config/spotify"
        "/opt/spotify"
        "/usr/share/spotify"
        "/usr/lib/spotify"
        "$HOME/snap/spotify/current/.config/spotify"
        "$HOME/.var/app/com.spotify.Client/config/spotify"
    )

    for p in "${paths[@]}"; do
        if [ -d "$p" ]; then
            SPOTIFY_PATH="$p"
            return 0
        fi
    done

    return 1
}

# ============================================================
#  PARAR SPOTIFY
# ============================================================
stop_spotify() {
    fath_log "Fechando processos do Spotify..." "INFO"
    pkill -f spotify 2>/dev/null || killall spotify 2>/dev/null || true
    sleep 2
    fath_log "Processos do Spotify encerrados." "SUCCESS"
}

# ============================================================
#  BACKUP
# ============================================================
backup_spotify() {
    local spot_path="$1"
    local xpui_spa="$spot_path/Apps/xpui.spa"
    local xpui_bak="$spot_path/Apps/xpui.bak"

    if [ -f "$xpui_spa" ]; then
        if [ ! -f "$xpui_bak" ]; then
            cp "$xpui_spa" "$xpui_bak"
            fath_log "Backup criado: xpui.bak" "SUCCESS"
        else
            fath_log "Backup ja existe: xpui.bak" "INFO"
        fi
    fi
}

# ============================================================
#  RESTAURAR
# ============================================================
restore_spotify() {
    local spot_path="$1"
    local xpui_spa="$spot_path/Apps/xpui.spa"
    local xpui_bak="$spot_path/Apps/xpui.bak"
    local restored=false

    if [ -f "$xpui_bak" ]; then
        cp "$xpui_bak" "$xpui_spa"
        fath_log "Restaurado: xpui.spa" "SUCCESS"
        restored=true
    fi

    if [ "$restored" = false ]; then
        fath_log "Nenhum backup encontrado para restaurar." "WARN"
        return 1
    fi

    return 0
}

# ============================================================
#  PATCHING - REMOVER ADS
# ============================================================
remove_ads() {
    local spot_path="$1"
    local xpui_spa="$spot_path/Apps/xpui.spa"

    fath_log "Iniciando remocao de anuncios..." "INFO"

    if [ ! -f "$xpui_spa" ]; then
        fath_log "Arquivo xpui.spa nao encontrado!" "ERROR"
        return 1
    fi

    python3 -c "
import zipfile, os, sys, shutil, tempfile

spa_path = sys.argv[1]
version = sys.argv[2]
tmp_path = spa_path + '.tmp'

patch_count = 0

with zipfile.ZipFile(spa_path, 'r') as zin:
    with zipfile.ZipFile(tmp_path, 'w') as zout:
        for item in zin.infolist():
            data = zin.read(item.filename)

            if item.filename == 'xpui.js':
                content = data.decode('utf-8')

                # Patch 1: Desabilitar flag de ads
                if 'adsEnabled:!0' in content:
                    content = content.replace('adsEnabled:!0', 'adsEnabled:!1')
                    patch_count += 1
                    print('  \033[0;36m[*]\033[0m Patch aplicado: adsEnabled desabilitado')

                # Patch 2: Desabilitar sponsorships
                if 'allSponsorships' in content:
                    content = content.replace('allSponsorships', 'allSpnsrshpsOff')
                    patch_count += 1
                    print('  \033[0;36m[*]\033[0m Patch aplicado: sponsorships desabilitado')

                # Patch 3: Injetar interceptor de ads XHR
                if 'Patched by Fath Spot' not in content:
                    ads_patch = '''
// Patched by Fath Spot v''' + version + '''
(function(){
    var origOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function(){
        if(arguments[1] && arguments[1].indexOf('/ads/')!==-1){
            arguments[1]='about:blank';
        }
        return origOpen.apply(this, arguments);
    };
})();
'''
                    content += ads_patch
                    patch_count += 1
                    print('  \033[0;32m[+]\033[0m Patch aplicado: interceptor de ads XHR')

                data = content.encode('utf-8')
                zout.writestr(item, data)
            else:
                zout.writestr(item, data)

if patch_count > 0:
    shutil.move(tmp_path, spa_path)
    print('  \033[0;32m[+]\033[0m ' + str(patch_count) + ' patches de ads aplicados com sucesso!')
else:
    os.remove(tmp_path)
    print('  \033[1;33m[!]\033[0m Nenhum patch de ads necessario (ja aplicado ou versao incompativel)')

sys.exit(0 if patch_count > 0 else 2)
" "$xpui_spa" "$FATHSPOT_VERSION"

    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# ============================================================
#  PATCHING - REMOVER PODCASTS
# ============================================================
remove_podcasts() {
    local spot_path="$1"
    local xpui_spa="$spot_path/Apps/xpui.spa"

    fath_log "Iniciando remocao de podcasts..." "INFO"

    if [ ! -f "$xpui_spa" ]; then
        fath_log "Arquivo xpui.spa nao encontrado!" "ERROR"
        return 1
    fi

    python3 -c "
import zipfile, os, sys, shutil

spa_path = sys.argv[1]
tmp_path = spa_path + '.tmp'

block_js = '''(function() {
    var origFetch = window.fetch;
    window.fetch = async function() {
        var args = arguments;
        var response = await origFetch.apply(this, args);
        var url = (args[0] && args[0].url) || args[0] || \"\";
        if (typeof url === \"string\" && (url.indexOf(\"pathfinder\") !== -1 || url.indexOf(\"personalized-recommendations\") !== -1)) {
            try {
                var clone = response.clone();
                var data = await clone.json();
                function removePodcasts(obj) {
                    if (!obj) return obj;
                    if (Array.isArray(obj)) {
                        return obj.filter(function(item) {
                            if (!item) return true;
                            var tn = item.__typename || item.type || \"\";
                            var uri = item.uri || \"\";
                            if (/podcast|episode|show|audiobook/i.test(tn)) return false;
                            if (/spotify:show:|spotify:episode:/i.test(uri)) return false;
                            if (item.data && /podcast|episode|show|audiobook/i.test(item.data.__typename || \"\")) return false;
                            return true;
                        }).map(function(item) { return removePodcasts(item); });
                    }
                    if (typeof obj === \"object\") {
                        var keys = Object.keys(obj);
                        for (var i = 0; i < keys.length; i++) {
                            obj[keys[i]] = removePodcasts(obj[keys[i]]);
                        }
                    }
                    return obj;
                }
                if (data && data.data && data.data.home && data.data.home.sectionContainer && data.data.home.sectionContainer.sections && data.data.home.sectionContainer.sections.items) {
                    data.data.home.sectionContainer.sections.items = data.data.home.sectionContainer.sections.items.filter(function(section) {
                        if (!section || !section.data || !section.data.title || !section.data.title.text) return true;
                        var title = section.data.title.text.toLowerCase();
                        if (/podcast|episode|show|audiobook/i.test(title)) return false;
                        var items = (section.sectionItems && section.sectionItems.items) || [];
                        if (items.length > 0) {
                            var firstItem = items[0] && items[0].content && items[0].content.data;
                            if (firstItem && /podcast|episode|show|audiobook/i.test(firstItem.__typename || \"\")) return false;
                        }
                        return true;
                    });
                }
                removePodcasts(data);
                return new Response(JSON.stringify(data), { status: response.status, statusText: response.statusText, headers: response.headers });
            } catch(e) { return response; }
        }
        return response;
    };
})();
'''

patched = False

with zipfile.ZipFile(spa_path, 'r') as zin:
    with zipfile.ZipFile(tmp_path, 'w') as zout:
        existing_names = [i.filename for i in zin.infolist()]

        for item in zin.infolist():
            data = zin.read(item.filename)

            if item.filename == 'fathspot-block.js':
                # Substituir script existente
                continue

            if item.filename == 'index.html':
                content = data.decode('utf-8')
                if 'fathspot-block.js' not in content:
                    content = content.replace('</body>', '<script src=\"fathspot-block.js\"></script></body>')
                    print('  \033[0;32m[+]\033[0m index.html atualizado para carregar bloqueador de podcasts')
                    patched = True
                data = content.encode('utf-8')
                zout.writestr(item, data)
            else:
                zout.writestr(item, data)

        # Adicionar script de bloqueio
        zout.writestr('fathspot-block.js', block_js)
        print('  \033[0;32m[+]\033[0m Script de bloqueio de podcasts injetado')
        patched = True

if patched:
    shutil.move(tmp_path, spa_path)
    print('  \033[0;32m[+]\033[0m Remocao de podcasts concluida!')
else:
    os.remove(tmp_path)
    print('  \033[1;33m[!]\033[0m Podcasts ja estavam removidos.')

sys.exit(0)
" "$xpui_spa"

    return $?
}

# ============================================================
#  DOWNLOAD DE MUSICA (MP3) - via yt-dlp + ffmpeg
# ============================================================
ensure_ytdlp() {
    if command -v yt-dlp &>/dev/null; then
        return 0
    fi

    fath_log "yt-dlp nao encontrado. Tentando instalar..." "WARN"

    if command -v pip3 &>/dev/null; then
        fath_log "Instalando via pip3..." "INFO"
        pip3 install --user yt-dlp 2>/dev/null && return 0
    fi

    # Tentar baixar binario
    fath_log "Baixando binario do yt-dlp do GitHub..." "INFO"
    local ytdlp_dir="$HOME/.local/bin"
    mkdir -p "$ytdlp_dir"
    local ytdlp_url="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp"
    if curl -L -o "$ytdlp_dir/yt-dlp" "$ytdlp_url" 2>/dev/null; then
        chmod +x "$ytdlp_dir/yt-dlp"
        export PATH="$ytdlp_dir:$PATH"
        fath_log "yt-dlp instalado em $ytdlp_dir" "SUCCESS"
        return 0
    fi

    fath_log "Nao foi possivel instalar yt-dlp automaticamente." "ERROR"
    fath_log "Instale manualmente: pip3 install yt-dlp" "INFO"
    return 1
}

download_music() {
    echo ""
    fath_log "=== DOWNLOAD DE MUSICA ===" "INFO"
    echo ""

    if ! ensure_ytdlp; then
        return
    fi

    if ! command -v ffmpeg &>/dev/null; then
        fath_log "ffmpeg nao encontrado!" "WARN"
        fath_log "Instale via seu gerenciador de pacotes:" "INFO"
        fath_log "  Ubuntu/Debian: sudo apt install ffmpeg" "INFO"
        fath_log "  Fedora: sudo dnf install ffmpeg" "INFO"
        fath_log "  Arch: sudo pacman -S ffmpeg" "INFO"
        fath_log "Sem ffmpeg o download sera em formato webm/m4a" "WARN"
    fi

    echo -n "  Digite o nome da musica (ex: Artista - Nome da Musica): "
    read -r search_query

    if [ -z "$search_query" ]; then
        fath_log "Nenhuma musica informada." "WARN"
        return
    fi

    local download_dir="$HOME/Music/FathSpot Downloads"
    mkdir -p "$download_dir"

    fath_log "Buscando e baixando: $search_query" "INFO"
    fath_log "Destino: $download_dir" "INFO"
    echo ""

    if yt-dlp "ytsearch1:$search_query" \
        --extract-audio \
        --audio-format mp3 \
        --audio-quality 0 \
        -o "$download_dir/%(title)s.%(ext)s" \
        --no-playlist \
        --embed-thumbnail \
        --add-metadata; then
        echo ""
        fath_log "MUSICA BAIXADA COM SUCESSO!" "SUCCESS"
        fath_log "Salva em: $download_dir" "INFO"
    else
        fath_log "Erro no download." "ERROR"
        fath_log "Verifique o nome da musica e tente novamente." "WARN"
    fi
}

# ============================================================
#  DOWNLOAD DE LETRA DA MUSICA
# ============================================================
parse_json_field() {
    local json="$1"
    local field="$2"

    if command -v jq &>/dev/null; then
        echo "$json" | jq -r "$field" 2>/dev/null
    else
        python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
keys = sys.argv[1].lstrip('.').split('.')
obj = data
for k in keys:
    if obj is None:
        break
    if isinstance(obj, dict):
        obj = obj.get(k)
    else:
        obj = None
        break
if obj and isinstance(obj, str):
    print(obj)
else:
    sys.exit(1)
" "$field" <<< "$json" 2>/dev/null
    fi
}

url_encode() {
    python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$1"
}

download_lyrics() {
    echo ""
    fath_log "=== DOWNLOAD DE LETRA ===" "INFO"
    echo ""

    echo -n "  Digite o nome do artista: "
    read -r artist

    if [ -z "$artist" ]; then
        fath_log "Nenhum artista informado." "WARN"
        return
    fi

    echo -n "  Digite o nome da musica: "
    read -r song

    if [ -z "$song" ]; then
        fath_log "Nenhuma musica informada." "WARN"
        return
    fi

    fath_log "Buscando letra: $artist - $song" "INFO"

    local encoded_artist encoded_song lyrics=""
    encoded_artist=$(url_encode "$artist")
    encoded_song=$(url_encode "$song")

    # Tentar API lyrics.ovh
    local response
    response=$(curl -s --max-time 15 "https://api.lyrics.ovh/v1/$encoded_artist/$encoded_song" 2>/dev/null) || true
    if [ -n "$response" ]; then
        lyrics=$(parse_json_field "$response" ".lyrics") || true
    fi

    # Fallback: Musixmatch via lewdhutao
    if [ -z "$lyrics" ]; then
        fath_log "API lyrics.ovh nao retornou resultado, tentando alternativa..." "WARN"
        response=$(curl -s --max-time 15 "https://lyrics.lewdhutao.my.eu.org/v2/musixmatch/lyrics?title=$encoded_song&artist=$encoded_artist" 2>/dev/null) || true
        if [ -n "$response" ]; then
            lyrics=$(parse_json_field "$response" ".data.lyrics") || true
            if [ -n "$lyrics" ]; then
                fath_log "Letra encontrada via Musixmatch!" "SUCCESS"
            fi
        fi
    fi

    # Fallback 2: YouTube Music via lewdhutao
    if [ -z "$lyrics" ]; then
        fath_log "Musixmatch nao retornou resultado, tentando YouTube Music..." "WARN"
        response=$(curl -s --max-time 15 "https://lyrics.lewdhutao.my.eu.org/v2/youtube/lyrics?title=$encoded_song&artist=$encoded_artist" 2>/dev/null) || true
        if [ -n "$response" ]; then
            lyrics=$(parse_json_field "$response" ".data.lyrics") || true
            if [ -n "$lyrics" ]; then
                fath_log "Letra encontrada via YouTube Music!" "SUCCESS"
            fi
        fi
    fi

    if [ -n "$lyrics" ]; then
        echo ""
        echo -e "  ${MAGENTA}==========================================${NC}"
        echo -e "   ${YELLOW}${artist} - ${song}${NC}"
        echo -e "  ${MAGENTA}==========================================${NC}"
        echo ""
        while IFS= read -r line; do
            echo -e "   ${WHITE}${line}${NC}"
        done <<< "$lyrics"
        echo ""
        echo -e "  ${MAGENTA}==========================================${NC}"

        echo ""
        echo -n "  Deseja salvar a letra em arquivo? (S/N): "
        read -r save_choice

        if [[ "$save_choice" =~ ^[Ss] ]]; then
            local lyrics_dir="$HOME/Music/FathSpot Letras"
            mkdir -p "$lyrics_dir"

            local safe_artist safe_song
            safe_artist=$(echo "$artist" | tr '\\/:*?"<>|' '_')
            safe_song=$(echo "$song" | tr '\\/:*?"<>|' '_')

            local lyrics_file="$lyrics_dir/$safe_artist - $safe_song.txt"

            {
                echo "$artist - $song"
                printf '=%.0s' {1..40}
                echo ""
                echo ""
                echo "$lyrics"
                echo ""
                echo "Baixado por Fath Spot v$FATHSPOT_VERSION"
            } > "$lyrics_file"

            fath_log "Letra salva em: $lyrics_file" "SUCCESS"
        fi
    else
        fath_log "Letra nao encontrada para: $artist - $song" "ERROR"
        fath_log "Verifique o nome do artista e da musica." "WARN"
    fi
}

# ============================================================
#  VERIFICACAO DE DEPENDENCIAS
# ============================================================
check_dependencies() {
    if ! command -v python3 &>/dev/null; then
        fath_log "python3 nao encontrado! E necessario para o funcionamento do Fath Spot." "ERROR"
        fath_log "Instale via seu gerenciador de pacotes:" "INFO"
        fath_log "  Ubuntu/Debian: sudo apt install python3" "INFO"
        fath_log "  Fedora: sudo dnf install python3" "INFO"
        fath_log "  Arch: sudo pacman -S python" "INFO"
        echo ""
        exit 1
    fi

    if ! command -v curl &>/dev/null; then
        fath_log "curl nao encontrado! E necessario para download de letras." "WARN"
    fi
}

# ============================================================
#  LOOP PRINCIPAL
# ============================================================
main() {
    show_banner
    check_dependencies

    if ! find_spotify; then
        fath_log "Spotify nao encontrado!" "ERROR"
        fath_log "Instale o Spotify Desktop oficial primeiro:" "INFO"
        fath_log "  Snap: sudo snap install spotify" "INFO"
        fath_log "  Flatpak: flatpak install flathub com.spotify.Client" "INFO"
        fath_log "  Ou baixe em: https://www.spotify.com/download/linux/" "INFO"
        echo ""
        read -n 1 -s -r -p "  Pressione qualquer tecla para sair..."
        echo ""
        exit 1
    fi

    fath_log "Spotify encontrado: $SPOTIFY_PATH" "SUCCESS"
    echo ""

    local running=true
    while $running; do
        show_menu
        echo -n "  Escolha: "
        read -r choice

        case "$choice" in
            1)
                echo ""
                stop_spotify
                backup_spotify "$SPOTIFY_PATH"
                if remove_ads "$SPOTIFY_PATH"; then
                    echo ""
                    fath_log "ADS REMOVIDOS COM SUCESSO!" "SUCCESS"
                    fath_log "Abra o Spotify para ver as mudancas." "INFO"
                fi
                fath_pause
                show_banner
                ;;
            2)
                echo ""
                stop_spotify
                backup_spotify "$SPOTIFY_PATH"
                if remove_podcasts "$SPOTIFY_PATH"; then
                    echo ""
                    fath_log "PODCASTS REMOVIDOS COM SUCESSO!" "SUCCESS"
                    fath_log "Abra o Spotify para ver as mudancas." "INFO"
                fi
                fath_pause
                show_banner
                ;;
            3)
                echo ""
                stop_spotify
                backup_spotify "$SPOTIFY_PATH"
                local ads_ok=false pod_ok=false
                remove_ads "$SPOTIFY_PATH" && ads_ok=true
                remove_podcasts "$SPOTIFY_PATH" && pod_ok=true
                if $ads_ok || $pod_ok; then
                    echo ""
                    fath_log "ADS + PODCASTS REMOVIDOS COM SUCESSO!" "SUCCESS"
                    fath_log "Abra o Spotify para ver as mudancas." "INFO"
                fi
                fath_pause
                show_banner
                ;;
            4)
                echo ""
                stop_spotify
                if restore_spotify "$SPOTIFY_PATH"; then
                    echo ""
                    fath_log "SPOTIFY RESTAURADO COM SUCESSO!" "SUCCESS"
                fi
                fath_pause
                show_banner
                ;;
            5)
                download_music
                fath_pause
                show_banner
                ;;
            6)
                download_lyrics
                fath_pause
                show_banner
                ;;
            0)
                echo ""
                fath_log "Saindo do Fath Spot... Ate mais!" "INFO"
                echo ""
                running=false
                ;;
            *)
                fath_log "Opcao invalida! Tente novamente." "WARN"
                ;;
        esac
    done
}

main "$@"
