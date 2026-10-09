# frozen_string_literal: true

require_relative "base"

module IPScanner
  module Resources
    # Sites registered for edge checks and the gate.
    class Sites < Base
      # Current policy for a site. Not metered.
      def policy(id)
        @http.get("/v1/sites/#{escape(id)}/policy")
      end
    end
  end
end
