#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

clear

echo
echo -e "${CYAN}=====================================================${NC}"
echo -e "${WHITE}ESTADO DE PUERTOS NODEJS${NC}"
echo -e "${CYAN}Creado por V3X${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo

printf "%-8s %-12s %-40s\n" "PUERTO" "ESTADO" "DOMINIO"
echo "---------------------------------------------------------------------"

PORTS=$(ls /usr/local/hestia/data/templates/web/nginx/NODEJS*.tpl 2>/dev/null \
| sed 's/.*NODEJS//' \
| sed 's/.tpl//' \
| sort -n)

for P in $PORTS
do

    DOMAIN_FOUND=$(
        grep -R "PROXY='NODEJS${P}'" \
        /usr/local/hestia/data/users/ 2>/dev/null |
        head -n1 |
        sed -n "s/.*DOMAIN='\([^']*\)'.*/\1/p"
    )

    if [ -n "$DOMAIN_FOUND" ]; then

        printf "%-8s %-12s %-40s\n" \
        "$P" "USADO" "$DOMAIN_FOUND"

    else

        printf "%-8s %-12s %-40s\n" \
        "$P" "LIBRE" "-"

    fi

done

echo
