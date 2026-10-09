# frozen_string_literal: true

require "test_helper"

class ResponsesTest < Minitest::Test
  def setup
    @client = IPScanner::Client.new(api_key: "k")
  end

  def test_locked_lookup
    body = {
      "target" => { "raw" => "1.1.1.1", "kind" => "ipv4", "ip" => "1.1.1.1" },
      "verdict" => { "classification" => "relay", "anonymized" => true, "confidence" => 0.9,
                     "method" => "range", "evidence" => ["relay_range"] },
      "purity" => nil, "networkClass" => "relay", "isVpn" => false, "provider" => nil, "vpnProvider" => nil,
      "riskScore" => 40,
      "geo" => { "country" => "US", "latitude" => nil, "longitude" => nil, "postalCode" => nil,
                 "accuracyRadius" => nil },
      "locked" => ["purity", "provider", "vpnProvider", "geo.latitude", "geo.longitude", "geo.postalCode",
                   "geo.accuracyRadius"],
      "planRequired" => "Starter"
    }
    stub_request(:post, "#{BASE}/v1/ip/lookup").to_return(json_response(body))

    result = @client.ip.lookup("1.1.1.1")

    assert_nil result["purity"]
    assert_nil result["geo"]["latitude"]
    assert_equal ["relay_range"], result["verdict"]["evidence"]
    assert_includes result["locked"], "vpnProvider"
    assert_equal "Starter", result["planRequired"]
  end

  def test_hostname_lookup_whois_status
    body = { "target" => { "kind" => "hostname", "hostname" => "example.com" }, "whoisStatus" => "timeout" }
    stub_request(:post, "#{BASE}/v1/ip/lookup").to_return(json_response(body))

    result = @client.ip.lookup("example.com")

    assert_equal "timeout", result["whoisStatus"]
    refute result.key?("whois")
  end

  def test_whois_status_not_ok_is_not_an_error
    body = { "domain" => "example.com", "registrar" => "", "nameservers" => [], "status" => [],
             "privacyProtection" => false, "whoisStatus" => "unavailable" }
    stub_request(:get, "#{BASE}/v1/whois/example.com").to_return(json_response(body))

    result = @client.ip.whois("example.com")

    assert_equal "unavailable", result["whoisStatus"]
    assert_equal [], result["nameservers"]
  end

  def test_vpn_provider_and_evidence
    body = { "ip" => "1.1.1.1", "isVpn" => true, "networkClass" => "vpn", "anonymized" => true,
             "provider" => "M247", "vpnProvider" => "Mullvad", "riskScore" => 90,
             "evidence" => %w[vpn_server_list vpn_operator] }
    stub_request(:get, "#{BASE}/v1/vpn/1.1.1.1").to_return(json_response(body))

    result = @client.ip.vpn("1.1.1.1")

    assert_equal "Mullvad", result["vpnProvider"]
    assert_equal %w[vpn_server_list vpn_operator], result["evidence"]
  end

  def test_locked_bulk_check_row
    body = {
      "submitted" => 1, "unique" => 1, "duplicates" => 0, "invalid" => [], "summary" => {},
      "results" => [{ "input" => "1.1.1.1", "ip" => "1.1.1.1", "score" => nil, "grade" => nil, "verdict" => nil,
                      "classification" => "hosting", "vpnProvider" => nil, "deductions" => nil,
                      "locked" => %w[score grade verdict deductions vpnProvider] }],
      "planRequired" => "Starter"
    }
    stub_request(:post, "#{BASE}/v1/bulk/check").to_return(json_response(body))

    row = @client.bulk.check(ips: ["1.1.1.1"])["results"].first

    assert_nil row["score"]
    assert_nil row["deductions"]
    assert_includes row["locked"], "score"
  end
end
