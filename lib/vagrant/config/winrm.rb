module Vagrant
  module Config
    class WINRMConfig < Base
      attr_accessor :username
      attr_accessor :password
      attr_accessor :host
      attr_accessor :port
      attr_accessor :guest_port
      attr_accessor :max_tries
      attr_accessor :timeout

      def initialize
        @username = "Administrator"
        @password = "vagrant"
        @guest_port = 5985
        @host = "localhost"
        @max_tries = 3
        @timeout = 30
      end

      def validate(env, errors)
        [:username, :password, :host, :max_tries, :timeout].each do |field|
          errors.add(I18n.t("vagrant.config.common.error_empty", :field => field)) if !instance_variable_get("@#{field}".to_sym)
        end

      end
    end
  end
end
