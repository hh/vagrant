require 'timeout'

require 'log4r'
require 'em-winrm'
require 'highline'

require 'vagrant/util/ansi_escape_code_remover'
require 'vagrant/util/file_mode'
require 'vagrant/util/platform'
require 'vagrant/util/retryable'

# class WinRM::WinRMWebService
#   def powershell_version
#     shell_id = open_shell
#     command_id = run_command(shell_id, '%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell -c echo $PSVersionTable')
#     command_output = get_command_output(shell_id, command_id) #, &block)
#     cleanup_command(shell_id, command_id)
#     close_shell(shell_id)
#     #command_output
#     /PSVersion\W*(\d+.\d+)/.match(
#       command_output[:data].map {|x| x[:stdout]}.join
#       ) { |m| m[1] }
#   end
#   def run_powershell_script(script_file, &block)
#     # if an IO object is passed read it..otherwise assume the contents of the file were passed
#     script = script_file.kind_of?(IO) ? script_file.read : script_file
#     script = script.chars.to_a.join("\x00") + "\x00"
#     puts script.inspect
#     if(defined?(script.encode))
#       script = script.encode('ASCII-8BIT')
#       script = Base64.strict_encode64(script)
#     else
#       script = Base64.encode64(script).chomp
#     end
  
#     shell_id = open_shell
#     command = "%SystemRoot%\\system32\\WindowsPowerShell\\v1.0\\powershell -encodedCommand #{script}"
#     puts command
#     command_id = run_command(shell_id, command)
#     command_output = get_command_output(shell_id, command_id, &block)
#     cleanup_command(shell_id, command_id)
#     close_shell(shell_id)
#     command_output
#   end
# end


module Vagrant
  module Communication
    # Provides communication with the VM via SSH.
    class WINRM < Base
      include Util::ANSIEscapeCodeRemover
      include Util::Retryable

      def initialize(vm)
        @vm     = vm
        @logger = Log4r::Logger.new("vagrant::communication::winrm")
        @co = nil
      end

      def ready?
        @logger.debug("Checking whether WINRM is ready...")

        Timeout.timeout(@vm.config.winrm.timeout) do
          execute "hostname"
        end

        # If we reached this point then we successfully connected
        @logger.info("WINRM is ready!")
        true
      rescue Timeout::Error => e
        #, Errors::SSHConnectionRefused, Net::SSH::Disconnect => e
        # The above errors represent various reasons that WINRM may not be
        # ready yet. Return false.
        @logger.info("WINRM not up yet: #{e.inspect}")
        return false
      end
      
      def execute(command, opts=nil, &block)
        # Check that the private key permissions are valid
        # @vm.ssh.check_key_permissions(ssh_info[:private_key_path])

        # Connect to SSH, giving it a few tries
        @logger.info("Connecting to WINRM: #{@vm.winrm.info[:host]}:#{@vm.winrm.info[:port]}")
        # exceptions = [Errno::ECONNREFUSED] #, Net::SSH::Disconnect]
        # connection = retryable(:tries => @vm.config.winrm.max_tries,
        #   :on => exceptions) do
        #   @logger.info("Pretending to connect via winrm here")
        #   #Net::SSH.start(ssh_info[:host], ssh_info[:username], opts)
        # end

        opts = {
          :error_check => true,
          :error_class => Errors::VagrantError,
          :error_key   => :winrm_bad_exit_status,
          :command     => command,
          :sudo        => false
        }.merge(opts || {})

        # Connect via SSH and execute the command in the shell.
        exit_status = shell_execute(command, &block)
        @logger.info("#{command} EXIT STATUS #{exit_status.inspect}")
        puts ("#{command} EXIT STATUS #{exit_status.inspect}")

        # Check for any errors
        if opts[:error_check] && exit_status != 0
          # The error classes expect the translation key to be _key,
          # but that makes for an ugly configuration parameter, so we
          # set it here from `error_key`
          error_opts = opts.merge(:_key => opts[:error_key])
          raise opts[:error_class], error_opts
        end

        # Return the exit status
        exit_status
      end

      def new_session
        opts = {
          :user => @vm.config.winrm.username,
          :pass => @vm.config.winrm.password,
          :host => @vm.config.winrm.host,
          :port => @vm.winrm.info[:port],
          #:transport => :http,
          :basic_auth_only => true
        }.merge ({})

        # create a session
        begin
          endpoint = "http://#{opts[:host]}:#{opts[:port]}/wsman"
          client = ::WinRM::WinRMWebService.new(endpoint, :plaintext, opts)
          client.set_timeout(opts[:operation_timeout]) if opts[:operation_timeout]
        rescue ::WinRM::WinRMAuthorizationError => error
          raise ::WinRM::WinRMAuthorizationError.new("#{error.message}@#{opts[:host]}")
        end
        client
      end
      
      def session
        @session ||= new_session
      end
      
      def h
        @highline ||= HighLine.new
      end
      
      def print_data(data, color = :cyan)
        if data =~ /\n/
          data.split(/\n/).each { |d| print_data(d, color) }
        else
          puts "#{h.color('winrm', color)} #{data.chomp}"
        end
      end

      def sudo(command, opts=nil, &block)
        # Run `execute` but with the `sudo` option.
        opts = { :sudo => true }.merge(opts || {})
        execute(command, opts, &block)
      end

      def upload(from, to)
        @logger.debug("Uploading: #{from} to #{to}")
        
        scp = Net::SCP.new(connection)
        scp.upload!(from, to)
      rescue Net::SCP::Error => e
        # If we get the exit code of 127, then this means SCP is unavailable.
        raise Errors::SCPUnavailable if e.message =~ /\(127\)/

        # Otherwise, just raise the error up
        raise
      end

      protected

      # Executes the command on an SSH connection within a login shell.
      def shell_execute(command)
        @logger.info("Execute: #{command}")
        exit_status = nil
        remote_id = session.open_shell
        command_id = session.run_command(remote_id, command)
        output = session.get_command_output(remote_id, command_id) do |out,error|
          print_data(out) if out
          print_data(error) if error
        end
        exit_status = output[:exitcode]
        @logger.info exit_status.inspect

        # Return the final exit status
        return exit_status
      end
    end
  end
end
