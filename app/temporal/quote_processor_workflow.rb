require "temporalio/workflow"
require "temporalio/activity"

class QuoteProcessorWorkflow < Temporalio::Workflow::Definition
  require "temporalio/client"
  require "temporalio/worker"

  class << self
    def run(quote_id)
      # This is like Sidekiq's perform_async - it returns immediately
      handle = client.execute_workflow(
        QuoteProcessorWorkflow,
        quote_id,
        id: SecureRandom.uuid,
        task_queue: "quote-parse"
      )

      # Return just the ID, not the handle
      handle.id
    end

    def client
      @client ||= Temporalio::Client.connect("localhost:7233", "default")
    end
  end

  def execute(quote_id)
    puts "Starting workflow for quote #{quote_id}"
    begin
      result = Temporalio::Workflow.execute_activity(
        ParseQuote,
        quote_id,
        schedule_to_close_timeout: 300,
        start_to_close_timeout: 300,
        retry_policy: retry_policy
      )
      puts "Workflow received activity result: #{result.inspect}"
      result
    rescue => e
      puts "Workflow encountered error: #{e.message}"
      puts e.backtrace.join("\n")
      raise
    end
  end

  def retry_policy
    Temporalio::RetryPolicy.new(
      initial_interval: 1,
      backoff_coefficient: 2.0,
      max_interval: 100,
      max_attempts: 3
    )
  end
end
