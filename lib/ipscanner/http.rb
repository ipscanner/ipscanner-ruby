# frozen_string_literal: true

require "json"
require "net/http"
require "openssl"
require "uri"

module IPScanner
  # Low-level transport shared by every resource.
  class HTTP
    RETRY_STATUSES = [502, 503, 504].freeze
    STREAM_TIMEOUT = 300
    NETWORK_ERRORS = [
      SocketError, SystemCallError, IOError, EOFError, OpenSSL::SSL::SSLError
    ].freeze
    TIMEOUT_ERRORS = [Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout].freeze

    RATE_LIMIT_HEADERS = {
      meter: ["X-RateLimit-Meter", :string],
      limit: ["X-RateLimit-Limit", :int],
      remaining: ["X-RateLimit-Remaining", :int],
      reset: ["X-RateLimit-Reset", :int],
      daily_limit: ["X-RateLimit-Daily-Limit", :int],
      daily_remaining: ["X-RateLimit-Daily-Remaining", :int],
      daily_reset: ["X-RateLimit-Daily-Reset", :int],
      hourly_limit: ["X-RateLimit-Hourly-Limit", :int],
      hourly_remaining: ["X-RateLimit-Hourly-Remaining", :int],
      hourly_reset: ["X-RateLimit-Hourly-Reset", :int],
      usage_percent: ["X-RateLimit-Usage-Percent", :int],
      upgrade_hint: ["X-Quota-Upgrade-Hint", :string],
      upgrade_url: ["X-Quota-Upgrade-Url", :string],
      upgrade_plan: ["X-Quota-Upgrade-Plan", :string],
      retry_after: ["Retry-After", :int]
    }.freeze

    def self.escape(segment)
      segment.to_s.b.gsub(/[^A-Za-z0-9\-._~]/) { |c| format("%%%02X", c.ord) }
    end

    def initialize(api_key:, base_url:, timeout:, max_retries:)
      @api_key = api_key
      @base_url = base_url.chomp("/")
      @timeout = timeout
      @max_retries = max_retries
    end

    def get(path, query = nil, raw: false)
      request(Net::HTTP::Get, path, query: query, raw: raw)
    end

    def post(path, body = {})
      request(Net::HTTP::Post, path, body: body)
    end

    def stream(path, body)
      uri = build_uri(path)
      req = build_request(Net::HTTP::Post, uri, body)
      req["Accept"] = "application/x-ndjson"
      with_errors do
        connection(uri, STREAM_TIMEOUT).start do |http|
          http.request(req) do |res|
            raise error_for(res, res.body) unless res.is_a?(Net::HTTPSuccess)

            buffer = +""
            res.read_body do |chunk|
              buffer << chunk
              while (newline = buffer.index("\n"))
                line = buffer.slice!(0, newline + 1).strip
                yield JSON.parse(line) unless line.empty?
              end
            end
            rest = buffer.strip
            yield JSON.parse(rest) unless rest.empty?
          end
        end
      end
    end

    private

    def request(klass, path, query: nil, body: nil, raw: false)
      uri = build_uri(path, query)
      attempts = 0
      loop do
        attempts += 1
        begin
          res = with_errors do
            connection(uri, @timeout).start { |http| http.request(build_request(klass, uri, body)) }
          end
        rescue ConnectionError
          raise unless retryable?(klass, attempts)

          backoff(attempts)
          next
        end
        if RETRY_STATUSES.include?(res.code.to_i) && retryable?(klass, attempts)
          backoff(attempts)
          next
        end
        raise error_for(res, res.body) unless res.is_a?(Net::HTTPSuccess)

        return raw ? res.body.to_s : parse(res.body)
      end
    end

    def retryable?(klass, attempts)
      klass == Net::HTTP::Get && attempts <= @max_retries
    end

    def backoff(attempt)
      sleep(0.5 * (2**(attempt - 1)))
    end

    def with_errors
      yield
    rescue *TIMEOUT_ERRORS => e
      raise TimeoutError, e.message
    rescue *NETWORK_ERRORS => e
      raise ConnectionError, e.message
    end

    def build_uri(path, query = nil)
      uri = URI.parse(@base_url + path)
      params = (query || {}).compact
      uri.query = URI.encode_www_form(params) unless params.empty?
      uri
    end

    def connection(uri, timeout)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = timeout
      http.read_timeout = timeout
      http.write_timeout = timeout
      http
    end

    def build_request(klass, uri, body)
      req = klass.new(uri)
      req["Accept"] = "application/json"
      req["User-Agent"] = "ipscanner-ruby/#{VERSION}"
      req["Authorization"] = "Bearer #{@api_key}" if @api_key && !@api_key.empty?
      unless body.nil?
        req["Content-Type"] = "application/json"
        req.body = JSON.generate(body)
      end
      req
    end

    def parse(text)
      return nil if text.nil? || text.empty?

      JSON.parse(text)
    end

    def error_for(res, text)
      status = res.code.to_i
      data = begin
        JSON.parse(text.to_s)
      rescue JSON::ParserError
        nil
      end
      data = nil unless data.is_a?(Hash) && data["error"].is_a?(String)
      code = data ? data["error"] : "http_#{status}"
      message = data && data["message"] ? data["message"] : status_text(res, status)
      args = { status: status, code: code, message: message, details: data && data["details"], body: data || text }

      case status
      when 401, 403 then AuthenticationError.new(**args)
      when 404 then NotFoundError.new(**args)
      when 429 then RateLimitError.new(rate_limit: rate_limit(res), **args)
      else APIError.new(**args)
      end
    end

    def status_text(res, status)
      text = res.message.to_s.strip
      text.empty? ? "HTTP #{status}" : text
    end

    def rate_limit(res)
      RATE_LIMIT_HEADERS.each_with_object({}) do |(key, (header, type)), out|
        value = res[header]
        next if value.nil? || value.empty?

        out[key] = type == :int ? Integer(value, exception: false) || value : value
      end
    end
  end
end
