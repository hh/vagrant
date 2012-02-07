module Vagrant
  module Communication
    autoload :Base, 'vagrant/communication/base'

    autoload :SSH,  'vagrant/communication/ssh'
    autoload :WINRM,'vagrant/communication/winrm'
  end
end
