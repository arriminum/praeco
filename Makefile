# Variables
PROJECT_NAME := praeco
VERSION := $(shell cat VERSION)
DIST_DIR := dist
PKG_DIR := $(DIST_DIR)/$(PROJECT_NAME)
PKG_ZIP := $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION).zip

SRC_FILES := src/praeco src/praecomail src/.env-telegram.example
PKG_FILES := $(SRC_FILES) install.sh Makefile VERSION README.md LICENSE CHANGELOG.md docs

.PHONY: all help install lint dist clean version

all: help

help:
	@echo ""
	@echo "Usage:"
	@echo "  make install   Install praeco/praecomail on this machine (needs root)"
	@echo "  make lint      Run shellcheck over all scripts"
	@echo "  make dist      Build dist/$(PROJECT_NAME)-$(VERSION).zip for distribution"
	@echo "  make version   Print the current version"
	@echo "  make clean     Remove build artifacts"
	@echo ""

install:
	@echo "Starting installation of praeco..."
	@chmod +x install.sh
	@sudo ./install.sh
	@echo "Installation completed."

lint:
	shellcheck -s sh src/praeco src/praecomail install.sh

version:
	@cat VERSION

dist: lint
	@echo "Building $(PKG_ZIP)..."
	@rm -rf "$(PKG_DIR)" "$(DIST_DIR)"/*.zip
	@mkdir -p "$(PKG_DIR)/src" "$(PKG_DIR)/docs"
	@cp src/praeco src/praecomail src/.env-telegram.example "$(PKG_DIR)/src/"
	@cp install.sh Makefile VERSION README.md LICENSE CHANGELOG.md "$(PKG_DIR)/"
	@cp docs/*.md "$(PKG_DIR)/docs/"
	@mv "$(PKG_DIR)/src/praeco" "$(PKG_DIR)/src/praecomail" "$(PKG_DIR)/"
	@mv "$(PKG_DIR)/src/.env-telegram.example" "$(PKG_DIR)/"
	@rmdir "$(PKG_DIR)/src"
	@( cd "$(DIST_DIR)" && zip -qr "$(PROJECT_NAME)-$(VERSION).zip" "$(PROJECT_NAME)" )
	@rm -rf "$(PKG_DIR)"
	@echo "Created $(PKG_ZIP)"

clean:
	@rm -rf "$(DIST_DIR)"/*.zip "$(PKG_DIR)"
	@echo "Clean completed."
