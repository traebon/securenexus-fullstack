SHELL := /bin/bash
.PHONY: help secrets preflight up-core up-identity up-portal up-monitoring up-dns up-mail up-byrne up-all down ps logs restart pack build-byrne-website install-awesomepos erp-branding erp-sso erp-shell erp-logs byrne-logs

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
	@echo "  make up-byrne      - byrne accounting website + ERPNext + POS"
	@echo "  make up-all        - everything"
	@echo "  make down          - stop all"
	@echo "  make ps            - docker compose ps"
	@echo "  make logs          - docker compose logs -f"
	@echo "  make restart S=svc - restart service"
	@echo "  make pack          - zip ./securenexus-fullstack to ../securenexus-fullstack.zip"
	@echo "  make build-byrne-website - build byrne website Docker image"
	@echo "  make install-awesomepos  - install AwesomePOS app in ERPNext"
	@echo "  make erp-branding  - apply SecureNexus branding to ERPNext"
	@echo "  make erp-sso       - configure Authentik SSO for ERPNext (requires env vars)"
	@echo "  make erp-shell     - open shell in ERPNext backend container"
	@echo "  make erp-logs      - follow ERPNext backend logs"
	@echo "  make byrne-logs    - follow all Byrne Accounting service logs"

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

up-byrne: build-byrne-website
	@echo "Starting Byrne Accounting infrastructure..."
	docker compose up -d erpnext-db erpnext-redis-cache erpnext-redis-queue
	@echo "Waiting for databases to be ready..."
	@sleep 15
	@echo "Running ERPNext configurator (site initialization)..."
	docker compose up erpnext-configurator
	@echo "Starting ERPNext services..."
	docker compose up -d erpnext-backend erpnext-socketio erpnext-worker erpnext-scheduler
	docker compose up -d byrne-website
	@echo ""
	@echo "✓ Byrne Accounting stack started!"
	@echo ""
	@echo "URLs:"
	@echo "  - Website: https://byrne-accounts.org"
	@echo "  - Website (www): https://www.byrne-accounts.org"
	@echo "  - ERP: https://erp.byrne-accounts.org"
	@echo "  - POS: https://pos.byrne-accounts.org"
	@echo ""
	@echo "Default Login (first time):"
	@echo "  - Username: Administrator"
	@echo "  - Password: (check secrets/erpnext_admin_password.txt)"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Wait for ERPNext backend to be healthy:"
	@echo "     docker compose ps erpnext-backend"
	@echo "  2. Install branding:"
	@echo "     docker exec -it erpnext-backend /custom-branding/install-branding.sh"
	@echo "  3. Set up Authentik SSO:"
	@echo "     - Create OAuth provider in Authentik for ERPNext"
	@echo "     - Run: docker exec -it -e CLIENT_ID='...' -e CLIENT_SECRET='...' erpnext-backend /custom-branding/setup-sso.sh"
	@echo ""

build-byrne-website:
	@echo "Building byrne-website Docker image..."
	docker compose build byrne-website

install-awesomepos:
	./byrne-scripts/install-awesomepos.sh

up-all: up-core up-identity up-portal up-monitoring up-dns up-mail up-byrne

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

erp-branding:
	@echo "Installing SecureNexus branding to ERPNext..."
	docker exec -it erpnext-backend /custom-branding/install-branding.sh

erp-sso:
	@if [ -z "$$CLIENT_ID" ] || [ -z "$$CLIENT_SECRET" ]; then \
		echo "Error: CLIENT_ID and CLIENT_SECRET environment variables required"; \
		echo ""; \
		echo "Usage:"; \
		echo "  export CLIENT_ID='your-authentik-client-id'"; \
		echo "  export CLIENT_SECRET='your-authentik-client-secret'"; \
		echo "  make erp-sso"; \
		exit 1; \
	fi
	docker exec -it -e CLIENT_ID="$$CLIENT_ID" -e CLIENT_SECRET="$$CLIENT_SECRET" erpnext-backend /custom-branding/setup-sso.sh

erp-shell:
	docker exec -it erpnext-backend bash

erp-logs:
	docker compose logs -f erpnext-backend

byrne-logs:
	docker compose logs -f byrne-website erpnext-backend erpnext-worker erpnext-scheduler erpnext-socketio
