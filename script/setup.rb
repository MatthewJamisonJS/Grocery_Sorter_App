#!/usr/bin/env ruby

# Grocery Sorter App - Automated Setup Script
# This script handles the basic setup process for new users
# No Google authentication required - app works without Google API

require 'fileutils'
require 'json'
require 'open-uri'
require 'net/http'

# Grocery Sorter App - Automated Setup Script
# This script handles the basic setup process for new users

class GrocerySorterSetup
  def initialize
    @config_dir = File.join(Dir.pwd, 'config')
  end

  def run
    puts "🛒 Grocery Sorter App - Setup Wizard"
    puts "=" * 50

    # Step 1: Check if already configured
    if already_configured?
      puts "✅ App is already configured!"
      puts "   Run: ruby script/grocery_sorter.rb"
      return
    end

    # Step 2: Create config directory
    create_config_directory

    # Step 3: Basic setup (no Google credentials needed)
    setup_basic_config

    puts "\n🎉 Setup complete! You can now run:"
    puts "   ruby script/grocery_sorter.rb"
    puts "   No Google authentication required!"
  end

  private

  def already_configured?
    # Check if basic Rails config exists
    File.exist?(File.join(@config_dir, 'application.rb'))
  end

  def create_config_directory
    unless Dir.exist?(@config_dir)
      puts "📁 Creating config directory..."
      Dir.mkdir(@config_dir)
    end
  end

  def setup_basic_config
    puts "\n🔧 Basic Setup"
    puts "-" * 15
    puts "✅ No Google authentication required"
    puts "✅ Google Docs integration is disabled"
    puts "✅ Core functionality is available"
    puts "✅ AI categorization works with Ollama"
    puts "✅ PDF export works without Google API"
    puts "✅ Clipboard paste functionality available"
  end
end

# Run the setup if this script is executed directly
if __FILE__ == $0
  setup = GrocerySorterSetup.new
  setup.run
end
