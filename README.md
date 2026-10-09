# IPScanner Ruby

Official Ruby client for the [IPScanner](https://ipscanner.io) API.

Full API reference: https://ipscanner.io/api-documentation

## Install

```sh
gem install ipscanner-io
```

Or in a Gemfile:

```ruby
gem "ipscanner-io"
```

Requires Ruby 3.0 or newer. No runtime dependencies.

## Quick start

```ruby
require "ipscanner"

client = IPScanner::Client.new(api_key: "your-api-key")

result = client.ip.lookup("8.8.8.8")
puts result["networkClass"]
puts result["purity"]["grade"]
```

Every method returns the parsed JSON response as a Hash with the same string keys the API sends.

`vpnProvider` names the VPN brand when known. On the Free plan, premium fields come back as `nil` and are listed in `locked`, with `planRequired` naming the plan that unlocks them.

## Usage

### IP

```ruby
client.ip.lookup("example.com")      # IP, CIDR or hostname
client.ip.vpn("1.1.1.1")
client.ip.proxy("1.1.1.1")
client.ip.geo("2001:4860:4860::8888")
client.ip.asn("1.1.1.1")
client.ip.whois("example.com")
client.ip.history(limit: 50, verdict: "vpn")
client.ip.demo("1.1.1.1")            # no key needed
client.ip.myip                       # no key needed
```

### Bulk

```ruby
report = client.bulk.check(ips: ["1.1.1.1", "8.8.8.8"])
report = client.bulk.check(input: File.read("ips.txt"))
```

`stream` reads the NDJSON response line by line. Pass a block, or call it without one to get an Enumerator.

```ruby
client.bulk.stream(input: File.read("ips.txt")) do |event|
  case event["type"]
  when "result" then puts "#{event['ip']} #{event['grade']}"
  when "error" then warn "#{event['input']}: #{event['reason']}"
  when "done" then puts "finished: #{event['complete']}"
  end
end
```

Fields the server leaves out are filled with their zero value. The `done` event has an extra `"complete"` key that is `true` only when every address was processed.

### Agentscan

```ruby
client.agentscan.check(ip: "203.0.113.7", user_agent: request.user_agent, headers: { "accept-language" => "en" })
client.agentscan.verify(ip: "66.249.66.1", bot: "googlebot")
client.agentscan.batch([{ line: 1, ip: "203.0.113.7", user_agent: "curl/8.0" }])
client.agentscan.allowlist
client.agentscan.self_check
```

### Edge

```ruby
client.edge.check(ip: "203.0.113.7", site: "your-site-id", user_agent: request.user_agent)
```

### Sites

```ruby
client.sites.policy("your-site-id")
```

### Gate

```ruby
result = client.gate.verify(secret: "gs_...", token: gate_token, remote_ip: request.remote_ip)
```

`gate.verify` sends the site secret instead of the API key and is never retried.

### Provenance

```ruby
client.provenance.check(ip: "203.0.113.7", claimed_jurisdiction: "eu")
client.provenance.verify
client.provenance.verify_anchored
client.provenance.chain(limit: 100)
client.provenance.jurisdictions
csv = client.provenance.export(from: "2026-01-01", to: "2026-01-31")
```

### Account

```ruby
client.account.limits
client.account.usage
```

### ASN directory

```ruby
client.asn_directory.top(top: 20, by: "prefixes")
client.asn_directory.search("cloudflare", limit: 10)
client.asn_directory.get("AS15169")
```

### Crawlers

```ruby
client.crawlers.list
```

## Errors

All errors inherit from `IPScanner::Error`.

| Class | When |
| --- | --- |
| `IPScanner::APIError` | Any non-2xx response. Has `status`, `code`, `message`, `details`, `body`. |
| `IPScanner::AuthenticationError` | 401 or 403 |
| `IPScanner::NotFoundError` | 404 |
| `IPScanner::RateLimitError` | 429. Adds `reason`, `retry_after`, `reset_at`, `limit`, `usage`, `remaining`, `needed`, `plan`, `upgrade_url`, `rate_limit`. |
| `IPScanner::ConnectionError` | The API could not be reached. |
| `IPScanner::TimeoutError` | The request timed out. |

```ruby
begin
  client.ip.vpn("1.1.1.1")
rescue IPScanner::RateLimitError => e
  sleep e.retry_after if e.retry_after
rescue IPScanner::APIError => e
  warn "#{e.status} #{e.code}: #{e.message}"
end
```

GET requests are retried up to `max_retries` times on network errors and 502, 503 and 504 responses. POST requests and 429 responses are never retried.

## Configuration

```ruby
IPScanner::Client.new(
  api_key: "your-api-key",          # default: ENV["IPSCANNER_API_KEY"]
  base_url: "https://ipscanner.io", # default: ENV["IPSCANNER_API_URL"] or https://ipscanner.io
  timeout: 30,                      # seconds
  max_retries: 2
)
```

Keyless endpoints (`ip.demo`, `ip.myip`, `asn_directory`, `crawlers`, `gate.verify`) work without an API key.

## Licence

MIT
