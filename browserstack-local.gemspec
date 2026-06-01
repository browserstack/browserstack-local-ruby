require File.expand_path('../lib/browserstack/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'browserstack-local'
  s.version     = BrowserStack::VERSION
  s.date        = '2026-06-01'
  s.summary     = "BrowserStack Local"
  s.description = "Ruby bindings for BrowserStack Local"
  s.authors     = ["BrowserStack"]
  s.email       = 'support@browserstack.com'
  s.files       = [
    "lib/browserstack/local.rb",
    "lib/browserstack/localbinary.rb",
    "lib/browserstack/localexception.rb",
    "lib/browserstack/fetch_download_source_url.rb",
    "lib/browserstack/version.rb"
  ]
  s.homepage    =
    'http://rubygems.org/gems/browserstack-local'
  s.license       = 'MIT'
end
