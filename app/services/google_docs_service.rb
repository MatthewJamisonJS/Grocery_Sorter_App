require "google/apis/docs_v1"

class GoogleDocsService
  Docs = Google::Apis::DocsV1

  def initialize
    @service = Docs::DocsService.new
    @service.client_options.application_name = GoogleAuthService::APPLICATION_NAME

    # Get the authorization credentials first
    credentials = GoogleAuthService.authorize
    puts "🔍 DEBUG: Credentials class: #{credentials.class}"
    puts "🔍 DEBUG: Credentials access token: #{credentials.access_token ? 'Present' : 'Missing'}"

    # Set the authorization properly
    @service.authorization = credentials
    puts "🔍 DEBUG: Service authorization set to: #{@service.authorization.class}"

    # Ensure the authorization is properly applied
    ensure_authorization_valid
  end

  def get_grocery_items(doc_input, user_email = nil)
    # Extract document ID from URL or use as-is if it's already an ID
    doc_id = extract_document_id(doc_input)

    begin
      puts "🔍 Attempting to fetch document: #{doc_id}"
      puts "🔍 DEBUG: Service authorization: #{@service.authorization.class}"
      puts "🔍 DEBUG: Authorization object: #{@service.authorization.inspect}"

      # If user email is provided, give specific guidance
      if user_email
        puts "📧 Using email: #{user_email}"
        puts "💡 Make sure the document is shared with: #{user_email}"
      end

      # Add detailed debugging before the API call
      puts "🔍 DEBUG: About to call @service.get_document(#{doc_id})"

      doc = @service.get_document(doc_id)

      puts "✅ Document fetched successfully"
      puts "📄 Document title: #{doc.title}"
      puts "🔍 DEBUG: Document object: #{doc.inspect}"

      items = []

      if doc.body&.content
        doc.body.content.each do |element|
          next unless element.paragraph&.elements

          # Extract all text runs in the paragraph and join them together
          text = element.paragraph.elements.map do |e|
            e.text_run&.content
          end.compact.join.strip

          items << text unless text.empty?
        end

        puts "📝 Found #{items.length} items in document"
        items.each_with_index { |item, i| puts "   #{i+1}. #{item}" }
      else
        puts "⚠️ Document body is empty or nil"
      end

      items
    rescue Google::Apis::ClientError => e
      puts "❌ Google API Client Error: #{e.message}"
      puts "🔍 DEBUG: Full error details: #{e.inspect}"
      case e.message
      when /404/
        puts "💡 Document not found. Check the document ID and permissions."
      when /403/
        puts "💡 Access denied. Make sure the document is shared with your Google account."
        if user_email
          puts "   📧 Share with: #{user_email}"
        end
        puts "   🔗 Document URL: https://docs.google.com/document/d/#{doc_id}/edit"
      when /401/
        puts "💡 Authentication failed. You may need to re-authenticate."
        puts "   🔄 Run: ruby reauthenticate.rb"
      end
      []
    rescue StandardError => e
      puts "❌ Unexpected error: #{e.message}"
      puts "🔧 Error class: #{e.class}"
      puts "🔍 DEBUG: Full error details: #{e.inspect}"
      puts "🔍 DEBUG: Error backtrace: #{e.backtrace.first(5)}"
      []
    end
  end

  def test_document_access(doc_input, user_email = nil)
    doc_id = extract_document_id(doc_input)

    begin
      puts "🔍 DEBUG: About to call get_document with ID: #{doc_id}"
      puts "🔍 DEBUG: Service authorization: #{@service.authorization.class}"

      # If user email is provided, give specific guidance
      if user_email
        puts "📧 Using email: #{user_email}"
        puts "💡 Make sure the document is shared with: #{user_email}"
      end

      doc = @service.get_document(doc_id)
      {
        success: true,
        title: doc.title,
        last_modified: doc.modified_time,
        permission_id: doc.permission_id
      }
    rescue Google::Apis::ClientError => e
      {
        success: false,
        error: e.message,
        error_class: e.class.to_s,
        user_email: user_email,
        doc_id: doc_id
      }
    rescue StandardError => e
      {
        success: false,
        error: e.message,
        error_class: e.class.to_s,
        user_email: user_email,
        doc_id: doc_id
      }
    end
  end

  def get_user_guidance_for_unauthorized(result)
    return unless result[:error]&.include?("Unauthorized")

    puts "\n🔧 Troubleshooting Steps:"
    puts "1. Open your Google Doc in the browser"
    puts "2. Click 'Share' in the top right corner"
    puts "3. Add this email as a viewer: #{result[:user_email] || 'your OAuth account email'}"
    puts "4. Save the sharing settings"
    puts "5. Try again"

    if result[:doc_id]
      puts "\n🔗 Direct link to share:"
      puts "https://docs.google.com/document/d/#{result[:doc_id]}/edit"
    end
  end

  private

  def extract_document_id(input)
    # If it's already just an ID (no slashes or dots), return as-is
    return input if input.match?(/^[a-zA-Z0-9_-]+$/)

    # Try to extract from Google Docs URL
    patterns = [
      # Standard Google Docs URL
      %r{https://docs\.google\.com/document/d/([a-zA-Z0-9_-]+)},
      # Google Docs URL with additional parameters
      %r{https://docs\.google\.com/document/d/([a-zA-Z0-9_-]+)/edit},
      %r{https://docs\.google\.com/document/d/([a-zA-Z0-9_-]+)/view},
      # Drive URL format
      %r{https://drive\.google\.com/file/d/([a-zA-Z0-9_-]+)},
      # Any URL with document ID pattern
      %r{/d/([a-zA-Z0-9_-]+)}
    ]

    patterns.each do |pattern|
      match = input.match(pattern)
      if match
        doc_id = match[1]
        puts "🔗 Extracted document ID: #{doc_id} from URL"
        return doc_id
      end
    end

    # If no pattern matches, assume it's already an ID
    puts "ℹ️ No URL pattern found, using input as document ID"
    input
  end

  def ensure_authorization_valid
    begin
      puts "🔍 DEBUG: Validating authorization..."

      # Check if we have valid credentials
      unless @service.authorization && @service.authorization.respond_to?(:access_token)
        puts "❌ Authorization object is invalid"
        return
      end

      # Check if access token is present
      unless @service.authorization.access_token
        puts "❌ No access token available"
        return
      end

      puts "✅ Authorization appears valid"

      # Test with a simple API call to a public document
      test_document_access
    rescue StandardError => e
      puts "❌ Authorization validation failed: #{e.message}"
    end
  end

  def test_document_access
    begin
      puts "🔍 DEBUG: Testing API access with public document..."
      # Use a known public document for testing
      test_doc_id = "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms"
      result = @service.get_document(test_doc_id)
      puts "✅ API access test successful - Document: #{result.title}"
    rescue Google::Apis::AuthorizationError => e
      puts "❌ API authorization test failed: #{e.message}"
      puts "🔧 This indicates the authorization isn't being applied correctly to API calls"
    rescue StandardError => e
      puts "⚠️ API test had other error: #{e.message}"
    end
  end
end
