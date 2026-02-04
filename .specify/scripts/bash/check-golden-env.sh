#!/usr/bin/env bash
# Check that the current environment matches the Chimera golden setup
# (Python 3.12, venv, PostgreSQL 16, optional Docker)
#
# Usage: ./check-golden-env.sh [--skip-db]
#   --skip-db   Do not check PostgreSQL connectivity (e.g. when DB not running)

set -e

SKIP_DB=false
for arg in "$@"; do
    case "$arg" in
        --skip-db) SKIP_DB=true ;;
        --help|-h)
            echo "Usage: $0 [--skip-db]"
            echo "  --skip-db   Skip PostgreSQL connectivity check"
            exit 0
            ;;
    esac
done

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/common.sh" 2>/dev/null || true

if [[ -z "${REPO_ROOT}" ]]; then
    REPO_ROOT="$(get_repo_root 2>/dev/null)" || REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

cd "$REPO_ROOT"
FAIL=0

# --- Python version (3.12.x)
if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
    echo "✗ Python not found. Golden env requires Python 3.12."
    FAIL=1
else
    PY=$(python3 --version 2>/dev/null || python --version 2>/dev/null)
    if [[ "$PY" =~ Python\ 3\.12 ]]; then
        echo "✓ Python: $PY"
    else
        echo "✗ Python must be 3.12.x (got: $PY). Set pyenv or .python-version."
        FAIL=1
    fi
fi

# --- Virtual environment
if [[ -z "${VIRTUAL_ENV}" ]]; then
    echo "✗ No active virtual environment. Activate with: source .venv/bin/activate"
    FAIL=1
else
    echo "✓ Virtual env: $VIRTUAL_ENV"
fi

# --- PostgreSQL driver (psycopg or psycopg2)
if python3 -c "import psycopg" 2>/dev/null || python3 -c "import psycopg2" 2>/dev/null; then
    echo "✓ PostgreSQL driver installed"
else
    echo "✗ Install PostgreSQL driver: pip install -r requirements.txt"
    FAIL=1
fi

# --- Optional: .env and DATABASE_URL
if [[ -f "$REPO_ROOT/.env" ]]; then
    echo "✓ .env present"
    # shellcheck source=/dev/null
    set -a
    source "$REPO_ROOT/.env" 2>/dev/null || true
    set +a
fi

if [[ -n "${DATABASE_URL:-}" ]]; then
    if $SKIP_DB; then
        echo "○ DATABASE_URL set; DB check skipped (--skip-db)"
    else
        if python3 -c "
import os
import sys
url = os.environ.get('DATABASE_URL')
if not url or not url.startswith('postgresql'):
    sys.exit(2)
try:
    import psycopg
    conn = psycopg.connect(url)
    conn.close()
except Exception:
    try:
        import psycopg2
        conn = psycopg2.connect(url)
        conn.close()
    except Exception as e:
        print(e, file=sys.stderr)
        sys.exit(1)
" 2>/dev/null; then
            echo "✓ PostgreSQL reachable (DATABASE_URL)"
        else
            EXIT=$?
            if [[ $EXIT -eq 2 ]]; then
                echo "○ DATABASE_URL not set or not postgresql; skipping DB check"
            else
                echo "✗ Cannot connect to PostgreSQL. Is the server running? (use --skip-db to skip)"
                FAIL=1
            fi
        fi
    fi
else
    echo "○ DATABASE_URL not set; copy .env.example to .env to enable DB check"
fi

# --- Docker (optional)
if command -v docker >/dev/null 2>&1; then
    echo "✓ Docker available (optional, for Postgres)"
else
    echo "○ Docker not found (optional for running Postgres via container)"
fi

if [[ $FAIL -eq 1 ]]; then
    echo ""
    echo "See docs/setup/golden-environment.md for setup instructions."
    exit 1
fi
echo ""
echo "Golden environment check passed."
exit 0
