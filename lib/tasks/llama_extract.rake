namespace :llama_extract do
  desc "Create the LlamaParse extraction agent if it doesn't exist"
  task create_agent: :environment do
    begin
      agent_id = LlamaExtractService.create_agent
      puts "Successfully created LlamaParse extraction agent with ID: #{agent_id}"
    rescue => e
      if e.message.include?("already exists")
        puts "LlamaParse extraction agent already exists"
      else
        puts "Error creating LlamaParse extraction agent: #{e.message}"
        raise e
      end
    end
  end
end
