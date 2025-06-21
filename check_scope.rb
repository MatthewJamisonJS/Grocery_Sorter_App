#!/usr/bin/env ruby

require_relative 'config/environment'
require_relative 'app/services/google_auth_service'

puts "🔍 Checking OAuth Scope and Permissions"
puts "=" * 40

# Check current scope
current_scope = Google::Apis::DocsV1::AUTH_DOCUMENTS_READONLY
puts "📋 Current scope: #{current_scope}"

# List available scopes
puts "\n📚 Available Google Docs scopes:"
puts "   - #{Google::Apis::DocsV1::AUTH_DOCUMENTS_READONLY} (current)"
puts "   - #{Google::Apis::DocsV1::AUTH_DOCUMENTS}"
puts "   - https://www.googleapis.com/auth/drive.readonly"
puts "   - https://www.googleapis.com/auth/drive"

# Check if we need to expand scope
puts "\n💡 For better document access, we might need:"
puts "   - Drive scope to access documents by URL"
puts "   - Full documents scope for editing capabilities"

# Test with current credentials
puts "\n🔍 Testing current credentials..."
begin
  client_id = Google::Auth::ClientId.from_file(Rails.root.join("config", "client_secrets.json"))
  token_store = Google::Auth::Stores::FileTokenStore.new(file: Rails.root.join("config", "tokens.yaml"))
  authorizer = Google::Auth::UserAuthorizer.new(current_scope, client_id, token_store)

  credentials = authorizer.get_credentials("default")

  if credentials
    puts "✅ Credentials found"
    puts "   Scope: #{credentials.scope}"
    puts "   Issuer: #{credentials.issuer || 'Not set'}"
    puts "   Expires: #{credentials.expires_at}"

    # Test if we can access the document with current scope
    puts "\n🧪 Testing document access with current scope..."
    service = Google::Apis::DocsV1::DocsService.new
    service.authorization = credentials

    begin
      doc = service.get_document('10RXduuaONZeKLAkaJrjL4T38IWXhyePpOtGQuFO021o')
      puts "✅ Document access successful with current scope!"
      puts "   Title: #{doc.title}"
    rescue Google::Apis::ClientError => e
      puts "❌ Document access failed: #{e.message}"
      puts "💡 This might indicate a scope issue"
    end
  else
    puts "❌ No credentials found"
  end
rescue StandardError => e
  puts "❌ Error: #{e.message}"
end

puts "\n🔧 Recommendations:"
puts "1. Try re-authenticating with expanded scope"
puts "2. Check if the document is in a shared drive"
puts "3. Verify the document ID is correct"
puts "4. Check Google Cloud Console OAuth settings"
