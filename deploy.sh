#!/usr/bin/env bash
#
# EverGreen [DIS] - despliegue local de la aplicacion generada con Telosys
#
# Uso:  ./deploy.sh <comando>
#
#   check      Verifica las herramientas necesarias
#   generate   Genera los tres proyectos desde el modelo (Telosys)
#   db         Levanta PostgreSQL con el DDL generado
#   api        Compila y ejecuta la API REST        (bloqueante, :8000)
#   web        Instala dependencias y ejecuta la SPA (bloqueante, :4200)
#   verify     Comprueba que base, API y SPA responden
#   clean      Borra todo el codigo generado (no toca modelo ni plantillas)
#   reset-db   Recrea la base desde cero, perdiendo los datos
#   all        check + clean + generate + db  (luego correr 'api' y 'web')
#
# 'api' y 'web' quedan en primer plano: hay que ejecutarlos en terminales aparte.
#
# Rutas de herramientas: se pueden sobreescribir por variable de entorno, ej.
#   TELOSYS_CLI=/opt/telosys/telosys ./deploy.sh generate
#
set -euo pipefail

# El CLI de Telosys resuelve las rutas relativas de telosys-tools.cfg contra el
# directorio actual, por eso todo se ejecuta desde la raiz del repositorio.
cd "$(dirname "${BASH_SOURCE[0]}")"
RAIZ="$(pwd)"

TELOSYS_CLI="${TELOSYS_CLI:-$HOME/tools/telosys-cli/telosys}"
MVN="${MVN:-mvn}"
[ -x "$HOME/tools/maven/bin/mvn" ] && MVN="${MVN_OVERRIDE:-$HOME/tools/maven/bin/mvn}"
if [ -z "${JAVA_HOME:-}" ] && [ -d "$HOME/tools/jdk17/Contents/Home" ]; then
  export JAVA_HOME="$HOME/tools/jdk17/Contents/Home"
fi
export PATH="${JAVA_HOME:+$JAVA_HOME/bin:}/opt/homebrew/bin:$PATH"

# Podman o Docker, el que este disponible
if command -v podman >/dev/null 2>&1; then
  COMPOSE="podman compose"
elif command -v docker >/dev/null 2>&1; then
  COMPOSE="docker compose"
else
  COMPOSE=""
fi

info() { printf '\n\033[1m== %s\033[0m\n' "$1"; }
ok()   { printf '   OK   %s\n' "$1"; }
err()  { printf '   FALLA %s\n' "$1" >&2; }

cmd_check() {
  info "Herramientas"
  local falta=0
  if [ -x "$TELOSYS_CLI" ]; then ok "Telosys CLI: $TELOSYS_CLI"
  else err "Telosys CLI no encontrado en $TELOSYS_CLI (definir TELOSYS_CLI)"; falta=1; fi
  if command -v java >/dev/null 2>&1; then ok "Java: $(java -version 2>&1 | head -1)"
  else err "Java no encontrado (se requiere JDK 17)"; falta=1; fi
  if command -v "$MVN" >/dev/null 2>&1 || [ -x "$MVN" ]; then ok "Maven: $("$MVN" -version 2>/dev/null | head -1)"
  else err "Maven no encontrado"; falta=1; fi
  if command -v node >/dev/null 2>&1; then ok "Node: $(node --version)"
  else err "Node no encontrado (se requiere 20.19+, 22.12+ o 24+)"; falta=1; fi
  if [ -n "$COMPOSE" ]; then ok "Contenedores: $COMPOSE"
  else err "No se encontro podman ni docker"; falta=1; fi
  [ "$falta" -eq 0 ] || { err "Faltan herramientas, ver README.md"; exit 1; }
}

# Alimenta el CLI interactivo de Telosys por entrada estandar
telosys() { printf '%s\nexit\n' "$1" | "$TELOSYS_CLI"; }

