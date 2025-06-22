require "net/http"
require "json"
require "uri"

module Ollama
  # Handles low-level communication with the Ollama API.
  class Client
    def initialize(host:, model:, api_key: nil, security_config:)
      @host = host
      @model = model
      @api_key = api_key
      @base_url = "#{host}/api"
      @security_config = security_config
      @connection_pool = {}
      @model_pull_detected = false # This state will be managed by HealthChecker
    end

    # Executes a non-streaming request
    def post(endpoint, body)
      uri = URI("#{@base_url}/#{endpoint}")
      http = get_connection(uri)
      request = build_request(:post, uri, body)

      response = http.request(request)

      if response.code == "200"
        JSON.parse(response.body)
      else
        puts "❌ [Ollama::Client] API Error: #{response.code} #{response.message}"
        nil
      end
    rescue Net::ReadTimeout => e
      puts "⚠️ [Ollama::Client] Request timed out: #{e.message}"
      nil
    rescue JSON::ParserError => e
      puts "❌ [Ollama::Client] Failed to parse JSON response: #{e.message}"
      nil
    rescue StandardError => e
      puts "❌ [Ollama::Client] Request failed: #{e.message}"
      nil
    end

    # Executes a streaming request with improved error handling
    def stream(endpoint, body, &block)
      uri = URI("#{@base_url}/#{endpoint}")
      http = get_connection(uri)
      request = build_request(:post, uri, body)
      full_response = ""

      begin
        http.request(request) do |response|
          unless response.is_a?(Net::HTTPSuccess)
            puts "❌ [Ollama::Client] Streaming Error: #{response.code} #{response.message}"
            return nil
          end

          response.read_body do |chunk|
            full_response << chunk
            block.call(chunk) if block_given? # Yield each chunk to the caller
          end
        end
        full_response
      rescue Net::ReadTimeout => e
        puts "⚠️ [Ollama::Client] Streaming request timed out: #{e.message}"
        nil
      rescue EOFError => e
        puts "❌ [Ollama::Client] Streaming connection closed: #{e.message}"
        nil
      rescue StandardError => e
        puts "❌ [Ollama::Client] Streaming failed: #{e.message}"
        nil
      end
    end

    def get(endpoint)
        uri = URI("#{@base_url}/#{endpoint}")
        http = get_connection(uri)
        request = build_request(:get, uri)
        http.request(request)
    rescue StandardError => e
        puts "❌ [Ollama::Client] GET request to #{endpoint} failed: #{e.message}"
        nil
    end

    def cleanup_connections
      @connection_pool.each_value do |conn|
        conn.finish if conn.started?
      end
      @connection_pool.clear
      puts "🧹 [Ollama::Client] Connection pool cleaned up."
    end

    private

    def build_request(method, uri, body = nil)
      request = case method
      when :post
                  Net::HTTP::Post.new(uri)
      else
                  Net::HTTP::Get.new(uri)
      end

      request["User-Agent"] = "GrocerySorter/1.0"
      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{@api_key}" if @api_key
      request.body = body.to_json if body && method == :post

      request
    end

    def get_connection(uri)
      key = "#{uri.hostname}:#{uri.port}"
      if @connection_pool[key]&.started?
        return @connection_pool[key]
      end

      http = Net::HTTP.new(uri.hostname, uri.port)
      timeouts = @security_config[:timeout_settings]
      http.open_timeout = timeouts[:open_timeout]
      http.read_timeout = @model_pull_detected ? @security_config.dig(:model_pull, :pull_in_progress_timeout) : timeouts[:read_timeout]
      http.keep_alive_timeout = timeouts[:keep_alive_timeout]
      http.start
      @connection_pool[key] = http
    end
  end
end
