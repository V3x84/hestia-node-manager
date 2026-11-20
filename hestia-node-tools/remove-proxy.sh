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
echo -e "${WHITE}DAR DE BAJA PROYECTO NODEJS${NC}"
echo -e "${YELLOW}Creado por V3X${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo

echo "0) Regresar al Menú Principal"
echo

/usr/local/hestia/bin/v-list-users | awk 'NR>2 {print NR-2") "$1}'

echo
read -p "Seleccione usuario: " OPT

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
    echo -e "${RED}Usuario no válido${NC}"
    sleep 2
    exit 1

fi

echo
echo "Dominios:"
echo

echo "0) Regresar al Menú Principal"
echo

/usr/local/hestia/bin/v-list-web-domains "$USER" |
awk 'NR>2 {print NR-2") "$1}'

echo
read -p "Seleccione dominio: " DOPT

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
    echo -e "${RED}Dominio no válido${NC}"
    sleep 2
    exit 1

fi

CURRENT_PROXY=$(
/usr/local/hestia/bin/v-list-web-domain \
"$USER" \
"$DOMAIN" |
grep "^PROXY:" |
awk '{print $2}'
)

echo
echo -e "${GREEN}Usuario:${NC} $USER"
echo -e "${GREEN}Dominio:${NC} $DOMAIN"
echo -e "${GREEN}Proxy:${NC}   $CURRENT_PROXY"
echo

if [[ ! "$CURRENT_PROXY" =~ NODEJS ]]; then

    echo
    echo -e "${RED}El dominio no utiliza NodeJS.${NC}"
    echo

    read -p "ENTER para regresar..." TMP

    exit 0

fi

echo
echo -e "${RED}ATENCION${NC}"
echo "Esta acción liberará el puerto NodeJS."
echo

read -p "Confirmar baja (s/n/0): " CONF

if [ "$CONF" = "0" ]; then
    exit 0
fi

if [[ "$CONF" != "s" && "$CONF" != "S" ]]; then
    exit 0
fi

/usr/local/hestia/bin/v-change-web-domain-proxy-tpl \
"$USER" \
"$DOMAIN" \
"default"

if [ $? -ne 0 ]; then

    echo
    echo -e "${RED}Error cambiando plantilla.${NC}"
    echo
    exit 1

fi

/usr/local/hestia/bin/v-rebuild-web-domain \
"$USER" \
"$DOMAIN"

systemctl reload nginx

REGISTRY="/usr/local/bin/hestia-node-tools/registry.db"
if [ -f "$REGISTRY" ]; then
    REGISTRY_TMP=$(mktemp)
    NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    awk -F '\t' -v OFS='\t' -v DOMAIN="$DOMAIN" -v NOW="$NOW" \
        '$2 == DOMAIN { $8 = "removed"; $10 = NOW } { print }' \
        "$REGISTRY" > "$REGISTRY_TMP"
    mv "$REGISTRY_TMP" "$REGISTRY"
    chmod 600 "$REGISTRY"
fi

echo
echo -e "${GREEN}✓ Proyecto dado de baja correctamente.${NC}"
echo

read -p "ENTER para regresar..." TMP
