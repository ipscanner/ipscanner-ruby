# frozen_string_literal: true

require_relative "base"

module IPScanner
  module Resources
    # Keyless catalog of known crawlers.
    class Crawlers < Base
      def list
        @http.get("/v1/crawlers")
      end
    end
  end
end
