# frozen_string_literal: true

require_relative "base"

module IPScanner
  module Resources
    # Edge: one verdict per request from Agentscan and the network check.
    class Edge < Base
      # Classifies a request for a site. Metered at 2 units.
      def check(ip:, site: nil, user_agent: nil, ja4: nil, headers: nil, headless_flags: nil, request_id: nil)
        body = {
          site: site, ip: ip, user_agent: user_agent, ja4: ja4, headers: headers,
          headless_flags: headless_flags, request_id: request_id
        }
        @http.post("/v1/edge/check", compact(body))
      end
    end
  end
end
