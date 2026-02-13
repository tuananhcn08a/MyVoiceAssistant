.PHONY: build app install run clean dmg

APP_NAME := MyVoiceAssistant
BUILD_DIR := build

# Build release binary
build:
	swift build -c release

# Create .app bundle
app:
	@chmod +x Scripts/build-app.sh
	@Scripts/build-app.sh

# Install .app to /Applications
install: app
	@echo "==> Installing to /Applications..."
	@cp -R "$(BUILD_DIR)/$(APP_NAME).app" /Applications/
	@echo "==> Installed $(APP_NAME).app to /Applications"

# Build and run (debug)
run:
	swift run $(APP_NAME)

# Clean build artifacts
clean:
	swift package clean
	rm -rf $(BUILD_DIR)

# Create DMG for distribution (placeholder)
dmg: app
	@echo "TODO: Create DMG with create-dmg or hdiutil"
	@echo "For now, use: make app && cp -R build/$(APP_NAME).app /Applications/"
