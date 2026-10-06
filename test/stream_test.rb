# frozen_string_literal: true

require "test_helper"

class StreamTest < Minitest::Test
  def setup
    @client = IPScanner::Client.new(api_key: "k")
  end

  def ndjson(*lines)
    { status: 200, body: "#{lines.map { |l| JSON.generate(l) }.join("\n")}\n",
      headers: { "Content-Type" => "application/x-ndjson" } }
  end

  def test_stream_events
    lines = [
      { "type" => "meta", "total" => 2, "metered" => 2 },
      { "type" => "result", "input" => "1.1.1.1", "ip" => "1.1.1.1", "score" => 90, "grade" => "A" },
      { "type" => "error", "index" => 1, "input" => "10.0.0.1", "reason" => "reserved" },
      { "type" => "done", "reason" => "complete", "processed" => 1, "failed" => 1, "total" => 2 }
    ]
    stub = stub_request(:post, "#{BASE}/v1/ip/bulk")
           .with(body: { "ips" => ["1.1.1.1", "10.0.0.1"] })
           .to_return(ndjson(*lines))

    events = @client.bulk.stream(ips: ["1.1.1.1", "10.0.0.1"]).to_a

    assert_requested stub
    assert_equal(%w[meta result error done], events.map { |e| e["type"] })
    assert_equal 0, events[1]["index"]
    assert_equal false, events[1]["anonymized"]
    assert_equal 0.0, events[1]["confidence"]
    assert_equal 1, events[2]["index"]
    assert_equal true, events[3]["complete"]
  end

  def test_stream_block_and_incomplete_done
    meta = { "type" => "meta", "total" => 3 }
    done = { "type" => "done", "reason" => "complete", "processed" => 1, "total" => 3 }
    stub_request(:post, "#{BASE}/v1/ip/bulk").to_return(ndjson(meta, done))

    seen = []
    @client.bulk.stream(input: "a b c") { |e| seen << e }

    assert_equal false, seen.last["complete"]
    assert_equal 0, seen.last["failed"]
  end

  def test_stream_quota_exceeded
    done = { "type" => "done", "reason" => "quota_exceeded", "processed" => 1, "total" => 1 }
    stub_request(:post, "#{BASE}/v1/ip/bulk").to_return(ndjson(done))

    assert_equal false, @client.bulk.stream(ips: ["1.1.1.1"]).first["complete"]
  end

  def test_stream_pre_stream_error
    stub_request(:post, "#{BASE}/v1/ip/bulk")
      .to_return(json_response({ "error" => "rate_limit_exceeded", "message" => "no", "retryAfter" => 5 },
                               status: 429))

    err = assert_raises(IPScanner::RateLimitError) { @client.bulk.stream(ips: ["1.1.1.1"]).to_a }
    assert_equal 5, err.retry_after
  end
end
