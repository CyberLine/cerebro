# Security

Das Image wird bei jedem Push auf `main`, in jedem Pull Request und täglich um 04:17 UTC neu gebaut.

- Trivy bricht den Lauf ab, wenn das Basisimage (OS-Pakete) eine ungefixte High- oder Critical-Lücke hat. Dann wird nichts nach GHCR gepusht.
- Funde in den mitgelieferten Cerebro-JARs (Play, Netty, Jackson, SQLite, …) landen als SARIF im Security-Tab und im Action-Log. Sie lassen den Lauf bewusst grün, weil die JARs aus dem unveränderten Upstream-Release 0.9.4 stammen und sonst jeder Lauf rot wäre.
- Der Secret-Scanner ist aus. Das Upstream-`application.conf` enthält ein öffentliches Default-Secret. Für alles außer lokalem Ausprobieren `CEREBRO_SECRET` setzen.

Zum Melden einer Lücke in diesem Packaging ein privates GitHub Security Advisory auf diesem Repo öffnen.
