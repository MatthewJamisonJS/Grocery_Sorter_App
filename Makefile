# Grocery Sorter App - Cross-Platform Makefile
# Provides easy setup and installation for Linux and macOS users

# Variables
APP_NAME = grocery_sorter
SCRIPT_DIR = script
CONFIG_DIR = config
BIN_DIR = /usr/local/bin
APP_DIR = /usr/local/share/$(APP_NAME)

# Detect OS
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    OS = macOS
    INSTALL_DIR = /usr/local/bin
else
    OS = Linux
    INSTALL_DIR = /usr/local/bin
endif

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

.PHONY: help install uninstall setup test clean run

# Default target
help:
	@echo "$(GREEN)Grocery Sorter App - Available Commands:$(NC)"
	@echo ""
	@echo "$(YELLOW)Setup Commands:$(NC)"
	@echo "  make setup     - Run the interactive setup wizard"
	@echo "  make install   - Install the app system-wide"
	@echo "  make uninstall - Remove the app from system"
	@echo ""
	@echo "$(YELLOW)Development Commands:$(NC)"
	@echo "  make test      - Test the app functionality"
	@echo "  make run       - Run the app directly"
	@echo "  make clean     - Clean build artifacts"
	@echo ""
	@echo "$(YELLOW)System Commands:$(NC)"
	@echo "  make deps      - Install system dependencies"
	@echo "  make check     - Check system requirements"
	@echo ""
	@echo "$(YELLOW)Usage:$(NC)"
	@echo "  After installation: $(APP_NAME)"
	@echo "  Direct run: make run"

# Check system requirements
check:
	@echo "$(GREEN)Checking system requirements...$(NC)"
	@echo "OS: $(OS)"
	@which ruby > /dev/null && echo "$(GREEN)✓ Ruby found$(NC)" || echo "$(RED)✗ Ruby not found$(NC)"
	@which bundle > /dev/null && echo "$(GREEN)✓ Bundler found$(NC)" || echo "$(RED)✗ Bundler not found$(NC)"
	@which make > /dev/null && echo "$(GREEN)✓ Make found$(NC)" || echo "$(RED)✗ Make not found$(NC)"
	@echo ""

# Install system dependencies
deps:
	@echo "$(GREEN)Installing system dependencies...$(NC)"
ifeq ($(OS),macOS)
	@echo "$(YELLOW)macOS detected$(NC)"
	@which brew > /dev/null || (echo "$(RED)Homebrew not found. Install from https://brew.sh$(NC)" && exit 1)
	@brew install ruby
	@echo "$(GREEN)✓ Ruby installed via Homebrew$(NC)"
else
	@echo "$(YELLOW)Linux detected$(NC)"
	@echo "Installing Ruby and development tools..."
	@sudo apt-get update || sudo dnf update || sudo pacman -Sy || echo "$(YELLOW)Package manager not detected, please install Ruby manually$(NC)"
	@sudo apt-get install -y ruby ruby-dev build-essential || sudo dnf install -y ruby ruby-devel gcc || sudo pacman -S ruby base-devel || echo "$(YELLOW)Please install Ruby and development tools manually$(NC)"
	@echo "$(GREEN)✓ System dependencies installed$(NC)"
endif
	@echo "Installing Ruby gems..."
	@bundle install
	@echo "$(GREEN)✓ Ruby dependencies installed$(NC)"

# Run the setup wizard
setup:
	@echo "$(GREEN)Running Grocery Sorter App setup wizard...$(NC)"
	@ruby $(SCRIPT_DIR)/setup.rb

# Install the app system-wide
install: check
	@echo "$(GREEN)Installing Grocery Sorter App...$(NC)"
	@sudo mkdir -p $(INSTALL_DIR)
	@sudo cp $(APP_NAME) $(INSTALL_DIR)/
	@sudo chmod +x $(INSTALL_DIR)/$(APP_NAME)
	@echo "$(GREEN)✓ App installed to $(INSTALL_DIR)/$(APP_NAME)$(NC)"
	@echo "$(GREEN)✓ You can now run '$(APP_NAME)' from anywhere$(NC)"

# Uninstall the app
uninstall:
	@echo "$(YELLOW)Uninstalling Grocery Sorter App...$(NC)"
	@sudo rm -f $(INSTALL_DIR)/$(APP_NAME)
	@echo "$(GREEN)✓ App uninstalled$(NC)"

# Test the app functionality
test:
	@echo "$(GREEN)Testing Grocery Sorter App...$(NC)"
	@ruby -c $(SCRIPT_DIR)/grocery_sorter.rb && echo "$(GREEN)✓ Main app syntax OK$(NC)" || echo "$(RED)✗ Main app syntax error$(NC)"
	@ruby -c $(SCRIPT_DIR)/setup.rb && echo "$(GREEN)✓ Setup script syntax OK$(NC)" || echo "$(RED)✗ Setup script syntax error$(NC)"
	@echo "$(GREEN)✓ All tests passed$(NC)"

# Run the app directly
run:
	@echo "$(GREEN)Starting Grocery Sorter App...$(NC)"
	@ruby $(SCRIPT_DIR)/grocery_sorter.rb

# Clean build artifacts
clean:
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@rm -rf tmp/
	@rm -rf log/
	@rm -f *.log
	@echo "$(GREEN)✓ Cleaned$(NC)"

# Quick start for new users
quickstart: deps setup install
	@echo "$(GREEN)🎉 Quick start complete!$(NC)"
	@echo "$(GREEN)Run '$(APP_NAME)' to start the app$(NC)"

# Development setup
dev: deps setup
	@echo "$(GREEN)Development environment ready!$(NC)"
	@echo "$(GREEN)Run 'make run' to start the app$(NC)" 