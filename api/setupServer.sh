#!/bin/bash

set -eu

# Generate the @fastify/secure-session key file on first boot. The file is
# expected to live at $PWD/secret-key (see backend/src/plugins/auth.ts) and
# should persist across container restarts via a mounted volume.
if [ ! -s ./secret-key ]; then
    echo "Generating secret-key for @fastify/secure-session"
    node -e "require('fs').writeFileSync('secret-key', require('crypto').randomBytes(32))"
fi

# Wait for the database to be reachable before attempting schema bootstrap.
if [ -n "${DATABASE_URL:-}" ]; then
    echo "Waiting for database to accept connections..."
    for i in $(seq 1 60); do
        if psql "$DATABASE_URL" -c 'SELECT 1' >/dev/null 2>&1; then
            break
        fi
        sleep 2
    done
fi

# Ensure required extensions exist. These are not managed by Drizzle.
if [ -n "${DATABASE_URL:-}" ]; then
    echo "Ensuring hstore and postgis extensions exist"
    psql "$DATABASE_URL" \
        -c "CREATE EXTENSION IF NOT EXISTS hstore; CREATE EXTENSION IF NOT EXISTS postgis;"
fi

# Push the Drizzle schema. Idempotent — safe to run on every boot.
echo "Pushing Drizzle schema"
npx --yes drizzle-kit push --config=drizzle.config.ts

# Apply the tile aggregation functions (plain SQL, not managed by Drizzle).
if [ -f drizzle/0002_tile_aggregate_functions.sql ] && [ -n "${DATABASE_URL:-}" ]; then
    echo "Applying tile aggregation functions"
    psql "$DATABASE_URL" < drizzle/0002_tile_aggregate_functions.sql || true
fi

echo "Starting MapRoulette backend"
exec node dist/index.js
