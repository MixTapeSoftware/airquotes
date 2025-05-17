require "temporalio"
require "temporalio/client"
require "temporalio/worker"
require_relative "../../app/temporal/quote_processor_workflow"
require_relative "../../app/temporal/activities/parse_quote"

namespace :temporal do
  desc "Start the Temporal worker"
  task worker: :environment do
    puts "Starting Temporal worker..."
    client = Temporalio::Client.connect("localhost:7233", "default")

    worker = Temporalio::Worker.new(
      client: client,
      task_queue: "quote-parse",
      workflows: [ QuoteProcessorWorkflow ],
      activities: [ ParseQuote ]
    )

    puts "Worker started, polling for tasks..."
    worker.run
  end
end
