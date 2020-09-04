require "net/http"

REQUEST_CLASSES = {
  get: Net::HTTP::Get,
  head: Net::HTTP::Head,
  post: Net::HTTP::Post,
  patch: Net::HTTP::Patch,
  put: Net::HTTP::Put,
  options: Net::HTTP::Options,
  delete: Net::HTTP::Delete
}

class OASRequest::HTTP
  def self.config(opts = {})
    # set default options
    opts[:host] ||= "localhost"
    opts[:path] ||= "/"
    opts[:port] ||= 443
    opts[:protocol] ||= "https"
    opts[:headers] ||= {}

    # set standard header values
    opts[:headers]["accept"] = "application/json"

    if opts[:body]
      # set content-type header when body is present
      opts[:headers]["content-type"] = "application/json"

      # ensure body is in JSON format
      opts[:body] = opts[:body].to_json
    end

    opts
  end

  def self.get_request(method, opts = {})
    raise "Unknown method #{method}" unless REQUEST_CLASSES.has_key? method.downcase.to_sym

    uri = URI "#{opts[:protocol]}://#{opts[:host]}:#{opts[:port]}#{opts[:path]}"

    request_class = REQUEST_CLASSES[method.downcase.to_sym]

    req = request_class.new uri, opts[:headers]

    req.body = opts[:body] if opts[:body]

    req
  end

  def self.http(headers:, host:, method:, port:, body:, path:, protocol:)
    options = config(
      host: host,
      path: path,
      port: port,
      protocol: protocol,
      headers: headers,
      body: body
    )

    req = get_request method, options

    http = Net::HTTP.new options[:host], options[:port]
    http.use_ssl = options[:protocol] == "https"

    response = http.request req

    headers = response.to_hash
    body = response.body
    if headers.fetch("content-type", []).join.include? "application/json"
      begin
        body = JSON.parse response.body
      rescue
        body = response.body
      end
    end

    {
      headers: headers,
      status_code: response.code.to_i,
      status_message: response.message,
      body: body
    }
  end
end
