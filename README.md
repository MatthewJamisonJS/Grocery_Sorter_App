# Grocery Sorter App

A cross-platform desktop application built with Glimmer DSL for LibUI that helps you organize grocery lists by automatically categorizing items into store aisles using AI.

## 🚨 Current Iteration Status

**This iteration focuses on core Ollama AI functionality without Google OAuth integration.**

- ✅ **Core AI Categorization**: Fully functional with Ollama
- ✅ **Clipboard Integration**: Paste grocery lists directly
- ✅ **PDF Export**: Generate categorized reports
- ✅ **Enhanced Fallback**: Works even when Ollama is unavailable
- ⏸️ **Google Docs Integration**: Temporarily disabled (see TODO comments)

## Features

- 🛒 **Grocery List Management**: Add items manually via clipboard paste
- 🤖 **AI-Powered Categorization**: Uses Ollama to intelligently sort items into store aisles
- 📋 **Clipboard Integration**: Paste grocery lists directly from any source
- 💾 **Export Functionality**: Save categorized lists as JSON files and PDF reports
- 🖥️ **Cross-Platform Desktop App**: Built with Glimmer DSL for LibUI (macOS & Linux)
- 🚀 **One-Command Setup**: Automatic setup wizard for new users
- 🔧 **Easy Installation**: Makefile and install scripts for both platforms
- 🔒 **Enhanced Security**: Built-in protection against Ollama vulnerabilities
- 🧠 **RAG-Powered Processing**: Uses embeddings for faster, more accurate categorization
- 🛡️ **Robust Fallback**: Enhanced rule-based categorization when AI is unavailable

## Prerequisites

- Ruby 3.0+
- Ollama installed and running locally (optional - enhanced fallback available)

## 🔒 Security Features

This application includes comprehensive security measures to protect against known Ollama vulnerabilities:

### Built-in Security
- **Host Validation**: Only allows localhost connections to Ollama
- **Rate Limiting**: Prevents API abuse with configurable limits
- **Timeout Protection**: Prevents hanging connections
- **Secure Headers**: Proper User-Agent and authentication headers
- **RAG Processing**: Reduces API calls with embedding-based categorization

### Security Setup

**Quick Security Setup:**
```bash
# Run the security setup script
ruby script/setup_secure_ollama.rb
```

**Manual Security Configuration:**
1. **Run Ollama locally only:**
   ```bash
   ollama serve --host 127.0.0.1:11434
   ```

2. **Set up firewall rules:**
   ```bash
   # macOS
   sudo pfctl -e
   echo "block drop in proto tcp from any to any port 11434" | sudo pfctl -f -
   
   # Linux
   sudo iptables -A INPUT -p tcp --dport 11434 -s 127.0.0.1 -j ACCEPT
   sudo iptables -A INPUT -p tcp --dport 11434 -j DROP
   ```

3. **Configure API key:**
   ```bash
   export OLLAMA_API_KEY="your-secure-api-key-here"
   ```

