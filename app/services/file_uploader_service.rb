# [Local] File Upload Service
#
# For the purposes of this demo we're loading locally.
# In a production service we would likely use a cloud provider.
class FileUploaderService
  class << self
    def upload(file)
      return nil unless file.present?

      original_filename = file.original_filename
      extension = File.extname(original_filename)
      uuid_filename = "#{SecureRandom.uuid}#{extension}"

      # Construct the full file path
      file_path = upload_path.join(uuid_filename)

      Rails.logger.info "Saving file to: #{file_path}"

      begin
        File.open(file_path, "wb") do |f|
          f.write(file.read)
        end

        # Verify file was saved
        unless File.exist?(file_path)
          Rails.logger.error "File was not saved successfully"
          return nil
        end

        {
          original_filename: original_filename,
          uuid_filename: uuid_filename,
          full_path: file_path
        }
      rescue => e
        Rails.logger.error "Error saving file: #{e.message}"
        nil
      end
    end

    # Returns the directory path for uploads
    def upload_path
      dir = Rails.root.join("uploads")
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      dir
    end

    # Convert a UUID filename to its full path
    def path_for(uuid_filename)
      upload_path.join(uuid_filename)
    end
  end
end
