.PHONY: install-ship run-local run-local-headless lint clean-assets print-generated-assets deploy deps-lint
SHIP := $(shell which ship)
REPO_PATH := $(shell pwd)

RELEASE_NOTES := "Automated release by ${USER} on $(shell date)"
lint_reporter := console

APPLIANCE_APP_ID := CHANGEME
APPLIANCE_CHANNEL := Unstable

SHIP_APP_ID := CHANGEME
SHIP_CHANNEL := Nightly

VERSION_TAG := "0.1.0-dev-${USER}"

# Replace this with your private or public ship repo in github
REPO := replicatedhq/replicated-starter-ship

# App name will be displayed in the ship console
APP_NAME := "My Cool App"
ICON := "https://vendor.replicated.com/011a5f1125bce80a8ced6fae0c409c91.png"

install-ship:
	brew install ship

deps-lint:
	@[ -x `npm bin`/replicated-lint ] || npm install --no-save replicated-lint

deps-vendor-cli:
	@if [[ -x deps/replicated ]]; then exit 0; else \
	echo '-> Downloading Replicated CLI... '; \
	mkdir -p deps/; \
	if [[ "`uname`" == "Linux" ]]; then curl -fsSL https://github.com/replicatedhq/replicated/releases/download/v0.9.0/replicated_0.9.0_linux_amd64.tar.gz | tar xvz -C deps; exit 0; fi; \
	if [[ "`uname`" == "Darwin" ]]; then curl -fsSL https://github.com/replicatedhq/replicated/releases/download/v0.9.0/replicated_0.9.0_darwin_amd64.tar.gz | tar xvz -C deps; exit 0; fi; fi;


lint-appliance: deps-lint
	`npm bin`/replicated-lint validate -f replicated.yaml --reporter $(lint_reporter)
lint-ship: deps-lint
	`npm bin`/replicated-lint validate --project replicatedShip -f ship.yaml --reporter $(lint_reporter)

lint: lint-appliance lint-ship

release-appliance: clean-assets lint-appliance deps-vendor-cli
	mkdir -p tmp
	kustomize build overlays/appliance | awk '/---/{print;print "# kind: scheduler-kubernetes";next}1' > tmp/k8s.yaml
	cat replicated.yaml tmp/k8s.yaml | deps/replicated release create \
	        --app $(APPLIANCE_APP_ID) \
		--yaml - \
		--promote $(APPLIANCE_CHANNEL) \
	        --version $(VERSION_TAG) \
	        --release-notes $(RELEASE_NOTES)

release-ship: clean-assets lint-ship deps-vendor-cli
	cat ship.yaml | deps/replicated release create \
	    --app $(SHIP_APP_ID) \
	    --yaml - \
	    --promote $(SHIP_CHANNEL) \
	    --version $(VERSION_TAG) \
	    --release-notes $(RELEASE_NOTES)

run-local: clean-assets lint-ship
	mkdir -p tmp
	cd tmp && \
	$(SHIP) app \
	    --runbook $(REPO_PATH)/ship.yaml  \
	    --set-github-contents $(REPO):/base:master:$(REPO_PATH) \
	    --set-github-contents $(REPO):/scripts:master:$(REPO_PATH) \
	    --set-channel-icon $(ICON) \
	    --set-channel-name $(APP_NAME) \
	    --log-level=off
	@$(MAKE) print-generated-assets

run-local-headless: clean-assets lint-ship
	mkdir -p tmp
	cd tmp && \
	$(SHIP) app \
	    --runbook $(REPO_PATH)/ship.yaml  \
	    --set-github-contents $(REPO):/base:master:$(REPO_PATH) \
	    --set-github-contents $(REPO):/scripts:master:$(REPO_PATH) \
	    --headless \
	    --log-level=error
	@$(MAKE) print-generated-assets

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

