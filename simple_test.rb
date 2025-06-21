#!/usr/bin/env ruby

require_relative 'config/environment'
require_relative 'app/services/google_auth_service'

puts "🧪 Simple Google Docs Test"
puts "=" * 30

begin
  # Test basic service initialization
  puts "1️⃣ Testing service initialization..."
  service = Google::Apis::DocsV1::DocsService.new
  service.authorization = GoogleAuthService.authorize

  if service.authorization
    puts "✅ Service initialized with authorization"
  else
    puts "❌ No authorization found"
    exit 1
  end

  # Test with a simple, known public document
  puts "\n2️⃣ Testing with a simple document..."
  test_doc_id = '1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms'

  begin
    doc = service.get_document(test_doc_id)
    puts "✅ Document access successful!"
    puts "   Title: #{doc.title}"
    puts "   Document ID: #{doc.document_id}"
  rescue Google::Apis::ClientError => e
    puts "❌ Document access failed: #{e.message}"
    puts "   This might be expected for this sample document"
  end

  # Test with your document
  puts "\n3️⃣ Testing with your document..."
  your_doc_id = '10RXduuaONZeKLAkaJrjL4T38IWXhyePpOtGQuFO021o'

  begin
    doc = service.get_document(your_doc_id)
    puts "✅ Your document access successful!"
    puts "   Title: #{doc.title}"
    puts "   Document ID: #{doc.document_id}"

    # Try to get content
    if doc.body&.content
      items = []
      doc.body.content.each do |element|
        next unless element.paragraph&.elements
        text = element.paragraph.elements.map { |e| e.text_run&.content }.compact.join.strip
        items << text unless text.empty?
      end
      puts "   Found #{items.length} items:"
      items.each_with_index { |item, i| puts "     #{i+1}. #{item}" }
    else
      puts "   No content found"
    end

  rescue Google::Apis::ClientError => e
    puts "❌ Your document access failed: #{e.message}"
    puts "   Error class: #{e.class}"
  end

rescue StandardError => e
  puts "❌ General error: #{e.message}"
  puts "   Error class: #{e.class}"
end

puts "\n🎉 Test complete!"
