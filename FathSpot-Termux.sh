#!/usr/bin/env bash
# ============================================================
#  Fath Spot - Spotify Tools para Termux/Android
#  Versao mobile do FathSpot (download de musica e letras)
# ============================================================

FATHSPOT_VERSION="1.1.0"

# Detectar Termux
IS_TERMUX=false
if [[ -n "$PREFIX" ]] || [[ -d "/data/data/com.termux" ]]; then
    IS_TERMUX=true
fi

# Diretorios
if $IS_TERMUX; then
    MUSIC_DIR="$HOME/storage/music/FathSpot Downloads"
    LYRICS_DIR="$HOME/storage/music/FathSpot Letras"
else
    MUSIC_DIR="$HOME/Music/FathSpot Downloads"
    LYRICS_DIR="$HOME/Music/FathSpot Letras"
fi

# ============================================================
#  CORES ANSI
# ============================================================
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
DARK_CYAN='\033[0;36m'
DARK_YELLOW='\033[0;33m'
RESET='\033[0m'

# ============================================================
#  LOGGING
# ============================================================
fath_log() {
    local msg="$1"
    local type="${2:-INFO}"
    local prefix color

    case "$type" in
        INFO)    prefix="[*]"; color="$CYAN" ;;
        SUCCESS) prefix="[+]"; color="$GREEN" ;;
        WARN)    prefix="[!]"; color="$YELLOW" ;;
        ERROR)   prefix="[-]"; color="$RED" ;;
        *)       prefix="[>]"; color="$WHITE" ;;
    esac

    echo -e "  ${color}${prefix}${RESET} ${msg}"
}

# ============================================================
#  BANNER
# ============================================================
show_banner() {
    clear
    echo ""
    echo -e "  ${GREEN}==========================================${RESET}"
    echo -e "  ${GREEN}||${RESET}                                      ${GREEN}||${RESET}"
    echo -e "  ${GREEN}||${RESET}${YELLOW}        F A T H   S P O T${RESET}          ${GREEN}||${RESET}"
    echo -e "  ${GREEN}||${RESET}${CYAN}   Spotify Tools for Termux/Android${RESET}  ${GREEN}||${RESET}"
    echo -e "  ${GREEN}||${RESET}${GRAY}             v${FATHSPOT_VERSION}${RESET}                  ${GREEN}||${RESET}"
    echo -e "  ${GREEN}||${RESET}                                      ${GREEN}||${RESET}"
    echo -e "  ${GREEN}==========================================${RESET}"
    echo -e "  ${DARK_YELLOW}~ Fenix renascendo no Spotify ~${RESET}"
    echo ""

    if ! $IS_TERMUX; then
        fath_log "AVISO: Voce nao esta no Termux. Algumas funcoes podem nao funcionar." "WARN"
        echo ""
    fi
}

# ============================================================
#  MENU
# ============================================================
show_menu() {
    echo ""
    echo -e "  ${DARK_CYAN}+--------------------------------------+${RESET}"
    echo -e "  ${DARK_CYAN}|${RESET}${WHITE}       SELECIONE UMA OPCAO${RESET}           ${DARK_CYAN}|${RESET}"
    echo -e "  ${DARK_CYAN}+--------------------------------------+${RESET}"
    echo -e "  ${DARK_CYAN}|${RESET}                                      ${DARK_CYAN}|${RESET}"
    echo -e "  ${DARK_CYAN}|${RESET}  ${GREEN}[1]${RESET}${WHITE} Baixar Musica (MP3)${RESET}             ${DARK_CYAN}|${RESET}"
    echo -e "  ${DARK_CYAN}|${RESET}                                      ${DARK_CYAN}|${RESET}"
    echo -e "  ${DARK_CYAN}|${RESET}  ${MAGENTA}[2]${RESET}${WHITE} Baixar Letra da Musica${RESET}          ${DARK_CYAN}|${RESET}"
    echo -e "  ${DARK_CYAN}|${RESET}                                      ${DARK_CYAN}|${RESET}"
    echo -e "  ${DARK_CYAN}|${RESET}  ${YELLOW}[3]${RESET}${WHITE} Configurar Termux${RESET}               ${DARK_CYAN}|${RESET}"
    echo -e "  ${DARK_CYAN}|${RESET}                                      ${DARK_CYAN}|${RESET}"
    echo -e "  ${DARK_CYAN}|${RESET}  ${RED}[0]${RESET}${WHITE} Sair${RESET}                            ${DARK_CYAN}|${RESET}"
    echo -e "  ${DARK_CYAN}|${RESET}                                      ${DARK_CYAN}|${RESET}"
    echo -e "  ${DARK_CYAN}+--------------------------------------+${RESET}"
    echo ""
}

