require "rake/testtask"

task :default => :test
Rake::TestTask.new do |t|
  t.pattern = "test/*test.rb"
  t.verbose = false
end

task :build do
  system "mkdir -p dist"
  system "gem build browserstack-local.gemspec"
  system "mv browserstack-local-*.gem dist"
  system "gem install ./dist/browserstack-local-*.gem"
end
