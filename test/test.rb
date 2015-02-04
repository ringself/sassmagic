test_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift test_dir unless $:.include?(test_dir)

require 'sass'
require 'sass/exec'
require 'sassmagic'
require 'debugger'
debugger
class Test
  include Sass::Tree
  def absolutize(file)
    File.expand_path("#{File.dirname(__FILE__)}/#{file}")
  end
  def go
    Sass.compile_file(absolutize("test.scss"), absolutize("test_scss.css"), :style => :nested)
    # Sass.compile("$who: world;
    # div { hello: $who }
    # p{width:100px}
    # section{background:url('http://tmp/1px.png')}")
  end
end

Test.new.go
