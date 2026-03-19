.DEFAULT_GOAL := help
ENVIRONMENT ?= dev

##@ Validation

.PHONY: lint-yaml
lint-yaml: ## Run yamllint on all YAML files
	yamllint -c .yamllint.yaml .

.PHONY: kustomize-build
kustomize-build: ## Build all Kustomize overlays (all environments)
	@echo "Building all Kustomize overlays..."
	@find . -path '*/overlays/*/kustomization.yaml' -exec dirname {} \; | while read dir; do \
		echo "Building $$dir ..."; \
		kustomize build --enable-helm "$$dir" > /dev/null || exit 1; \
	done
	@echo "All overlays built successfully."

.PHONY: kustomize-build-env
kustomize-build-env: ## Build overlays for ENVIRONMENT (default: dev)
	@echo "Building $(ENVIRONMENT) overlays..."
	@find . -path "*/overlays/$(ENVIRONMENT)/kustomization.yaml" -exec dirname {} \; | while read dir; do \
		echo "Building $$dir ..."; \
		kustomize build --enable-helm "$$dir" > /dev/null || exit 1; \
	done
	@echo "All $(ENVIRONMENT) overlays built successfully."

.PHONY: validate
validate: lint-yaml kustomize-build ## Run all validations (lint + build)
	@echo "All validations passed."

.PHONY: lint-all
lint-all: lint-yaml ## Run all lint checks
	@echo "All lint checks passed."

##@ Rendering

.PHONY: render
render: ## Render overlays to rendered/ directory for ENVIRONMENT (default: dev)
	@mkdir -p rendered
	@echo "Rendering $(ENVIRONMENT) overlays..."
	@find . -path "*/overlays/$(ENVIRONMENT)/kustomization.yaml" -exec dirname {} \; | while read dir; do \
		name=$$(echo "$$dir" | sed 's|^\./||' | tr '/' '-'); \
		echo "Rendering $$dir ..."; \
		kustomize build --enable-helm "$$dir" > "rendered/$${name}.yaml" || exit 1; \
	done
	@echo "All $(ENVIRONMENT) overlays rendered to rendered/"

.PHONY: clean
clean: ## Remove rendered output
	rm -rf rendered/

##@ Help

.PHONY: help
help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m [ENVIRONMENT=dev|staging|production]\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