# ============================================================
#  PAUSA
# ============================================================
fath_pause() {
    echo ""
    read -n 1 -s -r -p "  Pressione qualquer tecla para continuar..."
    echo ""
}

# ============================================================
#  CHECAR STORAGE
# ============================================================
check_storage() {
    if [[ ! -d "$HOME/storage" ]]; then
        fath_log "Permissao de storage nao configurada." "WARN"
        fath_log "Executando termux-setup-storage..." "INFO"
        termux-setup-storage
        sleep 2
        if [[ ! -d "$HOME/storage" ]]; then
            fath_log "Falha ao configurar storage. Execute manualmente: termux-setup-storage" "ERROR"
            return 1
        fi
        fath_log "Storage configurado com sucesso!" "SUCCESS"
    fi
    return 0
}

# ============================================================
#  JSON PARSER (jq ou python3 fallback)
# ============================================================
parse_json() {
    local json="$1"
    local field="$2"

    if command -v jq &>/dev/null; then
        echo "$json" | jq -r "$field" 2>/dev/null
    elif command -v python3 &>/dev/null; then
        echo "$json" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    keys = '$field'.strip('.').split('.')
    result = data
    for k in keys:
        if isinstance(result, dict) and k in result:
            result = result[k]
        else:
            result = None
            break
    if result is not None:
        print(result)
except:
    pass
" 2>/dev/null
    else
        fath_log "Nenhum parser JSON disponivel (jq ou python3)." "ERROR"
        fath_log "Execute a opcao [3] para instalar dependencias." "WARN"
        return 1
    fi
}

# ============================================================
#  OPCAO 1 - BAIXAR MUSICA (MP3)
# ============================================================
download_music() {
    echo ""
    fath_log "=== DOWNLOAD DE MUSICA ===" "INFO"
    echo ""

    # Checar yt-dlp
    if ! command -v yt-dlp &>/dev/null; then
        fath_log "yt-dlp nao encontrado!" "ERROR"
        echo -ne "  Deseja instalar agora? (S/N): "
        read -r install_choice
        if [[ "$install_choice" =~ ^[Ss]$ ]]; then
            fath_log "Instalando yt-dlp e ffmpeg..." "INFO"
            pkg install python ffmpeg -y && pip install yt-dlp
            if ! command -v yt-dlp &>/dev/null; then
                fath_log "Falha na instalacao do yt-dlp." "ERROR"
                return
            fi
            fath_log "yt-dlp instalado com sucesso!" "SUCCESS"
        else
            fath_log "Download cancelado. Instale com: pkg install python ffmpeg && pip install yt-dlp" "WARN"
            return
        fi
    fi

    # Checar ffmpeg
    if ! command -v ffmpeg &>/dev/null; then
        fath_log "ffmpeg nao encontrado!" "ERROR"
        echo -ne "  Deseja instalar agora? (S/N): "
        read -r install_choice
        if [[ "$install_choice" =~ ^[Ss]$ ]]; then
            pkg install ffmpeg -y
            if ! command -v ffmpeg &>/dev/null; then
                fath_log "Falha na instalacao do ffmpeg." "ERROR"
                return
            fi
            fath_log "ffmpeg instalado com sucesso!" "SUCCESS"
        else
            fath_log "Download cancelado. Instale com: pkg install ffmpeg" "WARN"
            return
        fi
    fi

    # Pedir nome da musica
    echo -ne "  Digite o nome da musica (ou artista - musica): "
    read -r query

    if [[ -z "$query" ]]; then
        fath_log "Nenhuma musica informada." "WARN"
        return
    fi

    # Checar storage (Termux)
    if $IS_TERMUX; then
        check_storage || return
    fi

    # Criar diretorio de download
    mkdir -p "$MUSIC_DIR"

    fath_log "Buscando e baixando: $query" "INFO"
    fath_log "Destino: $MUSIC_DIR" "INFO"
    echo ""

    yt-dlp "ytsearch1:$query" \
        --extract-audio \
        --audio-format mp3 \
        --audio-quality 0 \
        -o "$MUSIC_DIR/%(title)s.%(ext)s" \
        --no-playlist \
        --embed-thumbnail \
        --add-metadata

    if [[ $? -eq 0 ]]; then
        echo ""
        fath_log "MUSICA BAIXADA COM SUCESSO!" "SUCCESS"
        fath_log "Salva em: $MUSIC_DIR" "INFO"
    else
        echo ""
        fath_log "Erro no download." "ERROR"
        fath_log "Verifique o nome da musica e tente novamente." "WARN"
    fi
}

