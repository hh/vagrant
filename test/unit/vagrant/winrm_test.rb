require File.expand_path("../../base", __FILE__)

describe Vagrant::WINRM do
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
