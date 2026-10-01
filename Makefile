INSTALLER := tools/installer
ADDONTEST := tools/addontest
ARTWORK   := tools/artwork
VERSION   := $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
RUN       := go -C $(INSTALLER) run . -src "$(CURDIR)" -version "$(VERSION)"

# Zusätzliche Flags, z.B. make install ARGS="-flavors retail -wow 'D:/Games/World of Warcraft'"
ARGS ?=

.PHONY: install update dry-run package artwork test test-addon test-installer test-artwork vet

# Interaktiver Wizard: Flavors wählen, Plan ansehen, bestätigen
install:
	$(RUN) $(ARGS)

# Ohne Rückfragen alle bereits installierten Flavors aktualisieren
update:
	$(RUN) -yes $(ARGS)

# Nur anzeigen, was passieren würde
dry-run:
	$(RUN) -dry-run -yes $(ARGS)

# ZIP für CurseForge oder manuelle Installation: dist/LevelTimer-<version>.zip
package:
	$(RUN) -package "$(CURDIR)/dist/LevelTimer-$(VERSION).zip"

# CurseForge-Logo und Addon-Icon aus tools/artwork neu erzeugen
artwork:
	go -C $(ARTWORK) run . -logo "$(CURDIR)/curseforge/logo.png" -icon "$(CURDIR)/Media/Icon.tga"

test: test-addon test-installer test-artwork

# Lua-Szenarien aus tests/ gegen eine nachgebaute WoW-API.
# -count=1: Go kennt die Lua-Dateien nicht und würde sonst veraltete Ergebnisse aus dem Cache zeigen.
test-addon:
	go -C $(ADDONTEST) test -count=1 ./...

test-installer:
	go -C $(INSTALLER) test ./...

test-artwork:
	go -C $(ARTWORK) test ./...

vet:
	go -C $(INSTALLER) vet ./...
	go -C $(ADDONTEST) vet ./...
	go -C $(ARTWORK) vet ./...