# ============================================================
#  OPCAO 2 - BAIXAR LETRA DA MUSICA
# ============================================================
download_lyrics() {
    echo ""
    fath_log "=== DOWNLOAD DE LETRA ===" "INFO"
    echo ""

    echo -ne "  Digite o nome do artista: "
    read -r artist

    if [[ -z "$artist" ]]; then
        fath_log "Nenhum artista informado." "WARN"
        return
    fi

    echo -ne "  Digite o nome da musica: "
    read -r song

    if [[ -z "$song" ]]; then
        fath_log "Nenhuma musica informada." "WARN"
        return
    fi

    fath_log "Buscando letra: $artist - $song" "INFO"

    # URL-encode artista e musica
    local encoded_artist encoded_song
    if command -v python3 &>/dev/null; then
        encoded_artist=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$artist'))" 2>/dev/null)
        encoded_song=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$song'))" 2>/dev/null)
    else
        encoded_artist=$(echo "$artist" | sed 's/ /%20/g')
        encoded_song=$(echo "$song" | sed 's/ /%20/g')
    fi

    local lyrics=""
    local response

    # Tentar API lyrics.ovh
    response=$(curl -s --max-time 15 "https://api.lyrics.ovh/v1/${encoded_artist}/${encoded_song}" 2>/dev/null)
    if [[ -n "$response" ]]; then
        lyrics=$(parse_json "$response" ".lyrics")
    fi

    # Fallback: Musixmatch via lewdhutao
    if [[ -z "$lyrics" ]] || [[ "$lyrics" == "null" ]]; then
        fath_log "API lyrics.ovh nao retornou resultado, tentando Musixmatch..." "WARN"
        response=$(curl -s --max-time 15 "https://lyrics.lewdhutao.my.eu.org/v2/musixmatch/lyrics?title=${encoded_song}&artist=${encoded_artist}" 2>/dev/null)
        if [[ -n "$response" ]]; then
            lyrics=$(parse_json "$response" ".data.lyrics")
            if [[ -n "$lyrics" ]] && [[ "$lyrics" != "null" ]]; then
                fath_log "Letra encontrada via Musixmatch!" "SUCCESS"
            fi
        fi
    fi

    # Fallback 2: YouTube Music via lewdhutao
    if [[ -z "$lyrics" ]] || [[ "$lyrics" == "null" ]]; then
        fath_log "Musixmatch nao retornou resultado, tentando YouTube Music..." "WARN"
        response=$(curl -s --max-time 15 "https://lyrics.lewdhutao.my.eu.org/v2/youtube/lyrics?title=${encoded_song}&artist=${encoded_artist}" 2>/dev/null)
        if [[ -n "$response" ]]; then
            lyrics=$(parse_json "$response" ".data.lyrics")
            if [[ -n "$lyrics" ]] && [[ "$lyrics" != "null" ]]; then
                fath_log "Letra encontrada via YouTube Music!" "SUCCESS"
            fi
        fi
    fi

    # Exibir resultado
    if [[ -n "$lyrics" ]] && [[ "$lyrics" != "null" ]]; then
        echo ""
        echo -e "  ${MAGENTA}==========================================${RESET}"
        echo -e "   ${YELLOW}${artist} - ${song}${RESET}"
        echo -e "  ${MAGENTA}==========================================${RESET}"
        echo ""
        while IFS= read -r line; do
            echo -e "   ${WHITE}${line}${RESET}"
        done <<< "$lyrics"
        echo ""
        echo -e "  ${MAGENTA}==========================================${RESET}"

        # Salvar em arquivo
        echo ""
        echo -ne "  Deseja salvar a letra em arquivo? (S/N): "
        read -r save_choice

        if [[ "$save_choice" =~ ^[Ss]$ ]]; then
            if $IS_TERMUX; then
                check_storage || return
            fi

            mkdir -p "$LYRICS_DIR"

            local safe_artist safe_song
            safe_artist=$(echo "$artist" | sed 's/[\\/:*?"<>|]/_/g')
            safe_song=$(echo "$song" | sed 's/[\\/:*?"<>|]/_/g')
            local lyrics_file="$LYRICS_DIR/${safe_artist} - ${safe_song}.txt"

            {
                echo "$artist - $song"
                printf '=%.0s' {1..40}
                echo ""
                echo ""
                echo "$lyrics"
                echo ""
                echo "Baixado por Fath Spot v${FATHSPOT_VERSION}"
            } > "$lyrics_file"

            fath_log "Letra salva em: $lyrics_file" "SUCCESS"
        fi
    else
        fath_log "Letra nao encontrada para: $artist - $song" "ERROR"
        fath_log "Verifique o nome do artista e da musica." "WARN"
    fi
}

