Gem::Specification.new do |s|
  s.name        = 'browserstack-local'
  s.version     = '1.4.3'
  s.date        = '2023-08-24'
  s.summary     = "BrowserStack Local"
  s.description = "Ruby bindings for BrowserStack Local"
  s.authors     = ["BrowserStack"]
  s.email       = 'support@browserstack.com'
  s.files       = ["lib/browserstack/local.rb", "lib/browserstack/localbinary.rb", "lib/browserstack/localexception.rb"]
  s.homepage    = 'http://rubygems.org/gems/browserstack-local'
  s.license     = 'MIT'
  s.add_dependency "subprocess", "~> 1.5"
end

