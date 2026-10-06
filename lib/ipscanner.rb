# frozen_string_literal: true

require_relative "ipscanner/version"
require_relative "ipscanner/errors"
require_relative "ipscanner/http"
require_relative "ipscanner/resources/ip"
require_relative "ipscanner/resources/bulk"
require_relative "ipscanner/resources/agentscan"
require_relative "ipscanner/resources/provenance"
require_relative "ipscanner/resources/account"
require_relative "ipscanner/resources/asn_directory"
require_relative "ipscanner/resources/crawlers"
require_relative "ipscanner/client"

# Ruby client for the IPScanner API.
module IPScanner
end
