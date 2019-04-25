.PHONY: install-ship run-local run-local-headless lint clean-assets print-generated-assets deploy deps-lint
SHIP := $(shell which ship)
REPO_PATH := $(shell pwd)

lint_reporter := console

# Replace this with your private or public ship repo in github
REPO := replicatedhq/replicated-starter-ship

# App name will be displayed in the ship console
APP_NAME := "My Cool App"
ICON := "https://vendor.replicated.com/011a5f1125bce80a8ced6fae0c409c91.png"

install-ship:
	brew install ship

deps-lint:
	@[ -x `npm bin`/replicated-lint ] || npm install --no-save replicated-lint

lint-ship: deps-lint
	`npm bin`/replicated-lint validate --project replicatedShip -f ship.yaml --reporter $(lint_reporter)

lint: lint-ship

run-local: clean-assets lint-ship
	mkdir -p tmp
	cd tmp && \
	$(SHIP) app \
	    --runbook $(REPO_PATH)/ship.yaml  \
	    --set-github-contents $(REPO):/base:master:$(REPO_PATH) \
	    --set-github-contents $(REPO):/scripts:master:$(REPO_PATH) \
	    --set-channel-icon $(ICON) \
	    --set-channel-name $(APP_NAME) \
	    --log-level=off \
	    $(SHIP_FLAGS)
	@$(MAKE) print-generated-assets

run-local-headless:
	@$(MAKE) SHIP_FLAGS=--headless run-local

deploy-ship:
	@echo
	@echo  ┌─────────────┐
	@echo "│  Deploying  │"
	@echo  └─────────────┘
	@echo
	@sleep .5
	kubectl apply -f tmp/rendered.yaml

print-generated-assets:
	@echo
	@echo  ┌────────────────────┐
	@echo "│  Generated Assets  │"
	@echo  └────────────────────┘
	@echo
	@sleep .5
	@find tmp -maxdepth 3 -type file

clean-assets:
	rm -rf tmp/*

