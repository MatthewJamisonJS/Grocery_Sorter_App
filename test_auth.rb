require_relative "./app/services/google_auth_service"

begin
  puts "Testing GoogleAuthService authorization..."
  docs_service = GoogleAuthService.authorize

  if docs_service
    puts "✅ Authorization successful and Docs API client initialized."
  else
    puts "❌ Authorization failed."
  end
rescue StandardError => e
  puts "❌ Error during testing: #{e.message}"
end
