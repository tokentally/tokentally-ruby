# frozen_string_literal: true

require "faraday"
require "json"
require "time"

require_relative "tokentally/version"
require_relative "tokentally/errors"
require_relative "tokentally/client"

module TokenTally
  class << self
    attr_accessor :api_key, :base_url, :timeout

    def configure
      yield self
    end

    def client
      @client ||= Client.new(
        api_key: api_key,
        base_url: base_url,
        timeout: timeout
      )
    end

    def track_usage(usage_data, metadata: {})
      client.track_usage(usage_data, metadata: metadata)
    end
  end

  self.base_url = "https://api.tokentally.cloud"
  self.timeout = 30
end
