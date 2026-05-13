.PHONY: app back db db-down ipa deploy help

COMPOSE_DEV := docker compose -f ops/docker-compose.yml -f ops/docker-compose.dev.yml

app:     ## Flutter (prompts device if multiple)
	cd flutter_app && flutter run

back:    ## Backend (tsx watch, native)
	cd backend && npm run dev

db:      ## Start Postgres in Docker (dev overlay)
	$(COMPOSE_DEV) up -d postgres

db-down: ## Stop Postgres container
	$(COMPOSE_DEV) stop postgres

ipa:     ## Build iOS App Store IPA
	cd flutter_app && flutter build ipa --release && open build/ios/ipa

deploy:  ## Trigger a production deploy via GH Actions (HEAD short SHA)
	./ops/scripts/deploy.sh

help:    ## List commands
	@grep -E '^[a-z-]+:.*?##' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}; {printf "  \033[36m%-8s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
