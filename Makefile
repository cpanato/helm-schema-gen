GOPATH := $(shell go env GOPATH)
BIN_NAME := helm-schema-gen

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

FORCE: ;

.PHONY: deps
deps: ## Download go dependencies
	@echo Downloading dependencies
	@go mod download

.PHONY: clean
clean-build: ## Removes the bin folder
	rm -rf bin

bin/%: FORCE
	@echo Building binary
	go build -o $@ .

.PHONY: build
build: deps bin/$(BIN_NAME) ## Build the binary

.PHONY: lint
lint: ## use goimports to lint
	@$(GOPATH)/bin/goimports -d -e -local github.com/cpanato/helm-schema-gen $$(go list -f {{.Dir}} ./...)

.PHONY: bench
bench: ## Run benchmarks
	go test -bench=. ./...

.PHONY: test
test: ## Run tests
	go test -race -v -count=1 ./...

.PHONY: coverage
coverage: ## Run the tests with coverage
	go test -race -v -count=1 -covermode=atomic -coverprofile=coverage.out ./...

.PHONY: coverage-out
coverage-out: coverage ## Output code coverage at the CLI
	go tool cover -func=coverage.out

.PHONY: coverage-html
coverage-html: coverage ## Output code coverage as HTML
	go tool cover -html=coverage.out

.PHONY: outdated
outdated: ## Checks for outdated dependencies
	go list -u -m -json all | go-mod-outdated -update

.PHONY: install
install: build ## Installs the plugin from GitHub using version defined in plugin.yaml
	helm plugin install .
