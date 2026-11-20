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
echo -e "${WHITE}LOGS DE APLICACIONES NODEJS${NC}"
echo -e "${YELLOW}Creado por V3X${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Ejecute esta opción como root (sudo).${NC}"
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

while true
do
    clear

    echo
    echo -e "${CYAN}=====================================================${NC}"
    echo -e "${WHITE}LOGS: $DOMAIN${NC}"
    echo -e "${GREEN}Usuario:${NC} $USER"
    echo -e "${GREEN}Proxy:${NC}   $CURRENT_PROXY"
    [ -n "$PORT" ] && echo -e "${GREEN}Puerto:${NC}  $PORT"
    echo -e "${CYAN}=====================================================${NC}"
    echo

    echo -e "${GREEN}1)${NC} Ver últimas líneas de todos los logs"
    echo -e "${GREEN}2)${NC} Seguir logs en tiempo real"
    echo -e "${GREEN}3)${NC} Ver log de acceso de Nginx"
    echo -e "${GREEN}4)${NC} Ver log de errores de Nginx"
    echo -e "${GREEN}5)${NC} Volver"
    echo

    read -r -p "Seleccione una opción: " LOGOPT

    APP_LOGS=""

    if [ "$LOGOPT" = "1" ] || [ "$LOGOPT" = "2" ]; then
        APP_LOGS=$(
            {
                find "/home/$USER/.pm2/logs" "/home/$USER/web/$DOMAIN" \
                    "/var/www/$DOMAIN" -type f \
                    \( -name "*.log" -o -name "*.out" -o -name "*.err" \) \
                    2>/dev/null
            } |
            sort -u |
            grep -v '/public_html/.*/' |
            head -n 20
        )
    fi

    case $LOGOPT in
    1)
        if [ -z "$APP_LOGS" ]; then
            echo
            echo -e "${YELLOW}No se encontraron logs de aplicación.${NC}"
        else
            echo
            for LOGFILE in $APP_LOGS
            do
                echo -e "${CYAN}[$LOGFILE]${NC}"
                tail -n 100 "$LOGFILE" 2>/dev/null
                echo
            done
        fi
        read -r -p "ENTER para continuar..." TMP
    ;;

    2)
        if [ -z "$APP_LOGS" ]; then
            echo
            echo -e "${YELLOW}No se encontraron logs de aplicación.${NC}"
            read -r -p "ENTER para continuar..." TMP
        else
            echo -e "${YELLOW}Mostrando logs en tiempo real. Presione Ctrl+C para volver.${NC}"
            echo
            tail -n 50 -F $APP_LOGS
        fi
    ;;

    3)
        ACCESS_LOG=""
        for CANDIDATE in \
            "/var/log/nginx/domains/$DOMAIN.log" \
            "/var/log/apache2/domains/$DOMAIN.log" \
            "/var/log/nginx/access.log"
        do
            if [ -f "$CANDIDATE" ]; then
                ACCESS_LOG="$CANDIDATE"
                break
            fi
        done

        if [ -n "$ACCESS_LOG" ]; then
            echo
            echo -e "${CYAN}[$ACCESS_LOG]${NC}"
            tail -n 200 "$ACCESS_LOG"
        else
            echo
            echo -e "${YELLOW}No se encontró el log de acceso para $DOMAIN.${NC}"
        fi
        read -r -p "ENTER para continuar..." TMP
    ;;

    4)
        ERROR_LOG=""
        for CANDIDATE in \
            "/var/log/nginx/domains/$DOMAIN.error.log" \
            "/var/log/nginx/domains/$DOMAIN.log" \
            "/var/log/apache2/domains/$DOMAIN.error.log" \
            "/var/log/nginx/error.log"
        do
            if [ -f "$CANDIDATE" ]; then
                ERROR_LOG="$CANDIDATE"
                break
            fi
        done

        if [ -n "$ERROR_LOG" ]; then
            echo
            echo -e "${CYAN}[$ERROR_LOG]${NC}"
            tail -n 200 "$ERROR_LOG"
        else
            echo
            echo -e "${YELLOW}No se encontró el log de errores para $DOMAIN.${NC}"
        fi
        read -r -p "ENTER para continuar..." TMP
    ;;

    5)
        exit 0
    ;;

    *)
        echo
        echo -e "${RED}Opción inválida.${NC}"
        sleep 1
    ;;
    esac
done
