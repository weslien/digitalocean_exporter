EXECUTABLE ?= digitalocean_exporter
IMAGE ?= weslien/$(EXECUTABLE)
GO := CGO_ENABLED=0 go
DATE := $(shell date -u '+%FT%T%z')

LDFLAGS += -X main.Version=$(DRONE_TAG)
LDFLAGS += -X main.Revision=$(DRONE_COMMIT)
LDFLAGS += -X "main.BuildDate=$(DATE)"
LDFLAGS += -extldflags '-static'

PACKAGES = $(shell go list ./...)

.PHONY: all
all: build

.PHONY: clean
clean:
	$(GO) clean -i ./...
	rm -rf dist/

.PHONY: fmt
fmt:
	$(GO) fmt $(PACKAGES)

.PHONY: vet
vet:
	$(GO) vet $(PACKAGES)

.PHONY: lint
lint:
	@which golint > /dev/null; if [ $$? -ne 0 ]; then \
		$(GO) get -u golang.org/x/lint/golint; \
	fi
	for PKG in $(PACKAGES); do golint -set_exit_status $$PKG || exit 1; done;

.PHONY: test
test:
	@for PKG in $(PACKAGES); do $(GO) test -cover $$PKG || exit 1; done;

$(EXECUTABLE): $(wildcard *.go)
	$(GO) build -v -ldflags '-w $(LDFLAGS)'

.PHONY: build
build: $(EXECUTABLE)

.PHONY: install
install:
	$(GO) install -v -ldflags '-w $(LDFLAGS)'

.PHONY: release
release:
	@which gox > /dev/null; if [ $$? -ne 0 ]; then \
		$(GO) get -u github.com/mitchellh/gox; \
	fi
	CGO_ENABLED=0 gox -verbose -ldflags '-w $(LDFLAGS)' -osarch '!darwin/386' -output="dist/$(EXECUTABLE)-${DRONE_TAG}-{{.OS}}-{{.Arch}}"
