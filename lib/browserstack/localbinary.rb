require 'net/http'
require 'rbconfig'
require 'openssl'

module BrowserStack
  
class LocalBinary
  def initialize
    host_os = RbConfig::CONFIG['host_os']
    @http_path = case host_os
    when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
      @windows = true
      "https://s3.amazonaws.com/browserStack/browserstack-local/BrowserStackLocal.exe"
    when /darwin|mac os/
      "https://s3.amazonaws.com/browserStack/browserstack-local/BrowserStackLocal-darwin-x64"
    when /linux/
      if 1.size == 8
        "https://s3.amazonaws.com/browserStack/browserstack-local/BrowserStackLocal-linux-x64"
      else
        "https://s3.amazonaws.com/browserStack/browserstack-local/BrowserStackLocal-linux-ia32"
      end
    end
  end

  def download
    dest_parent_dir = File.join(File.expand_path('~'), '.browserstack')
    unless File.exists? dest_parent_dir
      Dir.mkdir dest_parent_dir
    end
    uri = URI.parse(@http_path)
    binary_path = File.join(dest_parent_dir, "BrowserStackLocal#{".exe" if @windows}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.request_get(uri.path) do |res|
      file = open(binary_path, 'w')
      res.read_body do |chunk|
        file.write(res.body)
      end
      file.close
      FileUtils.chmod "+x", binary_path
    end
    binary_path
  end

  def binary_path
    dest_parent_dir = File.join(File.expand_path('~'), '.browserstack')
    binary_path = File.join(dest_parent_dir, "BrowserStackLocal#{".exe" if @windows}")
    if File.exists? binary_path
      binary_path
    else
      download
    end
  end
end

end