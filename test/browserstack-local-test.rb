require 'rubygems'
require 'minitest'
require 'minitest/autorun'
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
