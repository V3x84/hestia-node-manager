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
echo -e "${WHITE}CREAR APLICACIÓN NODEJS${NC}"
echo -e "${YELLOW}Creado por V3X${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Ejecute esta opción como root (sudo).${NC}"
    exit 1
fi

if ! command -v node >/dev/null 2>&1; then
    echo -e "${RED}Node.js no está instalado.${NC}"
    echo "Use primero la opción 1 del menú principal."
    exit 1
fi

if ! command -v pm2 >/dev/null 2>&1; then
    echo -e "${YELLOW}PM2 no está instalado. Instalando PM2...${NC}"
    npm install -g pm2
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
    exit 1
fi

CURRENT_PROXY=$(
    /usr/local/hestia/bin/v-list-web-domain "$USER" "$DOMAIN" |
    grep "^PROXY:" |
    awk '{print $2}'
)

if [[ "$CURRENT_PROXY" =~ NODEJS ]]; then
    echo
    echo -e "${RED}El dominio ya tiene una plantilla NodeJS asignada.${NC}"
    echo -e "${GREEN}Proxy actual:${NC} $CURRENT_PROXY"
    exit 0
fi

# ==========================================
# PUERTO LIBRE
# ==========================================

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
        head -n 1 |
        sed -n "s/.*DOMAIN='\([^']*\)'.*/\1/p"
    )

    if [ -z "$DOMAIN_FOUND" ] && [ -z "$FREE_PORT" ]; then
        FREE_PORT="$P"
    fi
done

if [ -z "$FREE_PORT" ]; then
    echo
    echo -e "${RED}No existen puertos NodeJS libres.${NC}"
    echo "Use la opción 4 para crear una plantilla nueva."
    exit 1
fi

TPL="NODEJS${FREE_PORT}"
WEB_DIR="/home/$USER/web/$DOMAIN/public_html"
ENTRY_FILE="server.js"
PROCESS_NAME=$(echo "$DOMAIN" | sed 's/[^a-zA-Z0-9_-]/-/g')

echo
echo -e "${CYAN}=====================================================${NC}"
echo -e "${WHITE}CONFIGURACIÓN DE LA APLICACIÓN${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo
echo -e "${GREEN}Usuario:${NC}  $USER"
echo -e "${GREEN}Dominio:${NC}  $DOMAIN"
echo -e "${GREEN}Puerto:${NC}   $FREE_PORT"
echo -e "${GREEN}Directorio:${NC} $WEB_DIR"
echo -e "${GREEN}Proceso PM2:${NC} $PROCESS_NAME"
echo

read -r -p "Nombre del archivo principal [server.js]: " INPUT_ENTRY
if [ -n "$INPUT_ENTRY" ]; then
    ENTRY_FILE="$INPUT_ENTRY"
fi

if [[ "$ENTRY_FILE" = /* || "$ENTRY_FILE" = *".."* ]]; then
    echo
    echo -e "${RED}Ingrese únicamente un nombre de archivo relativo al directorio web.${NC}"
    exit 1
fi

echo
read -r -p "Confirmar creación [s/N]: " CONF
if [[ "$CONF" != "s" && "$CONF" != "S" ]]; then
    exit 0
fi

# ==========================================
# CREAR APLICACIÓN BASE
# ==========================================

mkdir -p "$WEB_DIR"
chown "$USER":"$USER" "$WEB_DIR"

if [ ! -f "$WEB_DIR/$ENTRY_FILE" ]; then
    cat > "$WEB_DIR/$ENTRY_FILE" <<EOF
const http = require('http');

const port = Number(process.env.PORT || $FREE_PORT);

const server = http.createServer((request, response) => {
    response.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
    response.end('Node.js funcionando correctamente en $DOMAIN');
});

server.listen(port, '127.0.0.1', () => {
    console.log('Aplicación escuchando en http://127.0.0.1:' + port);
});
EOF

    chown "$USER":"$USER" "$WEB_DIR/$ENTRY_FILE"
fi

if [ ! -f "$WEB_DIR/package.json" ]; then
    cat > "$WEB_DIR/package.json" <<EOF
{
  "name": "$PROCESS_NAME",
  "private": true,
  "scripts": {
    "start": "node $ENTRY_FILE"
  }
}
EOF

    chown "$USER":"$USER" "$WEB_DIR/package.json"
fi

cat > "$WEB_DIR/ecosystem.config.cjs" <<EOF
module.exports = {
  apps: [{
    name: '$PROCESS_NAME',
    script: '$ENTRY_FILE',
    cwd: '$WEB_DIR',
    instances: 1,
    exec_mode: 'fork',
    env: {
      NODE_ENV: 'production',
      PORT: '$FREE_PORT'
    }
  }]
};
EOF

chown "$USER":"$USER" "$WEB_DIR/ecosystem.config.cjs"

# ==========================================
# CONFIGURAR PM2
# ==========================================

echo
echo -e "${YELLOW}Iniciando aplicación con PM2...${NC}"

if runuser -u "$USER" -- pm2 start "$WEB_DIR/ecosystem.config.cjs" --update-env; then
    runuser -u "$USER" -- pm2 save
else
    echo
    echo -e "${RED}No se pudo iniciar la aplicación con PM2.${NC}"
    exit 1
fi

# ==========================================
# CONFIGURAR PROXY
# ==========================================

echo
echo -e "${YELLOW}Configurando proxy NodeJS $TPL...${NC}"

/usr/local/hestia/bin/v-change-web-domain-proxy-tpl \
    "$USER" \
    "$DOMAIN" \
    "$TPL"

if [ $? -ne 0 ]; then
    echo
    echo -e "${RED}Error aplicando la plantilla $TPL.${NC}"
    exit 1
fi

/usr/local/hestia/bin/v-rebuild-web-domain "$USER" "$DOMAIN"
if [ $? -ne 0 ]; then
    echo
    echo -e "${RED}Error reconstruyendo el dominio.${NC}"
    exit 1
fi

systemctl reload nginx

REGISTRY="/usr/local/bin/hestia-node-tools/registry.db"
touch "$REGISTRY"
REGISTRY_TMP=$(mktemp)
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

awk -F '\t' -v DOMAIN="$DOMAIN" '$2 != DOMAIN' "$REGISTRY" > "$REGISTRY_TMP"
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\tactive\t%s\t%s\n' \
    "$USER" "$DOMAIN" "$FREE_PORT" "$TPL" "$PROCESS_NAME" \
    "$WEB_DIR" "$ENTRY_FILE" "$NOW" "$NOW" >> "$REGISTRY_TMP"
mv "$REGISTRY_TMP" "$REGISTRY"
chmod 600 "$REGISTRY"

echo
echo -e "${CYAN}=====================================================${NC}"
echo -e "${WHITE}APLICACIÓN CREADA${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo
echo -e "${GREEN}Dominio:${NC} $DOMAIN"
echo -e "${GREEN}Puerto:${NC}  $FREE_PORT"
echo -e "${GREEN}PM2:${NC}     $PROCESS_NAME"
echo -e "${GREEN}Ruta:${NC}    $WEB_DIR"
echo

if runuser -u "$USER" -- pm2 list | grep -q "$PROCESS_NAME"; then
    echo -e "${GREEN}La aplicación está activa.${NC}"
else
    echo -e "${YELLOW}La aplicación fue creada, pero revise el estado en PM2.${NC}"
fi

read -r -p "ENTER para regresar..." TMP
