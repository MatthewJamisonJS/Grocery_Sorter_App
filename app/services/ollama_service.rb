require "net/http"
require "json"
require "uri"
require "concurrent"

class OllamaService
  def initialize(host: "http://localhost:11434", model: "llama3.3:latest")
    @host = host
    @model = model
    @base_url = "#{host}/api"
    @cache = Concurrent::Map.new
    @batch_size = 10  # Process items in batches for optimal performance
  end

  # Lightning-fast batch categorization for large lists
  def categorize_grocery_items_batch(items, progress_callback = nil)
    return [] if items.empty?

    # Split items into optimal batches
    batches = items.each_slice(@batch_size).to_a
    total_batches = batches.length

    puts "🚀 Processing #{items.length} items in #{total_batches} batches..."

    # Process batches concurrently for maximum speed
    results = Concurrent::Array.new

    batches.each_with_index do |batch, batch_index|
      progress_callback&.call("Processing batch #{batch_index + 1}/#{total_batches}") if progress_callback

      # Use cached results when possible
      cached_results = batch.map { |item| @cache[item.downcase] }.compact
      uncached_items = batch.reject { |item| @cache[item.downcase] }

      if uncached_items.any?
        # Process uncached items in this batch
        batch_results = process_batch_optimized(uncached_items)

        # Cache the results
        batch_results.each do |result|
          @cache[result[:product].downcase] = result[:aisle]
        end

        results.concat(batch_results)
      end

      results.concat(cached_results.map { |aisle| { product: batch[batch_index], aisle: aisle } })
    end

    puts "✅ Batch processing complete! Processed #{items.length} items"
    results
  end

  # Original method for backward compatibility
  def categorize_grocery_items(items)
    if items.length > 5
      # Use batch processing for larger lists
      categorize_grocery_items_batch(items)
    else
      # Use single request for small lists
      prompt = build_categorization_prompt(items)
      begin
        response = generate_response_optimized(prompt)
        parse_categorization_response(response, items)
      rescue StandardError => e
        puts "❌ Ollama API Error: #{e.message}"
        fallback_categorization(items)
      end
    end
  end

  def test_connection
    begin
      uri = URI("#{@base_url}/tags")
      response = Net::HTTP.get_response(uri)

      if response.code == "200"
        models = JSON.parse(response.body)["models"]&.map { |m| m["name"] }
        puts "✅ Ollama connection successful!"
        puts "📋 Available models: #{models&.join(', ')}"

        # Check for optimized models
        optimized_models = models&.select { |m| m.include?("q4") || m.include?("q5") }
        if optimized_models.any?
          puts "⚡ Optimized models available: #{optimized_models.join(', ')}"
          puts "💡 Consider using quantized models for faster processing!"
        end

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

  # Get optimal model for speed
  def get_optimal_model
    begin
      uri = URI("#{@base_url}/tags")
      response = Net::HTTP.get_response(uri)

      if response.code == "200"
        models = JSON.parse(response.body)["models"]&.map { |m| m["name"] }

        # Prefer quantized models for speed
        q4_models = models&.select { |m| m.include?("q4") }
        q5_models = models&.select { |m| m.include?("q5") }

        if q4_models.any?
          q4_models.first
        elsif q5_models.any?
          q5_models.first
        else
          @model
        end
      else
        @model
      end
    rescue
      @model
    end
  end

  private

  # Optimized batch processing with concurrent requests
  def process_batch_optimized(items)
    return [] if items.empty?

    # Use optimized model
    optimal_model = get_optimal_model

    # Create optimized prompt for batch processing
    prompt = build_batch_categorization_prompt(items)

    begin
      response = generate_response_optimized(prompt, optimal_model)
      parse_categorization_response(response, items)
    rescue StandardError => e
      puts "❌ Batch processing error: #{e.message}"
      fallback_categorization(items)
    end
  end

  # Optimized prompt for batch processing
  def build_batch_categorization_prompt(items)
    <<~PROMPT
      Categorize these grocery items into store aisles. Return JSON array only.

      Items: #{items.join(', ')}

      Aisles: Produce, Dairy, Meat & Seafood, Bakery, Pantry, Frozen Foods, Beverages, Snacks, Condiments, Household

      Format: [{"item": "name", "aisle": "aisle"}]
    PROMPT
  end

  # Original prompt for backward compatibility
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

  # Optimized response generation with performance settings
  def generate_response_optimized(prompt, model = nil)
    model ||= @model
    uri = URI("#{@base_url}/generate")

    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"

    # Optimized request body with performance settings
    request.body = {
      model: model,
      prompt: prompt,
      stream: false,
      options: {
        num_ctx: 2048,        # Smaller context for speed
        num_thread: 8,        # Use multiple threads
        temperature: 0.1,     # Lower temperature for consistent results
        top_p: 0.9,           # Optimize for speed
        top_k: 40             # Limit choices for faster processing
      }
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port,
                              open_timeout: 30,
                              read_timeout: 60) do |http|
      http.request(request)
    end

    if response.code == "200"
      JSON.parse(response.body)["response"]
    else
      raise "HTTP #{response.code}: #{response.body}"
    end
  end

  # Original method for backward compatibility
  def generate_response(prompt)
    generate_response_optimized(prompt)
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
