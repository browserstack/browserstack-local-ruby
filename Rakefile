require "rake/testtask"

task :default => :test
Rake::TestTask.new do |t|
  t.pattern = "test/*test.rb"
  t.verbose = false
end

task :build do
  system "mkdir dist"
  system "gem build browserstack-local.gemspec"
  move_command = RbConfig::CONFIG['host_os'].match(/mswin|msys|mingw|cygwin|bccwin|wince|emc|win32/) ? "move" : "mv";
  system "#{move_command} browserstack-local-*.gem dist"
  system "gem install ./dist/browserstack-local-*.gem"
end
