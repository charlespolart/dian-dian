.PHONY: run back db db-down test prod-ios prod-android version clean help check-clean check-release check-keystore

COMPOSE_DEV := docker compose -f ops/docker-compose.yml -f ops/docker-compose.dev.yml
PROD_HEALTH := https://diandian.overridedev.com/api/health

# The app version comes from flutter_app/pubspec.yaml (written by
# ./release-app.sh, never by hand). The build number is the commit count:
# never typed, always increasing, the same for iOS (CFBundleVersion) and
# Android (versionCode). The backend has its own version in
# backend/package.json (./release-backend.sh, ./deploy-prod.sh).
VERSION      := $(shell sed -nE 's/^version: ([0-9]+\.[0-9]+\.[0-9]+)$$/\1/p' flutter_app/pubspec.yaml)
BUILD_NUMBER := $(shell git rev-list --count HEAD)

ADB      := $(HOME)/Library/Android/sdk/platform-tools/adb
API_PORT := 3001

run:            ## Run the app in debug on a device/simulator (local API: Android through adb reverse, iPhone through the Mac's Bonjour name; `make run d=<device id>` to pick one)
	-@[ -x "$(ADB)" ] && for s in $$("$(ADB)" devices | awk 'NR>1 && $$2=="device"{print $$1}'); do "$(ADB)" -s $$s reverse tcp:$(API_PORT) tcp:$(API_PORT) >/dev/null && echo "adb reverse: $$s:localhost:$(API_PORT) → this Mac"; done; true
	cd flutter_app && flutter run --dart-define=API_HOST=$$(scutil --get LocalHostName).local $(if $(d),-d $(d),)

back:           ## Run the backend (tsx watch, native)
	cd backend && npm run dev

db:             ## Start Postgres in Docker (dev overlay)
	$(COMPOSE_DEV) up -d postgres

db-down:        ## Stop the Postgres container
	$(COMPOSE_DEV) stop postgres

test:           ## Flutter analyze + tests, backend typecheck
	cd flutter_app && flutter analyze && flutter test
	cd backend && npx tsc --noEmit && npx tsx --test src/lib/*.test.ts

prod-ios: check-release                 ## Build iOS for the App Store (.ipa), from the app-vX.Y.Z tag
	cd flutter_app && flutter build ipa --release --build-number=$(BUILD_NUMBER) && open build/ios/ipa

prod-android: check-release check-keystore  ## Build Android for the Play Store (.aab), from the app-vX.Y.Z tag
	cd flutter_app && flutter build appbundle --release --build-number=$(BUILD_NUMBER) && open build/app/outputs/bundle/release

version:        ## Show the app version and build number of the current commit, and the backend version
	@echo "app      $(VERSION) ($(BUILD_NUMBER))"
	@echo "backend  $$(node -p "require('./backend/package.json').version")"

clean:          ## Remove Flutter build artifacts
	cd flutter_app && flutter clean

help:           ## List commands
	@grep -E '^[a-z-]+:.*?##' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

# A distributed build corresponds to a commit: its build number is the commit
# count, and two different binaries must never carry the same one.
check-clean:
	@test -z "$$(git status --porcelain)" || { echo "Working tree modified: commit before building (the build number identifies a commit)." >&2; exit 1; }

# A store build starts from a version tag set by ./release-app.sh, and
# production must answer: no store binary pointing at an API that is not there.
check-release: check-clean
	@test -n "$(VERSION)" || { echo "flutter_app/pubspec.yaml has no 'version: X.Y.Z' line (no +N: the build number is computed)." >&2; exit 1; }
	@git tag --points-at HEAD | grep -qx "app-v$(VERSION)" || { echo "HEAD is not the tag app-v$(VERSION): store builds start from a version tag (./release-app.sh, then git checkout app-v$(VERSION))." >&2; exit 1; }
	@curl -fsS --max-time 10 -o /dev/null $(PROD_HEALTH) || { echo "The production API does not answer ($(PROD_HEALTH))." >&2; exit 1; }

check-keystore:
	@test -f flutter_app/android/key.properties || { echo "flutter_app/android/key.properties is missing: the Play Store refuses an AAB signed with the debug keys." >&2; exit 1; }

.DEFAULT_GOAL := help
