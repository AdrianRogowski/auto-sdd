#!/bin/bash
# clean-slate.sh
# Kill all processes on common dev ports and optionally restart the app.
#
# Usage:
#   ./scripts/clean-slate.sh                  # Kill dev ports only
#   ./scripts/clean-slate.sh --restart        # Kill ports + restart dev server
#   ./scripts/clean-slate.sh --ports 3000,8080  # Kill specific ports
#
# CONFIG: set DEV_PORTS and DEV_CMD in .env.local to customize
#   DEV_PORTS="3000,3001,5173"          # Ports to kill (default: common dev ports)
#   DEV_CMD="npm run dev"               # Command to restart (default: auto-detect)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(dirname "$SCRIPT_DIR")}"

if [ -f "$PROJECT_DIR/.env.local" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            [[ -n "${!key+x}" ]] && continue
            value="${BASH_REMATCH[2]}"
            if [[ "$value" =~ ^\"([^\"]*)\" ]]; then value="${BASH_REMATCH[1]}"
            elif [[ "$value" =~ ^\'([^\']*)\' ]]; then value="${BASH_REMATCH[1]}"
            else value="${value%%#*}"; value="${value%"${value##*[![:space:]]}"}"; fi
            export "$key=$value"
        fi
    done < "$PROJECT_DIR/.env.local"
fi

DEFAULT_PORTS="3000,3001,4000,5173,5174,8000,8080,8888"
DEV_PORTS="${DEV_PORTS:-$DEFAULT_PORTS}"
DEV_CMD="${DEV_CMD:-}"
RESTART=false
CUSTOM_PORTS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --restart|-r) RESTART=true; shift ;;
        --ports|-p) CUSTOM_PORTS="$2"; shift 2 ;;
        *) shift ;;
    esac
done

[ -n "$CUSTOM_PORTS" ] && DEV_PORTS="$CUSTOM_PORTS"

log() { echo "[clean-slate] $1"; }
success() { echo "[clean-slate] ✓ $1"; }

killed=0
IFS=',' read -ra PORTS <<< "$DEV_PORTS"
for port in "${PORTS[@]}"; do
    port=$(echo "$port" | tr -d '[:space:]')
    pids=$(lsof -ti:"$port" 2>/dev/null || true)
    if [ -n "$pids" ]; then
        echo "$pids" | xargs kill -9 2>/dev/null || true
        killed=$((killed + $(echo "$pids" | wc -l | tr -d '[:space:]')))
        log "Killed process(es) on port $port"
    fi
done

if [ "$killed" -gt 0 ]; then
    success "Killed $killed process(es) across ports: $DEV_PORTS"
else
    log "No processes found on ports: $DEV_PORTS"
fi

# Auto-detect dev command if not set
detect_dev_cmd() {
    cd "$PROJECT_DIR"
    if [ -f "package.json" ]; then
        if grep -q '"dev"' package.json 2>/dev/null; then
            if [ -f "pnpm-lock.yaml" ]; then echo "pnpm dev"
            elif [ -f "yarn.lock" ]; then echo "yarn dev"
            elif [ -f "bun.lockb" ]; then echo "bun dev"
            else echo "npm run dev"
            fi
            return
        fi
    fi
    if [ -f "Procfile" ]; then echo "$(head -1 Procfile | cut -d: -f2- | xargs)"; return; fi
    if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then echo "docker compose up"; return; fi
    if [ -f "manage.py" ]; then echo "python manage.py runserver"; return; fi
    if [ -f "main.go" ]; then echo "go run ."; return; fi
    echo ""
}

if [ "$RESTART" = true ]; then
    if [ -z "$DEV_CMD" ]; then
        DEV_CMD=$(detect_dev_cmd)
    fi
    if [ -n "$DEV_CMD" ]; then
        sleep 1
        log "Starting: $DEV_CMD"
        cd "$PROJECT_DIR"
        exec $DEV_CMD
    else
        log "No dev command found. Set DEV_CMD in .env.local or pass it manually."
    fi
fi
