# frozen_string_literal: true

module IPScanner
  # Base class for every error raised by this library.
  class Error < StandardError; end

  # Raised when the request could not reach the API.
  class ConnectionError < Error; end

  # Raised when the request timed out.
  class TimeoutError < ConnectionError; end

  # Raised for any non-2xx response.
  class APIError < Error
    attr_reader :status, :code, :details, :body

    def initialize(status:, code:, message:, details: nil, body: nil)
      super(message)
      @status = status
      @code = code
      @details = details
      @body = body
    end
  end

  # Raised on 401 and 403 responses.
  class AuthenticationError < APIError; end

  # Raised on 404 responses.
  class NotFoundError < APIError; end

  # Raised on 429 responses.
  class RateLimitError < APIError
    attr_reader :reason, :retry_after, :reset_at, :limit, :usage, :remaining,
                :needed, :plan, :upgrade_url, :rate_limit

    def initialize(rate_limit: {}, **kwargs)
      super(**kwargs)
      data = body.is_a?(Hash) ? body : {}
      upgrade = data["upgrade"].is_a?(Hash) ? data["upgrade"] : {}
      @reason = data["reason"]
      @retry_after = data["retryAfter"] || rate_limit[:retry_after]
      @reset_at = data["resetAt"]
      @limit = data["limit"]
      @usage = data["usage"]
      @remaining = data["remaining"]
      @needed = data["needed"]
      @plan = data["plan"]
      @upgrade_url = upgrade["url"]
      @rate_limit = rate_limit
    end
  end
end
