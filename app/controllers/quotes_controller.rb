class QuotesController < ApplicationController
  include QuoteCompareHelpers
  helper_method :needs_line_items_partial?, :array_of_line_items?, :hash_containing_line_items?


  def index
    @quotes = Quote.order(created_at: :desc)
  end

  def compare
    @quotes = Quote.where(id: params[:quote_ids]).order(created_at: :desc)
    @sections = extract_comparison_sections(@quotes)

    Rails.logger.debug "Found quotes: #{@quotes.map(&:id)}"
    Rails.logger.debug "Found sections: #{@sections}"
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

        workflow_id = QuoteProcessorWorkflow.run(quote.id)

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

  private

  def extract_comparison_sections(quotes)
    # Extract all unique sections from the structured data
    sections = Set.new
    quotes.each do |quote|
      next unless quote.structured && quote.structured["data"]
      quote.structured["data"].each do |section, _|
        sections.add(section)
      end
    end
    sections.to_a.sort
  end
end
