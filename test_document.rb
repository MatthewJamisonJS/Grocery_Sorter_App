#!/usr/bin/env ruby

require_relative 'config/environment'
require_relative 'app/services/google_docs_service'

# Test the specific document
doc_id = '1-Sc5-suRy_aakkH-A86kBP234NpaxXpt6ihiacS_mW4'

puts "🔍 Testing document access for: #{doc_id}"
puts "=" * 50

service = GoogleDocsService.new

# Test basic access
puts "\n📋 Testing document access..."
result = service.test_document_access(doc_id)

if result[:success]
  puts "✅ SUCCESS!"
  puts "   Title: #{result[:title]}"
  puts "   Last Modified: #{result[:last_modified]}"
  puts "   Permission ID: #{result[:permission_id]}"

  # Try to get content
  puts "\n📝 Testing content extraction..."
  items = service.get_grocery_items(doc_id)

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

  puts "\n💡 Troubleshooting tips:"
  puts "   1. Make sure the document is shared with your Google account"
  puts "   2. Check that the document ID is correct"
  puts "   3. Ensure the document is not deleted or moved"
  puts "   4. Try accessing the document in your browser first"
end
