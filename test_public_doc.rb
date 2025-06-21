#!/usr/bin/env ruby

require_relative 'config/environment'
require_relative 'app/services/google_docs_service'

# Test the public document
public_doc_url = 'https://docs.google.com/document/d/10RXduuaONZeKLAkaJrjL4T38IWXhyePpOtGQuFO021o/edit?usp=sharing'

puts "🔍 Testing public document access..."
puts "URL: #{public_doc_url}"
puts "=" * 50

service = GoogleDocsService.new

# Test basic access
puts "\n📋 Testing document access..."
result = service.test_document_access(public_doc_url)

if result[:success]
  puts "✅ SUCCESS!"
  puts "   Title: #{result[:title]}"
  puts "   Last Modified: #{result[:last_modified]}"
  puts "   Permission ID: #{result[:permission_id]}"

  # Try to get content
  puts "\n📝 Testing content extraction..."
  items = service.get_grocery_items(public_doc_url)

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
end
