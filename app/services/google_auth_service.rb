require "googleauth"
require "googleauth/stores/file_token_store"
require "google/apis/docs_v1"
require "fileutils"
require "webrick"

class GoogleAuthService
  APPLICATION_NAME = "Grocery Sorter App".freeze
  CREDENTIALS_PATH = Rails.root.join("config", "client_secrets.json")
  TOKEN_PATH = Rails.root.join("config", "tokens.yaml")
  # Expanded scope to include Drive access for better document access
  # Using exact scope strings from Google OAuth 2.0 documentation
  SCOPE = [
    "https://www.googleapis.com/auth/documents.readonly",
    "https://www.googleapis.com/auth/drive.readonly"
  ]
  REDIRECT_URI = "http://localhost:8080"

  def self.authorize
    begin
      client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
      token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
      # Pass scopes as array directly
      authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
      user_id = "default"

      credentials = authorizer.get_credentials(user_id)
      return credentials if credentials  # Return credentials, not the service

      # Use modern OAuth flow with local server
      puts "🌐 Starting OAuth flow..."
      puts "This will open your browser for authorization."

      # Start local server to handle OAuth callback
      server = start_oauth_server

      # Generate authorization URL with proper parameters for desktop apps
      url = authorizer.get_authorization_url(
        base_url: REDIRECT_URI,
        access_type: "offline",
        prompt: "consent"
      )

      puts "🔗 Opening browser for authorization..."
      puts "URL: #{url}"

      # Try different ways to open browser
      opened = system("open", url) || system("xdg-open", url) || system("start", url)
      unless opened
        puts "⚠️ Could not open browser automatically. Please copy and paste this URL:"
        puts url
      end

      # Wait for authorization code
      auth_code = wait_for_auth_code(server)

      if auth_code
        puts "✅ Authorization code received, exchanging for tokens..."
        credentials = authorizer.get_and_store_credentials_from_code(
          user_id: user_id,
          code: auth_code,
          base_url: REDIRECT_URI
        )

        puts "✅ Authorization successful!"
        puts "🔑 Access token obtained: #{credentials.access_token ? 'Yes' : 'No'}"
        puts "🔄 Refresh token obtained: #{credentials.refresh_token ? 'Yes' : 'No'}"

        credentials  # Return credentials, not the service
      else
        puts "❌ Authorization failed - no code received"
        puts "💡 Make sure you completed the authorization in your browser"
        nil
      end

    rescue StandardError => e
      puts "❌ Error during authorization: #{e.message}"
      puts "🔧 Error class: #{e.class}"
      puts "�� Make sure you have:"
      puts "   - Valid client_secrets.json in config/"
      puts "   - Internet connection"
      puts "   - Proper Google API permissions"
      puts "   - Redirect URI configured in Google Cloud Console"
      nil
    end
  end

  def self.start_oauth_server
    server = WEBrick::HTTPServer.new(Port: 8080)

    server.mount_proc("/") do |req, res|
      if req.query["code"]
        # Store the authorization code
        @auth_code = req.query["code"]

        res.status = 200
        res["Content-Type"] = "text/html"
        res.body = <<~HTML
          <html>
            <head><title>Authorization Successful</title><meta charset="UTF-8"></head>
            <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
              <h1 style="color: #34A853;">✅ Success!</h1>
              <p>You can close this window now.</p>
              <script>setTimeout(function() { window.close(); }, 3000);</script>
            </body>
          </html>
        HTML

        # Stop the server after receiving the code
        Thread.new { sleep(1); server.shutdown }
      elsif req.query["error"]
        @auth_code = nil
        res.status = 400
        res["Content-Type"] = "text/html"
        res.body = <<~HTML
          <html>
            <head><title>Authorization Failed</title><meta charset="UTF-8"></head>
            <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
              <h1 style="color: #EA4335;">❌ Authorization Failed</h1>
              <p>Error: #{req.query['error']}</p>
              <p>Please try again or check the terminal for more details.</p>
            </body>
          </html>
        HTML
      else
        res.status = 400
        res.body = "Invalid request"
      end
    end

    # Start server in background thread
    Thread.new { server.start }
    server
  end

  def self.wait_for_auth_code(server)
    timeout = 300 # 5 minutes
    start_time = Time.now

    while Time.now - start_time < timeout
      if @auth_code
        return @auth_code
      end
      sleep(1)
    end

    puts "⏰ Authorization timeout - no response received"
    puts "💡 Make sure you completed the authorization in your browser"
    nil
  end

  def self.initialize_docs_service(credentials)
    # Initialize the Docs API client
    docs_service = Google::Apis::DocsV1::DocsService.new
    docs_service.authorization = credentials
    docs_service.client_options.application_name = APPLICATION_NAME
    puts "✅ Google Docs API client initialized successfully."
    docs_service
  end

  def self.test_connection
    credentials = authorize
    if credentials
      puts "✅ Google API connection successful!"
      true
    else
      puts "❌ Google API connection failed!"
      false
    end
  end

  def self.debug_credentials
    begin
      client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
      token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
      # Pass scopes as array directly
      authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
      user_id = "default"

      credentials = authorizer.get_credentials(user_id)

      if credentials
        puts "🔍 Credential Debug Info:"
        puts "   Access Token: #{credentials.access_token ? 'Present' : 'Missing'}"
        puts "   Refresh Token: #{credentials.refresh_token ? 'Present' : 'Missing'}"
        puts "   Expires At: #{credentials.expires_at}"
        puts "   Issuer: #{credentials.issuer}"
        puts "   Scope: #{credentials.scope}"
        true
      else
        puts "❌ No credentials found"
        false
      end
    rescue StandardError => e
      puts "❌ Error debugging credentials: #{e.message}"
      false
    end
  end
end
