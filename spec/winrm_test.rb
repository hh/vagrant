require File.expand_path("../../base", __FILE__)

describe Vagrant::WINRM do
  let(:environment) do
    i=isolated_environment
    i
  end

  context "in getting on the ground" do
   it "casfdaonnects?" do
      @network_adapters = []
      @vm = mock("vm")
      @vm.stubs(:network_adapters).returns(@network_adapters)
      # for @env.config.ssh.port returing '59856'
      @ssh = mock('ssh')
      @ssh.stubs(:port).returns('59856')
      @config = mock("config")
      @config.stubs(:ssh).returns(@ssh)
      @env.stubs(:config).returns(@config)
      @env.vm.stubs(:vm).returns(@vm)
      puts @env.inspect #nil
      t=Vagrant::WINRM.new @env
      t.execute ''
    end
  end
  context "connecting to external WINRM" do
    it "should raise an exception if winrm gem isn't avaliable"
  end
  context "executing winrm commands" do
    it "should call winrm module with proper commands"
    it "should use custom host if set"
  end
  context "copying files to the remote host" do
    it "should upload a file"
  end
  context "checking if host is up" do
    it "return false if WINRM connection times out"
    it "return false if WINRM connection is refused"
    it "specify the timeout as an option to execute"
    it "error and exit if a WINRM::::AuthenticationFailed is raised"
  end
  context "getting the winrm port" do
    it "return the port given in the options if it exists"
    it "return the default port"
  end
end
