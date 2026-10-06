# frozen_string_literal: true

module IPScanner
  # Entry point for the IPScanner API.
  class Client
    DEFAULT_BASE_URL = "https://ipscanner.io"

    attr_reader :ip, :bulk, :agentscan, :provenance, :account, :asn_directory, :crawlers

    def initialize(api_key: nil, base_url: nil, timeout: 30, max_retries: 2)
      api_key ||= ENV.fetch("IPSCANNER_API_KEY", nil)
      base_url ||= ENV.fetch("IPSCANNER_API_URL", nil)
      base_url = DEFAULT_BASE_URL if base_url.nil? || base_url.empty?
      http = HTTP.new(api_key: api_key, base_url: base_url, timeout: timeout, max_retries: max_retries)

      @ip = Resources::IP.new(http)
      @bulk = Resources::Bulk.new(http)
      @agentscan = Resources::Agentscan.new(http)
      @provenance = Resources::Provenance.new(http)
      @account = Resources::Account.new(http)
      @asn_directory = Resources::AsnDirectory.new(http)
      @crawlers = Resources::Crawlers.new(http)
    end
  end
end
