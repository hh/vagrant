module Vagrant
  module Config
    class WINRMConfig < Base
      attr_accessor :username
      attr_accessor :password
      attr_accessor :host
      attr_accessor :forwarded_port_key
      attr_accessor :forwarded_port_destination
      attr_accessor :max_tries
      attr_accessor :timeout
      attr_accessor :port

      def initialize
        @username = "Administrator"
        @shell = "bash"
        @port = nil
      end

      def validate(env, errors)
        [:username, :password, :host, :forwarded_port_key, :max_tries, :timeout].each do |field|
          errors.add(I18n.t("vagrant.config.common.error_empty", :field => field)) if !instance_variable_get("@#{field}".to_sym)
        end

      end
    end
  end
end
