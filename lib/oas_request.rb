require "rack"
require "string"

class OASRequest
  def self.spec(oas)
    @@oas_security_schemes = (oas["components"] && oas["components"]["securitySchemes"]) ? oas["components"]["securitySchemes"] : nil

    Class.new do
      def initialize(server:, headers: {}, params: {}, query: {}, secret: nil, jwt: {})
        # TODO analyze oas.servers
        @server = server.chomp("/")

        # default properties
        @headers = headers
        @params = params
        @query = query
        @secret = secret
        @jwt = jwt
      end

      def __request(method:, url:, security_requirements: {}, options: {})
        # merge params with global defaults
        params = @params.merge(options.fetch(:params, {}))

        # process path template
        url_path = OASRequest::PathTemplate.template url, params

        # construct final host & url parts
        uri = URI "#{@server}#{url_path}"

        # Get security options from global config and per API method config
        method_security = {}
        if options.fetch(:secret, nil)
          method_security[:secret] = options.fetch(:secret, nil)
        end
        if options.fetch(:jwt, nil)
          method_security[:jwt] = options.fetch(:jwt, nil)
        end

        security_options = {}.merge({secret: @secret, jwt: @jwt}).merge(method_security)

        # Get security values in headers and queries from the required security schemas, and the given security options
        security_headers, security_queries = OASRequest::Security::parse_security(@@oas_security_schemes, security_requirements, security_options)

        # convert query back to regular hash
        search_obj = Rack::Utils.parse_query uri.query

        # Overrides
        headers = {}.merge(@headers).merge(security_headers).merge(options.fetch(:headers, {}))
        query = search_obj.merge(@query).merge(security_queries).merge(options.fetch(:query, {}))

        # final query string
        search = Rack::Utils.build_query query

        OASRequest::HTTP.http(
            headers: headers.reduce({}) do |headers, raw_header|
              header_name, header_value = raw_header
              headers[header_name] = header_value.kind_of?(Array) ? header_value.join(',') : header_value
              headers
            end,
            host: uri.host,
            method: method,
            port: uri.port,
            body: options.fetch(:body, nil),
            path: uri.path + (search.empty? ? "" : "?#{search}"),
            protocol: uri.scheme
        )
      end

      global_security = oas["security"] ? oas["security"][0] || {} : {}

      oas["paths"].each do |url, methods|
        methods.each do |method, definition|
          # filter to paths that contain an operationId
          next unless definition.is_a?(Hash) && definition["operationId"]

          operation_id = definition["operationId"]
          underscored_operation_id = operation_id.underscore

          method_security = definition["security"] ? definition["security"][0] || {} : {}

          # Get the global security requirements, followed by the per method security requirements
          security_requirements = {}.merge(global_security).merge(method_security)

          request_method = Proc.new do |headers: {}, params: {}, query: {}, body: nil, secret: nil, jwt: {}|
            __request(
                method: method,
                url: url,
                security_requirements: security_requirements,
                options: {
                    headers: headers,
                    params: params,
                    query: query,
                    body: body,
                    secret: secret,
                    jwt: jwt
                }
            )
          end

          # process each method
          define_method(operation_id, &request_method)

          # Rubyify it getFooByBar -> get_foo_by_bar
          define_method(underscored_operation_id, &request_method) if operation_id != underscored_operation_id
        end
      end
    end
  end
end

require "oas_request/path_template"
require "oas_request/http"
require "oas_request/security"
