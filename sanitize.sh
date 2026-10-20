#!/usr/bin/env bash
# Replaces example secrets/passwords/tokens with safe placeholders
# so Vault Radar doesn't block pushes.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
count=0

sanitize() {
    local file="$1"
    local before after
    before="$(cat "$file")"

    after="$before"

    # JWT fragments: eyJhbGciOiJSUz... or eyJhbGciOiJSUzI1NiIsIn...
    after="$(echo "$after" | sed -E 's/eyJ[A-Za-z0-9_-]{5,}(\.\.\.|[[:space:]]|\[)/EXAMPLE_JWT_TOKEN\1/g')"

    # Basic auth base64 credentials
    after="$(echo "$after" | sed -E 's/(Basic )[A-Za-z0-9+/]{20,}={0,2}/\1EXAMPLE_BASE64_CREDENTIALS/g')"

    # bearer <token> in Authorization headers
    after="$(echo "$after" | sed -E 's/(bearer|Bearer) eyJ[A-Za-z0-9_.-]+/\1 EXAMPLE_JWT_TOKEN/g')"

    # String token = "eyJ...";
    after="$(echo "$after" | sed -E 's/"eyJ[A-Za-z0-9_.-]+\.\.\.?"/"EXAMPLE_JWT_TOKEN"/g')"

    # Example passwords in env vars: KC_DB_PASSWORD='...' KCRAW_DB_PASSWORD='...'
    after="$(echo "$after" | sed -E "s/(KC_DB_PASSWORD|KCRAW_DB_PASSWORD|KC_BOOTSTRAP_ADMIN_PASSWORD)='[^']+'/\1='EXAMPLE_PASSWORD'/g")"
    after="$(echo "$after" | sed -E "s/(KC_DB_PASSWORD|KCRAW_DB_PASSWORD|KC_BOOTSTRAP_ADMIN_PASSWORD)=_<[^>]+>_/\1=EXAMPLE_PASSWORD/g")"

    # CLI --*-password=value patterns (keystore, db, service, etc)
    after="$(echo "$after" | sed -E 's/(config-keystore-password|https-key-store-password|service-password|db-password|db-mtls-key-store-password)="[^"]+"/\1=EXAMPLE_PASSWORD/g')"
    after="$(echo "$after" | sed -E "s/(config-keystore-password|https-key-store-password|service-password|db-password|db-mtls-key-store-password)='[^']+'/\1=EXAMPLE_PASSWORD/g")"
    after="$(echo "$after" | sed -E 's/(config-keystore-password|https-key-store-password|service-password|db-password|db-mtls-key-store-password)=([^ '"'"'"]+)/\1=EXAMPLE_PASSWORD/g')"

    # client_secret=XXXXX or client_secret=ZZZZZZ or client_secret=UUID etc
    after="$(echo "$after" | sed -E 's/(client_secret=)[A-Za-z0-9_-]{3,}/\1EXAMPLE_SECRET/g')"

    # -d "client_secret=the client secret"
    after="$(echo "$after" | sed -E 's/(client_secret=)the client secret/\1EXAMPLE_SECRET/g')"

    # password=YYYYYY
    after="$(echo "$after" | sed -E 's/(password=)[A-Z]{3,}/\1EXAMPLE_PASSWORD/g')"

    # Result comment with raw password
    after="$(echo "$after" | sed -E "s/Result: the password is used as-is: .+/Result: the password is used as-is: EXAMPLE_PASSWORD/")"

    if [[ "$before" != "$after" ]]; then
        echo "$after" > "$file"
        echo "  sanitized: $file"
        count=$((count + 1))
    fi
}

echo "Scanning keycloak-out for secret-like patterns..."

for f in "$DIR"/assemblies/*.adoc "$DIR"/modules/*.adoc; do
    [[ -f "$f" ]] || continue
    sanitize "$f"
done

echo "Done. $count file(s) sanitized."
