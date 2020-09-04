require "rack"
require "string"

class OASRequest
  def self.spec(oas)
    Class.new do
      def initialize(server:, headers: {}, params: {}, query: {})
        @server = server

        @headers = headers
        @params = params
        @query = query
      end

      def __request(method:, url:, options: {})
        # merge params with global defaults
        params = @params.merge(options.fetch(:params, {}))

        # process path template
        url_path = OASRequest::PathTemplate.template url, params

        # construct final host & url parts
        uri = URI "#{@server}#{url_path}"

        # convert query back to regular hash
        search_obj = Rack::Utils.parse_query uri.query

        authorization_headers = {}

        # Overrides
        headers = @headers.merge(authorization_headers).merge(options.fetch(:headers, {}))
        query = search_obj.merge(@query).merge(options.fetch(:query, {}))

        # final query string
        search = Rack::Utils.build_query query

        OASRequest::HTTP.http(
            headers: headers,
            host: uri.host,
            method: method,
            port: uri.port,
            body: options.fetch(:body, nil),
            path: uri.path + (search.empty? ? "" : "?#{search}"),
            protocol: uri.scheme
        )
      end


      oas["paths"].each do |url, methods|
        methods.each do |method, definition|
          # filter to paths that contain an operationId
          next unless definition.is_a?(Hash) && definition["operationId"]

          operation_id = definition["operationId"]
          underscored_operation_id = operation_id.underscore

          request_method = Proc.new do |headers: {}, params: {}, query: {}, body: nil|
            __request(
                method: method,
                url: url,
                options: {
                    headers: headers,
                    params: params,
                    query: query,
                    body: body
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
