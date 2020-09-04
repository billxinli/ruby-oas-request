require "minitest/autorun"
require "json"
require "oas_request"
require "webmock/minitest"

class PetstoreTest < Minitest::Test
  def setup
    WebMock.disallow_net_connect!

    file = File.open File.expand_path("../fixtures/petstore.json", __FILE__)
    data = JSON.parse file.read

    @api = OASRequest.spec(data)
  end

  def test_generate_methods
    api = @api.new(server: "https://example.com")

    assert api.respond_to?(:listPets)
    assert api.respond_to?(:createPets)
    assert api.respond_to?(:showPetById)
  end

  def test_methods_are_callable
    stub_request(:get, "https://example.com/pets/%7BpetId%7D").with(
      headers: {
        "Accept" => "application/json",
        "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
        "Host" => "example.com",
        "User-Agent" => "Ruby"
      }
    ).to_return(status: 200, body: "", headers: {})

    api = @api.new(server: "https://example.com")

    api.showPetById

    assert_requested :get,
      "https://example.com/pets/%7BpetId%7D",
      headers: {"Accept" => "application/json",
                "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                "Host" => "example.com",
                "User-Agent" => "Ruby"},
      times: 1
  end

  def test_methods_options
    stub_request(:get, "https://example.com/pets/1").with(
      headers: {
        "Accept" => "application/json",
        "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
        "Host" => "example.com",
        "User-Agent" => "Ruby"
      }
    ).to_return(status: 200, body: "", headers: {})

    api = @api.new(server: "https://example.com")

    api.showPetById({params: {petId: 1}})

    assert_requested :get,
      "https://example.com/pets/1",
      headers: {"Accept" => "application/json",
                "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                "Host" => "example.com",
                "User-Agent" => "Ruby"},
      times: 1
  end

  def test_global_defaults
    stub_request(:get, "https://example.com/pets/1?is_good=yes&name=ruby").with(
      headers: {
        "Accept" => "application/json",
        "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
        "Host" => "example.com",
        "User-Agent" => "Ruby",
        "X-Pet-Type" => "dog"
      }
    ).to_return(status: 200, body: "", headers: {})

    api = @api.new(server: "https://example.com",
                   headers: {
                     'x-pet-type': "dog"
                   },
                   params: {
                     petId: 1
                   },
                   query: {
                     name: "ruby"
                   })

    api.showPetById({query: {is_good: "yes"}})

    assert_requested :get,
      "https://example.com/pets/1?is_good=yes&name=ruby",
      headers: {"Accept" => "application/json",
                "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                "Host" => "example.com",
                "User-Agent" => "Ruby",
                "X-Pet-Type" => "dog"},
      times: 1
  end
end
