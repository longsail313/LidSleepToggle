APP_NAME := LidSleepToggle
BUILD_DIR := .build
SOURCES := $(wildcard Sources/*.m)
HEADERS := $(wildcard Sources/*.h)
CLANG := xcrun --sdk macosx clang
COMMON_FLAGS := -fobjc-arc -Wall -Wextra -mmacosx-version-min=13.0 -I Sources
FRAMEWORKS := -framework Cocoa

.PHONY: all release test clean

all: $(BUILD_DIR)/$(APP_NAME)

$(BUILD_DIR)/$(APP_NAME): $(SOURCES) $(HEADERS)
	mkdir -p $(BUILD_DIR)
	$(CLANG) $(COMMON_FLAGS) -g $(SOURCES) $(FRAMEWORKS) -o $@

release: $(BUILD_DIR)/release/$(APP_NAME)

$(BUILD_DIR)/release/$(APP_NAME): $(SOURCES) $(HEADERS)
	mkdir -p $(BUILD_DIR)/release
	$(CLANG) $(COMMON_FLAGS) -O2 -arch arm64 -arch x86_64 $(SOURCES) $(FRAMEWORKS) -o $@

test: $(BUILD_DIR)/PowerStatusParserTests
	$(BUILD_DIR)/PowerStatusParserTests

$(BUILD_DIR)/PowerStatusParserTests: Tests/PowerStatusParserTests.m Sources/PowerStatusParser.m Sources/PowerStatusParser.h
	mkdir -p $(BUILD_DIR)
	$(CLANG) $(COMMON_FLAGS) Tests/PowerStatusParserTests.m Sources/PowerStatusParser.m -framework Foundation -o $@

clean:
	rm -rf $(BUILD_DIR) dist
