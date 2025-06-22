require "net/http"
require "json"
require "uri"

# Load the refactored components
require_relative "ollama/client"
require_relative "ollama/health_checker"
require_relative "ollama/categorizer"

class OllamaService
  # This remains here as it's a core part of the prompt contract.
  AISLES = [
    "Produce", "Dairy & Eggs", "Meat & Seafood", "Bakery", "Pantry",
    "Frozen Foods", "Beverages", "Snacks", "Condiments & Sauces", "Household & Cleaning",
    "Health & Beauty", "Pet Supplies", "Baby Care", "Electronics", "Toys & Games",
    "Clothing & Apparel", "General Merchandise"
  ].freeze

  SECURITY_CONFIG = {
    timeout_settings: {
      open_timeout: 15,
      read_timeout: 90,
      keep_alive_timeout: 30
    },
    server_health: {
      max_consecutive_failures: 3,
      health_check_interval: 5
    },
    model_pull: {
      pull_in_progress_timeout: 300
    }
  }

  def initialize(host: "http://localhost:11434", model: "incept5/llama3.1-claude:latest", api_key: nil)
    @host = host
    @model = model
    @cache = {}
    @batch_size = 3

    # Initialize the new components
    @client = Ollama::Client.new(host: host, model: model, api_key: api_key, security_config: SECURITY_CONFIG)
    @health_checker = Ollama::HealthChecker.new(@client, SECURITY_CONFIG)
    @categorizer = Ollama::Categorizer.new(@client, model: model, health_checker: @health_checker)

    initialize_common_items_cache
    puts "✅ OllamaService initialized with new architecture."
  end

  # The main entry point for batch categorization.
  def categorize_grocery_items_batch(items, progress_callback = nil)
    return [] if items.empty?

    # Step 1: Check cache for instant results
    cache_hits, uncached_items = check_cache(items)
    processed_items = cache_hits
    progress_callback&.call("📋 Found #{cache_hits.length} items in cache, processing #{uncached_items.length} new items...")

    # Step 2: Process uncached items in batches
    if uncached_items.any?
      batches = uncached_items.each_slice(@batch_size).to_a
      total_batches = batches.length

      batches.each_with_index do |batch, index|
        progress_callback&.call("🔄 Processing batch #{index + 1}/#{total_batches}...")

        # Delegate categorization to the new Categorizer class
        result = @categorizer.categorize(batch)
        processed_items.concat(result)

        # Update cache with new results
        result.each do |item|
          @cache[item[:product].downcase.strip] = item[:aisle] if item && item[:product] && item[:aisle]
        end
      end
    end

    progress_callback&.call("✅ Batch processing complete!")
    processed_items
  end

  # Cleanup connections by delegating to the client
  def cleanup_connections
    @client.cleanup_connections
  end

  def get_service_status
    {
      host: @host,
      model: @model,
      batch_size: @batch_size,
      cache_size: @cache.size,
      consecutive_failures: @health_checker.consecutive_failures,
      model_pull_detected: @health_checker.model_pull_detected,
      server_healthy: @health_checker.server_healthy?
    }
  end

  private

  def check_cache(items)
    cache_hits = []
    uncached_items = []
    items.each do |item|
      item_lower = item.downcase.strip
      if @cache[item_lower]
        cache_hits << { product: item, aisle: @cache[item_lower], notes: "From cache" }
      else
        uncached_items << item
      end
    end
    [ cache_hits, uncached_items ]
  end

  def initialize_common_items_cache
    # This logic remains the same
    common_items = {
      # Produce
      "apple" => "Produce", "banana" => "Produce", "orange" => "Produce", "tomato" => "Produce",
      "lettuce" => "Produce", "carrot" => "Produce", "onion" => "Produce", "potato" => "Produce",
      "broccoli" => "Produce", "spinach" => "Produce", "cucumber" => "Produce", "bell pepper" => "Produce",
      "avocado" => "Produce", "lemon" => "Produce", "lime" => "Produce", "garlic" => "Produce",

      # Dairy
      "cheese" => "Dairy", "yogurt" => "Dairy", "butter" => "Dairy",
      "cream" => "Dairy", "eggs" => "Dairy", "sour cream" => "Dairy", "cottage cheese" => "Dairy",
      "half and half" => "Dairy", "heavy cream" => "Dairy",

      # Meat & Seafood
      "chicken" => "Meat & Seafood", "beef" => "Meat & Seafood", "pork" => "Meat & Seafood",
      "fish" => "Meat & Seafood", "salmon" => "Meat & Seafood", "tuna" => "Meat & Seafood",
      "shrimp" => "Meat & Seafood", "bacon" => "Meat & Seafood", "ham" => "Meat & Seafood",
      "turkey" => "Meat & Seafood", "sausage" => "Meat & Seafood",

      # Bakery
      "bread" => "Bakery", "bagel" => "Bakery", "muffin" => "Bakery", "cake" => "Bakery",
      "croissant" => "Bakery", "donut" => "Bakery", "cookie" => "Bakery", "bun" => "Bakery",
      "roll" => "Bakery", "pastry" => "Bakery",

      # Pantry
      "pasta" => "Pantry", "rice" => "Pantry", "beans" => "Pantry", "canned" => "Pantry",
      "soup" => "Pantry", "sauce" => "Pantry", "oil" => "Pantry", "flour" => "Pantry",
      "sugar" => "Pantry", "salt" => "Pantry", "pepper" => "Pantry", "spice" => "Pantry",

      # Frozen Foods
      "frozen" => "Frozen Foods", "ice cream" => "Frozen Foods", "frozen pizza" => "Frozen Foods",
      "frozen vegetables" => "Frozen Foods", "frozen fruit" => "Frozen Foods",

      # Beverages
      "soda" => "Beverages", "juice" => "Beverages", "water" => "Beverages", "beer" => "Beverages",
      "wine" => "Beverages", "coffee" => "Beverages", "tea" => "Beverages", "milk" => "Beverages",

      # Snacks
      "chips" => "Snacks", "crackers" => "Snacks", "cookies" => "Snacks", "candy" => "Snacks",
      "popcorn" => "Snacks", "nuts" => "Snacks", "pretzels" => "Snacks",

      # Condiments
      "ketchup" => "Condiments", "mustard" => "Condiments", "mayonnaise" => "Condiments",
      "hot sauce" => "Condiments", "soy sauce" => "Condiments", "vinegar" => "Condiments",
      "salad dressing" => "Condiments", "bbq sauce" => "Condiments",

      # Household
      "paper towels" => "Household", "toilet paper" => "Household", "cleaning" => "Household",
      "laundry" => "Household", "dish soap" => "Household", "trash bags" => "Household",
      "batteries" => "Household", "light bulbs" => "Household"
    }
    @cache.merge!(common_items)
  end
end
