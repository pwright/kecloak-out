#!/usr/bin/env bash
# Split keycloak guides into assemblies/modules and sanitize secrets.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEBEN="$DIR/../sk-vale/leben.py"
GUIDES="$DIR/../keycloak-1/docs/guides/target/generated-guides"
VALE_INI="$DIR/../sk-vale/.vale.ini"

if [[ ! -f "$LEBEN" ]]; then
    echo "ERROR: leben.py not found at $LEBEN"
    exit 1
fi
if [[ ! -d "$GUIDES" ]]; then
    echo "ERROR: keycloak guides not found at $GUIDES"
    exit 1
fi

echo "Cleaning previous output..."
rm -rf "$DIR/assemblies" "$DIR/modules"
mkdir -p "$DIR/assemblies" "$DIR/modules"

echo "Splitting keycloak guides with leben.py..."
cd "$DIR"
python3 -I "$LEBEN" "$GUIDES/**/*.adoc" --report-metrics metrics.json 2>&1

echo ""
echo "Sanitizing secrets..."
bash "$DIR/sanitize.sh"

echo ""
echo "Running Vale..."
cd "$DIR"
vale_exit=0
vale --config "$VALE_INI" --output JSON assemblies/ modules/ > "$DIR/vale-report.json" 2>&1 || vale_exit=$?

echo ""
assemblies=$(find "$DIR/assemblies" -name "*.adoc" | wc -l)
modules=$(find "$DIR/modules" -name "*.adoc" | wc -l)
echo "Summary: $assemblies assemblies, $modules modules"

if [[ $vale_exit -eq 0 ]]; then
    echo "Vale: all checks passed."
else
    echo "Vale: finished with warnings/errors (exit code $vale_exit)."
fi

exit $vale_exit
