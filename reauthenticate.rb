#!/usr/bin/env ruby

require_relative 'config/environment'
require_relative 'app/services/google_auth_service'

puts "🔄 Forcing Google API re-authentication..."
puts "=" * 50

# Remove existing tokens to force re-auth
token_file = Rails.root.join("config", "tokens.yaml")
if File.exist?(token_file)
  puts "🗑️ Removing existing tokens..."
  File.delete(token_file)
  puts "✅ Tokens removed"
else
  puts "ℹ️ No existing tokens found"
end

puts "\n🔐 Starting re-authentication process..."
puts "This will open your browser for authorization."
puts "Make sure to complete the authorization in your browser."

begin
  service = GoogleAuthService.authorize

  if service
    puts "\n✅ Re-authentication successful!"
    puts "🔧 Testing with a sample document..."

    # Test with a simple document
    test_doc_id = '1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms'
    begin
      doc = service.get_document(test_doc_id)
      puts "✅ Sample document access successful!"
      puts "📄 Document title: #{doc.title}"
    rescue StandardError => e
      puts "⚠️ Sample document still not accessible: #{e.message}"
      puts "💡 This might be normal if the sample document is private"
    end
  else
    puts "\n❌ Re-authentication failed!"
  end
rescue StandardError => e
  puts "\n❌ Error during re-authentication: #{e.message}"
end
