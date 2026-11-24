IMAGE ?= cerebro:local
PORT ?= 9000

.PHONY: build run smoke scan

build:
	docker build -t $(IMAGE) .

run: build
	docker run --rm --name cerebro -p $(PORT):9000 \
		-e CEREBRO_SECRET=$${CEREBRO_SECRET:-local-dev-only-not-for-production-use} \
		-v cerebro-data:/var/lib/cerebro \
		$(IMAGE)

smoke:
	./scripts/smoke.sh $(IMAGE)

scan: build
	docker run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy:0.76.2 image \
		--severity HIGH,CRITICAL \
		--ignore-unfixed \
		--scanners vuln \
		$(IMAGE)
