require "googleauth"
require "googleauth/stores/file_token_store"
require "google/apis/docs_v1"
require "fileutils"
require "webrick"
require "pathname"

# GoogleAuthService handles OAuth 2.0 authentication with Google APIs
# This service manages the complete OAuth flow including token storage and refresh
class GoogleAuthService
  # Application configuration constants
  APPLICATION_NAME = "Grocery Sorter App".freeze

  # Flexible path resolution that works both in Rails and standalone
  def self.root_path
    defined?(Rails) ? Rails.root : Pathname.new(File.expand_path("../..", __FILE__))
  end

  CREDENTIALS_PATH = root_path.join("config", "client_secrets.json")
  TOKEN_PATH = root_path.join("config", "tokens.yaml")
  REDIRECT_URI = "http://localhost:8080"

  # OAuth scopes define what permissions our app needs
  # We need read-only access to both Google Docs and Google Drive
  SCOPE = [
    "https://www.googleapis.com/auth/documents.readonly",  # Read Google Docs
    "https://www.googleapis.com/auth/drive.readonly"       # Read Google Drive files
  ].freeze

  # Main entry point for OAuth authentication
  # Returns Google::Auth::UserRefreshCredentials object if successful
  def self.authorize
    status, msg = validate_credentials!
    puts msg
    case status
    when :created
      raise "Credentials file created. Please fill it in and restart."
    when :invalid
      raise "Credentials file invalid. Please fix it and restart."
    end
    setup_oauth_client
    credentials = get_existing_credentials
    return credentials if credentials
    perform_oauth_flow
  end

  # --- Credential File Management ---

  # Ensures the credentials file exists. Returns :created or :exists.
  def self.ensure_credentials_file_exists!
    if File.exist?(CREDENTIALS_PATH)
      :exists
    else
      write_example_credentials_file!
      :created
    end
  end

  # Writes an example credentials file for the user to fill in
  def self.write_example_credentials_file!
    FileUtils.mkdir_p(CREDENTIALS_PATH.dirname)
    example_content = {
      "installed" => {
        "client_id" => "YOUR_CLIENT_ID_HERE",
        "project_id" => "your-project-id",
        "auth_uri" => "https://accounts.google.com/o/oauth2/auth",
        "token_uri" => "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url" => "https://www.googleapis.com/oauth2/v1/certs",
        "client_secret" => "YOUR_CLIENT_SECRET_HERE",
        "redirect_uris" => [ "http://localhost:8080" ]
      }
    }
    File.write(CREDENTIALS_PATH, JSON.pretty_generate(example_content))
  end

  # Checks if the credentials file is valid JSON and has required keys
  def self.valid_credentials_file?
    return false unless File.exist?(CREDENTIALS_PATH)
    content = File.read(CREDENTIALS_PATH)
    json = JSON.parse(content) rescue nil
    return false unless json && json["installed"]
    keys = %w[client_id client_secret auth_uri token_uri redirect_uris]
    keys.all? { |k| json["installed"].key?(k) && !json["installed"][k].to_s.strip.empty? }
  rescue
    false
  end

  # Validates credentials file, returns [:created|:invalid|:valid, message]
  def self.validate_credentials!
    status = ensure_credentials_file_exists!
    if status == :created
      [ :created, "📝 Created example credentials file at #{CREDENTIALS_PATH}. Please fill it in with your Google API credentials." ]
    elsif !valid_credentials_file?
      [ :invalid, "❌ Credentials file at #{CREDENTIALS_PATH} is invalid or incomplete. Please check and update it." ]
    else
      [ :valid, "✅ Credentials file is present and valid." ]
    end
  end

  # Test if we can successfully connect to Google APIs
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

  # Debug helper to inspect current credentials
  def self.debug_credentials
    credentials = get_existing_credentials
    return false unless credentials

    puts "🔍 Credential Debug Info:"
    puts "   Access Token: #{credentials.access_token ? 'Present' : 'Missing'}"
    puts "   Refresh Token: #{credentials.refresh_token ? 'Present' : 'Missing'}"
    puts "   Expires At: #{credentials.expires_at}"
    puts "   Scope: #{credentials.scope}"
    true
  end

  private

  # Step 2: Initialize OAuth client components
  def self.setup_oauth_client
    # Check if credentials file exists and has valid content
    unless File.exist?(CREDENTIALS_PATH) && File.size(CREDENTIALS_PATH) > 100
      puts "⚠️ Credentials file not found or invalid. Please set up your Google API credentials."
      puts "   File: #{CREDENTIALS_PATH}"
      return nil
    end

    # Load client credentials from Google Cloud Console JSON file
    @client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)

    # Set up token storage to persist credentials between app sessions
    @token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)

    # Create the authorizer that manages the OAuth flow
    @authorizer = Google::Auth::UserAuthorizer.new(@client_id, SCOPE, @token_store)
  rescue => e
    puts "❌ Error setting up OAuth client: #{e.message}"
    puts "   Please check your credentials file: #{CREDENTIALS_PATH}"
    nil
  end

  # Step 3: Check if we already have valid credentials stored
  def self.get_existing_credentials
    user_id = "default"  # We use a single user for this desktop app
    @authorizer.get_credentials(user_id)
  end

  # Step 4: Perform the complete OAuth flow
  def self.perform_oauth_flow
    puts "🌐 Starting OAuth flow..."
    puts "This will open your browser for authorization."

    # Step 4a: Start local server to receive the authorization code
    server = start_oauth_server

    # Step 4b: Generate the authorization URL and open browser
    auth_url = generate_authorization_url
    open_browser_for_authorization(auth_url)

    # Step 4c: Wait for user to complete authorization in browser
    auth_code = wait_for_authorization_code(server)

    # Step 4d: Exchange authorization code for access tokens
    exchange_code_for_tokens(auth_code)
  end

  # Step 4a: Start a local web server to receive the OAuth callback
  def self.start_oauth_server
    server = WEBrick::HTTPServer.new(Port: 8080)

    # Handle the OAuth callback from Google
    server.mount_proc("/") do |req, res|
      handle_oauth_callback(req, res, server)
    end

    # Start server in background thread so it doesn't block
    Thread.new { server.start }
    server
  end

  # Handle the OAuth callback response from Google
  def self.handle_oauth_callback(req, res, server)
    if req.query["code"]
      # Success! Store the authorization code
      @auth_code = req.query["code"]
      show_success_page(res)

      # Shutdown server after receiving the code
      Thread.new { sleep(1); server.shutdown }

    elsif req.query["error"]
      # OAuth error occurred
      @auth_code = nil
      show_error_page(res, req.query["error"])

    else
      # Invalid request
      res.status = 400
      res.body = "Invalid request"
    end
  end

  # Show success page when OAuth completes
  def self.show_success_page(res)
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
  end

  # Show error page when OAuth fails
  def self.show_error_page(res, error)
    res.status = 400
    res["Content-Type"] = "text/html"
    res.body = <<~HTML
      <html>
        <head><title>Authorization Failed</title><meta charset="UTF-8"></head>
        <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
          <h1 style="color: #EA4335;">❌ Authorization Failed</h1>
          <p>Error: #{error}</p>
          <p>Please try again or check the terminal for more details.</p>
        </body>
      </html>
    HTML
  end

  # Step 4b: Generate the authorization URL with proper parameters
  def self.generate_authorization_url
    @authorizer.get_authorization_url(
      base_url: REDIRECT_URI,
      access_type: "offline",  # Request refresh token
      prompt: "consent"        # Always show consent screen
    )
  end

  # Step 4b: Open the user's browser to the authorization URL
  def self.open_browser_for_authorization(url)
    # Try different commands to open browser based on OS
    opened = system("open", url) ||      # macOS
             system("xdg-open", url) ||  # Linux
             system("start", url)        # Windows

    unless opened
      puts "⚠️ Could not open browser automatically. Please copy and paste this URL:"
      puts url
    end
  end

  # Step 4c: Wait for the authorization code from the browser
  def self.wait_for_authorization_code(server)
    timeout = 300  # 5 minutes
    start_time = Time.now

    while Time.now - start_time < timeout
      return @auth_code if @auth_code
      sleep(1)
    end

    puts "⏰ Authorization timeout - no response received"
    puts "💡 Make sure you completed the authorization in your browser"
    nil
  end

  # Step 4d: Exchange the authorization code for access and refresh tokens
  def self.exchange_code_for_tokens(auth_code)
    return nil unless auth_code

    puts "✅ Authorization code received, exchanging for tokens..."

    user_id = "default"
    credentials = @authorizer.get_and_store_credentials_from_code(
      user_id: user_id,
      code: auth_code,
      base_url: REDIRECT_URI
    )

    puts "✅ Authorization successful!"
    puts "🔑 Access token obtained: #{credentials.access_token ? 'Yes' : 'No'}"
    puts "🔄 Refresh token obtained: #{credentials.refresh_token ? 'Yes' : 'No'}"

    credentials
  rescue StandardError => e
    handle_authorization_error(e)
    nil
  end

  # Handle any errors during the authorization process
  def self.handle_authorization_error(error)
    puts "❌ Error during authorization: #{error.message}"
    puts "🔧 Error class: #{error.class}"
    puts "💡 Make sure you have:"
    puts "   - Valid client_secrets.json in config/"
    puts "   - Internet connection"
    puts "   - Proper Google API permissions"
    puts "   - Redirect URI configured in Google Cloud Console"
  end
end
