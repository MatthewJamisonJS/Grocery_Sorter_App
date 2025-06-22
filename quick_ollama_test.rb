#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

puts "🧪 Quick Ollama Test"
puts "=" * 30

begin
  # Test 1: Check if Ollama is responding
  puts "1️⃣ Testing Ollama connection..."
  uri = URI("http://localhost:11434/api/tags")
  response = Net::HTTP.get_response(uri)

  if response.code == "200"
    puts "✅ Ollama is responding"
    models = JSON.parse(response.body)["models"]
    puts "📋 Available models: #{models.map { |m| m['name'] }.join(', ')}"
  else
    puts "❌ Ollama not responding: #{response.code}"
    exit 1
  end

  # Test 2: Simple generation test
  puts "\n2️⃣ Testing simple generation..."
  uri = URI("http://localhost:11434/api/generate")

  request_body = {
    model: "llama3.3:latest",
    prompt: "Say 'OK' and nothing else",
    stream: false,
    options: {
      temperature: 0.0,
      num_ctx: 64
    }
  }

  http = Net::HTTP.new(uri.hostname, uri.port)
  http.open_timeout = 10
  http.read_timeout = 30

  request = Net::HTTP::Post.new(uri)
  request["Content-Type"] = "application/json"
  request.body = request_body.to_json

  response = http.request(request)

  if response.code == "200"
    result = JSON.parse(response.body)
    puts "✅ Generation successful: #{result['response'].strip}"
  else
    puts "❌ Generation failed: #{response.code} - #{response.body}"
  end

  puts "\n🎉 Ollama is working! You can now run your app."

rescue => e
  puts "❌ Test failed: #{e.message}"
  puts "🔧 Error class: #{e.class}"
  puts "💡 Try restarting Ollama: pkill -f ollama && ollama serve"
end
