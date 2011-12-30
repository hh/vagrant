source "http://rubygems.org"

gemspec

if platform.include?("mingw") || platform.include?("mswin")
  # JRuby requires these gems for development, but only
  # on windows.
  gem "jruby-openssl", "~> 0.7.4", :platforms => :jruby
  gem "jruby-win32ole", "~> 0.8.5", :platforms => :jruby
end
