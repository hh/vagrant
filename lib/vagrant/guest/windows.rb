module Vagrant
  module Guest
    # A general Vagrant system implementation for "windows".
    #
    # Contributed by Chris McClimans <chris@hippiehacker.org>
    class Windows < Base
      # A custom config class which will be made accessible via `config.windows`
      # This is not necessary for all system implementers, of course. However,
      # generally, Vagrant tries to make almost every aspect of its execution
      # configurable, and this assists that goal.
      class WindowsConfig < Vagrant::Config::Base
        attr_accessor :winrm_user
        attr_accessor :winrm_password
        attr_accessor :halt_timeout
        attr_accessor :halt_check_interval
        # # This sets the command to use to execute items as a superuser. sudo is default
        # attr_accessor :suexec_cmd
        attr_accessor :device

        def initialize
          @winrm_user = 'Administrator'
          @winrm_password = 'vagrant'
          @halt_timeout = 30
          @halt_check_interval = 1
          # @suexec_cmd = 'sudo'
          @device = "e1000g"
        end
      end

      # Here for whenever it may be used.
      class WindowsError < Errors::VagrantError
        error_namespace("vagrant.guest.windows")
      end

      def prepare_host_only_network(net_options=nil)
      end

      def enable_host_only_network(net_options)
        # device = "#{vm.config.solaris.device}#{net_options[:adapter]}"
        # su_cmd = vm.config.solaris.suexec_cmd
        # ifconfig_cmd = "#{su_cmd} /sbin/ifconfig #{device}"
        # vm.ssh.execute do |ssh|
        #   ssh.exec!("#{ifconfig_cmd} plumb")
        #   ssh.exec!("#{ifconfig_cmd} inet #{net_options[:ip]} netmask #{net_options[:netmask]}")
        #   ssh.exec!("#{ifconfig_cmd} up")
        #   ssh.exec!("#{su_cmd} sh -c \"echo '#{net_options[:ip]}' > /etc/hostname.#{device}\"")
        # end
      end

      def change_host_name(name)
        #### ON windows, renaming a computer seems to require a reboot
        command="wmic computersystem where name=\"%COMPUTERNAME%\" call rename name=\"#{name}\""

        # su_cmd = vm.config.solaris.suexec_cmd
        # vm.ssh.execute do |ssh|
        #   # Only do this if the hostname is not already set
        #   if !ssh.test?("#{su_cmd} hostname | grep '#{name}'")
        #     ssh.exec!("#{su_cmd} sh -c \"echo '#{name}' > /etc/nodename\"")
        #     ssh.exec!("#{su_cmd} uname -S #{name}")
        #   end
        # end
      end


      # There should be an exception raised if the line
      #
      #     vagrant::::profiles=Primary Administrator
      #
      # does not exist in /etc/user_attr. TODO
      def halt
        vm.ui.info I18n.t("vagrant.guest.windows.attempting_halt")
        vm.channel.execute("mkdir -p #{guestpath}")
        # Wait until the VM's state is actually powered off. If this doesn't
        # occur within a reasonable amount of time (15 seconds by default),
        # then simply return and allow Vagrant to kill the machine.
        count = 0
        while @vm.state != :poweroff
          count += 1
          if count >= @vm.config.windows.halt_timeout
            raise WindowsError, :_key => :guestpath_expand_fail
            return 
          end
          sleep @vm.config.windows.halt_check_interval
        end
      end

      def mount_shared_folder(ssh, name, options
          )#, owner, group)
        # Create the shared folder
        # ssh.exec!("#{vm.config.solaris.suexec_cmd} mkdir -p #{guestpath}")

        # # Mount the folder with the proper owner/group
        # options = "-o uid=`id -u #{owner}`,gid=`id -g #{group}`"
        # ssh.exec!("#{vm.config.solaris.suexec_cmd} /sbin/mount -F vboxfs #{options} #{name} #{guestpath}")

        # # chown the folder to the proper owner/group
        # ssh.exec!("#{vm.config.solaris.suexec_cmd} chown `id -u #{owner}`:`id -g #{group}` #{guestpath}")
      end
    end
  end
end
