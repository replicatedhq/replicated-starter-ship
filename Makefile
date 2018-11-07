.PHONY: install-ship run-local run-local-headless lint clean-assets print-generated-assets deploy deps
SHIP := $(shell which ship)
PATH := $(shell pwd)
SHELL := /bin/bash -lo pipefail
lint_reporter := console

# Replace this with your private or public ship repo in github
REPO := replicatedhq/replicated-starter-ship

# Optional -- replace with your app details
APP_NAME := "My Cool App"
ICON := "https://vendor.replicated.com/011a5f1125bce80a8ced6fae0c409c91.png"


install-ship:
	brew tap replicatedhq/ship
	brew install ship

deps:
	npm install replicated-lint

lint:
	`~/bin/npm bin`/replicated-lint validate --project replicatedShip -f ship.yaml --reporter $(lint_reporter)

run-local: clean-assets lint
	mkdir -p tmp
	cd tmp && \
	$(SHIP) app \
	    --runbook $(PATH)/ship.yaml  \
	    --set-github-contents $(REPO):/base:master:$(PATH) \
	    --set-github-contents $(REPO):/scripts:master:$(PATH) \
	    --set-channel-icon $(ICON) \
	    --set-channel-name $(APP_NAME) \
	    --log-level=off
	@$(MAKE) print-generated-assets

run-local-headless: clean-assets lint
	mkdir -p tmp
	cd tmp && \
	$(SHIP) app \
	    --runbook $(PATH)/ship.yaml  \
	    --set-github-contents $(REPO):/base:master:$(PATH) \
	    --set-github-contents $(REPO):/scripts:master:$(PATH) \
	    --headless \
	    --log-level=error
	@$(MAKE) print-generated-assets

deploy:
	@echo
	@echo  ┌─────────────┐
	@echo "│  Deploying  │"
	@echo  └─────────────┘
	@echo
	@sleep .5
	kubectl apply -f tmp/rendered.yaml

clean-assets:
	rm -rf tmp/base tmp/overlays tmp/*.yaml tmp/scripts

print-generated-assets:
	@echo
	@echo  ┌────────────────────┐
	@echo "│  Generated Assets  │"
	@echo  └────────────────────┘
	@echo
	@sleep .5
	@ls tmp/*
