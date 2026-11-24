# syntax=docker/dockerfile:1

# Cerebro is built from source against Play 3.0 / Pekko on Java 21.
# The runtime is a stripped glibc jlink JRE on distroless without OpenSSL.
# Java does its own TLS. The base image only carries glibc, certificates and zone data.

ARG ALPINE_IMAGE=alpine:3.24
ARG TEMURIN_IMAGE=eclipse-temurin:21.0.9_10-jdk-jammy
ARG DISTROLESS_IMAGE=gcr.io/distroless/base-nossl-debian12:nonroot
ARG SBT_VERSION=1.13.1

FROM ${TEMURIN_IMAGE} AS builder

ARG SBT_VERSION

WORKDIR /src

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates gzip tar \
    && curl -fsSL "https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz" \
      | tar -xz -C /usr/local --strip-components=1 \
    && rm -rf /var/lib/apt/lists/*

COPY project/build.properties project/plugins.sbt project/
COPY build.sbt ./
RUN sbt --batch update

COPY app ./app
COPY conf ./conf
COPY public ./public
COPY test ./test
COPY project ./project
RUN sbt --batch test stage \
    && ln -sf "$(basename "$(ls /src/target/universal/stage/lib/*-launcher.jar | head -n 1)")" \
        /src/target/universal/stage/lib/launcher.jar

FROM ${TEMURIN_IMAGE} AS jre

# java.desktop stays: Guice's cglib still touches java.beans.
RUN jlink \
        --add-modules java.base,java.desktop,java.instrument,java.logging,java.management,java.naming,java.net.http,java.prefs,java.rmi,java.security.jgss,java.security.sasl,java.sql,java.xml,java.xml.crypto,jdk.charsets,jdk.crypto.ec,jdk.management,jdk.naming.dns,jdk.unsupported,jdk.zipfs \
        --strip-debug \
        --no-man-pages \
        --no-header-files \
        --compress=zip-6 \
        --output /javaruntime

FROM ${ALPINE_IMAGE} AS data

RUN mkdir -p /var/lib/cerebro \
    && touch /var/lib/cerebro/.keep \
    && chown -R 65532:65532 /var/lib/cerebro \
    && chmod 0750 /var/lib/cerebro

FROM ${DISTROLESS_IMAGE}

ARG IMAGE_SOURCE=""
ARG GIT_SHA=""

LABEL org.opencontainers.image.title="cerebro" \
      org.opencontainers.image.description="Cerebro 0.10.0 built from source on Play 3.0 / Java 21" \
      org.opencontainers.image.url="https://github.com/lmenezes/cerebro" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.version="0.10.0" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.licenses="MIT"

COPY --from=jre /javaruntime /opt/java
COPY --from=builder /src/target/universal/stage /opt/cerebro
COPY --chown=65532:65532 --from=data /var/lib/cerebro /var/lib/cerebro

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
