class ParseQuote < Temporalio::Activity::Definition
  def execute(quote_id)
    puts "=== Starting ParseQuote activity ==="
    puts "Quote ID: #{quote_id}"

    begin
      puts "Finding quote..."
      quote = Quote.find(quote_id)
      puts "Found quote: #{quote.inspect}"

      puts "Getting filepath..."
      filepath = FileUploaderService.path_for(quote.filename)
      puts "Filepath: #{filepath}"

      puts "Calling LlamaCloudService..."
      result = LlamaCloudService.process_document(filepath)
      puts "LlamaCloud result: #{result.inspect}"

      if result.nil?
        puts "WARNING: LlamaCloud returned nil result"
      end

      puts "=== Activity complete ==="
      result
    rescue => e
      puts "ERROR in ParseQuote activity: #{e.message}"
      puts e.backtrace.join("\n")
      raise
    end
  end
end
