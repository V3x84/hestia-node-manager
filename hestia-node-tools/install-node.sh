#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

clear

echo
echo -e "${CYAN}=====================================================${NC}"
echo -e "${WHITE}INSTALACIÓN DE NODE.JS${NC}"
echo -e "${YELLOW}Creado por V3X${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Ejecute esta opción como root (sudo).${NC}"
    exit 1
fi

if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo -e "${RED}No se pudo detectar el sistema operativo.${NC}"
    exit 1
fi

if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
    echo -e "${RED}Instalación compatible únicamente con Debian y Ubuntu.${NC}"
    exit 1
fi

echo "Actualizando paquetes..."
apt-get update

echo "Instalando dependencias..."
apt-get install -y ca-certificates curl gnupg

echo "Configurando el repositorio NodeSource..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -

echo "Instalando Node.js..."
apt-get install -y nodejs

echo
echo -e "${GREEN}Node.js instalado correctamente.${NC}"
echo "Versión de Node: $(node -v)"
echo "Versión de npm:  $(npm -v)"
