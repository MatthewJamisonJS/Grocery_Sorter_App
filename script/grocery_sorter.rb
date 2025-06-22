require 'glimmer-dsl-libui'
require 'json'
require 'colorize'

# Load Rails environment for database and configuration
require_relative '../config/environment'

# Load our custom services
require_relative '../app/services/ollama_service'

# Main GUI class for the Grocery Sorter App
# This class handles the user interface and coordinates between services
class GrocerySorterGUI
  include Glimmer  # Include Glimmer DSL for GUI components

  # Expose table_data for data binding with the GUI table
  attr_accessor :table_data

  def initialize
    # Step 1: Initialize data structures
    @table_data = []  # Array to hold grocery items for the table

    # Step 2: Initialize service connections
    @ollama_service = OllamaService.new

    # Step 3: Set up services
    setup_services
  end

  # Main method to launch the GUI application
  def launch
    # Create the main application window
    window('Grocery Sorter App', 600, 500) {
      vertical_box {
        # Section 1: Header with app title and connection testing
        create_header_section

        # Section 2: Google Docs integration for loading grocery lists
        create_google_docs_section

        # Section 3: Manual entry for adding individual items
        create_manual_entry_section

        # Section 4: AI categorization tools
        create_ai_categorization_section

        # Section 5: Results table showing the grocery list
        create_results_table_section

        # Section 6: Status bar for user feedback
        create_status_bar
      }
    }.show  # Display the window
  end

  private

  # Section 1: Create the header with app title and connection testing
  def create_header_section
    horizontal_box {
      label('🛒 Grocery Sorter App') {
        stretchy false  # Don't expand horizontally
      }
      button('Test Connections') {
        stretchy false
        on_clicked { test_all_connections }
      }
    }
  end

  # Section 2: Create Google Docs integration section
  def create_google_docs_section
    group('Google Docs Integration (DISABLED)') {
      vertical_box {
        # Google Docs integration is currently DISABLED
        label('🚫 Google Docs integration is currently DISABLED') {
          stretchy false
        }
        label('   The app does NOT connect to Google API') {
          stretchy false
        }
        label('   All Google Docs features are non-functional') {
          stretchy false
        }
        label('   Use manual entry or clipboard paste instead') {
          stretchy false
        }

        # Disabled input fields
        horizontal_box {
          label('Your Google Email:') {
            stretchy false
          }
          @email_entry = entry {
            text ''
            enabled false
          }
        }

        # Disabled document input
        horizontal_box {
          label('Document URL or ID:') {
            stretchy false
          }
          @doc_id_entry = entry {
            text 'Google Docs integration disabled'
            enabled false
          }
          button('Test Access') {
            stretchy false
            enabled false
            on_clicked {
              @status_label.text = "Google Docs integration is disabled"
            }
          }
          button('Load from Google Docs') {
            stretchy false
            enabled false
            on_clicked {
              @status_label.text = "Google Docs integration is disabled"
            }
          }
        }
      }
    }
  end

  # Section 3: Create manual entry section
  def create_manual_entry_section
    group('Manual Entry & Clipboard') {
      vertical_box {
        # Item input and add button
        horizontal_box {
          label('Add Item:') {
            stretchy false
          }
          @item_entry = entry {
            on_changed { |entry| @item_text = entry.text }
          }
          button('Add') {
            stretchy false
            on_clicked { add_manual_item }
          }
        }

        # Clipboard paste functionality
        horizontal_box {
          button('Paste from Clipboard') {
            stretchy false
            on_clicked { paste_from_clipboard }
          }
          button('Clear All') {
            stretchy false
            on_clicked { clear_all_items }
          }
          button('Load Sample Data') {
            stretchy false
            on_clicked { load_sample_data }
          }
        }
      }
    }
  end

  # Section 4: Create AI categorization section
  def create_ai_categorization_section
    group('AI Categorization') {
      vertical_box {
        horizontal_box {
          button('Categorize with AI') {
            stretchy false
            on_clicked { categorize_with_ai }
          }
          button('Export to JSON') {
            stretchy false
            on_clicked { export_to_json }
          }
        }
      }
    }
  end

  # Section 5: Create results table section
  def create_results_table_section
    group('Grocery List') {
      vertical_box {
        @table = table {
          text_column('Item')      # Column for grocery item names
          text_column('Aisle')     # Column for store aisle categories
          text_column('Status')    # Column for item status/source
          cell_rows bind(self, :table_data)  # Bind to our data array
        }
      }
    }
  end

  # Section 6: Create status bar for user feedback
  def create_status_bar
    @status_label = label('Ready to sort groceries! 🛒') {
      stretchy false
    }
  end

  # Step 3: Set up service connections
  def setup_services
    # Skip Google authentication entirely - app works without Google API
    puts "✅ App initialized without Google authentication"
    puts "   Google Docs features are disabled"
    puts "   Core functionality (AI categorization, PDF export) is available"
  end

  # Test all external service connections
  def test_all_connections
    @status_label.text = "Testing connections..."

    # Skip Google API connection test (authentication disabled)
    puts "⏭️ Skipping Google API test (authentication disabled)"

    # Test Ollama AI service connection
    ollama_ok = @ollama_service.test_connection

    # Update status based on test results
    if ollama_ok
      @status_label.text = "✅ Ollama connection successful! (Google API disabled)"
    else
      @status_label.text = "⚠️ Ollama connection failed. Check console for details."
    end
  end

  # Add a manually entered item to the grocery list
  def add_manual_item
    item = @item_entry.text.strip
    return if item.empty?

    # Add item to table data with manual entry indicator
    self.table_data = table_data + [ [ item, 'Pending', '✏️' ] ]

    # Clear the input field
    @item_entry.text = ''

    # Update status
    @status_label.text = "Added: #{item}"
  end

  # Paste items from clipboard
  def paste_from_clipboard
    begin
      # Use system clipboard command
      clipboard_content = `pbpaste 2>/dev/null || xclip -selection clipboard -o 2>/dev/null || xsel --clipboard --output 2>/dev/null`

      if clipboard_content.strip.empty?
        @status_label.text = "⚠️ Clipboard is empty"
        return
      end

      # Split clipboard content into lines and filter out empty lines
      items = clipboard_content.split(/\r?\n/).map(&:strip).reject(&:empty?)

      if items.empty?
        @status_label.text = "⚠️ No valid items found in clipboard"
        return
      end

      # Add items to table data with clipboard indicator
      items.each do |item|
        self.table_data = table_data + [ [ item, 'Pending', '📋' ] ]
      end

      @status_label.text = "✅ Pasted #{items.length} items from clipboard"

    rescue StandardError => e
      @status_label.text = "❌ Failed to paste from clipboard: #{e.message}"
      puts "Clipboard error: #{e.message}"
    end
  end

  # Clear all items from the grocery list
  def clear_all_items
    self.table_data = []
    @status_label.text = "Cleared all items"
  end

  # Load sample data for testing and demonstration
  def load_sample_data
    sample_items = [
      'Milk', 'Eggs', 'Bread', 'Apples', 'Bananas',
      'Chicken Breast', 'Rice', 'Pasta', 'Tomatoes', 'Cheese'
    ]

    # Convert to table format with sample data indicator
    self.table_data = sample_items.map { |item| [ item, 'Pending', '📋' ] }
    @status_label.text = "Loaded sample data"
  end

  # Use AI to categorize grocery items by store aisle
  def categorize_with_ai
    return if table_data.empty?

    @status_label.text = "🤖 Categorizing with AI..."

    # Step 1: Extract just the item names from the table
    items = table_data.map { |row| row[0] }

    begin
      # Step 2: Use Ollama service to categorize items
      categorized = @ollama_service.categorize_grocery_items(items)

      # Step 3: Update table with AI categorization results
      self.table_data = categorized.map.with_index do |item, index|
        [ item[:product], item[:aisle], '🤖' ]
      end

      @status_label.text = "✅ AI categorization complete!"
    rescue StandardError => e
      @status_label.text = "❌ AI categorization failed: #{e.message}"
    end
  end

  # Export the grocery list to a JSON file
  def export_to_json
    return if table_data.empty?

    # Step 1: Convert table data to structured format
    data = table_data.map do |row|
      { item: row[0], aisle: row[1], source: row[2] }
    end

    # Step 2: Generate filename with timestamp
    filename = "grocery_list_#{Time.now.strftime('%Y%m%d_%H%M%S')}.json"

    # Step 3: Write data to file with pretty formatting
    File.write(filename, JSON.pretty_generate(data))

    @status_label.text = "💾 Exported to #{filename}"
  end
end

# Application entry point
puts "🚀 Starting Grocery Sorter App..."
GrocerySorterGUI.new.launch
