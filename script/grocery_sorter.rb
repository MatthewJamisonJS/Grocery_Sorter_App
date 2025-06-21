require 'glimmer-dsl-libui'
require 'json'
require 'colorize'

# Load Rails environment
require_relative '../config/environment'

require_relative '../app/services/google_auth_service'
require_relative '../app/services/google_docs_service'
require_relative '../app/services/ollama_service'

class GrocerySorterGUI
  include Glimmer

  attr_accessor :table_data

  def initialize
    @table_data = []
    @google_docs_service = nil
    @ollama_service = OllamaService.new
    setup_services
  end

  def launch
    window('Grocery Sorter App', 600, 500) {
      vertical_box {
        # Header
        horizontal_box {
          label('🛒 Grocery Sorter App') {
            stretchy false
          }
          button('Test Connections') {
            stretchy false
            on_clicked { test_all_connections }
          }
        }

        # Google Docs Section
        group('Google Docs Integration') {
          vertical_box {
            horizontal_box {
              label('Your Google Email:') {
                stretchy false
              }
              @email_entry = entry {
                text ''
              }
            }
            horizontal_box {
              label('Document URL or ID:') {
                stretchy false
              }
              @doc_id_entry = entry {
                text 'https://docs.google.com/document/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit'
              }
              button('Test Access') {
                stretchy false
                on_clicked { test_document_access }
              }
              button('Load from Google Docs') {
                stretchy false
                on_clicked { load_from_google_docs }
              }
            }
            label('💡 Tip: Enter your Google email and paste the full Google Docs URL') {
              stretchy false
            }
          }
        }

        # Manual Entry Section
        group('Manual Entry') {
          vertical_box {
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
            horizontal_box {
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

        # AI Categorization
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

        # Results Table
        group('Grocery List') {
          vertical_box {
            @table = table {
              text_column('Item')
              text_column('Aisle')
              text_column('Status')
              cell_rows bind(self, :table_data)
            }
          }
        }

        # Status Bar
        @status_label = label('Ready to sort groceries! 🛒') {
          stretchy false
        }
      }
    }.show
  end

  private

  def setup_services
    begin
      @google_docs_service = GoogleDocsService.new
      puts "✅ Google Docs service initialized"
    rescue StandardError => e
      puts "⚠️ Google Docs service not available: #{e.message}"
    end
  end

  def test_all_connections
    @status_label.text = "Testing connections..."

    # Test Google API
    google_ok = GoogleAuthService.test_connection

    # Test Ollama
    ollama_ok = @ollama_service.test_connection

    if google_ok && ollama_ok
      @status_label.text = "✅ All connections successful!"
    else
      @status_label.text = "⚠️ Some connections failed. Check console for details."
    end
  end

  def load_from_google_docs
    return unless @google_docs_service

    doc_input = @doc_id_entry.text.strip
    user_email = @email_entry.text.strip

    return if doc_input.empty?

    if user_email.empty?
      @status_label.text = "⚠️ Please enter your Google email first"
      return
    end

    @status_label.text = "Loading from Google Docs..."

    begin
      items = @google_docs_service.get_grocery_items(doc_input, user_email)
      if items.any?
        self.table_data = items.map { |item| [ item, 'Pending', '📄' ] }
        @status_label.text = "✅ Loaded #{items.length} items from Google Docs"
      else
        @status_label.text = "⚠️ No items found or access denied"
      end
    rescue StandardError => e
      @status_label.text = "❌ Failed to load from Google Docs: #{e.message}"
    end
  end

  def test_document_access
    return unless @google_docs_service

    doc_input = @doc_id_entry.text.strip
    user_email = @email_entry.text.strip

    return if doc_input.empty?

    if user_email.empty?
      @status_label.text = "⚠️ Please enter your Google email first"
      return
    end

    @status_label.text = "Testing document access..."

    begin
      result = @google_docs_service.test_document_access(doc_input, user_email)

      if result[:success]
        @status_label.text = "✅ Access successful! Title: #{result[:title]}"
        puts "📄 Document Details:"
        puts "   Title: #{result[:title]}"
        puts "   Last Modified: #{result[:last_modified]}"
        puts "   Permission ID: #{result[:permission_id]}"
      else
        @status_label.text = "❌ Access failed: #{result[:error]}"
        puts "❌ Access Error: #{result[:error]}"
        puts "🔧 Error Class: #{result[:error_class]}"

        # Provide specific guidance for unauthorized errors
        @google_docs_service.get_user_guidance_for_unauthorized(result)
      end
    rescue StandardError => e
      @status_label.text = "❌ Test failed: #{e.message}"
    end
  end

  def add_manual_item
    item = @item_entry.text.strip
    return if item.empty?

    self.table_data = table_data + [ [ item, 'Pending', '✏️' ] ]
    @item_entry.text = ''
    @status_label.text = "Added: #{item}"
  end

  def clear_all_items
    self.table_data = []
    @status_label.text = "Cleared all items"
  end

  def load_sample_data
    sample_items = [
      'Milk', 'Eggs', 'Bread', 'Apples', 'Bananas',
      'Chicken Breast', 'Rice', 'Pasta', 'Tomatoes', 'Cheese'
    ]
    self.table_data = sample_items.map { |item| [ item, 'Pending', '📋' ] }
    @status_label.text = "Loaded sample data"
  end

  def categorize_with_ai
    return if table_data.empty?

    @status_label.text = "🤖 Categorizing with AI..."

    # Extract just the item names
    items = table_data.map { |row| row[0] }

    begin
      categorized = @ollama_service.categorize_grocery_items(items)

      # Update table with AI results
      self.table_data = categorized.map.with_index do |item, index|
        [ item[:product], item[:aisle], '🤖' ]
      end

      @status_label.text = "✅ AI categorization complete!"
    rescue StandardError => e
      @status_label.text = "❌ AI categorization failed: #{e.message}"
    end
  end

  def export_to_json
    return if table_data.empty?

    data = table_data.map do |row|
      { item: row[0], aisle: row[1], source: row[2] }
    end

    filename = "grocery_list_#{Time.now.strftime('%Y%m%d_%H%M%S')}.json"
    File.write(filename, JSON.pretty_generate(data))

    @status_label.text = "💾 Exported to #{filename}"
  end
end

# Launch the application
puts "🚀 Starting Grocery Sorter App..."
GrocerySorterGUI.new.launch
