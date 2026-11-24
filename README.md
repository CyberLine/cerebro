# Cerebro

Schlankes Image für [Cerebro](https://github.com/lmenezes/cerebro) 0.9.4, den Elasticsearch-Web-Admin.

`lmenezes/cerebro:0.9.4` auf Docker Hub ist seit 2021 unverändert (`openjdk:11.0.10` auf Debian Buster). Dieses Repo behält das letzte Upstream-Release und tauscht nur die Laufzeit: aktuelles Eclipse Temurin 11, per `jlink` auf die nötigen Module geschnitten, auf `gcr.io/distroless/base-nossl-debian12` ohne Shell, ohne Paketmanager und ohne OpenSSL. TLS macht die JVM selbst.

Play 2.8.7 spricht nur Java 11. Ein neueres JDK braucht einen Fork der Anwendung, nicht nur ein neues Basisimage. Die JARs selbst bleiben die von April 2021. OS-Lücken gehen mit jedem Rebuild weg, Lücken in Play, Netty, Jackson und SQLite bleiben, bis Cerebro neu gebaut wird. Der tägliche Scan zeigt sie im Security-Tab.

## Start

```bash
docker build -t cerebro .
docker run --rm -p 9000:9000 -e CEREBRO_SECRET="$(openssl rand -base64 32)" -v cerebro:/var/lib/cerebro cerebro
```

Oder `docker compose up --build`. Die UI liegt auf [http://localhost:9000](http://localhost:9000).

| Variable | Default | Bedeutung |
| --- | --- | --- |
| `CEREBRO_PORT` | `9000` | HTTP-Port im Container |
| `CEREBRO_SECRET` | öffentliches Upstream-Secret | Session- und CSRF-Secret, mindestens 32 Zeichen. In jedem geteilten Netz setzen. |
| `CEREBRO_DATA_PATH` | `/var/lib/cerebro/cerebro.db` | SQLite-Datei mit gespeicherten Hosts |
| `JAVA_TOOL_OPTIONS` | Container-Memory-Defaults | Zusätzliche JVM-Flags, die Java selbst liest |
| `AUTH_TYPE`, `BASIC_AUTH_USER`, `BASIC_AUTH_PWD`, `LDAP_*` | leer | Wie im Upstream-`application.conf` |

Eigene Hosts oder LDAP stehen weiter in `conf/application.conf`. Die Datei als ganzes ersetzen:

```bash
docker run --rm -p 9000:9000 \
  -v "$PWD/application.conf:/opt/cerebro/conf/application.conf:ro" \
  -v cerebro:/var/lib/cerebro \
  cerebro
```

Gespeicherte Cluster liegen in `/var/lib/cerebro`, nicht mehr neben den JARs.

## Lokal

```bash
make build
make smoke
make run
make scan
```

`make scan` braucht ein lokal installiertes Docker und zieht `aquasec/trivy`.

Das veröffentlichte Image aus GitHub Actions ist `linux/amd64`. Ein Build auf Apple Silicon erzeugt `linux/arm64` für denselben Dockerfile.

## GitHub

Nach dem Anlegen des leeren Remotes:

```bash
git remote add origin git@github.com:OWNER/REPO.git
git push -u origin main
```

Der Workflow `.github/workflows/image.yml` läuft bei Pull Requests, bei Push auf `main`, täglich um 04:17 UTC und manuell. Er baut, prüft ob die UI antwortet und die SQLite-Datei entsteht, scannt mit Trivy und pusht bei grünem OS-Scan nach GHCR:

- `ghcr.io/OWNER/REPO:latest`
- `ghcr.io/OWNER/REPO:0.9.4` (App-Version, wird täglich neu gebaut)
- `ghcr.io/OWNER/REPO:sha-<commit>`

Dafür muss der Actions-Token Packages schreiben dürfen (Repo-Settings, Actions, Workflow permissions: Read and write). Das Paket ist nach dem ersten Push oft privat. Library-Funde im Security-Tab brauchen GitHub Code Scanning. Ohne das bleibt der Upload ein Hinweis im Log, der OS-Scan gilt trotzdem.

Dependabot öffnet wöchentlich PRs für Actions und die Basisimage-Tags im Dockerfile (`eclipse-temurin`, `alpine`, `distroless`).

## Herkunft

Anwendung: Leonardo Menezes, MIT, [v0.9.4](https://github.com/lmenezes/cerebro/releases/tag/v0.9.4). Dieses Packaging steht ebenfalls unter MIT, siehe `LICENSE` und `NOTICE`.
