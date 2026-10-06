# frozen_string_literal: true

module IPScanner
  module Resources
    # Shared plumbing for resource classes.
    class Base
      def initialize(http)
        @http = http
      end

      private

      def escape(segment)
        HTTP.escape(segment)
      end

      def compact(hash)
        hash.compact
      end
    end
  end
end
