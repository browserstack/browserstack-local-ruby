require 'net/http'
require 'net/https'
require 'rbconfig'
require 'openssl'
require 'tmpdir'
require 'fileutils'
require 'browserstack/localexception'
require 'browserstack/fetch_download_source_url'
require 'browserstack/version'

module BrowserStack

class LocalBinary
  BASE_RETRIES = 9
  FALLBACK_TRIGGER_RETRY = 4

  def initialize(conf = {})
    @auth_token = conf[:auth_token] || ENV['BROWSERSTACK_ACCESS_KEY']
    @proxy_host = conf[:proxy_host]
    @proxy_port = conf[:proxy_port]
    @user_agent = conf[:user_agent] || "browserstack-local-ruby/#{BrowserStack::VERSION}"

    @windows = !!(RbConfig::CONFIG['host_os'] =~ /mswin|msys|mingw|cygwin|bccwin|wince|emc/)
    @binary_filename = compute_binary_filename
    @source_url = nil
    @download_error_message = nil

    @ordered_paths = [
      File.join(File.expand_path('~'), '.browserstack'),
      Dir.pwd,
      Dir.tmpdir
    ]
  end

  def binary_path
    dest_parent_dir = get_available_dirs
    bin_path = File.join(dest_parent_dir, dest_binary_name)

    return bin_path if File.exist?(bin_path) && verify_binary(bin_path)

    File.delete(bin_path) if File.exist?(bin_path)
    download_with_retries(bin_path)
  end

  private

  def dest_binary_name
    @windows ? 'BrowserStackLocal.exe' : 'BrowserStackLocal'
  end

  def compute_binary_filename
    host_os = RbConfig::CONFIG['host_os']
    host_cpu = RbConfig::CONFIG['host_cpu']
    case host_os
    when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
      'BrowserStackLocal.exe'
    when /darwin|mac os/
      'BrowserStackLocal-darwin-x64'
    when /linux/
      if host_cpu =~ /arm64|aarch64/
        'BrowserStackLocal-linux-arm64'
      elsif host_os =~ /linux-musl/
        'BrowserStackLocal-alpine'
      elsif 1.size == 8
        'BrowserStackLocal-linux-x64'
      else
        'BrowserStackLocal-linux-ia32'
      end
    else
      raise BrowserStack::LocalException.new("Unsupported host OS: #{host_os}")
    end
  end

  def download_with_retries(bin_path)
    retries = BASE_RETRIES
    while retries > 0
      refresh_source_url(retries) if retries == BASE_RETRIES || retries == FALLBACK_TRIGGER_RETRY
      begin
        download_to(@source_url + '/' + @binary_filename, bin_path)
        return bin_path if verify_binary(bin_path)
        @download_error_message = 'Downloaded binary failed verification'
      rescue StandardError => e
        @download_error_message = "Download failed: #{e.message}"
      end
      File.delete(bin_path) if File.exist?(bin_path)
      retries -= 1
    end

    raise BrowserStack::LocalException.new(
      "Failed to download BrowserStack Local binary after #{BASE_RETRIES} attempts. " \
      "Last error: #{@download_error_message}"
    )
  end

  def refresh_source_url(retries)
    is_fallback = (retries == FALLBACK_TRIGGER_RETRY) && !@download_error_message.nil?
    begin
      @source_url = BrowserStack::FetchDownloadSourceUrl.call(
        auth_token: @auth_token,
        user_agent: @user_agent,
        fallback: is_fallback,
        error_message: @download_error_message,
        proxy_host: @proxy_host,
        proxy_port: @proxy_port
      )
    rescue StandardError => e
      raise if @source_url.nil?
      @download_error_message = "Source URL refresh failed: #{e.message}"
    end
  end

  def download_to(url, bin_path)
    uri = URI.parse(url)
    http_class = if @proxy_host && @proxy_port
                   Net::HTTP::Proxy(@proxy_host, @proxy_port.to_i)
                 else
                   Net::HTTP
                 end
    http = http_class.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.open_timeout = 10
    http.read_timeout = 30

    req = Net::HTTP::Get.new(uri.request_uri)
    req['User-Agent'] = @user_agent

    res = http.request(req)
    raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)

    File.open(bin_path, 'wb') { |f| f.write(res.body) }
    FileUtils.chmod 0755, bin_path
  end

  def verify_binary(bin_path)
    binary_response = IO.popen(bin_path + " --version").readline
    !!(binary_response =~ /BrowserStack Local version \d+\.\d+/)
  rescue StandardError
    false
  end

  def get_available_dirs
    @ordered_paths.each do |path|
      return path if make_path(path)
    end
    raise BrowserStack::LocalException.new('Error trying to download BrowserStack Local binary')
  end

  def make_path(path)
    FileUtils.mkdir_p(path) unless File.directory?(path)
    true
  rescue StandardError
    false
  end
end

end
