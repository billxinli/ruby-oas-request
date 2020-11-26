require 'jwt'

class OASRequest::Security
  def self.is_number?(input)
    true if Float(input) rescue false
  end

  def self.parse_security(oas_security_schemes, security_requirements, security_options)
    headers = {}
    queries = {}

    if oas_security_schemes
      security_requirements.each do |key, value|
        security_scheme = oas_security_schemes.fetch(key, nil)

        # Security scheme is not defined in the global scheme, throw error
        unless security_scheme
          raise "Security scheme #{key} not defined in spec."
        end

        secret = security_options[:secret]
        jwt = security_options[:jwt]

        case security_scheme["type"]
        when "http"
          unless headers.include?(:authorization)
            headers[:authorization] = []
          end

          case security_scheme['scheme']
          when 'bearer'

            case security_scheme['bearerFormat']
            when 'JWT'
              payload = {}

              if jwt
                exp = jwt[:exp]

                if exp
                  raise "exp must be a number." unless self.is_number?(exp)
                  payload[:exp] = Time.now.to_i + (exp.to_i * 60)
                end
              end

              headers[:authorization].push("Bearer #{JWT.encode(payload, secret)}")

            else
              headers[:authorization].push("Bearer #{secret}")
            end
          else
            raise "#{security_scheme["scheme"]} scheme type not implemented."
          end

        when "apiKey"
          # apiKey type

          case security_scheme["in"]
          when "header"
            unless headers.include?(security_scheme["name"])
              headers[security_scheme["name"]] = []
            end
            headers[security_scheme["name"]].push(secret)

          when "query"
            unless queries.include?(security_scheme["name"])
              queries[security_scheme["name"]] = []
            end
            queries[security_scheme["name"]].push(secret)

          else
            raise "#{security_scheme["in"]} type not implemented."
          end

        else
          raise "#{security_scheme["type"]} type not implemented."
        end
      end
    end

    [headers, queries]
  end
end
