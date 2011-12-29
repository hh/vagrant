require 'winrm'

class WinRM::WinRMWebService
  def powershell_version
    shell_id = open_shell
    command_id = run_command(shell_id, '%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell -c echo $PSVersionTable')
    command_output = get_command_output(shell_id, command_id) #, &block)
    cleanup_command(shell_id, command_id)
    close_shell(shell_id)
    command_output
    /PSVersion\W*(\d+.\d+)/.match(command_output[:data].map {|x| x[:stdout]}.join) do |m|
      puts m[1]
    end
  end
  def run_powershell_script(script_file, &block)
    # if an IO object is passed read it..otherwise assume the contents of the file were passed
    script = script_file.kind_of?(IO) ? script_file.read : script_file
    script = script.chars.to_a.join("\x00") + "\x00"
    puts script.inspect
    if(defined?(script.encode))
      script = script.encode('ASCII-8BIT')
      script = Base64.strict_encode64(script)
    else
      script = Base64.encode64(script).chomp
    end
  
    shell_id = open_shell
    command = "%SystemRoot%\\system32\\WindowsPowerShell\\v1.0\\powershell -encodedCommand #{script}"
    puts command
    command_id = run_command(shell_id, command)
    command_output = get_command_output(shell_id, command_id, &block)
    cleanup_command(shell_id, command_id)
    close_shell(shell_id)
    command_output
  end
end

module Vagrant
  # Manages WINRM access to a specific environment. Allows an environment to
  # run commands, upload files, and check if a host is up.
  class WINRM
    include Util::Retryable
    include Util::SafeExec
    attr_accessor :env

    def initialize(environment)
      @env = environment
      @winrm = WinRM::WinRMWebService.new(
        'http://localhost:5985/wsman',
        :plaintext,
        :user => 'Administrator',
        :pass => 'vagrant',
        :basic_auth_only => true)
    end

    def execute(command)
      @winrm.cmd(command) do |stdout, stderr|
      end
    end

    # Uploads a file from `from` to `to`. `from` is expected to be a filename
    # or StringIO, and `to` is expected to be a path. This method simply forwards
    # the arguments to `Net::SCP#upload!` so view that for more information.
    def upload!(from, to)
      retryable(:tries => 5, :on => IOError) do
        script = <<EOS
Som fancy powershell script for upload a file from local disk
EOS
        @winrm.run_powershell_script(script) do |stdout, stderr|
          puts stdout
        end
      end
    end

    # Checks if this environment's machine is up (i.e. responding to WINRM).
    #
    # @return [Boolean]
    def up?
      # We have to determine the port outside of the block since it uses
      # API calls which can only be used from the main thread in JRuby on
      # Windows
      ssh_port = port

      require 'timeout'
      Timeout.timeout(env.config.ssh.timeout) do
        execute 'hostname'
      end

      true
    rescue Net::SSH::AuthenticationFailed
      raise Errors::SSHAuthenticationFailed
    rescue Timeout::Error, Errno::ECONNREFUSED, Net::SSH::Disconnect,
           Errors::SSHConnectionRefused
      return false
    end

    # Returns the port which is either given in the options hash or taken from
    # the config by finding it in the forwarded ports hash based on the
    # `config.ssh.forwarded_port_key`.
    def port(opts={})
      # Check if port was specified in options hash
      return opts[:port] if opts[:port]

      # Check if a port was specified in the config
      return env.config.ssh.port if env.config.ssh.port

      # Check if we have an SSH forwarded port
      pnum_by_name = nil
      pnum_by_destination = nil
      env.vm.vm.network_adapters.each do |na|
        # Look for the port number by name...
        pnum_by_name = na.nat_driver.forwarded_ports.detect do |fp|
          fp.name == env.config.ssh.forwarded_port_key
        end

        # Look for the port number by destination...
        pnum_by_destination = na.nat_driver.forwarded_ports.detect do |fp|
          fp.guestport == env.config.ssh.forwarded_port_destination
        end

        # pnum_by_name is what we're looking for here, so break early
        # if we have it.
        break if pnum_by_name
      end

      return pnum_by_name.hostport if pnum_by_name
      return pnum_by_destination.hostport if pnum_by_destination

      # This should NEVER happen.
      raise Errors::SSHPortNotDetected
    end
  end
end
