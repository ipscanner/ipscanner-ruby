# frozen_string_literal: true

require_relative "base"

module IPScanner
  module Resources
    # Network provenance attestations.
    class Provenance < Base
      def check(ip:, claimed_jurisdiction: nil, request_context: nil)
        body = { ip: ip, claimed_jurisdiction: claimed_jurisdiction, request_context: request_context }
        @http.post("/v1/provenance/check", compact(body))
      end

      def verify
        @http.get("/v1/provenance/verify")
      end

      def verify_anchored
        @http.post("/v1/provenance/verify", {})
      end

      def chain(limit: nil, before: nil)
        @http.get("/v1/provenance/chain", { limit: limit, before: before })
      end

      def jurisdictions
        @http.get("/v1/provenance/jurisdictions")
      end

      # Returns the attestation log as a CSV string.
      def export(from: nil, to: nil)
        @http.get("/v1/provenance/export", { from: from, to: to }, raw: true)
      end
    end
  end
end
