# frozen_string_literal: true

module TokenTally
  # Client for tracking AI API usage with TokenTally
  #
  # @example Basic usage
  #   client = TokenTally::Client.new(api_key: "tt_your_api_key")
  #   response = client.track_usage(
  #     tokens_in: 100,
  #     tokens_out: 200,
  #     model: "claude-3-sonnet-20240229"
  #   )
  #   puts "Cost: $#{response[:cost_usd]}"
  #
  class Client
    DEFAULT_BASE_URL = "https://api.tokentally.io"
    DEFAULT_TIMEOUT = 30

    attr_reader :api_key, :base_url, :timeout

    # Initialize a new TokenTally client
    #
    # @param api_key [String] Your TokenTally API key (starts with 'tt_')
    # @param base_url [String] Optional custom API base URL
    # @param timeout [Integer] Request timeout in seconds
    #
    def initialize(api_key:, base_url: nil, timeout: nil)
      raise ArgumentError, "API key is required" if api_key.nil? || api_key.empty?
      raise ArgumentError, "Invalid API key. Must start with 'tt_'" unless api_key.start_with?("tt_")

      @api_key = api_key
      @base_url = (base_url || DEFAULT_BASE_URL).chomp("/")
      @timeout = timeout || DEFAULT_TIMEOUT
    end

    # Track AI API usage
    #
    # @param tokens_in [Integer] Number of input tokens
    # @param tokens_out [Integer] Number of output tokens
    # @param model [String] The model name
    # @param provider [String] The AI provider (default: 'anthropic')
    # @param runtime_ms [Integer] Optional runtime in milliseconds
    # @param stop_reason [String] Optional stop reason
    # @param error_message [String] Optional error message
    # @param metadata [Hash] Optional custom metadata
    #
    # @return [Hash] Response with :success, :record_id, and :cost_usd
    #
    def track_usage(tokens_in:, tokens_out:, model:, provider: "anthropic",
                    runtime_ms: nil, stop_reason: nil, error_message: nil, metadata: {})
      payload = {
        tokens_in: tokens_in,
        tokens_out: tokens_out,
        model: model,
        provider: provider,
        metadata: metadata,
        timestamp: Time.now.utc.iso8601
      }

      payload[:runtime_ms] = runtime_ms if runtime_ms
      payload[:stop_reason] = stop_reason if stop_reason
      payload[:error_message] = error_message if error_message

      response = connection.post("/api/usage") do |req|
        req.body = JSON.generate(payload)
      end

      handle_response(response)
    end

    # Track usage with a block for automatic timing
    #
    # @param model [String] The model name
    # @param provider [String] The AI provider
    # @param metadata [Hash] Optional metadata
    # @yield Block to execute and time
    #
    # @return [Object] Result of the block
    #
    def with_tracking(model:, provider: "anthropic", metadata: {})
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      error_msg = nil

      begin
        result = yield
        result
      rescue StandardError => e
        error_msg = e.message
        raise
      ensure
        end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        runtime_ms = ((end_time - start_time) * 1000).to_i

        if defined?(result) && result.respond_to?(:usage)
          track_usage(
            tokens_in: result.usage.input_tokens,
            tokens_out: result.usage.output_tokens,
            model: model,
            provider: provider,
            runtime_ms: runtime_ms,
            stop_reason: result.respond_to?(:stop_reason) ? result.stop_reason : nil,
            error_message: error_msg,
            metadata: metadata
          )
        end
      end
    end

    private

    def connection
      @connection ||= Faraday.new(url: base_url) do |f|
        f.request :retry, max: 2, interval: 0.5
        f.headers["Content-Type"] = "application/json"
        f.headers["X-API-Key"] = api_key
        f.headers["User-Agent"] = "tokentally-ruby/#{TokenTally::VERSION}"
        f.options.timeout = timeout
        f.options.open_timeout = 10
      end
    end

    def handle_response(response)
      case response.status
      when 200, 201
        JSON.parse(response.body, symbolize_names: true)
      when 401
        raise AuthenticationError, "Invalid API key"
      when 429
        data = JSON.parse(response.body, symbolize_names: true) rescue {}
        raise RateLimitError, data[:error] || "Rate limit exceeded"
      when 400
        data = JSON.parse(response.body, symbolize_names: true) rescue {}
        raise ValidationError, data[:error] || "Validation error"
      else
        raise Error, "Request failed with status #{response.status}"
      end
    end
  end
end
