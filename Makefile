INSTALLER := tools/installer
VERSION   := $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
RUN       := go -C $(INSTALLER) run . -src "$(CURDIR)" -version "$(VERSION)"

# Zusätzliche Flags, z.B. make install ARGS="-flavors retail -wow 'D:/Games/World of Warcraft'"
ARGS ?=

.PHONY: install update dry-run test vet

# Interaktiver Wizard: Flavors wählen, Plan ansehen, bestätigen
install:
	$(RUN) $(ARGS)

# Ohne Rückfragen alle bereits installierten Flavors aktualisieren
update:
	$(RUN) -yes $(ARGS)

# Nur anzeigen, was passieren würde
dry-run:
	$(RUN) -dry-run -yes $(ARGS)

test:
	go -C $(INSTALLER) test ./...

vet:
	go -C $(INSTALLER) vet ./...
