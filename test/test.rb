test_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift test_dir unless $:.include?(test_dir)

require 'sass'
require 'sass/exec'
require 'sassmagic'
require 'debugger'

# debugger
class Test
  include Sass::Tree
  def absolutize(file)
    File.expand_path("#{File.dirname(__FILE__)}/#{file}")
  end
  def go
    Sass.compile_file(absolutize("ts/sass/test.scss"), absolutize("ts/stylesheet/test_scss.css"), :style => :expanded)
    # Sass.compile("$who: world;
    # div { hello: $who }
    # p{width:100px}
    # section{background:url('http://tmp/1px.png')}")
  end
end
# debugger
# RemoteSass.location = "https://raw.githubusercontent.com/jsw0528/base.sass/master/stylesheets/base.sass/"
# RemoteSass.location = "http://gitlab.alibaba-inc.com/mtb/app-xinrenquanyi/raw/master/src/css/sass/"
# debugger
Test.new.go

# Sassmagic::Installers::Base.new('xs')
# Sassmagic::Installers::Base.new