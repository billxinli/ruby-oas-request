require "minitest/autorun"
require "json"
require "oas_request"
require "webmock/minitest"

class MethodSecurityTest < Minitest::Test
  def setup
    WebMock.disallow_net_connect!

    file = File.open File.expand_path("../fixtures/method-security.json", __FILE__)
    data = JSON.parse file.read

    @api = OASRequest.spec(data)
  end

  def test_method_security_is_applied
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

  def test_method_security_with_method_security_is_applied
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
                     times: 1 do |req|
      jwt_token = req.headers["Authorization"].split('Bearer ')[1]

      decoded = JWT.decode jwt_token, 'secret', true, {algorithm: 'HS256'}

      assert_equal decoded[0], {}
    end
  end

  def test_method_security_with_method_security_override
    stub_request(:get, "https://example.com/method-specific-security").with(
        headers: {
            'Accept' => 'application/json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Host' => 'example.com',
            'User-Agent' => 'Ruby'
        }).to_return(status: 200, body: "", headers: {})

    api = @api.new(server: "https://example.com", secret: "secret")

    now = Time.now.to_i

    api.test_method_specific(secret: 'another-secret', jwt: {exp: 5})

    assert_requested :get,
                     "https://example.com/method-specific-security",
                     times: 1 do |req|
      jwt_token = req.headers["Authorization"].split('Bearer ')[1]

      decoded = JWT.decode jwt_token, 'another-secret', true, {algorithm: 'HS256'}


      assert now + (5 * 60) + 1 >= decoded[0]['exp']
      assert now + (5 * 60) - 1 <= decoded[0]['exp']
    end
  end
end
