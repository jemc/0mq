
Gem::Specification.new do |s|
  s.name          = '0mq'
  s.version       = '0.2.1'
  s.date          = '2014-03-04'
  s.summary       = "0mq"
  s.description   = "A Ruby-like wrapper for ffi-rzmq-core (ZeroMQ)"
  s.authors       = ["Joe McIlvain", "Alex McLain"]
  s.email         = 'joe.eli.mac@gmail.com'
  
  s.files         = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  
  s.require_path  = 'lib'
  s.homepage      = 'https://github.com/jemc/0mq/'
  s.licenses      = 'MIT'
  
  s.add_dependency 'ffi-rzmq-core', '~> 1.0'
  
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-rescue'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'fivemat'
end
