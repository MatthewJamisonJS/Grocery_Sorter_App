# frozen_string_literal: true

require 'glimmer-dsl-libui'
require 'google/apis/docs_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'
require 'os'
require 'prawn'
require 'prawn/table'
require 'concurrent-ruby'
require 'clipboard'

# Load application services
require_relative '../app/services/google_auth_service'
require_relative '../app/services/google_docs_service'
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

    # Initialize services in the background
    Thread.new do
      self.status_text = 'Initializing services...'
      validate_credentials
      @google_docs_service = GoogleDocsService.new
      @ollama_service = OllamaService.new
      self.status_text = 'Services initialized. Ready.'
    end
  end

  def process_google_doc
    return if google_doc_url.to_s.strip.empty?

    self.status_text = 'Processing Google Doc...'
    Thread.new do
      begin
        raw_items = @google_docs_service.get_grocery_items(google_doc_url)
        parse_and_process_items(raw_items)
      rescue StandardError => e
        Glimmer::LibUI.queue_main do
          self.status_text = "Error processing Google Doc: #{e.message}"
        end
      end
    end
  end

  def process_batch_text
    return if batch_text.to_s.strip.empty?

    self.status_text = 'Processing batch text...'
    Thread.new do
      begin
        raw_items = batch_text.split(/[\n,;]|\s+and\s+/i).map(&:strip).reject(&:empty?)
        parse_and_process_items(raw_items)
      rescue StandardError => e
        Glimmer::LibUI.queue_main do
          self.status_text = "Error processing batch text: #{e.message}"
        end
      end
    end
  end

  def download_pdf_report
    return unless @download_enabled

    path = Glimmer::LibUI.queue_main { @main_window&.save_file('report.pdf') }

    if path
      self.status_text = 'Generating PDF report...'
      Thread.new do
        begin
          PdfGenerator.new(@all_processed_items).generate(path)
          self.status_text = "PDF report saved to #{File.basename(path)}"
        rescue StandardError => e
          self.status_text = "Error generating PDF: #{e.message}"
          Glimmer::LibUI.queue_main { msg_box_error('PDF Generation Failed', e.message) }
        end
      end
    else
      self.status_text = 'PDF save cancelled.'
    end
  end

  def attach_main_window(window)
    @main_window = window
  end

  def load_from_clipboard
    self.batch_text = Clipboard.paste
    self.clipboard_loaded = true
    process_batch_text
  end

  private

  def validate_credentials
    status, message = GoogleAuthService.validate_credentials!
    self.status_text = message
    case status
    when :created
      Glimmer::LibUI.queue_main { msg_box('Credentials Created', message) }
    when :invalid
      Glimmer::LibUI.queue_main { msg_box_error('Invalid Credentials', message) }
    end
  end

  def parse_and_process_items(raw_items)
    return if raw_items.empty?

    self.status_text = "Categorizing #{raw_items.size} items... this may take a moment."
    @all_processed_items = @ollama_service.categorize_grocery_items(raw_items)

    Glimmer::LibUI.queue_main do
      self.items = @all_processed_items.first(10)
      self.items = [ [ 'No items processed.', '', '' ] ] if self.items.empty?
      self.download_enabled = !@all_processed_items.empty?
      self.status_text = "Processed #{@all_processed_items.size} items. Displaying top 10. PDF report is ready."
    end
  end
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
        create_google_doc_entry
        create_batch_entry
        create_results_table
        create_status_bar
      }
    }.show
  end

  private

  def create_google_doc_entry
    group('Google Doc Import') {
      stretchy false
      horizontal_box {
        label 'Doc URL:'
        entry {
          text <=> [ presenter, :google_doc_url ]
          stretchy true
        }
        button('Process Document') {
          on_clicked { presenter.process_google_doc }
        }
      }
    }
  end

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
        text_column('Category')
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
  APP_ROOT = File.expand_path('..', __dir__)

  def initialize(items)
    @items = items
  end

  def generate(path)
    # Group items by aisle
    items_by_aisle = @items.group_by { |item| item[2] } # Aisle is the 3rd element

    Prawn::Document.generate(path) do |pdf|
      pdf.font_families.update("DejaVu" => {
        normal: File.join(APP_ROOT, 'vendor/assets/fonts/DejaVuSans.ttf'),
        bold: File.join(APP_ROOT, 'vendor/assets/fonts/DejaVuSans-Bold.ttf')
      })
      pdf.font "DejaVu"

      pdf.text "Grocery List Report", size: 24, style: :bold, align: :center
      pdf.move_down 20

      items_by_aisle.sort.to_h.each do |aisle, items|
        pdf.text aisle, size: 18, style: :bold
        pdf.move_down 10

        table_data = [ [ 'Item', 'Category' ] ] + items.map { |item| [ item[0], item[1] ] }

        pdf.table(table_data, header: true, width: pdf.bounds.width) do
          row(0).font_style = :bold
          self.row_colors = [ "FFFFFF", "F0F0F0" ]
        end
        pdf.move_down 20
      end
    end
  end
end


# Main application entry point
if __FILE__ == $0
  app = GrocerySorterDesktopApp.new
  app.launch
end
