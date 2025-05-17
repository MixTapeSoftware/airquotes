require "net/http"
require "json"

class LlamaCloudService
  BASE_URL = "https://api.cloud.llamaindex.ai/api/v1/parsing"

  class << self
    def process_document(file_path)
      job_id = upload(file_path)
      wait_for_completion(job_id)
      get_result(job_id)
    rescue => e
      Rails.logger.error "LlamaCloud Error: #{e.message}"
      nil
    end

    private
      def upload(file_path)
        file = File.open(file_path, "rb")
        form_data = [
          [ "file", file, { filename: File.basename(file_path), content_type: "application/pdf" } ]
        ]

        response = post("upload", form_data)
        response["id"] or raise "No id in response: #{response.inspect}"
      end

      def wait_for_completion(job_id)
        attempt = 0
        max_attempts = 30 # Die after 30 attempts (about 45 seconds)

        loop do
          attempt += 1
          response = get("job/#{job_id}")
          status = response["status"]

          Rails.logger.debug "LlamaCloud: Job status check ##{attempt}: #{status}"

          break if status == "SUCCESS"

          if status == "FAILED"
            error_details = response["error"] || "unknown error"
            Rails.logger.error "LlamaCloud: Job failed - #{error_details}"
            raise "Job failed: #{error_details}"
          end

          if attempt >= max_attempts
            Rails.logger.error "LlamaCloud: Job timed out after #{max_attempts} attempts"
            raise "Job timed out after #{max_attempts} attempts (#{max_attempts * 1.5} seconds)"
          end

          sleep 1.5
        end
      end

      def get_result(job_id)
        api_call(:get, "job/#{job_id}/result/markdown", raw: true)
      end

      def get(path)
        api_call(:get, path)
      end

      def post(path, form_data)
        api_call(:post, path, form_data: form_data)
      end

      def api_call(method, path, form_data: nil, raw: false)
        uri = URI("#{BASE_URL}/#{path}")

        http = Net::HTTP.new(uri.host, uri.port).tap { |h| h.use_ssl = true }

        req = method == :get ? Net::HTTP::Get.new(uri) : Net::HTTP::Post.new(uri)
        req["Authorization"] = "Bearer #{ENV["LLAMA_CLOUD_API_KEY"] || raise("Missing LLAMA_CLOUD_API_KEY")}"
        req["Accept"] = "application/json"

        req.set_form(form_data, "multipart/form-data") if form_data

        res = http.request(req)

        unless res.is_a?(Net::HTTPSuccess)
          raise "HTTP Error #{res.code}: #{res.body[0..500]}"
        end

        raw ? res.body : JSON.parse(res.body)
      rescue JSON::ParserError => e
        raise "Invalid JSON response: #{e.message}"
      end
  end
end
