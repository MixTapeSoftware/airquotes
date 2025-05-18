class StructureQuote < Temporalio::Activity::Definition
  def execute(quote_id)
    puts "=== Starting StructureQuote activity ==="
    puts "Quote ID: #{quote_id}"

    quote = Quote.find(quote_id)
    filepath = FileUploaderService.path_for(quote.filename)

    schema_path = Rails.root.join("config", "schema.json")
    schema = JSON.parse(File.read(schema_path))
    LlamaExtractAgent.initialize(schema)

    structured_data = LlamaExtractService.process_document(filepath)

    quote.update(structured: structured_data)
    quote_id
  end
end
