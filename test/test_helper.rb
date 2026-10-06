# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ipscanner"
require "minitest/autorun"
require "webmock/minitest"

BASE = "https://ipscanner.io"

def json_response(body, status: 200, headers: {})
  { status: status, body: JSON.generate(body), headers: { "Content-Type" => "application/json" }.merge(headers) }
end

def no_sleep(client)
  http = client.ip.instance_variable_get(:@http)
  http.define_singleton_method(:backoff) { |_attempt| nil }
  client
end
