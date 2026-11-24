#!/bin/sh
# Upstream conf stays intact. These lines only override when the env var is set.
set -eu

conf=/opt/cerebro/conf/application.conf

sed -i '/^secret = /a secret = ${?CEREBRO_SECRET}' "$conf"
sed -i '/^data.path = /a data.path = ${?CEREBRO_DATA_PATH}' "$conf"
cp /tmp/logback.xml /opt/cerebro/conf/logback.xml

grep -F 'secret = ${?CEREBRO_SECRET}' "$conf" >/dev/null
grep -F 'data.path = ${?CEREBRO_DATA_PATH}' "$conf" >/dev/null
grep -F 'name="STDOUT"' /opt/cerebro/conf/logback.xml >/dev/null
if grep -F 'name="FILE"' /opt/cerebro/conf/logback.xml >/dev/null; then
    echo "file appender still present" >&2
    exit 1
fi
