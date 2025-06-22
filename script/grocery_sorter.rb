# frozen_string_literal: true

require 'glimmer-dsl-libui'
# TODO: Restore Google Docs functionality after fixing auth issues
# require 'google/apis/docs_v1'
# require 'googleauth'
# require 'googleauth/stores/file_token_store'
require 'fileutils'
require 'os'
require 'prawn'
require 'prawn/table'
require 'clipboard'
require 'pry'

# Load application services
# TODO: Restore Google Docs functionality after fixing auth issues
# require_relative '../app/services/google_auth_service'
# require_relative '../app/services/google_docs_service'
require_relative '../app/services/ollama_service'

# The Presenter holds the state and business logic of the application.
class Presenter
  include Glimmer::DataBinding::ObservableModel

  attr_accessor :google_doc_url, :batch_text, :items, :status_text, :download_enabled, :clipboard_loaded

  def initialize
    @google_doc_url = ''
    @batch_text = ''
    @items = [ [ '', '', '' ] ] # Start with a blank row
    @status_text = 'Welcome to Grocery Sorter!'
    @download_enabled = false
    @clipboard_loaded = false
    @all_processed_items = []
    @processed_cache = {}  # Simple cache for processed items
    @ollama_service = nil  # Initialize to nil

    # Initialize services in the background
    Thread.new do
      self.status_text = 'Initializing AI service...'
      # TODO: Restore Google Docs functionality after fixing auth issues
      # validate_credentials
      # @google_docs_service = GoogleDocsService.new
      begin
        @ollama_service = OllamaService.new
        self.status_text = 'AI service initialized. Ready for clipboard paste.'
      rescue StandardError => e
        puts "❌ Failed to initialize OllamaService: #{e.message}"
        self.status_text = 'AI service initialization failed. Using fallback mode.'
      end
    end
  end

  def play_completion_sound
    sound_path = File.expand_path('../app/assets/sounds/zelda_receive_item.mp3', __dir__)
    if File.exist?(sound_path)
      system('afplay', sound_path)
      puts "🔊 Completion sound played!"
    else
      puts "⚠️ Sound file not found at: #{sound_path}"
    end
  end

  def process_batch_text
    return if batch_text.to_s.strip.empty?

    # Check cache first
    cache_key = batch_text.strip.downcase
    if @processed_cache[cache_key]
      @all_processed_items = @processed_cache[cache_key]
      Glimmer::LibUI.queue_main do
        # Convert hash objects to arrays for Glimmer table display
        table_items = @all_processed_items.map do |item|
          product = item[:product] || item['product'] || ''
          aisle = item[:aisle] || item['aisle'] || ''
          [ product, aisle ]
        end

        self.items = table_items.first(10)
        self.download_enabled = !@all_processed_items.empty?
        self.status_text = "Loaded #{@all_processed_items.size} items from cache. Displaying top 10."
        self.clipboard_loaded = true
      end
      return
    end

    self.status_text = 'Processing batch text...'
    Thread.new do
      begin
        raw_items = batch_text.split(/[\n,;]|\s+and\s+/i).map(&:strip).reject(&:empty?)
        parse_and_process_items(raw_items)

        # Cache the results
        @processed_cache[cache_key] = @all_processed_items

        # Only show checkmark after successful completion
        Glimmer::LibUI.queue_main do
          self.clipboard_loaded = true
        end
      rescue StandardError => e
        Glimmer::LibUI.queue_main do
          self.status_text = "Error processing batch: #{e.message}"
          self.clipboard_loaded = false
        end
      end
    end
  end

  def download_pdf_report
    return unless @download_enabled

    # Generate a timestamped filename
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    filename = "grocery_report_#{timestamp}.pdf"
    path = File.join(Dir.home, "Downloads", filename)

    self.status_text = 'Generating PDF report...'
    Thread.new do
      begin
        PdfGenerator.new(@all_processed_items).generate(path)
        self.status_text = "PDF report saved to #{filename}"
        puts "✅ PDF saved to: #{path}"
        play_completion_sound
      rescue StandardError => e
        self.status_text = "Error generating PDF: #{e.message}"
        puts "❌ PDF generation failed: #{e.message}"
      end
    end
  end

  def attach_main_window(window)
    @main_window = window
  end

  def load_from_clipboard
    self.batch_text = Clipboard.paste
    self.clipboard_loaded = false  # Reset to false initially
    self.status_text = 'Loading from clipboard...'
    process_batch_text
  end

  private

  # TODO: Restore Google Docs functionality after fixing auth issues
  # def validate_credentials
  #   status, message = GoogleAuthService.validate_credentials!
  #   self.status_text = message
  #   case status
  #   when :created
  #     Glimmer::LibUI.queue_main { msg_box('Credentials Created', message) }
  #   when :invalid
  #     Glimmer::LibUI.queue_main { msg_box_error('Invalid Credentials', message) }
  #   end
  # end

  def parse_and_process_items(raw_items)
    return if raw_items.empty?

    start_time = Time.now
    self.status_text = "Categorizing #{raw_items.size} items... this may take a moment."

    # Use progress callback for real-time updates
    progress_callback = ->(message) do
      elapsed = Time.now - start_time
      Glimmer::LibUI.queue_main do
        self.status_text = "#{message} (#{elapsed.round(1)}s elapsed)"
      end
    end

    begin
      if @ollama_service.nil?
        raise "OllamaService not initialized. Please wait for initialization to complete."
      end

      @all_processed_items = @ollama_service.categorize_grocery_items_batch(raw_items, progress_callback)

      # Validate that we got valid results
      unless @all_processed_items.is_a?(Array) && @all_processed_items.all? { |item| item.is_a?(Hash) }
        raise "Invalid response format from Ollama service"
      end

      total_time = Time.now - start_time
      Glimmer::LibUI.queue_main do
        # Convert hash objects to arrays for Glimmer table display
        table_items = @all_processed_items.map do |item|
          product = item[:product] || item['product'] || 'Unknown'
          aisle = item[:aisle] || item['aisle'] || 'General'
          [ product.to_s, aisle.to_s ]
        end

        self.items = table_items.first(10)
        self.items = [ [ 'No items processed.', '' ] ] if self.items.empty?
        self.download_enabled = !@all_processed_items.empty?
        self.status_text = "Processed #{@all_processed_items.size} items in #{total_time.round(1)}s. Displaying top 10. PDF report is ready."
      end
    rescue StandardError => e
      puts "❌ Error processing items: #{e.message}"
      puts "🔧 Error details: #{e.class}: #{e.message}"
      puts "🔧 Backtrace: #{e.backtrace.first(3).join("\n")}"

      # Use fallback processing if OllamaService fails
      if e.message.include?("OllamaService not initialized") || e.message.include?("Invalid response format")
        puts "🔄 Using fallback processing..."
        fallback_results = raw_items.map do |item|
          { product: item, aisle: 'General', notes: 'Fallback' }
        end
        @all_processed_items = fallback_results

        Glimmer::LibUI.queue_main do
          table_items = fallback_results.map { |item| [ item[:product].to_s, item[:aisle].to_s ] }
          self.items = table_items.first(10)
          self.download_enabled = !@all_processed_items.empty?
          self.status_text = "Processed #{@all_processed_items.size} items using fallback mode. PDF report is ready."
        end
      else
        Glimmer::LibUI.queue_main do
          self.items = [ [ 'Error processing items', e.message ] ]
          self.download_enabled = false
          self.status_text = "Error: #{e.message}"
          self.clipboard_loaded = false
        end
      end
    end
  end

  # TODO: Restore Google Docs functionality after fixing auth issues
  # def process_google_doc
  #   return if google_doc_url.to_s.strip.empty?
  #
  #   self.status_text = 'Processing Google Doc...'
  #   Thread.new do
  #     begin
  #       raw_items = @google_docs_service.get_grocery_items(google_doc_url)
  #       parse_and_process_items(raw_items)
  #     rescue StandardError => e
  #       Glimmer::LibUI.queue_main do
  #         self.status_text = "Error processing Google Doc: #{e.message}"
  #       end
  #     end
  #   end
  # end
