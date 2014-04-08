$:.unshift(File.dirname(__FILE__) + '/lib')
require 'chef_metal_lxc/version'

Gem::Specification.new do |s|
  s.name = 'chef-metal-lxc'
  s.version = ChefMetalLXC::VERSION
  s.platform = Gem::Platform::RUBY
  s.extra_rdoc_files = ['README.md', 'LICENSE' ]
  s.summary = 'Provisioner for creating LXC containers in Chef Metal.'
  s.description = s.summary
  s.author = 'Ranjib Dey'
  s.email = 'dey.ranjib@gmail.com'
  s.homepage = 'https://github.com/opscode/chef-metal-lxc'

  s.add_dependency 'chef'
  s.add_dependency 'chef-metal', '~> 0.8'
  s.add_dependency 'ruby-lxc', '~> 1.0', '>= 1.0.2'
  s.add_dependency 'lxc-extra', '~> 0.0', '>= 0.0.3'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rake'

  s.bindir       = "bin"
  s.executables  = %w( )

  s.require_path = 'lib'
  s.files = %w(Rakefile LICENSE README.md) + Dir.glob("{distro,lib,tasks,spec}/**/*", File::FNM_DOTMATCH).reject {|f| File.directory?(f) }
end
