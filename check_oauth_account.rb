#!/usr/bin/env ruby

require_relative 'config/environment'
require_relative 'app/services/google_auth_service'

puts "🔍 Checking OAuth Account"
puts "=" * 30

begin
  client_id = Google::Auth::ClientId.from_file(Rails.root.join("config", "client_secrets.json"))
  token_store = Google::Auth::Stores::FileTokenStore.new(file: Rails.root.join("config", "tokens.yaml"))
  authorizer = Google::Auth::UserAuthorizer.new(Google::Apis::DocsV1::AUTH_DOCUMENTS_READONLY, client_id, token_store)

  credentials = authorizer.get_credentials("default")

  if credentials
    puts "✅ OAuth Account Information:"
    puts "   Access Token: #{credentials.access_token ? 'Present' : 'Missing'}"
    puts "   Refresh Token: #{credentials.refresh_token ? 'Present' : 'Missing'}"
    puts "   Expires At: #{credentials.expires_at}"
    puts "   Issuer: #{credentials.issuer || 'Not set'}"
    puts "   Scope: #{credentials.scope}"

    # Try to get user info from the token
    if credentials.access_token
      puts "\n🔍 Attempting to get user info from token..."
      # The issuer field should contain the email, but if not, we can try other methods
      puts "   Note: Share your document with the account that appears in the OAuth consent screen"
    end
  else
    puts "❌ No credentials found"
  end
rescue StandardError => e
  puts "❌ Error: #{e.message}"
end
