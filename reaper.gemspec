$:.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'reaper/version'

Gem::Specification.new do |s|
  s.name        = 'reaper'
  s.version     = Todidnt::VERSION
  s.summary     = 'Reaper'
  s.description = "Reaper helps find and close stale Github issues."
  s.authors     = ["Amber Feng"]
  s.email       = 'amber.feng@gmail.com'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/test_*.rb`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end
