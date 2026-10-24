# TokenTally Ruby SDK

Track your AI API usage with [TokenTally](https://tokentally.cloud). Get real-time analytics, cost tracking, and usage insights for Claude, OpenAI, and other AI providers.

Sign up and get your API key at **[tokentally.cloud](https://tokentally.cloud)** (Settings → API Keys).

## Installation

Add to your Gemfile:

```ruby
gem 'tokentally'
```

Or install directly:

```bash
gem install tokentally
```

## Quick Start

```ruby
require 'tokentally'

# Initialize the client
client = TokenTally::Client.new(api_key: 'tt_your_api_key')

# Track usage
response = client.track_usage(
  tokens_in: 150,
  tokens_out: 300,
  model: 'claude-3-sonnet-20240229',
  provider: 'anthropic',
  metadata: {
    feature: 'chat',
    user_id: 'user123'
  }
)

puts "Recorded! Cost: $#{response[:cost_usd]}"
```

## Global Configuration

```ruby
TokenTally.configure do |config|
  config.api_key = 'tt_your_api_key'
  config.base_url = 'https://api.tokentally.cloud'
  config.timeout = 30
end

# Then use the global client
TokenTally.track_usage(
  tokens_in: 100,
  tokens_out: 200,
  model: 'claude-3-sonnet-20240229'
)
```

## Usage with Anthropic SDK

```ruby
require 'tokentally'
require 'anthropic'

client = TokenTally::Client.new(api_key: 'tt_your_api_key')
anthropic = Anthropic::Client.new

# Make API call
message = anthropic.messages.create(
  model: 'claude-3-sonnet-20240229',
  max_tokens: 1000,
  messages: [{ role: 'user', content: 'Hello!' }]
)

# Track usage
client.track_usage(
  tokens_in: message.usage.input_tokens,
  tokens_out: message.usage.output_tokens,
  model: message.model,
  provider: 'anthropic',
  stop_reason: message.stop_reason,
  metadata: { feature: 'greeting' }
)
```

## Automatic Timing with Block

```ruby
result = client.with_tracking(
  model: 'claude-3-sonnet-20240229',
  provider: 'anthropic',
  metadata: { feature: 'summarization' }
) do
  anthropic.messages.create(
    model: 'claude-3-sonnet-20240229',
    max_tokens: 1000,
    messages: [{ role: 'user', content: 'Summarize...' }]
  )
end
```

## Error Handling

```ruby
begin
  client.track_usage(tokens_in: 100, tokens_out: 200, model: 'claude-3-sonnet')
rescue TokenTally::RateLimitError
  puts 'Rate limit exceeded. Upgrade for unlimited.'
rescue TokenTally::AuthenticationError
  puts 'Invalid API key.'
rescue TokenTally::Error => e
  puts "Error: #{e.message}"
end
```

## Links

- Website & dashboard: [tokentally.cloud](https://tokentally.cloud)
- Python SDK: [tokentally/tokentally-python](https://github.com/tokentally/tokentally-python)
- TypeScript SDK: [tokentally/tokentally-node](https://github.com/tokentally/tokentally-node)

## License

MIT License
