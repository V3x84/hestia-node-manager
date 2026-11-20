#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

clear

echo
echo -e "${CYAN}=====================================================${NC}"
echo -e "${WHITE}REINICIAR APLICACIÓN NODEJS${NC}"
echo -e "${YELLOW}Creado por V3X${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Ejecute esta opción como root (sudo).${NC}"
    exit 1
fi

if ! command -v pm2 >/dev/null 2>&1; then
    echo -e "${RED}PM2 no está instalado en el servidor.${NC}"
    exit 1
fi

# ==========================================
# USUARIO
# ==========================================

echo -e "${YELLOW}Usuarios disponibles:${NC}"
echo
echo "0) Regresar al Menú Principal"
echo

/usr/local/hestia/bin/v-list-users | awk 'NR>2 {print NR-2") "$1}'

echo
read -r -p "Seleccione usuario: " OPT

if [ "$OPT" = "0" ]; then
    exit 0
fi

USER=$(
    /usr/local/hestia/bin/v-list-users |
    awk 'NR>2 {print $1}' |
    sed -n "${OPT}p"
)

if [ -z "$USER" ]; then
    echo
    echo -e "${RED}Usuario no válido.${NC}"
    echo
    read -r -p "ENTER para regresar..." TMP
    exit 1
fi

# ==========================================
# DOMINIO
# ==========================================

echo
echo -e "${YELLOW}Dominios encontrados:${NC}"
echo
echo "0) Regresar al Menú Principal"
echo

/usr/local/hestia/bin/v-list-web-domains "$USER" | awk 'NR>2 {print NR-2") "$1}'

echo
read -r -p "Seleccione dominio: " DOPT

if [ "$DOPT" = "0" ]; then
    exit 0
fi

DOMAIN=$(
    /usr/local/hestia/bin/v-list-web-domains "$USER" |
    awk 'NR>2 {print $1}' |
    sed -n "${DOPT}p"
)

if [ -z "$DOMAIN" ]; then
    echo
    echo -e "${RED}Dominio no válido.${NC}"
    echo
    read -r -p "ENTER para regresar..." TMP
    exit 1
fi

CURRENT_PROXY=$(
    /usr/local/hestia/bin/v-list-web-domain "$USER" "$DOMAIN" |
    grep "^PROXY:" |
    awk '{print $2}'
)

if [[ ! "$CURRENT_PROXY" =~ NODEJS ]]; then
    echo
    echo -e "${RED}El dominio no utiliza una plantilla NodeJS.${NC}"
    echo
    read -r -p "ENTER para regresar..." TMP
    exit 0
fi

PORT=$(echo "$CURRENT_PROXY" | sed -n 's/^NODEJS\([0-9][0-9]*\)$/\1/p')

echo
echo -e "${CYAN}=====================================================${NC}"
echo -e "${WHITE}CONFIRMAR REINICIO${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo
echo -e "${GREEN}Usuario:${NC} $USER"
echo -e "${GREEN}Dominio:${NC} $DOMAIN"
echo -e "${GREEN}Proxy:${NC}   $CURRENT_PROXY"
[ -n "$PORT" ] && echo -e "${GREEN}Puerto:${NC}  $PORT"
echo

read -r -p "¿Reiniciar aplicación? [s/N]: " CONF

if [[ "$CONF" != "s" && "$CONF" != "S" ]]; then
    exit 0
fi

echo
echo -e "${YELLOW}Procesos PM2 disponibles para $USER:${NC}"
echo

runuser -u "$USER" -- pm2 list

echo
read -r -p "Nombre o ID del proceso PM2 (0 para cancelar): " PROCESS

if [ -z "$PROCESS" ] || [ "$PROCESS" = "0" ]; then
    exit 0
fi

echo
echo -e "${YELLOW}Reiniciando proceso: $PROCESS...${NC}"

if runuser -u "$USER" -- pm2 restart "$PROCESS" --update-env; then
    echo
    echo -e "${GREEN}Aplicación reiniciada correctamente.${NC}"
    echo
    runuser -u "$USER" -- pm2 list

    REGISTRY="/usr/local/bin/hestia-node-tools/registry.db"
    if [ -f "$REGISTRY" ]; then
        REGISTRY_TMP=$(mktemp)
        NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        awk -F '\t' -v OFS='\t' -v DOMAIN="$DOMAIN" -v NOW="$NOW" \
            '$2 == DOMAIN { $8 = "active"; $10 = NOW } { print }' \
            "$REGISTRY" > "$REGISTRY_TMP"
        mv "$REGISTRY_TMP" "$REGISTRY"
        chmod 600 "$REGISTRY"
    fi
else
    echo
    echo -e "${RED}No se pudo reiniciar el proceso \"$PROCESS\".${NC}"
    echo "Compruebe el nombre o ID mostrado por PM2."
    exit 1
fi
