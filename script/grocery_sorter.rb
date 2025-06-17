require 'glimmer-dsl-libui'
require 'json'
require 'colorize'
# require 'ollama-ai' # Uncomment when gem is available

class GrocerySorterGUI
  include Glimmer

  attr_accessor :table_data

  def initialize
    @table_data = []
  end

  def launch
    window('Grocery Sorter', 400, 300) {
      vertical_box {
        label('Your Grocery List:')
        @table = table {
          text_column('Item')
          text_column('Aisle')
          cell_rows bind(self, :table_data)
        }
        button('Load List') {
          stretchy false
          on_clicked { load_and_map_groceries }
        }
      }
    }.show
  end

  def load_and_map_groceries
    items = fetch_grocery_list
    mapped = assign_aisles_with_ollama(items)
    self.table_data = mapped.map { |h| [ h[:product], h[:aisle] ] }
  end

  def fetch_grocery_list
    # Placeholder for Google Docs API integration
    [ 'Milk', 'Eggs', 'Bread', 'Apples' ]
  end

  def assign_aisles_with_ollama(items)
    begin
      # client = Ollama::Client.new
      # prompt = "Map the following grocery items to aisles/categories: #{items.to_json}"
      # response = client.call(prompt: prompt)
      # parsed_response = JSON.parse(response)
      # parsed_response.map { |item| { product: item['product'], aisle: item['aisle'] } }
      # Placeholder response for now:
      items.map { |item| { product: item, aisle: "Aisle #{rand(1..10)}" } }
    rescue StandardError => e
      puts "Error: #{e.message}".colorize(:red)
      []
    end
  end
end

GrocerySorterGUI.new.launch
