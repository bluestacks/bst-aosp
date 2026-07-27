#!/bin/bash
# Precise: only real g1_build_stable.sh process, not waiters whose argv mention it.
set +u
pgrep -u markxu -af 'scripts/g1_build_stable.sh' 2>/dev/null | grep -v 'pgrep' | grep -v 'while ' | grep -v 'bash -c' | grep -E 'bash .*/g1_build_stable\.sh' || true
