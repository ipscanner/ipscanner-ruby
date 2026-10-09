# frozen_string_literal: true

require_relative "base"

module IPScanner
  module Resources
    # Gate: server-side redemption of form tokens.
    class Gate < Base
      # Redeems a gate token with the site secret. Sends no API key and is never retried.
      def verify(secret:, token:, remote_ip: nil)
        @http.post("/v1/gate/verify", compact({ secret: secret, token: token, remote_ip: remote_ip }), auth: false)
      end
    end
  end
end
