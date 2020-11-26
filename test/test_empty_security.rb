require "minitest/autorun"
require "json"
require "oas_request"
require "webmock/minitest"

class EmptySecurityTest < Minitest::Test
  def setup
    WebMock.disallow_net_connect!

    file = File.open File.expand_path("../fixtures/empty-security.json", __FILE__)
    data = JSON.parse file.read

    @api = OASRequest.spec(data)
  end

  def test_empty_security_global_method
    stub_request(:get, "https://example.com/global-security").with(
        headers: {
            'Accept' => 'application/json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Host' => 'example.com',
            'User-Agent' => 'Ruby'
        }).to_return(status: 200, body: "", headers: {})


    api = @api.new(server: "https://example.com", secret: "secret")

    api.test_global()

    assert_requested :get,
                     "https://example.com/global-security",
                     headers: {"Accept" => "application/json",
                               "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                               "Host" => "example.com",
                               "User-Agent" => "Ruby"},
                     times: 1
  end

  def test_empty_security_per_method
    stub_request(:get, "https://example.com/method-specific-security").with(
        headers: {
            'Accept' => 'application/json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Host' => 'example.com',
            'User-Agent' => 'Ruby'
        }).to_return(status: 200, body: "", headers: {})


    api = @api.new(server: "https://example.com", secret: "secret")

    api.test_method_specific()

    assert_requested :get,
                     "https://example.com/method-specific-security",
                     headers: {"Accept" => "application/json",
                               "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                               "Host" => "example.com",
                               "User-Agent" => "Ruby"},
                     times: 1
  end
end