end

# The UI class is responsible for building the graphical user interface.
class UI
  include Glimmer

  attr_reader :presenter

  def initialize(presenter)
    @presenter = presenter
  end

  def launch
    window('Grocery Sorter', 800, 600) { |w|
      margined true
      presenter.attach_main_window(w)

      on_closing do
        # You can add any cleanup logic here
      end

      vertical_box {
        # TODO: Restore Google Docs functionality after fixing auth issues
        # create_google_doc_entry
        create_batch_entry
        create_results_table
        create_status_bar
      }
    }.show
  end

  private

  # TODO: Restore Google Docs functionality after fixing auth issues
  # def create_google_doc_entry
  #   group('Google Doc Import') {
  #     stretchy false
  #     horizontal_box {
  #       label 'Doc URL:'
  #       entry {
  #         text <=> [ presenter, :google_doc_url ]
  #         stretchy true
  #       }
  #       button('Process Document') {
  #         on_clicked { presenter.process_google_doc }
  #       }
  #     }
  #   }
  # end

  def create_batch_entry
    group('Lightning-Fast Batch Processing') {
      stretchy false
      vertical_box {
        horizontal_box {
          button('Load from Clipboard') {
            on_clicked { presenter.load_from_clipboard }
          }
          label('✅') {
            visible <= [ presenter, :clipboard_loaded ]
          }
        }
        horizontal_box {
          button('Download PDF Report') {
            enabled <=> [ presenter, :download_enabled ]
            on_clicked { presenter.download_pdf_report }
          }
        }
      }
    }
  end

  def create_results_table
    group('Categorized Groceries (showing top 10)') {
      stretchy true
      table {
        text_column('Item')
        text_column('Aisle')
        cell_rows <=> [ presenter, :items ]
      }
    }
  end

  def create_status_bar
    group('Status') {
      stretchy false
      label {
        text <= [ presenter, :status_text ]
      }
    }
  end
