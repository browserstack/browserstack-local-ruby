require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'browserstack/local'

class BrowserStackLocalTest < Minitest::Test
  def setup
    @bs_local = BrowserStack::Local.new
  end

  # The tests below actually start the BrowserStackLocal binary and open a
  # tunnel, so they need a valid BROWSERSTACK_ACCESS_KEY and network access.
  # Skip them (instead of erroring) when no key is available so the rest of
  # the suite stays green in credential-less environments such as CI.
  def skip_without_credentials
    skip 'requires BROWSERSTACK_ACCESS_KEY (live integration test)' if ENV['BROWSERSTACK_ACCESS_KEY'].to_s.empty?
  end

  def test_check_pid
    skip_without_credentials
    @bs_local.start
    refute_nil @bs_local.pid, 0
  end

  def test_is_running
    skip_without_credentials
    @bs_local.start
    assert_equal true, @bs_local.isRunning
  end

  def test_multiple_binary
    skip_without_credentials
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
