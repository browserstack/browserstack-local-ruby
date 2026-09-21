require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'minitest/mock'
require 'tmpdir'
require 'browserstack/local'

class BrowserStackLocalTest < Minitest::Test
  def setup
    @bs_local = BrowserStack::Local.new
  end

  def test_check_pid
    @bs_local.start
    refute_nil @bs_local.pid, 0
  end

  def test_is_running
    @bs_local.start
    assert_equal true, @bs_local.isRunning
  end

  def test_multiple_binary
    @bs_local.start
    bs_local_2 = BrowserStack::Local.new
    second_log_file = File.join(Dir.pwd, 'local2.log')
    assert_raises BrowserStack::LocalException do
      bs_local_2.start({'logfile' => second_log_file})
    end
    File.delete(second_log_file)
  end

  def test_enable_verbose
    @bs_local.add_args('v')
    assert_match /\-v/, @bs_local.command
  end

  def test_set_folder
    @bs_local.add_args 'f', "/"
    assert_match /\-f/, @bs_local.command
    assert_match /\//, @bs_local.command
  end

  def test_enable_force
    @bs_local.add_args "force"
    assert_match /\-force/, @bs_local.command
  end

  def test_enable_only
    @bs_local.add_args "only"
    assert_match /\-only/, @bs_local.command
  end

  def test_enable_only_automate
    @bs_local.add_args "onlyAutomate"
    assert_match /\-onlyAutomate/, @bs_local.command
  end

  def test_enable_force_local
    @bs_local.add_args "forcelocal"
    assert_match /\-forcelocal/, @bs_local.command
  end

  def test_set_local_identifier
    @bs_local.add_args "localIdentifier", "randomString"
    assert_match /\-localIdentifier randomString/, @bs_local.command
  end

  def test_custom_boolean_argument
    @bs_local.add_args "boolArg1"
    @bs_local.add_args "boolArg2"
    assert_match /\-boolArg1/, @bs_local.command
    assert_match /\-boolArg2/, @bs_local.command
  end

  def test_custom_keyval
    @bs_local.add_args "customKey1", "'custom value1'"
    @bs_local.add_args "customKey2", "'custom value2'"
    assert_match /\-customKey1 \'custom value1\'/, @bs_local.command
    assert_match /\-customKey2 \'custom value2\'/, @bs_local.command
  end

  def test_set_proxy
    @bs_local.add_args "proxyHost", "localhost"
    @bs_local.add_args "proxyPort", 8080
    @bs_local.add_args "proxyUser", "user"
    @bs_local.add_args "proxyPass", "pass"
    assert_match /\-proxyHost localhost \-proxyPort 8080 \-proxyUser user \-proxyPass pass/, @bs_local.command
  end

  def test_force_proxy
    @bs_local.add_args "forceproxy"
    assert_match /\-forceproxy/, @bs_local.command
  end

  def test_hosts
    @bs_local.add_args "hosts", "localhost,8080,0"
    assert_match /localhost\,8080\,0/, @bs_local.command
  end

  def teardown
    @bs_local.stop
  end
end

