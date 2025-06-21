#!/bin/bash

# Grocery Sorter App - Linux Installation Script
# Supports Ubuntu/Debian, Fedora/RHEL, and Arch Linux

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to detect package manager
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v yum &> /dev/null; then
        echo "yum"
    else
        echo "unknown"
    fi
}

# Function to install dependencies based on package manager
install_dependencies() {
    local pkg_manager=$(detect_package_manager)
    
    print_status "Detected package manager: $pkg_manager"
    
    case $pkg_manager in
        "apt")
            print_status "Installing dependencies via apt..."
            sudo apt-get update
            sudo apt-get install -y ruby ruby-dev build-essential git curl
            ;;
        "dnf")
            print_status "Installing dependencies via dnf..."
            sudo dnf update
            sudo dnf install -y ruby ruby-devel gcc git curl
            ;;
        "pacman")
            print_status "Installing dependencies via pacman..."
            sudo pacman -Sy
            sudo pacman -S ruby base-devel git curl
            ;;
        "yum")
            print_status "Installing dependencies via yum..."
            sudo yum update
            sudo yum install -y ruby ruby-devel gcc git curl
            ;;
        *)
            print_error "Unsupported package manager. Please install Ruby manually."
            exit 1
            ;;
    esac
    
    print_status "Installing Ruby gems..."
    bundle install
}

# Function to install the app
install_app() {
    local install_dir="/usr/local/bin"
    local app_name="grocery_sorter"
    
    print_status "Installing Grocery Sorter App..."
    
    # Create installation directory if it doesn't exist
    sudo mkdir -p "$install_dir"
    
    # Copy the launcher script
    sudo cp "$app_name" "$install_dir/"
    sudo chmod +x "$install_dir/$app_name"
    
    print_status "✓ App installed to $install_dir/$app_name"
    print_status "✓ You can now run '$app_name' from anywhere"
}

# Function to run setup wizard
run_setup() {
    print_status "Running setup wizard..."
    ruby script/setup.rb
}

# Function to check if Ruby is installed
check_ruby() {
    if ! command -v ruby &> /dev/null; then
        print_error "Ruby is not installed."
        return 1
    fi
    
    local ruby_version=$(ruby -v | cut -d' ' -f2 | cut -d'p' -f1)
    print_status "Found Ruby version: $ruby_version"
    
    # Check if Ruby version is 3.0 or higher
    if [[ $(echo "$ruby_version 3.0" | tr " " "\n" | sort -V | head -n 1) != "3.0" ]]; then
        print_warning "Ruby version $ruby_version detected. Version 3.0+ is recommended."
    fi
    
    return 0
}

# Function to check if Bundler is installed
check_bundler() {
    if ! command -v bundle &> /dev/null; then
        print_warning "Bundler not found. Installing..."
        gem install bundler
    fi
}

# Main installation function
main() {
    echo "🛒 Grocery Sorter App - Linux Installer"
    echo "======================================"
    echo ""
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root."
        exit 1
    fi
    
    # Check Ruby installation
    if ! check_ruby; then
        print_status "Installing Ruby..."
        install_dependencies
    else
        print_status "Ruby is already installed."
    fi
    
    # Check Bundler
    check_bundler
    
    # Install Ruby gems
    print_status "Installing Ruby dependencies..."
    bundle install
    
    # Install the app
    install_app
    
    # Run setup wizard
    echo ""
    print_status "Installation complete! Running setup wizard..."
    run_setup
    
    echo ""
    print_status "🎉 Installation and setup complete!"
    echo ""
    echo "You can now run the app with:"
    echo "  grocery_sorter"
    echo ""
    echo "Or run it directly with:"
    echo "  make run"
    echo ""
    echo "For help, run:"
    echo "  make help"
}

# Function to uninstall
uninstall() {
    print_status "Uninstalling Grocery Sorter App..."
    sudo rm -f /usr/local/bin/grocery_sorter
    print_status "✓ App uninstalled"
}

# Parse command line arguments
case "${1:-}" in
    "uninstall")
        uninstall
        ;;
    "help"|"-h"|"--help")
        echo "Grocery Sorter App - Linux Installer"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no args)  - Install the app"
        echo "  uninstall  - Remove the app"
        echo "  help       - Show this help"
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Run '$0 help' for usage information."
        exit 1
        ;;
esac 