**For detailed security documentation, see:**
- [Security Configuration Guide](config/ollama_security.md)
- [Ollama Security Best Practices](https://github.com/ollama/ollama/blob/main/docs/security.md)

## 🚀 Quick Start (Recommended)

### Step 1: Get the App

**Option A: Download from GitHub (Easiest)**
1. Go to the [GitHub repository](https://github.com/MatthewJamisonJS/Grocery_Sorter_App)
2. Click the green "Code" button
3. Click "Download ZIP"
4. Extract the ZIP file to a folder on your computer
5. Open Terminal/Command Prompt and navigate to the extracted folder

**Option B: Clone with Git (For developers)**
```bash
# Clone the repository
git clone https://github.com/MatthewJamisonJS/Grocery_Sorter_App.git

# Navigate into the project folder
cd Grocery_Sorter_App
```

### Step 2: Run the App

**macOS & Linux - One Command Setup**

Once you're in the project folder, just run:

```bash
./grocery_sorter
```

The app will automatically:
- ✅ Check if setup is needed
- 🔧 Run the setup wizard if it's your first time
- 🔒 Configure security settings for Ollama
- 🚀 Launch the application
- 📋 Ready for clipboard paste functionality

**If you get a permission error, make the script executable:**
```bash
chmod +x grocery_sorter
./grocery_sorter
```

### Linux - Alternative Installation Methods

#### Option 1: Using Make (Recommended)
```bash
# Quick start with automatic dependency installation
make quickstart

# Or step by step:
make deps      # Install system dependencies
make setup     # Run setup wizard
make install   # Install system-wide
```

#### Option 2: Using Install Script
```bash
# Make executable and run
chmod +x install.sh
./install.sh

# Or uninstall later
./install.sh uninstall
```

#### Option 3: Manual Installation
```bash
# Install Ruby and dependencies
sudo apt-get update && sudo apt-get install -y ruby ruby-dev build-essential  # Ubuntu/Debian
sudo dnf install -y ruby ruby-devel gcc  # Fedora/RHEL
sudo pacman -S ruby base-devel  # Arch Linux

# Install Ruby gems
bundle install

# Run setup and install
ruby script/setup.rb
sudo cp grocery_sorter /usr/local/bin/
```

### macOS - Alternative Installation

#### Using Homebrew (Recommended)
```bash
# Install Ruby via Homebrew
brew install ruby

# Install Ruby gems
bundle install

# Run setup and install
ruby script/setup.rb
sudo cp grocery_sorter /usr/local/bin/
```

#### Using Make
```bash
# Quick start
make quickstart

# Or step by step:
make deps      # Install Ruby via Homebrew
make setup     # Run setup wizard
make install   # Install system-wide
```

## Setup Options

The setup wizard offers three options:

### 1. **I have credentials** (Recommended)
- Paste your existing Google API credentials
- Full functionality immediately

### 2. **Help me get credentials**
- Step-by-step guide to Google Cloud Console
- Automatic credential validation

### 3. **Demo mode**
- No credentials required
- Limited functionality for testing
- Perfect for trying out the app

## Ollama Setup (Optional)

For AI categorization features:

1. **Install Ollama**:
   - Download from [ollama.ai](https://ollama.ai/download)
   - Follow installation instructions for your platform

2. **Start Ollama Securely**:
   ```bash
   # Secure localhost-only binding
   ollama serve --host 127.0.0.1:11434
   ```

3. **Pull a Model**:
   ```bash
   ollama pull llama2
   ```

4. **Configure Security** (Recommended):
   ```bash
   # Run the security setup script
   ruby script/setup_secure_ollama.rb
   ```

## Usage

### Starting the Application

**Simple way:**
```bash
./grocery_sorter
```

**After installation:**
```bash
grocery_sorter
```

**Manual way:**
```bash
ruby script/grocery_sorter.rb
```

**Using Make:**
```bash
make run
```

### Features

- **Clipboard Integration**: Paste grocery lists directly from any source
- **AI Categorization**: Automatically sort items into store aisles
- **Enhanced Fallback**: Rule-based categorization when AI is unavailable
- **Export**: Save categorized lists as JSON files and PDF reports

### Clipboard Integration

1. Copy your grocery list from any source (text, notes, etc.)
2. Click "Load from Clipboard" in the app
3. The app will automatically categorize all items
4. View results in the table and download PDF reports

### AI Categorization

The app uses Ollama to intelligently categorize grocery items into common store aisles:

- Produce (fruits, vegetables)
- Dairy & Eggs (milk, cheese, yogurt)
- Meat & Seafood
- Bakery (bread, pastries)
- Pantry (canned goods, pasta, rice)
- Frozen Foods
- Beverages
- Snacks
- Condiments & Sauces
- Household & Cleaning
- Health & Beauty
- Electronics
- General Merchandise

## Troubleshooting

### Ollama Connection Issues

**"Wrong Status Line" or Streaming Errors:**
- The app now uses non-streaming requests by default for better reliability
- If you see streaming errors, they're automatically handled with fallback categorization

**"Connection Failed" or Timeout Errors:**
```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# Start Ollama if not running
ollama serve

# Test with a simple model
ollama pull llama2:7b
```

**Server Restart Detection:**
- The app automatically detects when Ollama server restarts
- Wait 10-15 seconds for the server to stabilize after restart
- The app will retry automatically

### Enhanced Fallback System

**When Ollama is unavailable:**
- The app automatically switches to enhanced rule-based categorization
- No internet connection required
- Works with common grocery items
- Results are still accurate for most items

### PDF Generation Issues

**"Font Not Found" Errors:**
- Font files are included in `vendor/assets/fonts/`
- If you get font errors, ensure the font files exist:
```bash
ls -la vendor/assets/fonts/
# Should show: DejaVuSans.ttf and DejaVuSans-Bold.ttf
```

### General Issues

**"Ruby Not Found" or Version Issues:**
```bash
# Check Ruby version
ruby --version

# Install via Homebrew (macOS)
brew install ruby

# Install via package manager (Linux)
sudo apt-get install ruby ruby-dev  # Ubuntu/Debian
sudo dnf install ruby ruby-devel    # Fedora/RHEL
```

**"Bundle Install" Errors:**
```bash
# Install bundler first
gem install bundler

# Then install dependencies
bundle install
```

**Permission Issues:**
```bash
# Make scripts executable
chmod +x grocery_sorter
chmod +x install.sh

# Fix directory permissions
chmod 755 app/config/
```

**Performance Issues:**
- The app uses enhanced fallback categorization when Ollama is unavailable
- Consider using a smaller model: `ollama pull llama2:7b`
- Reduce batch size in the OllamaService configuration

## Development

### Available Make Commands

```bash
make help       # Show all available commands
make check      # Check system requirements
make deps       # Install system dependencies
make setup      # Run setup wizard
make install    # Install app system-wide
make uninstall  # Remove app from system
make test       # Test app functionality
make run        # Run app directly
make clean      # Clean build artifacts
make dev        # Setup development environment
make quickstart # Complete setup and installation
```

### Project Structure

```
grocery_sorter_app/
├── app/services/
│   ├── ollama_service.rb           # Ollama AI integration (ACTIVE)
│   ├── google_auth_service.rb      # Google API authentication (DISABLED)
│   └── google_docs_service.rb      # Google Docs integration (DISABLED)
├── script/
│   ├── grocery_sorter.rb           # Main Glimmer application
│   └── setup.rb                    # Automated setup wizard
├── grocery_sorter                  # Smart launcher script
├── install.sh                      # Linux installation script
├── Makefile                        # Cross-platform build system
└── config/
    ├── client_secrets.example.json # Example credentials file
    ├── client_secrets.json         # Google API credentials (DISABLED)
    └── tokens.yaml                 # Google API tokens (DISABLED)
```

### Adding New Features

1. **New AI Models**: Modify `OllamaService` to support different models
2. **Additional APIs**: Create new service classes following the existing pattern
3. **UI Enhancements**: Extend the Glimmer DSL interface in `grocery_sorter.rb`

## TODO: Google Docs Integration

**Status**: Temporarily disabled for this iteration

**To restore Google Docs functionality:**
1. Uncomment Google-related requires in `script/grocery_sorter.rb`
2. Uncomment Google Docs UI elements
3. Fix OAuth authentication issues
4. Test with valid Google API credentials

**Files to modify:**
- `script/grocery_sorter.rb` (uncomment Google imports and UI)
- `app/services/google_auth_service.rb` (fix OAuth flow)
- `app/services/google_docs_service.rb` (verify API integration)

## Security

This app handles sensitive Google API credentials. See [SECURITY.md](SECURITY.md) for important security information.

**Key security points:**
- ✅ Credentials are stored locally only
- ✅ No credentials are sent to external servers
- ✅ OAuth tokens are encrypted
- ❌ Never commit credentials to version control

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Acknowledgments

- [Glimmer DSL for LibUI](https://github.com/AndyObtiva/glimmer-dsl-libui) - Desktop GUI framework
- [Ollama](https://ollama.ai) - Local AI inference
