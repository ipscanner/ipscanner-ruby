# frozen_string_literal: true

require_relative "lib/ipscanner/version"

Gem::Specification.new do |spec|
  spec.name = "ipscanner-io"
  spec.version = IPScanner::VERSION
  spec.authors = ["IPScanner"]
  spec.summary = "Ruby client for the IPScanner API."
  spec.description = "Official Ruby client for the IPScanner API: IP lookups, bulk checks, Agentscan and provenance."
  spec.homepage = "https://ipscanner.io"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata = {
    "homepage_uri" => "https://ipscanner.io",
    "source_code_uri" => "https://github.com/ipscanner/ipscanner-ruby",
    "documentation_uri" => "https://ipscanner.io/api-documentation",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]
end
