Gem::Specification.new do |spec|
  spec.name          = "tokentally"
  spec.version       = "0.1.0"
  spec.authors       = ["TokenTally"]
  spec.email         = ["support@tokentally.io"]

  spec.summary       = "Track AI API usage with TokenTally"
  spec.description   = "Ruby SDK for TokenTally - Track your AI API usage, costs, and analytics for Claude, OpenAI, and other providers."
  spec.homepage      = "https://github.com/tokentally/tokentally-ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.files = Dir["lib/**/*", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-retry", "~> 2.0"

  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
end
