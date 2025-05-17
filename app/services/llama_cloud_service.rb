require "net/http"
require "json"

class LlamaCloudService
  BASE_URL = "https://api.cloud.llamaindex.ai/api/v1/parsing"

  class << self
    def process_document(file_path)
      raise "File not found: #{file_path}" unless File.exist?(file_path)

      job_id = upload(file_path)
      wait_for_completion(job_id)
      get_result(job_id)
    end

    private
      def upload(file_path)
        file = File.open(file_path, "rb")
        form_data = [
          [ "file", file, { filename: File.basename(file_path), content_type: "application/pdf" } ]
        ]

        response = JSON.parse(post("upload", form_data))
        response["id"] or raise "No id in response: #{response.inspect}"
      end

      def wait_for_completion(job_id)
        attempt = 0
        max_attempts = 30 # Die after 30 attempts (about 45 seconds)

        loop do
          attempt += 1
          response = JSON.parse(get("job/#{job_id}"))
          status = response["status"]

          break if status == "SUCCESS"

          if status == "FAILED"
            error_details = response["error"] || "unknown error"
            raise "Job failed: #{error_details}"
          end

          if attempt >= max_attempts
            raise "Job timed out after #{max_attempts} attempts (#{max_attempts * 1.5} seconds)"
          end

          sleep 1.5
        end
      end

      def get_result(job_id)
        get("job/#{job_id}/result/markdown")
      end

      def get(path)
        api_call(:get, path)
      end

      def post(path, form_data)
        api_call(:post, path, form_data: form_data)
      end

      def api_call(method, path, form_data: nil)
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

        res.body
      end
  end
end
