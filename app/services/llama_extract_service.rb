require "net/http"
require "json"

class LlamaExtractService
  BASE_URL = "https://api.cloud.llamaindex.ai/api/v1/extraction".freeze
  FILES_URL = "https://api.cloud.llamaindex.ai/api/v1/files".freeze
  AGENT_NAME = "hvac_estimate_extractor".freeze

  class << self
    def create_agent
      schema_path = Rails.root.join("config", "schema.json")
      raise "Schema file not found at #{schema_path}" unless File.exist?(schema_path)

      schema = JSON.parse(File.read(schema_path))
      response = api_post("extraction-agents", {
        name: AGENT_NAME,
        data_schema: schema,
        config: {
          extraction_target: "PER_DOC",
          extraction_mode: "BALANCED"
        }
      })

      response["id"] or raise "No id in response: #{response.inspect}"
    end

    def process_document(file_path)
      raise "File not found: #{file_path}" unless File.exist?(file_path)

      file_id = upload_file(file_path)
      job_id = start_extraction_job(file_id)
      wait_for_completion(job_id)
      get_result(job_id)
    end

    private

    def upload_file(file_path)
      file = File.open(file_path, "rb")
      form_data = [
        [ "upload_file", file, { filename: File.basename(file_path), content_type: "application/pdf" } ]
      ]

      response = upload_form_data(form_data)
      response["id"] or raise "No id in file upload response: #{response.inspect}"
    end

    def start_extraction_job(file_id)
      agent_id = get_agent_id
      response = api_post("jobs", {
        extraction_agent_id: agent_id,
        file_id: file_id
      })

      response["id"] or raise "No id in job response: #{response.inspect}"
    end

    def get_agent_id
      response = api_get("extraction-agents/by-name/#{AGENT_NAME}")
      response["id"] or raise "No id in agent response: #{response.inspect}"
    end

    def wait_for_completion(job_id)
      30.times do  # Try for a minute or so
        sleep 2 # Ain't going to be done right away, ever.
        response = api_get("jobs/#{job_id}")

        case response["status"]
        when "SUCCESS"
          return true
        when "FAILED"
          error_details = response["error"] || "unknown error"
          raise "Job failed: #{error_details}"
        end
      end

      raise "Job timed out after 45 seconds"
    end

    def get_result(job_id)
      api_get("jobs/#{job_id}/result")
    end

    def api_get(path)
      request(:get, "#{BASE_URL}/#{path}")
    end

    def api_post(path, data)
      request(:post, "#{BASE_URL}/#{path}", json_data: data)
    end

    def upload_form_data(form_data)
      request(:post, FILES_URL, form_data: form_data)
    end

    def request(method, url, json_data: nil, form_data: nil)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      req = method == :get ? Net::HTTP::Get.new(uri) : Net::HTTP::Post.new(uri)
      req["Authorization"] = "Bearer #{api_key}"
      req["Accept"] = "application/json"

      if form_data
        req.set_form(form_data, "multipart/form-data")
      elsif json_data
        req["Content-Type"] = "application/json"
        req.body = json_data.to_json
      end

      res = http.request(req)

      unless res.is_a?(Net::HTTPSuccess)
        raise "HTTP Error #{res.code}: #{res.body[0..500]}"
      end

      JSON.parse(res.body)
    end

    def api_key
      ENV["LLAMA_CLOUD_API_KEY"] || raise("Missing LLAMA_CLOUD_API_KEY")
    end
  end
end
