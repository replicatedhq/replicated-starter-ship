.PHONY: install-ship run-local run-local-headless lint clean-assets print-generated-assets deploy deps-lint
SHIP := $(shell which ship)
PATH := $(shell pwd)
SHELL := /bin/bash -o pipefail

RELEASE_NOTES := "Automated release on $(shell date)"
lint_reporter := console

APPLIANCE_CHANNEL := Unstable

SHIP_NIGHTLY_CHANNEL_ID := CHANGEME

# ship supports ignoring semver so we can probably remove this once that flag is added to CLI. This works fine for now
SHIP_SEMVER_SNAPSHOT := 0.1.0-SNAPSHOT

# Replace this with your private or public ship repo in github
REPO := replicatedhq/replicated-starter-ship
# Optional -- replace with your app details
APP_NAME := "My Cool App"
ICON := "https://vendor.replicated.com/011a5f1125bce80a8ced6fae0c409c91.png"

install-ship:
	brew tap replicatedhq/ship
	brew install ship

deps-lint:
	@[ -x `npm bin`/replicated-lint ] || npm install --no-save replicated-lint

deps-vendor-cli:
	@if [[ -x deps/replicated ]]; then exit 0; else \
	echo '-> Downloading Replicated CLI... '; \
	mkdir -p deps/; \
	if [[ "`uname`" == "Linux" ]]; then curl -fsSL https://github.com/replicatedhq/replicated/releases/download/v0.6.0/replicated_0.6.0_linux_amd64.tar.gz | tar xvz -C deps; exit 0; fi; \
	if [[ "`uname`" == "Darwin" ]]; then curl -fsSL https://github.com/replicatedhq/replicated/releases/download/v0.6.0/replicated_0.6.0_darwin_amd64.tar.gz | tar xvz -C deps; exit 0; fi; fi;

require_gsed:
	@[ -z `which gsed` ] || echo "command not found: gsed" && exit 1

lint-appliance: deps-lint
	`npm bin`/replicated-lint validate -f replicated.yaml --reporter $(lint_reporter)
lint-ship: deps-lint
	`npm bin`/replicated-lint validate --project replicatedShip -f ship.yaml --reporter $(lint_reporter)

lint: lint-appliance lint-ship

run-local: clean-assets lint-ship
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

run-local-headless: clean-assets lint-ship
	mkdir -p tmp
	cd tmp && \
	$(SHIP) app \
	    --runbook $(PATH)/ship.yaml  \
	    --set-github-contents $(REPO):/base:master:$(PATH) \
	    --set-github-contents $(REPO):/scripts:master:$(PATH) \
	    --headless \
	    --log-level=error
	@$(MAKE) print-generated-assets

release-appliance: clean-assets lint-appliance deps-vendor-cli
	kustomize build overlays/appliance | awk '/---/{print;print "# kind: scheduler-kubernetes";next}1' > tmp/k8s.yaml
	cat replicated.yaml tmp/k8s.yaml | deps/replicated release create --promote $(APPLIANCE_CHANNEL) --yaml -

release-ship: clean-assets lint-ship deps-vendor-cli
	@deps/replicated shiprelease create \
	    --vendor-token ${REPLICATED_API_TOKEN} \
	    --channel-id $(SHIP_CHANNEL_ID) \
	    --spec-file ./ship.yaml \
	    --semver $(SHIP_SEMVER_SNAPSHOT) \
	    --release-notes $(RELEASE_NOTES)

deploy-ship:
	@echo
	@echo  ┌─────────────┐
	@echo "│  Deploying  │"
	@echo  └─────────────┘
	@echo
	@sleep .5
	kubectl apply -f tmp/rendered.yaml

clean-assets:
	rm -rf tmp/*

print-generated-assets:
	@echo
	@echo  ┌────────────────────┐
	@echo "│  Generated Assets  │"
	@echo  └────────────────────┘
	@echo
	@sleep .5
	@find tmp -maxdepth 3 -type file

