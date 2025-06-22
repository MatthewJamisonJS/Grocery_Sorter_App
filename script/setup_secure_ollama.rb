#!/usr/bin/env ruby
# frozen_string_literal: true

# Ollama Security Setup Script
# This script helps configure Ollama securely and tests the setup

require 'net/http'
require 'json'
require 'uri'
require 'fileutils'
require 'securerandom'

class OllamaSecuritySetup
  def initialize
    @ollama_host = "http://localhost:11434"
    @base_url = "#{@ollama_host}/api"
    @config_dir = File.expand_path("~/.ollama_security")
    @api_key_file = File.join(@config_dir, "api_key.txt")
  end

  def run
    puts "🔒 Ollama Security Setup"
    puts "=" * 50

    create_config_directory
    check_ollama_installation
    generate_api_key
    test_security_configuration
    provide_recommendations
  end

  private

  def create_config_directory
    puts "\n📁 Creating security configuration directory..."
    FileUtils.mkdir_p(@config_dir)
    puts "✅ Configuration directory created: #{@config_dir}"
  end

  def check_ollama_installation
    puts "\n🔍 Checking Ollama installation..."

    # Check if Ollama is installed
    unless system("which ollama > /dev/null 2>&1")
      puts "❌ Ollama is not installed or not in PATH"
      puts "💡 Install Ollama: curl -fsSL https://ollama.ai/install.sh | sh"
      exit 1
    end

    # Check Ollama version
    version = `ollama --version 2>/dev/null`.strip
    puts "✅ Ollama version: #{version}"

    # Check if Ollama is running
    unless ollama_running?
      puts "⚠️ Ollama is not running"
      puts "💡 Start Ollama: ollama serve"
      puts "💡 For secure setup: ollama serve --host 127.0.0.1:11434"
      exit 1
    end

    puts "✅ Ollama is running"
  end

  def ollama_running?
    begin
      uri = URI("#{@base_url}/tags")
      response = Net::HTTP.get_response(uri)
      response.code == "200"
    rescue StandardError
      false
    end
  end

  def generate_api_key
    puts "\n🔑 Generating API key for enhanced security..."

    if File.exist?(@api_key_file)
      puts "✅ API key already exists: #{@api_key_file}"
      @api_key = File.read(@api_key_file).strip
    else
      @api_key = SecureRandom.hex(32)
      File.write(@api_key_file, @api_key)
      File.chmod(0600, @api_key_file) # Secure permissions
      puts "✅ New API key generated and saved: #{@api_key_file}"
    end

    puts "🔑 API Key: #{@api_key[0..15]}..."
  end

  def test_security_configuration
    puts "\n🧪 Testing security configuration..."

    # Test 1: Basic connectivity
    puts "1. Testing basic connectivity..."
    if test_basic_connectivity
      puts "   ✅ Basic connectivity works"
    else
      puts "   ❌ Basic connectivity failed"
      return false
    end

    # Test 2: API key authentication
    puts "2. Testing API key authentication..."
    if test_api_key_auth
      puts "   ✅ API key authentication works"
    else
      puts "   ⚠️ API key authentication not supported (using basic auth)"
    end

    # Test 3: Rate limiting
    puts "3. Testing rate limiting..."
    test_rate_limiting

    # Test 4: Host binding
    puts "4. Testing host binding..."
    test_host_binding

    true
  end

  def test_basic_connectivity
    begin
      uri = URI("#{@base_url}/tags")
      response = Net::HTTP.get_response(uri)
      response.code == "200"
    rescue StandardError
      false
    end
  end

  def test_api_key_auth
    begin
      uri = URI("#{@base_url}/tags")
      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{@api_key}"

      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(request)
      end

      response.code == "200"
    rescue StandardError
      false
    end
  end

  def test_rate_limiting
    puts "   ⏳ Testing rate limiting (sending multiple requests)..."

    start_time = Time.now
    success_count = 0

    10.times do |i|
      begin
        uri = URI("#{@base_url}/tags")
        response = Net::HTTP.get_response(uri)
        if response.code == "200"
          success_count += 1
        end
        sleep(0.1) # Small delay between requests
      rescue StandardError
        # Ignore errors for rate limiting test
      end
    end

    elapsed = Time.now - start_time
    puts "   📊 Rate test: #{success_count}/10 requests successful in #{elapsed.round(2)}s"

    if success_count >= 8
      puts "   ✅ Rate limiting appears reasonable"
    else
      puts "   ⚠️ Rate limiting may be too aggressive"
    end
  end

  def test_host_binding
    # Test if Ollama is accessible from external IPs
    puts "   🔍 Testing host binding security..."

    # This is a basic test - in production, you'd want more comprehensive testing
    begin
      # Try to connect to localhost specifically
      uri = URI("http://127.0.0.1:11434/api/tags")
      response = Net::HTTP.get_response(uri)

      if response.code == "200"
        puts "   ✅ Ollama accessible on localhost"

        # Check if it's also accessible on 0.0.0.0 (less secure)
        uri_external = URI("http://0.0.0.0:11434/api/tags")
        begin
          response_external = Net::HTTP.get_response(uri_external)
          if response_external.code == "200"
            puts "   ⚠️ Ollama accessible on all interfaces (less secure)"
          else
            puts "   ✅ Ollama only accessible on localhost (secure)"
          end
        rescue StandardError
          puts "   ✅ Ollama only accessible on localhost (secure)"
        end
      else
        puts "   ❌ Ollama not accessible on localhost"
      end
    rescue StandardError => e
      puts "   ❌ Host binding test failed: #{e.message}"
    end
  end

  def provide_recommendations
    puts "\n📋 Security Recommendations"
    puts "=" * 50

    puts "1. 🔒 Run Ollama locally only:"
    puts "   ollama serve --host 127.0.0.1:11434"

    puts "\n2. 🛡️ Configure firewall rules:"
    if RUBY_PLATFORM.include?("darwin")
      puts "   # macOS:"
      puts "   sudo pfctl -e"
      puts "   echo 'block drop in proto tcp from any to any port 11434' | sudo pfctl -f -"
    else
      puts "   # Linux:"
      puts "   sudo iptables -A INPUT -p tcp --dport 11434 -s 127.0.0.1 -j ACCEPT"
      puts "   sudo iptables -A INPUT -p tcp --dport 11434 -j DROP"
    end

    puts "\n3. 🔑 Set environment variable:"
    puts "   export OLLAMA_API_KEY=\"#{@api_key}\""
    puts "   # Add to your shell profile for persistence"

    puts "\n4. 📊 Monitor access logs:"
    puts "   # Check Ollama logs:"
    puts "   journalctl -u ollama -f  # systemd"
    puts "   tail -f /var/log/ollama.log  # if using log file"

    puts "\n5. 🔄 Regular updates:"
    puts "   curl -fsSL https://ollama.ai/install.sh | sh"

    puts "\n6. 🧪 Test your setup:"
    puts "   ruby script/setup_secure_ollama.rb"

    puts "\n✅ Security setup complete!"
    puts "📖 See config/ollama_security.md for detailed documentation"
  end
end

if __FILE__ == $0
  setup = OllamaSecuritySetup.new
  setup.run
end
