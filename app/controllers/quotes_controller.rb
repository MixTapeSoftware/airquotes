class QuotesController < ApplicationController
  def index
  end

  def upload
    if params[:quote] && params[:quote][:document]
      file = params[:quote][:document]
      filename = file.original_filename

      # Ensure the uploads directory exists
      FileUtils.mkdir_p(Rails.root.join("uploads"))

      # Save the file
      filepath = Rails.root.join("uploads", filename)
      File.binwrite(filepath, file.read)

      # Create a new quote record with the file path
      quote = Quote.create!(
        path: filepath.to_s,
        name: filename
      )

      render json: {
        success: true,
        filename: filename,
        path: quote.path
      }
    else
      render json: { success: false, error: "No file provided" }, status: :unprocessable_entity
    end
  end
end
