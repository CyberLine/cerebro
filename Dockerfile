# syntax=docker/dockerfile:1

# Cerebro 0.9.4 is Play 2.8.7, which only runs on Java 11.
# The published app jars stay pinned; the runtime below is rebuilt from current bases.
# Alpine JRE images for Java 11 are amd64-only and sqlite-jdbc 3.34 has no musl arm64 lib,
# so the runtime is a stripped glibc jlink JRE on distroless (no shell, no package manager).

ARG ALPINE_IMAGE=alpine:3.24
ARG TEMURIN_IMAGE=eclipse-temurin:11.0.33_10-jdk-jammy
ARG DISTROLESS_IMAGE=gcr.io/distroless/base-debian12:nonroot

FROM ${ALPINE_IMAGE} AS dist

ARG CEREBRO_VERSION=0.9.4
ARG CEREBRO_SHA256=c17f4abaaa7eb7d32c71ba17effc9995f3a96ee7cf10f4bfc929537df6430710

COPY docker/apply-config.sh docker/logback.xml /tmp/

RUN apk add --no-cache ca-certificates curl tar \
    && curl -fsSL -o /tmp/cerebro.tgz \
        "https://github.com/lmenezes/cerebro/releases/download/v${CEREBRO_VERSION}/cerebro-${CEREBRO_VERSION}.tgz" \
    && echo "${CEREBRO_SHA256}  /tmp/cerebro.tgz" | sha256sum -c - \
    && mkdir -p /opt/cerebro /var/lib/cerebro \
    && tar -xzf /tmp/cerebro.tgz --strip-components=1 -C /opt/cerebro \
    && rm -rf /opt/cerebro/bin /tmp/cerebro.tgz \
    && ln -s "cerebro.cerebro-${CEREBRO_VERSION}-launcher.jar" /opt/cerebro/lib/launcher.jar \
    && sh /tmp/apply-config.sh \
    && rm -f /tmp/apply-config.sh /tmp/logback.xml \
    && touch /var/lib/cerebro/.keep \
    && chown 65532:65532 /var/lib/cerebro /var/lib/cerebro/.keep \
    && chmod 0750 /var/lib/cerebro \
    && chown 65532:65532 /opt/cerebro \
    && chmod 0755 /opt/cerebro \
    && chmod -R a-w /opt/cerebro/lib /opt/cerebro/conf

FROM ${TEMURIN_IMAGE} AS jre

# java.desktop is required: Guice's cglib calls java.beans, which is not a separate module on Java 11.
RUN jlink \
        --add-modules java.base,java.desktop,java.instrument,java.logging,java.management,java.naming,java.net.http,java.prefs,java.rmi,java.security.jgss,java.security.sasl,java.sql,java.xml,java.xml.crypto,jdk.charsets,jdk.crypto.ec,jdk.management,jdk.naming.dns,jdk.unsupported,jdk.zipfs \
        --strip-debug \
        --no-man-pages \
        --no-header-files \
        --compress=2 \
        --output /javaruntime

FROM ${DISTROLESS_IMAGE}

ARG CEREBRO_VERSION=0.9.4
ARG IMAGE_SOURCE=""
ARG GIT_SHA=""

LABEL org.opencontainers.image.title="cerebro" \
      org.opencontainers.image.description="Cerebro 0.9.4 on a stripped current Java 11 runtime" \
      org.opencontainers.image.url="https://github.com/lmenezes/cerebro" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.version="${CEREBRO_VERSION}" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.licenses="MIT"

COPY --from=jre /javaruntime /opt/java
COPY --from=dist /opt/cerebro /opt/cerebro
COPY --chown=65532:65532 --from=dist /var/lib/cerebro /var/lib/cerebro

ENV JAVA_HOME=/opt/java \
    PATH="/opt/java/bin:${PATH}" \
    LANG=C.UTF-8 \
    CEREBRO_PORT=9000 \
    CEREBRO_DATA_PATH=/var/lib/cerebro/cerebro.db \
    JAVA_TOOL_OPTIONS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.awt.headless=true"

USER nonroot:nonroot
WORKDIR /opt/cerebro
EXPOSE 9000
VOLUME ["/var/lib/cerebro"]

ENTRYPOINT ["java", "-Duser.dir=/opt/cerebro", "-Djava.io.tmpdir=/var/lib/cerebro", "-jar", "/opt/cerebro/lib/launcher.jar"]
