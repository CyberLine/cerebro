# Security

The image is rebuilt on every push to `main`, on every pull request, and daily at 04:17 UTC. The Docker build runs `sbt test` and `sbt stage`.

- Trivy fails the run if OS packages or application JARs have an unfixed High or Critical vulnerability. Nothing is pushed to GHCR in that case.
- Jackson and Guava are pinned to fixed versions via `dependencyOverrides`, because Play 3.0.12 still pulls older ones.
- The secret scanner is off. The bundled `application.conf` ships a public default secret. Set `CEREBRO_SECRET` (at least 32 characters) for anything beyond local try-outs.

To report a vulnerability in this packaging, open a private GitHub Security Advisory on this repository.
