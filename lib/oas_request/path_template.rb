class OASRequest::PathTemplate
  def self.template(url, params)
    params_symbol = params.transform_keys(&:to_s)

    params_in_url = url.scan(/\{(?<param>[^\/]+)\}/)

    params_in_url.each do |params_group|
      params_group.each do |param|
        next unless params_symbol.key? param

        r = Regexp.new "{#{param}}"

        url = url.gsub(r, params_symbol.fetch(param).to_s)
      end
    end

    url.gsub("{", "%7B").gsub("}", "%7D")
  end
end
