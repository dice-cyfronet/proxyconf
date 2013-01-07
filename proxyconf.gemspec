require "rubygems"
require "parka/specification"
require "./lib/proxyconf.rb"

Parka::Specification.new do |gem|
  gem.name             = "proxyconf"
  gem.version          = ProxyConf::VERSION
  gem.summary          = "Dynamic nginx proxy configuration tool"
  gem.homepage         = "http://trac.kocur.olorin.info/projects/xen"
  gem.author           = "Kamil Figiela, Paweł Pietraszko"
  gem.email            = "fkamil@student.agh.edu.pl"
  gem.executables      = "proxyconf"            
  gem.files            = Dir.glob ["Gemfile", "Gemfile.lock", "README.rdoc", "bin/*", "lib/*", "lib/*/*", "lib/*/*/*", "example/*"]
  gem.extra_rdoc_files = "README.rdoc"    
  gem.rdoc_options     = ["--line-numbers", "--inline-source", "--title", "proxyconf", "--main", "README.rdoc"]
  

end