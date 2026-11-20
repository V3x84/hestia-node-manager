# Hestia Node Manager

Herramienta interactiva para administrar aplicaciones Node.js detrás de Nginx en servidores con Hestia Control Panel.

- **Versión:** 2.0.1
- **Autor:** V3X
- **Repositorio:** https://github.com/V3x84/hestia-node-manager

## Funciones

Desde el menú principal puedes:

1. Instalar Node.js LTS desde NodeSource (Debian y Ubuntu).
2. Asignar a un dominio una plantilla proxy `NODEJS` disponible.
3. Consultar qué puertos de las plantillas `NODEJS` están libres o en uso.
4. Crear la siguiente plantilla `NODEJS` copiando la plantilla existente con el número más alto.
5. Crear una aplicación Node.js básica en el directorio web de un dominio, iniciarla con PM2 y configurar el proxy.
6. Reiniciar un proceso PM2 asociado a un dominio.
7. Consultar logs de la aplicación y logs de acceso o error de Nginx.
8. Consultar las rutas de instalación y del registro.
9. Quitar el proxy Node.js de un dominio.

## Requisitos

- Servidor Linux con **Hestia Control Panel** y acceso `root` mediante `sudo`.
- Bash y utilidades estándar de Linux (`awk`, `grep`, `sed`, `find`, `tail`, entre otras).
- Nginx y las herramientas de Hestia en `/usr/local/hestia/bin`.
- Al menos una plantilla Nginx `NODEJS*.tpl` y su correspondiente `NODEJS*.stpl` en `/usr/local/hestia/data/templates/web/nginx/`.
- Para crear aplicaciones: Node.js y npm. La herramienta instala PM2 globalmente si no está disponible.
- La opción de instalación de Node.js está limitada a Debian y Ubuntu y requiere conexión a Internet.

## Instalación

Clona el repositorio en el servidor Hestia y copia el menú y sus módulos a las rutas que este espera:

```bash
git clone https://github.com/V3x84/hestia-node-manager.git
cd hestia-node-manager

sudo install -d -m 755 /usr/local/bin/hestia-node-tools
sudo install -m 755 hestia-node /usr/local/bin/hestia-node
sudo install -m 755 hestia-node-tools/*.sh /usr/local/bin/hestia-node-tools/

# Inicializa el registro solo si todavía no existe.
if [ ! -f /usr/local/bin/hestia-node-tools/registry.db ]; then
    sudo install -m 600 hestia-node-tools/registry.db /usr/local/bin/hestia-node-tools/registry.db
fi
```

Inicia el menú con:

```bash
sudo /usr/local/bin/hestia-node
```

Para actualizar una instalación, vuelve a copiar `hestia-node` y los archivos `.sh` con los comandos `install` anteriores. No reemplaces un `registry.db` existente: contiene el registro local de aplicaciones.

## Crear una aplicación

1. Inicia el menú como `root`.
2. Selecciona **1** para instalar Node.js si aún no está instalado.
3. Si no hay plantillas `NODEJS` libres, selecciona **4** para crear una.
4. Selecciona **5**, el usuario de Hestia y el dominio.
5. Confirma la ruta, el puerto y el nombre del proceso. El archivo principal es `server.js` por defecto; puedes indicar otro nombre relativo dentro del directorio web.
6. Confirma la creación. La herramienta genera los archivos iniciales si no existen, inicia la aplicación con PM2, configura la plantilla proxy y reconstruye el dominio.

La aplicación se crea en `/home/<usuario>/web/<dominio>/public_html` y escucha en `127.0.0.1` usando el puerto asignado por la plantilla. El proceso de PM2 se ejecuta bajo el usuario de Hestia seleccionado.

## Plantillas y puertos

Las plantillas `NODEJS<n>.tpl` y `NODEJS<n>.stpl` definen el puerto de proxy que utiliza Hestia. La herramienta considera libre una plantilla cuyo proxy no aparece asignado a un dominio en la configuración de usuarios de Hestia.

La opción **4** copia la plantilla con el número más alto y reemplaza en las copias la referencia `127.0.0.1:<puerto>` por el siguiente número. Debe existir al menos una plantilla `NODEJS` antes de usarla.

## Administración

- **Reiniciar:** opción **6**; elige el dominio y luego el nombre o ID del proceso mostrado por PM2.
- **Logs:** opción **7**; permite consultar las últimas líneas, seguir logs en tiempo real (Ctrl+C para volver) o revisar logs de Nginx cuando están disponibles.
- **Quitar proxy:** opción **9**; cambia la plantilla del dominio a `default` y marca el registro como `removed`. **No detiene ni elimina el proceso PM2, los archivos de la aplicación ni sus datos**; realiza esas tareas por separado si corresponden.

El registro local está en `/usr/local/bin/hestia-node-tools/registry.db`. La herramienta lo crea o actualiza al gestionar aplicaciones y aplica permisos `600`. Puede contener nombres de usuario, dominios y rutas del servidor; no publiques el registro de un servidor real. El archivo `registry.db` incluido en este repositorio solo contiene los encabezados iniciales.

## Estructura del repositorio

```text
.
├── hestia-node
└── hestia-node-tools/
    ├── assign-proxy.sh
    ├── create-app.sh
    ├── create-template.sh
    ├── install-node.sh
    ├── logs-app.sh
    ├── ports-status.sh
    ├── registry.db
    ├── remove-proxy.sh
    └── restart-app.sh
```

El menú busca los módulos en `/usr/local/bin/hestia-node-tools`; por eso no basta con copiar únicamente `hestia-node`.
