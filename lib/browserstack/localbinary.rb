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
      "https://www.dropbox.com/s/oviu8oge5elv1ca/BrowserStackLocal-win32.exe?dl=0"
    when /darwin|mac os/
      "https://www.dropbox.com/s/q6quexatq5013xy/BrowserStackLocal-darwin-x64?dl=0"
    when /linux/
      if 1.size == 8
        "https://www.dropbox.com/s/jnrm7u3inwhnj5r/BrowserStackLocal-linux-x64?dl=0"
      else
        "https://www.dropbox.com/s/ae2zsyxceeci0wk/BrowserStackLocal-linux-ia32?dl=0"
      end
    end

    @ordered_paths = [
      File.join(File.expand_path('~'), '.browserstack'),
      Dir.pwd,
      Dir.tmpdir
    ]
  end

  def download(dest_parent_dir)
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
      FileUtils.chmod 0755, binary_path
    end
    binary_path
  end

  def binary_path
    dest_parent_dir = get_available_dirs
    binary_path = File.join(dest_parent_dir, "BrowserStackLocal#{".exe" if @windows}")
    if File.exists? binary_path
      binary_path
    else
      download(dest_parent_dir)
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
    rescue Exception => e
      return false
    end
  end
end

end