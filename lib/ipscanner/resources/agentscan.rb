# frozen_string_literal: true

require_relative "base"

module IPScanner
  module Resources
    # Agentscan: classify the client behind a request.
    class Agentscan < Base
      def check(ip:, user_agent: nil, ja4: nil, headers: nil, headless_flags: nil, request_id: nil)
        body = {
          ip: ip, user_agent: user_agent, ja4: ja4, headers: headers,
          headless_flags: headless_flags, request_id: request_id
        }
        @http.post("/v1/agentscan/check", compact(body))
      end

      # Classifies parsed log lines, each a Hash with line, ip and optional user_agent, ja4, headers.
      def batch(lines)
        @http.post("/v1/agentscan/batch", { lines: lines })
      end

      # Checks whether a request claiming to be a known crawler is genuine.
      def verify(ip:, bot: nil, user_agent: nil)
        @http.post("/v1/agentscan/verify", compact({ ip: ip, bot: bot, user_agent: user_agent }))
      end

      def allowlist
        @http.get("/v1/agentscan/allowlist")
      end

      # Classifies the caller. Not metered.
      def self_check(ip: nil, user_agent: nil, headers: nil, ja4: nil)
        body = { ip: ip, user_agent: user_agent, headers: headers, ja4: ja4 }
        @http.post("/v1/agentscan/self", compact(body))
      end
    end
  end
end
