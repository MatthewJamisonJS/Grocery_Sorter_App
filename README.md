# Grocery Sorter App

A desktop application built with Glimmer DSL for LibUI that helps you organize grocery lists by automatically categorizing items into store aisles using AI.

## Features

- 🛒 **Grocery List Management**: Add items manually or import from Google Docs
- 🤖 **AI-Powered Categorization**: Uses Ollama to intelligently sort items into store aisles
- 📄 **Google Docs Integration**: Import grocery lists directly from Google Docs
- 💾 **Export Functionality**: Save categorized lists as JSON files
- 🖥️ **Cross-Platform Desktop App**: Built with Glimmer DSL for LibUI

## Prerequisites

- Ruby 3.0+
- Google Cloud Project with Google Docs API enabled
- Ollama installed and running locally

## Quick Start

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

## Detailed Setup

### Google API Setup

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

4. **Configure the App**:
   - Save the downloaded JSON as `config/client_secrets.json`
   - The app will handle authentication on first run

### Ollama Setup

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

```bash
ruby script/grocery_sorter.rb
```

### Features

- **Test Connections**: Verify Google API and Ollama are working
- **Load from Google Docs**: Import grocery lists using a document ID
- **Manual Entry**: Add items one by one
- **AI Categorization**: Automatically sort items into store aisles
- **Export**: Save categorized lists as JSON files

### Google Docs Integration

1. Create a Google Doc with your grocery list (one item per line)
2. Copy the document ID from the URL
3. Paste it into the "Document ID" field
4. Click "Load from Google Docs"

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
- **Invalid Credentials**: Check that `client_secrets.json` is properly formatted

### Ollama Issues

- **Connection Failed**: Make sure Ollama is running (`ollama serve`)
- **Model Not Found**: Pull the required model (`ollama pull llama2`)
- **Slow Responses**: Consider using a smaller model or upgrading hardware

### General Issues

- **Missing Dependencies**: Run `bundle install`
- **Permission Errors**: Ensure you have write access to the config directory
- **Network Issues**: Check your internet connection for Google API calls

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
│   └── setup.rb                    # Setup and testing script
└── config/
    ├── client_secrets.json         # Google API credentials
    └── tokens.yaml                 # Google API tokens
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
