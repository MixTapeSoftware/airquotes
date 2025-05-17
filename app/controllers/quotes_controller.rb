class QuotesController < ApplicationController
  def index
  end

  def upload
    if params[:quote] && params[:quote][:document]
      file = params[:quote][:document]
      result = FileUploaderService.upload(file)

      if result
        quote = Quote.create!(
          name: result[:original_filename],
          path: result[:uuid_filename]
        )

        render json: {
          filename: result[:original_filename],
          path: result[:uuid_filename]
        }
      else
        render json: { error: "Invalid file" }, status: :unprocessable_entity
      end
    else
      render json: { error: "No file uploaded" }, status: :unprocessable_entity
    end
  end
end
