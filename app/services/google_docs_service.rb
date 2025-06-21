require "google/apis/docs_v1"

# GoogleDocsService handles communication with Google Docs API
# This service extracts grocery items from Google Docs documents
class GoogleDocsService
  # Alias for the Google Docs API namespace
  Docs = Google::Apis::DocsV1

  def initialize
    # Step 1: Initialize the Google Docs API client
    setup_docs_client

    # Step 2: Get OAuth credentials and apply them to the client
    apply_authorization

    # Step 3: Validate that our authorization is working
    validate_authorization
  end

  # Main method to extract grocery items from a Google Doc
  # Accepts either a document ID or full Google Docs URL
  def get_grocery_items(doc_input, user_email = nil)
    # Step 1: Extract the document ID from the input
    doc_id = extract_document_id(doc_input)

    # Step 2: Fetch the document from Google Docs API
    document = fetch_document(doc_id, user_email)
    return [] unless document

    # Step 3: Parse the document content to extract grocery items
    extract_items_from_document(document)
  end

  # Test if we can access a specific document
  def test_document_access(doc_input, user_email = nil)
    doc_id = extract_document_id(doc_input)

    begin
      document = @service.get_document(doc_id)
      {
        success: true,
        title: document.title,
        last_modified: document.modified_time,
        permission_id: document.permission_id
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

  # Provide helpful guidance when document access is unauthorized
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

  # Step 1: Set up the Google Docs API client
  def setup_docs_client
    @service = Docs::DocsService.new
    @service.client_options.application_name = GoogleAuthService::APPLICATION_NAME
  end

  # Step 2: Apply OAuth authorization to the API client
  def apply_authorization
    # Get OAuth credentials from the auth service
    credentials = GoogleAuthService.authorize

    # Apply the credentials to our API client
    @service.authorization = credentials
  end

  # Step 3: Validate that our authorization is working
  def validate_authorization
    # Check if we have valid credentials
    unless @service.authorization&.respond_to?(:access_token)
      puts "❌ Authorization object is invalid"
      return
    end

    # Check if access token is present
    unless @service.authorization.access_token
      puts "❌ No access token available"
      return
    end

    # Test with a public document to verify API access
    test_api_access
  end

  # Test API access with a known public document
  def test_api_access
    # Use Google's sample document for testing
    test_doc_id = "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms"

    begin
      result = @service.get_document(test_doc_id)
      puts "✅ Google Docs API access verified"
    rescue Google::Apis::AuthorizationError => e
      puts "❌ API authorization test failed: #{e.message}"
    rescue StandardError => e
      puts "⚠️ API test had other error: #{e.message}"
    end
  end

  # Step 1 of get_grocery_items: Extract document ID from various input formats
  def extract_document_id(input)
    # If input is already just an ID (no slashes or dots), return as-is
    return input if input.match?(/^[a-zA-Z0-9_-]+$/)

    # Define URL patterns to extract document ID from
    url_patterns = [
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

    # Try each pattern to extract the document ID
    url_patterns.each do |pattern|
      match = input.match(pattern)
      if match
        doc_id = match[1]
        return doc_id
      end
    end

    # If no pattern matches, assume it's already an ID
    input
  end

  # Step 2 of get_grocery_items: Fetch document from Google Docs API
  def fetch_document(doc_id, user_email = nil)
    # Provide helpful guidance if user email is provided
    if user_email
      puts "📧 Using email: #{user_email}"
      puts "💡 Make sure the document is shared with: #{user_email}"
    end

    # Make the API call to get the document
    document = @service.get_document(doc_id)

    puts "✅ Document fetched successfully: #{document.title}"

    document

  rescue Google::Apis::ClientError => e
    handle_api_error(e, doc_id, user_email)
    nil
  rescue StandardError => e
    handle_unexpected_error(e, doc_id)
    nil
  end

  # Step 3 of get_grocery_items: Parse document content to extract grocery items
  def extract_items_from_document(document)
    items = []

    # Check if document has content
    unless document.body&.content
      puts "⚠️ Document body is empty or nil"
      return items
    end

    # Iterate through each structural element in the document
    document.body.content.each do |element|
      # Only process paragraph elements (which contain text)
      next unless element.paragraph&.elements

      # Extract all text runs from the paragraph and join them together
      text = element.paragraph.elements.map do |text_element|
        text_element.text_run&.content
      end.compact.join.strip

      # Add non-empty text as a grocery item
      items << text unless text.empty?
    end

    puts "📝 Found #{items.length} items in document"

    items
  end

  # Handle Google API specific errors with helpful messages
  def handle_api_error(error, doc_id, user_email)
    puts "❌ Google API Error: #{error.message}"

    case error.message
    when /404/
      puts "💡 Document not found. Check the document ID and permissions."
    when /403/
      puts "💡 Access denied. Make sure the document is shared with your Google account."
      if user_email
        puts "   🔗 Share with: #{user_email}"
      end
      puts "   🔗 Document URL: https://docs.google.com/document/d/#{doc_id}/edit"
    when /401/
      puts "💡 Authentication failed. You may need to re-authenticate."
      puts "   🔄 Run: ruby reauthenticate.rb"
    end
  end

  # Handle unexpected errors with debugging information
  def handle_unexpected_error(error, doc_id)
    puts "❌ Unexpected error: #{error.message}"
    puts "🔧 Error class: #{error.class}"
    puts "🔍 Error details: #{error.inspect}"
    puts "🔍 Error backtrace: #{error.backtrace.first(5)}"
  end
end
