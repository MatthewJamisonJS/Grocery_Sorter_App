require "net/http"
require "json"
require "uri"

class OllamaService
  def initialize(host: "http://localhost:11434", model: "llama3.3:latest")
    @host = host
    @model = model
    @base_url = "#{host}/api"
  end

  def categorize_grocery_items(items)
    prompt = build_categorization_prompt(items)

    begin
      response = generate_response(prompt)
      parse_categorization_response(response, items)
    rescue StandardError => e
      puts "❌ Ollama API Error: #{e.message}"
      fallback_categorization(items)
    end
  end

  def test_connection
    begin
      uri = URI("#{@base_url}/tags")
      response = Net::HTTP.get_response(uri)

      if response.code == "200"
        puts "✅ Ollama connection successful!"
        puts "📋 Available models: #{JSON.parse(response.body)['models']&.map { |m| m['name'] }&.join(', ')}"
        true
      else
        puts "❌ Ollama connection failed! Status: #{response.code}"
        false
      end
    rescue StandardError => e
      puts "❌ Ollama connection failed: #{e.message}"
      puts "🔧 Make sure Ollama is running: ollama serve"
      false
    end
  end

  private

  def build_categorization_prompt(items)
    <<~PROMPT
      Categorize the following grocery items into appropriate store aisles/sections.
      Return the response as a JSON array with objects containing 'item' and 'aisle' fields.

      Grocery items: #{items.join(', ')}

      Common grocery store aisles include:
      - Produce (fruits, vegetables)
      - Dairy (milk, cheese, yogurt)
      - Meat & Seafood
      - Bakery (bread, pastries)
      - Pantry (canned goods, pasta, rice)
      - Frozen Foods
      - Beverages
      - Snacks
      - Condiments & Sauces
      - Household & Cleaning

      Response format:
      [
        {"item": "Milk", "aisle": "Dairy"},
        {"item": "Apples", "aisle": "Produce"}
      ]
    PROMPT
  end

  def generate_response(prompt)
    uri = URI("#{@base_url}/generate")

    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request.body = {
      model: @model,
      prompt: prompt,
      stream: false
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.code == "200"
      JSON.parse(response.body)["response"]
    else
      raise "HTTP #{response.code}: #{response.body}"
    end
  end

  def parse_categorization_response(response, original_items)
    begin
      # Try to extract JSON from the response
      json_match = response.match(/\[.*\]/m)
      if json_match
        parsed = JSON.parse(json_match[0])
        parsed.map { |item| { product: item["item"], aisle: item["aisle"] } }
      else
        # Fallback if JSON parsing fails
        fallback_categorization(original_items)
      end
    rescue JSON::ParserError
      fallback_categorization(original_items)
    end
  end

  def fallback_categorization(items)
    # Simple fallback categorization
    items.map do |item|
      aisle = case item.downcase
      when /milk|cheese|yogurt|butter|cream/
                "Dairy"
      when /apple|banana|orange|tomato|lettuce|carrot/
                "Produce"
      when /bread|bagel|muffin|cake/
                "Bakery"
      when /chicken|beef|pork|fish|meat/
                "Meat & Seafood"
      when /pasta|rice|beans|canned/
                "Pantry"
      when /frozen|ice cream/
                "Frozen Foods"
      when /soda|juice|water|beer/
                "Beverages"
      when /chips|crackers|cookies|candy/
                "Snacks"
      else
                "General"
      end
      { product: item, aisle: aisle }
    end
  end
end
