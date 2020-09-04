require "minitest/autorun"
require "json"
require "oas_request"
require "webmock/minitest"

class HTTPBinTest < Minitest::Test
  def setup
    WebMock.allow_net_connect!
    file = File.open File.expand_path("../fixtures/httpbin.json", __FILE__)
    data = JSON.parse file.read

    @api = OASRequest.spec(data)
  end

  def test_generate_methods
    api = @api.new(server: "https://httpbin.org")

    assert api.respond_to?(:getIP)
    assert api.respond_to?(:httpGet)
    assert api.respond_to?(:httpPost)
    assert api.respond_to?(:httpDelete)
  end

  def test_get_root
    api = @api.new(server: "https://httpbin.org")

    results = api.httpGet

    assert_equal results[:headers]["content-type"], ["application/json"]
    # Webmock messes with the internals of connections
    # assert_equal results[:headers]["connection"], ["close"]
    assert_equal results[:headers]["access-control-allow-origin"], ["*"]
    assert_equal results[:headers]["access-control-allow-credentials"], ["true"]

    assert_equal results[:status_code], 200
    assert_equal results[:status_message], "OK"

    assert_equal results[:body]["args"], {}
    assert_equal results[:body]["headers"]["Accept"], "application/json"
    assert_equal results[:body]["headers"]["Host"], "httpbin.org"
    assert_equal results[:body]["url"], "https://httpbin.org/get"
  end

  def test_post_plain
    api = @api.new(server: "https://httpbin.org")

    results = api.httpPost({body: "foo"})

    assert_equal results[:body]["data"], '"foo"'
  end

  def test_post_json
    api = @api.new(server: "https://httpbin.org")

    results = api.httpPost({body: {foo: "bar"}})

    assert_equal results[:body]["data"], '{"foo":"bar"}'
    assert_equal results[:body]["json"], {"foo" => "bar"}
  end
end
