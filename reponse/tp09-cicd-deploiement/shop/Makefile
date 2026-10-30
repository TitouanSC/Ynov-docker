COMPOSE=docker compose
PROD=$(COMPOSE) -f compose.yml -f compose.prod.yml --env-file .env

.PHONY: up down ps logs config prod-up prod-down migrate test wait

up:
	$(COMPOSE) up -d --build --wait

wait:
	$(COMPOSE) up -d --wait

down:
	$(COMPOSE) down

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f --tail=100

config:
	$(COMPOSE) config

prod-up:
	$(PROD) up -d --wait --scale api=2

prod-down:
	$(PROD) down

migrate:
	MIGRATION=$(M) $(COMPOSE) --profile ops run --rm -e MIGRATION=$(M) migrate

test:
	./scripts/smoke-test.sh
