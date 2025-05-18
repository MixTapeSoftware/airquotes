require "temporalio/workflow"
require "temporalio/activity"
require_relative "activities/structure_quote"
require_relative "activities/parse_quote"

class QuoteProcessorWorkflow < Temporalio::Workflow::Definition
  require "temporalio/client"
  require "temporalio/worker"

  class << self
    def run(quote_id)
      handle = client.start_workflow(
        QuoteProcessorWorkflow,
        quote_id,
        id: SecureRandom.uuid,
        task_queue: "quote-parse"
      )

      handle.id
    end

    def client
      @client ||= Temporalio::Client.connect("localhost:7233", "default")
    end
  end

  def execute(quote_id)
    puts "Starting workflow for quote #{quote_id}"
    begin
      # First structure the quote
      structure_result = Temporalio::Workflow.execute_activity(
        StructureQuote,
        quote_id,
        schedule_to_close_timeout: 300,
        start_to_close_timeout: 300,
        retry_policy: retry_policy
      )
      puts "StructureQuote activity completed: #{structure_result.inspect}"

      # Then parse the quote
      parse_result = Temporalio::Workflow.execute_activity(
        ParseQuote,
        quote_id,
        schedule_to_close_timeout: 300,
        start_to_close_timeout: 300,
        retry_policy: retry_policy
      )
      puts "ParseQuote activity completed: #{parse_result.inspect}"

      parse_result
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
      max_attempts: 3,
      non_retryable_error_types: [ "ActiveRecord::RecordNotFound" ]
    )
  end
end
