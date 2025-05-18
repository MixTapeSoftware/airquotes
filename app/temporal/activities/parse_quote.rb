class ParseQuote < Temporalio::Activity::Definition
  def execute(quote_id)
    puts "=== Starting ParseQuote activity ==="
    puts "Quote ID: #{quote_id}"

    quote = Quote.find(quote_id)
    filepath = FileUploaderService.path_for(quote.filename)

    markdown_result = LlamaCloudService.process_document(filepath)

    quote.update(parsed_result: markdown_result)
    quote_id
  end
end
