# MapRoulette in Docker

Docker images and deployment scripts for the MapRoulette monorepo
([maproulette/maproulette4](https://github.com/maproulette/maproulette4)),
plus a linked PostGIS database container.

The repo produces three containers:

| Container             | Image                             | Role                                          |
|-----------------------|-----------------------------------|-----------------------------------------------|
| `mr-postgis`          | `postgis/postgis:17-3.5`          | PostGIS database (data persisted to `./postgres-data`) |
| `maproulette-api`     | `maproulette/maproulette-api`     | Fastify backend (port 9000)                   |
| `maproulette-frontend`| `maproulette/maproulette-frontend`| nginx serving the Vite build (port 3000)      |

All three are attached to a shared `mrnet` bridge network so nginx can reach
the backend as `maproulette-api:9000`.

## Configuration

The api and frontend both read their configuration from a single `.env` file
at the repo root. Copy the template and fill it in:

```sh
cp .env.template .env
$EDITOR .env
```

At a minimum, update the fields marked `CHANGE_ME`:

* **OSM_OAUTH_CLIENT_ID / OSM_OAUTH_CLIENT_SECRET** — credentials from an
  OAuth 2.0 application you've registered on the OSM server you're pointing
  `OSM_BASE_URL` at.
* **OSM_OAUTH_CALLBACK_URL** — must match the callback URL configured on the
  OSM OAuth application. Typically `${API_PUBLIC_ORIGIN}/auth/callback`.
* **API_PUBLIC_ORIGIN** — the URL users reach in the browser (the nginx
  frontend host), not the internal container hostname.
* **DATABASE_URL** — leave as-is to use the bundled `mr-postgis` container,
  or point at an external database.

The `VITE_*` values are **inlined at build time** into the frontend bundle,
so if you change any of them you must rebuild the frontend image.

## Running deploy.sh

The `deploy.sh` script builds and deploys the containers. Because the api
and frontend now share a monorepo, they also share a `--release` and
`--git` pair.

```
Usage: ./deploy.sh [OPTION]...

  -f, --frontend       Deploy the frontend container.
  -a, --api            Deploy the API container.
  -r, --release VER    Git branch, tag, or commit id to build. Default: LATEST.
  -g, --git ORG/REPO   Source repository. Default: maproulette/maproulette4.
  --dbPort PORT        Host port for the postgis container. Default: 127.0.0.1:5432.
  --wipeDB             Stop and recreate the postgis container.
  --dbExternal         The database is external — don't manage a postgis container.
  --buildOnly          Build images but do not start containers.
  --useHostNetwork     Use host networking for all containers.
  -h, --help           Display this help and exit.
```

Values can also be set in a `conf.sh` file (copy `conf.template.sh`). Command
line arguments take precedence.

### Examples

Deploy everything at latest:

```sh
./deploy.sh -a -f
```

Deploy a specific release:

```sh
./deploy.sh -a -f -r v1.2.3
```

Build from a fork:

```sh
./deploy.sh -a -f -g myorg/maproulette4
```

Build images without starting containers:

```sh
./deploy.sh -a -f --buildOnly
```

## What happens on first boot

When the api container starts for the first time, `setupServer.sh`:

1. Generates a `secret-key` file for `@fastify/secure-session` if one does
   not already exist. The file is mounted from `api/maproulette-secret/` on
   the host so it survives container restarts.
2. Waits for `DATABASE_URL` to accept connections.
3. Ensures the `hstore` and `postgis` extensions exist.
4. Runs `drizzle-kit push` to apply the schema (idempotent).
5. Applies `backend/drizzle/0002_tile_aggregate_functions.sql`, which
   contains the tile aggregation functions that Drizzle does not manage.
6. Starts the Fastify server.

## FAQ

**I want to connect to my own database, how do I do that?**

Set `DATABASE_URL` in `.env` and pass `--dbExternal` to `deploy.sh`. The
script will skip managing the `mr-postgis` container.

**I'm running against a database on my host machine.**

Use `host.docker.internal` as the hostname in `DATABASE_URL`, or pass
`--useHostNetwork` and use `127.0.0.1`.

**I want to only deploy the frontend but it is failing.**

If the api and frontend are deployed together, nginx resolves the backend
via the `maproulette-api` container on `mrnet`. If you're deploying the
frontend on its own, edit `frontend/nginx-config` and point `upstream api`
at the host/port of your running backend.

**Where is my session secret stored?**

`api/maproulette-secret/secret-key` on the host, mounted into the container
at `/app/backend/secret-key`. Delete the file to force a fresh key on next
boot (this will invalidate existing sessions).
