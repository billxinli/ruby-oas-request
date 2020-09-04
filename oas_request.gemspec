$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))

require "oas_request/version"

Gem::Specification.new do |s|
  s.name = "oas_request"
  s.version = OASRequest::VERSION
  s.date = "2020-07-28"
  s.summary = "OAS request generator"
  s.description = "A simple OAS request generator"
  s.authors = [""]
  s.email = ""
  s.files = %w[lib/oas_request.rb lib/oas_request/path_template.rb lib/oas_request/http.rb]
  s.homepage = "https://rubygems.org/gems/oas_request"
  s.license = "MIT"

  s.required_ruby_version = ">= 2.5.0"
  s.add_runtime_dependency "rack", "~> 2.2", ">= 2.2.3"
  s.add_development_dependency "webmock", "~> 3.8", ">= 3.8.3"
end
