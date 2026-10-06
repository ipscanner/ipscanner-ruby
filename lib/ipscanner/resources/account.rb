# frozen_string_literal: true

require_relative "base"

module IPScanner
  module Resources
    # Quota and usage for the current key.
    class Account < Base
      def limits
        @http.get("/v1/user/limits")
      end

      def usage
        @http.get("/v1/usage/summary")
      end
    end
  end
end
