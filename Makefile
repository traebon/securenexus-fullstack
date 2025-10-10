SHELL := /bin/bash
.PHONY: help secrets preflight up-core up-identity up-portal up-monitoring up-dns up-mail up-all down ps logs restart pack

help:
	@echo "Targets:"
	@echo "  make secrets       - generate ./secrets/*"
	@echo "  make preflight     - sanity checks"
	@echo "  make up-core       - docker-proxy, traefik, headscale"
	@echo "  make up-identity   - postgres/redis/authentik"
	@echo "  make up-portal     - landing + homarr"
	@echo "  make up-monitoring - prom/loki/promtail/blackbox/grafana/node/cadvisor"
	@echo "  make up-dns        - coredns + etcd + mysql + dns-updater"
	@echo "  make up-mail       - stalwart"
	@echo "  make up-all        - everything"
	@echo "  make down          - stop all"
	@echo "  make ps            - docker compose ps"
	@echo "  make logs          - docker compose logs -f"
	@echo "  make restart S=svc - restart service"
	@echo "  make pack          - zip ./securenexus-fullstack to ../securenexus-fullstack.zip"

secrets:
	./scripts/generate-secrets.sh

preflight:
	./scripts/preflight.sh

up-core:
	docker compose up -d docker-proxy traefik souin_redis headscale crowdsec crowdsec_bouncer

up-identity:
	docker compose up -d authentik_db redis_cache authentik_server authentik_worker

up-portal:
	docker compose up -d landing homarr wellknown brand-static

up-monitoring:
	docker compose up -d prometheus blackbox loki promtail grafana cadvisor node-exporter

up-dns: up-core
	docker compose --profile dns up -d

up-mail:
	docker compose up -d stalwart

up-all: up-core up-identity up-portal up-monitoring up-dns up-mail

down:
	docker compose down

ps:
	docker compose ps

logs:
	docker compose logs -f

restart:
	@if [ -z "$(S)" ]; then echo "Usage: make restart S=service"; exit 1; fi
	docker compose restart $(S)

pack:
	@cd .. && zip -r securenexus-fullstack.zip securenexus-fullstack >/dev/null && echo "Wrote ../securenexus-fullstack.zip"
