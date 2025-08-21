# Makefile for Guardrail Service Documentation
# Provides convenient commands for building and managing Antora documentation

.PHONY: help
help: ## Show this help message
	@echo "Guardrail Service Documentation - Make Commands"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: deps
deps: ## Install Node.js dependencies
	@echo "Installing dependencies..."
	npm ci

.PHONY: deps-update
deps-update: ## Update Node.js dependencies
	@echo "Updating dependencies..."
	npm update
	npm audit fix

.PHONY: clean
clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	rm -rf build/ public/ .cache/ .antora-cache/

.PHONY: clean-all
clean-all: clean ## Clean everything including dependencies
	@echo "Cleaning everything..."
	rm -rf node_modules/

.PHONY: build-local
build-local: ## Build documentation locally for testing
	@echo "Building documentation locally..."
	npx antora --fetch local-antora-playbook.yml

.PHONY: build-prod
build-prod: ## Build documentation for production
	@echo "Building documentation for production..."
	npx antora --fetch antora-playbook.yml

.PHONY: preview
preview: build-local ## Preview documentation locally
	@echo "Starting preview server..."
	npx http-server build -o

.PHONY: preview-prod
preview-prod: build-prod ## Preview production build locally
	@echo "Starting production preview server..."
	npx http-server public -o

.PHONY: serve
serve: ## Serve already built documentation
	@echo "Starting server for built documentation..."
	@if [ -d "build" ]; then \
		npx http-server build -p 8080; \
	else \
		echo "No build directory found. Run 'make build-local' first."; \
		exit 1; \
	fi

.PHONY: validate
validate: ## Validate cross-references and structure
	@echo "Validating documentation structure..."
	npx antora --fetch --generator @antora/xref-validator local-antora-playbook.yml

.PHONY: check-links
check-links: build-local ## Check for broken links
	@echo "Checking for broken links..."
	npx http-server build -p 8080 & \
	SERVER_PID=$$!; \
	sleep 3; \
	npx broken-link-checker http://localhost:8080 --recursive --exclude-external; \
	kill $$SERVER_PID

.PHONY: lint
lint: ## Lint AsciiDoc files
	@echo "Linting AsciiDoc files..."
	@find modules -name "*.adoc" -exec echo "Checking: {}" \; -exec asciidoctor --safe-mode=safe --failure-level=WARNING -o /dev/null {} \;

.PHONY: format
format: ## Format AsciiDoc files
	@echo "Formatting AsciiDoc files..."
	npx prettier --write "**/*.{json,yml,yaml,md}"

.PHONY: watch
watch: ## Watch for changes and rebuild
	@echo "Watching for changes..."
	npx nodemon --watch modules --watch antora.yml --watch local-antora-playbook.yml --ext adoc,yml --exec "make build-local"

.PHONY: create-module
create-module: ## Create a new documentation module
	@read -p "Enter module name: " module; \
	echo "Creating module: $$module"; \
	mkdir -p modules/$$module/{pages,images,examples,attachments,partials}; \
	echo "* xref:index.adoc[$$module Overview]" > modules/$$module/nav.adoc; \
	echo "= $$module" > modules/$$module/pages/index.adoc; \
	echo ":description: Documentation for $$module" >> modules/$$module/pages/index.adoc; \
	echo "" >> modules/$$module/pages/index.adoc; \
	echo "Welcome to the $$module documentation." >> modules/$$module/pages/index.adoc; \
	echo "Module '$$module' created successfully!"

.PHONY: stats
stats: ## Show documentation statistics
	@echo "Documentation Statistics:"
	@echo "========================"
	@echo "Modules: $$(ls -d modules/*/ 2>/dev/null | wc -l)"
	@echo "Pages: $$(find modules -name "*.adoc" 2>/dev/null | wc -l)"
	@echo "Images: $$(find modules -name "*.png" -o -name "*.jpg" -o -name "*.svg" 2>/dev/null | wc -l)"
	@echo "Examples: $$(find modules/*/examples -type f 2>/dev/null | wc -l)"
	@if [ -d "build" ]; then \
		echo "Build size: $$(du -sh build 2>/dev/null | cut -f1)"; \
		echo "HTML files: $$(find build -name "*.html" 2>/dev/null | wc -l)"; \
	fi

.PHONY: tree
tree: ## Show documentation structure
	@echo "Documentation Structure:"
	@echo "======================="
	@tree -I 'node_modules|build|public|.cache' -L 3 --dirsfirst

.PHONY: dev
dev: deps build-local serve ## One-stop development setup

.PHONY: test
test: validate lint ## Run all tests

.PHONY: ci
ci: clean deps validate lint build-prod ## Run CI pipeline locally

.PHONY: docker-build
docker-build: ## Build Docker image for serving docs
	@echo "Building Docker image..."
	docker build -t guardrail-docs:latest .

.PHONY: docker-run
docker-run: ## Run documentation in Docker
	@echo "Running documentation in Docker..."
	docker run -p 8080:80 guardrail-docs:latest

.PHONY: nix-shell
nix-shell: ## Enter Nix development shell
	@echo "Entering Nix development shell..."
	nix develop

.PHONY: nix-build
nix-build: ## Build with Nix
	@echo "Building with Nix..."
	nix develop -c make build-prod

.PHONY: init
init: ## Initialize the project for first use
	@echo "Initializing Guardrail Service Documentation..."
	@if command -v nix >/dev/null 2>&1; then \
		echo "Nix detected, entering development shell..."; \
		nix develop -c make deps; \
	else \
		echo "Installing dependencies with npm..."; \
		make deps; \
	fi
	@echo "Creating directories..."
	@mkdir -p build public .cache
	@echo "Initialization complete! Run 'make dev' to start developing."

.PHONY: release
release: clean build-prod ## Prepare a release
	@echo "Preparing release..."
	@read -p "Enter version number: " version; \
	echo "Creating release $$version"; \
	tar -czf guardrail-docs-$$version.tar.gz public/; \
	echo "Release archive created: guardrail-docs-$$version.tar.gz"

# Default target
.DEFAULT_GOAL := help