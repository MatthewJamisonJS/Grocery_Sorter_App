#!/usr/bin/env ruby

require_relative 'config/environment'
require_relative 'app/services/google_auth_service'

puts "🔍 OAuth Debug Script"
puts "=" * 50

# Step 1: Check if credentials file exists
puts "\n1️⃣ Checking credentials file..."
if File.exist?('config/client_secrets.json')
  puts "✅ client_secrets.json found"
  begin
    client_secrets = JSON.parse(File.read('config/client_secrets.json'))
    puts "✅ JSON is valid"
    puts "   Client ID: #{client_secrets['installed']['client_id']}"
    puts "   Project ID: #{client_secrets['installed']['project_id']}"
  rescue JSON::ParserError => e
    puts "❌ Invalid JSON in client_secrets.json: #{e.message}"
    exit 1
  end
else
  puts "❌ client_secrets.json not found"
  exit 1
end

# Step 2: Check existing tokens
puts "\n2️⃣ Checking existing tokens..."
if File.exist?('config/tokens.yaml')
  puts "✅ tokens.yaml found"
  GoogleAuthService.debug_credentials
else
  puts "ℹ️ No existing tokens found - will need to authenticate"
end

# Step 3: Test Google API connection
puts "\n3️⃣ Testing Google API connection..."
if GoogleAuthService.test_connection
  puts "✅ Google API connection successful!"
else
  puts "❌ Google API connection failed!"
  puts "\n💡 This might be due to:"
  puts "   - Missing or invalid OAuth credentials"
  puts "   - Incorrect redirect URI configuration"
  puts "   - Network connectivity issues"
  puts "   - Google Cloud Console configuration issues"
end

# Step 4: Test document access (if connection successful)
puts "\n4️⃣ Testing document access..."
test_doc_id = '10RXduuaONZeKLAkaJrjL4T38IWXhyePpOtGQuFO021o'
test_url = 'https://docs.google.com/document/d/10RXduuaONZeKLAkaJrjL4T38IWXhyePpOtGQuFO021o/edit?usp=sharing'

begin
  service = GoogleDocsService.new
  result = service.test_document_access(test_url)

  if result[:success]
    puts "✅ Document access successful!"
    puts "   Title: #{result[:title]}"
    puts "   Last Modified: #{result[:last_modified]}"
  else
    puts "❌ Document access failed: #{result[:error]}"
    puts "   Error Class: #{result[:error_class]}"

    if result[:error].include?('Unauthorized')
      puts "\n💡 Unauthorized error suggests:"
      puts "   - Document is not shared with your Google account"
      puts "   - OAuth scope is insufficient"
      puts "   - Token is expired or invalid"
    end
  end
rescue StandardError => e
  puts "❌ Error testing document access: #{e.message}"
end

puts "\n🔧 Debug complete!"
puts "If you're still having issues, check:"
puts "1. Google Cloud Console OAuth configuration"
puts "2. Redirect URI settings (should include http://localhost:8080)"
puts "3. Document sharing permissions"
puts "4. OAuth consent screen configuration"
