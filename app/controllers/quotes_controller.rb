class QuotesController < ApplicationController
  def index
    @quotes = Quote.order(created_at: :desc)
  end

  def destroy
    @quote = Quote.find(params[:id])
    @quote.destroy
    respond_to do |format|
      format.html { redirect_to quotes_path, notice: "Quote was successfully deleted." }
      format.json { head :no_content }
    end
  end

  def upload
    if params[:quote] && params[:quote][:document]
      file = params[:quote][:document]
      result = FileUploaderService.upload(file)


      if result
        quote = Quote.create!(
          name: result[:original_filename],
          filename: result[:uuid_filename]
        )

        workflow_handle = QuoteProcessorWorkflow.run(quote.id)
        workflow_id = workflow_handle.id
        Rails.logger.info "Started workflow with ID: #{workflow_id}"


        render json: {
          id: quote.id,
          filename: result[:original_filename],
          path: result[:uuid_filename],
          filepath: result[:filepath],
          workflow_id: workflow_id
        }
      else
        render json: { error: "Invalid file" }, status: :unprocessable_entity
      end
    else
      render json: { error: "No file uploaded" }, status: :unprocessable_entity
    end
  end

  def quote_item
    @quote = Quote.find(params[:id])
    render partial: "quote_item", locals: { quote: @quote }, formats: [ :html ]
  end
end
