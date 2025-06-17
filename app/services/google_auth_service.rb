require "googleauth"
require "googleauth/stores/file_token_store"
require "google/apis/docs_v1"
require "fileutils"

class GoogleAuthService
  APPLICATION_NAME = "Grocery Sorter App".freeze
  CREDENTIALS_PATH = Rails.root.join("config", "client_secrets.json")
  TOKEN_PATH = Rails.root.join("config", "tokens.yaml")
  SCOPE = Google::Apis::DocsV1::AUTH_DOCUMENTS_READONLY

  def self.authorize
    begin
      client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
      token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
      authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
      user_id = "default"

      credentials = authorizer.get_credentials(user_id)
      return initialize_docs_service(credentials) if credentials

      url = authorizer.get_authorization_url(
        base_url: Google::Auth::InstalledAppFlow::OOB_URI
      )
      puts "1️⃣ Open this URL in your browser and authorize the app:"
      puts url
      print "2️⃣ Enter the code shown on the page: "
      code = gets.strip

      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id,
        code: code,
        base_url: Google::Auth::InstalledAppFlow::OOB_URI
      )

      initialize_docs_service(credentials)
    rescue StandardError => e
      puts "❌ Error during authorization: #{e.message}"
      nil
    end
  end

  def self.initialize_docs_service(credentials)
    # Initialize the Docs API client
    docs_service = Google::Apis::DocsV1::DocsService.new
    docs_service.authorization = credentials
    puts "✅ Google Docs API client initialized successfully."
    docs_service
  end
end
