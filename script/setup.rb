#!/usr/bin/env ruby

require 'fileutils'
require 'json'
require 'open-uri'
require 'net/http'

# Grocery Sorter App - Automated Setup Script
# This script handles the complete setup process for new users

class GrocerySorterSetup
  def initialize
    @config_dir = File.join(Dir.pwd, 'config')
    @client_secrets_path = File.join(@config_dir, 'client_secrets.json')
    @tokens_path = File.join(@config_dir, 'tokens.yaml')
    @example_path = File.join(@config_dir, 'client_secrets.example.json')
  end

  def run
    puts "🛒 Grocery Sorter App - Setup Wizard"
    puts "=" * 50

    # Step 1: Check if already configured
    if already_configured?
      puts "✅ App is already configured!"
      puts "   Run: ruby script/grocery_sorter.rb"
      return
    end

    # Step 2: Create config directory
    create_config_directory

    # Step 3: Handle Google API credentials
    setup_google_credentials

    # Step 4: Test the setup
    test_setup

    puts "\n🎉 Setup complete! You can now run:"
    puts "   ruby script/grocery_sorter.rb"
    puts "\n💡 Pro tip: The app will automatically create the credentials file"
    puts "   on first run if it doesn't exist, so you can also just run the app directly!"
  end

  private

  def already_configured?
    File.exist?(@client_secrets_path) && File.exist?(@tokens_path)
  end

  def create_config_directory
    unless Dir.exist?(@config_dir)
      puts "📁 Creating config directory..."
      Dir.mkdir(@config_dir)
    end
  end

  def setup_google_credentials
    puts "\n🔐 Google API Credentials Setup"
    puts "-" * 30

    if File.exist?(@client_secrets_path)
      puts "✅ Google credentials found"
      return
    end

    puts "📋 You need Google API credentials to use this app."
    puts "   This is a one-time setup process."

    choice = get_user_choice(
      "Choose an option:",
      [
        "1. I have credentials - let me paste them",
        "2. Help me get credentials from Google Cloud Console",
        "3. Use demo mode (limited functionality)"
      ]
    )

    case choice
    when "1"
      setup_with_existing_credentials
    when "2"
      help_get_credentials
    when "3"
      setup_demo_mode
    end
  end

  def setup_with_existing_credentials
    puts "\n📝 Please paste your Google API credentials JSON:"
    puts "   (Copy the entire JSON content from your downloaded file)"
    puts "   Press Enter twice when done:"

    lines = []
    while (line = gets.chomp) != ""
      lines << line
    end

    credentials_json = lines.join("\n")

    begin
      # Validate JSON
      JSON.parse(credentials_json)

      # Save to file
      File.write(@client_secrets_path, credentials_json)
      puts "✅ Credentials saved successfully!"

    rescue JSON::ParserError
      puts "❌ Invalid JSON format. Please try again."
      setup_with_existing_credentials
    end
  end

  def help_get_credentials
    puts "\n🌐 Getting Google API Credentials"
    puts "-" * 30
    puts "Follow these steps:"
    puts ""
    puts "1. Go to Google Cloud Console:"
    puts "   https://console.cloud.google.com/"
    puts ""
    puts "2. Create a new project or select existing one"
    puts ""
    puts "3. Enable the Google Docs API:"
    puts "   - Go to 'APIs & Services' > 'Library'"
    puts "   - Search for 'Google Docs API'"
    puts "   - Click 'Enable'"
    puts ""
    puts "4. Create OAuth 2.0 credentials:"
    puts "   - Go to 'APIs & Services' > 'Credentials'"
    puts "   - Click 'Create Credentials' > 'OAuth 2.0 Client IDs'"
    puts "   - Choose 'Desktop application'"
    puts "   - Download the JSON file"
    puts ""
    puts "5. Copy the JSON content and paste it when prompted"
    puts ""

    input = get_user_input("Press Enter when you have your credentials ready...")
    setup_with_existing_credentials
  end

  def setup_demo_mode
    puts "\n🎭 Setting up Demo Mode"
    puts "-" * 20
    puts "Demo mode will use a sample document for testing."
    puts "Limited functionality but no credentials required."

    # Create a minimal demo credentials file
    demo_credentials = {
      "installed" => {
        "client_id" => "demo-client-id.apps.googleusercontent.com",
        "project_id" => "demo-project",
        "auth_uri" => "https://accounts.google.com/o/oauth2/auth",
        "token_uri" => "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url" => "https://www.googleapis.com/oauth2/v1/certs",
        "client_secret" => "demo-secret",
        "redirect_uris" => [ "http://localhost" ]
      }
    }

    File.write(@client_secrets_path, JSON.pretty_generate(demo_credentials))
    puts "✅ Demo mode configured!"
    puts "   Note: You'll need real credentials for full functionality"
  end

  def test_setup
    puts "\n🧪 Testing Setup"
    puts "-" * 15

    unless File.exist?(@client_secrets_path)
      puts "❌ Google credentials not found"
      return false
    end

    begin
      credentials = JSON.parse(File.read(@client_secrets_path))
      if credentials["installed"] && credentials["installed"]["client_id"]
        puts "✅ Google credentials look valid"
        true
      else
        puts "❌ Invalid credentials format"
        false
      end
    rescue JSON::ParserError
      puts "❌ Invalid JSON in credentials file"
      false
    end
  end

  def get_user_choice(prompt, options)
    puts prompt
    options.each { |option| puts "   #{option}" }

    loop do
      choice = get_user_input("Enter your choice (1-#{options.length}): ")
      if (1..options.length).include?(choice.to_i)
        return choice
      end
      puts "❌ Invalid choice. Please try again."
    end
  end

  def get_user_input(prompt)
    print "#{prompt} "
    gets.chomp
  end
end

# Run the setup if this script is executed directly
if __FILE__ == $0
  setup = GrocerySorterSetup.new
  setup.run
end
