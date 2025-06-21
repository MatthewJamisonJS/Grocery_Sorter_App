#!/usr/bin/env ruby

require_relative 'config/environment'
require_relative 'app/services/google_docs_service'

puts "🧪 Testing Google Docs with Email Authentication"
puts "=" * 50

# Test parameters
test_url = 'https://docs.google.com/document/d/10RXduuaONZeKLAkaJrjL4T38IWXhyePpOtGQuFO021o/edit?usp=sharing'

puts "\n📧 Please enter your Google email (the one you used for OAuth):"
print "Email: "
user_email = gets.strip

if user_email.empty?
  puts "❌ No email provided. Exiting."
  exit 1
end

puts "\n🔍 Testing with email: #{user_email}"
puts "URL: #{test_url}"

service = GoogleDocsService.new

# Test document access
puts "\n📋 Testing document access..."
result = service.test_document_access(test_url, user_email)

if result[:success]
  puts "✅ SUCCESS!"
  puts "   Title: #{result[:title]}"
  puts "   Last Modified: #{result[:last_modified]}"

  # Try to get content
  puts "\n📝 Testing content extraction..."
  items = service.get_grocery_items(test_url, user_email)

  if items.any?
    puts "✅ Content extracted successfully!"
    puts "   Found #{items.length} items:"
    items.each_with_index { |item, i| puts "   #{i+1}. #{item}" }
  else
    puts "⚠️ No content found in document"
  end
else
  puts "❌ FAILED!"
  puts "   Error: #{result[:error]}"
  puts "   Error Class: #{result[:error_class]}"

  # Show troubleshooting steps
  service.get_user_guidance_for_unauthorized(result)
end

puts "\n🎉 Test complete!"
