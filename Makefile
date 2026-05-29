NAME = KeepingYouAwake
VERSION = 2.0.0

SCHEME = $(NAME)
TARGET = $(NAME)
DIRECT_SCHEME = $(NAME) (Direct)
DIRECT_TARGET = $(NAME) (Direct)
WORKSPACE = $(NAME).xcworkspace

BUILD_DIR = build
OUTPUT_DIR = dist
LOCALIZATIONS_DIR = Localizations

# DMG
DMG_VOLUME_NAME = $(NAME) $(VERSION)
DMG_TMP_DIR = $(BUILD_DIR)/dmg

XCODEBUILD = set -o pipefail && env NSUnbufferedIO=YES xcodebuild
BEAUTIFY = | if command -v xcbeautify >/dev/null 2>&1; then xcbeautify; else cat; fi
DISABLE_PACKAGE_RESOLUTION = -disableAutomaticPackageResolution -onlyUsePackageVersionsFromResolvedFile
SAVE_LOG = 2>&1 | tee "$(BUILD_DIR)/$(NAME).log"

default: clean

clean:
	$(RM) -r $(BUILD_DIR)
PHONY: clean

dist-clean:
	$(RM) -r $(OUTPUT_DIR)
PHONY: dist-clean

test:
	@mkdir -p "$(BUILD_DIR)"
	$(XCODEBUILD) test \
	-workspace "$(WORKSPACE)" \
	-scheme "$(SCHEME)" \
	-derivedDataPath "$(BUILD_DIR)" \
	$(DISABLE_PACKAGE_RESOLUTION) \
	$(SAVE_LOG) \
	$(BEAUTIFY)
PHONY: test

test-with-sanitizers:
	@mkdir -p "$(BUILD_DIR)"
	$(XCODEBUILD) test \
	-workspace "$(WORKSPACE)" \
	-scheme "$(SCHEME)" \
	-testPlan "SanitizerTestPlan" \
	-derivedDataPath "$(BUILD_DIR)" \
	$(DISABLE_PACKAGE_RESOLUTION) \
	$(SAVE_LOG) \
	$(BEAUTIFY)
PHONY: test-with-sanitizers

l10n-export:
	Localizations/l10n-export.sh
.PHONY: l10n-export

l10n-import:
	Localizations/l10n-import.sh
.PHONY: l10n-export

l10n-update:
	$(MAKE) l10n-export
	$(MAKE) l10n-import
	$(MAKE) l10n-export
.PHONY: l10n-update

$(OUTPUT_DIR)/$(NAME).xcarchive:
	@mkdir -p "$(BUILD_DIR)"
	$(XCODEBUILD) archive \
	-workspace "$(WORKSPACE)" \
	-scheme "$(SCHEME)" \
	-archivePath "$(OUTPUT_DIR)/$(NAME).xcarchive" \
	$(DISABLE_PACKAGE_RESOLUTION) \
	$(SAVE_LOG) \
	$(BEAUTIFY)

$(OUTPUT_DIR)/$(NAME).pkg: $(OUTPUT_DIR)/$(NAME).xcarchive
	$(XCODEBUILD) \
	-exportArchive \
	-archivePath "$(OUTPUT_DIR)/$(NAME).xcarchive" \
	-exportPath "$(OUTPUT_DIR)/" \
	-exportOptionsPlist "ExportOptions.plist" \
	$(DISABLE_PACKAGE_RESOLUTION) \
	$(SAVE_LOG) \
	$(BEAUTIFY)

$(OUTPUT_DIR)/$(NAME)-$(VERSION).zip: $(OUTPUT_DIR)/$(NAME).pkg
	@echo "Exporting $(OUTPUT_DIR)/$(NAME)-$(VERSION).zip..."
	@ditto -c -k --sequesterRsrc --keepParent $(OUTPUT_DIR)/$(NAME).app $(OUTPUT_DIR)/$(NAME)-$(VERSION).zip

dist: $(OUTPUT_DIR)/$(NAME)-$(VERSION).zip
	@echo "Verifying code signing identity..."
	@spctl -a -vv $(OUTPUT_DIR)/$(NAME).app
.PHONY: dist

# --- Direct Distribution (DMG) ---

DIRECT_ARCHIVE = $(OUTPUT_DIR)/$(NAME)-$(VERSION)-direct.xcarchive

$(DIRECT_ARCHIVE):
	@mkdir -p "$(BUILD_DIR)"
	$(XCODEBUILD) archive \
	-workspace "$(WORKSPACE)" \
	-scheme "$(DIRECT_SCHEME)" \
	-archivePath "$(DIRECT_ARCHIVE)" \
	$(DISABLE_PACKAGE_RESOLUTION) \
	$(SAVE_LOG) \
	$(BEAUTIFY)

$(OUTPUT_DIR)/$(NAME)-direct.app: $(DIRECT_ARCHIVE)
	@echo "Extracting app from archive..."
	@cp -R "$(DIRECT_ARCHIVE)/Products/Applications/$(NAME).app" "$@"
	@echo "App extracted to $@"

$(OUTPUT_DIR)/$(NAME)-$(VERSION).dmg: $(OUTPUT_DIR)/$(NAME)-direct.app
	@echo "Creating DMG..."
	@mkdir -p "$(DMG_TMP_DIR)"
	@cp -R "$(OUTPUT_DIR)/$(NAME)-direct.app" "$(DMG_TMP_DIR)/$(NAME).app"
	@ln -s /Applications "$(DMG_TMP_DIR)/Applications"
	@hdiutil create -volname "$(DMG_VOLUME_NAME)" \
		-srcfolder "$(DMG_TMP_DIR)" \
		-ov -format UDZO -imagekey zlib-level=9 \
		"$(OUTPUT_DIR)/$(NAME)-$(VERSION).dmg"
	@$(RM) -r "$(DMG_TMP_DIR)"
	@$(RM) -r "$(OUTPUT_DIR)/$(NAME)-direct.app"
	@echo "DMG created: $(OUTPUT_DIR)/$(NAME)-$(VERSION).dmg"
	@echo "Verifying code signing..."
	@spctl -a -vv -t install "$(OUTPUT_DIR)/$(NAME)-$(VERSION).dmg" || true

# Build and package DMG (Direct distribution)
dmg: clean dist-clean $(OUTPUT_DIR)/$(NAME)-$(VERSION).dmg
.PHONY: dmg

# Build both App Store and Direct distribution packages
package: clean dist-clean
	@echo ""
	@echo "============================================"
	@echo "  Building App Store package..."
	@echo "============================================"
	$(MAKE) dist
	@mv "$(OUTPUT_DIR)/$(NAME)-$(VERSION).zip" "$(OUTPUT_DIR)/$(NAME)-$(VERSION)-store.zip"
	@mv "$(OUTPUT_DIR)/$(NAME).app" "$(OUTPUT_DIR)/$(NAME)-store.app"
	@echo ""
	@echo "============================================"
	@echo "  Building Direct DMG package..."
	@echo "============================================"
	$(MAKE) dmg
	@mv "$(OUTPUT_DIR)/$(NAME)-$(VERSION)-store.zip" "$(OUTPUT_DIR)/$(NAME)-$(VERSION).zip"
	@rm -f "$(OUTPUT_DIR)/$(NAME)-store.app"
	@echo ""
	@echo "============================================"
	@echo "  Package complete!"
	@echo "============================================"
	@echo "  App Store:  $(OUTPUT_DIR)/$(NAME)-$(VERSION).zip"
	@echo "  Direct:     $(OUTPUT_DIR)/$(NAME)-$(VERSION).dmg"
	@echo "============================================"
.PHONY: package
