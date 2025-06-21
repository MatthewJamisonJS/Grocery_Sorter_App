#!/usr/bin/env ruby

require 'colorize'

# Load Rails environment
require_relative '../config/environment'

require_relative '../app/services/google_auth_service'
require_relative '../app/services/ollama_service'

class Setup
  def self.run
    puts "🔧 Grocery Sorter App Setup".colorize(:cyan)
    puts "=" * 50

    setup_google_api
    setup_ollama
    test_integration

    puts "\n🎉 Setup complete! You can now run:"
    puts "   ruby script/grocery_sorter.rb"
  end

  private

  def self.setup_google_api
    puts "\n📋 Google API Setup".colorize(:yellow)
    puts "-" * 30

    if File.exist?('config/client_secrets.json')
      puts "✅ client_secrets.json found"

      if File.exist?('config/tokens.yaml')
        puts "✅ tokens.yaml found"
        puts "🔄 Testing Google API connection..."

        if GoogleAuthService.test_connection
          puts "✅ Google API is ready!"
        else
          puts "❌ Google API connection failed"
          puts "💡 You may need to re-authenticate"
        end
      else
        puts "⚠️ tokens.yaml not found"
        puts "💡 Run the app to authenticate with Google"
      end
    else
      puts "❌ client_secrets.json not found"
      puts "💡 Download from Google Cloud Console:"
      puts "   1. Go to https://console.cloud.google.com"
      puts "   2. Create a project or select existing"
      puts "   3. Enable Google Docs API"
      puts "   4. Create credentials (OAuth 2.0 Client ID)"
      puts "   5. Download JSON and save as config/client_secrets.json"
    end
  end

  def self.setup_ollama
    puts "\n🤖 Ollama Setup".colorize(:yellow)
    puts "-" * 30

    ollama_service = OllamaService.new

    if ollama_service.test_connection
      puts "✅ Ollama is running and accessible"
    else
      puts "❌ Ollama connection failed"
      puts "💡 Install and start Ollama:"
      puts "   1. Install: https://ollama.ai/download"
      puts "   2. Start: ollama serve"
      puts "   3. Pull a model: ollama pull llama2"
    end
  end

  def self.test_integration
    puts "\n🧪 Integration Test".colorize(:yellow)
    puts "-" * 30

    # Test Ollama with sample data
    ollama_service = OllamaService.new
    sample_items = [ 'Milk', 'Apples', 'Bread' ]

    begin
      result = ollama_service.categorize_grocery_items(sample_items)
      puts "✅ Ollama categorization test successful"
      puts "   Sample result: #{result.first}"
    rescue StandardError => e
      puts "❌ Ollama test failed: #{e.message}"
    end
  end
end

if __FILE__ == $0
  Setup.run
end
