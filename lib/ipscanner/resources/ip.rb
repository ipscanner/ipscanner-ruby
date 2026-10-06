# frozen_string_literal: true

require_relative "base"

module IPScanner
  module Resources
    # Single-address lookups.
    class IP < Base
      # Full lookup for an IP, CIDR or hostname.
      def lookup(target)
        @http.post("/v1/ip/lookup", { target: target })
      end

      def vpn(ip)
        @http.get("/v1/vpn/#{escape(ip)}")
      end

      def proxy(ip)
        @http.get("/v1/proxy/#{escape(ip)}")
      end

      def geo(ip)
        @http.get("/v1/geo/#{escape(ip)}")
      end

      def asn(ip)
        @http.get("/v1/asn/#{escape(ip)}")
      end

      def whois(domain)
        @http.get("/v1/whois/#{escape(domain)}")
      end

      # Recent lookups made by this account.
      def history(limit: nil, before: nil, verdict: nil)
        @http.get("/v1/ip/history", { limit: limit, before: before, verdict: verdict })
      end

      # Keyless lookup with the same response shape as lookup.
      def demo(ip)
        @http.get("/v1/demo/#{escape(ip)}")
      end

      # Describes the address the request came from.
      def myip
        @http.get("/v1/myip")
      end
    end
  end
end
