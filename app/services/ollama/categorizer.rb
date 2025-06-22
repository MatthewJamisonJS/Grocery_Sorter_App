module Ollama
  # Handles the business logic of categorizing grocery items.
  class Categorizer
    def initialize(client, model:, health_checker:)
      @client = client
      @model = model
      @health_checker = health_checker
    end

    def categorize(items, max_retries = 2)
      retries = 0

      # Pre-process items to extract quantities
      processed_items = preprocess_items(items)
      prompt = build_prompt(processed_items)

      # As per the user request, add detailed logging
      puts "📝 [Categorizer] Full Prompt being sent to AI:"
      puts "--------------------------------------------------"
      puts prompt
      puts "--------------------------------------------------"

      while retries <= max_retries
        # Check server health before attempting a request
        unless @health_checker.should_attempt_request?
          puts "🔄 [Categorizer] Server unhealthy, using fallback."
          return enhanced_fallback(items)
        end

        # Use non-streaming by default for better reliability
        response = @client.post("generate", build_payload(prompt, false))

        if response.nil?
            @health_checker.increment_failures
            retries += 1
            puts "⚠️ [Categorizer] Request failed. Retrying (attempt #{retries}/#{max_retries + 1})..."
            sleep(retries * 2) # Exponential backoff
            next
        end

        # Log the raw response
        puts "📝 [Categorizer] Raw AI Response:"
        puts "--------------------------------------------------"
        puts response.inspect
        puts "--------------------------------------------------"

        parsed = parse_response(response["response"], processed_items)

        # If parsing is successful and complete, return the results
        if parsed && parsed.size == processed_items.size
          @health_checker.reset_failures
          return parsed
        else
          puts "⚠️ [Categorizer] Parsing failed or was incomplete. Retrying..."
          retries += 1
          sleep(retries * 2)
        end
      end

      puts "❌ [Categorizer] All retries failed. Using enhanced fallback."
      enhanced_fallback(items)
    end

    private

    # Pre-process items to extract quantities and clean product names
    def preprocess_items(items)
      items.map do |item|
        quantity, clean_product = extract_quantity_and_product(item)
        {
          original: item,
          clean: clean_product,
          quantity: quantity
        }
      end
    end

    # Extract quantity from the beginning of an item (e.g., "2 coca-cola" -> [2, "coca-cola"])
    def extract_quantity_and_product(item)
      # Match patterns like "2 coca-cola", "3 a&w root beer", "1 dozen eggs"
      m = item.to_s.match(/^(\d+)\s+(.+)/i)
      if m
        quantity = m[1].to_i
        product = m[2].strip
        [ quantity, product ]
      else
        [ nil, item.to_s.strip ]
      end
    rescue => e
      puts "⚠️ Error extracting quantity from '#{item}': #{e.message}"
      [ nil, item.to_s.strip ]
    end

    def build_payload(prompt, stream = false)
      {
        model: @model,
        prompt: prompt,
        stream: stream,
        options: {
          temperature: 0.0,
          top_p: 0.1,
          num_ctx: 1024
        }
      }
    end

    def build_prompt(processed_items)
      # Extract just the clean product names for the AI
      clean_items = processed_items.map { |item| item[:clean] }

      <<~PROMPT
      You are an expert Walmart associate responsible for stocking shelves.
      Your task is to categorize a list of grocery items into their correct aisles based on a standard Walmart store layout.
      For each item, provide the product name, the corresponding aisle, and include the original item from the list in the 'notes' field.

      Respond ONLY with a single, valid JSON array of objects. Do not include any other text or explanations.

      Use the following standard Walmart aisle categories:
      #{OllamaService::AISLES.to_json}

      Here is the list of items to categorize:
      #{clean_items.to_json}

      Example response format:
      [
        {"product": "Dozen Eggs", "aisle": "Dairy & Eggs", "notes": "1 dozen eggs"},
        {"product": "Tide Pods", "aisle": "Household & Cleaning", "notes": "tide pods laundry detergent"}
      ]
      PROMPT
    end

    def parse_response(response_text, processed_items)
      return nil if response_text.nil? || response_text.strip.empty?

      # Try to extract JSON from the response
      json_match = response_text.match(/\[.*\]/m)
      return nil unless json_match

      json_string = json_match.to_s
      puts "📝 [Categorizer] Extracted JSON for parsing:"
      puts "--------------------------------------------------"
      puts json_string
      puts "--------------------------------------------------"

      parsed = JSON.parse(json_string)
      return nil unless parsed.is_a?(Array)

      # Match results back to original items and add quantity information
      processed_items.map do |processed_item|
        found = parsed.find { |p| p["notes"]&.casecmp?(processed_item[:clean]) }

        if found
          # Format notes with quantity if present
          notes = format_notes(processed_item[:original], processed_item[:quantity], found["notes"])

          {
            product: found["product"] || processed_item[:clean],
            aisle: found["aisle"] || "General",
            notes: notes
          }
        else
          # Fallback with quantity formatting
          notes = format_notes(processed_item[:original], processed_item[:quantity], "Not found in AI response")

          {
            product: processed_item[:clean],
            aisle: "General",
            notes: notes
          }
        end
      end
    rescue JSON::ParserError => e
      puts "❌ [Categorizer] JSON parsing failed: #{e.message}"
      nil
    end

    # Format notes to include quantity information
    def format_notes(original_item, quantity, base_notes)
      if quantity && quantity > 1
        "#{quantity} cases - #{base_notes}"
      elsif quantity && quantity == 1
        "1 case - #{base_notes}"
      else
        base_notes
      end
    end

    def simple_fallback(items)
        puts "🔄 [Categorizer] Using simple rule-based fallback."
        items.map do |item|
            quantity, clean_product = extract_quantity_and_product(item)
            notes = format_notes(item, quantity, "Fallback category")
            { product: clean_product, aisle: "General", notes: notes }
        end
    end

    def enhanced_fallback(items)
        puts "🔄 [Categorizer] Using enhanced fallback categorization (no Ollama API needed)."

        # Enhanced rule-based categorization
        items.map do |item|
            quantity, clean_product = extract_quantity_and_product(item)
            aisle = categorize_by_rules(clean_product)
            notes = format_notes(item, quantity, "Enhanced fallback")
            { product: clean_product, aisle: aisle, notes: notes }
        end
    end

    def categorize_by_rules(item)
        item_lower = item.downcase

        # Produce
        return "Produce" if item_lower.match?(/\b(apple|banana|orange|tomato|lettuce|carrot|onion|potato|broccoli|spinach|cucumber|pepper|avocado|lemon|lime|garlic|fruit|vegetable|produce)\b/)

        # Dairy & Eggs
        return "Dairy & Eggs" if item_lower.match?(/\b(cheese|yogurt|butter|cream|egg|milk|sour cream|cottage cheese|half and half|heavy cream)\b/)

        # Meat & Seafood
        return "Meat & Seafood" if item_lower.match?(/\b(chicken|beef|pork|fish|salmon|tuna|shrimp|bacon|ham|turkey|sausage|meat|seafood)\b/)

        # Bakery
        return "Bakery" if item_lower.match?(/\b(bread|bagel|muffin|cake|croissant|donut|cookie|bun|roll|pastry)\b/)

        # Pantry
        return "Pantry" if item_lower.match?(/\b(pasta|rice|bean|canned|soup|sauce|oil|flour|sugar|salt|pepper|spice|grain|cereal)\b/)

        # Frozen Foods
        return "Frozen Foods" if item_lower.match?(/\b(frozen|ice cream|pizza)\b/)

        # Beverages
        return "Beverages" if item_lower.match?(/\b(soda|juice|water|beer|wine|coffee|tea|drink|beverage)\b/)

        # Snacks
        return "Snacks" if item_lower.match?(/\b(chip|cracker|cookie|candy|popcorn|nut|pretzel|snack)\b/)

        # Condiments & Sauces
        return "Condiments & Sauces" if item_lower.match?(/\b(ketchup|mustard|mayonnaise|hot sauce|soy sauce|vinegar|dressing|bbq sauce|condiment)\b/)

        # Household & Cleaning
        return "Household & Cleaning" if item_lower.match?(/\b(paper towel|toilet paper|cleaning|laundry|dish soap|trash bag|battery|light bulb|household|cleaner)\b/)

        # Health & Beauty
        return "Health & Beauty" if item_lower.match?(/\b(shampoo|soap|toothpaste|deodorant|razor|brush|beauty|health|personal care)\b/)

        # Electronics
        return "Electronics" if item_lower.match?(/\b(phone|charger|battery|electronic|device|tech)\b/)

        # Pet Supplies
        return "Pet Supplies" if item_lower.match?(/\b(dog|cat|pet|animal|food|toy)\b/)

        # Baby Care
        return "Baby Care" if item_lower.match?(/\b(baby|diaper|formula|baby food|infant)\b/)

        # Default
        "General Merchandise"
    end
  end
end
