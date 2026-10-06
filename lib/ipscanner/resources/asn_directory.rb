# frozen_string_literal: true

require_relative "base"

module IPScanner
  module Resources
    # Keyless directory of autonomous systems.
    class AsnDirectory < Base
      # Largest networks, ranked by addresses or prefixes.
      def top(top: nil, by: nil)
        @http.get("/v1/asn/directory", { top: top, by: by })
      end

      def search(query, limit: nil)
        @http.get("/v1/asn/directory", { q: query, limit: limit })
      end

      # Accepts 15169 or "AS15169".
      def get(asn)
        number = asn.to_s.strip.sub(/\AAS/i, "")
        @http.get("/v1/asn/directory/#{escape(number)}")
      end
    end
  end
end
