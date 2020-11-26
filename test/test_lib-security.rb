require "jwt"
require "minitest/autorun"
require "oas_request"

class LibSecurityTest < Minitest::Test
  def test_simple_case
    mock_oas_security_schemes = {
        "BearerAuth" => {
            "type" => 'http',
            "scheme" => 'bearer'
        },
        "ApiKeyAuthHeader" => {
            "type" => 'apiKey',
            "in" => 'header',
            "name" => 'X-API-KEY'
        },
        "ApiKeyAuthQuery" => {
            "type" => 'apiKey',
            "in" => 'query',
            "name" => 'X-API-KEY'
        },
        "BearerAuthJWT" => {
            "type" => 'http',
            "scheme" => 'bearer',
            "bearerFormat" => 'JWT'
        }
    }

    mock_secret = '__secret__'
    result = OASRequest::Security.parse_security(
        mock_oas_security_schemes,
        {
            "BearerAuth" => [],
            "ApiKeyAuthHeader" => [],
            "ApiKeyAuthQuery" => []
        },
        {
            secret: mock_secret,
            jwt: {
                exp: '5m'
            }
        })

    assert_equal result, [
        {
            authorization: ["Bearer #{mock_secret}"],
            "X-API-KEY" => [mock_secret]
        },
        {
            "X-API-KEY" => [mock_secret]
        }
    ]
  end

  def test_api_key_with_multiple_values_case
    mock_oas_security_schemes = {
        "ApiKeyAuthHeader" => {
            "type" => 'apiKey',
            "in" => 'header',
            "name" => 'X-API-KEY'
        },
        "ApiKeyAuthQuery" => {
            "type" => 'apiKey',
            "in" => 'query',
            "name" => 'X-API-KEY'
        },
        "ApiKeyAuthHeaderAnother" => {
            "type" => 'apiKey',
            "in" => 'header',
            "name" => 'X-API-KEY'
        },
        "ApiKeyAuthQueryAnother" => {
            "type" => 'apiKey',
            "in" => 'query',
            "name" => 'X-API-KEY'
        }
    }

    mock_secret = '__secret__'
    result = OASRequest::Security.parse_security(
        mock_oas_security_schemes,
        {
            "ApiKeyAuthHeader" => [],
            "ApiKeyAuthQuery" => [],
            "ApiKeyAuthHeaderAnother" => [],
            "ApiKeyAuthQueryAnother" => []
        },
        {
            secret: mock_secret,
            jwt: {
                exp: '5m'
            }
        })

    assert_equal result, [
        {
            "X-API-KEY" => [mock_secret, mock_secret]
        },
        {
            "X-API-KEY" => [mock_secret, mock_secret]
        }
    ]
  end

  def test_bearer_with_multiple_values_case
    mock_oas_security_schemes = {
        "BearerAuth" => {
            "type" => 'http',
            "scheme" => 'bearer'
        },
        "BearerAuthJWT" => {
            "type" => 'http',
            "scheme" => 'bearer',
            "bearerFormat" => 'JWT'
        }
    }

    mock_secret = '__secret__'
    result = OASRequest::Security.parse_security(
        mock_oas_security_schemes,
        {
            "BearerAuth" => [],
            "BearerAuthJWT" => []
        },
        {
            secret: mock_secret,
            jwt: {
                exp: 5
            }
        })

    assert_equal result[0][:authorization][0], "Bearer #{mock_secret}"
    assert result[0][:authorization][1] != "Bearer #{mock_secret}"
  end

  def test_http_basic_is_not_supported
    mock_oas_security_schemes = {
        "BasicAuth" => {
            "type" => 'http',
            "scheme" => 'basic'
        }
    }

    mock_secret = '__secret__'

    err = assert_raises RuntimeError do
      OASRequest::Security.parse_security(
          mock_oas_security_schemes,
          {
              "BasicAuth" => []
          },
          {
              secret: mock_secret
          })
    end

    assert_equal err.message, 'basic scheme type not implemented.'
  end

  def test_oauth2_is_not_supported
    mock_oas_security_schemes = {
        "OauthAuth" => {
            "type" => 'oauth2'
        }
    }

    mock_secret = '__secret__'

    err = assert_raises RuntimeError do
      OASRequest::Security.parse_security(
          mock_oas_security_schemes,
          {
              "OauthAuth" => []
          },
          {
              secret: mock_secret
          })
    end

    assert_equal err.message, 'oauth2 type not implemented.'
  end

  def test_openIdConnect_is_not_supported
    mock_oas_security_schemes = {
        "OpenIdConnectAuth" => {
            "type" => 'openIdConnect'
        }
    }

    mock_secret = '__secret__'

    err = assert_raises RuntimeError do
      OASRequest::Security.parse_security(
          mock_oas_security_schemes,
          {
              "OpenIdConnectAuth" => []
          },
          {
              secret: mock_secret
          })
    end
    assert_equal err.message, 'openIdConnect type not implemented.'
  end


  def test_apiKey_in_cookie_is_not_supported
    mock_oas_security_schemes = {
        "CookieAuth" => {
            "type" => 'apiKey',
            "in" => 'cookie'
        }
    }

    mock_secret = '__secret__'

    err = assert_raises RuntimeError do
      OASRequest::Security.parse_security(mock_oas_security_schemes,
                                          {
                                              "CookieAuth" => []
                                          },
                                          {
                                              secret: mock_secret
                                          })
    end
    assert_equal err.message, 'cookie type not implemented.'
  end

  def test_jwt_with_invalid_options
    mock_oas_security_schemes = {
        "BearerAuthJWT" => {
            "type" => 'http',
            "scheme" => 'bearer',
            "bearerFormat" => 'JWT'
        }
    }

    mock_secret = '__secret__'

    err = assert_raises RuntimeError do
      OASRequest::Security.parse_security(
          mock_oas_security_schemes,
          {
              "BearerAuthJWT" => []
          },
          {
              secret: mock_secret,
              jwt: {
                  exp: 'some invalid value'
              }
          })
    end
    assert_equal err.message, 'exp must be a number.'
  end

  def test_jwt_with_exp_time
    mock_oas_security_schemes = {
        "BearerAuthJWT" => {
            "type" => 'http',
            "scheme" => 'bearer',
            "bearerFormat" => 'JWT'
        }
    }

    mock_secret = '__secret__'
    now = Time.now.to_i

    result = OASRequest::Security.parse_security(
        mock_oas_security_schemes,
        {
            "BearerAuthJWT" => []
        },
        {
            secret: mock_secret,
            jwt: {
                exp: 5
            }
        })

    jwt_token = result[0][:authorization][0].split('Bearer ')[1]

    decoded = JWT.decode jwt_token, mock_secret, true, {algorithm: 'HS256'}

    assert now + (5 * 60) + 1 >= decoded[0]['exp']
    assert now + (5 * 60) - 1 <= decoded[0]['exp']
  end

  def test_jwt_without_exp_time
    mock_oas_security_schemes = {
        "BearerAuthJWT" => {
            "type" => 'http',
            "scheme" => 'bearer',
            "bearerFormat" => 'JWT'
        }
    }

    mock_secret = '__secret__'

    result = OASRequest::Security.parse_security(
        mock_oas_security_schemes,
        {
            "BearerAuthJWT" => []
        },
        {
            secret: mock_secret,
            jwt: {}
        })

    jwt_token = result[0][:authorization][0].split('Bearer ')[1]

    decoded = JWT.decode jwt_token, mock_secret, true, {algorithm: 'HS256'}

    assert_equal decoded[0], {}
  end

  def test_jwt_without_options
    mock_oas_security_schemes = {
        "BearerAuthJWT" => {
            "type" => 'http',
            "scheme" => 'bearer',
            "bearerFormat" => 'JWT'
        }
    }

    mock_secret = '__secret__'

    result = OASRequest::Security.parse_security(
        mock_oas_security_schemes,
        {
            "BearerAuthJWT" => []
        },
        {
            secret: mock_secret
        })

    jwt_token = result[0][:authorization][0].split('Bearer ')[1]

    decoded = JWT.decode jwt_token, mock_secret, true, {algorithm: 'HS256'}

    assert_equal decoded[0], {}
  end
end
