require 'simplecov'
SimpleCov.start

require 'rspec'
require 'pronto/ansible_lint'

Dir.glob(Dir.pwd + '/spec/support/**/*.rb') { |file| require file }

# Cross-platform way of finding an executable in the $PATH.
#
#   which('ruby') #=> /usr/bin/ruby
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each do |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable?(exe) && !File.directory?(exe)
    end
  end
  nil
end

if which('ansible-lint').nil?
  raise 'Please `pip install ansible-lint` or ensure ansible-lint is in your PATH'
end

RSpec.configure do |c|
  c.include RepositoryHelper
end
