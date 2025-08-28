#!/bin/bash

# Este script monitora e exibe o status de players de mídia que suportam MPRIS.
# A rolagem do texto só ocorre quando a música está tocando (status "Playing").

# Use a função 'slice_loop' para criar um efeito de rolagem (marquee) no texto.
# A função pega um 'pedaço' da string e, ao atingir o final, reinicia a partir do começo.
function slice_loop () {
    local str="$1"
    local start=$2
    local how_many=$3
    local len=${#str};

    local result="";

    for ((i=0; i < how_many; i++)); do
        local index=$(((start+i) % len)) # Calcula o índice e 'volta' ao início se necessário
        local char="${str:index:1}"      # Pega o caractere na posição calculada
        local result="$result$char"      # Adiciona o caractere ao resultado
    done

    echo -n $result
}

# Variáveis iniciais
begin=0
work_text=""

while :; do
    state=$(playerctl status 2>/dev/null)
    
    # Busca os metadados da música para o player ativo.
    text=$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null)

    case $state in
        "Playing")
            # Se o texto da música mudou, reinicia a rolagem.
            if [[ "$work_text" != "$text" ]]; then
                work_text=$text
                begin=0
            fi

            # Adiciona um espaço ao final para uma transição suave na rolagem.
            slice=$(slice_loop "$work_text | " $begin 20)
            
            # Exibe o ícone de 'play' e o texto em rolagem.
            playerctl metadata --format '{"text": "'" $slice"'", "tooltip": "{{playerName}} : {{artist}} - {{title}}"}'
            
            sleep 0.2
            ((begin++))
            ;;
            
        "Paused")
            # Exibe o ícone de 'pausado' e o texto estático.
            # Limita o tamanho do texto para evitar que fique muito longo na barra.
            if [[ ${#text} -gt 20 ]]; then
                text=${text:0:20}
            fi
            
            playerctl metadata --format '{"text": "'" $text"'", "tooltip": "{{playerName}} : {{artist}} - {{title}}"}'
            
            sleep 0.2
            ;;
            
        "Stopped")
            # Exibe o ícone de 'stop' quando a reprodução é interrompida.
            playerctl metadata --format '{"text": "'"◼️ No music playing"'", "tooltip": "{{playerName}} : {{artist}} - {{title}}"}'
            
            sleep 0.2
            ;;
            
        *)
            # Caso não haja players ativos.
            echo '{"text": "'"◼️ No player found"'", "tooltip": "Nothing playing right now"}'
            
            sleep 0.2
            ;;
    esac
done