# ============================================================
#  OPCAO 3 - CONFIGURAR TERMUX
# ============================================================
configure_termux() {
    echo ""
    fath_log "=== CONFIGURACAO DO TERMUX ===" "INFO"
    echo ""

    # Storage
    fath_log "Configurando acesso ao armazenamento..." "INFO"
    termux-setup-storage
    sleep 2

    # Dependencias
    fath_log "Atualizando pacotes e instalando dependencias..." "INFO"
    echo ""

    pkg update -y && pkg install python curl ffmpeg jq -y

    if [[ $? -eq 0 ]]; then
        fath_log "Pacotes instalados com sucesso!" "SUCCESS"
    else
        fath_log "Erro ao instalar pacotes." "ERROR"
    fi

    fath_log "Instalando yt-dlp via pip..." "INFO"
    pip install yt-dlp

    if [[ $? -eq 0 ]]; then
        fath_log "yt-dlp instalado com sucesso!" "SUCCESS"
    else
        fath_log "Erro ao instalar yt-dlp." "ERROR"
    fi

    echo ""
    fath_log "========================================" "SUCCESS"
    fath_log "CONFIGURACAO COMPLETA!" "SUCCESS"
    fath_log "========================================" "SUCCESS"
    echo ""
    fath_log "Dependencias instaladas:" "INFO"
    fath_log "  - python3, curl, ffmpeg, jq, yt-dlp" "INFO"
    fath_log "Voce ja pode usar as opcoes [1] e [2]." "INFO"
}

# ============================================================
#  LOOP PRINCIPAL
# ============================================================
main() {
    show_banner

    while true; do
        show_menu
        echo -ne "  Escolha: "
        read -r choice

        case "$choice" in
            1)
                download_music
                fath_pause
                show_banner
                ;;
            2)
                download_lyrics
                fath_pause
                show_banner
                ;;
            3)
                configure_termux
                fath_pause
                show_banner
                ;;
            0)
                echo ""
                fath_log "Saindo do Fath Spot... Ate mais!" "INFO"
                echo ""
                exit 0
                ;;
            *)
                fath_log "Opcao invalida! Tente novamente." "WARN"
                ;;
        esac
    done
}

main
