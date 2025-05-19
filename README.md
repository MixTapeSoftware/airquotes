# AirQuotes

The HVAC Quotation Comparison Platform.

## Prerequisites

- [asdf](https://asdf-vm.com/) - Version manager
- Docker and Docker Compose
- [Llama Cloud API Key](https://docs.cloud.llamaindex.ai/api_key) - Required for AI features
- [Temporal CLI](https://temporal.io/setup/install-temporal-cli) - Required for workflow management

## Installation

### 1. Install asdf and required plugins

Follow the [official asdf getting started guide](https://asdf-vm.com/guide/getting-started.html) to install asdf, then:

```bash
# Install Ruby plugin for asdf
asdf plugin add ruby

# Install Node.js plugin for asdf
asdf plugin add nodejs

# Install required versions
asdf install ruby 3.2.3
asdf install nodejs 20.11.1

# Set local versions
asdf local ruby 3.2.3
asdf local nodejs 20.11.1
```

### 2. Install Temporal CLI

```bash
# Install Temporal CLI using Homebrew
brew install temporal

# Start Temporal development server
temporal server start-dev
```

### 3. Install Rails and dependencies

```bash
# Install Rails
gem install rails

# Install project dependencies
bundle install

# Install JavaScript dependencies
yarn install

# Setup the database
rails db:create db:migrate
```

### 4. Environment Setup

```bash
# Export required environment variables
export LLAMA_CLOUD_API_KEY=YOUR_KEY_HERE  # Get your key from https://docs.cloud.llamaindex.ai/api_key
```

## Running the Application

### 1. Start Docker Services

```bash
# Start the required Docker services
docker compose up -d
```

### 2. Start the Rails Server

```bash
# Start the Rails server
rails server
```

### 3. Start the Worker

In a separate terminal:

```bash
# Start the background worker
rails temporal:worker
```

The application should now be running at http://localhost:3000

## Development

- Rails server runs on http://localhost:3000
- Docker services are configured in `docker-compose.yml`
- Background jobs are processed by the Temporal worker
- Temporal UI is available at http://localhost:8080

## Troubleshooting

If you encounter any issues:

1. Ensure all Docker services are running:
   ```bash
   docker compose ps
   ```

2. Check the Rails logs:
   ```bash
   tail -f log/development.log
   ```

3. Verify the worker is running:
   ```bash
   ps aux | grep temporal:worker
   ```

4. Check Temporal server status:
   ```bash
   temporal server status
   ```

