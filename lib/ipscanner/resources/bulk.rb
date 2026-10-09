# frozen_string_literal: true

require_relative "base"

module IPScanner
  module Resources
    # Many addresses per request.
    class Bulk < Base
      EVENT_DEFAULTS = {
        "type" => "", "index" => 0, "total" => 0, "input" => "", "reason" => "",
        "message" => "", "error" => "", "ip" => "", "verdict" => "", "classification" => "",
        "confidence" => 0.0, "anonymized" => false, "vpnProvider" => "", "score" => 0, "grade" => "",
        "isTorExit" => false, "asn" => "", "asnName" => "", "asnType" => "", "country" => "",
        "processed" => 0, "failed" => 0, "metered" => 0
      }.freeze

      # Scores a list of addresses or a pasted blob in one response.
      def check(ips: nil, input: nil)
        @http.post("/v1/bulk/check", body(ips, input))
      end

      # Yields each NDJSON event as it arrives, or returns an Enumerator without a block.
      def stream(ips: nil, input: nil)
        return enum_for(:stream, ips: ips, input: input) unless block_given?

        @http.stream("/v1/ip/bulk", body(ips, input)) do |line|
          event = EVENT_DEFAULTS.merge(line.compact)
          if event["type"] == "done"
            event["complete"] = event["reason"] == "complete" &&
                                event["processed"] + event["failed"] >= event["total"]
          end
          yield event
        end
        nil
      end

      private

      def body(ips, input)
        compact({ ips: ips, input: input })
      end
    end
  end
end
