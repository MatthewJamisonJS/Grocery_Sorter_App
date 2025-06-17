require "google/apis/docs_v1"

class GoogleDocsService
  Docs = Google::Apis::DocsV1

  def initialize
    @service = Docs::DocsService.new
    @service.client_options.application_name = GoogleAuthService::APPLICATION_NAME
    @service.authorization = GoogleAuthService.authorize
  end

  def get_grocery_items(doc_id)
    doc = @service.get_document(doc_id)
    items = []

    doc.body.content.each do |element|
      next unless element.paragraph&.elements

      # Extract all text runs in the paragraph and join them together
      text = element.paragraph.elements.map do |e|
        e.text_run&.content
      end.compact.join.strip

      items << text unless text.empty?
    end

    items
  end
end
