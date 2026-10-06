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

  def test_post_is_not_retried
    stub = stub_request(:post, "#{BASE}/v1/ip/lookup").to_return(status: 503, body: "")

    assert_raises(IPScanner::APIError) { no_sleep(@client).ip.lookup("1.1.1.1") }
    assert_requested stub, times: 1
  end
end
