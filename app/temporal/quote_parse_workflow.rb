class QuoteProcessorWorkflow < Temporalio::Workflow::Definition
  def execute(quote_id)
    Temporalio::Workflow.execute_activity(
      ParseQuote,
      quote_id,
      schedule_to_close_timeout: 300
    )
  end
end
