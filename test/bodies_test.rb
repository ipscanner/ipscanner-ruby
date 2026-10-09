# frozen_string_literal: true

require "test_helper"

class BodiesTest < Minitest::Test
  def setup
    @client = IPScanner::Client.new(api_key: "k")
  end

  def test_agentscan_check_snake_case
    stub = stub_request(:post, "#{BASE}/v1/agentscan/check")
           .with(
             headers: { "Content-Type" => "application/json" },
             body: {
               "ip" => "1.2.3.4", "user_agent" => "curl/8", "headless_flags" => { "webdriver" => true },
               "request_id" => "r1"
             }
           )
           .to_return(json_response({ "class" => "human", "action" => "allow" }))

    result = @client.agentscan.check(ip: "1.2.3.4", user_agent: "curl/8", headless_flags: { webdriver: true },
                                     request_id: "r1")

    assert_requested stub
    assert_equal "human", result["class"]
  end

  def test_agentscan_verify_and_self
    verify = stub_request(:post, "#{BASE}/v1/agentscan/verify")
             .with(body: { "ip" => "66.249.66.1", "bot" => "googlebot" })
             .to_return(json_response({ "outcome" => "verified" }))
    me = stub_request(:post, "#{BASE}/v1/agentscan/self")
         .with(body: {})
         .to_return(json_response({ "metered" => false }))

    @client.agentscan.verify(ip: "66.249.66.1", bot: "googlebot")
    @client.agentscan.self_check

    assert_requested verify
    assert_requested me
  end

  def test_provenance_check_snake_case
    stub = stub_request(:post, "#{BASE}/v1/provenance/check")
           .with(body: { "ip" => "1.2.3.4", "claimed_jurisdiction" => "EU", "request_context" => { "path" => "/" } })
           .to_return(json_response({ "policy_action" => "allow", "attestation_id" => 7 }))

    result = @client.provenance.check(ip: "1.2.3.4", claimed_jurisdiction: "EU", request_context: { path: "/" })

    assert_requested stub
    assert_equal 7, result["attestation_id"]
  end

  def test_bulk_check_body
    stub = stub_request(:post, "#{BASE}/v1/bulk/check")
           .with(body: { "input" => "1.1.1.1\n8.8.8.8" })
           .to_return(json_response({ "submitted" => 2 }))

    @client.bulk.check(input: "1.1.1.1\n8.8.8.8")

    assert_requested stub
  end

  def test_edge_check
    response = {
      "class" => "vpn",
      "agent" => { "class" => "human", "confidence" => 0.9, "action" => "allow",
                   "signals" => { "scripted_client" => "" } },
      "network" => { "networkClass" => "vpn", "anonymized" => true, "riskScore" => 80, "provider" => "M247",
                     "vpnProvider" => "Mullvad", "evidence" => ["vpn_server_list"], "asn" => 9009 },
      "site" => { "id" => "site_1", "mode" => "monitor", "policyVersion" => 3 },
      "futureField" => 1
    }
    stub = stub_request(:post, "#{BASE}/v1/edge/check")
           .with(
             headers: { "Authorization" => "Bearer k", "Content-Type" => "application/json" },
             body: { "site" => "site_1", "ip" => "1.2.3.4", "user_agent" => "curl/8", "request_id" => "r1" }
           )
           .to_return(json_response(response))

    result = @client.edge.check(ip: "1.2.3.4", site: "site_1", user_agent: "curl/8", request_id: "r1")

    assert_requested stub
    assert_equal "vpn", result["class"]
    assert_equal "Mullvad", result["network"]["vpnProvider"]
    assert_equal ["vpn_server_list"], result["network"]["evidence"]
    assert_equal 9009, result["network"]["asn"]
    assert_equal 3, result["site"]["policyVersion"]
  end

  def test_sites_policy
    stub = stub_request(:get, "#{BASE}/v1/sites/site%2F1/policy")
           .with(headers: { "Authorization" => "Bearer k" })
           .to_return(json_response({ "site" => "site/1", "mode" => "enforce",
                                      "policy" => { "relay" => "flag" }, "version" => 2 }))

    result = @client.sites.policy("site/1")

    assert_requested stub
    assert_equal "flag", result["policy"]["relay"]
  end

  def test_gate_verify_sends_no_authorization
    response = {
      "success" => true, "class" => "relay", "action" => "flag", "mode" => "monitor", "confidence" => 0.8,
      "network" => { "classification" => "relay", "anonymized" => true, "provider" => nil, "vpn_provider" => nil },
      "signals" => ["relay_range"], "hostname" => "example.com", "issued_at" => "2026-10-09T12:00:00Z",
      "ip_match" => true, "locked" => ["network.provider", "network.vpn_provider"], "planRequired" => "Starter"
    }
    stub = stub_request(:post, "#{BASE}/v1/gate/verify")
           .with(
             headers: { "Content-Type" => "application/json", "User-Agent" => "ipscanner-ruby/0.2.0" },
             body: { "secret" => "gs_x", "token" => "t1", "remote_ip" => "1.2.3.4" }
           )
           .to_return(json_response(response))

    result = @client.gate.verify(secret: "gs_x", token: "t1", remote_ip: "1.2.3.4")

    assert_requested stub
    assert_requested(:post, "#{BASE}/v1/gate/verify") { |req| !req.headers.key?("Authorization") }
    assert_equal true, result["success"]
    assert_nil result["network"]["vpn_provider"]
    assert_equal "Starter", result["planRequired"]
  end

  def test_gate_verify_omits_remote_ip
    stub = stub_request(:post, "#{BASE}/v1/gate/verify")
           .with(body: { "secret" => "gs_x", "token" => "t1" })
           .to_return(json_response({ "success" => true }))

    @client.gate.verify(secret: "gs_x", token: "t1")

    assert_requested stub
  end

  def test_gate_verify_is_not_retried
    stub = stub_request(:post, "#{BASE}/v1/gate/verify")
           .to_return(json_response({ "success" => false, "error" => "unavailable", "message" => "later" },
                                    status: 503))

    err = assert_raises(IPScanner::APIError) { no_sleep(@client).gate.verify(secret: "gs_x", token: "t1") }
    assert_equal "unavailable", err.code
    assert_requested stub, times: 1
  end

  def test_post_is_not_retried
    stub = stub_request(:post, "#{BASE}/v1/ip/lookup").to_return(status: 503, body: "")

    assert_raises(IPScanner::APIError) { no_sleep(@client).ip.lookup("1.1.1.1") }
    assert_requested stub, times: 1
  end
end
