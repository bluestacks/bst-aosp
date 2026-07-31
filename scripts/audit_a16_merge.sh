#!/bin/bash
# Read-only compatibility wrapper for the authoritative promotion audit.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/audit_android16_promotion.py" audit "$@"
