# frozen_string_literal: true

require "test_helper"

class ClientTest < Minitest::Test
  def setup
    @env = ENV.to_h.slice("IPSCANNER_API_KEY", "IPSCANNER_API_URL")
    ENV.delete("IPSCANNER_API_KEY")
    ENV.delete("IPSCANNER_API_URL")
  end

  def teardown
    ENV.delete("IPSCANNER_API_KEY")
    ENV.delete("IPSCANNER_API_URL")
    @env.each { |k, v| ENV[k] = v }
  end

  def test_sends_auth_and_default_headers
    stub = stub_request(:get, "#{BASE}/v1/vpn/1.1.1.1")
           .with(headers: {
                   "Authorization" => "Bearer sk_test",
                   "Accept" => "application/json",
                   "User-Agent" => "ipscanner-ruby/0.1.0"
                 })
           .to_return(json_response({ "ip" => "1.1.1.1", "isVpn" => false, "riskScore" => 3 }))

    result = IPScanner::Client.new(api_key: "sk_test").ip.vpn("1.1.1.1")

    assert_requested stub
    assert_equal({ "ip" => "1.1.1.1", "isVpn" => false, "riskScore" => 3 }, result)
  end

  def test_omits_auth_header_without_key
    stub_request(:get, "#{BASE}/v1/myip").to_return(json_response({ "ipv4" => "1.2.3.4" }))

    IPScanner::Client.new.ip.myip

    assert_requested(:get, "#{BASE}/v1/myip") { |req| !req.headers.key?("Authorization") }
  end

  def test_reads_env
    ENV["IPSCANNER_API_KEY"] = "sk_env"
    ENV["IPSCANNER_API_URL"] = "http://localhost:8080/"
    stub = stub_request(:get, "http://localhost:8080/v1/crawlers")
           .with(headers: { "Authorization" => "Bearer sk_env" })
           .to_return(json_response({ "crawlers" => [], "count" => 0 }))

    IPScanner::Client.new.crawlers.list

    assert_requested stub
  end

  def test_escapes_ipv6_path
    stub = stub_request(:get, "#{BASE}/v1/geo/2001%3Adb8%3A%3A1").to_return(json_response({ "ip" => "2001:db8::1" }))

    IPScanner::Client.new(api_key: "k").ip.geo("2001:db8::1")

    assert_requested stub
  end

  def test_query_params_skip_nil
    stub = stub_request(:get, "#{BASE}/v1/ip/history?limit=10").to_return(json_response({ "events" => [] }))

    IPScanner::Client.new(api_key: "k").ip.history(limit: 10)

    assert_requested stub
  end

  def test_asn_directory_get_strips_prefix
    stub = stub_request(:get, "#{BASE}/v1/asn/directory/15169").to_return(json_response({ "asn" => 15_169 }))

    IPScanner::Client.new.asn_directory.get("AS15169")

    assert_requested stub, times: 1
  end

  def test_provenance_export_returns_raw_csv
    stub_request(:get, "#{BASE}/v1/provenance/export?from=2026-01-01")
      .to_return(status: 200, body: "id,ts\n1,x\n", headers: { "Content-Type" => "text/csv" })

    csv = IPScanner::Client.new(api_key: "k").provenance.export(from: "2026-01-01")

    assert_equal "id,ts\n1,x\n", csv
  end
end
