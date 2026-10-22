# frozen_string_literal: true

require_relative "test_helper"

class EmailTest < Minitest::Test
  def setup
    @client = IPScanner::Client.new(api_key: "pk_test")
  end

  def test_email_check_posts_with_the_key
    answer = {
      "email" => "jane@outlok.com", "status" => "risky", "reason" => "typo", "suggestion" => "jane@outlook.com",
      "domain" => "outlok.com",
      "checks" => { "syntax" => true, "mx" => nil, "disposable" => false, "role" => false, "freeProvider" => false },
      "mailbox" => "not_checked"
    }
    stub = stub_request(:post, "#{BASE}/v1/email/check")
           .with(headers: { "Authorization" => "Bearer pk_test", "User-Agent" => "ipscanner-ruby/0.3.1" },
                 body: { "email" => "jane@outlok.com" })
           .to_return(json_response(answer))

    result = @client.email.check("jane@outlok.com")

    assert_requested stub
    assert_equal "jane@outlook.com", result["suggestion"]
    assert_nil result["checks"]["mx"]
  end

  def test_gate_verify_sends_the_email
    stub = stub_request(:post, "#{BASE}/v1/gate/verify")
           .with(body: { "secret" => "gs_x", "token" => "t1", "email" => "x@mailinator.com" })
           .to_return(json_response({ "success" => true, "action" => "block",
                                      "email" => { "status" => "risky", "reason" => "disposable", "suggestion" => nil,
                                                   "domain" => "mailinator.com", "action" => "block" } }))

    result = @client.gate.verify(secret: "gs_x", token: "t1", email: "x@mailinator.com")

    assert_requested stub
    assert_equal "block", result["email"]["action"]
  end

  def test_proxy_locked_purity_count
    stub_request(:get, "#{BASE}/v1/proxy/5.6.7.8")
      .to_return(json_response({ "ip" => "5.6.7.8", "purity" => nil, "deductionCount" => 3,
                                 "locked" => %w[purity provider vpnProvider], "planRequired" => "Starter" }))

    result = @client.ip.proxy("5.6.7.8")

    assert_nil result["purity"]
    assert_equal 3, result["deductionCount"]
  end
end
