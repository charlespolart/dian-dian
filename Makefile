.PHONY: run back db db-down test prod-ios prod-android version clean help check-clean check-prod check-keystore

COMPOSE_DEV := docker compose -f ops/docker-compose.yml -f ops/docker-compose.dev.yml
PROD_HEALTH := https://diandian.overridedev.com/api/health

# The app version and build number come from flutter_app/pubspec.yaml
# (`version: 1.3.0+7`). The backend has its own version in backend/package.json,
# released and deployed by ./release.sh and ./deploy-prod.sh.
VERSION      := $(shell sed -nE 's/^version: ([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)$$/\1/p' flutter_app/pubspec.yaml)
BUILD_NUMBER := $(shell sed -nE 's/^version: ([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)$$/\2/p' flutter_app/pubspec.yaml)

run:            ## Run the app on a device/simulator (local API in debug)
	cd flutter_app && flutter run

back:           ## Run the backend (tsx watch, native)
	cd backend && npm run dev

db:             ## Start Postgres in Docker (dev overlay)
	$(COMPOSE_DEV) up -d postgres

db-down:        ## Stop the Postgres container
	$(COMPOSE_DEV) stop postgres

test:           ## Flutter analyze + tests, backend typecheck
	cd flutter_app && flutter analyze && flutter test
	cd backend && npx tsc --noEmit

prod-ios: check-clean check-prod                     ## Build iOS for the App Store (.ipa)
	cd flutter_app && flutter build ipa --release && open build/ios/ipa

prod-android: check-clean check-prod check-keystore  ## Build Android for the Play Store (.aab)
	cd flutter_app && flutter build appbundle --release && open build/app/outputs/bundle/release

version:        ## Show the app version (build number) and the backend version
	@echo "app      $(VERSION) ($(BUILD_NUMBER))"
	@echo "backend  $$(node -p "require('./backend/package.json').version")"

clean:          ## Remove Flutter build artifacts
	cd flutter_app && flutter clean

help:           ## List commands
	@grep -E '^[a-z-]+:.*?##' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

# A distributed build must correspond to a commit: no store build from a
# modified working tree.
check-clean:
	@test -z "$$(git status --porcelain)" || { echo "Working tree modified: commit before building (a store build identifies a commit)." >&2; exit 1; }

# No store binary pointing at an API that is not there.
check-prod:
	@curl -fsS --max-time 10 -o /dev/null $(PROD_HEALTH) || { echo "The production API does not answer ($(PROD_HEALTH))." >&2; exit 1; }

check-keystore:
	@test -f flutter_app/android/key.properties || { echo "flutter_app/android/key.properties is missing: the Play Store refuses an AAB signed with the debug keys." >&2; exit 1; }

.DEFAULT_GOAL := help
