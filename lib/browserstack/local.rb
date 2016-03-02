require 'browserstack/localbinary'
require 'browserstack/localexception'

module BrowserStack

class Local
  attr_reader :pid

  def initialize(key = ENV["BROWSERSTACK_ACCESS_KEY"])
    @key = key
    @logfile = File.join(Dir.pwd, "local.log")
  end

  def add_args(key, value=nil)
    if key == "key"
      @key = value
    elsif key == "v" && value.to_s != "false"
      @verbose_flag = "-vvv"
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
    elsif key == "logfile"
      @logfile = value
    elsif key == "binarypath"
      @binary_path = value
    end
  end

  def start(options = {})
    options.each_pair do |key, value|
      self.add_args(key, value)
    end

    @binary_path = if @binary_path.nil?
        BrowserStack::LocalBinary.new.binary_path
      else
        @binary_path
      end
    
    system("echo '' > '#{@logfile}'")
    #@pid = spawn()
    #Process.detach @pid
    @process = IO.popen(command_args)
    @stdout = File.open(@logfile, "r")

    while true
      begin
        line = @stdout.readline
      rescue EOFError => e
        sleep 1
        next
      end
      break if line.nil?
      if line.match(/\*\*\* Error\:/)
        @stdout.close
        raise BrowserStack::LocalException.new(line)
        return
      end
      if line.strip == "Press Ctrl-C to exit"
        @pid = @process.pid
        @stdout.close
        break
      end
    end

    while true
      break if self.isRunning
      sleep 1
    end
  end

  def isRunning
    return true if (!@pid.nil? && Process.kill(0, @pid)) rescue false
  end

  def stop
    return if @pid.nil?
    Process.kill("TERM", @pid)
    @process.close
    while self.isRunning
      sleep 1
    end
  end

  def command
    "#{@binary_path} -logFile '#{@logfile}' #{@folder_flag} #{@key} #{@folder_path} #{@force_local_flag} #{@local_identifier_flag} #{@only_flag} #{@only_automate_flag} #{@proxy_host} #{@proxy_port} #{@proxy_user} #{@proxy_pass} #{@force_flag} #{@verbose_flag} #{@hosts}".strip
  end

  def command_args
    args = ["#{@binary_path}", "-logFile", "#{@logfile}", "#{@key}", "#{@folder_flag}", "#{@folder_path}", "#{@force_local_flag}", "#{@local_identifier_flag}", "#{@only_flag}", "#{@only_automate_flag}", "#{@proxy_host}", "#{@proxy_port}", "#{@proxy_user}", "#{@proxy_pass}", "#{@force_flag}", "#{@verbose_flag}", "#{@hosts}"]
    args = args.select {|a| a.to_s != "" }
    args.push(:err => [:child, :out])
    args
  end
end

end
