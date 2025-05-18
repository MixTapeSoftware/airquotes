require "net/http"
require "json"

class LlamaExtractAgent
  BASE_URL = "https://api.cloud.llamaindex.ai/api/v1/extraction".freeze
  AGENT_NAME = "hvac_estimate_extractor".freeze

  class << self
    def initialize(schema)
      # Try to get existing agent
      existing_id = find_agent_id
      return existing_id if existing_id

      # Create new agent if not found
      create_agent(schema)
    end

    private

    def find_agent_id
      response = make_request(:get, "extraction-agents/by-name/#{AGENT_NAME}")
      response["id"]
    rescue => e
      # Only continue if agent not found, re-raise other errors
      raise unless e.message.include?("404")
      nil
    end

    def create_agent(schema)
      data = {
        name: AGENT_NAME,
        data_schema: schema,
        config: { extraction_target: "PER_DOC", extraction_mode: "BALANCED" }
      }

      response = make_request(:post, "extraction-agents", data)
      response["id"] or raise "Failed to create agent"
    end

    def make_request(method, path, data = nil)
      uri = URI("#{BASE_URL}/#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      if method == :get
        req = Net::HTTP::Get.new(uri)
      else
        req = Net::HTTP::Post.new(uri)
        req["Content-Type"] = "application/json"
        req.body = data.to_json if data
      end

      req["Authorization"] = "Bearer #{ENV["LLAMA_CLOUD_API_KEY"] || raise("Missing API key")}"
      req["Accept"] = "application/json"

      res = http.request(req)

      unless res.is_a?(Net::HTTPSuccess)
        raise "HTTP Error #{res.code}: #{res.body[0..100]}"
      end

      JSON.parse(res.body)
    end
  end
end
