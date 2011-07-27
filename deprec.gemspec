require 'rubygems' 

SPEC = Gem::Specification.new do |s|
  s.name = 'le1t0-deprec'
  s.version = '2.1.6.082'
  
  s.authors = ['Le1t0']
  s.description = <<-EOF
      This project provides libraries of Capistrano tasks and extensions to 
      remove the repetative manual work associated with installing services 
      on linux servers.
  EOF
  s.email = 'dev@ewout.to'
  s.homepage = 'http://github.com/le1t0/deprec'
  s.summary = 'deployment recipes for capistrano'

  s.require_paths = ['lib']
  s.add_dependency('le1t0-capistrano', '= 2.5.18.024')
  candidates = Dir.glob("{bin,docs,lib}/**/*") 
  candidates.concat(%w(CHANGELOG COPYING LICENSE README THANKS))
  s.files = candidates.delete_if do |item| 
    item.include?("CVS") || item.include?("rdoc") 
  end
  s.executables = ["depify"]
end
