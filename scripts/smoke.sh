#!/bin/sh
# Starts the image, waits until the UI answers, and checks that SQLite landed on the data volume.
set -eu

image="${1:-cerebro:local}"
name="cerebro-smoke-$$"
volume="cerebro-smoke-$$"

docker rm -f "$name" >/dev/null 2>&1 || true
docker volume rm "$volume" >/dev/null 2>&1 || true

cleanup() {
    status=$?
    if [ "$status" -ne 0 ]; then
        docker logs "$name" >&2 || true
    fi
    docker rm -f "$name" >/dev/null 2>&1 || true
    docker volume rm "$volume" >/dev/null 2>&1 || true
    exit "$status"
}
trap cleanup EXIT INT TERM

docker run -d --name "$name" -p 9000 \
    -e CEREBRO_SECRET=smoke-test-secret-not-for-production-use \
    -v "$volume:/var/lib/cerebro" \
    "$image" >/dev/null

port="$(docker port "$name" 9000/tcp | awk -F: 'NR==1 { print $NF }')"

i=0
while [ "$i" -lt 40 ]; do
    code="$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:${port}/" || true)"
    case "$code" in
        200|302|303) break ;;
    esac
    i=$((i + 1))
    sleep 2
done

if [ "$i" -eq 40 ]; then
    echo "cerebro did not answer on port ${port}" >&2
    exit 1
fi

docker run --rm -v "$volume:/data:ro" alpine:3.24 \
    sh -c 'test -s /data/cerebro.db'

echo "cerebro ready on http://127.0.0.1:${port}/"
