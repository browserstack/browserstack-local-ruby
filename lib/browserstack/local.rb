require 'browserstack/localbinary'

module BrowserStack

class Local
  attr_reader :pid

  def initialize(key = nil, binary_path = nil)
    @key = key
    @binary_path = if binary_path.nil?
        BrowserStack::LocalBinary.new.binary_path
      else
        binary_path
      end
  end

  def add_args(key, value=nil)
    if key == "key"
      @key = value
    elsif key == "v" && value.to_s != "false"
      @verbose_flag = "-v"
    elsif key == "force" && value.to_s != "false"
      @force_flag = "-force"
    elsif key == "only" && value.to_s != "false"
      @only_flag = "-only"
    elsif key == "onlyAutomate" && value.to_s != "false"
      @only_automate_flag = "-onlyAutomate"
    elsif key == "forcelocal" && value.to_s != "false"
      @force_local_flag = "-forcelocal"
    elsif key == "localIdentifier"
      @local_identifier_flag = "-localIdentifier '#{value}'"
    elsif key == "f"
      @folder_flag = "-f"
      @folder_path = "'#{value}'"
    elsif key == "proxyHost"
      @proxy_host = "-proxyHost '#{value}'"
    elsif key == "proxyPort"
      @proxy_port = "-proxyPort #{value}"
    elsif key == "proxyUser"
      @proxy_user = "-proxyUser '#{value}'"
    elsif key == "proxyPass"
      @proxy_pass = "-proxyPass '#{value}'"
    elsif key == "hosts"
      @hosts = value
    end
  end

  def start(options = {})
    options.each_pair do |key, value|
      self.add_args(key, value)
    end

    @process = IO.popen(command, "w+")

    while true
      line = @process.readline
      break if line.nil?
      if line.match(/\*\*\* Error\:/)
        @process.close
        raise BrowserStack::LocalException.new(line)
        return
      end
      if line.strip == "Press Ctrl-C to exit"
        @pid = @process.pid
        return
      end
    end

    while true
      break if self.isRunning
      sleep 1
    end
  end

  def isRunning
    resp = Net::HTTP.get(URI.parse("http://localhost:45691/check")) rescue nil
    resp && !resp.match(/running/i).nil?
  end

  def stop
    return if @pid.nil?
    Process.kill("INT", @pid)
    @process.close
  end

  def command
    "#{@binary_path} #{@folder_flag} #{@key} #{@folder_path} #{@force_local_flag} #{@local_identifier_flag} #{@only_flag} #{@only_automate_flag} #{@proxy_host} #{@proxy_port} #{@proxy_user} #{@proxy_pass} #{@force_flag} #{@verbose_flag} #{@hosts}".strip
  end
end

class LocalException < Exception
end

end
