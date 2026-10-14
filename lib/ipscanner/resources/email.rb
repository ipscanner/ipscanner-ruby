# frozen_string_literal: true

require_relative "base"

module IPScanner
  module Resources
    # Email: address checks before a signup is accepted.
    class Email < Base
      # Checks one address: syntax, throwaway domains, mail servers, typos and role addresses. One request.
      def check(email)
        @http.post("/v1/email/check", { email: email })
      end
    end
  end
end
