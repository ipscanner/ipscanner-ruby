# frozen_string_literal: true

require "test_helper"

class ErrorsTest < Minitest::Test
  def setup
    @client = no_sleep(IPScanner::Client.new(api_key: "k"))
  end

  def test_maps_status_to_class
    {
      401 => IPScanner::AuthenticationError,
      403 => IPScanner::AuthenticationError,
      404 => IPScanner::NotFoundError,
      400 => IPScanner::APIError
    }.each do |status, klass|
      stub_request(:get, "#{BASE}/v1/asn/1.1.1.1")
        .to_return(json_response({ "error" => "code_#{status}", "message" => "msg #{status}" }, status: status))

      err = assert_raises(klass) { @client.ip.asn("1.1.1.1") }
      assert_equal status, err.status
      assert_equal "code_#{status}", err.code
      assert_equal "msg #{status}", err.message
    end
  end

  def test_bulk_details
    body = { "error" => "bad_request", "message" => "no", "details" => { "invalid" => ["x"] } }
    stub_request(:post, "#{BASE}/v1/bulk/check").to_return(json_response(body, status: 400))

    err = assert_raises(IPScanner::APIError) { @client.bulk.check(ips: ["x"]) }
    assert_equal({ "invalid" => ["x"] }, err.details)
  end

  def test_non_json_error_body
    stub_request(:get, "#{BASE}/v1/whois/example.com").to_return(status: [500, "Internal Server Error"], body: "oops")

    err = assert_raises(IPScanner::APIError) { @client.ip.whois("example.com") }
    assert_equal "http_500", err.code
    assert_equal "Internal Server Error", err.message
    assert_equal "oops", err.body
  end

  def test_rate_limit_quota_body
    body = {
      "error" => "rate_limit_exceeded", "reason" => "monthly_quota", "message" => "Quota reached",
      "meter" => "request", "plan" => "free", "limit" => 1000, "usage" => 1000, "remaining" => 0,
      "resetAt" => "2026-11-01T00:00:00Z", "retryAfter" => 120, "softBlock" => false,
      "upgrade" => { "url" => "https://ipscanner.io/pricing", "message" => "Upgrade" }
    }
    headers = {
      "Retry-After" => "999",
      "X-RateLimit-Limit" => "1000",
      "X-RateLimit-Remaining" => "0",
      "X-RateLimit-Meter" => "request"
    }
    stub = stub_request(:get, "#{BASE}/v1/vpn/1.1.1.1").to_return(json_response(body, status: 429, headers: headers))

    err = assert_raises(IPScanner::RateLimitError) { @client.ip.vpn("1.1.1.1") }
    assert_requested stub, times: 1
    assert_equal "monthly_quota", err.reason
    assert_equal 120, err.retry_after
    assert_equal "2026-11-01T00:00:00Z", err.reset_at
    assert_equal 1000, err.limit
    assert_equal 1000, err.usage
    assert_equal 0, err.remaining
    assert_nil err.needed
    assert_equal "free", err.plan
    assert_equal "https://ipscanner.io/pricing", err.upgrade_url
    assert_equal({ meter: "request", limit: 1000, remaining: 0, retry_after: 999 }, err.rate_limit)
  end

  def test_rate_limit_retry_after_header_fallback
    stub_request(:get, "#{BASE}/v1/demo/1.1.1.1")
      .to_return(json_response({ "error" => "rate_limit_exceeded", "message" => "slow down" },
                               status: 429, headers: { "Retry-After" => "30" }))

    err = assert_raises(IPScanner::RateLimitError) { @client.ip.demo("1.1.1.1") }
    assert_equal 30, err.retry_after
  end

  def test_get_retries_on_unavailable
    stub = stub_request(:get, "#{BASE}/v1/user/limits")
           .to_return({ status: 503, body: "" }, json_response({ "limit" => 1000 }))

    assert_equal({ "limit" => 1000 }, @client.account.limits)
    assert_requested stub, times: 2
  end

  def test_get_gives_up_after_max_retries
    stub = stub_request(:get, "#{BASE}/v1/usage/summary").to_return(status: 502, body: "")

    err = assert_raises(IPScanner::APIError) { @client.account.usage }
    assert_equal 502, err.status
    assert_requested stub, times: 3
  end

  def test_get_retries_network_errors
    stub = stub_request(:get, "#{BASE}/v1/crawlers").to_raise(Errno::ECONNREFUSED)

    assert_raises(IPScanner::ConnectionError) { @client.crawlers.list }
    assert_requested stub, times: 3
  end

  def test_timeout
    stub_request(:get, "#{BASE}/v1/crawlers").to_timeout

    assert_raises(IPScanner::TimeoutError) { @client.crawlers.list }
  end
end
