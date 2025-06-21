# Grocery Sorter App

A desktop application built with Glimmer DSL for LibUI that helps you organize grocery lists by automatically categorizing items into store aisles using AI.

## Features

- 🛒 **Grocery List Management**: Add items manually or import from Google Docs
- 🤖 **AI-Powered Categorization**: Uses Ollama to intelligently sort items into store aisles
- 📄 **Google Docs Integration**: Import grocery lists directly from Google Docs
- 💾 **Export Functionality**: Save categorized lists as JSON files
- 🖥️ **Cross-Platform Desktop App**: Built with Glimmer DSL for LibUI
- 🚀 **One-Command Setup**: Automatic setup wizard for new users

## Prerequisites

- Ruby 3.0+
- Google Cloud Project with Google Docs API enabled (optional - demo mode available)
- Ollama installed and running locally (optional - for AI categorization)

## 🚀 Quick Start (Recommended)

**Just run one command and follow the setup wizard:**

```bash
./grocery_sorter
```

The app will automatically:
- ✅ Check if setup is needed
- 🔧 Run the setup wizard if it's your first time
- 🚀 Launch the application
- 📋 Guide you through Google API setup (if needed)

## Alternative Setup

If you prefer manual setup:

1. **Install dependencies**:
   ```bash
   bundle install
   ```

2. **Run the setup script**:
   ```bash
   ruby script/setup.rb
   ```

3. **Start the application**:
   ```bash
   ruby script/grocery_sorter.rb
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

## Google API Setup (Optional)

If you want full Google Docs integration:

1. **Create a Google Cloud Project**:
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Create a new project or select an existing one

2. **Enable Google Docs API**:
   - Navigate to "APIs & Services" > "Library"
   - Search for "Google Docs API"
   - Click "Enable"

3. **Create OAuth 2.0 Credentials**:
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth 2.0 Client IDs"
   - Choose "Desktop application"
   - Download the JSON file

4. **Use the setup wizard**:
   - Run `./grocery_sorter`
   - Choose option 1 or 2
   - Paste your credentials when prompted

## Ollama Setup (Optional)

For AI categorization features:

1. **Install Ollama**:
   - Download from [ollama.ai](https://ollama.ai/download)
   - Follow installation instructions for your platform

2. **Start Ollama**:
   ```bash
   ollama serve
   ```

3. **Pull a Model**:
   ```bash
   ollama pull llama2
   ```

## Usage

### Starting the Application

**Simple way:**
```bash
./grocery_sorter
```

**Manual way:**
```bash
ruby script/grocery_sorter.rb
```

### Features

- **Test Connections**: Verify Google API and Ollama are working
- **Load from Google Docs**: Import grocery lists using a document URL or ID
- **Manual Entry**: Add items one by one
- **AI Categorization**: Automatically sort items into store aisles
- **Export**: Save categorized lists as JSON files

### Google Docs Integration

1. Create a Google Doc with your grocery list (one item per line)
2. Copy the document URL or ID
3. Paste it into the "Document URL or ID" field
4. Enter your Google email
5. Click "Load from Google Docs"

### AI Categorization

The app uses Ollama to intelligently categorize grocery items into common store aisles:

- Produce (fruits, vegetables)
- Dairy (milk, cheese, yogurt)
- Meat & Seafood
- Bakery (bread, pastries)
- Pantry (canned goods, pasta, rice)
- Frozen Foods
- Beverages
- Snacks
- Condiments & Sauces
- Household & Cleaning

## Troubleshooting

### Google API Issues

- **Authentication Error**: Run the app and follow the authentication flow
- **Permission Denied**: Ensure Google Docs API is enabled in your project
- **Invalid Credentials**: Use the setup wizard to re-enter credentials

### Ollama Issues

- **Connection Failed**: Make sure Ollama is running (`ollama serve`)
- **Model Not Found**: Pull the required model (`ollama pull llama2`)
- **Slow Responses**: Consider using a smaller model or upgrading hardware

### General Issues

- **Missing Dependencies**: Run `bundle install`
- **Permission Errors**: Ensure you have write access to the config directory
- **Network Issues**: Check your internet connection for Google API calls

## Security

This app handles sensitive Google API credentials. See [SECURITY.md](SECURITY.md) for important security information.

**Key security points:**
- ✅ Credentials are stored locally only
- ✅ No credentials are sent to external servers
- ✅ OAuth tokens are encrypted
- ❌ Never commit credentials to version control

## Development

### Project Structure

```
grocery_sorter_app/
├── app/services/
│   ├── google_auth_service.rb      # Google API authentication
│   ├── google_docs_service.rb      # Google Docs integration
│   └── ollama_service.rb           # Ollama AI integration
├── script/
│   ├── grocery_sorter.rb           # Main Glimmer application
│   └── setup.rb                    # Automated setup wizard
├── grocery_sorter                  # Smart launcher script
└── config/
    ├── client_secrets.example.json # Example credentials file
    ├── client_secrets.json         # Google API credentials (user-provided)
    └── tokens.yaml                 # Google API tokens (auto-generated)
```

### Adding New Features

1. **New AI Models**: Modify `OllamaService` to support different models
2. **Additional APIs**: Create new service classes following the existing pattern
3. **UI Enhancements**: Extend the Glimmer DSL interface in `grocery_sorter.rb`

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
- [Google Docs API](https://developers.google.com/workspace/docs/api) - Document integration
- [Ollama](https://ollama.ai) - Local AI inference
