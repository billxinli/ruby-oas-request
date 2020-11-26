require "minitest/autorun"
require "json"
require "oas_request"
require "webmock/minitest"

class MissingSecurityTest < Minitest::Test
  def setup
    WebMock.disallow_net_connect!

    file = File.open File.expand_path("../fixtures/missing-security.json", __FILE__)
    data = JSON.parse file.read

    @api = OASRequest.spec(data)
  end

  def test_missing_security_raise_error
    api = @api.new(server: "https://example.com", secret: "secret")

    err = assert_raises RuntimeError do

      api.test_global()
    end

    assert_equal err.message, "Security scheme MissingSecurityMethod not defined in spec."
  end
end
