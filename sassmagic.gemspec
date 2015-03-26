# coding: utf-8
lib = File.expand_path('lib', File.dirname(__FILE__))
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
# require 'compass/core/version'

Gem::Specification.new do |spec|
  spec.name = 'sassmagic'
  spec.version = '0.1.5'
  spec.summary = 'Awesome Extensions For Sass'
  spec.description = 'Awesome features that you wanted'
  spec.homepage = 'https://github.com/ringself/sassmagic'
  spec.author = 'ring'
  spec.email = 'ring.wangh@alibaba-inc.com'
  spec.license = 'MIT'
  spec.files = Dir[
      'bin/*',
      'lib/**/*',
    'stylesheets/**/*',
    '*.md'
  ]
  spec.bindir = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.platform = Gem::Platform::RUBY
  spec.required_ruby_version = '>= 1.9'
  spec.add_dependency "sass", ">= 3.3.0", "< 3.5"
end
