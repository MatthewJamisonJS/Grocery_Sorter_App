class GrocerySorterDesktopApp
  # ...existing code...

  def window(title, width, height, &block)
    # Define the behavior for creating a window
    puts "Creating window: #{title}, Width: #{width}, Height: #{height}"
    block.call if block_given?
  end

  # ...existing code...
end
