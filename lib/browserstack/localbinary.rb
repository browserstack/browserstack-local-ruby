require 'net/http'
require 'net/https'
require 'rbconfig'
require 'openssl'
require 'tmpdir'
require 'browserstack/localexception'

module BrowserStack
  
class LocalBinary
  def initialize
    host_os = RbConfig::CONFIG['host_os']
    @http_path = case host_os
    when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
      @windows = true
      "https://www.browserstack.com/local-testing/downloads/binaries/BrowserStackLocal.exe"
    when /darwin|mac os/
      "https://www.browserstack.com/local-testing/downloads/binaries/BrowserStackLocal-darwin-x64"
    when /linux-musl/
      "https://www.browserstack.com/local-testing/downloads/binaries/BrowserStackLocal-alpine"
    when /linux/
      if 1.size == 8
        "https://www.browserstack.com/local-testing/downloads/binaries/BrowserStackLocal-linux-x64"
      else
        "https://www.browserstack.com/local-testing/downloads/binaries/BrowserStackLocal-linux-ia32"
      end
    end

    @ordered_paths = [
      File.join(File.expand_path('~'), '.browserstack'),
      Dir.pwd,
      Dir.tmpdir
    ]
  end

  def download(dest_parent_dir)
    unless File.exist? dest_parent_dir
      Dir.mkdir dest_parent_dir
    end
    uri = URI.parse(@http_path)
    binary_path = File.join(dest_parent_dir, "BrowserStackLocal#{".exe" if @windows}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    res = http.get(uri.path)
    file = open(binary_path, 'wb')
    file.write(res.body)
    file.close
    FileUtils.chmod 0755, binary_path

    binary_path
  end

  def verify_binary(binary_path)
    binary_response = IO.popen(binary_path + " --version").readline
    binary_response =~ /BrowserStack Local version \d+\.\d+/
  rescue Exception => e
    false
  end

  def binary_path
    dest_parent_dir = get_available_dirs
    binary_path = File.join(dest_parent_dir, "BrowserStackLocal#{".exe" if @windows}")

    if File.exist? binary_path
      binary_path
    else
      binary_path = download(dest_parent_dir)
    end

    valid_binary = verify_binary(binary_path)

    if valid_binary
      binary_path
    else
      binary_path = download(dest_parent_dir)
      valid_binary = verify_binary(binary_path)
      if valid_binary
        binary_path
      else
        raise BrowserStack::LocalException.new('BrowserStack Local binary is corrupt')
      end
    end
  end

  private

  def get_available_dirs
    i = 0
    while i < @ordered_paths.size
      path = @ordered_paths[i]
      if make_path(path)
        return path
      else
        i += 1
      end
    end
    raise BrowserStack::LocalException.new('Error trying to download BrowserStack Local binary')
  end

  def make_path(path)
    begin
      FileUtils.mkdir_p path if !File.directory?(path)
      return true
    rescue Exception
      return false
    end
  end
end

end
