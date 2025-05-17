class ParseQuote < Temporalio::Activity::Definition
  def execute(quote_id)
    quote = Quote.find(quote_id)
    filepath = FileUploaderService.path_for(quote.filename)

    FileUploaderService.process_document(filepath)
  end
end
