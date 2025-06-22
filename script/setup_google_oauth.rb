#!/usr/bin/env ruby

require "fileutils"
require "json"

class GoogleOAuthSetup
  def initialize
    @config_dir = File.join(Dir.pwd, 'app', 'config')
    @client_secrets_path = File.join(@config_dir, 'client_secrets.json')
  end

  def run
    puts "🔐 Google OAuth Setup for Grocery Sorter App"
    puts "=" * 50

    if already_configured?
      puts "✅ Google OAuth appears to be already configured."
      puts "📁 Config file: #{@client_secrets_path}"
      return
    end

    puts "❌ Google OAuth is not properly configured."
    puts "🔧 Let's set it up now..."

    setup_instructions
  end

  private

  def already_configured?
    return false unless File.exist?(@client_secrets_path)

    begin
      config = JSON.parse(File.read(@client_secrets_path))
      client_secret = config.dig("installed", "client_secret")
      return false if client_secret.nil? || client_secret.include?("REPLACE_WITH_YOUR_ACTUAL_CLIENT_SECRET")
      true
    rescue JSON::ParserError
      false
    end
  end

  def setup_instructions
    puts "\n📋 Google OAuth Setup Instructions:"
    puts "1. Go to https://console.cloud.google.com/"
    puts "2. Create a new project or select an existing one"
    puts "3. Enable the Google Docs API and Google Drive API"
    puts "4. Go to 'Credentials' → 'Create Credentials' → 'OAuth 2.0 Client IDs'"
    puts "5. Choose 'Desktop application' as the application type"
    puts "6. Download the JSON file"
    puts "7. Replace the contents of #{@client_secrets_path} with the downloaded JSON"

    puts "\n🔑 Required APIs to enable:"
    puts "   - Google Docs API"
    puts "   - Google Drive API"

    puts "\n🌐 Redirect URI to configure:"
    puts "   - http://localhost:8080"

    puts "\n📝 After downloading the credentials JSON:"
    puts "1. Open #{@client_secrets_path}"
    puts "2. Replace the entire content with your downloaded JSON"
    puts "3. Save the file"
    puts "4. Run the app again"

    puts "\n💡 The app will automatically handle the OAuth flow when you first try to access a Google Doc."
  end
end

if __FILE__ == $0
  GoogleOAuthSetup.new.run
end
