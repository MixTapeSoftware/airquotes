require "temporalio/worker"
require_relative "quote_processor_workflow"
require_relative "activities/parse_quote"
require_relative "activities/structure_quote"

class QuoteWorker
  def self.run
    client = Temporalio::Client.connect("localhost:7233", "default")

    puts "Registering activities: ParseQuote, StructureQuote"
    worker = Temporalio::Worker.new(
      client,
      "quote-parse",
      workflows: [ QuoteProcessorWorkflow ],
      activities: [ ParseQuote, StructureQuote ]
    )

    puts "Starting worker for task queue: quote-parse..."
    puts "Registered activities: #{worker.activities.map(&:name).join(', ')}"
    worker.run
  end
end
