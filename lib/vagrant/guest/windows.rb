module Vagrant
  module Guest
    # A general Vagrant system implementation for "windows".
    #
    # Contributed by Chris McClimans <chris@hippiehacker.org>
    class Windows < Base
      # A custom config class which will be made accessible via `config.windows`
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
        #### on windows, renaming a computer seems to require a reboot
        vm.channel.execute("wmic computersystem where name=\"%COMPUTERNAME%\" call rename name=\"#{name}\"")
      end


      # There should be an exception raised if the line
      #
      #     vagrant::::profiles=Primary Administrator
      #
      # does not exist in /etc/user_attr. TODO
      def halt
        vm.ui.info I18n.t("vagrant.guest.windows.attempting_halt")
        vm.channel.execute("shutdown /s /t 1 /c \"Vagrant Halt\" /f /d p:4:1")
        # Wait until the VM's state is actually powered off. If this doesn't
        # occur within a reasonable amount of time (15 seconds by default),
        # then simply return and allow Vagrant to kill the machine.
        count = 0
        while @vm.state != :poweroff
          count += 1
          if count >= 15 # @vm.config.windows.halt_timeout
            raise WindowsError, :_key => :guestpath_expand_fail
            return 
          end
          sleep 1 # @vm.config.windows.halt_check_interval
        end
      end

      def mount_shared_folder(ssh, name, options)
        #, owner, group)
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
