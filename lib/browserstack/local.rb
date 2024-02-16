require 'browserstack/localbinary'
require 'browserstack/localexception'
require 'json'
require 'subprocess'

module BrowserStack

class Local
  attr_reader :pid

  def initialize(key = ENV["BROWSERSTACK_ACCESS_KEY"], startup_timeout = 120)
    @key = key
    @user_arguments = []
    @logfile = File.join(Dir.pwd, "local.log")
    @is_windows = RbConfig::CONFIG['host_os'].match(/mswin|msys|mingw|cygwin|bccwin|wince|emc|win32/)
    @startup_timeout = startup_timeout
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
      @local_identifier_flag = value
    elsif key == "f"
      @folder_flag = "-f"
      @folder_path = value
    elsif key == "proxyHost"
      @proxy_host = value
    elsif key == "proxyPort"
      @proxy_port = value
    elsif key == "proxyUser"
      @proxy_user = value
    elsif key == "proxyPass"
      @proxy_pass = value
    elsif key == "hosts"
      @hosts = value
    elsif key == "logfile"
      @logfile = value
    elsif key == "binarypath"
      @binary_path = value
    elsif key == "forceproxy" && value.to_s != "false"
      @force_proxy_flag = "-forceproxy"
    else
      if value.to_s.downcase.eql?("true")
        @user_arguments << "-#{key}"
      else
        @user_arguments += ["-#{key}", value]
      end
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

    # ensure the logfile exists
    File.open(@logfile, "a") do
    end

    @process = Subprocess::Process.new(start_command_args, stdout: Subprocess::PIPE, stderr: Subprocess::STDOUT)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + @startup_timeout

    while Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
      begin
        remaining = [Process.clock_gettime(Process::CLOCK_MONOTONIC) - deadline, 1].max
        if IO.select([@process.stdout], [], [@process.stdout], remaining).nil?
          sleep 1
          next
        end
        line = @process.stdout.readline
      rescue EOFError => e
        sleep 1
        next
      end

      data = JSON.parse(line) rescue {"message" => "Unable to parse daemon mode JSON output"}
      if data['state'].to_s != "connected"
        raise BrowserStack::LocalException.new(data["message"]["message"])
        return
      else
        @pid = data["pid"]
        @process.wait
        @process = nil
        return
      end
    end
  end

  def isRunning
    return true if (!@pid.nil? && Process.kill(0, @pid)) rescue false
  end

  def stop
    return if @pid.nil?
    unless @process.nil?
      @process.terminate
      @process.wait
      @process = nil
    end
    Subprocess.check_call(stop_command_args)
    @pid = nil
  end

  def start_command_args
    args = [@binary_path, "-d", "start", "-logFile", @logfile, @key, @folder_flag, @folder_path, @force_local_flag]
    args += ["-localIdentifier", @local_identifier_flag] if @local_identifier_flag
    args += [@only_flag, @only_automate_flag]
    args += ["-proxyHost", @proxy_host] if @proxy_host
    args += ["-proxyPort", @proxy_port] if @proxy_port
    args += ["-proxyUser", @proxy_user] if @proxy_user
    args += ["-proxyPass", @proxy_pass] if @proxy_pass
    args += [@force_proxy_flag, @force_flag, @verbose_flag, @hosts]
    args += @user_arguments

    args.select {|a| a.to_s != "" }
  end

  def stop_command_args
    args = ["#{@binary_path}", "-d", "stop"]
    args +=  ["-localIdentifier", "#{@local_identifier_flag}"] if @local_identifier_flag
    args.select {|a| a.to_s != "" }
  end
end

end
