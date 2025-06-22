# Linux Installation Guide

This guide provides detailed instructions for installing the Grocery Sorter App on various Linux distributions.

## Supported Distributions

- **Ubuntu/Debian** (apt package manager)
- **Fedora/RHEL/CentOS** (dnf/yum package manager)
- **Arch Linux** (pacman package manager)
- **Other distributions** with manual Ruby installation

## Quick Installation

### Step 1: Get the App

**Option A: Download from GitHub (Easiest)**
1. Go to the [GitHub repository](https://github.com/MatthewJamisonJS/Grocery_Sorter_App)
2. Click the green "Code" button
3. Click "Download ZIP"
4. Extract the ZIP file to a folder on your computer
5. Open Terminal and navigate to the extracted folder

**Option B: Clone with Git (For developers)**
```bash
# Clone the repository
git clone https://github.com/MatthewJamisonJS/Grocery_Sorter_App.git

# Navigate into the project folder
cd Grocery_Sorter_App
```

### Step 2: Install and Run

#### Option 1: One-Command Setup (Recommended)

Once you're in the project folder:

```bash
# Make the launcher executable and run
chmod +x grocery_sorter
./grocery_sorter
```

The app will automatically:
- ✅ Check if setup is needed
- 🔧 Run the setup wizard if it's your first time
- 🚀 Launch the application
- 📋 Guide you through Google API setup (if needed)

#### Option 2: Using Make

```bash
# Quick start with automatic dependency installation
make quickstart

# Or step by step:
make deps      # Install system dependencies
make setup     # Run setup wizard
make install   # Install system-wide
```

#### Option 3: Using Install Script

```bash
# Make executable and run
chmod +x install.sh
./install.sh

# Or uninstall later
./install.sh uninstall
```

## Distribution-Specific Instructions

### Ubuntu/Debian

```bash
# Update package list
sudo apt-get update

# Install Ruby and development tools
sudo apt-get install -y ruby ruby-dev build-essential git curl

# Install Bundler
gem install bundler

# Install Ruby gems
bundle install

# Run setup and install
ruby script/setup.rb
sudo cp grocery_sorter /usr/local/bin/
```

### Fedora/RHEL/CentOS

```bash
# Update package list
sudo dnf update

# Install Ruby and development tools
sudo dnf install -y ruby ruby-devel gcc git curl

# Install Bundler
gem install bundler

# Install Ruby gems
bundle install

# Run setup and install
ruby script/setup.rb
sudo cp grocery_sorter /usr/local/bin/
```

### Arch Linux

```bash
# Update package list
sudo pacman -Sy

# Install Ruby and development tools
sudo pacman -S ruby base-devel git curl

# Install Bundler
gem install bundler

# Install Ruby gems
bundle install

# Run setup and install
ruby script/setup.rb
sudo cp grocery_sorter /usr/local/bin/
```

### Other Distributions

For distributions not listed above:

1. **Install Ruby manually**:
   - Download from [ruby-lang.org](https://www.ruby-lang.org/en/documentation/installation/)
   - Or use a Ruby version manager like `rbenv` or `rvm`

2. **Install development tools**:
   ```bash
   # For most distributions
   sudo [package-manager] install build-essential gcc git curl
   ```

3. **Install Bundler and gems**:
   ```bash
   gem install bundler
   bundle install
   ```

4. **Run setup**:
   ```bash
   ruby script/setup.rb
   sudo cp grocery_sorter /usr/local/bin/
   ```

## Using Ruby Version Managers

### rbenv (Recommended)

```bash
# Install rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/main/bin/rbenv-installer | bash

# Add to shell profile
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Install Ruby
rbenv install 3.3.6
rbenv global 3.3.6

# Install Bundler
gem install bundler

# Install gems
bundle install
```

### RVM

```bash
# Install RVM
curl -sSL https://get.rvm.io | bash -s stable

# Reload shell
source ~/.rvm/scripts/rvm

# Install Ruby
rvm install 3.3.6
rvm use 3.3.6 --default

# Install Bundler
gem install bundler

# Install gems
bundle install
```

## Troubleshooting

### Common Issues

#### Ruby Not Found
```bash
# Check if Ruby is installed
ruby --version

# If not found, install via package manager
sudo apt-get install ruby  # Ubuntu/Debian
sudo dnf install ruby      # Fedora/RHEL
sudo pacman -S ruby        # Arch
```

#### Permission Denied
```bash
# Ensure you have sudo access
sudo whoami

# If installing to /usr/local/bin, ensure directory exists
sudo mkdir -p /usr/local/bin
```

#### Missing Dependencies
```bash
# Install build tools
sudo apt-get install build-essential  # Ubuntu/Debian
sudo dnf install gcc                  # Fedora/RHEL
sudo pacman -S base-devel             # Arch
```

#### Bundler Issues
```bash
# Install Bundler
gem install bundler

# If you get permission errors, install for current user
gem install --user-install bundler
```

#### Gem Installation Issues
```bash
# Clear gem cache
gem cleanup

# Reinstall gems
bundle install --clean
```

### Distribution-Specific Issues

#### Ubuntu/Debian
- **Old Ruby version**: Use `rbenv` or `rvm` to install newer Ruby
- **Missing headers**: Install `ruby-dev` package
- **Permission issues**: Use `gem install --user-install`

#### Fedora/RHEL
- **SELinux issues**: Temporarily disable SELinux or configure policies
- **Missing development tools**: Install `gcc` and `ruby-devel`
- **Firewall issues**: Configure firewall for Ollama if using AI features

#### Arch Linux
- **AUR packages**: Consider using `yay` or `paru` for additional packages
- **System updates**: Keep system updated with `sudo pacman -Syu`
- **Ruby conflicts**: Use `rbenv` to manage multiple Ruby versions

## Development Setup

For developers who want to contribute:

```bash
# Clone repository
git clone https://github.com/yourusername/grocery_sorter_app.git
cd grocery_sorter_app

# Setup development environment
make dev

# Run tests
make test

# Run app
make run
```

## Uninstalling

### Remove App
```bash
# Using Make
make uninstall

# Using install script
./install.sh uninstall

# Manual removal
sudo rm -f /usr/local/bin/grocery_sorter
```

### Remove Dependencies (Optional)
```bash
# Remove Ruby gems
bundle clean --force

# Remove Ruby (if installed via package manager)
sudo apt-get remove ruby ruby-dev  # Ubuntu/Debian
sudo dnf remove ruby ruby-devel    # Fedora/RHEL
sudo pacman -R ruby                # Arch
```

## Support

If you encounter issues:

1. Check the [main README.md](README.md) for general troubleshooting
2. Review the [SECURITY.md](SECURITY.md) for credential-related issues
3. Open an issue on GitHub with your distribution and error details
4. Check the [Makefile](Makefile) for available commands

## Contributing to Linux Support

To improve Linux support:

1. Test on your distribution
2. Update this guide with distribution-specific notes
3. Submit pull requests with improvements
4. Report issues with specific error messages and system information 