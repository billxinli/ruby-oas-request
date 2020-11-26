require "minitest/autorun"
require "json"
require "oas_request"
require "webmock/minitest"

class GlobalSecurityTest < Minitest::Test
  def setup
    WebMock.disallow_net_connect!

    file = File.open File.expand_path("../fixtures/global-security.json", __FILE__)
    data = JSON.parse file.read

    @api = OASRequest.spec(data)
  end

  def test_per_method_overrides_security_values
    stub_request(:get, "https://example.com/method-specific-security?API-Key=per-method-override-query").with(
        headers: {
            'Accept' => 'application/json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Host' => 'example.com',
            'User-Agent' => 'Ruby',
            'X-API-KEY' => 'per-method-override-header'
        }).to_return(status: 200, body: "", headers: {})

    api = @api.new(server: "https://example.com", secret: "secret")

    api.test_method_specific({
                                 secret: 'method-secret',
                                 query: {
                                     'API-Key': 'per-method-override-query'
                                 },
                                 headers: {
                                     'X-API-KEY': 'per-method-override-header'

                                 }
                             })

    assert_requested :get,
                     "https://example.com/method-specific-security?API-Key=per-method-override-query",
                     headers: {"Accept" => "application/json",
                               "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                               "Host" => "example.com",
                               "User-Agent" => "Ruby",
                               "X-API-KEY" => "per-method-override-header"},
                     times: 1
  end

  def test_global_security_is_applied
    stub_request(:get, "https://example.com/global-security").with(
        headers: {
            'Accept' => 'application/json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Host' => 'example.com',
            'User-Agent' => 'Ruby',
            'X-Api-Key' => 'secret'
        }).to_return(status: 200, body: "", headers: {})

    api = @api.new(server: "https://example.com", secret: "secret")

    api.test_global()

    assert_requested :get,
                     "https://example.com/global-security",
                     headers: {"Accept" => "application/json",
                               "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                               "Host" => "example.com",
                               "User-Agent" => "Ruby",
                               'X-Api-Key' => "secret"},
                     times: 1
  end

  def test_global_security_with_method_security_is_applied
    stub_request(:get, "https://example.com/method-specific-security?API-Key=secret").with(
        headers: {
            'Accept' => 'application/json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Host' => 'example.com',
            'User-Agent' => 'Ruby',
            'X-Api-Key' => 'secret'
        }).to_return(status: 200, body: "", headers: {})

    api = @api.new(server: "https://example.com", secret: "secret")

    api.test_method_specific()

    assert_requested :get,
                     "https://example.com/method-specific-security?API-Key=secret",
                     headers: {"Accept" => "application/json",
                               "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                               "Host" => "example.com",
                               "User-Agent" => "Ruby",
                               'X-Api-Key' => "secret"},
                     times: 1
  end

  def test_global_security_with_method_security_override
    stub_request(:get, "https://example.com/method-specific-security?API-Key=method-secret").with(
        headers: {
            'Accept' => 'application/json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Host' => 'example.com',
            'User-Agent' => 'Ruby',
            'X-Api-Key' => 'method-secret'
        }).to_return(status: 200, body: "", headers: {})

    api = @api.new(server: "https://example.com", secret: "secret")

    api.test_method_specific(secret: 'method-secret')

    assert_requested :get,
                     "https://example.com/method-specific-security?API-Key=method-secret",
                     headers: {"Accept" => "application/json",
                               "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                               "Host" => "example.com",
                               "User-Agent" => "Ruby",
                               'X-Api-Key' => "method-secret"},
                     times: 1
  end
end
