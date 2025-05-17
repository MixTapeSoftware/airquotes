require "temporalio/worker"
require_relative "quote_processor_workflow"
require_relative "activities/parse_quote"

class QuoteWorker
  def self.run
    client = Temporalio::Client.connect("localhost:7233", "default")

    worker = Temporalio::Worker.new(
      client,
      "quote-parse",
      workflows: [ QuoteProcessorWorkflow ],
      activities: [ ParseQuote ]
    )

    puts "Starting worker for task queue: quote-parse..."
    worker.run
  end
end
