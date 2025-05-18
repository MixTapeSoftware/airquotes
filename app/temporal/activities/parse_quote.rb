class ParseQuote < Temporalio::Activity::Definition
  def execute(quote_id)
    puts "=== Starting ParseQuote activity ==="
    puts "Quote ID: #{quote_id}"

    quote = Quote.find(quote_id)
    filepath = FileUploaderService.path_for(quote.filename)

    schema_path = Rails.root.join("config", "schema.json")
    schema = JSON.parse(File.read(schema_path))
    LlamaExtractAgent.initialize(schema)

    structured_data = LlamaExtractService.process_document(filepath)
    markdown_result = LlamaCloudService.process_document(filepath)

    quote.update(
      structured: structured_data,
      parsed_result: markdown_result
    )

    quote_id
  end
end
