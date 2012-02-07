module Vagrant
  module Config
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

      def validate(env, errors)
        [:username, :password, :host, :max_tries, :timeout].each do |field|
          errors.add(I18n.t("vagrant.config.common.error_empty", :field => field)) if !instance_variable_get("@#{field}".to_sym)
        end
      end
    end
  end
end
