.PHONY: app app-web back ipa help

app:     ## Flutter (prompts device if multiple)
	cd flutter_app && flutter run

app-web: ## Flutter on Chrome
	cd flutter_app && flutter run -d chrome

back:    ## Backend (tsx watch)
	cd backend && npm run dev

ipa:     ## Build iOS App Store IPA
	cd flutter_app && flutter build ipa --release && open build/ios/ipa

help:    ## List commands
	@grep -E '^[a-z-]+:.*?##' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}; {printf "  \033[36m%-8s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
