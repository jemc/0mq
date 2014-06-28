
Gem::Specification.new do |s|
  s.name          = '0mq'
  s.version       = '0.5.2'
  s.date          = '2014-06-11'
  s.summary       = "0mq"
  s.description   = "A Ruby-like wrapper for ffi-rzmq-core (ZeroMQ)"
  s.authors       = ["Joe McIlvain", "Alex McLain"]
  s.email         = 'joe.eli.mac@gmail.com'
  
  s.files         = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  
  s.require_path  = 'lib'
  s.homepage      = 'https://github.com/jemc/0mq/'
  s.licenses      = 'MIT'
  
  s.add_dependency 'ffi-rzmq-core', '~> 1.0'
  
  s.add_development_dependency 'bundler',    '~>  1.6'
  s.add_development_dependency 'rake',       '~> 10.3'
  s.add_development_dependency 'pry',        '~>  0.9'
  s.add_development_dependency 'pry-rescue', '~>  1.4'
  s.add_development_dependency 'rspec',      '~>  3.0'
  s.add_development_dependency 'rspec-its',  '~>  1.0'
  s.add_development_dependency 'fivemat',    '~>  1.3'
  s.add_development_dependency 'yard',       '~>  0.8'
  s.add_development_dependency 'ruby-prof',  '~>  0.15' unless defined? Rubinius
end
