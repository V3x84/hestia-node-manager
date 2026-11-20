#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

TPL_DIR="/usr/local/hestia/data/templates/web/nginx"

LAST_PORT=$(
ls $TPL_DIR/NODEJS*.tpl |
sed 's/.*NODEJS//' |
sed 's/.tpl//' |
sort -n |
tail -1
)

NEW_PORT=$((LAST_PORT + 1))

echo
echo -e "${CYAN}=====================================================${NC}"
echo -e "${WHITE}CREAR NUEVA PLANTILLA${NC}"
echo -e "${CYAN}Creado por V3X${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo

echo "Plantilla origen : NODEJS${LAST_PORT}"
echo "Nueva plantilla  : NODEJS${NEW_PORT}"
echo

read -p "Continuar (s/n): " CONF

if [[ "$CONF" != "s" && "$CONF" != "S" ]]; then
    exit 0
fi

cp \
$TPL_DIR/NODEJS${LAST_PORT}.tpl \
$TPL_DIR/NODEJS${NEW_PORT}.tpl

cp \
$TPL_DIR/NODEJS${LAST_PORT}.stpl \
$TPL_DIR/NODEJS${NEW_PORT}.stpl

sed -i \
"s/127.0.0.1:${LAST_PORT}/127.0.0.1:${NEW_PORT}/g" \
$TPL_DIR/NODEJS${NEW_PORT}.tpl

sed -i \
"s/127.0.0.1:${LAST_PORT}/127.0.0.1:${NEW_PORT}/g" \
$TPL_DIR/NODEJS${NEW_PORT}.stpl

echo
echo -e "${GREEN}Plantilla creada correctamente${NC}"
echo
echo "NODEJS${NEW_PORT}"
echo