end


# Main application class
class GrocerySorterDesktopApp
  attr_reader :presenter

  def initialize
    @presenter = Presenter.new
  end

  def launch
    UI.new(presenter).launch
  end
end

# PDF Generation Logic - remains unchanged
class PdfGenerator
  require 'prawn'
  require 'prawn/table'

  # Suppress UTF-8 warning
  Prawn::Fonts::AFM.hide_m17n_warning = true

  APP_ROOT = File.expand_path('..', __dir__)

  def initialize(items)
    @items = items
  end

  def generate(path)
    # Group items by aisle - handle both hash and array formats
    items_by_aisle = @items.group_by do |item|
      if item.is_a?(Hash)
        item[:aisle] || item['aisle'] || 'General'
      else
        item[2] # Aisle is the 3rd element in array format
      end
    end

    Prawn::Document.generate(path) do |pdf|
      # Set up fonts with improved error handling
      setup_fonts(pdf)

      pdf.text "Grocery List Report", size: 24, style: :bold, align: :center
      pdf.move_down 20

      items_by_aisle.sort.to_h.each do |aisle, items|
        pdf.text aisle.to_s, size: 18, style: :bold
        pdf.move_down 10

        # Build table data - always use 2 columns
        table_data = [ [ 'Item', 'Aisle' ] ]
        items.each do |item|
          if item.is_a?(Hash)
            product = item[:product] || item['product'] || 'Unknown'
            aisle_val = item[:aisle] || item['aisle'] || 'General'
            table_data << [ product.to_s, aisle_val.to_s ]
          else
            product = item[0] || 'Unknown'
            aisle_val = item[1] || 'General'
            table_data << [ product.to_s, aisle_val.to_s ]
          end
        end

        # Calculate table width safely with fallback
        table_width = calculate_table_width(pdf)

        begin
          pdf.table(table_data, header: true, width: table_width) do
            row(0).font_style = :bold
            # No extra styling
          end
        rescue => e
          puts "⚠️ Table generation failed: #{e.message}"
          # Fallback: just list items without table
          items.each do |item|
            if item.is_a?(Hash)
              product = item[:product] || item['product'] || 'Unknown'
              aisle_val = item[:aisle] || item['aisle'] || 'General'
              pdf.text "• #{product} - #{aisle_val}"
            else
              product = item[0] || 'Unknown'
              aisle_val = item[1] || 'General'
              pdf.text "• #{product} - #{aisle_val}"
            end
          end
        end

        pdf.move_down 20
      end
    end
  end

  private

  def setup_fonts(pdf)
    begin
      # Try to use DejaVu fonts if available
      normal_font_path = File.join(APP_ROOT, 'vendor', 'assets', 'fonts', 'DejaVuSans.ttf')
      bold_font_path = File.join(APP_ROOT, 'vendor', 'assets', 'fonts', 'DejaVuSans-Bold.ttf')

      if File.exist?(normal_font_path) && File.exist?(bold_font_path)
        pdf.font_families.update("DejaVu" => {
          normal: normal_font_path,
          bold: bold_font_path
        })
        pdf.font "DejaVu"
        puts "✅ Using DejaVu fonts for PDF generation"
      else
        # Use default fonts
        pdf.font "Helvetica"
        puts "✅ Using default Helvetica font"
      end
    rescue => e
      # Always fallback to default font
      pdf.font "Helvetica"
      puts "✅ Using fallback Helvetica font"
    end
  end

  def calculate_table_width(pdf)
    # Try to get the page width, with multiple fallbacks
    begin
      # Method 1: Try bounds.width
      width = pdf.bounds.width
      return width if width && width > 0
    rescue => e
      puts "⚠️ Could not get bounds.width: #{e.message}"
    end

    begin
      # Method 2: Try page_width
      width = pdf.page_width
      return width if width && width > 0
    rescue => e
      puts "⚠️ Could not get page_width: #{e.message}"
    end

    begin
      # Method 3: Try page_size
      width = pdf.page_size[0]
      return width if width && width > 0
    rescue => e
      puts "⚠️ Could not get page_size: #{e.message}"
    end

    # Final fallback: use a reasonable default
    puts "⚠️ Using default table width of 500"
    500
  end
end


# Main application entry point
if __FILE__ == $0
  app = GrocerySorterDesktopApp.new
  app.launch
end