cmd_generate() {
  info "Generando desde el modelo (22 entidades)"
  # Nota: el frontend requiere '-r' para copiar los recursos estaticos del bundle.
  # Nota: NO se usa 'ib': los bundles del repositorio tienen plantillas adaptadas.
  local salida
  salida=$(telosys 'h evergreen-dis-modelo
m dis_dominio
cm
b database-sql-scripts
gen * * -y
b model-doc
gen * * -y
b java-jpa-entities
gen * * -y
h evergreen-dis-api
m dis_dominio
cm
b java-rest-springboot-jpa-basic
gen * * -y
h evergreen-dis-web
m dis_dominio
cm
b front-angular
gen * * -r -y' 2>&1)

  echo "$salida" | grep -E "Model OK|Model ERROR|file\(s\) generated|generation error" | sed 's/^/   /'

  local errores
  errores=$(echo "$salida" | grep -oE '[0-9]+ generation error' | grep -cv '^0 ' || true)
  if [ "$errores" -ne 0 ]; then err "Hubo errores de generacion"; exit 1; fi
  echo "$salida" | grep -q "Model ERROR" && { err "El modelo no valida"; exit 1; }
  ok "Generacion sin errores"
}

cmd_db() {
  info "PostgreSQL"
  if [ "$COMPOSE" = "podman compose" ]; then
    podman machine start 2>/dev/null || true
  fi
  [ -f evergreen-dis-modelo/sql/postgresql-create-tables.sql ] || {
    err "Falta el DDL generado: ejecutar './deploy.sh generate' primero"; exit 1; }
  ( cd evergreen-dis-modelo && $COMPOSE up -d )
  printf '   esperando a que la base este lista'
  for _ in $(seq 1 30); do
    if ( cd evergreen-dis-modelo && $COMPOSE exec -T db pg_isready -U evergreen -d evergreen_dis >/dev/null 2>&1 ); then
      printf '\n'; ok "Base lista en localhost:5432"; return 0
    fi
    printf '.'; sleep 2
  done
  printf '\n'; err "La base no respondio a tiempo"; exit 1
}

cmd_api() {
  info "API REST en http://localhost:8000  (Ctrl+C para detener)"
  ( cd evergreen-dis-api && "$MVN" -B spring-boot:run )
}

cmd_web() {
  info "SPA en http://localhost:4200  (Ctrl+C para detener)"
  ( cd evergreen-dis-web && npm install && npm start )
}

cmd_verify() {
  info "Verificacion"
  local fallas=0
  if ( cd evergreen-dis-modelo && $COMPOSE exec -T db psql -U evergreen -d evergreen_dis -tAc \
       "select count(*) from information_schema.tables where table_schema='public'" 2>/dev/null | grep -q '^22$' ); then
    ok "Base: 22 tablas"
  else err "Base: no se encontraron las 22 tablas"; fallas=1; fi

  if curl -sf --max-time 15 http://localhost:8000/api/v1/cliente >/dev/null 2>&1; then
    ok "API responde en :8000"
  else err "API no responde en :8000"; fallas=1; fi

  if curl -sf --max-time 15 http://localhost:8000/swagger-ui/index.html >/dev/null 2>&1; then
    ok "Swagger UI disponible"
  else err "Swagger UI no responde"; fallas=1; fi

  if curl -sf --max-time 15 http://localhost:4200/ >/dev/null 2>&1; then
    ok "SPA responde en :4200"
  else err "SPA no responde en :4200"; fallas=1; fi

  [ "$fallas" -eq 0 ] && ok "Todo en orden" || err "Revisar los puntos anteriores"
}

cmd_clean() {
  info "Borrando codigo generado"
  # Se conservan: TelosysTools/ (modelo, plantillas, configuracion),
  # db/ y docker-compose.yml (escritos a mano).
  rm -rf evergreen-dis-modelo/sql evergreen-dis-modelo/model-doc \
         evergreen-dis-modelo/src evergreen-dis-modelo/pom.xml
  find evergreen-dis-api -mindepth 1 -maxdepth 1 ! -name TelosysTools -exec rm -rf {} +
  find evergreen-dis-web -mindepth 1 -maxdepth 1 ! -name TelosysTools -exec rm -rf {} +
  ok "Quedan solo modelo, plantillas y configuracion"
}

cmd_reset_db() {
  info "Recreando la base (se pierden los datos)"
  ( cd evergreen-dis-modelo && $COMPOSE down -v )
  cmd_db
}

case "${1:-}" in
  check)     cmd_check ;;
  generate)  cmd_generate ;;
  db)        cmd_db ;;
  api)       cmd_api ;;
  web)       cmd_web ;;
  verify)    cmd_verify ;;
  clean)     cmd_clean ;;
  reset-db)  cmd_reset_db ;;
  all)
    cmd_check; cmd_clean; cmd_generate; cmd_db
    info "Siguiente paso"
    echo "   Ejecutar en dos terminales aparte, desde $RAIZ :"
    echo "     ./deploy.sh api"
    echo "     ./deploy.sh web"
    echo "   Y luego:  ./deploy.sh verify"
    ;;
  *)
    sed -n '2,26p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 1 ;;
esac
