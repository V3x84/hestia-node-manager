#!/bin/bash

# ==========================================
# COLORES
# ==========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

clear

echo
echo -e "${CYAN}=====================================================${NC}"
echo -e "${WHITE}ASIGNAR PROXY NODEJS${NC}"
echo -e "${YELLOW}Creado por V3X${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo

# ==========================================
# USUARIOS
# ==========================================

echo -e "${YELLOW}Usuarios disponibles:${NC}"
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
    echo -e "${RED}ERROR:${NC} Usuario no válido"
    echo

    read -p "ENTER para regresar..." TMP
    exit 1

fi

if [ "$USER" = "alexishestia" ]; then

    echo
    echo -e "${RED}ERROR:${NC} No se permite utilizar el usuario administrador."
    echo

    read -p "ENTER para regresar..." TMP
    exit 1

fi

echo
echo -e "${GREEN}Usuario seleccionado:${NC} $USER"

# ==========================================
# DOMINIOS
# ==========================================

echo
echo -e "${YELLOW}Dominios encontrados:${NC}"
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
    echo -e "${RED}ERROR:${NC} Dominio no válido"
    echo

    read -p "ENTER para regresar..." TMP
    exit 1

fi

echo
echo -e "${GREEN}Dominio seleccionado:${NC} $DOMAIN"

# ==========================================
# VALIDAR SI YA TIENE NODEJS
# ==========================================

CURRENT_PROXY=$(
/usr/local/hestia/bin/v-list-web-domain "$USER" "$DOMAIN" |
grep "^PROXY:" |
awk '{print $2}'
)

if [[ "$CURRENT_PROXY" =~ NODEJS ]]; then

    echo
    echo -e "${RED}=====================================================${NC}"
    echo -e "${RED}EL DOMINIO YA TIENE NODEJS CONFIGURADO${NC}"
    echo -e "${RED}=====================================================${NC}"
    echo

    echo "Dominio : $DOMAIN"
    echo "Proxy   : $CURRENT_PROXY"
    echo

    read -p "ENTER para regresar..." TMP

    exit 0

fi

# ==========================================
# ESTADO DE PUERTOS
# ==========================================

echo
echo -e "${CYAN}=====================================================${NC}"
echo -e "${WHITE}ESTADO DE PUERTOS NODEJS${NC}"
echo -e "${YELLOW}Creado por V3X${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo

printf "%-8s %-12s %-40s\n" "PUERTO" "ESTADO" "DOMINIO"
echo "---------------------------------------------------------------------"

FREE_PORT=""

PORTS=$(
ls /usr/local/hestia/data/templates/web/nginx/NODEJS*.tpl 2>/dev/null |
sed 's/.*NODEJS//' |
sed 's/.tpl//' |
sort -n
)

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

        if [ -z "$FREE_PORT" ]; then
            FREE_PORT="$P"
        fi

    fi

done

# ==========================================
# SIN PUERTOS LIBRES
# ==========================================

if [ -z "$FREE_PORT" ]; then

    echo
    echo -e "${YELLOW}No existen puertos libres.${NC}"
    echo -e "${YELLOW}Utilice primero:${NC}"
    echo
    echo "3) Crear Nueva Plantilla"
    echo

    read -p "ENTER para regresar..." TMP
    exit 1

fi

TPL="NODEJS${FREE_PORT}"

echo
echo -e "${GREEN}Siguiente puerto libre:${NC} $FREE_PORT"
echo -e "${MAGENTA}Plantilla seleccionada:${NC} $TPL"

# ==========================================
# RESUMEN
# ==========================================

echo
echo -e "${CYAN}=====================================================${NC}"
echo -e "${WHITE}CONFIGURACION AUTOMATICA${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo

echo -e "${GREEN}Usuario:${NC}    $USER"
echo -e "${GREEN}Dominio:${NC}    $DOMAIN"
echo -e "${GREEN}Puerto:${NC}     $FREE_PORT"
echo -e "${GREEN}Plantilla:${NC}  $TPL"
echo

read -p "Continuar (s/n/0): " CONF

if [ "$CONF" = "0" ]; then
    exit 0
fi

if [[ "$CONF" != "s" && "$CONF" != "S" ]]; then

    echo
    echo "Operación cancelada."
    echo

    exit 0

fi

# ==========================================
# APLICAR PROXY
# ==========================================

echo
echo -e "${BLUE}Aplicando plantilla proxy...${NC}"

/usr/local/hestia/bin/v-change-web-domain-proxy-tpl \
"$USER" \
"$DOMAIN" \
"$TPL"

if [ $? -ne 0 ]; then

    echo
    echo -e "${RED}ERROR aplicando plantilla.${NC}"
    echo

    read -p "ENTER para regresar..." TMP
    exit 1

fi

echo
echo -e "${BLUE}Reconstruyendo dominio...${NC}"

/usr/local/hestia/bin/v-rebuild-web-domain \
"$USER" \
"$DOMAIN"

if [ $? -ne 0 ]; then

    echo
    echo -e "${RED}ERROR reconstruyendo dominio.${NC}"
    echo

    read -p "ENTER para regresar..." TMP
    exit 1

fi

echo
echo -e "${BLUE}Recargando Nginx...${NC}"

systemctl reload nginx

echo
echo -e "${CYAN}=====================================================${NC}"
echo -e "${WHITE}RESULTADO FINAL${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo

/usr/local/hestia/bin/v-list-web-domain \
"$USER" \
"$DOMAIN" | grep "^PROXY:"

echo
echo -e "${GREEN}✓ Proxy NodeJS asignado correctamente.${NC}"
echo

read -p "ENTER para regresar..." TMP
