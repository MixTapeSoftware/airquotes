class FileUploaderService
  def self.upload(file)
    return nil unless file.present?

    original_filename = file.original_filename
    extension = File.extname(original_filename)
    uuid_filename = "#{SecureRandom.uuid}#{extension}"

    # Ensure storage directory exists
    storage_path = Rails.root.join("uploads")
    FileUtils.mkdir_p(storage_path) unless Dir.exist?(storage_path)

    # Save the file with UUID name
    file_path = storage_path.join(uuid_filename)
    Rails.logger.info "Saving file to: #{file_path}"

    begin
      File.open(file_path, "wb") do |f|
        f.write(file.read)
      end
      Rails.logger.info "File saved successfully"

      # Verify file was saved
      if File.exist?(file_path)
        size = File.size(file_path)
        Rails.logger.info "File exists with size: #{size} bytes"
      else
        Rails.logger.error "File was not saved successfully"
        return nil
      end
    rescue => e
      Rails.logger.error "Error saving file: #{e.message}"
      return nil
    end

    {
      original_filename: original_filename,
      uuid_filename: uuid_filename
    }
  end
end