# Regression tests for the logfile-creation step in Local#start (CWE-78).
# The logfile used to be created with `system("echo ... > #{@logfile}")`, which
# passed the caller-supplied path through a shell. These tests drive the public
# `start` entry point but abort just after the logfile step (a fake binarypath
# skips the download; stubbing start_command_args prevents launching the binary),
# so they need no credentials, network, or tunnel.
class BrowserStackLocalLogfileTest < Minitest::Test
  class AbortAfterLogfile < StandardError; end

  # Runs `start` with the given logfile value, aborting right after the logfile
  # is created (before the real binary is spawned).
  def start_up_to_logfile(logfile_value)
    bs = BrowserStack::Local.new('dummy_key')
    bs.stub(:start_command_args, ->(*) { raise AbortAfterLogfile }) do
      begin
        # An existing, harmless executable as binarypath skips the binary download.
        bs.start('binarypath' => existing_executable, 'logfile' => logfile_value)
      rescue AbortAfterLogfile
        # expected: we intentionally stop before launching the binary
      end
    end
  end

  def existing_executable
    ['/bin/true', '/usr/bin/true'].find { |p| File.executable?(p) } || RbConfig.ruby
  end

  def test_shell_metacharacters_in_logfile_path_are_not_executed
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        marker = File.join(dir, 'pwned')
        # Unix payload: close the single quote around @logfile, run touch, reopen.
        # Pre-fix this expands to: echo '' > 'log' ; touch <marker> ; echo 'x'
        payload = "log' ; touch #{marker} ; echo 'x"

        start_up_to_logfile(payload)

        refute File.exist?(marker),
               'shell metacharacters in the logfile path were executed (command injection)'
      end
    end
  end

  def test_logfile_path_is_treated_as_a_literal_filename
    Dir.mktmpdir do |dir|
      logfile = File.join(dir, 'sub', 'my log.txt') # spaces + missing subdir
      start_up_to_logfile(logfile)

      assert File.file?(logfile),
             'the logfile should be created as a literal path, even with spaces / a missing dir'
      assert_equal '', File.read(logfile), 'the logfile should be truncated to empty'
    end
  end
end

class BrowserStackLocalBinaryTest < Minitest::Test
  def test_default_user_agent_contains_gem_name_and_version
    ua = BrowserStack::LocalBinary.new(auth_token: 'fake').instance_variable_get(:@user_agent)
    assert_match(/^browserstack-local-ruby\/#{Regexp.escape(BrowserStack::VERSION)}$/, ua)
  end

  def test_custom_user_agent_respected
    ua = BrowserStack::LocalBinary.new(auth_token: 'fake', user_agent: 'custom/1.0').instance_variable_get(:@user_agent)
    assert_equal 'custom/1.0', ua
  end

  def test_linux_arm64_picks_arm64_binary
    with_host_config('linux-gnu', 'aarch64') do
      assert_equal 'BrowserStackLocal-linux-arm64',
                   BrowserStack::LocalBinary.new.send(:compute_binary_filename)
    end
  end

  def test_linux_arm64_alt_cpu_name_picks_arm64_binary
    with_host_config('linux-gnu', 'arm64') do
      assert_equal 'BrowserStackLocal-linux-arm64',
                   BrowserStack::LocalBinary.new.send(:compute_binary_filename)
    end
  end

  def test_alpine_arm64_picks_arm64_not_alpine
    # Matches Node SDK: arm64 wins over musl on Linux
    with_host_config('linux-musl', 'aarch64') do
      assert_equal 'BrowserStackLocal-linux-arm64',
                   BrowserStack::LocalBinary.new.send(:compute_binary_filename)
    end
  end

  def test_alpine_x64_picks_alpine_binary
    with_host_config('linux-musl', 'x86_64') do
      assert_equal 'BrowserStackLocal-alpine',
                   BrowserStack::LocalBinary.new.send(:compute_binary_filename)
    end
  end

  def test_darwin_arm64_picks_darwin_x64
    # No darwin-arm64 binary; runs under Rosetta. Matches Node.
    with_host_config('darwin22', 'arm64') do
      assert_equal 'BrowserStackLocal-darwin-x64',
                   BrowserStack::LocalBinary.new.send(:compute_binary_filename)
    end
  end

  def test_local_binary_accepts_proxy_conf
    bin = BrowserStack::LocalBinary.new(
      auth_token: 'fake',
      proxy_host: 'proxy.example.com',
      proxy_port: 8080
    )
    assert_equal 'proxy.example.com', bin.instance_variable_get(:@proxy_host)
    assert_equal 8080, bin.instance_variable_get(:@proxy_port)
  end

  private

  def with_host_config(host_os, host_cpu)
    orig = RbConfig::CONFIG.dup
    RbConfig::CONFIG['host_os'] = host_os
    RbConfig::CONFIG['host_cpu'] = host_cpu
    yield
  ensure
    RbConfig::CONFIG.replace(orig)
  end
end
