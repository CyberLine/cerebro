# Cerebro

Slim image for [Cerebro](https://github.com/lmenezes/cerebro), the Elasticsearch web admin.

`lmenezes/cerebro:0.9.4` on Docker Hub has been unchanged since 2021. This repo rebuilds the app from source: Play 3.0.12 / Pekko, Scala 2.13.18, Java 21, current sqlite-jdbc. The runtime is a `jlink`-trimmed Temurin 21 JRE on `gcr.io/distroless/base-nossl-debian13` with no shell, no package manager, and no OpenSSL. The JVM handles TLS itself.

App version: **0.11.0**. The AngularJS UI still comes from upstream 0.9.4.

## Run

```bash
docker build -t cerebro .
docker run --rm -p 9000:9000 -e CEREBRO_SECRET="$(openssl rand -base64 32)" -v cerebro:/var/lib/cerebro cerebro
```

Or `docker compose up --build`. The UI is at [http://localhost:9000](http://localhost:9000).

| Variable | Default | Meaning |
| --- | --- | --- |
| `CEREBRO_PORT` | `9000` | HTTP port inside the container |
| `CEREBRO_SECRET` | public default secret | Session and CSRF secret, at least 32 characters |
| `CEREBRO_DATA_PATH` | `/var/lib/cerebro/cerebro.db` | SQLite file for saved hosts |
| `JAVA_TOOL_OPTIONS` | container memory defaults | Extra JVM flags |
| `AUTH_TYPE`, `BASIC_AUTH_USER`, `BASIC_AUTH_PWD`, `LDAP_*` | empty | Same as in `conf/application.conf` |

Custom hosts or LDAP live in `conf/application.conf`. Replace the whole file:

```bash
docker run --rm -p 9000:9000 \
  -v "$PWD/application.conf:/opt/cerebro/conf/application.conf:ro" \
  -v cerebro:/var/lib/cerebro \
  cerebro
```

Saved clusters are stored under `/var/lib/cerebro`.

## Local

```bash
make build
make smoke
make run
make scan
```

`make scan` needs Docker and pulls `aquasec/trivy`. The image build compiles with sbt and runs the specs.

## Attribution

Application: Leonardo Menezes, MIT, based on [v0.9.4](https://github.com/lmenezes/cerebro/releases/tag/v0.9.4). This packaging and rebuild are also MIT; see `LICENSE` and `NOTICE`.
